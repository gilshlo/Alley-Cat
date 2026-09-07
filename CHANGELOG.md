# Changelog

Development history for Alley Cat - Moonlight Mischief. The project remains
unreleased; dates identify development updates rather than published versions.

## 2026-09-06 - Documentation refresh

- Documented current scope: playable core, first alley visual pass, prototype
  room scenery, and remaining human playtesting/export/audio review.
- Added direct-play and editor-launch instructions, including fresh-checkout
  requirements and restarting an already-running game after updates.
- Embedded the actual alley screenshots in the main README.
- Expanded the audio asset contract with the current fallback tracks, effect
  IDs, bus behavior, original-track integration and a listening checklist.
- Expanded pixel-art documentation with component ownership, source provenance,
  asset rebuild instructions and a visual acceptance checklist.
- Clarified that the last recorded 44-check gameplay run is historical and the
  local `.tools` harness is not shipped source or a CI pipeline. Runtime tests
  were not rerun for this documentation-only update.

## 2026-09-05 - Playable core and first alley visual pass

### Core implementation

- Added typed Godot 4 GDScript singletons for events, run state, audio and
  deferred scene transitions with attempt-token validation.
- Added the cat's idle, walk, jump, climb and knockback states, buffered jumps,
  coyote time, trash-can launches, clothesline grabs and window entry.
- Added moving street dogs, rotating window states and thrown broom hazards.
- Implemented Cheese & Mice, Birdcage, Fishbowl, Library Vases and Robot Vacuum
  objectives, including vacuum top-landing capture and sleeping-dog alert.
- Added score multipliers, room completion, timeouts, lives, pause and restart.

### Presentation update

- Replaced the geometric alley presentation with six authored raster assets:
  backdrop, windows, trash cans, laundry, cat poses and dog run frames.
- Added a bitmap HUD, contextual prompts, preserved room instructions,
  warm-window accents, bounded particles, can-lid rattle and hazard warnings.
- Added twelve cat poses, four dog run poses, quiet footsteps, landing sounds,
  metallic can clinks and an original eight-bar alley chiptune fallback.
- Preserved the collision layout and jump tuning during the art pass.
- Saved actual native-resolution renders for the idle and active alley views.

### Validation and limitations

- Godot 4.5.1 imported the project and passed 44 local gameplay checks.
- Inspected rendered alley screenshots for presentation and prompt visibility.
- The original commercial soundtrack is not included. The room scenery still
  needs its art pass; human playtesting, final animation/mix review and desktop
  export validation remain outstanding.
