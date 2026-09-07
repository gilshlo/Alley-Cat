extends Node2D
## Owns alley-local timers and hazards; run data lives in GameManager.

var cat: Cat
var hud: GameHUD
var windows: Array[AlleyWindow] = []
var _can_bodies: Array[StaticBody2D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _dog_timer: float = 3.5
var _window_timer: float = 0.0
var _throw_timer: float = 4.0
var _window_cycle: int = 0
var _pending_direction: float = 0.0
var _pending_throw: AlleyWindow
var _throw_warning: float = 0.0

func _ready() -> void:
	_rng.randomize()
	var floor_body: StaticBody2D = WorldBuilder.bounds(self)
	floor_body.visible = false
	var backdrop: Sprite2D = Sprite2D.new()
	backdrop.texture = preload("res://assets/pixel/alley_backdrop.png")
	backdrop.centered = false
	backdrop.z_index = -50
	add_child(backdrop)
	for location: Vector2 in [Vector2(85, 331), Vector2(295, 316), Vector2(500, 331)]:
		var can: StaticBody2D = WorldBuilder.platform(self, Rect2(location, Vector2(46, 380 - location.y)), Color("506b79"))
		can.add_to_group(&"launch_pad")
		can.set_meta(&"launch_height", 155.0)
		can.visible = false
		_can_bodies.append(can)
	for height: float in [245.0, 157.0]:
		var line: Clothesline = Clothesline.new()
		line.position = Vector2(320, height)
		add_child(line)
	var window_positions: Array[Vector2] = [Vector2(108, 226), Vector2(318, 226), Vector2(523, 226), Vector2(215, 138), Vector2(425, 138)]
	for index: int in range(window_positions.size()):
		var window: AlleyWindow = AlleyWindow.new()
		window.position = window_positions[index]
		window.room_id = index
		window.enter_requested.connect(_on_window_enter_requested)
		add_child(window)
		windows.append(window)
	cat = Cat.new()
	cat.position = GameManager.alley_spawn
	cat.invulnerability = 2.0
	cat.z_index = 8
	cat.damaged.connect(GameManager.hurt_in_alley)
	add_child(cat)
	for index: int in range(_can_bodies.size()):
		var visual: TrashCanVisual = TrashCanVisual.new()
		visual.frame = index
		visual.platform = _can_bodies[index]
		visual.cat = cat
		visual.position = Vector2([85.0, 295.0, 500.0][index] - 9.0, [331.0, 316.0, 331.0][index] - 10.0)
		visual.z_index = 3
		add_child(visual)
	var atmosphere: AlleyAtmosphere = AlleyAtmosphere.new()
	atmosphere.cat = cat
	atmosphere.windows = windows
	atmosphere.z_index = 12
	add_child(atmosphere)
	hud = GameHUD.new()
	add_child(hud)
	hud.set_objective("ALLEY / Jump from cans. Hold W to grab lines. E enters a lit window.")
	_update_windows()
	AudioManager.play_music(&"alley")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameManager.phase != GameManager.Phase.ALLEY:
		return
	_dog_timer -= delta
	_window_timer -= delta
	_throw_timer -= delta
	if _dog_timer <= 0.7 and _pending_direction == 0.0:
		_pending_direction = 1.0 if _rng.randf() < 0.5 else -1.0
	if is_instance_valid(_pending_throw):
		_throw_warning -= delta
		if _throw_warning <= 0.0:
			_release_broom()
	if _dog_timer <= 0.0:
		_spawn_dog()
		_dog_timer = maxf(1.4, 4.2 - float(GameManager.level_multiplier) * 0.25) + _rng.randf_range(0.0, 1.2)
	if _window_timer <= 0.0:
		_update_windows()
		_window_timer = 4.0
	if _throw_timer <= 0.0:
		_throw_broom()
		_throw_timer = _rng.randf_range(3.5, 5.5) / minf(float(GameManager.level_multiplier), 2.5)
	_update_hint()
	queue_redraw()

func _spawn_dog() -> void:
	if get_tree().get_nodes_in_group(&"street_dogs").size() >= 4:
		_pending_direction = 0.0
		return
	var dog: StreetDog = StreetDog.new()
	dog.direction = _pending_direction if _pending_direction != 0.0 else (1.0 if _rng.randf() < 0.5 else -1.0)
	_pending_direction = 0.0
	dog.position = Vector2(-35 if dog.direction > 0 else 675, 369)
	dog.speed = 105.0 + minf(float(GameManager.level_multiplier) * 12.0, 90.0)
	dog.add_to_group(&"street_dogs")
	dog.z_index = 7
	add_child(dog)

func _update_windows() -> void:
	_window_cycle += 1
	var available: Array[AlleyWindow] = []
	for window: AlleyWindow in windows:
		if GameManager.completed_rooms.has(window.room_id):
			window.set_window_state(AlleyWindow.WindowState.COMPLETE)
		else:
			available.append(window)
	# Deterministic rotation guarantees every incomplete room gets a lit turn.
	for index: int in range(available.size()):
		var mode: int = (index + _window_cycle) % available.size()
		available[index].set_window_state(AlleyWindow.WindowState.ILLUMINATED if mode < 2 else (AlleyWindow.WindowState.OPEN if mode == 2 else AlleyWindow.WindowState.SHUT))

func _throw_broom() -> void:
	var candidates: Array[AlleyWindow] = []
	for window: AlleyWindow in windows:
		if window.window_state == AlleyWindow.WindowState.OPEN:
			candidates.append(window)
	if candidates.is_empty():
		return
	_pending_throw = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_pending_throw.warn_throw()
	_throw_warning = 0.65

func _release_broom() -> void:
	var broom: ThrownObject = ThrownObject.new()
	broom.position = _pending_throw.position
	broom.velocity = Vector2(clampf(cat.position.x - _pending_throw.position.x, -130.0, 130.0), -70.0)
	broom.z_index = 9
	add_child(broom)
	_pending_throw = null

func _update_hint() -> void:
	for window: AlleyWindow in windows:
		if window.window_state == AlleyWindow.WindowState.ILLUMINATED and window.overlaps_body(cat):
			hud.set_hint("E", GameManager.ROOM_NAMES[window.room_id])
			return
	if cat.state_id == Cat.State.CLIMB:
		hud.set_hint("S", "DROP / SPACE TO LEAP")
	elif cat.is_on_floor() and is_instance_valid(cat.floor_collider()) and cat.floor_collider().is_in_group(&"launch_pad"):
		hud.set_hint("SPACE", "SPRING FROM THE CAN")
	else:
		hud.set_hint("E", "FIND A LIT WINDOW")

func _on_window_enter_requested(room_id: int, return_position: Vector2) -> void:
	GameManager.enter_room(room_id, return_position)

func _draw() -> void:
	if _pending_direction != 0.0:
		var spot: Vector2 = Vector2(6 if _pending_direction > 0.0 else 607, 352)
		PixelFont.panel(self, Rect2(spot, Vector2(27, 18)), Color("493a3e"), PixelFont.GOLD)
		PixelFont.text(self, ">!" if _pending_direction > 0.0 else "!<", spot + Vector2(7, 5), PixelFont.PAPER)
