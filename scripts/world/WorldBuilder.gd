class_name WorldBuilder
extends RefCounted
## Small scene-construction helpers; all dimensions are native viewport pixels.

static func platform(parent: Node, rect: Rect2, color: Color, one_way: bool = false) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = one_way
	shape.one_way_collision_margin = 4.0
	body.add_child(shape)
	var art: Polygon2D = Polygon2D.new()
	var half: Vector2 = rect.size * 0.5
	art.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	art.color = color
	body.add_child(art)
	var edge: Line2D = Line2D.new()
	edge.points = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y)])
	edge.width = 2.0
	edge.default_color = color.lightened(0.28)
	body.add_child(edge)
	parent.add_child(body)
	return body


static func bounds(parent: Node) -> StaticBody2D:
	var floor_body: StaticBody2D = platform(parent, Rect2(0, 380, 640, 20), Color("303147"))
	floor_body.add_to_group(&"floor")
	platform(parent, Rect2(-16, -40, 16, 440), Color("17172b"))
	platform(parent, Rect2(640, -40, 16, 440), Color("17172b"))
	platform(parent, Rect2(0, -40, 640, 16), Color("17172b"))
	return floor_body


static func area_box(area: Area2D, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	area.collision_layer = 8
	area.collision_mask = 2
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.position = offset
	area.add_child(shape)


static func label(parent: Node, text: String, at: Vector2, size: int = 12, color: Color = Color("eee5ed")) -> Label:
	var result: Label = Label.new()
	result.text = text
	result.position = at
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result
