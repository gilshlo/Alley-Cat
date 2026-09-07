extends Node
## Sole owner of run data. Rooms report a result with an attempt token, so
## duplicate physics callbacks cannot award points or consume lives twice.

enum RoomId { CHEESE, BIRDCAGE, FISHBOWL, LIBRARY, ROBOT_VACUUM }
enum Phase { ALLEY, ROOM, TRANSITION, GAME_OVER }

const ROOM_NAMES: PackedStringArray = ["Cheese & Mice", "Birdcage", "Fishbowl", "Library Vases", "Robot Vacuum"]
const ALLEY_SCENE: String = "res://scenes/Alley.tscn"
const CLASSIC_SCENE: String = "res://scenes/RoomClassic.tscn"
const VACUUM_SCENE: String = "res://scenes/RoomRobotVacuum.tscn"
const STARTING_LIVES: int = 3

var score: int = 0
var lives: int = STARTING_LIVES
var level_multiplier: int = 1
var current_room: int = -1
var attempt_id: int = 0
var phase: Phase = Phase.ALLEY
var completed_rooms: Dictionary = {}
var alley_spawn: Vector2 = Vector2(60.0, 360.0)
var _fade: ColorRect
var _transition_layer: CanvasLayer
var _fade_tween: Tween
var _quitting: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	_install_inputs()
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100
	add_child(_transition_layer)
	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0.02, 0.02, 0.05, 0.0)
	_transition_layer.add_child(_fade)
	EventBus.run_started.emit.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _quitting:
		_quitting = true
		_quit_cleanly.call_deferred()


func _quit_cleanly() -> void:
	get_tree().paused = true
	AudioManager.stop_all()
	# Let the audio thread release its final playback buffer before shutdown.
	await get_tree().create_timer(0.08, true, false, true).timeout
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and phase == Phase.GAME_OVER:
		restart_run()
	elif event.is_action_pressed("pause") and phase != Phase.TRANSITION and phase != Phase.GAME_OVER:
		get_tree().paused = not get_tree().paused
		EventBus.notification.emit("PAUSED - Esc to resume" if get_tree().paused else "")
	elif event.is_action_pressed("mute"):
		AudioManager.set_muted(not AudioManager.muted)


func can_enter_room(room_id: int) -> bool:
	return phase == Phase.ALLEY and room_id >= 0 and room_id < ROOM_NAMES.size() and not completed_rooms.has(room_id)


func enter_room(room_id: int, return_position: Vector2) -> bool:
	if not can_enter_room(room_id):
		return false
	alley_spawn = Vector2(clampf(return_position.x, 30.0, 610.0), 360.0)
	current_room = room_id
	attempt_id += 1
	phase = Phase.TRANSITION
	EventBus.room_entered.emit(room_id, attempt_id)
	_switch_scene.call_deferred(VACUUM_SCENE if room_id == RoomId.ROBOT_VACUUM else CLASSIC_SCENE, Phase.ROOM)
	return true


func finish_room(won: bool, base_points: int, token: int) -> void:
	if phase != Phase.ROOM or token != attempt_id:
		return
	phase = Phase.TRANSITION
	var awarded: int = maxi(base_points, 0) * level_multiplier if won else 0
	if won:
		completed_rooms[current_room] = true
		score += awarded
		AudioManager.play_sfx(&"win")
	else:
		lives = maxi(lives - 1, 0)
		AudioManager.play_sfx(&"lose")
		EventBus.lives_changed.emit(lives)
	EventBus.room_finished.emit(current_room, won, awarded)
	if completed_rooms.size() == ROOM_NAMES.size():
		completed_rooms.clear()
		level_multiplier += 1
	EventBus.score_changed.emit(score, level_multiplier)
	if lives == 0:
		_end_run()
	else:
		_switch_scene.call_deferred(ALLEY_SCENE, Phase.ALLEY)


func hurt_in_alley() -> void:
	if phase != Phase.ALLEY:
		return
	lives = maxi(lives - 1, 0)
	EventBus.lives_changed.emit(lives)
	if lives == 0:
		_end_run()


func restart_run() -> void:
	if phase != Phase.GAME_OVER:
		return
	get_tree().paused = false
	score = 0
	lives = STARTING_LIVES
	level_multiplier = 1
	completed_rooms.clear()
	current_room = -1
	attempt_id += 1
	alley_spawn = Vector2(60.0, 360.0)
	phase = Phase.TRANSITION
	EventBus.run_started.emit()
	EventBus.score_changed.emit(score, level_multiplier)
	EventBus.lives_changed.emit(lives)
	_switch_scene.call_deferred(ALLEY_SCENE, Phase.ALLEY)


func _end_run() -> void:
	phase = Phase.GAME_OVER
	get_tree().paused = true
	EventBus.run_over.emit(score)
	EventBus.notification.emit("GAME OVER - R to restart")


func _switch_scene(scene_path: String, destination: Phase) -> void:
	# Deferred entry prevents freeing collision objects while physics is flushing.
	get_tree().paused = true
	if is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(_fade, "color:a", 1.0, 0.16)
	await _fade_tween.finished
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Unable to load scene %s: %s" % [scene_path, error_string(error)])
		_fade.color.a = 0.0
		_end_run()
		return
	await get_tree().scene_changed
	phase = destination
	if destination == Phase.ALLEY:
		current_room = -1
	get_tree().paused = false
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(_fade, "color:a", 0.0, 0.20)


func _install_inputs() -> void:
	# Preserve editor-defined actions; defaults make a fresh checkout playable.
	_bind(&"move_left", [KEY_A, KEY_LEFT])
	_bind(&"move_right", [KEY_D, KEY_RIGHT])
	_bind(&"jump", [KEY_SPACE, KEY_Z])
	_bind(&"grab", [KEY_W, KEY_UP])
	_bind(&"drop", [KEY_S, KEY_DOWN])
	_bind(&"interact", [KEY_E, KEY_ENTER])
	_bind(&"pause", [KEY_ESCAPE])
	_bind(&"restart", [KEY_R])
	_bind(&"mute", [KEY_M])


func _bind(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for keycode: int in keys:
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = keycode as Key
		InputMap.action_add_event(action, key)
