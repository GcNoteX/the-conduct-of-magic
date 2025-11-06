extends Node

func get_line_length(line: Line2D) -> float:
	var length := 0.0
	var points = line.points
	for i in range(points.size() - 1):
		length += points[i].distance_to(points[i + 1])
	return length

func _is_same_source(a: MapLine, b: MapLine) -> bool:
	var same = false

	if a.start and b.start:
		same = same or a.start.owner == b.start.owner
	if a.end and b.start:
		same = same or a.end.owner == b.start.owner
	if a.start and b.end:
		same = same or a.start.owner == b.end.owner
	if a.end and b.end:
		same = same or a.end.owner == b.end.owner

	return same
