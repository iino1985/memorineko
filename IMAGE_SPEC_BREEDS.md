# MemoriNeko — Cat Breed Variants Image Spec (v3: new breeds)

## Concept

MemoriNeko now lets the user pick which cat character lives in the menu
bar, independent of the memory/CPU/battery expression logic that's already
built (see `IMAGE_SPEC.md` for that base spec — it still fully applies to
the expression progression). This spec is only about **3 new fur
patterns/breeds** to add alongside the existing calico cat.

## New breeds to produce

| # | Breed (JP) | File prefix | Fur description |
|---|---|---|---|
| 1 | 黒猫 (black cat) | `cat_black` | Solid black fur all over. Keep enough visual separation between fur/outline/features at tiny size — use a soft dark-gray or very subtle lighter sheen on the fur if needed so the silhouette doesn't turn into a flat black blob, but the fur reads as black overall. White whiskers. Eyes can be a warm yellow-green to pop against the black fur. |
| 2 | 茶トラ (orange tabby) | `cat_tabby` | Warm orange/ginger base fur with darker orange-brown tabby stripe markings (classic mackerel or classic tabby stripe pattern) on the head. Optional small white patch on the muzzle/chin for contrast. Eyes: green or amber. |
| 3 | ハチワレ (hachiware / "figure-8" tuxedo) | `cat_hachiware` | White base fur with a black patch covering the top of the head and ears like a cap, split down the middle above the nose so it reads as two black "islands" (the classic hachiware figure-8 forehead pattern). Rest of the face (cheeks, muzzle, chin) stays white. Eyes: green or blue. |

For each breed, produce the same 5 expression stages as the base spec —
same file-naming stage suffixes:

```
Sources/memo-neko/Resources/cat_black_slim.png
Sources/memo-neko/Resources/cat_black_normal.png
Sources/memo-neko/Resources/cat_black_chubby.png
Sources/memo-neko/Resources/cat_black_plump.png
Sources/memo-neko/Resources/cat_black_stuffed.png

Sources/memo-neko/Resources/cat_tabby_slim.png
Sources/memo-neko/Resources/cat_tabby_normal.png
Sources/memo-neko/Resources/cat_tabby_chubby.png
Sources/memo-neko/Resources/cat_tabby_plump.png
Sources/memo-neko/Resources/cat_tabby_stuffed.png

Sources/memo-neko/Resources/cat_hachiware_slim.png
Sources/memo-neko/Resources/cat_hachiware_normal.png
Sources/memo-neko/Resources/cat_hachiware_chubby.png
Sources/memo-neko/Resources/cat_hachiware_plump.png
Sources/memo-neko/Resources/cat_hachiware_stuffed.png
```

15 images total. Partial delivery is fine — any breed/stage that isn't
supplied falls back to the calico version's programmatic placeholder icon,
so ship whichever ones are ready first (recommend finishing all 5 stages
of one breed at a time, rather than 1 stage across all breeds, so each
breed is usable as soon as its set is done).

## Character reference (must match exactly except fur color/pattern)

Use `design-reference/original_character_cat_normal.png` (the existing
calico "normal" stage) as the base silhouette: same head size/shape, same
ear shape and size, same overall proportions, same linework style and
weight, same 44×44px framing, same cute mascot art style. **Only the fur
color/pattern and eye color change per breed** — everything else
(head shape, ear shape, whisker style, line style) must stay identical to
the calico reference so the 4 breeds clearly read as "the same character
design, different coat," not 4 unrelated characters.

Within each breed, reuse the calico's per-stage expression reference from
`IMAGE_SPEC.md` (eyes, mouth, sweat drops, cheek blush progression —
slim → normal → chubby → plump → stuffed) applied on top of that breed's
fur. Cheek blush and the amber/red accent colors used in the `plump` and
`stuffed` stages should still be visible layered on top of black or
tabby fur (e.g. a rosy tint over the cheek fur, not just skin) — check
this especially for the black breed where a same-color blush could
disappear.

## IMPORTANT fix vs. the original calico art: fill more of the canvas

The existing calico images only use about 70-80% of the 44×44 canvas
(lots of empty transparent margin around the character), which makes the
icon look noticeably smaller than other menu bar app icons once it's
composited live. We're band-aiding that at runtime with a 1.3x digital
zoom, but that already introduces slight cropping/softness — **so please
draw these new breeds bigger from the start**:

- Character (including ear tips and whisker tips) should fill roughly
  **90-95% of the 44×44 canvas**, leaving only a couple of pixels of
  transparent margin, not the ~20% margin the old calico art has.
- Keep the whole head + ears inside the canvas (don't crop ears off) —
  just minimize the surrounding empty space.
- This sizing must be consistent across all 5 stages of a breed so the
  character doesn't visibly grow/shrink/shift when the expression
  changes — only the expression elements (eyes/mouth/sweat/blush) differ
  between stages, exactly like the calico set.

## Format requirements (same as base spec)

- Canvas size: 44×44 px, square
- Background: transparent PNG
- Full color, flat/cel-shaded style matching the calico reference
- Bold, simple, high-contrast linework — this renders at ~18-22pt in the
  real menu bar, so avoid fine detail that disappears at that size
- Style: cute mascot illustration, same cuteness level as the calico set

## Output location

```
Sources/memo-neko/Resources/cat_black_*.png
Sources/memo-neko/Resources/cat_tabby_*.png
Sources/memo-neko/Resources/cat_hachiware_*.png
```

The app already has the breed-picker UI and file-loading logic wired up
(menu bar → "猫の種類を選ぶ" → 三毛猫 / 黒猫 / 茶トラ / ハチワレ), it just needs these
PNG files dropped into the Resources folder above to light up.
