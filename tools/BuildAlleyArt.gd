extends SceneTree
## Offline raster authoring source. Run with Godot --headless --script.
## The shipped PNGs are ordinary assets; this script is not run by the game.

const OUT: String = "res://assets/pixel/"
const PALETTE: Dictionary = {
	"o": Color("101724"), "d": Color("1c2636"), "b": Color("2e3d4c"),
	"s": Color("547080"), "h": Color("819ba0"), "e": Color("e9d78c"),
	"p": Color("111d29"), "n": Color("d59b96"), "w": Color("bbcdc3"),
	"a": Color("8c6259"), "r": Color("b57d60"), "t": Color("d9a475"),
	"g": Color("789d87"), "c": Color("adccaa"), "m": Color("956980")
}
var canvas: Image
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _initialize() -> void:
	_build.call_deferred()

func _build() -> void:
	rng.seed = 1984
	DirAccess.make_dir_recursive_absolute(OUT)
	_background()
	_windows()
	_cans()
	_laundry()
	_cats()
	_dogs()
	print("Authored alley assets saved to " + OUT)
	quit()

func _new(size: Vector2i) -> void:
	canvas = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)

func _save(filename: String) -> void:
	var result: Error = canvas.save_png(OUT + filename)
	assert(result == OK, "Could not save " + filename)

func _rect(rect: Rect2i, color: String) -> void:
	var clipped: Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, canvas.get_size()))
	if clipped.has_area():
		canvas.fill_rect(clipped, Color(color))

func _dot(at: Vector2i, color: String) -> void:
	if Rect2i(Vector2i.ZERO, canvas.get_size()).has_point(at):
		canvas.set_pixelv(at, Color(color))

func _line(start: Vector2i, end: Vector2i, color: String) -> void:
	var steps: int = maxi(absi(end.x - start.x), absi(end.y - start.y))
	for index: int in range(steps + 1):
		var point: Vector2 = Vector2(start).lerp(Vector2(end), float(index) / maxi(steps, 1))
		_dot(Vector2i(point.round()), color)

func _ellipse(rect: Rect2i, color: String) -> void:
	var center: Vector2 = Vector2(rect.position) + Vector2(rect.size) * 0.5
	var radius: Vector2 = Vector2(rect.size) * 0.5
	for vertical: int in range(rect.position.y, rect.end.y):
		for horizontal: int in range(rect.position.x, rect.end.x):
			var relative: Vector2 = (Vector2(horizontal, vertical) + Vector2(0.5, 0.5) - center) / radius
			if relative.length_squared() <= 1.0:
				_dot(Vector2i(horizontal, vertical), color)

func _pixels(at: Vector2i, rows: Array, flip: bool = false) -> void:
	for vertical: int in range(rows.size()):
		var row: String = rows[vertical]
		for horizontal: int in range(row.length()):
			var key: String = row[horizontal]
			if PALETTE.has(key):
				var point: Vector2i = at + Vector2i(row.length() - horizontal - 1 if flip else horizontal, vertical)
				if Rect2i(Vector2i.ZERO, canvas.get_size()).has_point(point):
					canvas.set_pixelv(point, PALETTE[key])

func _background() -> void:
	_new(Vector2i(640, 400))
	canvas.fill(Color("111c30"))
	_rect(Rect2i(0, 45, 640, 37), "17263b")
	_rect(Rect2i(0, 82, 640, 36), "203246")
	for index: int in range(60):
		var spot: Vector2i = Vector2i(rng.randi_range(0, 639), rng.randi_range(45, 120))
		_dot(spot, "71818d" if index % 4 == 0 else "33485b")
	_ellipse(Rect2i(554, 45, 53, 53), "283b4b")
	_ellipse(Rect2i(560, 48, 43, 43), "d6cead")
	_ellipse(Rect2i(565, 51, 34, 35), "e5dcbc")
	_ellipse(Rect2i(581, 57, 9, 6), "cbc6a9")
	_ellipse(Rect2i(568, 72, 8, 5), "cbc6a9")
	for building: int in range(12):
		var left: int = building * 59 - 20
		var roof: int = rng.randi_range(75, 110)
		_rect(Rect2i(left, roof, 48, 90), "23384a")
		_rect(Rect2i(left + 4, roof - 4, 40, 4), "2c4150")
		for pane: int in range(3):
			_rect(Rect2i(left + 9 + pane * 12, roof + 12, 3, 7), "697365" if pane == building % 3 else "182b3e")
	# The main facade is deliberately quieter than the interactable sprites.
	_rect(Rect2i(39, 102, 559, 246), "1b2939")
	for row: int in range(25):
		for column: int in range(23):
			var left: int = 41 + column * 25 - (12 if row % 2 else 0)
			var top: int = 104 + row * 10
			var colors: PackedStringArray = ["31424e", "344550", "30414d", "35444f", "384652"]
			_rect(Rect2i(left, top, 24, 9), colors[rng.randi_range(0, 4)])
			_line(Vector2i(left + 1, top), Vector2i(left + 22, top), "3f5059")
			if rng.randf() < 0.25:
				_line(Vector2i(left + 8, top + 5), Vector2i(left + 13, top + 5), "40515a")
			if rng.randf() < 0.10:
				_line(Vector2i(left + 18, top + 1), Vector2i(left + 16, top + 4), "293b47")
	# Stone cornices and vertical pilasters break up the brick grid.
	for height: int in [94, 184, 281]:
		_rect(Rect2i(34, height, 570, 9), "182b3a")
		_rect(Rect2i(32, height, 574, 3), "627172")
		_rect(Rect2i(35, height + 3, 568, 3), "455b62")
		_rect(Rect2i(40, height + 8, 558, 4), "233440")
	for left: int in [39, 162, 277, 365, 481, 590]:
		_rect(Rect2i(left, 105, 5, 175), "263945")
		_rect(Rect2i(left, 105, 1, 175), "50626a")
	for left: int in [79, 286, 474]:
		_rect(Rect2i(left, 81, 23, 13), "30414c")
		_rect(Rect2i(left - 2, 78, 27, 4), "5b6970")
		_rect(Rect2i(left + 5, 83, 2, 10), "40535d")
	# Close side walls, riveted drainpipes, a warm hanging lamp, and climbing ivy.
	_rect(Rect2i(0, 68, 30, 302), "172738")
	_rect(Rect2i(4, 70, 4, 286), "293b4b")
	_rect(Rect2i(609, 80, 31, 288), "192c3b")
	for left: int in [24, 605]:
		_rect(Rect2i(left, 110, 7, 252), "152838")
		_rect(Rect2i(left + 1, 110, 2, 252), "58727a")
		_rect(Rect2i(left + 3, 110, 2, 252), "344e60")
		for height: int in [126, 207, 284, 352]:
			_rect(Rect2i(left - 1, height, 9, 3), "263947")
			_dot(Vector2i(left, height), "8c9992")
	_lamp(Vector2i(29, 188))
	_lamp(Vector2i(607, 243))
	# A crooked wooden fence has individual boards, grain, knots and nailheads.
	for index: int in range(35):
		var left: int = index * 19 - 8
		var top: int = rng.randi_range(305, 314)
		var wood: String = ["554a50", "594d51", "615054", "4c444c"][index % 4]
		_rect(Rect2i(left, top + 3, 17, 68), "202b38")
		_rect(Rect2i(left + 1, top + 1, 14, 68), wood)
		_rect(Rect2i(left + 3, top, 10, 2), "938077")
		_line(Vector2i(left + 2, top + 4), Vector2i(left + 2, 369), "817071")
		_line(Vector2i(left + 13, top + 5), Vector2i(left + 13, 371), "3c3843")
		_line(Vector2i(left + 6, top + 12), Vector2i(left + 7, top + 30), "493d48")
		_line(Vector2i(left + 10, top + 34), Vector2i(left + 9, top + 54), "796361")
		_ellipse(Rect2i(left + 6, top + 38, 4, 7), "3c3540")
		_dot(Vector2i(left + 7, top + 39), "947a6e")
	for top: int in [325, 359]:
		_rect(Rect2i(0, top, 640, 6), "2a303a")
		_rect(Rect2i(0, top, 640, 2), "86736e")
		_rect(Rect2i(0, top + 2, 640, 2), "645354")
		for nail: int in range(34):
			_dot(Vector2i(nail * 19 + 7, top + 2), "b1a08a")
	_ground()
	for side: int in [0, 1]:
		for branch: int in range(15):
			var left: int = rng.randi_range(1, 36) if side == 0 else rng.randi_range(614, 639)
			var top: int = rng.randi_range(253, 369)
			_line(Vector2i(left, top), Vector2i(left + 4, top + 13), "293e42")
			_ellipse(Rect2i(left - 3, top, 7, 3), "496e63")
			_ellipse(Rect2i(left + 2, top + 5, 6, 3), "32564f")
	# Poster, discarded paper and a little fishbone: household comedy, not clutter.
	_rect(Rect2i(223, 336, 21, 29), "292e38")
	_rect(Rect2i(224, 335, 19, 27), "b3a58a")
	_rect(Rect2i(226, 338, 15, 2), "625d59")
	_pixels(Vector2i(228, 344), [".o...o.", "oodddoo", "odepedo", ".odddo.", "..ooo.."])
	_line(Vector2i(227, 356), Vector2i(239, 356), "827966")
	_line(Vector2i(393, 374), Vector2i(410, 374), "ada589")
	for offset: int in [3, 7, 11]:
		_line(Vector2i(394 + offset, 371), Vector2i(394 + offset, 377), "ada589")
	_rect(Rect2i(456, 375, 11, 3), "9b9786")
	_line(Vector2i(458, 374), Vector2i(469, 376), "c1b9a0")
	_save("alley_backdrop.png")

func _lamp(at: Vector2i) -> void:
	for radius: int in range(4, 0, -1):
		var width: int = 10 + radius * 8
		_ellipse(Rect2i(at - Vector2i(width / 2, width / 2), Vector2i(width, width)), ["38464a", "344149", "303d45", "293844"][radius - 1])
	_line(at + Vector2i(-8, -23), at + Vector2i(0, -23), "8c9890")
	_line(at + Vector2i(0, -23), at + Vector2i(0, -14), "8c9890")
	_rect(Rect2i(at + Vector2i(-8, -12), Vector2i(16, 3)), "182632")
	_rect(Rect2i(at + Vector2i(-6, -9), Vector2i(12, 16)), "8e7855")
	_rect(Rect2i(at + Vector2i(-4, -8), Vector2i(8, 13)), "dfb977")
	_rect(Rect2i(at + Vector2i(-2, -7), Vector2i(3, 12)), "f1dca0")
	_rect(Rect2i(at + Vector2i(-8, 6), Vector2i(16, 3)), "172531")
	_line(at + Vector2i(-6, -10), at + Vector2i(-6, 7), "af9668")
	_line(at + Vector2i(5, -10), at + Vector2i(5, 7), "354045")

func _ground() -> void:
	_rect(Rect2i(0, 370, 640, 30), "1e303c")
	_rect(Rect2i(0, 378, 640, 4), "536b70")
	_line(Vector2i(0, 378), Vector2i(640, 378), "869084")
	for index: int in range(48):
		var left: int = index * 16 - 5
		_rect(Rect2i(left, 382, 15, 10), "2b424c" if index % 2 else "334952")
		_line(Vector2i(left + 1, 382), Vector2i(left + 12, 382), "52656a")
	for index: int in range(65):
		var spot: Vector2i = Vector2i(rng.randi_range(0, 638), rng.randi_range(370, 377))
		_rect(Rect2i(spot, Vector2i(rng.randi_range(1, 6), 1)), "405764")
	for puddle: Rect2i in [Rect2i(184, 373, 76, 4), Rect2i(369, 371, 80, 5), Rect2i(555, 374, 56, 3)]:
		_ellipse(puddle, "446775")
		_line(puddle.position + Vector2i(10, 1), puddle.position + Vector2i(25, 1), "8eaa9f")

func _windows() -> void:
	_new(Vector2i(320, 80))
	for frame: int in range(4):
		var origin: Vector2i = Vector2i(frame * 80, 0)
		var lit: bool = frame == 2
		if lit:
			_rect(Rect2i(origin + Vector2i(5, 5), Vector2i(70, 72)), "dfb36712")
			_rect(Rect2i(origin + Vector2i(10, 8), Vector2i(60, 65)), "dfb36716")
		_rect(Rect2i(origin + Vector2i(13, 13), Vector2i(57, 58)), "14233080")
		_rect(Rect2i(origin + Vector2i(14, 9), Vector2i(52, 59)), "182534")
		_rect(Rect2i(origin + Vector2i(17, 10), Vector2i(46, 56)), "8b8680")
		_rect(Rect2i(origin + Vector2i(19, 13), Vector2i(42, 51)), "222e3a")
		_rect(Rect2i(origin + Vector2i(21, 15), Vector2i(38, 48)), "d3a466" if lit else "1c303f")
		_rect(Rect2i(origin + Vector2i(23, 17), Vector2i(34, 34)), "edc783" if lit else "304654")
		_rect(Rect2i(origin + Vector2i(23, 17), Vector2i(34, 9)), "e2b872" if lit else "334955")
		_rect(Rect2i(origin + Vector2i(23, 55), Vector2i(34, 8)), "9b7752" if lit else "223341")
		# Painted wood with alternating sun-faded edges and shadowed slats.
		for side: int in [0, 1]:
			var left: int = 5 if side == 0 else 65
			_rect(Rect2i(origin + Vector2i(left, 15), Vector2i(10, 46)), "203540")
			_rect(Rect2i(origin + Vector2i(left + 1, 16), Vector2i(8, 44)), "4b6b70")
			_line(origin + Vector2i(left + 1, 15), origin + Vector2i(left + 1, 59), "7c9490")
			for slat: int in range(8):
				_line(origin + Vector2i(left + 2, 19 + slat * 5), origin + Vector2i(left + 7, 19 + slat * 5), "263e4a")
		if frame == 0:
			_rect(Rect2i(origin + Vector2i(20, 14), Vector2i(40, 49)), "294450")
			for slat: int in range(9):
				_rect(Rect2i(origin + Vector2i(22, 16 + slat * 5), Vector2i(36, 3)), "547477")
				_line(origin + Vector2i(22, 16 + slat * 5), origin + Vector2i(57, 16 + slat * 5), "6e8b86")
			_rect(Rect2i(origin + Vector2i(39, 14), Vector2i(2, 49)), "263d47")
			_rect(Rect2i(origin + Vector2i(36, 43), Vector2i(8, 3)), "a49d7e")
		else:
			for side: int in [0, 1]:
				var left: int = 22 if side == 0 else 52
				_rect(Rect2i(origin + Vector2i(left, 16), Vector2i(7, 39)), "825260" if lit else "473d54")
				_rect(Rect2i(origin + Vector2i(left + 1, 17), Vector2i(2, 37)), "b27b7e" if lit else "685264")
				_rect(Rect2i(origin + Vector2i(left + 2, 41), Vector2i(5, 3)), "d1aa75")
				_rect(Rect2i(origin + Vector2i(left, 54), Vector2i(9, 3)), "643c50" if lit else "3b3348")
			_line(origin + Vector2i(21, 31), origin + Vector2i(58, 31), "ae8b62" if lit else "47545a")
			_rect(Rect2i(origin + Vector2i(39, 14), Vector2i(2, 17)), "d3b584" if lit else "61736f")
		_rect(Rect2i(origin + Vector2i(12, 8), Vector2i(56, 4)), "92958a")
		_line(origin + Vector2i(15, 8), origin + Vector2i(64, 8), "b9b49a")
		_rect(Rect2i(origin + Vector2i(10, 64), Vector2i(60, 4)), "bab196")
		_rect(Rect2i(origin + Vector2i(12, 68), Vector2i(56, 3)), "677875")
		_line(origin + Vector2i(13, 64), origin + Vector2i(66, 64), "d4c8a5")
		_rect(Rect2i(origin + Vector2i(20, 71), Vector2i(6, 3)), "304752")
		_rect(Rect2i(origin + Vector2i(54, 71), Vector2i(6, 3)), "304752")
		if frame == 3:
			_line(origin + Vector2i(33, 44), origin + Vector2i(38, 49), "91c7a3")
			_line(origin + Vector2i(38, 49), origin + Vector2i(48, 38), "91c7a3")
		# Small terracotta herb pot anchored to the ledge.
		_rect(Rect2i(origin + Vector2i(54, 58), Vector2i(8, 6)), "996e5a")
		_rect(Rect2i(origin + Vector2i(53, 57), Vector2i(10, 2)), "c19371")
		_line(origin + Vector2i(58, 56), origin + Vector2i(58, 48), "719684")
		_ellipse(Rect2i(origin + Vector2i(53, 50), Vector2i(6, 3)), "6e9980")
		_ellipse(Rect2i(origin + Vector2i(58, 47), Vector2i(5, 3)), "98ae87")
	_save("windows.png")

func _cans() -> void:
	_new(Vector2i(192, 80))
	for frame: int in range(3):
		var origin: Vector2i = Vector2i(frame * 64, 0)
		var bottom: int = 74 if frame == 1 else 59
		_ellipse(Rect2i(origin + Vector2i(4, bottom - 4), Vector2i(58, 8)), "10233190")
		_rect(Rect2i(origin + Vector2i(9, 13), Vector2i(46, bottom - 15)), "1b3542")
		_rect(Rect2i(origin + Vector2i(11, 15), Vector2i(42, bottom - 19)), "446974")
		_rect(Rect2i(origin + Vector2i(12, 16), Vector2i(12, bottom - 20)), "557d83")
		_rect(Rect2i(origin + Vector2i(43, 15), Vector2i(10, bottom - 19)), "365563")
		for ridge: int in range(5):
			var left: int = 14 + ridge * 8
			_rect(Rect2i(origin + Vector2i(left, 19), Vector2i(2, bottom - 24)), "2c4a58")
			_line(origin + Vector2i(left + 2, 18), origin + Vector2i(left + 2, bottom - 6), "79968f")
		for speck: int in range(28):
			var point: Vector2i = origin + Vector2i(rng.randi_range(12, 51), rng.randi_range(23, bottom - 5))
			_dot(point, "8a7e63" if speck % 3 == 0 else "648487")
		_ellipse(Rect2i(origin + Vector2i(9, bottom - 6), Vector2i(46, 7)), "284854")
		_line(origin + Vector2i(14, bottom - 1), origin + Vector2i(48, bottom - 1), "729089")
		_ellipse(Rect2i(origin + Vector2i(5, 7), Vector2i(54, 9)), "283f4c")
		_ellipse(Rect2i(origin + Vector2i(7, 6), Vector2i(50, 7)), "90a599")
		_ellipse(Rect2i(origin + Vector2i(10, 6), Vector2i(44, 4)), "bdd0b2")
		_rect(Rect2i(origin + Vector2i(5, 10), Vector2i(54, 3)), "5b8082")
		_line(origin + Vector2i(7, 10), origin + Vector2i(55, 10), "bfccb0")
		_rect(Rect2i(origin + Vector2i(25, 2), Vector2i(14, 5)), "1e3642")
		_rect(Rect2i(origin + Vector2i(26, 2), Vector2i(12, 2)), "8da499")
		_rect(Rect2i(origin + Vector2i(28, 4), Vector2i(8, 2)), "233d49")
		for left: int in [6, 54]:
			_rect(Rect2i(origin + Vector2i(left, 20), Vector2i(4, 8)), "739087")
			_rect(Rect2i(origin + Vector2i(left + 1, 21), Vector2i(2, 5)), "213d4c")
		_rect(Rect2i(origin + Vector2i(27, 27), Vector2i(14, 12)), "a8ad8b")
		_rect(Rect2i(origin + Vector2i(29, 29), Vector2i(10, 8)), "738c7d")
		_pixels(origin + Vector2i(31, 30), ["..e..", ".eee.", "eeeee", "..e..", "..e.."])
	_save("trash_cans.png")

func _laundry() -> void:
	_new(Vector2i(192, 40))
	for frame: int in range(6):
		var origin: Vector2i = Vector2i(frame * 32, 0)
		var fabric: String = ["a0b0ac", "758b9a", "b5888a", "c9b997", "688a8f", "93849e"][frame]
		var shadow: String = ["688d90", "506d83", "855d75", "998c7c", "3e6677", "645973"][frame]
		if frame == 0 or frame == 4:
			_rect(Rect2i(origin + Vector2i(9, 4), Vector2i(15, 26)), shadow)
			_rect(Rect2i(origin + Vector2i(6, 5), Vector2i(6, 10)), fabric)
			_rect(Rect2i(origin + Vector2i(22, 5), Vector2i(6, 10)), fabric)
			_rect(Rect2i(origin + Vector2i(11, 4), Vector2i(11, 25)), fabric)
			_rect(Rect2i(origin + Vector2i(14, 3), Vector2i(5, 4)), "263d4a")
			_line(origin + Vector2i(12, 28), origin + Vector2i(21, 28), "bec3af")
		elif frame == 1:
			for offset: int in [7, 18]:
				_rect(Rect2i(origin + Vector2i(offset, 4), Vector2i(6, 21)), fabric)
				_rect(Rect2i(origin + Vector2i(offset + 1, 25), Vector2i(10, 5)), shadow)
				_line(origin + Vector2i(offset, 9), origin + Vector2i(offset + 5, 9), "a7b3ad")
		elif frame == 2:
			_rect(Rect2i(origin + Vector2i(5, 4), Vector2i(22, 18)), fabric)
			_rect(Rect2i(origin + Vector2i(5, 19), Vector2i(9, 7)), shadow)
			_rect(Rect2i(origin + Vector2i(19, 19), Vector2i(8, 7)), shadow)
			_line(origin + Vector2i(5, 6), origin + Vector2i(26, 6), "d5b59f")
		else:
			_rect(Rect2i(origin + Vector2i(6, 4), Vector2i(21, 30)), shadow)
			_rect(Rect2i(origin + Vector2i(7, 4), Vector2i(17, 29)), fabric)
			_rect(Rect2i(origin + Vector2i(10, 4), Vector2i(2, 29)), "c3c2a7" if frame == 3 else "a99da8")
			_line(origin + Vector2i(7, 29), origin + Vector2i(23, 29), shadow)
			for fringe: int in range(7):
				_dot(origin + Vector2i(7 + fringe * 3, 34), fabric)
		for left: int in [9, 22]:
			_rect(Rect2i(origin + Vector2i(left, 0), Vector2i(2, 6)), "c5ad7e")
			_dot(origin + Vector2i(left, 1), "edcf90")
	_save("laundry.png")

func _cats() -> void:
	_new(Vector2i(384, 32))
	var head: Array = ["....s.....s...", "...sbs...sbs..", "...smds.smds..", "...sddddddds..", "..sbdddddddds.", "..sddeedeedds.", "..sdwppdwppds.", "..sdddnddddds.", "..sddddddbdss.", "...sbbwwbbss..", "....sbbbss....", ".....sss......"]
	var seated: Array = [".....ssssss.....", "...ssbbbbdds....", "..sbbddddddds...", ".sbbdddddddds...", ".sbbddddddddds..", ".sbdddddddddds..", ".sbddddddbbbbs..", ".sbbddddbswwbs..", "..sbbdddswwbs...", "...ssddswwbs....", "..shhsssshhhs..."]
	var running: Array = ["...ssssssssssss...", "..sbbbbbbbbddddss.", ".sbbbddddddddddds.", "sbbddddddddddddds.", "sbdddddddddddddds.", "sddddddddddbbbbs..", ".sddssssdddswws...", "..ss....sss.ss...."]
	for frame: int in range(12):
		var origin: Vector2i = Vector2i(frame * 32, 0)
		var bob: int = 1 if frame == 1 or frame == 4 or frame == 6 else 0
		if frame < 3:
			_pixels(origin + Vector2i(6, 20), seated)
			_pixels(origin + Vector2i(14, 8 + bob), head)
			_pixels(origin + Vector2i(0, 14 + bob), ["..sss..", ".sbbbs.", "sbs.ss.", "sb.....", "sb.....", "sbs....", ".sbs...", "..sbs..", "...sbs.", "....sbs", ".....sb", ".....sb", "....ssb", "...sbbb", "....sss"])
			if frame == 2:
				_rect(Rect2i(origin + Vector2i(18, 13), Vector2i(7, 2)), "1c2636")
				_line(origin + Vector2i(18, 14), origin + Vector2i(20, 14), "819ba0")
				_line(origin + Vector2i(22, 14), origin + Vector2i(24, 14), "819ba0")
		elif frame <= 6:
			_pixels(origin + Vector2i(3, 17 + bob), running)
			_pixels(origin + Vector2i(18, 9 + bob), head)
			var stride: int = [0, 3, 0, -3][frame - 3]
			_leg(origin + Vector2i(8, 23), origin + Vector2i(8 - stride, 30), "2e3d4c")
			_leg(origin + Vector2i(19, 23), origin + Vector2i(19 + stride, 30), "547080")
			_leg(origin + Vector2i(5, 20), origin + Vector2i(1, 12 + stride), "547080")
		elif frame == 7 or frame == 8:
			_pixels(origin + Vector2i(5, 16), running)
			_pixels(origin + Vector2i(17, 5 if frame == 7 else 11), head)
			_leg(origin + Vector2i(18, 21), origin + Vector2i(25, 24 if frame == 7 else 29), "819ba0")
			_leg(origin + Vector2i(8, 22), origin + Vector2i(4, 28), "547080")
			_leg(origin + Vector2i(6, 20), origin + Vector2i(1, 12), "547080")
		elif frame == 9 or frame == 10:
			_pixels(origin + Vector2i(5, 21), seated)
			_pixels(origin + Vector2i(10, 13), head)
			_leg(origin + Vector2i(13, 25), origin + Vector2i(9, 11), "547080")
			_leg(origin + Vector2i(22, 25), origin + Vector2i(23, 11), "819ba0")
			_rect(Rect2i(origin + Vector2i(7, 10), Vector2i(5, 3)), "bbcdc3")
			_rect(Rect2i(origin + Vector2i(21, 10), Vector2i(5, 3)), "bbcdc3")
			_leg(origin + Vector2i(9, 28), origin + Vector2i(2 + (frame - 9) * 2, 23), "547080")
		else:
			_pixels(origin + Vector2i(5, 18), running)
			_pixels(origin + Vector2i(16, 7), head)
			_leg(origin + Vector2i(11, 23), origin + Vector2i(4, 28), "819ba0")
			_leg(origin + Vector2i(21, 23), origin + Vector2i(29, 28), "819ba0")
			_leg(origin + Vector2i(8, 18), origin + Vector2i(1, 9), "819ba0")
	_save("cat_poses.png")

func _leg(start: Vector2i, end: Vector2i, color: String) -> void:
	_line(start + Vector2i(-1, 0), end + Vector2i(-1, 0), "101724")
	_line(start, end, color)
	_line(start + Vector2i(1, 0), end + Vector2i(1, 0), "2e3d4c")
	_rect(Rect2i(end, Vector2i(4, 2)), color)

func _dogs() -> void:
	_new(Vector2i(192, 32))
	var body: Array = ["....aaaaaaa..........", "..aattttrrraaaa......", ".atrtttrrrrraaara....", "atrtttrrrrrraaaara...", "arrrrrrrrrrraaaara...", "arrrrrrrrrrraaaaraa..", "aarrrrrrraaaaaaaa...", ".aaaaarraaaaarraa...", "...aaarrraaaarrra...", ".....aaaa....aaaa..."]
	var head: Array = ["...aaaaaaa....", "..aattttttaa..", ".attttrrrrra..", "atrraatrrrrra.", "arraaatrtprra.", "araaaarrrrrra.", "arraarrrtttta.", ".aaaarrttttooo", "..aarttttttooo", "...aartttttta.", "....aarraaaa..", ".....mmmmmm..."]
	for frame: int in range(4):
		var origin: Vector2i = Vector2i(frame * 48, 0)
		var bob: int = frame % 2
		_pixels(origin + Vector2i(8, 12 + bob), body)
		_pixels(origin + Vector2i(29, 6 + bob), head)
		var stride: int = [0, 3, 0, -3][frame]
		for leg: int in [13, 29]:
			_rect(Rect2i(origin + Vector2i(leg + stride * (-1 if leg == 13 else 1), 21), Vector2i(4, 7)), "9e6e58")
			_rect(Rect2i(origin + Vector2i(leg + stride * (-1 if leg == 13 else 1) - 1, 27), Vector2i(6, 3)), "d0a37d")
		_line(origin + Vector2i(10, 15), origin + Vector2i(5, 7 + bob), "d9a475")
		_line(origin + Vector2i(9, 16), origin + Vector2i(4, 8 + bob), "8c6259")
		_dot(origin + Vector2i(37, 11 + bob), "edd6aa")
	_save("dog_run.png")
