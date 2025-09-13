class_name Tier1Debugger
extends TierDebugger

@export var radius: float = 30
@export_range(0.0, 1.0, 0.05) var alpha: float = 0.7
# alpha controls transparency:
#   low value (close to 0) → more transparent (faint wedges)
#   high value (close to 1) → more opaque (solid wedges)

@export var steps: int = 6
# steps controls how smooth the wedge edges look:
#   low value (e.g. 2–3) → rough, blocky wedge edges
#   high value (e.g. 12–20) → smoother curves, more polygons drawn

func _draw() -> void:
	for i in range(8):
		var start_angle = deg_to_rad(45 * i - 22.5)
		var end_angle   = deg_to_rad(45 * i + 22.5)

		# Approximate wedge with triangle fan
		var points = [Vector2.ZERO]

		for j in range(steps + 1):
			var t = float(j) / steps
			var angle = lerp(start_angle, end_angle, t)
			points.append(Vector2.RIGHT.rotated(angle) * radius)

		# hue changes per wedge, alpha is exported
		var color = Color.from_hsv(i / 8.0, 0.6, 0.9, alpha)
		draw_colored_polygon(points, color)
