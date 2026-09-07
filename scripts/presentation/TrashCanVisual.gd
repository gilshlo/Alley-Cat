class_name TrashCanVisual
extends Node2D

const SHEET: Texture2D = preload("res://assets/pixel/trash_cans.png")
var frame: int = 0
var platform: StaticBody2D
var cat: Cat
var _rattle: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	cat.landed.connect(_on_landed)
	cat.jumped.connect(_on_jumped)

func _physics_process(delta: float) -> void:
	_time += delta
	_rattle = move_toward(_rattle, 0.0, delta * 3.0)
	queue_redraw()

func _on_landed(speed: float, collider: Node) -> void:
	if collider == platform:
		_rattle = clampf(speed / 450.0, 0.2, 1.0)

func _on_jumped(boosted: bool) -> void:
	if boosted and cat.floor_collider() == platform:
		_rattle = 1.0

func _draw() -> void:
	draw_texture_rect_region(SHEET, Rect2(0, 13, 64, 67), Rect2(frame * 64, 13, 64, 67))
	var lift: float = roundf(absf(sin(_time * 35.0)) * _rattle * 3.0)
	draw_texture_rect_region(SHEET, Rect2(0, -lift, 64, 13), Rect2(frame * 64, 0, 64, 13))
