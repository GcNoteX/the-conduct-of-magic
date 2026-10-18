extends Node

"""
Headless checks for the inscribing rules.
Run: godot --headless --path . res://tests/test_inscription_board.tscn
Exits with code 1 if any check fails.
"""

const SWORD := preload("res://tests/fixtures/test_sword.tres")
const KINDLE := preload("res://enchantments/patterns/kindle.tres")
const GLOW := preload("res://enchantments/patterns/glow.tres")
const KEEN := preload("res://enchantments/patterns/keen.tres")
const WARD := preload("res://enchantments/patterns/ward.tres")
const FIRE := preload("res://items/enchantment_materials/fire_stone/fire_stone.tres")
const WATER := preload("res://items/enchantment_materials/water_stone/water_stone.tres")
const BLUE := preload("res://items/enchantment_materials/blue_stone/blue_stone.tres")
const PortBoard := preload("res://tests/fixtures/port_board.gd")
const YELLOW := preload("res://items/enchantment_materials/yellow_stone/yellow_stone.tres")

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_hex_math()
	test_map()
	test_placement()
	test_lines()
	test_shared_magic_nodes()
	test_activation_and_chains()
	test_commit()
	test_planned_materials_stay_with_the_item()
	test_multi_cell_nodes()
	test_bigger_magic_nodes()
	test_big_nodes_with_ports()
	test_port_shape_checks()
	test_parallel_fixed_lines()
	test_shape_check()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


## A board on a fresh test sword (the 9x19 fixture). With no player given, one with plenty of
## every material.
func new_board(player: Player = null) -> InscriptionBoard:
	if player == null:
		player = Player.new()
		for mat in [FIRE, WATER, BLUE, YELLOW]:
			player.add_material(mat, 9)
	var inst := ItemInstance.new()
	inst.definition = SWORD
	return InscriptionBoard.new(inst, player)


func m(q: int, r: int) -> String:
	return InscriptionBoard.magic_key(Vector2i(q, r))


func path(cells: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(cells)
	return out


func test_hex_math() -> void:
	for a in [Vector2i(0, 0), Vector2i(3, -2), Vector2i(-4, 7)]:
		check(Hex.from_pixel(Hex.to_pixel(a, 1.0), 1.0) == a, "pixel round trip %s" % a)
		check(
			Hex.offset_to_axial(Hex.axial_to_offset(a).x, Hex.axial_to_offset(a).y) == a,
			"offset round trip %s" % a
		)
		check(Hex.rotate(a, 6) == a, "six rotations return %s" % a)
	check(Hex.rotate(Vector2i(1, 0), 1) == Vector2i(0, 1), "60° rotation of (1,0)")
	check(Hex.distance(Vector2i(0, 0), Vector2i(2, -1)) == 2, "hex distance")
	var run := Hex.line(Vector2i(0, 0), Vector2i(3, -5))
	var joined: bool = run.size() == 6 and run.back() == Vector2i(3, -5)
	for i in range(1, run.size()):
		joined = joined and Hex.distance(run[i - 1], run[i]) == 1
	check(joined, "a hex line steps cell to neighbouring cell")


func test_map() -> void:
	var b := new_board()
	check(b.get_node_keys().size() == 10, "the test sword has 10 magic nodes")
	check(b.has_node(m(3, 2)) and b.is_magic(m(3, 2)), "magic node at (3,2)")
	for e in [KINDLE, GLOW, KEEN, WARD]:
		for cells: Array[Vector2i] in b.pattern_line_paths(e, Vector2i.ZERO, 0):
			var joined: bool = true
			for i in range(1, cells.size()):
				joined = joined and Hex.distance(cells[i - 1], cells[i]) == 1
			check(joined and cells.size() > 2, "%s's own lines run through cells" % e.resource_path)


func test_placement() -> void:
	var b := new_board()
	check(b.check_place(KINDLE, Vector2i(1, 5), 0) == "", "kindle fits on the blade")
	check(b.check_place(KINDLE, Vector2i(3, 2), 0) != "", "can't place on a magic node")
	check(b.check_place(KINDLE, Vector2i(-10, 3), 0) != "", "can't place outside the item")
	var p := b.place(KINDLE, Vector2i(1, 5), 0)
	check(p != null, "kindle placed")
	check(
		b.node_at(Vector2i(3, 5)) == InscriptionBoard.enchantment_key(p.id, 1),
		"second node two cells east"
	)
	check(b.is_occupied(Vector2i(2, 5)), "kindle's own line fills the cell between its nodes")
	check(b.check_place(KINDLE, Vector2i(0, 5), 0) != "", "can't overlap another enchantment")
	check(
		b.check_place(KINDLE, Vector2i(2, 4), 1) == "A line runs through there",
		"can't place over an enchantment's own line"
	)
	b.add_line(path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7)]))
	check(
		b.check_place(KINDLE, Vector2i(0, 6), 0) == "A line runs through there",
		"can't place over a drawn line"
	)
	check(
		b.remove_placement(p) == "" and b.state.placements.is_empty() and b.state.lines.is_empty(),
		"draft placement and its lines removed for free"
	)


func test_lines() -> void:
	var b := new_board()
	var p := b.place(KINDLE, Vector2i(1, 5), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.check_line_start(Vector2i(1, 6)) != "", "lines start on a node")
	check(b.check_step(path([Vector2i(1, 5)]), Vector2i(1, 6)) == "", "step to a free cell")
	check(b.check_step(path([Vector2i(1, 5)]), Vector2i(1, 7)) != "", "can't skip a cell")
	check(
		b.check_step(path([Vector2i(1, 5)]), Vector2i(2, 5)).begins_with("An enchantment's own"),
		"can't step onto an enchantment's own line"
	)
	var l := b.add_line(path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7)]))
	check(l != null and l.a == e0 and l.b == m(1, 7), "draw enchantment node to magic node")
	check(b.line_at(Vector2i(1, 6)) == l, "the line fills its middle cell")
	check(
		b.check_step(path([Vector2i(3, 5), Vector2i(2, 6)]), Vector2i(1, 6)).begins_with("Another"),
		"lines can't cross"
	)
	check(
		b.check_step(path([Vector2i(3, 5), Vector2i(2, 6)]), Vector2i(3, 5)) != "",
		"a line can't cross itself"
	)
	check(
		b.check_step(path([Vector2i(1, 7), Vector2i(1, 6)]), Vector2i(1, 5)) != "",
		"duplicate line rejected"
	)
	check(
		b.check_step(path([Vector2i(1, 5), Vector2i(1, 4), Vector2i(0, 4)]), Vector2i(-1, 4)) != "",
		"a line ends when it reaches a node"
	)
	check(b.add_line(path([Vector2i(3, 5), Vector2i(4, 4)])) != null, "neighbouring nodes join")
	check(
		b.check_line(path([Vector2i(1, 5), Vector2i(1, 4)])) == "Lines have to end on a node",
		"lines have to end on a node"
	)
	check(b.check_line(path([Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)])) != "", "own line")
	check(b.remove_line(l) == "" and not b.is_occupied(Vector2i(1, 6)), "draft line removed free")


func test_shared_magic_nodes() -> void:
	var b := new_board()
	b.place(KINDLE, Vector2i(1, 5), 0)
	var g := b.place(GLOW, Vector2i(-1, 8), 0)
	check(g != null, "glow placed")
	check(b.add_line(path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7)])) != null, "kindle line")
	check(
		(
			b.check_line(path([Vector2i(1, 8), Vector2i(1, 7)]))
			== "Enchantments can't share magic nodes"
		),
		"glow can't use kindle's magic node"
	)


func test_activation_and_chains() -> void:
	var b := new_board()
	var p := b.place(KINDLE, Vector2i(1, 5), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.check_insert(e0, WATER) != "", "flame node rejects water")
	check(b.insert_material(e0, FIRE) == "", "flame node takes fire")
	check(b.insert_material(e1, WATER) == "", "any node takes water")
	check(not b.is_node_active(e0), "fire inactive with no lines")
	check(b.condition_status(e0)[0][2] == "0/2 lines", "fire shows its line progress")
	b.add_line(path([Vector2i(1, 5), Vector2i(1, 4), Vector2i(0, 4)]))
	b.add_line(path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7)]))
	check(b.is_node_active(e0), "fire active with 2 lines")
	check(b.condition_status(e0)[0][2] == "2/2 lines", "fire progress complete")
	b.add_line(path([Vector2i(3, 5), Vector2i(4, 4)]))
	check(not b.is_node_active(e1), "water inactive reaching 1 magic node")
	check(
		b.add_line(path([Vector2i(4, 4), Vector2i(4, 3), Vector2i(4, 2), Vector2i(3, 2)])) != null,
		"magic node to magic node line"
	)
	check(b.reachable_magic_nodes(e1).size() == 2, "water reaches 2 magic nodes through the chain")
	check(b.is_node_active(e1), "water active through a magic chain")
	check(b.is_placement_active(p), "kindle active")
	var dead := path(
		[Vector2i(-7, 14), Vector2i(-6, 14), Vector2i(-5, 14), Vector2i(-4, 14), Vector2i(-3, 14)]
	)
	b.add_line(dead)
	check(
		b.is_dead(m(-7, 14)) and b.is_line_dead(b.find_line(m(-7, 14), m(-3, 14))),
		"unchained magic line is dead"
	)
	check(not b.is_dead(m(3, 2)), "chained magic node is live")


func test_commit() -> void:
	var player := Player.new()
	player.add_material(FIRE, 1)
	player.add_material(BLUE, 1)
	var b := new_board(player)
	var p := b.place(KINDLE, Vector2i(1, 5), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.check_commit() != "", "nothing to commit before activation")
	b.insert_material(e0, FIRE)
	b.insert_material(e1, BLUE)
	b.add_line(path([Vector2i(1, 5), Vector2i(1, 4), Vector2i(0, 4)]))
	b.add_line(path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7)]))
	b.add_line(path([Vector2i(3, 5), Vector2i(4, 4)]))
	b.add_line(
		path(
			[
				Vector2i(-7, 14),
				Vector2i(-6, 14),
				Vector2i(-5, 14),
				Vector2i(-4, 14),
				Vector2i(-3, 14)
			]
		)
	)
	check(
		b.check_commit().begins_with("Some magic nodes"),
		"a chain of magic nodes that reaches no enchantment blocks the commit"
	)
	b.remove_line(b.find_line(m(-7, 14), m(-3, 14)))
	player.add_material(YELLOW, 1)
	var g := b.place(GLOW, Vector2i(-1, 8), 0)
	b.insert_material(InscriptionBoard.enchantment_key(g.id, 2), YELLOW)
	check(
		b.check_commit().begins_with("Every planned enchantment"),
		"commit blocked while glow is planned but not active"
	)
	check(b.commit().is_empty() and not p.committed, "nothing commits from a half-done plan")
	check(b.planned_count(YELLOW) == 1, "glow's yellow is held in the item's plan")
	b.remove_placement(g)
	check(
		player.get_material_count(YELLOW) == 1 and b.planned_count(YELLOW) == 0,
		"taking glow off returns its yellow to the inventory"
	)
	check(b.check_commit() == "", "commit allowed once every draft is active")
	var done := b.commit()
	check(done.size() == 1 and done[0] == p and p.committed, "the active enchantment commits")
	check(
		player.get_material_count(FIRE) == 0 and player.get_material_count(BLUE) == 0,
		"committed materials stay used up"
	)
	check(b.planned_count(FIRE) == 0, "a committed carving holds no planned materials")
	var k2 := b.place(KINDLE, Vector2i(-1, 9), 0)
	check(
		b.check_commit().begins_with("Every planned enchantment"),
		"a new half-done enchantment blocks the next commit"
	)
	b.remove_placement(k2)
	check(b.check_commit().begins_with("Plan and activate"), "nothing left to commit after one")
	check(b.find_line(e0, m(1, 7)).committed, "chained lines commit")
	check(b.check_line_start(Vector2i(3, 5)) != "", "can't add lines to a committed carving")
	check(b.remove_placement(p) != "", "committed carving can't be removed")
	check(b.check_insert(e0, FIRE) != "", "committed node takes no materials")


## Planning a material takes it out of the inventory and holds it in the item
func test_planned_materials_stay_with_the_item() -> void:
	var player := Player.new()
	player.add_material(FIRE, 1)
	player.add_material(WATER, 2)
	var b := new_board(player)
	var other := new_board(player)
	var p := b.place(KINDLE, Vector2i(1, 5), 0)
	var q := other.place(KINDLE, Vector2i(1, 5), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.insert_material(e0, FIRE) == "", "fire planned into the first sword")
	check(
		player.get_material_count(FIRE) == 0 and b.planned_count(FIRE) == 1,
		"planned fire moves from the inventory into the item"
	)
	check(
		other.check_insert(InscriptionBoard.enchantment_key(q.id, 0), FIRE).begins_with(
			"You don't have"
		),
		"another item can't plan the fire this one holds"
	)
	b.insert_material(e1, WATER)
	check(player.get_material_count(WATER) == 1, "water planned")
	check(b.insert_material(e1, WATER) == "", "inserting the same material again is a no-op")
	check(player.get_material_count(WATER) == 1, "and takes nothing more")
	b.remove_material(e0)
	check(
		player.get_material_count(FIRE) == 1 and b.planned_count(FIRE) == 0,
		"unplanning fire returns it"
	)
	b.insert_material(e1, FIRE)
	check(
		player.get_material_count(WATER) == 2 and player.get_material_count(FIRE) == 0,
		"swapping returns the old material and takes the new one"
	)
	check(
		other.check_insert(InscriptionBoard.enchantment_key(q.id, 0), FIRE) != "",
		"still held by the first item after the swap"
	)


## Kindle with its second node covering one more cell to the east
func wide_kindle(extra: Array[Vector2i]) -> Enchantment:
	var e := Enchantment.new()
	e.enchantment_name = "Wide kindle"
	var nodes: Array[EnchantmentPatternNode] = []
	for n in KINDLE.nodes:
		var copy := EnchantmentPatternNode.new()
		copy.offset = n.offset
		copy.tier_requirement = n.tier_requirement
		copy.material_requirements = n.material_requirements
		nodes.append(copy)
	nodes[1].extra_cells = extra
	e.nodes = nodes
	e.lines = KINDLE.lines
	return e


func test_multi_cell_nodes() -> void:
	var b := new_board()
	var wide := wide_kindle(path([Vector2i(1, 0)]))
	check(b.footprint(wide, Vector2i(1, 5), 0).has(Vector2i(4, 5)), "footprint has extra cells")
	check(
		b.footprint(wide, Vector2i(1, 5), 1).has(Vector2i(1, 8)), "extra cells turn with the node"
	)
	check(
		b.check_place(wide, Vector2i(1, 4), 0) == "It overlaps another node",
		"an extra cell can't sit on a magic node"
	)
	var p := b.place(wide, Vector2i(1, 5), 0)
	check(p != null, "a multi-cell node places")
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.node_covering(Vector2i(4, 5)) == e1, "the extra cell belongs to its node")
	check(b.node_at(Vector2i(4, 5)) == "", "lines attach at the node's own cell, not extra cells")
	check(
		b.check_place(KINDLE, Vector2i(4, 5), 0) == "It overlaps another node",
		"another enchantment can't sit on an extra cell"
	)
	check(
		(
			b.check_step(path([Vector2i(4, 4)]), Vector2i(4, 5))
			== "An enchantment node covers this cell"
		),
		"a line can't run through an extra cell"
	)
	check(b.check_line(path([Vector2i(4, 4), Vector2i(3, 5)])) == "", "lines still join the node")
	b.remove_placement(p)
	check(b.node_covering(Vector2i(4, 5)) == "", "removing the placement frees its extra cells")


## The short sword's Ember Well covers two cells: lines attach at its own cell only
func test_bigger_magic_nodes() -> void:
	var inst := ItemInstance.new()
	inst.definition = preload("res://inscribing/demo/short_sword.tres")
	var b := InscriptionBoard.new(inst, Player.new())
	var well := Hex.offset_to_axial(0, 12)
	var extra := well + Vector2i(1, 0)
	var key := InscriptionBoard.magic_key(well)
	check(b.node_covering(extra) == key, "the well's extra cell belongs to it")
	check(b.node_at(extra) == "", "lines don't attach at the extra cell")
	check(b.node_cells(key) == ([well, extra] as Array[Vector2i]), "the well covers two cells")
	check(
		b.check_step(path([well]), extra) == "A magic node covers this cell",
		"a line can't run through the extra cell"
	)
	check(b.check_place(KINDLE, extra, 0) == "It overlaps another node", "nothing sits on it")


## Bastion's big node covers four cells and takes lines only at its two ports; it's one node,
## so lines at both ports count together for its material
func test_big_nodes_with_ports() -> void:
	var b := PortBoard.board(new_board().inventory)
	var o := PortBoard.ORIGIN
	check(b.check_place(PortBoard.BASTION, o, 0) == "", "Bastion fits on the open map")
	var p := b.place(PortBoard.BASTION, o, 0)
	var big := InscriptionBoard.enchantment_key(p.id, 0)
	var corner := o + Vector2i(1, 1)
	check(b.node_at(o) == big and b.node_at(corner) == big, "both ports attach lines to the node")
	check(b.node_ports(big) == path([o, corner]), "the node lists its two ports")
	for c in [o + Vector2i(1, 0), o + Vector2i(0, 1)]:
		check(b.node_at(c) == "" and b.node_covering(c) == big, "a cell that isn't a port")
	check(b.node_cells(big).size() == 4, "the big node covers four cells")
	check(
		b.check_line_start(o + Vector2i(1, 0)) == "Lines attach to this node at its ports",
		"a line can't start on a cell that isn't a port"
	)
	check(
		(
			b.check_step(path([PortBoard.MAGIC_SIDE]), o + Vector2i(1, 0))
			== "An enchantment node covers this cell"
		),
		"a line can't end on a cell that isn't a port"
	)
	var fixed := b.fixed_lines()
	check(fixed[1].cells[0] == corner, "a fixed line starts at its port")
	check(fixed[0].cells.back() == o, "and ends at its port")
	var above := PortBoard.path([PortBoard.MAGIC_ABOVE, Vector2i(5, 2), o])
	var below := PortBoard.path([corner, Vector2i(5, 5), PortBoard.MAGIC_BELOW])
	check(b.check_line(above) == "", "a drawn line can end at port 0")
	b.add_line(above)
	check(b.check_line(below) == "", "a drawn line can start at port 1")
	b.add_line(below)
	b.insert_material(big, FIRE)
	check(b.line_count(big) == 2, "lines at both ports count for the one node")
	check(b.is_node_active(big), "fire's 2 lines are met across two ports")
	check(
		b.check_line(PortBoard.path([corner, Vector2i(6, 3), PortBoard.MAGIC_SIDE])) == "",
		"another line can share a port"
	)
	check(
		(
			b.check_line(
				PortBoard.path([corner, Vector2i(4, 5), Vector2i(3, 5), Vector2i(3, 4), o])
			)
			== "Draw from one node to another"
		),
		"a line can't run from one port of the node to another"
	)
	var turned := PortBoard.board(new_board().inventory)
	var at := Vector2i(-99, -99)
	for c in turned.get_cells():
		if at.x == -99 and turned.check_place(PortBoard.BASTION, c, 1) == "":
			at = c
	var q := turned.place(PortBoard.BASTION, at, 1)
	check(q != null, "Bastion places turned")
	if q:
		var k := InscriptionBoard.enchantment_key(q.id, 0)
		check(
			turned.node_ports(k) == path([at, at + Hex.rotate(Vector2i(1, 1), 1)]),
			"ports turn with the enchantment"
		)


func test_port_shape_checks() -> void:
	check(InscriptionBoard.check_shape(PortBoard.BASTION) == "", "Bastion has a sound shape")
	var e: Enchantment = PortBoard.BASTION.duplicate(true)
	e.nodes[0].ports = path([Vector2i(0, 0), Vector2i(2, 0)])
	check(
		InscriptionBoard.check_shape(e) == "Node 0: its port (2, 0) isn't one of its cells",
		"a port has to be one of the node's cells"
	)
	e.nodes[0].ports = path([Vector2i(1, 1), Vector2i(1, 1)])
	check(
		InscriptionBoard.check_shape(e) == "Node 0: the port (1, 1) is listed twice",
		"a port is listed once"
	)
	e.nodes[0].ports = path([Vector2i(0, 0), Vector2i(1, 1)])
	e.lines[1].from_port = 2
	check(
		InscriptionBoard.check_shape(e) == "Line 1: node 0 has no port 2", "the port has to exist"
	)
	e.lines[1].from_port = 0
	check(
		InscriptionBoard.check_shape(e).begins_with("Line 1: its cells"),
		"a line runs from the port it names"
	)


## An enchantment's shape can join the same two nodes more than once, each line through its own
## cells; drawn lines still can't join nodes that are already joined
func test_parallel_fixed_lines() -> void:
	var e := Enchantment.new()
	var nodes: Array[EnchantmentPatternNode] = [
		EnchantmentPatternNode.new(), EnchantmentPatternNode.new()
	]
	nodes[1].offset = Vector2i(1, 0)
	e.nodes = nodes
	var straight := EnchantmentPatternLine.new()
	var over := EnchantmentPatternLine.new()
	over.cells = path([Vector2i(1, -1)])
	e.lines = [straight, over] as Array[EnchantmentPatternLine]
	check(InscriptionBoard.check_shape(e) == "", "two lines may join the same two nodes")
	var again := EnchantmentPatternLine.new()
	e.lines = [straight, over, again] as Array[EnchantmentPatternLine]
	check(
		InscriptionBoard.check_shape(e) == "Line 2: it runs the same way as line 0",
		"but not the same way twice"
	)
	again.cells = path([Vector2i(0, -1), Vector2i(2, -1)])
	check(
		InscriptionBoard.check_shape(e).begins_with("Line 2: its cells have to run"),
		"a third line needs a sound path"
	)
	again.cells = path([Vector2i(0, 1)])
	check(InscriptionBoard.check_shape(e) == "", "three lines between two nodes, each its own way")
	var b := PortBoard.board(new_board().inventory)
	var p := b.place(PortBoard.BASTION, PortBoard.ORIGIN, 0)
	var big := InscriptionBoard.enchantment_key(p.id, 0)
	var left := InscriptionBoard.enchantment_key(p.id, 1)
	var joins := 0
	for f in b.fixed_lines():
		if (f.a == left and f.b == big) or (f.a == big and f.b == left):
			joins += 1
	check(joins == 2, "Bastion joins its left node to the big node twice")
	check(
		(
			b.check_line(path([Vector2i(2, 3), Vector2i(2, 4), Vector2i(3, 4), PortBoard.ORIGIN]))
			== "Those nodes are already connected"
		),
		"a drawn line can't join them a third time"
	)


func test_shape_check() -> void:
	for e in [KINDLE, GLOW, KEEN, WARD]:
		check(InscriptionBoard.check_shape(e) == "", "%s has a sound shape" % e.enchantment_name)
	check(InscriptionBoard.check_shape(wide_kindle(path([Vector2i(1, 0)]))) == "", "wide kindle")
	check(
		(
			InscriptionBoard.check_shape(wide_kindle(path([Vector2i(-1, 0)])))
			== "Line 0: it runs over node 1"
		),
		"an extra cell can't sit on a line"
	)
	check(
		(
			InscriptionBoard.check_shape(wide_kindle(path([Vector2i(-2, 0)])))
			== "Node 1 overlaps node 0"
		),
		"an extra cell can't sit on another node"
	)
	var moved := wide_kindle(path([]))
	moved.nodes[0].offset = Vector2i(0, 1)
	check(
		InscriptionBoard.check_shape(moved) == "The first node has to sit on the origin cell",
		"the first node sits on the origin"
	)
	var gap := wide_kindle(path([]))
	gap.nodes[1].offset = Vector2i(3, 0)
	check(InscriptionBoard.check_shape(gap).begins_with("Line 0: its cells"), "lines can't skip")
	check(
		InscriptionBoard.check_shape(Enchantment.new()) != "", "an empty enchantment has no shape"
	)
