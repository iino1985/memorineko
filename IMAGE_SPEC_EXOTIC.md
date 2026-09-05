# MemoriNeko — Exotic Shorthair Breed Image Spec (v4: new head shape)

## Concept

Add a 5th selectable cat to MemoriNeko: **エキゾチック (Exotic Shorthair)** —
the "smooshed face" breed (think Garfield / the flat-faced Persian-type
cat). Unlike the previous 3 breeds (`cat_black`, `cat_tabby`,
`cat_hachiware`), which reused the calico's exact head/ear shape and only
changed fur color, **this one is a different head silhouette on purpose**
— that's what makes it instantly recognizable at tiny menu-bar size next
to the other 4 (round-headed pointy-eared cats).

## What makes it "Exotic Shorthair" — the head shape brief

Design a new head template with these traits, all exaggerated enough to
read clearly at ~18-22pt on screen:

- **Very round, wide head** — rounder and wider relative to height than
  the existing cats, almost a circle/dome shape rather than the existing
  cats' slightly-tapered rounded-triangle head.
- **Tiny ears, set low and wide** — small rounded ears positioned low on
  the sides of the head (not tall/pointed like the other 4 breeds), so
  little of the ear is visible from the front — this is a key silhouette
  difference from the other breeds.
- **Flat, short muzzle** — little to no nose projection; the nose reads
  as a small shape almost flush with the face, not a triangle poking out.
  No visible separate muzzle bump — the face is one smooth round shape
  from forehead to chin.
- **Huge round eyes** — noticeably bigger than the other breeds' eyes,
  taking up a larger share of the face. This is the main expression
  engine for this breed (see stages below) and also the character's
  main "cute" selling point.
- **Same art style as the other cats**: flat/cel-shaded coloring, same
  bold black outline weight, same overall cuteness level, same whisker
  style. It should clearly belong to the same icon family despite the
  different proportions — same construction technique, different blueprint.

## Fur color

Solid soft gray/silver-blue coat (the classic "blue" Exotic Shorthair
color) — this is a color none of the other 4 breeds use yet (calico=mixed,
black=black, tabby=orange, hachiware=black+white), so it stays visually
distinct in the picker. Eyes: copper/orange, which is the classic Exotic
eye color and contrasts nicely against the gray fur. White whiskers.

## 5 expression stages

Same slim → normal → chubby → plump → stuffed progression concept as the
other breeds (see `IMAGE_SPEC.md` for the original philosophy), adapted to
this breed's already-huge eyes and flat face:

| Stage | File | Expression |
|---|---|---|
| slim | `cat_exotic_slim.png` | Calm, relaxed. Big round eyes open normally, neutral or very faint smile. No sweat, no blush. |
| normal | `cat_exotic_normal.png` | Content/happy. Same big round eyes, pleasant open smile, light cheek blush. |
| chubby | `cat_exotic_chubby.png` | Starting to strain. Eyelids droop slightly over the big eyes (still round, just partially lowered), mouth flatter, one small sweat drop, cheeks a bit more flushed. |
| plump | `cat_exotic_plump.png` | Uncomfortable. Eyes half-closed or squeezed into a strained shape, wavy/flat "つらい" mouth, 2 sweat drops, cheeks notably red. |
| stuffed | `cat_exotic_stuffed.png` | Overwhelmed. Eyes as swirls or X's (this breed's giant eyes make this read especially well — lean into it), mouth open in a strained wavy line, heavy sweat, deep red cheeks. Still cute/funny, not scary. |

Keep the head size, shape, and position **100% fixed across all 5
stages** — only the eyes/mouth/sweat/blush change, exactly like the other
breeds' expression logic.

## Format requirements (same as other breeds)

- Canvas size: 44×44 px, square, transparent background
- **Fill ~90-95% of the canvas** with the character (including ear tips
  and whisker tips) — leave only a couple of pixels of transparent
  margin. This is the lesson learned from the other breeds: the original
  calico art only filled ~70-80% and looked visibly smaller once live in
  the menu bar, and even the v2-smooth black/tabby/hachiware set (~95%
  fill) still reads slightly smaller than the calico because the calico
  gets an extra 1.3x digital zoom at runtime — so this new breed should
  fill the canvas at least as fully as the v2-smooth set, ideally
  slightly more, so it doesn't need a bigger zoom correction afterward.
- This sizing must be consistent across all 5 stages — the head shouldn't
  visibly grow/shrink/shift between stages, only the expression changes.
- Bold, simple, high-contrast linework — avoid fine detail that
  disappears at tiny size.

## Output location

```
Sources/memo-neko/Resources/cat_exotic_slim.png
Sources/memo-neko/Resources/cat_exotic_normal.png
Sources/memo-neko/Resources/cat_exotic_chubby.png
Sources/memo-neko/Resources/cat_exotic_plump.png
Sources/memo-neko/Resources/cat_exotic_stuffed.png
```

5 images total. The app's breed-picker UI and file-loading logic already
have an "エキゾチック" entry wired up (menu bar → "猫の種類を選ぶ" → 三毛猫 / 黒猫 /
茶トラ / ハチワレ / エキゾチック) — it just needs these 5 PNG files dropped into
the Resources folder above to light up. Until then it silently falls back
to the existing placeholder icon, so there's no rush/no broken state.
