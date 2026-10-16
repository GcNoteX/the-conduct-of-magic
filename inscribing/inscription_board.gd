class_name InscriptionBoard
extends RefCounted

"""
The rules of carving on one item's hex map. Pure logic, no drawing, so it can be tested headless.
- Wraps an ItemInstance: its map comes from the definition, its plan and carvings from its GraphState
- Nodes are addressed by key: "m:q,r" for magic nodes, "e:<placement id>:<node index>" for enchantment nodes
- Positions are in unit hex space (hex size 1); views scale them
- Every check_* returns "" when allowed, or a player-facing reason when not
"""

const NODE_RADIUS := 0.45 ## Lines may not pass this close to a node they don't attach to
const EPS := 0.0001

var item: ItemInstance
var map: HexMapDefinition
var state: GraphState

var _cells: Dictionary = {} ## Vector2i -> true
var _magic_cells: Array[Vector2i] = []
var _nodes: Dictionary = {} ## key -> {kind, cell, placement, index}
var _cell_to_node: Dictionary = {} ## Vector2i -> key
var _adjacency: Dictionary = {} ## key -> Array[String], drawn lines only

func _init(item_instance: ItemInstance) -> void:
	item = item_instance
	var def := item.definition as EnchantableItemDefinition
	assert(def and def.map_template, "InscriptionBoard needs an EnchantableItemDefinition with a map_template")
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

## The enchantments' own fixed lines, as [key_a, key_b]
func fixed_lines() -> Array:
	var out := []
	for p in state.placements:
		for l in p.enchantment.lines:
			out.append([enchantment_key(p.id, l.x), enchantment_key(p.id, l.y)])
	return out

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

## A magic node (or line) that doesn't chain to any enchantment node is dead and ignored on commit
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
	var cells := placement_cells(e, origin, rotation_steps)
	var seen := {}
	for c in cells:
		if not _cells.has(c):
			return "It doesn't fit inside the item"
		if seen.has(c):
			return "The enchantment's shape overlaps itself"
		seen[c] = true
		if _cell_to_node.has(c):
			return "It overlaps another node"
	var new_positions: Array[Vector2] = []
	for c in cells:
		new_positions.append(Hex.to_pixel(c, 1.0))
	var existing := []
	for l in state.lines:
		existing.append([l.a, l.b])
	existing.append_array(fixed_lines())
	for pos in new_positions:
		for seg in existing:
			if _point_segment_distance(pos, node_position(seg[0]), node_position(seg[1])) < NODE_RADIUS:
				return "It sits on top of a line"
	for l in e.lines:
		var a := new_positions[l.x]
		var b := new_positions[l.y]
		var err := _check_segment(a, b, [], new_positions, [l.x, l.y])
		if err != "":
			return err
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
func check_line(a: String, b: String) -> String:
	if a == b or not _nodes.has(a) or not _nodes.has(b):
		return "Draw from one node to another"
	if find_line(a, b):
		return "Those nodes are already connected"
	for f in fixed_lines():
		if (f[0] == a and f[1] == b) or (f[0] == b and f[1] == a):
			return "Those nodes are already connected"
	if is_node_committed(a) or is_node_committed(b):
		return "That node is part of a committed carving"
	var bound := _bound_placements(a)
	bound.merge(_bound_placements(b))
	if bound.size() > 1:
		return "Enchantments can't share magic nodes"
	return _check_segment(node_position(a), node_position(b), [a, b])

func add_line(a: String, b: String) -> LineState:
	if check_line(a, b) != "":
		return null
	var l := LineState.new()
	l.a = a
	l.b = b
	state.lines.append(l)
	_rebuild()
	return l

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

## [[description, fulfilled], ...] for the material in the node
func condition_status(key: String) -> Array:
	var out := []
	var m := node_material(key)
	if m == null:
		return out
	var ctx := MaterialActivationContext.for_board(self, key)
	for c in m.activation_conditions:
		if c:
			out.append([c.describe(), c.is_fulfilled(ctx)])
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

func check_commit(player: Player) -> String:
	if commit_candidates().is_empty():
		return "Activate an enchantment before committing"
	var missing := missing_materials(player)
	if not missing.is_empty():
		var names: Array[String] = []
		for m in missing:
			names.append("%d× %s" % [missing[m], material_name(m)])
		return "Not enough materials: " + ", ".join(names)
	return ""

## Commits every activated draft enchantment with the lines chained to it. Materials are used up.
## Dead lines and inactive drafts stay as drafts.
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
	for p in state.placements:
		var cells := placement_cells(p.enchantment, p.origin, p.rotation_steps)
		for i in cells.size():
			var k := enchantment_key(p.id, i)
			_nodes[k] = {"kind": "enchantment", "cell": cells[i], "placement": p, "index": i}
			_cell_to_node[cells[i]] = k
	for l in state.lines:
		if not _adjacency.has(l.a):
			_adjacency[l.a] = []
		if not _adjacency.has(l.b):
			_adjacency[l.b] = []
		_adjacency[l.a].append(l.b)
		_adjacency[l.b].append(l.a)

## Checks a new straight segment against the map, nodes and every existing line.
## `endpoint_keys` are existing nodes the segment attaches to. `extra_nodes` are positions of nodes
## not placed yet (a placement being checked), with `extra_endpoints` the indexes it attaches to.
func _check_segment(a: Vector2, b: Vector2, endpoint_keys: Array, extra_nodes: Array[Vector2] = [], extra_endpoints: Array = []) -> String:
	var steps := maxi(2, int(a.distance_to(b) / 0.1))
	for s in steps + 1:
		if not _cells.has(Hex.from_pixel(a.lerp(b, float(s) / steps), 1.0)):
			return "Lines have to stay inside the item"
	for k in _nodes:
		if k in endpoint_keys:
			continue
		if _point_segment_distance(node_position(k), a, b) < NODE_RADIUS:
			return "Lines can't pass through a node"
	for i in extra_nodes.size():
		if i in extra_endpoints:
			continue
		if _point_segment_distance(extra_nodes[i], a, b) < NODE_RADIUS:
			return "Lines can't pass through a node"
	var existing := []
	for l in state.lines:
		existing.append([l.a, l.b])
	existing.append_array(fixed_lines())
	for seg in existing:
		var c := node_position(seg[0])
		var d := node_position(seg[1])
		if _segments_cross(a, b, c, d):
			return "Lines can't cross"
	return ""

static func _cross(u: Vector2, v: Vector2) -> float:
	return u.x * v.y - u.y * v.x

static func _segments_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var d1 := _cross(d - c, a - c)
	var d2 := _cross(d - c, b - c)
	var d3 := _cross(b - a, c - a)
	var d4 := _cross(b - a, d - a)
	if ((d1 > EPS and d2 < -EPS) or (d1 < -EPS and d2 > EPS)) and ((d3 > EPS and d4 < -EPS) or (d3 < -EPS and d4 > EPS)):
		return true
	# Collinear segments cross if they overlap by more than a point
	if absf(d1) < EPS and absf(d2) < EPS:
		var dir := (b - a).normalized()
		var t0 := 0.0
		var t1 := (b - a).length()
		var s0 := (c - a).dot(dir)
		var s1 := (d - a).dot(dir)
		return minf(t1, maxf(s0, s1)) - maxf(t0, minf(s0, s1)) > EPS
	return false

static func _point_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), EPS), 0.0, 1.0)
	return p.distance_to(a + ab * t)
