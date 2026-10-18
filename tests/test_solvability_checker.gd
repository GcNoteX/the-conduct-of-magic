extends Node

"""
Headless checks for the solvability checker dev tool.
Run: godot --headless --path . res://tests/test_solvability_checker.tscn
Exits with code 1 if any check fails.
"""

const CARVED := preload("res://inscribing/demo/carved_demo_sword.tres")
const SWORD := preload("res://inscribing/demo/long_sword.tres")
const FIRE := preload("res://items/enchantment_materials/fire_stone/fire_stone.tres")
const WATER := preload("res://items/enchantment_materials/water_stone/water_stone.tres")
const RED := preload("res://items/enchantment_materials/red_stone/red_stone.tres")
const BLUE := preload("res://items/enchantment_materials/blue_stone/blue_stone.tres")
const YELLOW := preload("res://items/enchantment_materials/yellow_stone/yellow_stone.tres")

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_whole_board()
	test_single_enchantment()
	test_against_every_cut_order()
	test_unsolvable_and_empty()
	test_component_toggle()
	test_plans_commit()
	test_report_matches_the_plan_list()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func demo_inventory() -> Dictionary:
	return {FIRE: 3, WATER: 3, RED: 3, BLUE: 3, YELLOW: 1}


func carved_board() -> DisenchantBoard:
	var inst: ItemInstance = CARVED.duplicate(true)
	return DisenchantBoard.new(InscriptionBoard.new(inst, Player.new()))


func names(s: SolvabilityChecker.Solution) -> String:
	return s.describe_dissolves()


## Every solution the checker gives has to replay cleanly through the rules
func replays_cleanly(
	d: DisenchantBoard, s: SolvabilityChecker.Solution, targets: Array[PlacementState]
) -> bool:
	for o in d.replay(s.steps(targets, d)):
		if o.error != "":
			return false
	return true


func test_whole_board() -> void:
	var d := carved_board()
	var checker := SolvabilityChecker.new(d)
	var all := d.carvings()
	check(checker.lines_to_cut(all).size() == 12, "both chains together have 12 lines")
	var found := checker.solve(all, demo_inventory())
	check(not found.is_empty(), "the carved demo sword can be cleared")
	check(found[0].dissolves.size() == 3, "with 3 dissolves at the fewest")
	check(found[0].cuts.size() == 12, "cutting every line")
	for s in found:
		check(replays_cleanly(d, s, all), "solution %s replays through the rules" % names(s))
	var report := SolvabilityCheck.report(d, demo_inventory())
	check(
		report.contains("Kindle and Keen together: can be cleared"),
		"the report says the board clears"
	)
	check(report.contains("Kindle A (Fire stone)"), "the report says what each node holds")
	check(report.contains("Keen C (Red stone)"), "Keen's nodes are lettered")
	check(report.contains("Cut Kindle A – M2"), "cuts name nodes by their board labels")
	check(not report.contains("node 1"), "no enchantment node numbers to mix up with magic ones")
	var raw_key := RegEx.create_from_string("[em]:-?\\d")
	check(raw_key.search(report) == null, "the report has no raw node keys")


func test_single_enchantment() -> void:
	var d := carved_board()
	var checker := SolvabilityChecker.new(d)
	var kindle: Array[PlacementState] = [d.carvings()[0]]
	var found := checker.solve(kindle, demo_inventory())
	check(
		found.size() == 2 and names(found[0]) == "Blue stone, Fire stone, Water stone",
		"kindle: blue + fire + water at the fewest"
	)
	check(names(found[1]) == "Blue stone, Fire stone, Yellow stone", "or blue + fire + yellow")
	for s in found:
		check(replays_cleanly(d, s, kindle), "kindle's solution %s replays" % names(s))
	var without_blue := demo_inventory()
	without_blue.erase(BLUE)
	found = checker.solve(kindle, without_blue)
	check(found.is_empty(), "without blue (the only stone runes) it can't be cleared")


## The checker's answer for Kindle matches trying every one of its 120 cut orders
func test_against_every_cut_order() -> void:
	var d := carved_board()
	var checker := SolvabilityChecker.new(d)
	var kindle: PlacementState = d.carvings()[0]
	var edges := d.chain(kindle)
	var starts: Array[Array] = [
		[], [FIRE], [FIRE, WATER], [FIRE, YELLOW], [RED, BLUE], [WATER, YELLOW]
	]
	for mats in starts:
		var start := RuneSet.new()
		var dissolves: Array[DisenchantStep] = []
		for m: EnchantmentMaterialDefinition in mats:
			start = start.plus(m.dissolve_runes)
			dissolves.append(DisenchantStep.dissolve(m))
		var brute := false
		for order in permutations(edges):
			var steps := dissolves.duplicate()
			for k: String in order:
				var ends := d.edge_ends(k)
				steps.append(DisenchantStep.cut(ends[0], ends[1]))
			var outs := d.replay(steps)
			if outs.back().error == "":
				brute = true
				break
		var found := checker.find_cut_order(edges, start) != null
		check(
			found == brute,
			"checker agrees with brute force for %d dissolves %s" % [mats.size(), mats]
		)


func test_unsolvable_and_empty() -> void:
	var d := carved_board()
	var checker := SolvabilityChecker.new(d)
	var all := d.carvings()
	check(
		checker.find_cut_order(checker.lines_to_cut(all), RuneSet.new()) == null,
		"no runes, no cuts"
	)
	check(checker.solve(all, {}).is_empty(), "nothing to dissolve means it can't be cleared")
	check(checker.solve(all, {BLUE: 3}).is_empty(), "stone alone can't clear it")
	var inst := ItemInstance.new()
	inst.definition = SWORD
	var bare := DisenchantBoard.new(InscriptionBoard.new(inst, Player.new()))
	var none: Array[PlacementState] = []
	var empty := SolvabilityChecker.new(bare).solve(none, {})
	check(empty.size() == 1 and empty[0].cuts.is_empty(), "an empty board is already clear")


func permutations(items: Array[String]) -> Array:
	if items.size() <= 1:
		return [items.duplicate()]
	var out := []
	for i in items.size():
		var rest := items.duplicate()
		var head: String = rest.pop_at(i)
		for p in permutations(rest):
			out.append([head] + p)
	return out


## The SolvabilityCheck component reports only when enabled, and only for carved items
func test_component_toggle() -> void:
	var player := Player.new()
	for m: EnchantmentMaterialDefinition in demo_inventory():
		player.add_material(m, demo_inventory()[m])
	var component := SolvabilityCheck.new()
	var carved: ItemInstance = CARVED.duplicate(true)
	check(component.check_item(carved, player) == "", "disabled, it stays quiet")
	component.enabled = true
	check(component.check_item(carved, player).contains("can be cleared"), "enabled, it reports")
	var bare := ItemInstance.new()
	bare.definition = SWORD
	check(component.check_item(bare, player) == "", "an item with no carvings is skipped")
	component.free()


## Kindle alone, Keen alone and both: the checker's plan, planned step by step on the board the
## way the table plans it, commits and pulls out exactly those enchantments
func test_plans_commit() -> void:
	for which in [[0], [1], [0, 1]]:
		var player := Player.new()
		for mat: EnchantmentMaterialDefinition in demo_inventory():
			player.add_material(mat, demo_inventory()[mat])
		var d := DisenchantBoard.new(InscriptionBoard.new(CARVED.duplicate(true), player))
		var targets: Array[PlacementState] = []
		for i: int in which:
			targets.append(d.carvings()[i])
		var label := " and ".join(targets.map(func(p: PlacementState): return d.carving_name(p)))
		var found := SolvabilityChecker.new(d).solve(targets, demo_inventory())
		check(not found.is_empty(), "%s can be cleared" % label)
		if found.is_empty():
			continue
		var ok := true
		for s in found[0].steps(targets, d):
			match s.kind:
				DisenchantStep.Kind.DISSOLVE:
					ok = ok and d.plan_dissolve(s.material) == ""
				DisenchantStep.Kind.CUT:
					ok = ok and d.plan_cut(DisenchantBoard.step_edge_key(s)) == ""
				_:
					ok = ok and d.plan_pull_out(d.find_carving(s.placement_id)) == ""
		check(ok, "%s: every step of the plan can be planned" % label)
		check(d.check_commit() == "", "%s: the plan commits (%s)" % [label, d.check_commit()])
		var pulled := d.commit()
		check(pulled.size() == targets.size(), "%s: the commit pulls out %s" % [label, label])
		check(d.carvings().size() == 2 - targets.size(), "%s: only the others stay carved" % label)


## Every planned step reads in the report exactly as the table's plan list shows it
func test_report_matches_the_plan_list() -> void:
	var d := carved_board()
	var report := SolvabilityCheck.report(d, demo_inventory())
	var all := d.carvings()
	var steps := SolvabilityChecker.new(d).solve(all, demo_inventory())[0].steps(all, d)
	for i in steps.size():
		if steps[i].kind != DisenchantStep.Kind.DISSOLVE:
			var row := "%d. %s  (" % [i + 1, d.describe_step(steps[i])]
			check(report.contains(row), "the report has step %s" % row)
