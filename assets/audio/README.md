# Music asset contract

The project is playable without audio files: `AudioManager` generates PCM
chiptunes and pitch-varied SFX at startup. These are original fallback
compositions/sounds, **not recordings or transcriptions of Alley Cat's music**.

## Current fallback audio

- `alley`: an eight-bar swung melody with bass and a quiet rhythmic tick.
- `room` and `vacuum`: short synthesized loops for the prototype rooms.
- Movement/action effects: `jump`, `launch`, `grab`, `hit`, and `collect`.
- Result/character effects: `win`, `lose`, and `bark`.
- Alley feedback: quiet `step` sounds, `land` impacts, and metallic `can` clinks.

Two players crossfade on the Music bus; ten pooled voices play on the SFX bus.
Pitch variation affects individual effects, not the music. Press M in-game to
mute/unmute both buses. The alley's presentation component triggers footsteps,
landing sounds and can clinks without changing the room noise/alert rules.

## Supply the original soundtrack

To preserve original music that you have permission to use, render/import:

| Path | Track ID | Use |
| --- | --- | --- |
| `res://assets/audio/alley.ogg` | `alley` | Alley hub |
| `res://assets/audio/room.ogg` | `room` | Four classic rooms |
| `res://assets/audio/vacuum.ogg` | `vacuum` | Robot vacuum room |

AudioManager automatically selects these imported files when available. Enable
Loop in the Godot importer for seamless native looping, then Reimport. A
non-looping supplied stream will restart through the player's finished signal.
Use clean loop boundaries and moderate headroom; Music and SFX have independent
bus gains. No soundtrack files or rights are supplied by this project.

## Register another imported format

Register an `AudioStream` explicitly before its first playback:

```gdscript
var recording: AudioStream = load("res://assets/audio/licensed_theme.wav") as AudioStream
AudioManager.register_track(&"alley", recording)
AudioManager.play_music(&"alley")
```

Register replacements before first playback. MIDI is not an audio recording:
render it to OGG/WAV with the intended instrument bank first, rather than changing
its extension. Runtime volume is available through
`AudioManager.set_bus_volume(&"Music", 0.5)` or the equivalent `&"SFX"` call.

## Audio review checklist

1. Import authorized recordings and verify each of the three track IDs.
2. Listen across loop boundaries and transitions between the alley and rooms.
3. Check relative music/SFX volume, repeated can launches, and overlapping sounds.
4. Verify M, pause/resume, restart, and closing the game window.

Automated gameplay checks exercise audio setup and mute behavior; they do not
establish perceptual mix quality or verify that a supplied recording is licensed.
