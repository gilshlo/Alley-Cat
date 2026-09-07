class_name ThrownObject
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0

func _ready() -> void:
	WorldBuilder.area_box(self, Vector2(12, 12))
	collision_layer = 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_age += delta
	velocity.y += 330.0 * delta
	position += velocity * delta
	rotation += delta * 6.0
	if position.y > 410.0 or _age > 5.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Cat:
		(body as Cat).hurt(velocity.normalized())
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-2, -13, 4, 21), Color("b8a081"))
	draw_rect(Rect2(-7, 5, 14, 8), Color("e3c279"))
