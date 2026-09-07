class_name AlleyAtmosphere
extends Node2D
## Small bounded pixel particles: no fullscreen blur, bloom, or physics changes.

var cat: Cat
var windows: Array[AlleyWindow] = []
var _particles: Array[Dictionary] = []
var _time: float = 0.0
var _step_timer: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 1984
	cat.landed.connect(_on_landed)
	cat.jumped.connect(_on_jumped)
	EventBus.cat_hurt.connect(_on_hurt)

func _physics_process(delta: float) -> void:
	_time += delta
	_step_timer -= delta
	for index: int in range(_particles.size() - 1, -1, -1):
		var particle: Dictionary = _particles[index]
		particle["life"] = float(particle["life"]) - delta
		if float(particle["life"]) <= 0.0:
			_particles.remove_at(index)
			continue
		particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
		particle["velocity"] = Vector2(particle["velocity"]) + Vector2(0, 40.0) * delta
	if _step_timer <= 0.0 and cat.is_on_floor() and absf(cat.velocity.x) > 80.0:
		_step_timer = 0.12
		_burst(cat.global_position + Vector2(-cat.facing * 7, 9), 2, Color("8d9489"), 15.0)
		AudioManager.play_sfx(&"step", 1.0, 0.08)
	queue_redraw()

func _on_landed(speed: float, collider: Node) -> void:
	if speed > 130.0:
		_burst(cat.global_position + Vector2(0, 8), mini(12, int(speed / 45.0)), Color("b0aa8b"), 40.0)
		AudioManager.play_sfx(&"can" if is_instance_valid(collider) and collider.is_in_group(&"launch_pad") else &"land", 0.95, 0.04)

func _on_jumped(boosted: bool) -> void:
	_burst(cat.global_position + Vector2(0, 8), 10 if boosted else 4, Color("c5c6a2"), 35.0)
	if boosted:
		AudioManager.play_sfx(&"can", 1.1, 0.04)

func _on_hurt(at: Vector2) -> void:
	_burst(at, 16, Color("e8bb77"), 90.0)

func _burst(at: Vector2, count: int, color: Color, spread: float) -> void:
	for index: int in range(count):
		if _particles.size() >= 80:
			_particles.pop_front()
		_particles.append({"position": at, "velocity": Vector2(_rng.randf_range(-spread, spread), _rng.randf_range(-spread, -5.0)), "life": _rng.randf_range(0.2, 0.55), "color": color})

func _draw() -> void:
	for window: AlleyWindow in windows:
		if window.window_state == AlleyWindow.WindowState.ILLUMINATED:
			var origin: Vector2 = window.position + Vector2(0, 27)
			draw_colored_polygon(PackedVector2Array([origin + Vector2(-17, 0), origin + Vector2(17, 0), origin + Vector2(40, 55), origin + Vector2(-40, 55)]), Color(0.88, 0.64, 0.32, 0.035))
	for mote: int in range(12):
		var offset: float = float(mote) * 1.73
		var spot: Vector2 = Vector2(fposmod(mote * 53.0 + _time * 2.0, 630.0) + 5.0, 112.0 + fposmod(mote * 31.0, 218.0) + sin(_time * 0.8 + offset) * 6.0)
		var alpha: float = 0.12 + maxf(0.0, sin(_time * 1.1 + offset)) * 0.3
		draw_rect(Rect2(spot.round(), Vector2.ONE), Color(0.78, 0.87, 0.72, alpha))
	for particle: Dictionary in _particles:
		var color: Color = particle["color"]
		color.a = minf(1.0, float(particle["life"]) * 4.0)
		draw_rect(Rect2(Vector2(particle["position"]).round(), Vector2(2, 1)), color)
