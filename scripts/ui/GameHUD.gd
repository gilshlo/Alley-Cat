class_name GameHUD
extends CanvasLayer
## A crisp, compact arcade HUD, drawn with the project's own bitmap alphabet.

var _canvas: Node2D
var _objective: String = ""
var _message: String = ""
var _status: String = ""
var _hint_key: String = "E"
var _hint_text: String = "FIND A LIT WINDOW"
var _age: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_paint)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.notification.connect(_on_notification)
	_canvas.queue_redraw()

func _process(delta: float) -> void:
	if not get_tree().paused:
		_age += delta
	if _age < 8.2:
		_canvas.queue_redraw()

func set_objective(text: String) -> void:
	_objective = text
	if text.begins_with("BIRDCAGE"):
		set_hint("E", "OPEN THE CAGE")
	elif text.begins_with("FISHBOWL"):
		set_hint("SPACE", "PADDLE / SURFACE FOR AIR")
	elif text.begins_with("LIBRARY"):
		set_hint("SPACE", "LAND ON THE VASES")
	elif text.begins_with("ROBOT"):
		set_hint("SPACE", "JUMP FROM FURNITURE")
	elif text.begins_with("CHEESE"):
		set_hint("SPACE", "CATCH ALL FIVE MICE")
	_canvas.queue_redraw()

func set_status(text: String) -> void:
	if _status != text:
		_status = text
		_canvas.queue_redraw()

func set_hint(key: String, text: String) -> void:
	if _hint_key != key or _hint_text != text:
		_hint_key = key
		_hint_text = text
		_canvas.queue_redraw()

func _on_score_changed(_score: int, _multiplier: int) -> void:
	_canvas.queue_redraw()

func _on_lives_changed(_lives: int) -> void:
	_canvas.queue_redraw()

func _on_notification(text: String) -> void:
	_message = text
	_canvas.queue_redraw()

func _paint() -> void:
	_canvas.draw_rect(Rect2(0, 0, 640, 45), PixelFont.INK)
	_canvas.draw_line(Vector2(0, 44), Vector2(640, 44), Color("43555e"))
	_canvas.draw_line(Vector2(16, 43), Vector2(123, 43), PixelFont.GOLD)
	PixelFont.text(_canvas, "ALLEY CAT", Vector2(16, 12), PixelFont.PAPER, 2)
	PixelFont.text(_canvas, "MOONLIGHT MISCHIEF", Vector2(17, 31), PixelFont.MUTED)
	_canvas.draw_line(Vector2(260, 11), Vector2(260, 34), Color("344551"))
	PixelFont.text(_canvas, "SCORE", Vector2(284, 9), PixelFont.MUTED)
	PixelFont.text(_canvas, "%06d" % GameManager.score, Vector2(284, 22), PixelFont.PAPER, 2)
	PixelFont.text(_canvas, "LIVES", Vector2(409, 9), PixelFont.MUTED)
	for life: int in range(3):
		_heart(Vector2(410 + life * 19, 24), Color("d3a17c") if life < GameManager.lives else Color("364553"))
	PixelFont.text(_canvas, "NIGHT %02d" % GameManager.level_multiplier, Vector2(525, 9), PixelFont.MUTED)
	for room: int in range(5):
		var spot: Vector2 = Vector2(527 + room * 18, 26)
		var color: Color = PixelFont.MINT if GameManager.completed_rooms.has(room) else Color("526875")
		_canvas.draw_rect(Rect2(spot, Vector2(7, 7)), color, false, 1.0)
		if GameManager.completed_rooms.has(room):
			_canvas.draw_rect(Rect2(spot + Vector2(2, 2), Vector2(3, 3)), color)
	if not _status.is_empty():
		PixelFont.panel(_canvas, Rect2(14, 51, minf(612.0, PixelFont.width(_status) + 16), 19))
		PixelFont.text(_canvas, _status.left(99), Vector2(22, 57), PixelFont.MINT)
		PixelFont.text(_canvas, _objective.left(100), Vector2(17, 76), PixelFont.MUTED)
	elif _age < 8.0 and not _objective.is_empty():
		var title: String = _objective.get_slice(" / ", 0)
		PixelFont.text(_canvas, "01 / THE ALLEY" if title == "ALLEY" else title, Vector2(17, 55), PixelFont.PAPER)
		PixelFont.text(_canvas, "A LITTLE TROUBLE. A LONG WAY UP." if title == "ALLEY" else _objective.get_slice(" / ", 1).left(78), Vector2(17, 68), PixelFont.MUTED)
	_canvas.draw_rect(Rect2(0, 382, 640, 18), Color("101c2b"))
	_canvas.draw_line(Vector2(0, 382), Vector2(640, 382), Color("3a525e"))
	_key("A/D", "MOVE", Vector2(14, 385))
	_key("SPACE", "JUMP", Vector2(91, 385))
	_key("W", "GRAB", Vector2(180, 385))
	_key("ESC", "PAUSE", Vector2(248, 385))
	_key(_hint_key, _hint_text.left(37), Vector2(371, 385), PixelFont.GOLD)
	if not _message.is_empty():
		_canvas.draw_rect(Rect2(0, 45, 640, 337), Color(0.04, 0.07, 0.12, 0.8))
		PixelFont.panel(_canvas, Rect2(114, 155, 412, 89), Color("172536"), PixelFont.GOLD)
		var headline: String = _message.get_slice(" - ", 0).to_upper()
		PixelFont.centered(_canvas, headline, Vector2(320, 173), PixelFont.PAPER, 2 if headline.length() < 30 else 1)
		var detail: String = _message.get_slice(" - ", 1)
		PixelFont.centered(_canvas, detail if not detail.is_empty() else "BACK TO THE ALLEY", Vector2(320, 214), PixelFont.MUTED)

func _key(key: String, description: String, at: Vector2, color: Color = PixelFont.MUTED) -> void:
	var key_width: float = PixelFont.width(key) + 7.0
	_canvas.draw_rect(Rect2(at, Vector2(key_width, 12)), Color("2c414f"))
	_canvas.draw_line(at + Vector2(0, 11), at + Vector2(key_width, 11), Color("556b72"))
	PixelFont.text(_canvas, key, at + Vector2(3, 2), PixelFont.PAPER)
	PixelFont.text(_canvas, description, at + Vector2(key_width + 5, 2), color)

func _heart(at: Vector2, color: Color) -> void:
	_canvas.draw_rect(Rect2(at + Vector2(1, 0), Vector2(3, 2)), color)
	_canvas.draw_rect(Rect2(at + Vector2(6, 0), Vector2(3, 2)), color)
	_canvas.draw_rect(Rect2(at + Vector2(0, 2), Vector2(10, 3)), color)
	_canvas.draw_rect(Rect2(at + Vector2(1, 5), Vector2(8, 1)), color)
	_canvas.draw_rect(Rect2(at + Vector2(2, 6), Vector2(6, 1)), color)
	_canvas.draw_rect(Rect2(at + Vector2(3, 7), Vector2(4, 1)), color)
	_canvas.draw_rect(Rect2(at + Vector2(4, 8), Vector2(2, 1)), color)
