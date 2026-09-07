class_name PixelFont
extends RefCounted
## An authored 5x7 bitmap alphabet: every mark aligns to a native pixel.

const INK: Color = Color("101829")
const PAPER: Color = Color("edd6aa")
const GOLD: Color = Color("dfa760")
const MUTED: Color = Color("82979b")
const MINT: Color = Color("88c5ab")
const GLYPHS: Dictionary = {
	"A": [14,17,17,31,17,17,17], "B": [30,17,17,30,17,17,30],
	"C": [14,17,16,16,16,17,14], "D": [30,17,17,17,17,17,30],
	"E": [31,16,16,30,16,16,31], "F": [31,16,16,30,16,16,16],
	"G": [14,17,16,23,17,17,15], "H": [17,17,17,31,17,17,17],
	"I": [14,4,4,4,4,4,14], "J": [7,2,2,2,18,18,12],
	"K": [17,18,20,24,20,18,17], "L": [16,16,16,16,16,16,31],
	"M": [17,27,21,21,17,17,17], "N": [17,25,21,19,17,17,17],
	"O": [14,17,17,17,17,17,14], "P": [30,17,17,30,16,16,16],
	"Q": [14,17,17,17,21,18,13], "R": [30,17,17,30,20,18,17],
	"S": [15,16,16,14,1,1,30], "T": [31,4,4,4,4,4,4],
	"U": [17,17,17,17,17,17,14], "V": [17,17,17,17,17,10,4],
	"W": [17,17,17,21,21,21,10], "X": [17,17,10,4,10,17,17],
	"Y": [17,17,10,4,4,4,4], "Z": [31,1,2,4,8,16,31],
	"0": [14,17,19,21,25,17,14], "1": [4,12,4,4,4,4,14],
	"2": [14,17,1,2,4,8,31], "3": [30,1,1,14,1,1,30],
	"4": [2,6,10,18,31,2,2], "5": [31,16,16,30,1,1,30],
	"6": [14,16,16,30,17,17,14], "7": [31,1,2,4,8,8,8],
	"8": [14,17,17,14,17,17,14], "9": [14,17,17,15,1,1,14],
	"!": [4,4,4,4,4,0,4], "?": [14,17,1,2,4,0,4],
	".": [0,0,0,0,0,0,4], ":": [0,4,0,0,4,0,0],
	"/": [1,1,2,4,8,16,16], "-": [0,0,0,31,0,0,0],
	"+": [0,4,4,31,4,4,0], "%": [25,26,2,4,8,11,19],
	"'": [4,4,8,0,0,0,0], "<": [2,4,8,16,8,4,2],
	">": [8,4,2,1,2,4,8], "=": [0,31,0,31,0,0,0],
	"(": [2,4,8,8,8,4,2], ")": [8,4,2,2,2,4,8],
	"|": [4,4,4,4,4,4,4], " ": [0,0,0,0,0,0,0],
	"&": [12,18,20,8,21,18,13], ",": [0,0,0,0,0,4,8],
	";": [0,4,0,0,4,4,8]
}

static func width(value: String, pixel_size: int = 1) -> float:
	return float(maxi(0, value.length() * 6 - 1) * pixel_size)

static func text(canvas: CanvasItem, value: String, at: Vector2, color: Color = PAPER, pixel_size: int = 1) -> void:
	var cursor: Vector2 = at.round()
	for character: String in value.to_upper():
		var rows: Array = GLYPHS.get(character, GLYPHS["?"])
		for row: int in range(7):
			for column: int in range(5):
				if int(rows[row]) & (1 << (4 - column)):
					canvas.draw_rect(Rect2(cursor + Vector2(column, row) * pixel_size, Vector2.ONE * pixel_size), color)
		cursor.x += 6 * pixel_size

static func centered(canvas: CanvasItem, value: String, at: Vector2, color: Color = PAPER, pixel_size: int = 1) -> void:
	text(canvas, value, at - Vector2(width(value, pixel_size) * 0.5, 0), color, pixel_size)

static func panel(canvas: CanvasItem, rect: Rect2, fill: Color = INK, edge: Color = Color("455563")) -> void:
	canvas.draw_rect(Rect2(rect.position + Vector2(2, 3), rect.size), Color(0.02, 0.04, 0.08, 0.5))
	canvas.draw_rect(rect, fill)
	canvas.draw_rect(rect.grow(-0.5), edge, false, 1.0)
	for corner: Vector2 in [rect.position, rect.position + Vector2(rect.size.x - 2, 0), rect.end - Vector2(2, 2), rect.position + Vector2(0, rect.size.y - 2)]:
		canvas.draw_rect(Rect2(corner, Vector2(2, 2)), GOLD)
