extends Node

func get_line_length(line: Line2D) -> float:
	var length := 0.0
	var points = line.points
	for i in range(points.size() - 1):
		length += points[i].distance_to(points[i + 1])
	return length

## Checks if lines are adjcent in any manner
func _are_adjacent_lines(a: MapLine, b: MapLine) -> bool:
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

func dfs_collect_nodes(start_nodes: Array, get_neighbors_func: Callable)\
 	-> Array[Variant]:
	"""
	Generic DFS utility.
	Traverses connected graph-like structures starting from `start_nodes`.

	- start_nodes: Array of starting nodes.
	- get_neighbors_func: Callable(node) -> Array of connected nodes.

	Returns all visited nodes (unique).
	"""
	var visited: = {}
	var stack: = start_nodes.duplicate()

	while stack.size() > 0:
		var node = stack.pop_back()
		if node == null or visited.has(node):
			continue

		visited[node] = true
		var neighbors = get_neighbors_func.call(node)
		for neighbor in neighbors:
			if neighbor != null and not visited.has(neighbor):
				stack.push_back(neighbor)

	return visited.keys()

func create_map_item(m: EnchantmentMaterial) -> MapItem:
	var ins = preload(SceneReferences.map_item).instantiate( ) as MapItem
	ins.e_material = m
	return ins
