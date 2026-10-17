# gdlint: disable=max-public-methods
# A rules facade the view and tests query from many angles, so it keeps a wide public API.
class_name InscriptionBoard
extends RefCounted

"""
The rules of carving on one item's hex map. Pure logic, no drawing, so it can be tested headless.
- Wraps an ItemInstance: its map comes from the definition,
  its plan and carvings from its GraphState
- Nodes are addressed by key: "m:q,r" for magic nodes,
  "e:<placement id>:<node index>" for enchantment nodes
- Positions are in unit hex space (hex size 1); views scale them
- Lines run cell by cell between two nodes and fill every cell between them,
  so "lines can't cross" means "no two lines share a cell"
- Every check_* returns "" when allowed, or a player-facing reason when not
"""

var item: ItemInstance
var map: HexMapDefinition
var state: GraphState

var _cells: Dictionary = {}  ## Vector2i -> true
var _magic_cells: Array[Vector2i] = []
var _nodes: Dictionary = {}  ## key -> {kind, cell, placement, index}
var _cell_to_node: Dictionary = {}  ## Vector2i -> key
var _adjacency: Dictionary = {}  ## key -> Array[String], drawn lines only
var _occupied: Dictionary = {}  ## Vector2i -> LineState, or PlacementState for its fixed lines
var _extra_cells: Dictionary = {}  ## Vector2i -> key of the multi-cell node covering it


func _init(item_instance: ItemInstance) -> void:
	item = item_instance
	var def := item.definition as EnchantableItemDefinition
	assert(
		def and def.map_template,
		"InscriptionBoard needs an EnchantableItemDefinition with a map_template"
	)
	map = def.map_template
	if item.enchantment_graph_state == null:
		item.enchantment_graph_state = GraphState.new()
	state = item.enchantment_graph_state
	for c in map.get_cells():
		_cells[c] = true
	_magic_cells = map.get_magic_nodes()
	_rebuild()


#
# ── Keys and lookups ─────────────────────────────
#
static func magic_key(cell: Vector2i) -> String:
	return "m:%d,%d" % [cell.x, cell.y]


static func enchantment_key(placement_id: int, index: int) -> String:
	return "e:%d:%d" % [placement_id, index]


func get_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(_cells.keys())
	return out


func has_cell(c: Vector2i) -> bool:
	return _cells.has(c)


func get_node_keys() -> Array[String]:
	var out: Array[String] = []
	out.assign(_nodes.keys())
	return out


func has_node(key: String) -> bool:
	return _nodes.has(key)


func node_at(cell: Vector2i) -> String:
	return _cell_to_node.get(cell, "")


## The node covering `cell`, by its own cell or one of its extra cells, or ""
func node_covering(cell: Vector2i) -> String:
	return _cell_to_node.get(cell, _extra_cells.get(cell, ""))


func node_cell(key: String) -> Vector2i:
	return _nodes[key].cell


func node_position(key: String) -> Vector2:
	return Hex.to_pixel(_nodes[key].cell, 1.0)


func is_magic(key: String) -> bool:
	return _nodes.has(key) and _nodes[key].kind == "magic"


func node_placement(key: String) -> PlacementState:
	return _nodes[key].placement if _nodes.has(key) else null


func node_index(key: String) -> int:
	return _nodes[key].index if _nodes.has(key) else -1


func node_material(key: String) -> EnchantmentMaterialDefinition:
	var p := node_placement(key)
	return p.materials[node_index(key)] if p else null


func node_definition(key: String) -> EnchantmentPatternNode:
	var p := node_placement(key)
	return p.enchantment.nodes[node_index(key)] if p else null


func placement_cells(e: Enchantment, origin: Vector2i, rotation_steps: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for n in e.nodes:
		out.append(origin + Hex.rotate(n.offset, rotation_steps))
	return out


## The extra cells of an enchantment's multi-cell nodes placed this way
func node_extra_cells(e: Enchantment, origin: Vector2i, rotation_steps: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for n in e.nodes:
		for c in n.extra_cells:
			out.append(origin + Hex.rotate(n.offset + c, rotation_steps))
	return out


## Each fixed line of an enchantment placed this way, as its full cell path from node to node
func pattern_line_paths(e: Enchantment, origin: Vector2i, rotation_steps: int) -> Array:
	var nodes := placement_cells(e, origin, rotation_steps)
	var out := []
	for l in e.lines:
		var path: Array[Vector2i] = [nodes[l.from_node]]
		for c in l.cells:
			path.append(origin + Hex.rotate(c, rotation_steps))
		path.append(nodes[l.to_node])
		out.append(path)
	return out


## Every cell an enchantment placed this way covers: its nodes (with their extra cells)
## and the cells of its fixed lines
func footprint(e: Enchantment, origin: Vector2i, rotation_steps: int) -> Array[Vector2i]:
	var out := placement_cells(e, origin, rotation_steps)
	out.append_array(node_extra_cells(e, origin, rotation_steps))
	for l in e.lines:
		for c in l.cells:
			out.append(origin + Hex.rotate(c, rotation_steps))
	return out


## The placed enchantments' own fixed lines: [{a, b, cells, placement}]
func fixed_lines() -> Array:
	var out := []
	for p in state.placements:
		var paths := pattern_line_paths(p.enchantment, p.origin, p.rotation_steps)
		for i in paths.size():
			var l: EnchantmentPatternLine = p.enchantment.lines[i]
			(
				out
				. append(
					{
						"a": enchantment_key(p.id, l.from_node),
						"b": enchantment_key(p.id, l.to_node),
						"cells": paths[i],
						"placement": p,
					}
				)
			)
	return out


## The drawn line filling `cell` (a cell between nodes), or null
func line_at(cell: Vector2i) -> LineState:
	return _occupied.get(cell) as LineState


func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)


#
# ── Graph queries (drawn lines only) ─────────────
#
func line_count(key: String) -> int:
	return _adjacency.get(key, []).size()


## Every node reachable from `key` through drawn lines, including `key`
func component(key: String) -> Array[String]:
	var seen := {key: true}
	var stack: Array[String] = [key]
	while not stack.is_empty():
		var k: String = stack.pop_back()
		for n in _adjacency.get(k, []):
			if not seen.has(n):
				seen[n] = true
				stack.append(n)
	var out: Array[String] = []
	out.assign(seen.keys())
	return out


func reachable_magic_nodes(key: String) -> Array[String]:
	var out: Array[String] = []
	for k in component(key):
		if k != key and is_magic(k):
			out.append(k)
	return out


## Placement ids an enchantment-node-free chain would bind to, plus the node's own placement
func _bound_placements(key: String) -> Dictionary:
	var out := {}
	for k in component(key):
		var p := node_placement(k)
		if p:
			out[p.id] = p
	return out


## A magic node (or line) that doesn't chain to any enchantment node is dead.
## Dead draft lines block a commit.
func is_dead(key: String) -> bool:
	return _bound_placements(key).is_empty()


func is_line_dead(l: LineState) -> bool:
	return is_dead(l.a)


func is_node_committed(key: String) -> bool:
	var p := node_placement(key)
	if p:
		return p.committed
	for bound in _bound_placements(key).values():
		if bound.committed:
			return true
	return false


#
# ── Placing enchantments ─────────────────────────
#
func check_place(e: Enchantment, origin: Vector2i, rotation_steps: int) -> String:
	if e == null or e.nodes.is_empty():
		return "That enchantment has no shape yet"
	var seen := {}
	for c in footprint(e, origin, rotation_steps):
		if not _cells.has(c):
			return "It doesn't fit inside the item"
		if seen.has(c):
			return "The enchantment's shape overlaps itself"
		seen[c] = true
		if node_covering(c) != "":
			return "It overlaps another node"
		if _occupied.has(c):
			return "A line runs through there"
	return ""


func place(e: Enchantment, origin: Vector2i, rotation_steps: int) -> PlacementState:
	if check_place(e, origin, rotation_steps) != "":
		return null
	var p := PlacementState.new()
	p.id = state.next_placement_id
	state.next_placement_id += 1
	p.enchantment = e
	p.origin = origin
	p.rotation_steps = posmod(rotation_steps, 6)
	p.materials.resize(e.nodes.size())
	state.placements.append(p)
	_rebuild()
	return p


func check_remove_placement(p: PlacementState) -> String:
	if p.committed:
		return "Committed carvings can't be removed (disenchanting comes later)"
	return ""


func remove_placement(p: PlacementState) -> String:
	var err := check_remove_placement(p)
	if err != "":
		return err
	var prefix := "e:%d:" % p.id
	for l in state.lines.duplicate():
		if l.a.begins_with(prefix) or l.b.begins_with(prefix):
			state.lines.erase(l)
	state.placements.erase(p)
	_rebuild()
	return ""


#
# ── Drawing lines ────────────────────────────────
#
## Whether a line may start on the node in `cell`
func check_line_start(cell: Vector2i) -> String:
	var key := node_at(cell)
	if key == "":
		return "Lines start on a node"
	if is_node_committed(key):
		return "That node is part of a committed carving"
	return ""


## Whether a line being drawn along `path` (starting on a node) may step into `next`.
## Stepping onto a node finishes the line, so the two end nodes are checked then.
func check_step(path: Array[Vector2i], next: Vector2i) -> String:
	if path.is_empty():
		return "Lines start on a node"
	var start_err := check_line_start(path[0])
	if start_err != "":
		return start_err
	var last: Vector2i = path.back()
	if path.size() > 1 and node_at(last) != "":
		return "The line already ends on a node"
	var cell_err := _check_step_cell(path, next)
	if cell_err != "":
		return cell_err
	var end_key := node_at(next)
	if end_key != "":
		return _check_ends(node_at(path[0]), end_key)
	return ""


## Whether `cells` is a whole line: from one node, cell by cell, to another node
func check_line(cells: Array[Vector2i]) -> String:
	if cells.size() < 2:
		return "Draw from one node to another"
	var path: Array[Vector2i] = [cells[0]]
	for i in range(1, cells.size()):
		var err := check_step(path, cells[i])
		if err != "":
			return err
		path.append(cells[i])
	if node_at(cells.back()) == "":
		return "Lines have to end on a node"
	return ""


func add_line(cells: Array[Vector2i]) -> LineState:
	if check_line(cells) != "":
		return null
	var l := LineState.new()
	l.a = node_at(cells[0])
	l.b = node_at(cells.back())
	l.cells.assign(cells)
	state.lines.append(l)
	_rebuild()
	return l


## The draft line most recently drawn onto a node, or null
func last_draft_line(key: String) -> LineState:
	for i in range(state.lines.size() - 1, -1, -1):
		var l: LineState = state.lines[i]
		if not l.committed and (l.a == key or l.b == key):
			return l
	return null


func find_line(a: String, b: String) -> LineState:
	for l in state.lines:
		if (l.a == a and l.b == b) or (l.a == b and l.b == a):
			return l
	return null


func remove_line(l: LineState) -> String:
	if l.committed:
		return "Committed lines can't be removed (disenchanting comes later)"
	state.lines.erase(l)
	_rebuild()
	return ""


#
# ── Materials ────────────────────────────────────
#
func check_insert(key: String, m: EnchantmentMaterialDefinition) -> String:
	var p := node_placement(key)
	if p == null:
		return "Materials go into enchantment nodes"
	if p.committed:
		return "That carving is already committed"
	if not node_definition(key).accepts(m):
		return "This node accepts %s" % node_definition(key).describe_requirements()
	return ""


func insert_material(key: String, m: EnchantmentMaterialDefinition) -> String:
	var err := check_insert(key, m)
	if err == "":
		node_placement(key).materials[node_index(key)] = m
	return err


func remove_material(key: String) -> EnchantmentMaterialDefinition:
	var p := node_placement(key)
	if p == null or p.committed:
		return null
	var m: EnchantmentMaterialDefinition = p.materials[node_index(key)]
	p.materials[node_index(key)] = null
	return m


## How many of a material this item's drafts are planning to use
func reserved_in_drafts(m: EnchantmentMaterialDefinition) -> int:
	var n := 0
	for p in state.placements:
		if not p.committed:
			n += p.materials.count(m)
	return n


#
# ── Activation ───────────────────────────────────
#
func is_node_active(key: String) -> bool:
	var m := node_material(key)
	if m == null:
		return false
	var ctx := MaterialActivationContext.for_board(self, key)
	for c in m.activation_conditions:
		if c and not c.is_fulfilled(ctx):
			return false
	return true


## [[description, fulfilled, progress], ...] for the material in the node
func condition_status(key: String) -> Array:
	var out := []
	var m := node_material(key)
	if m == null:
		return out
	var ctx := MaterialActivationContext.for_board(self, key)
	for c in m.activation_conditions:
		if c:
			out.append([c.describe(), c.is_fulfilled(ctx), c.progress(ctx)])
	return out


func is_placement_active(p: PlacementState) -> bool:
	for i in p.enchantment.nodes.size():
		if not is_node_active(enchantment_key(p.id, i)):
			return false
	return true


#
# ── Commit ───────────────────────────────────────
#
## Draft enchantments that are fully activated and would be committed now
func commit_candidates() -> Array[PlacementState]:
	var out: Array[PlacementState] = []
	for p in state.placements:
		if not p.committed and is_placement_active(p):
			out.append(p)
	return out


func materials_needed(placements: Array[PlacementState]) -> Dictionary:
	var need := {}
	for p in placements:
		for m in p.materials:
			if m:
				need[m] = need.get(m, 0) + 1
	return need


## Materials the player is short of to commit now: {material: shortfall}
func missing_materials(player: Player) -> Dictionary:
	var missing := {}
	var need := materials_needed(commit_candidates())
	for m in need:
		var short: int = need[m] - player.get_material_count(m)
		if short > 0:
			missing[m] = short
	return missing


## Draft enchantments that aren't fully activated yet. Any of these blocks a commit.
func inactive_drafts() -> Array[PlacementState]:
	var out: Array[PlacementState] = []
	for p in state.placements:
		if not p.committed and not is_placement_active(p):
			out.append(p)
	return out


## Draft lines in chains that don't reach an enchantment node. Any of these blocks a commit.
func dead_lines() -> Array[LineState]:
	var out: Array[LineState] = []
	for l in state.lines:
		if not l.committed and is_line_dead(l):
			out.append(l)
	return out


## You can only commit a clean board: every draft enchantment active and every line connected
func check_commit(player: Player) -> String:
	if not dead_lines().is_empty():
		return "Some magic nodes aren't connected to an enchantment. Connect or remove them first"
	var inactive := inactive_drafts()
	if not inactive.is_empty():
		var names: Array[String] = []
		for p in inactive:
			names.append(p.enchantment.enchantment_name)
		return "Every planned enchantment has to be active to commit. Not yet: " + ", ".join(names)
	if commit_candidates().is_empty():
		return "Plan and activate an enchantment before committing"
	var missing := missing_materials(player)
	if not missing.is_empty():
		var names: Array[String] = []
		for m in missing:
			names.append("%d× %s" % [missing[m], material_name(m)])
		return "Not enough materials: " + ", ".join(names)
	return ""


## Commits every draft enchantment (all must be active) with the lines chained to it.
## Materials are used up.
func commit(player: Player) -> Array[PlacementState]:
	var done: Array[PlacementState] = []
	if check_commit(player) != "":
		return done
	done = commit_candidates()
	var need := materials_needed(done)
	for m in need:
		player.remove_material(m, need[m])
	var ids := {}
	for p in done:
		p.committed = true
		ids[p.id] = true
	for l in state.lines:
		for bound in _bound_placements(l.a):
			if ids.has(bound):
				l.committed = true
	return done


func committed_placements() -> Array[PlacementState]:
	var out: Array[PlacementState] = []
	for p in state.placements:
		if p.committed:
			out.append(p)
	return out


static func material_name(m: EnchantmentMaterialDefinition) -> String:
	if m == null:
		return "nothing"
	if m.display_name != "":
		return m.display_name
	return str(m.id) if m.id != &"" else m.resource_path.get_file().get_basename()


#
# ── Enchantment shapes ───────────────────────────
#
## Why an enchantment's own shape is broken, or "" when it's sound. Checked unrotated at the origin:
## the first node sits on the origin, no two cells overlap,
## and each fixed line runs cell by cell between two different nodes.
static func check_shape(e: Enchantment) -> String:
	if e == null or e.nodes.is_empty():
		return "That enchantment has no shape yet"
	if e.nodes[0].offset != Vector2i.ZERO:
		return "The first node has to sit on the origin cell"
	var taken := {}  ## Vector2i -> what takes it, for messages
	for i in e.nodes.size():
		var n: EnchantmentPatternNode = e.nodes[i]
		var cells: Array[Vector2i] = [n.offset]
		for c in n.extra_cells:
			cells.append(n.offset + c)
		for c in cells:
			if taken.has(c):
				return "Node %d overlaps %s" % [i, taken[c]]
			taken[c] = "node %d" % i
	var joined := {}
	for i in e.lines.size():
		var err := _check_shape_line(e, i, taken, joined)
		if err != "":
			return "Line %d: %s" % [i, err]
	return ""


static func _check_shape_line(
	e: Enchantment, i: int, taken: Dictionary, joined: Dictionary
) -> String:
	var l: EnchantmentPatternLine = e.lines[i]
	var count := e.nodes.size()
	if l.from_node < 0 or l.from_node >= count or l.to_node < 0 or l.to_node >= count:
		return "it has to join two of the enchantment's nodes"
	if l.from_node == l.to_node:
		return "it has to join two different nodes"
	var pair := Vector2i(mini(l.from_node, l.to_node), maxi(l.from_node, l.to_node))
	if joined.has(pair):
		return "nodes %d and %d are already joined" % [pair.x, pair.y]
	joined[pair] = true
	var path: Array[Vector2i] = [e.nodes[l.from_node].offset]
	path.append_array(l.cells)
	path.append(e.nodes[l.to_node].offset)
	for j in range(1, path.size()):
		if Hex.distance(path[j - 1], path[j]) != 1:
			return "its cells have to run from node to node, each next to the one before"
	for c in l.cells:
		if taken.has(c):
			return "it runs over %s" % taken[c]
		taken[c] = "line %d" % i
	return ""


#
# ── Internals ────────────────────────────────────
#
func _rebuild() -> void:
	_nodes.clear()
	_cell_to_node.clear()
	_adjacency.clear()
	for c in _magic_cells:
		var k := magic_key(c)
		_nodes[k] = {"kind": "magic", "cell": c, "placement": null, "index": -1}
		_cell_to_node[c] = k
	_extra_cells.clear()
	for p in state.placements:
		var cells := placement_cells(p.enchantment, p.origin, p.rotation_steps)
		for i in cells.size():
			var k := enchantment_key(p.id, i)
			_nodes[k] = {"kind": "enchantment", "cell": cells[i], "placement": p, "index": i}
			_cell_to_node[cells[i]] = k
			for c in p.enchantment.nodes[i].extra_cells:
				_extra_cells[p.origin + Hex.rotate(p.enchantment.nodes[i].offset + c, p.rotation_steps)] = k
	for l in state.lines:
		if not _adjacency.has(l.a):
			_adjacency[l.a] = []
		if not _adjacency.has(l.b):
			_adjacency[l.b] = []
		_adjacency[l.a].append(l.b)
		_adjacency[l.b].append(l.a)
	_occupied.clear()
	for l in state.lines:
		for i in range(1, l.cells.size() - 1):
			_occupied[l.cells[i]] = l
	for p in state.placements:
		for l in p.enchantment.lines:
			for c in l.cells:
				_occupied[p.origin + Hex.rotate(c, p.rotation_steps)] = p


func _check_step_cell(path: Array[Vector2i], next: Vector2i) -> String:
	var last: Vector2i = path.back()
	if Hex.distance(last, next) != 1:
		return "Lines go from a cell to its neighbour"
	if not _cells.has(next):
		return "Lines have to stay inside the item"
	if next in path:
		return "A line can't cross itself"
	return _taken_reason(next)


## Why a line can't run through `cell` because something already takes it, or ""
func _taken_reason(cell: Vector2i) -> String:
	if _extra_cells.has(cell):
		return "An enchantment node covers this cell"
	var owner: Variant = _occupied.get(cell)
	if owner is LineState:
		return "Another line runs through here"
	if owner is PlacementState:
		return "An enchantment's own line runs through here"
	return ""


func _check_ends(a: String, b: String) -> String:
	if a == b:
		return "Draw from one node to another"
	if find_line(a, b):
		return "Those nodes are already connected"
	for f in fixed_lines():
		if (f.a == a and f.b == b) or (f.a == b and f.b == a):
			return "Those nodes are already connected"
	if is_node_committed(b):
		return "That node is part of a committed carving"
	var bound := _bound_placements(a)
	bound.merge(_bound_placements(b))
	if bound.size() > 1:
		return "Enchantments can't share magic nodes"
	return ""
