# Publishing

How to cut a release and list **System Graph Gauge** on the KDE Store.

## 1. Cut a release

1. Bump `Version` in `metadata.json` (and keep it in sync with the tag).
2. Commit, then tag and push:

   ```sh
   git commit -am "Release vX.Y"
   git tag -a vX.Y -m "System Graph Gauge vX.Y"
   git push origin main vX.Y
   ```

3. Build the distributable package (a `.plasmoid` is a zip with `metadata.json`
   at the root and the `contents/` tree). `zip` works; if it isn't installed,
   use Python's stdlib:

   ```sh
   python3 - <<'PY'
   import zipfile, os
   paths = ["metadata.json"]
   for root, _, files in os.walk("contents"):
       for f in files:
           if not f.endswith(".bak"):
               paths.append(os.path.join(root, f))
   with zipfile.ZipFile("sysgraph.plasmoid", "w", zipfile.ZIP_DEFLATED) as z:
       for p in sorted(paths):
           z.write(p, p)
   PY
   ```

   Verify it: `kpackagetool6 --type Plasma/Applet --show ./sysgraph.plasmoid`

4. Create the GitHub release and attach the package:

   ```sh
   gh release create vX.Y --title "vX.Y" --notes "..."
   gh release upload vX.Y sysgraph.plasmoid --clobber
   ```

The built `*.plasmoid` is git-ignored; it lives on the release, not in the tree.

Local install for testing: `kpackagetool6 --type Plasma/Applet --install .`
(use `--upgrade .` to reinstall over an existing copy).

## 2. List on the KDE Store

Publishing is a web upload under your store.kde.org (Pling / OpenDesktop)
account — there is no CLI for it.

1. Sign in at <https://store.kde.org/> → avatar menu → **Add Product**.
2. Category: **Plasma 6 Add-Ons → Plasmoid (Plasma Widget)**.
3. Fill in the fields below.
4. Upload the `.plasmoid` file (keep the name so KNewStuff recognises the type).
5. Upload the screenshots from `screenshots/`.
6. Publish. After approval it appears in Plasma under
   **Add Widgets → Get New Widgets → Download New Plasma Widgets**.

### Listing fields

| Field | Value |
|---|---|
| Title | System Graph Gauge |
| Category | Plasma 6 Add-Ons → Plasmoid (Plasma Widget) |
| License | GPL-3.0-or-later |
| Version | matches the release tag / `metadata.json` |
| Summary | A panel gauge with a live history graph and per-sensor breakdown on click. |
| Homepage / Source | https://github.com/OmarAlzand/sysgraph-plasmoid |
| File | `sysgraph.plasmoid` (or the release asset URL) |
| Screenshots | `screenshots/popup.png`, `screenshots/panel.png` |

**Tags:** `plasma, plasma6, plasmoid, widget, system-monitor, cpu, memory, temperature, sensors, ksystemstats, chart, graph, panel`

### Description

> A KDE Plasma 6 panel widget that shows a system sensor as a plain number in the
> panel, and opens a live history graph plus a per-sensor breakdown when you click it.
>
> Plasma's stock System Monitor applet shares one "face" between the panel and the
> popup, so you can't have a compact number in the panel **and** a rich graph on
> click. This widget separates the two.
>
> **Panel:** an accent-coloured icon and the sensor's current value, scaled to the
> panel height so it stays crisp at any resolution.
>
> **Click:** a header (accent dot, title, large value), a 60-sample history line
> chart (fixed or auto-scaled), and a breakdown of related sensors with optional
> mini-bars (e.g. per-core CPU usage).
>
> Configurable per instance: title, panel glyph, main sensor, accent colour, chart
> maximum, auto-scale, and the breakdown sensor list. Works with any ksystemstats
> sensor; add several instances for CPU, temperature, memory, and more.
>
> GPL-3.0-or-later. Source: https://github.com/OmarAlzand/sysgraph-plasmoid
