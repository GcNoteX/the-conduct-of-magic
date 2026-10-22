class_name AutoCarver
extends RefCounted

## Test and bot helper: carves an enchantment on an item the way a simple player would, through
## the real InscriptionBoard rules. It tries every origin and rotation in turn, puts the first
## material in `preferred` that each node accepts and the inventory holds, then draws the
## shortest free line from each node that isn't active yet to a magic node it doesn't reach,
## until every node is active, and commits.
## It is greedy, so a "no" means it found no way, not that none exists.

## Why the last carve() failed, or "" after a success
var last_error := ""

var _board: InscriptionBoard
var _preferred: Array[EnchantmentMaterialDefinition] = []


## `preferred` is the order materials are tried in; the cheapest first suits a thrifty player
func _init(board: InscriptionBoard, preferred: Array[EnchantmentMaterialDefinition]) -> void:
	_board = board
	_preferred = preferred


## Carves and commits `e`, returning its committed placement, or null if no try worked. A failed
## try is taken off the item again, so its materials go back to the inventory.
func carve(e: Enchantment) -> PlacementState:
	last_error = "It doesn't fit anywhere on the item"
	for rotation in 6:
		for origin in _board.get_cells():
			if _board.check_place(e, origin, rotation) != "":
				continue
			var p := _board.place(e, origin, rotation)
			var err := _fill(p)
			if err == "":
				err = _activate(p)
			if err == "":
				err = _board.check_commit()
			if err == "":
				_board.commit()
				last_error = ""
				return p
			last_error = err
			_board.remove_placement(p)
	return null


## Puts a material into each node of the draft
func _fill(p: PlacementState) -> String:
	for i in p.enchantment.nodes.size():
		var key := InscriptionBoard.enchantment_key(p.id, i)
		var chosen: EnchantmentMaterialDefinition = null
		for m in _preferred:
			if _board.check_insert(key, m) == "":
				chosen = m
				break
		if chosen == null:
			return "No material in stock fits node %d" % i
		_board.insert_material(key, chosen)
	return ""


## Draws lines until every node of the draft is active
func _activate(p: PlacementState) -> String:
	for i in p.enchantment.nodes.size():
		var key := InscriptionBoard.enchantment_key(p.id, i)
		while not _board.is_node_active(key):
			var path := _path_to_new_magic_node(key)
			if path.is_empty():
				return "No free path from node %d to another magic node" % i
			if _board.add_line(path) == null:
				return "The board refused a line: " + _board.check_line(path)
	return ""


## The shortest line from one of the node's ports to a magic node outside its chain, through
## free cells, or [] if there's none
func _path_to_new_magic_node(key: String) -> Array[Vector2i]:
	var reached := _board.component(key)
	var parent: Dictionary[Vector2i, Vector2i] = {}
	var frontier: Array[Vector2i] = []
	for port in _board.node_ports(key):
		parent[port] = port
		frontier.append(port)
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		for next in Hex.neighbours(cell):
			if parent.has(next) or not _board.has_cell(next):
				continue
			var end := _board.node_at(next)
			if end != "":
				if _board.is_magic(end) and end not in reached:
					parent[next] = cell
					var path := _trace(parent, next)
					if _board.check_line(path) == "":
						return path
				continue
			if _board.node_covering(next) != "" or _board.is_occupied(next):
				continue
			parent[next] = cell
			frontier.append(next)
	return []


func _trace(parent: Dictionary[Vector2i, Vector2i], end: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [end]
	var c := end
	while parent[c] != c:
		c = parent[c]
		out.push_front(c)
	return out
