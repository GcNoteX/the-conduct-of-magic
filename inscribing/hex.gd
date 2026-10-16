class_name Hex

"""
Pointy-top hex grid helpers.
- Board logic works in axial coordinates (q, r)
- Map layouts are authored in odd-r offset coordinates (col, row), one string per row
- Pixel conversions take the hex size (centre to corner)
"""

const SQRT3 := 1.7320508075688772

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

static func offset_to_axial(col: int, row: int) -> Vector2i:
	return Vector2i(col - (row - (row & 1)) / 2, row)

static func axial_to_offset(a: Vector2i) -> Vector2i:
	return Vector2i(a.x + (a.y - (a.y & 1)) / 2, a.y)

static func to_pixel(a: Vector2i, size: float) -> Vector2:
	return Vector2(size * SQRT3 * (a.x + a.y / 2.0), size * 1.5 * a.y)

static func from_pixel(p: Vector2, size: float) -> Vector2i:
	var q := (SQRT3 / 3.0 * p.x - p.y / 3.0) / size
	var r := (2.0 / 3.0 * p.y) / size
	return _round(q, r)

## Rotates an axial offset by `steps` × 60° clockwise around the origin
static func rotate(a: Vector2i, steps: int) -> Vector2i:
	var v := a
	for i in posmod(steps, 6):
		v = Vector2i(-v.y, v.x + v.y)
	return v

static func neighbours(a: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRECTIONS:
		out.append(a + d)
	return out

static func distance(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2

static func corners(centre: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(60 * i - 30)
		pts.append(centre + Vector2(cos(angle), sin(angle)) * size)
	return pts

static func _round(q: float, r: float) -> Vector2i:
	var x := q
	var z := r
	var y := -x - z
	var rx := roundf(x)
	var ry := roundf(y)
	var rz := roundf(z)
	var dx := absf(rx - x)
	var dy := absf(ry - y)
	var dz := absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy <= dz:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))
