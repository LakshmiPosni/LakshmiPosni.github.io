# Lata's Bachelorette Party 💗 — Web App

A free, no-App-Store, shareable schedule app. Works on iPhone **and** Android — anyone opens a link, taps "Add to Home Screen," and it behaves like an installed app.

## What's in this folder
- **`index.html`** — the entire app in one self-contained file (no internet needed to run). This is the file to host and edit.

## How to put it online for free (pick one)

### Option A — Netlify Drop (easiest, ~1 minute)
1. Go to **app.netlify.com/drop**.
2. Drag this whole **LataBacheloretteWeb** folder onto the page.
3. You get a live link like `https://something.netlify.app` — share it with everyone.
   (A free Netlify account lets you rename it to e.g. `latas-bach.netlify.app`.)

### Option B — GitHub Pages (free, permanent)
1. Create a free GitHub account + a new repository.
2. Upload `index.html` to it.
3. Repo **Settings → Pages → Deploy from branch → main → /root**.
4. Your link: `https://yourname.github.io/reponame/`.

### Option C — Cloudflare Pages / Vercel
Same idea — create a free account, drag the folder or connect the repo, get a link.

## How friends "install" it
Send them the link. On the page they tap the **Share** icon → **Add to Home Screen**. It gets the 💗 icon and opens fullscreen like a real app. Their name and packing checkmarks are saved on their own phone.

## Editing content
Everything is in `index.html` inside the `<script>` block near the top:
- `BRIDE` — the bride's name.
- `days` — each day's schedule and outfit themes. Add `time:[hour,minute]` (24-hour) to an item to give it a time pill.
- `packing` — the checklist.
Colors live in the `:root { ... }` block in the `<style>` at the top.
