class_name PatrolHazard
extends Area2D

var extent: float = 170.0
var speed: float = 1.4
var vertical_extent: float = 0.0
var eel: bool = false
var _origin: Vector2
var _age: float = 0.0

func _ready() -> void:
	_origin = position
	WorldBuilder.area_box(self, Vector2(24, 12) if eel else Vector2(16, 30))
	collision_layer = 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_age += delta
	position = _origin + Vector2(sin(_age * speed) * extent, cos(_age * speed * 0.71) * vertical_extent)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Cat:
		(body as Cat).hurt(body.global_position - global_position)

func _draw() -> void:
	if eel:
		for index: int in range(7):
			draw_rect(Rect2(index * 4 - 14, sin(_age * 9.0 + index) * 3.0 - 2, 5, 5), Color("d1e476"))
	else:
		draw_rect(Rect2(-2, -20, 4, 27), Color("c5a17b"))
		draw_rect(Rect2(-9, 6, 18, 10), Color("dcc67d"))
