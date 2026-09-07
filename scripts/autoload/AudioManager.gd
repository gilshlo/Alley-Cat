extends Node
## Music and SFX are independent buses. Native MIDI playback is not assumed:
## register a licensed rendered OGG/WAV/MP3 to replace the synthesized score.

const SAMPLE_RATE: int = 22050
const VOICE_COUNT: int = 10
var muted: bool = false
var _music: Array[AudioStreamPlayer] = []
var _voices: Array[AudioStreamPlayer] = []
var _tracks: Dictionary = {}
var _effects: Dictionary = {}
var _active_music: int = 0
var _next_voice: int = 0
var _current_track: StringName = &""
var _crossfade: Tween
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_bus(&"Music", -12.0)
	_ensure_bus(&"SFX", -6.0)
	for index: int in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"Music"
		player.finished.connect(_on_music_finished.bind(index))
		add_child(player)
		_music.append(player)
	for index: int in range(VOICE_COUNT):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = &"SFX"
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(voice)
		_voices.append(voice)
	_effects[&"jump"] = _tone(310.0, 700.0, 0.12)
	_effects[&"launch"] = _tone(190.0, 1050.0, 0.23)
	_effects[&"grab"] = _tone(640.0, 420.0, 0.07)
	_effects[&"hit"] = _tone(180.0, 45.0, 0.20)
	_effects[&"collect"] = _tone(660.0, 1320.0, 0.13)
	_effects[&"win"] = _tone(390.0, 1560.0, 0.48)
	_effects[&"lose"] = _tone(380.0, 65.0, 0.60)
	_effects[&"bark"] = _tone(100.0, 55.0, 0.16)
	_effects[&"land"] = _tone(92.0, 43.0, 0.065)
	_effects[&"step"] = _tone(80.0, 50.0, 0.03)
	_effects[&"can"] = _can_clink()
	_tracks[&"alley"] = _alley_score()
	_tracks[&"room"] = _melody([60, 67, 65, 63, 58, 65, 63, 62], 0.18)
	_tracks[&"vacuum"] = _melody([48, 60, 55, 58, 50, 62, 57, 60], 0.16)
	for track: StringName in [&"alley", &"room", &"vacuum"]:
		var path: String = "res://assets/audio/%s.ogg" % track
		if ResourceLoader.exists(path):
			register_track(track, load(path) as AudioStream)


func register_track(track_id: StringName, stream: AudioStream) -> void:
	if stream == null:
		push_warning("Cannot register a null music stream")
		return
	_tracks[track_id] = stream


func _on_music_finished(index: int) -> void:
	if index == _active_music:
		_music[index].play()


func _exit_tree() -> void:
	stop_all()
	_tracks.clear()
	_effects.clear()


func stop_all() -> void:
	if is_instance_valid(_crossfade):
		_crossfade.kill()
	for player: AudioStreamPlayer in _music + _voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_current_track = &""


func play_music(track_id: StringName, fade_seconds: float = 0.4) -> void:
	if not _tracks.has(track_id) or track_id == _current_track:
		return
	if is_instance_valid(_crossfade):
		_crossfade.kill()
	var outgoing: AudioStreamPlayer = _music[_active_music]
	_active_music = 1 - _active_music
	var incoming: AudioStreamPlayer = _music[_active_music]
	incoming.stop()
	incoming.stream = _tracks[track_id] as AudioStream
	incoming.volume_db = -60.0
	incoming.play()
	_current_track = track_id
	_crossfade = create_tween().set_parallel(true)
	_crossfade.tween_property(outgoing, "volume_db", -60.0, maxf(0.01, fade_seconds))
	_crossfade.tween_property(incoming, "volume_db", 0.0, maxf(0.01, fade_seconds))
	_crossfade.chain().tween_callback(outgoing.stop)


func play_sfx(effect: StringName, pitch: float = 1.0, variation: float = 0.07) -> void:
	if not _effects.has(effect):
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICE_COUNT
	voice.stop()
	voice.stream = _effects[effect] as AudioStream
	voice.volume_db = -18.0 if effect == &"step" else 0.0
	voice.pitch_scale = clampf(pitch + _rng.randf_range(-absf(variation), absf(variation)), 0.25, 3.0)
	voice.play()


func set_bus_volume(bus: StringName, linear_volume: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear_volume, 0.0001, 1.0)))


func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), value)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"SFX"), value)


func _ensure_bus(bus: StringName, decibels: float) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, decibels)
	if bus == &"SFX":
		AudioServer.add_bus_effect(index, AudioEffectLimiter.new())


func _tone(start_hz: float, end_hz: float, seconds: float) -> AudioStreamWAV:
	var count: int = int(seconds * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var oscillator: float = 0.0
	for sample: int in range(count):
		var progress: float = float(sample) / float(count)
		oscillator += lerpf(start_hz, end_hz, progress) / SAMPLE_RATE
		var envelope: float = minf(progress * 30.0, 1.0) * pow(1.0 - progress, 1.4)
		var value: float = (1.0 if fposmod(oscillator, 1.0) < 0.35 else -1.0) * envelope * 0.24
		data.encode_s16(sample * 2, int(value * 32767.0))
	return _wav(data, false)


func _melody(notes: Array, beat: float) -> AudioStreamWAV:
	# Original fallback composition, not a transcription of commercial audio.
	var samples_per_note: int = int(beat * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples_per_note * notes.size() * 2)
	for note_index: int in range(notes.size()):
		var frequency: float = 440.0 * pow(2.0, (float(notes[note_index]) - 69.0) / 12.0)
		for sample: int in range(samples_per_note):
			var time: float = float(sample) / SAMPLE_RATE
			var envelope: float = minf(time * 100.0, 1.0) * maxf(0.0, 1.0 - time / beat)
			var lead: float = 1.0 if fposmod(time * frequency, 1.0) < 0.25 else -1.0
			var bass: float = sin(TAU * time * frequency * 0.5)
			data.encode_s16((note_index * samples_per_note + sample) * 2, int((lead * 0.15 + bass * 0.12) * envelope * 32767.0))
	return _wav(data, true)


func _wav(data: PackedByteArray, looping: bool) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = data.size() / 2
	return stream


func _can_clink() -> AudioStreamWAV:
	var count: int = int(0.18 * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for sample: int in range(count):
		var time: float = float(sample) / SAMPLE_RATE
		var envelope: float = minf(time * 500.0, 1.0) * exp(-time * 28.0)
		var metal: float = sin(TAU * time * 773.0) * 0.12 + sin(TAU * time * 1373.0) * 0.07 + sin(TAU * time * 2081.0) * 0.03
		data.encode_s16(sample * 2, int(metal * envelope * 32767.0))
	return _wav(data, false)


func _alley_score() -> AudioStreamWAV:
	# An original eight-bar theme: swung lead, walking bass and a quiet tick.
	# Registered soundtrack assets still override this synthesized fallback.
	var melody: Array[int] = [69, 0, 72, 76, 74, 72, 71, 0, 69, 72, 76, 79, 76, 72, 71, 0, 69, 74, 77, 76, 74, 72, 69, 0, 65, 69, 74, 77, 76, 74, 72, 0, 69, 72, 77, 76, 72, 69, 67, 0, 68, 71, 76, 74, 71, 68, 64, 0, 67, 71, 74, 77, 74, 71, 68, 0, 76, 74, 71, 68, 69, 0, 64, 0]
	var roots: Array[int] = [45, 45, 50, 50, 53, 52, 47, 52]
	var samples_per_pair: int = int(0.45 * SAMPLE_RATE)
	var long_note: int = int(0.25 * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples_per_pair * 32 * 2)
	var write_index: int = 0
	for step: int in range(melody.size()):
		var count: int = long_note if step % 2 == 0 else samples_per_pair - long_note
		var duration: float = float(count) / SAMPLE_RATE
		var frequency: float = 440.0 * pow(2.0, (float(melody[step]) - 69.0) / 12.0)
		var bass_note: int = roots[step / 8] + (7 if step % 4 >= 2 else 0)
		var bass_frequency: float = 440.0 * pow(2.0, (float(bass_note) - 69.0) / 12.0)
		for sample: int in range(count):
			var time: float = float(sample) / SAMPLE_RATE
			var envelope: float = minf(time * 180.0, 1.0) * pow(maxf(0.0, 1.0 - time / duration), 1.4)
			var phase_angle: float = TAU * time * frequency
			var lead: float = (sin(phase_angle) + sin(phase_angle * 3.0) * 0.30 + sin(phase_angle * 5.0) * 0.13) * 0.15 if melody[step] > 0 else 0.0
			var bass: float = sin(TAU * time * bass_frequency) * 0.18
			var tick: float = sin(TAU * time * 5100.0) * exp(-time * 150.0) * 0.016
			data.encode_s16(write_index * 2, int(((lead + bass) * envelope + tick) * 32767.0))
			write_index += 1
	return _wav(data, true)
