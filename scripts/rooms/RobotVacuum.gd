class_name RobotVacuum
extends CharacterBody2D
## A real moving-platform body: the cat inherits floor motion through layer 6.

@export var min_speed: float = 65.0
@export var max_speed: float = 135.0
var direction: float = 1.0
var speed: float = 90.0
var toy_attached: bool = true
var _turn_timer: float = 1.0
var _age: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	process_physics_priority = -20
	collision_layer = 32
	collision_mask = 1
	safe_margin = 0.04
	floor_snap_length = 2.0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(42, 18)
	shape.shape = rectangle
	add_child(shape)
	add_to_group(&"vacuum")

func _physics_process(delta: float) -> void:
	_age += delta
	_turn_timer -= delta
	if _turn_timer <= 0.0:
		_turn_timer = _rng.randf_range(0.7, 1.7)
		speed = _rng.randf_range(min_speed, max_speed)
		if _rng.randf() < 0.3:
			direction *= -1.0
	velocity.x = direction * speed
	velocity.y = minf(velocity.y + 1000.0 * delta, 500.0)
	move_and_slide()
	for index: int in range(get_slide_collision_count()):
		var normal: Vector2 = get_slide_collision(index).get_normal()
		if absf(normal.x) > 0.7:
			# Reflect heading off a vertical surface; ignore floor normals.
			direction = signf(normal.x)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-20, -7, 40, 15), Color("384353"))
	draw_rect(Rect2(-18, -10, 36, 14), Color("869eac"))
	draw_rect(Rect2(-14, -11, 28, 3), Color("c0d7d7"))
	draw_rect(Rect2(-4, -8, 8, 4), Color("74e7c3") if int(_age * 4) % 2 else Color("d2efaa"))
	draw_rect(Rect2(direction * 17 - 2, -3, 4, 5), Color("fa8e88"))
	draw_line(Vector2(-15, 7), Vector2(-22, 10), Color("4d6778"), 2.0)
	draw_line(Vector2(15, 7), Vector2(22, 10), Color("4d6778"), 2.0)
	if toy_attached:
		draw_line(Vector2(0, -10), Vector2(0, -17), Color("d4bb8e"))
		draw_rect(Rect2(-5, -22, 10, 6), Color("e3a6b6"))
		draw_circle(Vector2(-2, -22), 2, Color("f2cdd0"))
