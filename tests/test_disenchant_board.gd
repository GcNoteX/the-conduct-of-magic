extends Node

"""
Headless checks for the disenchanting rules.
Run: godot --headless --path . res://tests/test_disenchant_board.tscn
Exits with code 1 if any check fails.
"""

const SWORD := preload("res://tests/fixtures/test_sword.tres")
const KINDLE := preload("res://enchantments/patterns/kindle.tres")
const FIRE := preload("res://items/enchantment_materials/fire_stone/fire_stone.tres")
const WATER := preload("res://items/enchantment_materials/water_stone/water_stone.tres")
const RED := preload("res://items/enchantment_materials/red_stone/red_stone.tres")
const BLUE := preload("res://items/enchantment_materials/blue_stone/blue_stone.tres")
const YELLOW := preload("res://items/enchantment_materials/yellow_stone/yellow_stone.tres")
const PortBoard := preload("res://tests/fixtures/port_board.gd")

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_rune_set()
	test_map_runes()
	test_costs_and_chains()
	test_replay_and_payouts()
	test_pull_out_and_commit()
	test_no_partial_commits()
	test_planned_dissolves_stay_with_the_item()
	test_big_node_with_ports()
	test_parallel_line_names()
	test_saved_plans_fit_changed_ports()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func m(q: int, r: int) -> String:
	return InscriptionBoard.magic_key(Vector2i(q, r))


func path(cells: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(cells)
	return out


func runes(water: int, fire: int, wind: int, stone: int) -> RuneSet:
	return RuneSet.of(water, fire, wind, stone)


## A test sword carved with Kindle (fire and water) on the blade, and optionally a second Kindle
## (fire and blue) lower down. The carving's own materials come from a separate player.
func carved_sword(second: bool = false) -> ItemInstance:
	var carver := Player.new()
	for mat in [FIRE, WATER, BLUE]:
		carver.add_material(mat, 2)
	var inst := ItemInstance.new()
	inst.definition = SWORD
	var b := InscriptionBoard.new(inst, carver)
	var p := b.place(KINDLE, Vector2i(1, 5), 0)
	b.insert_material(InscriptionBoard.enchantment_key(p.id, 0), FIRE)
	b.insert_material(InscriptionBoard.enchantment_key(p.id, 1), WATER)
	b.add_line(path([Vector2i(1, 5), Vector2i(1, 4), Vector2i(0, 4)]))
	b.add_line(path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7)]))
	b.add_line(path([Vector2i(3, 5), Vector2i(4, 4)]))
	b.add_line(path([Vector2i(4, 4), Vector2i(4, 3), Vector2i(4, 2), Vector2i(3, 2)]))
	if second:
		var q := b.place(KINDLE, Vector2i(-1, 9), 0)
		b.insert_material(InscriptionBoard.enchantment_key(q.id, 0), FIRE)
		b.insert_material(InscriptionBoard.enchantment_key(q.id, 1), BLUE)
		b.add_line(path([Vector2i(-1, 9), Vector2i(-2, 10), Vector2i(-3, 10)]))
		b.add_line(path([Vector2i(-1, 9), Vector2i(-1, 10), Vector2i(0, 10), Vector2i(1, 10)]))
		b.add_line(path([Vector2i(1, 9), Vector2i(1, 10)]))
	var done := b.commit()
	assert(done.size() == (2 if second else 1), "test carving didn't commit: " + b.check_commit())
	return inst


func board_for(inst: ItemInstance, player: Player) -> DisenchantBoard:
	return DisenchantBoard.new(InscriptionBoard.new(inst, player))


func stocked() -> Player:
	var p := Player.new()
	for mat in [FIRE, WATER, RED]:
		p.add_material(mat, 1)
	return p


func test_rune_set() -> void:
	var a := runes(1, 2, 0, 0)
	var b := runes(0, 1, 1, 0)
	check(a.plus(b).equals(runes(1, 3, 1, 0)), "rune sets add")
	check(a.minus(b).equals(runes(1, 1, -1, 0)), "rune sets subtract")
	check(a.equals(runes(1, 2, 0, 0)), "plus and minus leave the set unchanged")
	check(a.covers(runes(1, 1, 0, 0)) and not a.covers(b), "covers checks every type")
	check(a.shortfall(b).equals(runes(0, 0, 1, 0)), "shortfall is what's missing")
	check(RuneSet.copy_of(null).is_empty(), "a null set reads as empty")
	check(b.describe() == "1 fire, 1 wind", "describe names each type")
	check(FIRE.edge_runes.equals(runes(0, 1, 0, 0)), "fire stone puts 1 fire on each edge")
	check(WATER.edge_runes.equals(runes(1, 0, 0, 0)), "water stone puts 1 water on each edge")
	check(FIRE.harvest_runes.fire > 0 and FIRE.dissolve_runes.fire > 0, "fire gives fire back")


func test_map_runes() -> void:
	var map: HexMapDefinition = SWORD.map_template
	check(map.magic_edge_runes.size() == map.get_magic_nodes().size(), "every magic node has runes")
	check(map.edge_runes_at(Vector2i(3, 2)).equals(runes(0, 0, 1, 0)), "top magic node is wind")
	check(map.edge_runes_at(Vector2i(0, 4)).equals(runes(1, 0, 0, 0)), "magic node 2 is water")
	check(map.edge_runes_at(Vector2i(0, 0)).is_empty(), "a cell without a magic node has none")
	check(
		map.harvest_runes_at(Vector2i(0, 4)).equals(runes(1, 1, 0, 0)),
		"magic node harvest from the map"
	)


func test_costs_and_chains() -> void:
	var d := board_for(carved_sword(), stocked())
	var p: PlacementState = d.carvings()[0]
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(d.edges().size() == 5, "kindle's chain has 5 lines: 1 own, 3 to magic, 1 magic-magic")
	check(d.chain(p).size() == 5, "every line is in kindle's chain")
	check(
		DisenchantBoard.edge_key(e0, m(0, 4)) == DisenchantBoard.edge_key(m(0, 4), e0),
		"edge keys don't depend on direction"
	)
	check(
		d.edge_cost(DisenchantBoard.edge_key(e0, e1)).equals(runes(1, 1, 0, 0)),
		"own line costs fire + water"
	)
	check(
		d.edge_cost(DisenchantBoard.edge_key(e0, m(1, 7))).equals(runes(0, 1, 0, 1)),
		"enchantment-magic line costs the material's and the magic node's runes"
	)
	check(
		d.edge_cost(DisenchantBoard.edge_key(m(4, 4), m(3, 2))).equals(runes(0, 1, 1, 0)),
		"magic-magic line costs both magic nodes' runes"
	)
	check(d.node_harvest_runes(e0).equals(FIRE.harvest_runes), "enchantment node harvest")
	check(
		d.check_cut(DisenchantBoard.edge_key(m(0, 4), m(4, 4))) != "",
		"only committed lines can be cut"
	)


func test_replay_and_payouts() -> void:
	var player := stocked()
	var d := board_for(carved_sword(), player)
	var p: PlacementState = d.carvings()[0]
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	var first := DisenchantBoard.edge_key(e0, m(0, 4))
	check(d.plan_cut(first) == "", "a cut you can't afford can still be planned")
	check(d.outcomes()[0].error == "Needs 1 water, 1 fire more", "you start with no runes")
	check(d.plan_cut(first) != "", "the same line can't be planned twice")
	d.plan_dissolve(FIRE)
	check(d.outcomes()[1].after_blocked, "steps after a blocked one wait")
	check(d.first_blocked() == 0, "the first blocked step is found")
	d.undo_last()
	d.undo_last()
	check(d.state.disenchant_plan.is_empty(), "undo from the end")

	d.plan_dissolve(FIRE)
	d.plan_dissolve(WATER)
	check(d.runes().equals(runes(3, 3, 0, 0)), "dissolving gives the material's runes")
	d.plan_cut(first)
	var o: DisenchantBoard.Outcome = d.outcomes()[2]
	check(o.spent.equals(runes(1, 1, 0, 0)), "the cut costs its displayed runes")
	check(o.freed == [m(0, 4)], "cutting a magic node's only line frees it")
	check(d.runes().equals(runes(3, 3, 0, 0)), "the freed magic node pays out its harvest")
	d.plan_cut(DisenchantBoard.edge_key(e1, m(4, 4)))
	check(d.outcomes()[3].freed.is_empty(), "a node with lines left doesn't pay out")
	check(d.runes().equals(runes(2, 2, 0, 0)), "runes after the second cut")
	d.plan_cut(DisenchantBoard.edge_key(m(4, 4), m(3, 2)))
	check(d.first_blocked() == 4, "the magic-magic cut needs wind")
	check(d.outcomes()[4].error == "Needs 1 wind more", "and says what's missing")
	d.undo_last()
	d.plan_dissolve(RED)
	d.plan_cut(DisenchantBoard.edge_key(m(4, 4), m(3, 2)))
	o = d.outcomes()[5]
	check(o.error == "" and o.freed.size() == 2, "cutting the last line of two nodes frees both")
	check(d.runes().equals(runes(2, 3, 3, 1)), "both freed magic nodes pay out")
	d.plan_cut(DisenchantBoard.edge_key(e0, m(1, 7)))
	d.plan_cut(DisenchantBoard.edge_key(e0, e1))
	o = d.outcomes()[7]
	check(o.freed.size() == 2, "the last own line frees both enchantment nodes")
	check(
		o.gained.equals(FIRE.harvest_runes.plus(WATER.harvest_runes)),
		"each enchantment node pays out its material's harvest, once"
	)
	check(d.first_blocked() == -1, "the whole plan can be done")
	var again := board_for(d.board.item, player)
	check(again.state.disenchant_plan.size() == 8, "the plan is kept on the item")
	check(again.runes().equals(d.runes()), "replaying the kept plan gives the same runes")


func test_pull_out_and_commit() -> void:
	var player := stocked()
	var inst := carved_sword()
	var d := board_for(inst, player)
	var p: PlacementState = d.carvings()[0]
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	check(d.check_pull_out(p).begins_with("Cut every line"), "can't pull out with lines left")
	check(d.check_commit() == "Plan a disenchant first", "nothing planned")
	for mat in [FIRE, WATER, RED]:
		d.plan_dissolve(mat)
	for k in [
		DisenchantBoard.edge_key(e0, m(0, 4)),
		DisenchantBoard.edge_key(e1, m(4, 4)),
		DisenchantBoard.edge_key(m(4, 4), m(3, 2)),
		DisenchantBoard.edge_key(e0, m(1, 7)),
		DisenchantBoard.edge_key(e0, e1),
	]:
		d.plan_cut(k)
	check(
		d.check_commit() == "Pull out an enchantment before committing", "cuts alone don't commit"
	)
	check(d.plan_pull_out(p) == "", "pull out once every line is planned cut")
	check(d.plan_pull_out(p) != "", "pull out only once")
	check(d.check_commit() == "", "a whole plan can commit")
	var done := d.commit()
	check(done == [p], "kindle pulled out")
	check(d.carvings().is_empty() and d.edges().is_empty(), "no carvings or lines left")
	check(inst.enchantment_graph_state.lines.is_empty(), "the chain's drawn lines are gone")
	check(d.state.disenchant_plan.is_empty(), "the plan is cleared")
	for mat in [FIRE, WATER, RED]:
		check(player.get_material_count(mat) == 0, "dissolved %s is used up" % mat.display_name)
	var b := d.board
	check(not b.is_occupied(Vector2i(2, 5)), "kindle's own line cells are free")
	check(not b.is_occupied(Vector2i(4, 3)), "the magic-magic line's cells are free")
	check(b.node_at(Vector2i(1, 5)) == "", "the enchantment's node cells are free")
	check(b.check_place(KINDLE, Vector2i(1, 5), 0) == "", "kindle can be carved there again")
	check(b.check_line_start(Vector2i(3, 2)) == "", "the freed magic node can be used again")


func test_no_partial_commits() -> void:
	var player := stocked()
	player.add_material(FIRE, 2)
	player.add_material(WATER, 2)
	var d := board_for(carved_sword(true), player)
	check(d.carvings().size() == 2, "two carvings")
	var lower: PlacementState = d.carvings()[1]
	check(d.chain(lower).size() == 4, "the lower kindle's chain has 4 lines")
	var upper: PlacementState = d.carvings()[0]
	var e0 := InscriptionBoard.enchantment_key(upper.id, 0)
	var e1 := InscriptionBoard.enchantment_key(upper.id, 1)
	for mat in [FIRE, WATER, RED, FIRE, WATER]:
		d.plan_dissolve(mat)
	for k in d.chain(upper):
		d.plan_cut(k)
	d.plan_pull_out(upper)
	d.plan_cut(d.chain(lower)[0])
	check(d.first_blocked() == -1, "every step can be done")
	check(
		d.check_commit().begins_with("Every enchantment you cut into"),
		"a half-cut enchantment blocks the commit"
	)
	check(d.commit().is_empty() and d.carvings().size() == 2, "nothing is committed")
	d.undo_last()
	check(d.check_commit() == "", "without the stray cut it commits")
	check(d.commit().size() == 1 and d.carvings() == [lower], "only the planned one comes out")
	check(d.board.node_at(Vector2i(-1, 9)) != "", "the other carving stays")
	check(not d.has_edge(DisenchantBoard.edge_key(e0, e1)), "the removed chain's lines are gone")


func test_planned_dissolves_stay_with_the_item() -> void:
	var player := Player.new()
	player.add_material(FIRE, 1)
	var inst := carved_sword()
	var d := board_for(inst, player)
	var other := board_for(carved_sword(), player)
	check(d.plan_dissolve(FIRE) == "", "dissolve planned")
	check(
		player.get_material_count(FIRE) == 0 and d.board.planned_count(FIRE) == 1,
		"a planned dissolve moves the material into the item"
	)
	check(other.check_dissolve(FIRE).begins_with("You don't have"), "no other item can plan it")
	check(d.check_dissolve(FIRE) != "", "nor can this one twice")
	d.undo_last()
	check(player.get_material_count(FIRE) == 1, "undoing a dissolve gives the material back")
	d.plan_dissolve(FIRE)
	d.clear_plan()
	check(
		player.get_material_count(FIRE) == 1 and d.state.disenchant_plan.is_empty(),
		"clearing the plan gives everything back"
	)
	check(d.check_dissolve(BLUE).begins_with("You don't have"), "can't dissolve what you lack")


## A big node is one node: its lines at both ports are its edges, and it's freed (paying its harvest
## once) when the last of them is cut
func test_big_node_with_ports() -> void:
	var player := Player.new()
	for mat in [FIRE, YELLOW]:
		player.add_material(mat, 3)
	var b := PortBoard.board(player)
	var o := PortBoard.ORIGIN
	var p := b.place(PortBoard.BASTION, o, 0)
	var big := InscriptionBoard.enchantment_key(p.id, 0)
	b.insert_material(big, FIRE)
	b.insert_material(InscriptionBoard.enchantment_key(p.id, 1), YELLOW)
	b.insert_material(InscriptionBoard.enchantment_key(p.id, 2), YELLOW)
	b.add_line(PortBoard.path([PortBoard.MAGIC_ABOVE, Vector2i(5, 2), o]))
	b.add_line(PortBoard.path([o + Vector2i(1, 1), Vector2i(5, 5), PortBoard.MAGIC_BELOW]))
	check(b.commit().size() == 1, "Bastion commits: " + b.check_commit())
	var d := DisenchantBoard.new(b)
	check(d.node_edges(big).size() == 5, "the big node's 3 fixed and 2 drawn lines are all its own")
	check(d.chain(p).size() == 5, "Bastion's chain is its 5 lines")
	var left := InscriptionBoard.enchantment_key(p.id, 1)
	var first := DisenchantBoard.edge_key(left, big)
	var second := DisenchantBoard.edge_key(left, big, 1)
	check(
		d.has_edge(first) and d.has_edge(second),
		"the two lines between the same nodes are two edges"
	)
	check(d.edge_cells(first) != d.edge_cells(second), "each with its own cells")
	check(d.edge_cost(second).equals(d.edge_cost(first)), "and each with its own cost")
	check(d.plan_cut(second) == "", "the second line can be planned on its own")
	check(not d.is_cut_planned(first), "without planning the first")
	check(d.planned_step_of_edge(second) == 0, "the plan finds the right line")
	check(d.cut_step(second).line == 1, "its step names which of the two lines it cuts")
	d.undo_last()
	var steps: Array[DisenchantStep] = []
	for i in 4:
		steps.append(DisenchantStep.dissolve(FIRE))
	steps.append(DisenchantStep.dissolve(YELLOW))
	steps.append(DisenchantStep.dissolve(YELLOW))
	for k in d.node_edges(big):
		steps.append(d.cut_step(k))
	var outs := d.replay(steps)
	var freed_at := -1
	for i in outs.size():
		check(outs[i].error == "", "step %d can be done: %s" % [i, outs[i].error])
		if big in outs[i].freed:
			freed_at = i
	check(freed_at == outs.size() - 1, "the big node is freed by the cut of its last line")


## Bastion committed on the open port board, with a line drawn from each of its big node's ports
func committed_bastion(player: Player) -> InscriptionBoard:
	for mat in [FIRE, YELLOW]:
		player.add_material(mat, 3)
	var b := PortBoard.board(player)
	var o := PortBoard.ORIGIN
	var p := b.place(PortBoard.BASTION, o, 0)
	b.insert_material(InscriptionBoard.enchantment_key(p.id, 0), FIRE)
	b.insert_material(InscriptionBoard.enchantment_key(p.id, 1), YELLOW)
	b.insert_material(InscriptionBoard.enchantment_key(p.id, 2), YELLOW)
	b.add_line(PortBoard.path([PortBoard.MAGIC_ABOVE, Vector2i(5, 2), o]))
	b.add_line(PortBoard.path([o + Vector2i(1, 1), Vector2i(5, 5), PortBoard.MAGIC_BELOW]))
	b.commit()
	return b


## Two lines between the same nodes read as "line 1" and "line 2" in the plan and tooltips; a line
## with no twin keeps its plain name
func test_parallel_line_names() -> void:
	var b := committed_bastion(Player.new())
	var d := DisenchantBoard.new(b)
	var p := d.carvings()[0]
	var big := InscriptionBoard.enchantment_key(p.id, 0)
	var left := InscriptionBoard.enchantment_key(p.id, 1)
	var right := InscriptionBoard.enchantment_key(p.id, 2)
	var first := DisenchantBoard.edge_key(left, big)
	var second := DisenchantBoard.edge_key(left, big, 1)
	check(
		d.edge_name(first).ends_with(" (line 1)"), "the first twin is line 1: " + d.edge_name(first)
	)
	check(
		d.edge_name(second).ends_with(" (line 2)"), "the second is line 2: " + d.edge_name(second)
	)
	check(
		d.describe_step(d.cut_step(second)) == "Cut %s" % d.edge_name(second),
		"its plan step reads like its name: " + d.describe_step(d.cut_step(second))
	)
	check(
		(
			d.describe_step(d.cut_step(second)).contains("Bastion A")
			and d.describe_step(d.cut_step(second)).contains("Bastion B")
		),
		"and names both ends by their labels"
	)
	var single := DisenchantBoard.edge_key(big, right)
	check(not d.edge_name(single).contains("(line"), "a single line has no number")


## A saved plan made before Bastion's shape changed: its big node's second port moved and one of
## its two lines to the left node went. Opening the item drops the drawn line that no longer ends
## at a port and the planned cuts of lines that are gone, and keeps the rest.
func test_saved_plans_fit_changed_ports() -> void:
	var player := Player.new()
	var b := committed_bastion(player)
	var d := DisenchantBoard.new(b)
	var p := d.carvings()[0]
	var big := InscriptionBoard.enchantment_key(p.id, 0)
	var left := InscriptionBoard.enchantment_key(p.id, 1)
	var above := DisenchantBoard.edge_key(InscriptionBoard.magic_key(PortBoard.MAGIC_ABOVE), big)
	var below := DisenchantBoard.edge_key(big, InscriptionBoard.magic_key(PortBoard.MAGIC_BELOW))
	for k in [above, below, DisenchantBoard.edge_key(left, big, 1)]:
		b.state.disenchant_plan.append(d.cut_step(k))
	var kept := d.cut_step(DisenchantBoard.edge_key(left, big))
	b.state.disenchant_plan.append(kept)
	var changed: Enchantment = PortBoard.BASTION.duplicate(true)
	changed.nodes[0].ports = [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i]
	changed.lines.remove_at(2)
	p.enchantment = changed
	var again := InscriptionBoard.new(b.item, player)
	check(again.state.lines.size() == 1, "the line at the moved port is taken off")
	check(
		again.state.lines[0].cells[0] == PortBoard.MAGIC_ABOVE,
		"the line at the port that stayed is kept"
	)
	var plan := again.state.disenchant_plan
	check(plan.size() == 2, "the cuts of the two lines that are gone are dropped: %d" % plan.size())
	var d2 := DisenchantBoard.new(again)
	var ok := true
	for s in plan:
		ok = ok and d2.has_edge(DisenchantBoard.step_edge_key(s))
	check(ok, "every cut left in the plan names a line that exists")
