# MemoriNeko — Cat Icon Image Spec (v2: expression-based)

## Concept

MemoriNeko (メモリねこ) is a macOS menu bar app. A cat icon lives in the menu bar and its
**facial expression** gets visibly more strained/exhausted as Mac RAM usage
goes up. The whole point of the app: the user should be able to tell how
full their memory is just by glancing at the cat's face, without reading a
number.

> "As the Mac's memory fills up, the cat starts to look like it's struggling."

## Important change from v1

An earlier version tried to encode memory usage as **body/face width**
(the cat getting visually "fatter"). That failed in testing: at real
menu-bar icon size (~18pt, tiny) the width differences between adjacent
stages were imperceptible, and it also made the character less cute.

**This version replaces body-width with facial expression.** The character
itself — face shape, size, ear shape, fur color/pattern, overall cuteness —
must stay **100% identical and fixed** across all 5 images. Only the face's
expression elements (eyes, mouth, sweat drops, cheek blush) change.

## Character reference (must match exactly)

Use `design-reference/original_character_cat_normal.png` as the fixed
character design — same calico cat, same head size/shape, same ear shape,
same fur pattern and color palette, same linework style, same 44×44px
framing. This is not a "similar style" reference, it's the literal
character all 5 stages must reuse unchanged, differing only in expression.

## What we need

Five PNG images of the exact same cat, differing only in facial expression:

| # | File name | Stage (JP label) | Memory usage | Expression direction |
|---|---|---|---|---|
| 1 | `cat_slim.png` | シュッ (slim) | 0–40% | Relaxed, content. Eyes open and round, calm/neutral or slight smile. No sweat. |
| 2 | `cat_normal.png` | 普通 (normal) | 40–60% | Happy, satisfied. Same as the reference image — pleasant smile, round eyes, maybe a very light cheek blush. |
| 3 | `cat_chubby.png` | ちょいぽちゃ (a little much) | 60–75% | Starting to feel it. Eyes squint slightly (content-but-strained), mouth flatter/smaller, cheeks a bit more flushed. One small sweat drop appears. |
| 4 | `cat_plump.png` | ぽっちゃり (plump) | 75–90% | Uncomfortable. Eyes half-closed or a strained ">< " shape, mouth a wavy/flat "つらい" line, 2 sweat drops, cheeks notably flushed/red. |
| 5 | `cat_stuffed.png` | パンパン (stuffed/bursting) | 90–100% | Overwhelmed/maxed out. Eyes as swirls, X's, or squeezed shut in distress, mouth open in a strained wavy line, sweat dripping heavily, cheeks deep red. Comedic "about to burst" feeling — still cute/funny, not scary. |

The progression should read as one continuous story: calm → content →
slightly strained → uncomfortable → overwhelmed. Think of how a character
looks right before/during "I ate too much" — same body, only the face
tells the story.

## Format requirements

- **Canvas size:** 44×44 px, square (same as reference)
- **Background:** transparent PNG
- **Color:** full color, matching the reference character's existing palette
- **Face/head size and shape:** identical across all 5 — do not resize,
  stretch, or reshape the head/ears. Only expression elements (eyes,
  mouth, sweat, blush) change.
- **Style:** bold, simple, high-contrast — this renders very small
  (menu bar icon, ~18–22pt on screen), so keep linework clear and avoid
  anything too fine/thin to read at that size. Expression changes need
  to be big and obvious, not subtle.
- **Style:** cute mascot illustration matching the reference exactly —
  flat/cel-shaded coloring, same line weight, same overall cuteness.

## Output location

Place the final 5 files here (this will overwrite the current placeholder
files, which currently hold a different, exaggerated-body-width version
that's being replaced by this expression-based approach):

```
Sources/memo-neko/Resources/cat_slim.png
Sources/memo-neko/Resources/cat_normal.png
Sources/memo-neko/Resources/cat_chubby.png
Sources/memo-neko/Resources/cat_plump.png
Sources/memo-neko/Resources/cat_stuffed.png
```

Partial delivery is fine (the app falls back to a placeholder icon for any
missing stage), but for this expression-only approach it's especially
important that all 5 share the exact same base character so the "only the
face changes" effect actually reads.
