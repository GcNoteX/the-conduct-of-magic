extends Node

"""
Headless checks for the inscribing rules.
Run: godot --headless --path . res://tests/test_inscription_board.tscn
Exits with code 1 if any check fails.
"""

const SWORD := preload("res://inscribing/demo/demo_sword.tres")
const KINDLE := preload("res://enchantments/patterns/kindle.tres")
const GLOW := preload("res://enchantments/patterns/glow.tres")
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
	test_lines_and_crossing()
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


func test_map() -> void:
	var b := new_board()
	check(b.get_node_keys().size() == 9, "demo sword has 9 magic nodes")
	check(b.has_node(m(1, 2)) and b.is_magic(m(1, 2)), "magic node at (1,2)")


func test_placement() -> void:
	var b := new_board()
	check(b.check_place(KINDLE, Vector2i(1, 3), 0) == "", "kindle fits on the blade")
	check(b.check_place(KINDLE, Vector2i(1, 2), 0) != "", "can't place on a magic node")
	check(b.check_place(KINDLE, Vector2i(-10, 3), 0) != "", "can't place outside the item")
	var p := b.place(KINDLE, Vector2i(1, 3), 0)
	check(p != null, "kindle placed")
	check(b.check_place(KINDLE, Vector2i(0, 3), 0) != "", "can't overlap another enchantment")
	check(
		b.node_at(Vector2i(2, 3)) == InscriptionBoard.enchantment_key(p.id, 1),
		"second node one cell east"
	)
	check(
		b.remove_placement(p) == "" and b.state.placements.is_empty(),
		"draft placement removed for free"
	)


func test_lines_and_crossing() -> void:
	var b := new_board()
	var p := b.place(KINDLE, Vector2i(1, 3), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.add_line(m(1, 2), e1) != null, "draw magic node to enchantment node")
	check(b.check_line(e0, m(3, 2)) == "Lines can't cross", "crossing lines rejected")
	check(b.check_line(e1, m(1, 2)) != "", "duplicate line rejected")
	check(b.check_line(e0, e1) != "", "can't redraw an enchantment's own line")
	check(b.check_line(m(1, 2), m(1, 2)) != "", "can't draw to the same node")
	var l := b.find_line(m(1, 2), e1)
	check(b.remove_line(l) == "" and b.state.lines.is_empty(), "draft line removed for free")


func test_shared_magic_nodes() -> void:
	var b := new_board()
	var k := b.place(KINDLE, Vector2i(1, 3), 0)
	var g := b.place(GLOW, Vector2i(-1, 6), 0)
	check(g != null, "glow placed")
	var k0 := InscriptionBoard.enchantment_key(k.id, 0)
	var g1 := InscriptionBoard.enchantment_key(g.id, 1)
	check(b.add_line(k0, m(1, 5)) != null, "kindle reaches magic node (1,5)")
	check(
		b.check_line(g1, m(1, 5)) == "Enchantments can't share magic nodes",
		"glow can't use kindle's magic node"
	)


func test_activation_and_chains() -> void:
	var b := new_board()
	var p := b.place(KINDLE, Vector2i(1, 3), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.check_insert(e0, WATER) != "", "flame node rejects water")
	check(b.insert_material(e0, FIRE) == "", "flame node takes fire")
	check(b.insert_material(e1, WATER) == "", "any node takes water")
	check(not b.is_node_active(e0), "fire inactive with no lines")
	b.add_line(e0, m(1, 2))
	b.add_line(e0, m(1, 5))
	check(b.is_node_active(e0), "fire active with 2 lines")
	b.add_line(e1, m(3, 2))
	check(not b.is_node_active(e1), "water inactive reaching 1 magic node")
	check(b.add_line(m(3, 2), m(1, 2)) != null, "magic node to magic node line")
	check(b.reachable_magic_nodes(e1).size() == 3, "water reaches 3 magic nodes through the chain")
	check(b.is_node_active(e1), "water active through a magic chain")
	check(b.is_placement_active(p), "kindle active")
	b.add_line(m(-2, 8), m(0, 8))
	check(
		b.is_dead(m(-2, 8)) and b.is_line_dead(b.find_line(m(-2, 8), m(0, 8))),
		"unchained magic line is dead"
	)
	check(not b.is_dead(m(1, 2)), "chained magic node is live")


func test_commit() -> void:
	var b := new_board()
	var player := Player.new()
	player.add_material(FIRE, 1)
	var p := b.place(KINDLE, Vector2i(1, 3), 0)
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(b.check_commit(player) != "", "nothing to commit before activation")
	b.insert_material(e0, FIRE)
	b.insert_material(e1, BLUE)
	b.add_line(e0, m(1, 2))
	b.add_line(e0, m(1, 5))
	b.add_line(e1, m(3, 2))
	b.add_line(m(-2, 8), m(0, 8))
	var g := b.place(GLOW, Vector2i(-1, 6), 0)
	b.insert_material(InscriptionBoard.enchantment_key(g.id, 2), YELLOW)
	check(
		b.check_commit(player).begins_with("Not enough materials"),
		"commit blocked when short of blue"
	)
	check(b.missing_materials(player).get(BLUE, 0) == 1, "short exactly one blue")
	player.add_material(BLUE, 2)
	check(b.check_commit(player) == "", "commit allowed")
	var done := b.commit(player)
	check(done.size() == 1 and done[0] == p and p.committed, "only the active enchantment commits")
	check(not g.committed, "inactive glow stays a draft")
	check(
		player.get_material_count(FIRE) == 0 and player.get_material_count(BLUE) == 1,
		"materials used up on commit"
	)
	check(b.find_line(e0, m(1, 2)).committed, "chained lines commit")
	check(not b.find_line(m(-2, 8), m(0, 8)).committed, "dead line ignored on commit")
	check(b.check_line(e1, m(1, 5)) != "", "can't add lines to a committed carving")
	check(b.remove_placement(p) != "", "committed carving can't be removed")
	check(b.check_insert(e0, FIRE) != "", "committed node takes no materials")
	check(b.reserved_in_drafts(YELLOW) == 1, "glow's yellow is reserved in the draft")
