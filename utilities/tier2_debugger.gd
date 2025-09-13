class_name Tier2Debugger
extends TierDebugger

@export var radius: float = 30
@export_range(0.0, 1.0, 0.05) var alpha: float = 0.3
@export var sector_line_width: float = 2.0
@export var middle_vector_color: Color = Color.RED

# Middle direction vector (normalized), set externally
var mid_vector: Vector2 = Vector2.RIGHT

func _draw() -> void:
	# Draw the circle with 4 sectors (N/E/S/W)
	for i in range(4):
		var start_angle = deg_to_rad(90 * i)
		var end_angle   = deg_to_rad(90 * (i + 1))
		
		# Triangle fan for the sector
		var points = [Vector2.ZERO]
		var steps = 6  # smoother wedge
		for j in range(steps + 1):
			var t = float(j) / steps
			var angle = lerp(start_angle, end_angle, t)
			points.append(Vector2.RIGHT.rotated(angle) * radius)
		
		var color = Color.from_hsv(i / 4.0, 0.6, 0.9, alpha)
		draw_colored_polygon(points, color)
	
	# Draw the middle direction vector as a line
	draw_line(Vector2.ZERO, mid_vector * radius, middle_vector_color, sector_line_width)
