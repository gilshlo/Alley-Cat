class_name Collectible
extends Area2D

signal collected(item: Collectible)
enum Kind { MOUSE, CAGE, BIRD, FISH, VASE }

var kind: Kind = Kind.MOUSE
var patrol_width: float = 0.0
var patrol_speed: float = 1.0
var taken: bool = false
var _origin: Vector2
var _age: float = 0.0

func _ready() -> void:
	_origin = position
	WorldBuilder.area_box(self, Vector2(18, 18))
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_age += delta
	if patrol_width > 0.0:
		position.x = _origin.x + sin(_age * patrol_speed) * patrol_width
		if kind == Kind.BIRD or kind == Kind.FISH:
			position.y = _origin.y + sin(_age * patrol_speed * 1.7) * 12.0
	if kind == Kind.CAGE or kind == Kind.VASE:
		for body: Node2D in get_overlapping_bodies():
			_try_collect(body)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	_try_collect(body)

func _try_collect(body: Node2D) -> void:
	if taken or not body is Cat:
		return
	var player: Cat = body as Cat
	if kind == Kind.CAGE and not Input.is_action_just_pressed("interact"):
		return
	if kind == Kind.VASE and (player.velocity.y < 35.0 or player.global_position.y > global_position.y - 3.0):
		return
	taken = true
	AudioManager.play_sfx(&"collect")
	collected.emit(self)
	queue_free()

func _draw() -> void:
	match kind:
		Kind.MOUSE:
			draw_rect(Rect2(-7, -3, 13, 7), Color("d3a8b0"))
			draw_circle(Vector2(-3, -4), 3, Color("f1ced0"))
			draw_line(Vector2(5, 2), Vector2(12, -2), Color("c48c9e"))
		Kind.CAGE:
			draw_rect(Rect2(-12, -14, 24, 29), Color("dec78f"), false, 2.0)
			for offset: int in [-7, 0, 7]:
				draw_line(Vector2(offset, -14), Vector2(offset, 14), Color("dec78f"))
			draw_rect(Rect2(-5, -4, 10, 9), Color("6fe3b7"))
		Kind.BIRD:
			draw_rect(Rect2(-6, -4, 12, 8), Color("77e0ba"))
			draw_line(Vector2(-3, 0), Vector2(-11, sin(_age * 25.0) * 8.0), Color("aaf2d6"), 3.0)
			draw_rect(Rect2(6, -2, 4, 3), Color("f1ce7a"))
		Kind.FISH:
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(0, -5), Vector2(8, 0), Vector2(0, 5)]), Color("ffad79"))
			draw_rect(Rect2(-10, -4, 3, 8), Color("f27c79"))
			draw_rect(Rect2(4, -1, 2, 2), Color("343044"))
		Kind.VASE:
			draw_rect(Rect2(-5, -12, 10, 5), Color("b9e7df"))
			draw_rect(Rect2(-8, -7, 16, 17), Color("7ca7cb"))
			draw_rect(Rect2(-8, 0, 16, 3), Color("f0d99f"))
