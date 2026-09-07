extends RoomBase
## Jump from furniture and land on the vacuum's top to claim the toy.
## Side hits and loud landings accumulate sleep alert; nearby impacts wake it.

var vacuum: RobotVacuum
var dog: SleepingDog
var _launched_from_furniture: bool = false
var _impact_cooldown: float = 0.0
var _alert_label: Label

func _ready() -> void:
	default_room_id = GameManager.RoomId.ROBOT_VACUUM
	time_limit = 60.0
	super._ready()
	hud.set_objective("ROBOT VACUUM / Jump from furniture onto the toy. Land quietly, away from the dog.")
	furniture(Rect2(30, 296, 145, 17), Color("9a708a"))
	furniture(Rect2(207, 242, 87, 12), Color("a18478"))
	furniture(Rect2(327, 301, 104, 12), Color("8a8fa0"))
	cat.position = Vector2(92, 283)
	cat.landed.connect(_on_cat_landed)
	cat.state_changed.connect(_on_cat_state_changed)
	dog = SleepingDog.new()
	dog.position = Vector2(574, 362)
	dog.awakened.connect(_on_dog_awakened)
	add_child(dog)
	vacuum = RobotVacuum.new()
	vacuum.position = Vector2(305, 369)
	vacuum.max_speed += minf(float(GameManager.level_multiplier - 1) * 8.0, 45.0)
	add_child(vacuum)
	_alert_label = WorldBuilder.label(self, "", Vector2(444, 89), 12, Color("ffd19f"))
	AudioManager.play_music(&"vacuum")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not resolved and is_instance_valid(dog):
		_impact_cooldown = maxf(0.0, _impact_cooldown - delta)
		progress_text = "TARGET ARMED - land on top" if _launched_from_furniture else "Jump from a couch, table or chair"
		_alert_label.text = "DOG ALERT %03d%%" % int(dog.alert / dog.wake_threshold * 100.0)
		if cat.is_on_floor() and cat.floor_collider() == floor_body:
			dog.add_noise(absf(cat.velocity.x) / cat.run_speed * delta * 0.25, cat.global_position)
		if cat.global_position.distance_to(dog.global_position) < 40.0:
			dog.wake()
		for index: int in range(cat.get_slide_collision_count()):
			var collision: KinematicCollision2D = cat.get_slide_collision(index)
			if collision.get_collider() == vacuum and absf(collision.get_normal().x) > 0.6 and _impact_cooldown <= 0.0:
				_impact_cooldown = 0.45
				_noisy_impact(2.0)
	super._physics_process(delta)

func _on_cat_state_changed(_previous: int, current: int) -> void:
	if current != Cat.State.JUMP:
		return
	var origin: Node = cat.floor_collider()
	_launched_from_furniture = cat.velocity.y < -50.0 and is_instance_valid(origin) and origin.is_in_group(&"furniture")

func _on_cat_landed(impact_speed: float, collider: Node) -> void:
	if resolved:
		return
	if collider == vacuum:
		var centered: bool = absf(cat.global_position.x - vacuum.global_position.x) <= 19.0
		if _launched_from_furniture and centered and impact_speed >= 65.0 and vacuum.toy_attached:
			vacuum.toy_attached = false
			AudioManager.play_sfx(&"collect", 1.2)
			win(800)
		else:
			_noisy_impact(2.2)
	elif collider == floor_body:
		_noisy_impact(clampf(impact_speed / 240.0, 0.25, 2.6))
	else:
		dog.add_noise(0.08, cat.global_position)
	_launched_from_furniture = false

func _noisy_impact(amount: float) -> void:
	if cat.global_position.distance_to(dog.global_position) < 135.0:
		dog.wake()
	else:
		dog.add_noise(amount, cat.global_position)

func _on_dog_awakened() -> void:
	lose("You woke the dog!")

func _draw() -> void:
	super._draw()
	draw_rect(Rect2(27, 271, 151, 29), Color("705776"))
	draw_rect(Rect2(26, 286, 15, 72), Color("886681"))
	draw_rect(Rect2(165, 286, 15, 72), Color("886681"))
	draw_rect(Rect2(216, 249, 8, 131), Color("775e61"))
	draw_rect(Rect2(277, 249, 8, 131), Color("775e61"))
	draw_rect(Rect2(337, 311, 8, 69), Color("63667d"))
	draw_rect(Rect2(414, 277, 8, 103), Color("63667d"))
	draw_rect(Rect2(479, 375, 145, 5), Color("a87480"))
