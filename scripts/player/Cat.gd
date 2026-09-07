class_name Cat
extends CharacterBody2D
## Logical positions remain subpixel for stable physics. The viewport snaps
## rendering to pixels; rounding the physics body would destroy small motions.

signal damaged()
signal landed(impact_speed: float, collider: Node)
signal state_changed(previous: int, current: int)
signal jumped(boosted: bool)

enum State { IDLE, WALK, JUMP, CLIMB, KNOCKBACK }

@export var run_speed: float = 148.0
@export var acceleration: float = 1000.0
@export var friction: float = 1400.0
@export var jump_height: float = 84.0
@export var time_to_apex: float = 0.38
@export var climb_speed: float = 100.0

var axis: float = 0.0
var facing: float = 1.0
var state_id: State = State.IDLE
var current_state: CatState
var gravity: float = 0.0
var jump_speed: float = 0.0
var coyote_time: float = 0.0
var jump_buffer: float = 0.0
var grab_lock: float = 0.0
var invulnerability: float = 0.0
var knockback_time: float = 0.0
var active_line: Clothesline
var water_mode: bool = false
var control_enabled: bool = true
var _states: Dictionary = {}
var _lines: Array[Clothesline] = []
var _windows: Array[AlleyWindow] = []


func _ready() -> void:
	add_to_group(&"cat")
	# Layers are bitmasks: world=1, cat=2, hazards=4, interactables=8,
	# clotheslines=16, moving platforms=32. Areas detect cat; cat hits solids.
	collision_layer = 2
	collision_mask = 1 | 32
	platform_floor_layers = 32
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY
	floor_snap_length = 3.0
	safe_margin = 0.04
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 6.0
	capsule.height = 18.0
	shape.shape = capsule
	add_child(shape)
	# h = g*t^2/2 and v0 = -g*t, so jump height/apex time are tunable.
	gravity = 2.0 * jump_height / (time_to_apex * time_to_apex)
	jump_speed = -2.0 * jump_height / time_to_apex
	_states = {State.IDLE: IdleState.new(), State.WALK: WalkState.new(), State.JUMP: JumpState.new(), State.CLIMB: ClimbState.new(), State.KNOCKBACK: KnockbackState.new()}
	for state: CatState in _states.values():
		state.cat = self
	current_state = _states[State.IDLE] as CatState
	current_state.enter()
	add_child(CatVisual.new())


func _physics_process(delta: float) -> void:
	invulnerability = maxf(invulnerability - delta, 0.0)
	grab_lock = maxf(grab_lock - delta, 0.0)
	jump_buffer = maxf(jump_buffer - delta, 0.0)
	coyote_time = 0.10 if is_on_floor() else maxf(coyote_time - delta, 0.0)
	axis = Input.get_axis("move_left", "move_right") if control_enabled else 0.0
	if axis != 0.0:
		facing = signf(axis)
	if control_enabled and Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	if control_enabled and Input.is_action_just_pressed("interact"):
		for window: AlleyWindow in _windows.duplicate():
			if is_instance_valid(window) and window.try_enter(self):
				return
	if control_enabled and Input.is_action_pressed("grab") and grab_lock == 0.0 and state_id == State.JUMP:
		_try_grab()
	var was_grounded: bool = is_on_floor()
	current_state.physics_update(delta)
	var impact_speed: float = velocity.y
	move_and_slide()
	if not was_grounded and is_on_floor() and impact_speed > 0.0:
		var floor_body: Node = floor_collider()
		landed.emit(impact_speed, floor_body)
		EventBus.cat_landed.emit(global_position, impact_speed)
	if state_id == State.JUMP and is_on_floor():
		change_state(State.WALK if axis != 0.0 else State.IDLE)
	if global_position.y > 450.0:
		global_position = Vector2(clampf(global_position.x, 30.0, 610.0), 350.0)
		velocity = Vector2.ZERO
		hurt(Vector2.UP)
	queue_redraw()


func change_state(next_state: State) -> void:
	if next_state == state_id:
		return
	var previous: State = state_id
	current_state.exit()
	state_id = next_state
	current_state = _states[next_state] as CatState
	current_state.enter()
	state_changed.emit(previous, next_state)


func apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * (0.22 if water_mode else 1.0) * delta, 90.0 if water_mode else 700.0)


func steer(delta: float, strength: float = 1.0) -> void:
	var target: float = axis * run_speed * (0.65 if water_mode else 1.0)
	velocity.x = move_toward(velocity.x, target, (acceleration if axis != 0.0 else friction) * strength * delta)


func consume_jump() -> bool:
	if jump_buffer <= 0.0 or not control_enabled:
		return false
	if coyote_time <= 0.0 and state_id != State.CLIMB and not water_mode:
		return false
	var pad: Node = floor_collider() if is_on_floor() else null
	var boosted: bool = is_instance_valid(pad) and pad.is_in_group(&"launch_pad")
	velocity.y = jump_speed * (0.40 if water_mode else 1.0)
	if boosted:
		# A pad launch uses v = sqrt(2*g*h), independently of normal jump height.
		velocity.y = -sqrt(2.0 * gravity * float(pad.get_meta(&"launch_height", 155.0)))
		velocity.x = axis * 225.0
		AudioManager.play_sfx(&"launch")
	else:
		AudioManager.play_sfx(&"jump")
	coyote_time = 0.0
	jump_buffer = 0.0
	# Only detaching from a line needs a re-grab lock. Ground launches must
	# be able to catch a line during the first few frames of their ascent.
	grab_lock = 0.24 if state_id == State.CLIMB else 0.0
	jumped.emit(boosted)
	change_state(State.JUMP)
	return true


func floor_collider() -> Node:
	for index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		if collision.get_normal().dot(Vector2.UP) > 0.7:
			return collision.get_collider() as Node
	return null


func hurt(direction: Vector2) -> bool:
	if invulnerability > 0.0 or not control_enabled:
		return false
	invulnerability = 1.5
	knockback_time = 0.30
	velocity = Vector2(signf(direction.x) * 220.0, -235.0)
	if velocity.x == 0.0:
		velocity.x = -facing * 220.0
	change_state(State.KNOCKBACK)
	AudioManager.play_sfx(&"hit")
	EventBus.cat_hurt.emit(global_position)
	damaged.emit()
	return true


func track_line(line: Clothesline, overlapping: bool) -> void:
	if overlapping and not _lines.has(line):
		_lines.append(line)
	elif not overlapping:
		_lines.erase(line)


func track_window(window: AlleyWindow, overlapping: bool) -> void:
	if overlapping and not _windows.has(window):
		_windows.append(window)
	elif not overlapping:
		_windows.erase(window)


func _try_grab() -> void:
	for line: Clothesline in _lines:
		if is_instance_valid(line) and absf(global_position.y - line.global_position.y - 12.0) < 23.0:
			active_line = line
			change_state(State.CLIMB)
			return

