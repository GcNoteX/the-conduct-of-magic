class_name BotCarver
extends RefCounted

## How the playtest bot works an inscription board: finds a spot for an enchantment, fills its
## nodes with the cheapest materials they accept, and routes lines to free magic nodes until
## every node is active. It only uses the board's public rules, so anything it can do a player
## can do with the mouse.

var rng: RandomNumberGenerator
var catalogue: SupplierCatalogue
## Why the last carve() failed, for the report
var last_failure: String = ""


func _init(random: RandomNumberGenerator, supplier: SupplierCatalogue) -> void:
	rng = random
	catalogue = supplier


## Places `e` on the board and activates it, trying up to `tries` spots. Leaves an active draft
## on success; on failure takes everything it added back off and returns null.
func carve(board: InscriptionBoard, e: Enchantment, tries: int) -> PlacementState:
	var spots := free_spots(board, e)
	if spots.is_empty():
		last_failure = "no room on the item"
		return null
	_shuffle(spots)
	last_failure = ""
	for s in spots.slice(0, tries):
		var p := board.place(e, s[0], s[1])
		if p == null:
			last_failure = "a free spot was refused"
			continue
		var added: Array[LineState] = []
		var why := _activate(board, p, added)
		if why == "":
			return p
		last_failure = why
		for l in added:
			if l in board.state.lines:
				board.remove_line(l)
		board.remove_placement(p)
	return null


## Every [origin, rotation] where `e` fits right now
func free_spots(board: InscriptionBoard, e: Enchantment) -> Array:
	var out := []
	for c in board.get_cells():
		for r in 6:
			if board.check_place(e, c, r) == "":
				out.append([c, r])
	return out


## The materials the player holds that this node accepts, cheapest first
func usable_materials(board: InscriptionBoard, key: String) -> Array[EnchantmentMaterialDefinition]:
	var out: Array[EnchantmentMaterialDefinition] = []
	var def := board.node_definition(key)
	for m in board.inventory.material_inventory:
		if board.inventory.get_material_count(m) > 0 and def.accepts(m):
			out.append(m)
	out.sort_custom(_cheaper)
	return out


## The cheapest material the supplier sells that a pattern node accepts, or null
func cheapest_for(node: EnchantmentPatternNode) -> EnchantmentMaterialDefinition:
	var best: EnchantmentMaterialDefinition = null
	for m in catalogue.materials():
		if node.accepts(m) and (best == null or _cheaper(m, best)):
			best = m
	return best


## Draws one line from `from_key` to a node that `accepts_end` likes, by the shortest free
## route. Returns the line, or null when there is no route.
func route_line(board: InscriptionBoard, from_key: String, accepts_end: Callable) -> LineState:
	for start in board.node_ports(from_key):
		if board.check_line_start(start) != "":
			continue
		var path := _shortest_route(board, start, from_key, accepts_end)
		if not path.is_empty():
			return board.add_line(path)
	return null


## A magic node `key` may still be wired to: not already in its chain and not bound to
## another enchantment
func is_free_magic(board: InscriptionBoard, key: String, end: String) -> bool:
	return board.is_magic(end) and board.is_dead(end) and end not in board.component(key)


## Cheaper first, then in the supplier's order, so planning and carving pick the same stones
func _cheaper(a: EnchantmentMaterialDefinition, b: EnchantmentMaterialDefinition) -> bool:
	var pa := catalogue.price_of(a)
	var pb := catalogue.price_of(b)
	if pa != pb:
		return pa < pb
	var stock := catalogue.materials()
	return stock.find(a) < stock.find(b)


func _activate(board: InscriptionBoard, p: PlacementState, added: Array[LineState]) -> String:
	# Fill the pickiest nodes first, so a node that takes anything doesn't use up the only
	# stone another node accepts
	var order: Array[String] = []
	for i in p.enchantment.nodes.size():
		order.append(InscriptionBoard.enchantment_key(p.id, i))
	order.sort_custom(
		func(a: String, b: String) -> bool:
			return usable_materials(board, a).size() < usable_materials(board, b).size()
	)
	for key in order:
		var options := usable_materials(board, key)
		if options.is_empty():
			return "no material for %s" % board.node_definition(key).describe_requirements()
		board.insert_material(key, options[0])
	for i in p.enchantment.nodes.size():
		var key := InscriptionBoard.enchantment_key(p.id, i)
		var options := usable_materials(board, key)
		options.push_front(board.node_material(key))
		for m in options:
			if board.node_material(key) != m and board.insert_material(key, m) != "":
				continue
			while not board.is_node_active(key):
				var l := route_line(
					board, key, func(end: String) -> bool: return is_free_magic(board, key, end)
				)
				if l == null:
					break
				added.append(l)
			if board.is_node_active(key):
				break
		if not board.is_node_active(key):
			return "couldn't meet %s" % _conditions_text(board, key)
	return ""


func _conditions_text(board: InscriptionBoard, key: String) -> String:
	var parts: Array[String] = []
	for c in board.condition_status(key):
		if not c[1]:
			parts.append(c[0])
	return ", ".join(parts) if not parts.is_empty() else "its conditions"


func _shortest_route(
	board: InscriptionBoard, start: Vector2i, from_key: String, accepts_end: Callable
) -> Array[Vector2i]:
	var came_from: Dictionary[Vector2i, Vector2i] = {start: start}
	var frontier: Array[Vector2i] = [start]
	var head := 0
	while head < frontier.size():
		var at: Vector2i = frontier[head]
		head += 1
		for n in Hex.neighbours(at):
			if came_from.has(n) or not board.has_cell(n):
				continue
			var end := board.node_at(n)
			if end != "" and end != from_key and accepts_end.call(end):
				var path: Array[Vector2i] = [n]
				var back := at
				while back != start:
					path.push_front(back)
					back = came_from[back]
				path.push_front(start)
				if board.check_line(path) == "":
					return path
				continue
			if board.node_covering(n) != "" or board.is_occupied(n):
				continue
			came_from[n] = at
			frontier.append(n)
	return []


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t
