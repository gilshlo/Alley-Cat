class_name RoomBase
extends Node2D
## Shared lifecycle, timing and idempotent result handling for every room.

@export var time_limit: float = 55.0
var cat: Cat
var hud: GameHUD
var resolved: bool = false
var time_left: float = 55.0
var token: int = 0
var default_room_id: int = 0
var floor_body: StaticBody2D
var progress_text: String = ""

func _ready() -> void:
	# Also supports running a room scene directly from the editor (F6).
	if GameManager.current_room < 0:
		GameManager.current_room = default_room_id
		GameManager.attempt_id += 1
		GameManager.phase = GameManager.Phase.ROOM
	token = GameManager.attempt_id
	time_left = time_limit
	floor_body = WorldBuilder.bounds(self)
	cat = Cat.new()
	cat.position = Vector2(55, 365)
	cat.damaged.connect(_on_cat_damaged)
	add_child(cat)
	hud = GameHUD.new()
	add_child(hud)
	AudioManager.play_music(&"room")

func _physics_process(delta: float) -> void:
	if resolved or GameManager.phase != GameManager.Phase.ROOM:
		return
	time_left = maxf(time_left - delta, 0.0)
	hud.set_status("%s   TIME %02d" % [progress_text, ceili(time_left)])
	if time_left <= 0.0:
		lose("Time ran out")

func win(base_points: int = 500) -> void:
	if resolved:
		return
	resolved = true
	cat.control_enabled = false
	GameManager.finish_room(true, base_points + int(time_left) * 5, token)

func lose(reason: String) -> void:
	if resolved:
		return
	resolved = true
	cat.control_enabled = false
	EventBus.notification.emit(reason)
	GameManager.finish_room(false, 0, token)

func furniture(rect: Rect2, color: Color) -> StaticBody2D:
	var body: StaticBody2D = WorldBuilder.platform(self, rect, color, true)
	body.add_to_group(&"furniture")
	return body

func _on_cat_damaged() -> void:
	lose("Caught! Back to the alley")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 380), Color("393047"))
	for index: int in range(17):
		draw_rect(Rect2(index * 40, 55, 2, 280), Color("45384e"))
	draw_rect(Rect2(0, 335, 640, 45), Color("594353"))
	draw_rect(Rect2(0, 335, 640, 5), Color("ac7b76"))
	draw_rect(Rect2(245, 81, 146, 61), Color("b18b78"))
	draw_rect(Rect2(250, 86, 136, 51), Color("27344c"))
	draw_circle(Vector2(350, 105), 12, Color("e4c894"))
	draw_rect(Rect2(311, 86, 4, 51), Color("b18b78"))
