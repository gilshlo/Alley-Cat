class_name StreetDog
extends Area2D

var direction: float = 1.0
var speed: float = 120.0
var _age: float = 0.0
const SPRITES: Texture2D = preload("res://assets/pixel/dog_run.png")

func _ready() -> void:
	WorldBuilder.area_box(self, Vector2(31, 19))
	collision_layer = 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_age += delta
	position.x += direction * speed * delta
	if position.x < -70.0 or position.x > 710.0:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Cat:
		(body as Cat).hurt(Vector2(direction, -1.0))
		AudioManager.play_sfx(&"bark")

func _draw() -> void:
	draw_rect(Rect2(-17, 9, 37, 2), Color(0.02, 0.07, 0.10, 0.4))
	draw_set_transform(Vector2.ZERO, 0, Vector2(direction, 1))
	draw_texture_rect_region(SPRITES, Rect2(-24, -20, 48, 32), Rect2((int(_age * 12.0) % 4) * 48, 0, 48, 32))
	draw_set_transform(Vector2.ZERO)
