# MemoriNeko — Calico Hi-Res Replacement Spec (v5: full 5-stage redo)

## Why

The original calico cat character (`cat_slim.png` ... `cat_stuffed.png`,
the app's default breed) only ever existed as tiny 44×44px source images,
hand-placed with a lot of empty canvas margin (~70-80% fill). That's
workable for the menu bar, but it means:

- The macOS app icon (built by upscaling `cat_normal.png` to 1024px) is
  visibly blurry — it was never drawn at high resolution to begin with.
- Any other big display of the calico (website hero image, etc.) is
  blurry for the same reason.
- The app currently has a special-cased 1.3x digital "overscan" zoom
  hack (see `CatBreed.swift` → `overscan`) applied only to the calico at
  runtime, just to make it look roughly as big as the other 4 breeds in
  the menu bar — a band-aid for the fact the old art doesn't fill the
  canvas like the newer breeds do.

The 4 other breeds (`cat_black`, `cat_tabby`, `cat_hachiware`,
`cat_exotic`) were all done properly: drawn/rendered at high resolution
(~1254px) as "masters," then downscaled with anti-aliasing to crisp 44px
menu bar icons that fill ~90-95% of the canvas. **This spec asks for the
same treatment for the calico**, replacing all 5 stages so the whole set
is consistent, and the 1.3x overscan hack can be deleted from the code
once these land.

## What we need

Re-render the existing calico character, keeping the design 100%
identical, at all 5 expression stages, as high-resolution masters:

Reference file: `design-reference/original_character_cat_normal.png`
(the calico "normal" stage — round white face, orange patch over the
left ear/side of the head, dark gray/black patch over the right
ear/side, small black dot eyes, tiny open smile, light pink cheek blush,
white whiskers, bold black outline, flat cel-shaded coloring).

For expression reference at each stage, use the existing
`cat_slim.png` / `cat_normal.png` / `cat_chubby.png` / `cat_plump.png` /
`cat_stuffed.png` (in `Sources/memo-neko/Resources/`) and
`IMAGE_SPEC.md`'s stage descriptions — this is **not a redesign**, it's a
clean high-res re-draw of the exact same 5 expressions:

| Stage | Expression |
|---|---|
| slim | Relaxed, content. Eyes open and round, calm/neutral or slight smile. No sweat. |
| normal | Happy, satisfied — pleasant smile, round eyes, light cheek blush. |
| chubby | Eyes squint slightly, mouth flatter/smaller, cheeks a bit more flushed, one small sweat drop. |
| plump | Eyes half-closed / strained, wavy "つらい" mouth, 2 sweat drops, cheeks notably flushed. |
| stuffed | Eyes as swirls or X's, mouth open in a strained wavy line, heavy sweat, deep red cheeks. Still cute, not scary. |

Keep the head size, shape, ear shape, calico color placement, and
position **100% fixed across all 5 stages** — only the expression
elements (eyes/mouth/sweat/blush) change, exactly like the current set
and like the other 4 breeds.

## Format requirements (match the other breeds' pipeline exactly)

- Provide both a high-res **master** (for the hero/app-icon use case) and
  the downscaled **44×44px menu bar version** for each stage, same as the
  `v2-smooth` deliverable for the other breeds:
  - Master: ~1200-1300px square, transparent background
  - Menu bar version: 44×44px, transparent background, anti-aliased
    Lanczos-style downscale from the master (not a naive resize)
- **Fill ~90-95% of the canvas** with the character at both sizes — this
  is the key fix vs. the old art's ~70-80% fill. Consistent across all 5
  stages so the head doesn't visibly grow/shrink/shift between stages.
- Same bold black outline weight and flat cel-shaded style as the
  current calico and the other 4 breeds — this should read as "the same
  character, just crisper," not a new design.

## Output location

```
Sources/memo-neko/Resources/cat_slim.png       (44px, replaces existing)
Sources/memo-neko/Resources/cat_normal.png     (44px, replaces existing)
Sources/memo-neko/Resources/cat_chubby.png     (44px, replaces existing)
Sources/memo-neko/Resources/cat_plump.png      (44px, replaces existing)
Sources/memo-neko/Resources/cat_stuffed.png    (44px, replaces existing)

design-reference/masters/cat_calico_slim.png       (~1254px master)
design-reference/masters/cat_calico_normal.png     (~1254px master)
design-reference/masters/cat_calico_chubby.png     (~1254px master)
design-reference/masters/cat_calico_plump.png      (~1254px master)
design-reference/masters/cat_calico_stuffed.png    (~1254px master)
```

10 files total (5 menu-bar-size + 5 masters). The masters are also what
the website will use for the hero image and app icon rebuild, so keep
those as the true high-res source rather than a re-upscale of the 44px
version.

## Note for whoever wires this in afterward

Once these land: replace the 5 files in `Sources/memo-neko/Resources/`,
then in `Sources/memo-neko/CatBreed.swift` change `case .calico: return 1.3`
to `1.15` (matching the other 4 breeds) in the `overscan` property, since
the new art will already fill the canvas properly and won't need the old
zoom hack. Also worth rebuilding `AppIcon.icns` from the new
`cat_calico_normal` master so the Dock/Finder icon stops being blurry too.
