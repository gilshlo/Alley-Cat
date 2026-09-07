class_name AlleyWindow
extends Area2D
## The painted frame is visual; the original interaction rectangle is retained.
signal enter_requested(room_id: int, return_position: Vector2)

enum WindowState { SHUT, OPEN, ILLUMINATED, COMPLETE }
const FRAMES: Texture2D = preload("res://assets/pixel/windows.png")
@export var room_id: int = 0
var window_state: WindowState = WindowState.SHUT
var _nearby_cat: Cat
var _age: float = 0.0
var _warning: float = 0.0

func _ready() -> void:
	WorldBuilder.area_box(self, Vector2(50, 54))
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	z_index = 2
	queue_redraw()

func _physics_process(delta: float) -> void:
	_age += delta
	_warning = maxf(0.0, _warning - delta)
	queue_redraw()

func warn_throw() -> void:
	_warning = 0.7

func set_window_state(value: WindowState) -> void:
	window_state = value
	queue_redraw()

func try_enter(cat: Cat) -> bool:
	if window_state != WindowState.ILLUMINATED or not GameManager.can_enter_room(room_id):
		return false
	if not overlaps_body(cat):
		return false
	enter_requested.emit(room_id, cat.global_position)
	return GameManager.phase == GameManager.Phase.TRANSITION

func _on_body_entered(body: Node2D) -> void:
	if body is Cat:
		_nearby_cat = body as Cat
		_nearby_cat.track_window(self, true)

func _on_body_exited(body: Node2D) -> void:
	if body is Cat:
		(body as Cat).track_window(self, false)
		_nearby_cat = null

func _draw() -> void:
	var lit: bool = window_state == WindowState.ILLUMINATED
	var shake: float = roundf(sin(_age * 50.0)) if _warning > 0.0 else 0.0
	draw_texture_rect_region(FRAMES, Rect2(-40 + shake, -39, 80, 80), Rect2(int(window_state) * 80, 0, 80, 80))
	if lit:
		draw_rect(Rect2(-16, -21, 32, 37), Color(1.0, 0.78, 0.42, 0.025 + sin(_age * 2.0) * 0.015))
	PixelFont.centered(self, str(room_id + 1), Vector2(0, -19), PixelFont.PAPER if lit else Color("839493"))
	if is_instance_valid(_nearby_cat) and lit:
		var title: String = "E  " + GameManager.ROOM_NAMES[room_id].to_upper()
		var width: float = PixelFont.width(title) + 12
		PixelFont.panel(self, Rect2(-width * 0.5, -54, width, 17), PixelFont.INK, PixelFont.GOLD)
		PixelFont.centered(self, title, Vector2(0, -49), PixelFont.PAPER)
	elif _warning > 0.0:
		PixelFont.panel(self, Rect2(-9, -57, 18, 17), Color("573c40"), Color("d59b76"))
		PixelFont.centered(self, "!", Vector2(0, -52), PixelFont.PAPER)
