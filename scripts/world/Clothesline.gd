class_name Clothesline
extends Area2D

@export var length: float = 530.0
const LAUNDRY: Texture2D = preload("res://assets/pixel/laundry.png")
var _time: float = 0.0

func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _ready() -> void:
	WorldBuilder.area_box(self, Vector2(length, 38.0), Vector2(0, 10))
	collision_layer = 16
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Cat:
		(body as Cat).track_line(self, true)

func _on_body_exited(body: Node2D) -> void:
	if body is Cat:
		(body as Cat).track_line(self, false)

func _draw() -> void:
	draw_line(Vector2(-length * 0.5, 1), Vector2(length * 0.5, 1), Color("172b38"), 2.0)
	draw_line(Vector2(-length * 0.5, 0), Vector2(length * 0.5, 0), Color("b1ac92"), 1.0)
	for end: float in [-length * 0.5, length * 0.5]:
		draw_rect(Rect2(end - 3, -3, 6, 6), Color("334b57"))
		draw_rect(Rect2(end - 1, -1, 2, 2), Color("d5c39b"))
	for index: int in range(7):
		var offset: float = -length * 0.5 + 30.0 + index * 73.0
		var sway: float = roundf(sin(_time * 1.3 + float(index) * 0.9) * 1.5)
		draw_texture_rect_region(LAUNDRY, Rect2(offset + sway, 1, 32, 40), Rect2((index % 6) * 32, 0, 32, 40))
