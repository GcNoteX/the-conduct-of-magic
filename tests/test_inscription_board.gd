extends Node

"""
Headless checks for the inscribing rules.
Run: godot --headless --path . res://tests/test_inscription_board.tscn
Exits with code 1 if any check fails.
"""

const SWORD := preload("res://inscribing/demo/demo_sword.tres")
const KINDLE := preload("res://enchantments/patterns/kindle.tres")
const GLOW := preload("res://enchantments/patterns/glow.tres")
const KEEN := preload("res://enchantments/patterns/keen.tres")
const WARD := preload("res://enchantments/patterns/ward.tres")
const FIRE := preload("res://items/enchantment_materials/fire_stone/fire_stone.tres")
const WATER := preload("res://items/enchantment_materials/water_stone/water_stone.tres")
const BLUE := preload("res://items/enchantment_materials/blue_stone/blue_stone.tres")
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
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func new_board() -> InscriptionBoard:
	var inst := ItemInstance.new()
	inst.definition = SWORD
	return InscriptionBoard.new(inst)


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
	check(b.get_node_keys().size() == 10, "demo sword has 10 magic nodes")
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
	var b := new_board()
	var player := Player.new()
	player.add_material(FIRE, 1)
	var p := b.place(KINDLE, Vector2i(1, 5), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.check_commit(player) != "", "nothing to commit before activation")
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
	var g := b.place(GLOW, Vector2i(-1, 8), 0)
	b.insert_material(InscriptionBoard.enchantment_key(g.id, 2), YELLOW)
	player.add_material(BLUE, 2)
	check(
		b.check_commit(player).begins_with("Every planned enchantment"),
		"commit blocked while glow is planned but not active"
	)
	check(b.commit(player).is_empty() and not p.committed, "nothing commits from a half-done plan")
	check(b.reserved_in_drafts(YELLOW) == 1, "glow's yellow is reserved in the draft")
	b.remove_placement(g)
	player.remove_material(BLUE, 2)
	check(
		b.check_commit(player).begins_with("Not enough materials"),
		"commit blocked when short of blue"
	)
	check(b.missing_materials(player).get(BLUE, 0) == 1, "short exactly one blue")
	player.add_material(BLUE, 2)
	check(b.check_commit(player) == "", "commit allowed once every draft is active")
	var done := b.commit(player)
	check(done.size() == 1 and done[0] == p and p.committed, "the active enchantment commits")
	check(
		player.get_material_count(FIRE) == 0 and player.get_material_count(BLUE) == 1,
		"materials used up on commit"
	)
	var k2 := b.place(KINDLE, Vector2i(-1, 9), 0)
	check(
		b.check_commit(player).begins_with("Every planned enchantment"),
		"a new half-done enchantment blocks the next commit"
	)
	b.remove_placement(k2)
	check(
		b.check_commit(player).begins_with("Plan and activate"), "nothing left to commit after one"
	)
	check(b.find_line(e0, m(1, 7)).committed, "chained lines commit")
	check(not b.find_line(m(-7, 14), m(-3, 14)).committed, "dead line ignored on commit")
	check(b.check_line_start(Vector2i(3, 5)) != "", "can't add lines to a committed carving")
	check(b.remove_placement(p) != "", "committed carving can't be removed")
	check(b.check_insert(e0, FIRE) != "", "committed node takes no materials")
