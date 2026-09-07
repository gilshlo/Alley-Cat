class_name CatVisual
extends Node2D
## Visual-only animation never scales or moves the cat's collision capsule.

const POSES: Texture2D = preload("res://assets/pixel/cat_poses.png")
var cat: Cat
var _time: float = 0.0
var _squash: float = 0.0
var _takeoff: float = 0.0

func _ready() -> void:
	cat = get_parent() as Cat
	cat.landed.connect(_on_landed)
	cat.jumped.connect(_on_jumped)

func _physics_process(delta: float) -> void:
	_time += delta
	_squash = move_toward(_squash, 0.0, delta * 5.0)
	_takeoff = move_toward(_takeoff, 0.0, delta * 5.0)
	queue_redraw()

func _on_landed(speed: float, _collider: Node) -> void:
	_squash = clampf(speed / 650.0, 0.15, 0.8)

func _on_jumped(_boosted: bool) -> void:
	_takeoff = 1.0

func _draw() -> void:
	if not is_instance_valid(cat):
		return
	var frame: int = 0
	match cat.state_id:
		Cat.State.IDLE:
			frame = 2 if fmod(_time, 4.2) > 4.02 else int(_time * 1.5) % 2
		Cat.State.WALK:
			frame = 3 + int(_time * 12.0) % 4
		Cat.State.JUMP:
			frame = 7 if cat.velocity.y < -30.0 else 8
		Cat.State.CLIMB:
			frame = 9 + (int(_time * 6.0) % 2 if absf(cat.axis) > 0.0 else 0)
		Cat.State.KNOCKBACK:
			frame = 11
	if cat.is_on_floor():
		draw_rect(Rect2(-12, 8, 24, 2), Color(0.03, 0.07, 0.12, 0.45))
	var alpha: float = 0.45 if cat.invulnerability > 0.0 and int(_time * 12.0) % 2 == 0 else 1.0
	var stretch: Vector2 = Vector2(1.0 + _squash * 0.18 - _takeoff * 0.05, 1.0 - _squash * 0.13 + _takeoff * 0.05)
	draw_set_transform(Vector2(0, 8.0 - 8.0 * stretch.y), 0, stretch * Vector2(cat.facing, 1))
	draw_texture_rect_region(POSES, Rect2(-16, -23, 32, 32), Rect2(frame * 32, 0, 32, 32), Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO)
