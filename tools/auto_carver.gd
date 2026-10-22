class_name AutoCarver
extends RefCounted

## Test and bot helper: carves an enchantment on an item the way a simple player would, through
## the real InscriptionBoard rules. It tries every origin and rotation in turn, puts the first
## material in `preferred` that each node accepts and the inventory holds, then draws the
## shortest free line from each node that isn't active yet to a magic node it doesn't reach,
## until every node is active, and commits.
## It is greedy, so a "no" means it found no way, not that none exists.

## Trying every order is quick up to this many enchantments; past it only the given order is tried
const MAX_ORDERED := 4
## Stock a trial carve gets of each preferred material
const TRIAL_STOCK := 20

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


## The order to carve `list` in on `item` that carves the most of them, trying every order on a
## copy of the item with plenty of stock. The item itself isn't touched. Each enchantment is
## placed where it first fits, so an earlier one can crowd out a later one; the order matters.
static func best_order(
	item: ItemInstance,
	list: Array[Enchantment],
	preferred: Array[EnchantmentMaterialDefinition],
) -> Array[Enchantment]:
	var orders: Array = [list.duplicate()]
	if list.size() <= MAX_ORDERED:
		orders = _orders(list)
	var best: Array[Enchantment] = []
	for order: Array[Enchantment] in orders:
		var trial_player := Player.new()
		for m in preferred:
			trial_player.add_material(m, TRIAL_STOCK)
		var trial := AutoCarver.new(
			InscriptionBoard.new(item.duplicate(true), trial_player), preferred
		)
		var carved: Array[Enchantment] = []
		for e in order:
			if trial.carve(e) == null:
				break
			carved.append(e)
		if carved.size() > best.size():
			best = carved
		if best.size() == list.size():
			break
	return best


## Every order of `list`
static func _orders(list: Array[Enchantment]) -> Array:
	if list.size() <= 1:
		return [list.duplicate()]
	var out: Array = []
	for i in list.size():
		var rest := list.duplicate()
		var first: Enchantment = rest.pop_at(i)
		for tail: Array[Enchantment] in _orders(rest):
			var order: Array[Enchantment] = [first]
			order.append_array(tail)
			out.append(order)
	return out


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


## Draws lines until every node of the draft is active. A node short of lines is joined to a
## node its enchantment already reaches if it can be, so magic nodes aren't spent on it; a node
## short of magic nodes is joined to whatever reaches one it doesn't.
func _activate(p: PlacementState) -> String:
	for i in p.enchantment.nodes.size():
		var key := InscriptionBoard.enchantment_key(p.id, i)
		while not _board.is_node_active(key):
			var family := _family(p)
			var mine := _board.component(key)
			var wants_reach := _wants_reach(key)
			var path := _shortest_line(
				key,
				func(t: String) -> bool: return t in family and (not wants_reach or t not in mine)
			)
			if path.is_empty():
				path = _shortest_line(
					key, func(t: String) -> bool: return _board.is_magic(t) and t not in family
				)
			if path.is_empty():
				return "No free path from node %d to a node that would help" % i
			if _board.add_line(path) == null:
				return "The board refused a line: " + _board.check_line(path)
	return ""


## Whether the node's material is still short of magic nodes reached (not just of lines)
func _wants_reach(key: String) -> bool:
	var ctx := MaterialActivationContext.for_board(_board, key)
	for c in _board.node_material(key).activation_conditions:
		if c is NumberOfConnectionsCondition and not c.is_fulfilled(ctx):
			return true
	return false


## Every node the placement's nodes reach, its own nodes included
func _family(p: PlacementState) -> Array[String]:
	var out: Array[String] = []
	for i in p.enchantment.nodes.size():
		for k in _board.component(InscriptionBoard.enchantment_key(p.id, i)):
			if k not in out:
				out.append(k)
	return out


## The shortest line from one of the node's ports, through free cells, to a node `wanted`
## accepts and the rules allow a line to, or [] if there's none
func _shortest_line(key: String, wanted: Callable) -> Array[Vector2i]:
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
				if end != key and wanted.call(end):
					var path := _trace(parent, cell)
					path.append(next)
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
