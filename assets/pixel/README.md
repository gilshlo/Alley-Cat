# Moonlight alley art

Six project-owned, native-resolution PNGs replace the original geometric alley
presentation. The pixel maps, palette, scene decoration and sprite poses are
authored in `tools/BuildAlleyArt.gd` and rasterized into PNGs; no external
image-generation API or downloaded artwork was used. Assets are built offline,
not rebuilt every time the game starts.

## Scope

This is the first alley-focused visual pass. The animated cat and bitmap HUD
are shared with the rooms; room backgrounds, furniture and collectibles still
use the original prototype presentation. The direction preserves the compact
arcade layout with a quiet cool facade, warm interactive windows, readable
silhouettes and restrained effects rather than blur or bloom.

## Asset sheets

| File | Dimensions | Contents |
| --- | --- | --- |
| `alley_backdrop.png` | 640 x 400 | Moon, skyline, facade, fence, lamps and pavement |
| `windows.png` | 320 x 80 | Four 80 x 80 frames: shut, open, illuminated, complete |
| `trash_cans.png` | 192 x 80 | Three 64 x 80 cans, with separately rendered lids |
| `laundry.png` | 192 x 40 | Six 32 x 40 garments |
| `cat_poses.png` | 384 x 32 | Twelve 32 x 32 poses |
| `dog_run.png` | 192 x 32 | Four 48 x 32 running poses |

Cat columns are idle, breath, blink, four running poses, ascent, descent, two
climbing poses and knockback. `CatVisual` selects frames from the actual FSM.
Squash/stretch affects this child only, never the physics body. Sprites retain
nearest-neighbor filtering. Clothesline sensors, can surfaces and window entry
rectangles have not changed.

The palette is built around ink `#101724`, slate `#2e3d4c`, teal `#547080`, warm
cream `#edd6aa`, faded rose `#956980`, and amber `#dfa760`. Foreground highlights
are brighter than the quiet facade, and warm windows communicate availability.

## Runtime integration

| Component | Responsibility |
| --- | --- |
| `CatVisual` | FSM-driven poses and visual-only landing squash |
| `TrashCanVisual` | Independent lid rattle on landing and launching |
| `Clothesline` | Garment selection and pixel-aligned sway |
| `AlleyWindow` | Window frames, entry prompts and throw warnings |
| `StreetDog` | Four-frame running animation |
| `AlleyAtmosphere` | Light accents, ambient motes and capped dust particles |
| `GameHUD` / `PixelFont` | Bitmap text, controls, room objectives and overlays |

## Rebuild the assets

Run from the project root after editing the authored maps or backdrop. These
commands assume the local portable engine exists; on a fresh checkout use your
own Godot 4.5+ executable path:

```powershell
& '.\.tools\godot\Godot_v4.5.1-stable_win64_console.exe' --headless --path . --script res://tools/BuildAlleyArt.gd
& '.\.tools\godot\Godot_v4.5.1-stable_win64_console.exe' --headless --path . --editor --import --quit
```

The HUD uses the custom 5 x 7 alphabet in `scripts/presentation/PixelFont.gd`,
not a system font. Art can be edited directly in a pixel editor instead; do not
rerun the builder afterwards unless its source has also been updated, because
the builder intentionally overwrites these six outputs.

Keep the PNGs and their `.import` settings in source control. Do not publish
the generated `.godot` cache or the local portable engine with the source.

## Visual review

The current rendered references are `docs/alley-preview.png` and
`docs/alley-active.png`, both at the native 640 x 400 resolution. They are actual
game renders, not mockups; the active view stages a hanging pose and a dog to
show the interaction presentation.

After an art change, check the alley at integer scaling, all cat poses, can-lid
alignment, clothesline grabs, illuminated-window prompts, dog/broom warnings,
and pause/game-over panels. Check a classic room and the vacuum room as well:
shared cat/HUD changes must not hide their instructions or affect collisions.

Approve the alley's appearance and movement in human playtesting before
expanding the same treatment to all room scenery. The recorded 44 gameplay
checks are useful regressions, not a substitute for this visual review.
