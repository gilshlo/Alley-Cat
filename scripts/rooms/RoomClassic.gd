extends RoomBase
## Four compact interpretations sharing objective and hazard infrastructure.

var remaining: int = 0
var room_kind: int = 0
var cage_open: bool = false
var oxygen: float = 12.0
const WATER: Rect2 = Rect2(125, 164, 410, 216)

func _ready() -> void:
	super._ready()
	room_kind = GameManager.current_room
	match room_kind:
		GameManager.RoomId.CHEESE:
			_build_cheese()
		GameManager.RoomId.BIRDCAGE:
			_build_birdcage()
		GameManager.RoomId.FISHBOWL:
			_build_fishbowl()
		GameManager.RoomId.LIBRARY:
			_build_library()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not resolved:
		if room_kind == GameManager.RoomId.FISHBOWL:
			cat.water_mode = WATER.has_point(cat.position)
			oxygen = maxf(0.0, oxygen - delta) if cat.water_mode else minf(12.0, oxygen + delta * 5.0)
			progress_text = "FISH %d/5   AIR %02d - Space paddles; surface to breathe" % [5 - remaining, ceili(oxygen)]
			if oxygen <= 0.0:
				lose("Out of breath")
		elif room_kind == GameManager.RoomId.BIRDCAGE:
			progress_text = "Catch the freed bird!" if cage_open else "Reach the cage and press E"
		else:
			progress_text = "REMAINING %d" % remaining
	super._physics_process(delta)

func _build_cheese() -> void:
	hud.set_objective("CHEESE & MICE / Climb the cheese and catch all five mice. Dodge the broom.")
	furniture(Rect2(70, 326, 125, 14), Color("dbaf64"))
	furniture(Rect2(180, 271, 145, 14), Color("dbaf64"))
	furniture(Rect2(305, 216, 140, 14), Color("dbaf64"))
	furniture(Rect2(430, 161, 130, 14), Color("dbaf64"))
	for spot: Vector2 in [Vector2(130, 315), Vector2(250, 260), Vector2(370, 205), Vector2(485, 150), Vector2(545, 369)]:
		_spawn_item(Collectible.Kind.MOUSE, spot, 30.0)
	_spawn_hazard(Vector2(340, 360), 235.0)

func _build_birdcage() -> void:
	hud.set_objective("BIRDCAGE / E opens the cage. Leap to catch the bird before time expires.")
	_build_stairs()
	_spawn_item(Collectible.Kind.CAGE, Vector2(448, 132))
	_spawn_hazard(Vector2(290, 361), 210.0)

func _build_fishbowl() -> void:
	hud.set_objective("FISHBOWL / Catch five fish. Tap Space to swim; avoid eels and surface for air.")
	cat.position = Vector2(80, 235)
	furniture(Rect2(25, 250, 95, 12), Color("7595a2"))
	furniture(Rect2(80, 185, 70, 10), Color("7595a2"))
	furniture(Rect2(500, 185, 100, 10), Color("7595a2"))
	for spot: Vector2 in [Vector2(200, 205), Vector2(325, 218), Vector2(460, 249), Vector2(205, 330), Vector2(430, 348)]:
		_spawn_item(Collectible.Kind.FISH, spot, 25.0)
	_spawn_hazard(Vector2(320, 286), 160.0, true)

func _build_library() -> void:
	hud.set_objective("LIBRARY VASES / Land on all four vases from above. Avoid the sweeping broom.")
	_build_stairs()
	for spot: Vector2 in [Vector2(137, 317), Vector2(246, 256), Vector2(355, 196), Vector2(448, 141)]:
		_spawn_item(Collectible.Kind.VASE, spot)
	_spawn_hazard(Vector2(328, 275), 220.0, false, 54.0)

func _build_stairs() -> void:
	furniture(Rect2(70, 329, 120, 12), Color("94716a"))
	furniture(Rect2(193, 268, 105, 12), Color("94716a"))
	furniture(Rect2(302, 208, 105, 12), Color("94716a"))
	furniture(Rect2(407, 153, 130, 12), Color("94716a"))

func _spawn_item(kind: Collectible.Kind, spot: Vector2, patrol: float = 0.0) -> void:
	var item: Collectible = Collectible.new()
	item.kind = kind
	item.position = spot
	item.patrol_width = patrol
	item.patrol_speed = 1.2 + float(remaining) * 0.17
	item.collected.connect(_on_item_collected)
	# A freed bird is spawned inside an Area2D callback; defer tree mutation.
	add_child.call_deferred(item)
	remaining += 1

func _spawn_hazard(spot: Vector2, extent: float, eel: bool = false, vertical: float = 0.0) -> void:
	var hazard: PatrolHazard = PatrolHazard.new()
	hazard.position = spot
	hazard.extent = extent
	hazard.vertical_extent = vertical
	hazard.eel = eel
	hazard.speed = 1.0 + minf(float(GameManager.level_multiplier) * 0.12, 1.0)
	add_child(hazard)

func _on_item_collected(item: Collectible) -> void:
	if resolved:
		return
	remaining -= 1
	if item.kind == Collectible.Kind.CAGE:
		cage_open = true
		_spawn_item(Collectible.Kind.BIRD, Vector2(330, 118), 175.0)
	elif remaining == 0:
		win(500)

func _draw() -> void:
	super._draw()
	if room_kind == GameManager.RoomId.FISHBOWL:
		draw_rect(WATER, Color("234d6b"))
		for index: int in range(12):
			draw_circle(Vector2(144 + index * 32, 173), 3, Color("7cb9c5"))
		draw_rect(WATER, Color("82b2c2"), false, 2.0)
	elif room_kind == GameManager.RoomId.CHEESE:
		draw_colored_polygon(PackedVector2Array([Vector2(60, 378), Vector2(566, 151), Vector2(566, 378)]), Color("a97b43"))
		for index: int in range(9):
			draw_circle(Vector2(200 + index * 38, 344 - (index % 3) * 28), 9, Color("73563a"))
	elif room_kind == GameManager.RoomId.LIBRARY:
		for shelf: int in range(4):
			for book: int in range(8):
				draw_rect(Rect2(78 + shelf * 112 + book * 10, 344 - shelf * 57, 7, 29), Color("696b91") if book % 2 else Color("a4757e"))
