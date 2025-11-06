extends Node

func get_line_length(line: Line2D) -> float:
	var length := 0.0
	var points = line.points
	for i in range(points.size() - 1):
		length += points[i].distance_to(points[i + 1])
	return length

## Checks the identities of the owner's behind each map line 
func _is_same_source(a: MapLine, b: MapLine) -> bool:
	var same = false

	if a.start and b.start:
		same = same or a.start == b.start
	if a.end and b.start:
		same = same or a.end == b.start
	if a.start and b.end:
		same = same or a.start == b.end
	if a.end and b.end:
		same = same or a.end == b.end

	return same
