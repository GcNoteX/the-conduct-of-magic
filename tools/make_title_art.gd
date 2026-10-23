extends Node

"""
Draws the placeholder pixel art for the studio splash and the main menu: a workshop at night,
the game's name on a wooden plaque, and a small studio mark. Each image is drawn small and shown
scaled up with nearest filtering, so every pixel stays a crisp square.
Run: godot --headless --path . res://tools/make_title_art.tscn
Rerunning overwrites the PNGs in OUT_DIR.
"""

const OUT_DIR := "res://art/title/"
const BACKGROUND_SIZE := Vector2i(320, 180)
const MARK_SIZE := 24
const TITLE := "THE CONDUCT OF MAGIC"
const GLYPH_WIDTH := 5
const GLYPH_HEIGHT := 7
const LETTER_GAP := 1
const WORD_GAP := 4
const PLAQUE_PADDING := Vector2i(8, 6)

## A 5×7 bitmap font for the letters in TITLE: one string per row, "#" for a lit pixel
const GLYPHS: Dictionary[String, Array] = {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
}

## The palette every image draws from
const INK := Color("140c08")
const SKY := Color("1b2340")
const SKY_LOW := Color("2a3560")
const MOON := Color("e8e2c0")
const STAR := Color("c8d0f0")
const WALL := Color("3b2618")
const WALL_LIGHT := Color("4a3020")
const SEAM := Color("2a1a10")
const WOOD := Color("5a3a22")
const WOOD_LIGHT := Color("6b4528")
const WOOD_DARK := Color("3a2414")
const PARCHMENT := Color("e8d8a8")
const PARCHMENT_SHADE := Color("c8b480")
const RUNE_GLOW := Color("7ee0ff")
const GOLD := Color("e0b850")
const GOLD_DARK := Color("a07828")
const CANDLE := Color("e8e0c8")
const FLAME := Color("ffd060")
const FLAME_CORE := Color("fff4c0")
const STONE_COLORS: Array[Color] = [
	Color("c8384a"), Color("3c5ccc"), Color("e0c040"), Color("e07030"), Color("40a0d0")
]
const CANDLE_LIGHT := Color(1.0, 0.75, 0.4)
## How strongly the candle lights the room, and how far its light reaches, in pixels
const CANDLE_LIGHT_STRENGTH := 0.35
const CANDLE_LIGHT_RADIUS := 70.0
## How dark the corners get, from 0 (no vignette) to 1 (black)
const VIGNETTE_STRENGTH := 0.55
## A 4×4 ordered-dither threshold map, so light and shade fall off in pixel steps
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const LIGHT_STEPS := 4.0

var _img: Image


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save(_draw_background(), "title_background.png")
	_save(_draw_plaque(), "title_logo.png")
	_save(_draw_mark(), "studio_mark.png")
	get_tree().quit()


func _save(img: Image, file_name: String) -> void:
	var err := img.save_png(ProjectSettings.globalize_path(OUT_DIR + file_name))
	print("%s %s" % ["Saved" if err == OK else "Couldn't save", OUT_DIR + file_name])


func _draw_background() -> Image:
	var w := BACKGROUND_SIZE.x
	var h := BACKGROUND_SIZE.y
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Wall of vertical planks
	for x in w:
		var plank := x / 16
		var c := WALL_LIGHT if plank % 2 == 0 else WALL
		if x % 16 == 0:
			c = SEAM
		_rect(x, 0, 1, h, c)
	# Window with the night sky and the moon
	_rect(22, 14, 54, 60, WOOD_DARK)
	_rect(25, 17, 48, 54, SKY)
	_rect(25, 52, 48, 19, SKY_LOW)
	_disc(60, 30, 6, MOON)
	_disc(62, 28, 5, SKY)
	for star: Vector2i in [Vector2i(32, 24), Vector2i(44, 20), Vector2i(38, 40), Vector2i(66, 46)]:
		_img.set_pixelv(star, STAR)
	_rect(48, 17, 2, 54, WOOD_DARK)
	_rect(25, 43, 48, 2, WOOD_DARK)
	_rect(20, 74, 58, 4, WOOD_LIGHT)
	# Shelves of stones and jars on the right
	for shelf_y: int in [44, 78]:
		_rect(214, shelf_y, 90, 4, WOOD_LIGHT)
		_rect(214, shelf_y + 4, 90, 2, WOOD_DARK)
	for i in 5:
		_gem(222 + i * 16, 38, STONE_COLORS[i])
	for i in 4:
		var jar_x := 220 + i * 21
		_rect(jar_x, 62, 10, 16, STONE_COLORS[(i + 2) % STONE_COLORS.size()].darkened(0.45))
		_rect(jar_x + 1, 63, 8, 14, STONE_COLORS[(i + 2) % STONE_COLORS.size()].darkened(0.2))
		_rect(jar_x + 2, 60, 6, 3, WOOD_DARK)
		_rect(jar_x + 2, 65, 2, 8, Color(1, 1, 1, 0.35))
	# The workbench
	_rect(0, 124, w, 8, WOOD_LIGHT)
	_rect(0, 132, w, 2, WOOD_DARK)
	_rect(0, 134, w, h - 134, WOOD)
	for x in range(0, w, 40):
		_rect(x, 134, 1, h - 134, WOOD_DARK)
	# Parchment with a glowing hex rune
	_rect(134, 112, 56, 14, PARCHMENT_SHADE)
	_rect(135, 112, 54, 12, PARCHMENT)
	_hexagon(162, 118, 5, RUNE_GLOW)
	_img.set_pixel(162, 118, RUNE_GLOW)
	# A stone waiting on the bench, and the candle
	_gem(206, 118, STONE_COLORS[0])
	_rect(98, 108, 5, 16, CANDLE)
	_rect(98, 122, 5, 2, PARCHMENT_SHADE)
	_rect(100, 104, 1, 4, FLAME)
	_rect(99, 105, 3, 2, FLAME)
	_img.set_pixel(100, 106, FLAME_CORE)
	_light_and_vignette(Vector2(100, 104))
	return _img


## Warms the pixels near the candle and darkens the corners, both in dithered steps
func _light_and_vignette(candle: Vector2) -> void:
	var size := Vector2(_img.get_size())
	var centre := size / 2.0
	for y in _img.get_height():
		for x in _img.get_width():
			var threshold := (BAYER[(y % 4) * 4 + x % 4] + 0.5) / 16.0
			var c := _img.get_pixel(x, y)
			var light := clampf(1.0 - Vector2(x, y).distance_to(candle) / CANDLE_LIGHT_RADIUS, 0, 1)
			light = floorf(light * LIGHT_STEPS + threshold) / LIGHT_STEPS
			c = c.lerp(c * CANDLE_LIGHT * 1.6, light * CANDLE_LIGHT_STRENGTH)
			var edge := ((Vector2(x, y) - centre) / centre).length() / sqrt(2.0)
			var shade := floorf(edge * edge * LIGHT_STEPS + threshold) / LIGHT_STEPS
			c = c.lerp(INK, shade * VIGNETTE_STRENGTH)
			c.a = 1.0
			_img.set_pixel(x, y, c)


## The game's name in the bitmap font, on a wooden plaque with a gold border
func _draw_plaque() -> Image:
	var text_width := _text_width(TITLE)
	var w := text_width + PLAQUE_PADDING.x * 2
	var h := GLYPH_HEIGHT + PLAQUE_PADDING.y * 2
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	_rect(1, 0, w - 2, h, INK)
	_rect(0, 1, w, h - 2, INK)
	_rect(1, 1, w - 2, h - 2, WOOD)
	_rect(1, h - 3, w - 2, 2, WOOD_DARK)
	_outline(2, 2, w - 4, h - 4, GOLD_DARK)
	_outline(3, 3, w - 6, h - 6, GOLD)
	_text(TITLE, PLAQUE_PADDING.x + 1, PLAQUE_PADDING.y + 1, INK)
	_text(TITLE, PLAQUE_PADDING.x, PLAQUE_PADDING.y, PARCHMENT)
	return _img


## A gold ring around a glowing hex rune
func _draw_mark() -> Image:
	_img = Image.create(MARK_SIZE, MARK_SIZE, false, Image.FORMAT_RGBA8)
	var c := MARK_SIZE / 2
	_ring(c, c, 11, GOLD)
	_ring(c, c, 10, GOLD_DARK)
	_hexagon(c, c, 6, RUNE_GLOW)
	_rect(c - 1, c - 1, 2, 2, RUNE_GLOW)
	return _img


func _text_width(text: String) -> int:
	var width := 0
	for ch in text:
		width += WORD_GAP if ch == " " else GLYPH_WIDTH + LETTER_GAP
	return width - LETTER_GAP


func _text(text: String, x: int, y: int, color: Color) -> void:
	for ch in text:
		if ch == " ":
			x += WORD_GAP
			continue
		var rows: Array = GLYPHS[ch]
		for row in GLYPH_HEIGHT:
			var line: String = rows[row]
			for col in GLYPH_WIDTH:
				if line[col] == "#":
					_img.set_pixel(x + col, y + row, color)
		x += GLYPH_WIDTH + LETTER_GAP


func _rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	var area := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, _img.get_size()))
	if color.a >= 1.0:
		_img.fill_rect(area, color)
		return
	for py in range(area.position.y, area.end.y):
		for px in range(area.position.x, area.end.x):
			_img.set_pixel(px, py, _img.get_pixel(px, py).blend(color))


func _outline(x: int, y: int, w: int, h: int, color: Color) -> void:
	_rect(x, y, w, 1, color)
	_rect(x, y + h - 1, w, 1, color)
	_rect(x, y, 1, h, color)
	_rect(x + w - 1, y, 1, h, color)


func _disc(cx: int, cy: int, r: int, color: Color) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x * x + y * y <= r * r:
				_img.set_pixel(cx + x, cy + y, color)


func _ring(cx: int, cy: int, r: int, color: Color) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var d := x * x + y * y
			if d <= r * r and d > (r - 1) * (r - 1):
				_img.set_pixel(cx + x, cy + y, color)


## A pointy-topped hexagon outline, drawn as six straight edges
func _hexagon(cx: int, cy: int, r: int, color: Color) -> void:
	var corners: Array[Vector2] = []
	for i in 6:
		var angle := deg_to_rad(60.0 * i - 90.0)
		corners.append(Vector2(cx, cy) + Vector2(cos(angle), sin(angle)) * r)
	for i in 6:
		_line(corners[i], corners[(i + 1) % 6], color)


func _line(from: Vector2, to: Vector2, color: Color) -> void:
	var steps := int(maxf(absf(to.x - from.x), absf(to.y - from.y)))
	for i in steps + 1:
		var p := from.lerp(to, float(i) / maxf(steps, 1))
		_img.set_pixel(roundi(p.x), roundi(p.y), color)


## A cut stone: a small diamond with a light facet
func _gem(cx: int, cy: int, color: Color) -> void:
	for y in range(-3, 4):
		var half := 3 - absi(y)
		_rect(cx - half, cy + y, half * 2 + 1, 1, color if y < 1 else color.darkened(0.3))
	_img.set_pixel(cx - 1, cy - 1, color.lightened(0.5))
