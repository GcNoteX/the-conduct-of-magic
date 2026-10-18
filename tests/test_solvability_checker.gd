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
const CHECKER_SCENE := preload("res://tools/check_solvability.gd")

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_whole_board()
	test_single_enchantment()
	test_against_every_cut_order()
	test_unsolvable_and_empty()
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
	var report: String = CHECKER_SCENE.report(d, demo_inventory())
	check(report.contains("Everything: clearable"), "the report says the board clears")


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
