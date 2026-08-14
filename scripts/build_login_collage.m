#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

int main(void) {
    @autoreleasepool {
        NSFileManager *files = NSFileManager.defaultManager;
        NSURL *projectURL = [NSURL fileURLWithPath:files.currentDirectoryPath];
        NSURL *sourceURL = [projectURL URLByAppendingPathComponent:@"login-collage-photos" isDirectory:YES];
        NSURL *outputURL = [projectURL URLByAppendingPathComponent:@"login-collage.jpg"];
        NSSet<NSString *> *allowed = [NSSet setWithArray:@[@"jpg", @"jpeg", @"png", @"heic"]];
        NSError *error = nil;
        NSArray<NSURL *> *contents = [files contentsOfDirectoryAtURL:sourceURL
                                          includingPropertiesForKeys:nil
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                               error:&error];
        if (!contents) {
            fprintf(stderr, "Could not read photo folder: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }

        NSArray<NSURL *> *photos = [[contents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *url, NSDictionary *bindings) {
            return [allowed containsObject:url.pathExtension.lowercaseString];
        }]] sortedArrayUsingComparator:^NSComparisonResult(NSURL *left, NSURL *right) {
            return [left.lastPathComponent localizedStandardCompare:right.lastPathComponent];
        }];
        if (photos.count != 30) {
            fprintf(stderr, "Expected exactly 30 photos, found %lu.\n", (unsigned long)photos.count);
            return 1;
        }

        const size_t columns = 5;
        const size_t rows = 6;
        const size_t tileSize = 400;
        const size_t canvasWidth = columns * tileSize;
        const size_t canvasHeight = rows * tileSize;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, canvasWidth, canvasHeight, 8, 0, colorSpace,
                                                     kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        if (!context) {
            fprintf(stderr, "Could not create collage canvas.\n");
            return 1;
        }
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        CGContextFillRect(context, CGRectMake(0, 0, canvasWidth, canvasHeight));

        NSDictionary *thumbnailOptions = @{
            (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
            (__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform: @YES,
            (__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize: @1400
        };
        NSURL *temporaryURL = [NSURL fileURLWithPath:@"/tmp/lata-login-collage-thumbnails" isDirectory:YES];
        [files removeItemAtURL:temporaryURL error:nil];
        [files createDirectoryAtURL:temporaryURL withIntermediateDirectories:YES attributes:nil error:&error];

        for (NSUInteger index = 0; index < photos.count; index++) {
            NSURL *photoURL = photos[index];
            NSURL *normalizedURL = [temporaryURL URLByAppendingPathComponent:[photoURL.lastPathComponent stringByAppendingString:@".png"]];
            NSTask *converter = [[NSTask alloc] init];
            converter.executableURL = [NSURL fileURLWithPath:@"/usr/bin/qlmanage"];
            converter.arguments = @[@"-t", @"-s", @"1400", @"-o", temporaryURL.path, photoURL.path];
            converter.standardOutput = NSFileHandle.fileHandleWithNullDevice;
            converter.standardError = NSFileHandle.fileHandleWithNullDevice;
            if (![converter launchAndReturnError:&error]) {
                fprintf(stderr, "Could not normalize %s: %s\n", photoURL.lastPathComponent.UTF8String, error.localizedDescription.UTF8String);
                CGContextRelease(context);
                return 1;
            }
            [converter waitUntilExit];
            if (converter.terminationStatus != 0) {
                fprintf(stderr, "Could not normalize %s.\n", photoURL.lastPathComponent.UTF8String);
                CGContextRelease(context);
                return 1;
            }

            CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)normalizedURL, NULL);
            CGImageRef image = source ? CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)thumbnailOptions) : NULL;
            if (source) CFRelease(source);
            if (!image) {
                fprintf(stderr, "Could not read %s.\n", photoURL.lastPathComponent.UTF8String);
                CGContextRelease(context);
                return 1;
            }

            CGFloat imageWidth = CGImageGetWidth(image);
            CGFloat imageHeight = CGImageGetHeight(image);
            NSUInteger column = index % columns;
            NSUInteger row = index / columns;
            CGRect tileRect = CGRectMake(column * tileSize,
                                         canvasHeight - ((row + 1) * tileSize),
                                         tileSize, tileSize);
            CGFloat scale = MAX(tileSize / imageWidth, tileSize / imageHeight);
            CGFloat drawWidth = imageWidth * scale;
            CGFloat drawHeight = imageHeight * scale;
            CGRect drawRect = CGRectMake(CGRectGetMidX(tileRect) - drawWidth / 2.0,
                                         CGRectGetMidY(tileRect) - drawHeight / 2.0,
                                         drawWidth, drawHeight);

            CGContextSaveGState(context);
            CGContextClipToRect(context, tileRect);
            CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
            CGContextDrawImage(context, drawRect, image);
            CGContextRestoreGState(context);
            CGImageRelease(image);
        }
        [files removeItemAtURL:temporaryURL error:nil];

        CGImageRef collage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
            (__bridge CFURLRef)outputURL,
            CFSTR("public.jpeg"),
            1,
            NULL
        );
        NSDictionary *jpegOptions = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @0.9};
        CGImageDestinationAddImage(destination, collage, (__bridge CFDictionaryRef)jpegOptions);
        BOOL saved = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        CGImageRelease(collage);
        if (!saved) {
            fprintf(stderr, "Could not save collage.\n");
            return 1;
        }

        printf("Created %s from 30 photos (%zux%zu).\n",
               outputURL.path.UTF8String, canvasWidth, canvasHeight);
    }
    return 0;
}
