class_name SolvabilityCheck
extends Node

## Dev component: tick Enabled in the inspector and, when the scene runs, it prints to the Output
## panel whether each carved item's disenchant board can be cleared, with which materials, and a
## cut order that works. Magic nodes are named by the numbers drawn on them in Disenchant mode,
## and enchantment nodes by their enchantment, number and material, like "Kindle node 1 (Fire
## stone)". The inscribing table holds one and calls it when it opens a carved item.

## Prints a report when the table starts and whenever it opens a carved item
@export var enabled: bool = false
## The most materials a solution may dissolve
@export_range(0, 10) var max_dissolves: int = 6


## Prints the report for every item in `items` that has carvings, when enabled
func check_items(items: Array[ItemInstance], player: Player) -> void:
	for inst in items:
		check_item(inst, player)


## Prints the report for `inst` when enabled and it has carvings, checked against the player's
## materials. Returns the report, or "" when nothing was checked.
func check_item(inst: ItemInstance, player: Player) -> String:
	if not enabled:
		return ""
	var board := DisenchantBoard.new(InscriptionBoard.new(inst, player))
	if board.carvings().is_empty():
		return ""
	var text := report(board, player.material_inventory, max_dissolves)
	print(text)
	return text


## A report a person can read: the whole board, then each carving on its own
static func report(board: DisenchantBoard, available: Dictionary, most_dissolves := 6) -> String:
	var checker := SolvabilityChecker.new(board)
	checker.max_dissolves = most_dissolves
	var all := board.carvings()
	var names: Array[String] = []
	for p in all:
		names.append(p.enchantment.enchantment_name)
	var out := "── Solvability check: %s ──\n" % _item_name(board.board.item)
	out += "Carved: %s. Lines to cut: %d.\n" % [", ".join(names), board.edges().size()]
	out += "Magic node numbers are the ones drawn on the board in Disenchant mode.\n"
	out += "Materials: %s.\n" % _describe_materials(available)
	out += _section("Everything", checker, all, available, board)
	if all.size() > 1:
		for p in all:
			var one: Array[PlacementState] = [p]
			out += _section(p.enchantment.enchantment_name, checker, one, available, board)
	return out


static func _section(
	label: String,
	checker: SolvabilityChecker,
	targets: Array[PlacementState],
	available: Dictionary,
	board: DisenchantBoard
) -> String:
	var found := checker.solve(targets, available)
	if found.is_empty():
		return (
			"\n%s: can't be cleared, even dissolving up to %d materials.\n"
			% [label, checker.max_dissolves]
		)
	var first := found[0]
	var out := (
		"\n%s: can be cleared by dissolving %d material%s.\n"
		% [label, first.dissolves.size(), "" if first.dissolves.size() == 1 else "s"]
	)
	var options: Array[String] = []
	for s in found:
		options.append(s.describe_dissolves())
	out += "  Cheapest choices: %s\n" % "  or  ".join(options)
	out += (
		"  One way, dissolving %s first, then cutting in this order:\n" % first.describe_dissolves()
	)
	for i in first.cuts.size():
		var k := first.cuts[i]
		out += (
			"    %d. %s (costs %s)\n" % [i + 1, board.edge_name(k), board.edge_cost(k).describe()]
		)
	out += (
		"  Then pull out %s. Runes left over: %s.\n"
		% [_target_names(targets), first.runes_left.describe()]
	)
	return out


static func _target_names(targets: Array[PlacementState]) -> String:
	var names: Array[String] = []
	for p in targets:
		names.append(p.enchantment.enchantment_name)
	return " and ".join(names)


static func _describe_materials(available: Dictionary) -> String:
	var parts: Array[String] = []
	for m: EnchantmentMaterialDefinition in available:
		if available[m] > 0:
			parts.append("%d %s" % [available[m], InscriptionBoard.material_name(m)])
	return ", ".join(parts) if not parts.is_empty() else "none"


static func _item_name(inst: ItemInstance) -> String:
	var def := inst.definition
	return def.display_name if def and def.display_name != "" else str(inst.id)
