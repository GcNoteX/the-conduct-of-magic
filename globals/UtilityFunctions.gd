extends Node

func get_line_length(line: Line2D) -> float:
	var length := 0.0
	var points = line.points
	for i in range(points.size() - 1):
		length += points[i].distance_to(points[i + 1])
	return length
