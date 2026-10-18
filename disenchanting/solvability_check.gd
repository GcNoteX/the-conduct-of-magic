@icon("res://editor/icons/solvability_check.svg")
class_name SolvabilityCheck
extends Node

## Dev component: tick Enabled in the inspector and, when the scene runs, it prints to the Output
## panel whether each carved item's disenchant board can be cleared, with which materials, and a
## cut order that works. Nodes go by the labels drawn on the board in Disenchant mode: "M4" for
## magic node 4, "Keen B" for Keen's second node. The inscribing table holds one and calls it when
## it opens a carved item.

## Prints a report when the table starts and whenever it opens a carved item
@export var enabled: bool = false
## The most materials a solution may dissolve
@export_range(0, 10) var max_dissolves: int = 6


## Prints the report for every item in `items` that has carvings, when enabled
func check_items(items: Array[ItemInstance], player: Player) -> void:
	for inst in items:
		check_item(inst, player)


## Prints the report for `inst` when enabled and it has carvings, checked against the player's
## materials (and any the item's disenchant plan already holds, since undoing the plan gives them
## back). Returns the report, or "" when nothing was checked.
func check_item(inst: ItemInstance, player: Player) -> String:
	if not enabled:
		return ""
	var board := DisenchantBoard.new(InscriptionBoard.new(inst, player))
	if board.carvings().is_empty():
		return ""
	var available := player.material_inventory.duplicate()
	for s in board.state.disenchant_plan:
		if s.kind == DisenchantStep.Kind.DISSOLVE and s.material:
			available[s.material] = available.get(s.material, 0) + 1
	var text := report(board, available, max_dissolves)
	print(text)
	return text


## A report a person can read: how the board's nodes are named, then every carving together and
## each on its own. Nodes go by the labels drawn on the board in Disenchant mode, and each cut
## reads exactly like its step in the table's plan list.
static func report(board: DisenchantBoard, available: Dictionary, most_dissolves := 6) -> String:
	var checker := SolvabilityChecker.new(board)
	checker.max_dissolves = most_dissolves
	var all := board.carvings()
	var names: Array[String] = []
	for p in all:
		names.append(board.carving_name(p))
	var out := "── Solvability check: %s ──\n" % InscriptionBoard.item_name(board.board.item)
	out += "Carved: %s. Lines to cut: %d.\n" % [", ".join(names), board.edges().size()]
	out += "Your materials: %s.\n" % _describe_materials(available)
	out += _naming(board, all)
	if not board.state.disenchant_plan.is_empty():
		out += (
			"This item already has a disenchant plan: the steps below start from an empty one, "
			+ "so undo it first.\n"
		)
	var together := " and ".join(names) + (" together" if all.size() > 1 else "")
	out += _section(together, checker, all, available, board)
	if all.size() > 1:
		for p in all:
			var one: Array[PlacementState] = [p]
			out += _section(board.carving_name(p) + " alone", checker, one, available, board)
	return out


## How to read the node names, with what each enchantment node holds
static func _naming(board: DisenchantBoard, carvings: Array[PlacementState]) -> String:
	var out := "Node names, as labelled on the board in Disenchant mode:\n"
	out += "  M4 = magic node 4."
	if not carvings.is_empty():
		var n := board.carving_name(carvings[0])
		out += " %s A = %s's first node, %s B its second, and so on." % [n, n, n]
	out += "\n"
	for p in carvings:
		var holds: Array[String] = []
		for i in p.enchantment.nodes.size():
			var k := InscriptionBoard.enchantment_key(p.id, i)
			holds.append(board.node_name(k))
		out += "  %s\n" % ", ".join(holds)
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
	var count := first.dissolves.size()
	var out := (
		"\n%s: can be cleared by dissolving %d material%s.\n"
		% [label, count, "" if count == 1 else "s"]
	)
	if found.size() > 1:
		var options: Array[String] = []
		for s in found:
			options.append(s.describe_dissolves())
		out += "  Any of these %d choices works: %s.\n" % [found.size(), "  |  ".join(options)]
	out += "  One way, numbered as in the plan list and on the cut lines:\n"
	var steps := first.steps(targets, board)
	var dissolves := first.dissolves.size()
	if dissolves > 0:
		out += (
			"    Dissolve (step%s): %s. Double-click each material in your list.\n"
			% [_step_range(1, dissolves), first.describe_dissolves()]
		)
	out += "    Then, in order:\n"
	for i in steps.size():
		var s := steps[i]
		var row := "      %d. %s" % [i + 1, board.describe_step(s)]
		if s.kind == DisenchantStep.Kind.CUT:
			var cost := board.edge_cost(DisenchantBoard.edge_key(s.a, s.b))
			out += "%s  (click the line; costs %s)\n" % [row, cost.describe()]
		elif s.kind == DisenchantStep.Kind.PULL_OUT:
			var n := board.carving_name(board.find_carving(s.placement_id))
			out += "%s  (click any %s node)\n" % [row, n]
	out += "    Then press Commit.\n"
	out += "  Runes left over: %s.\n" % first.runes_left.describe()
	return out


## " 1" or "s 1–3"
static func _step_range(from: int, to: int) -> String:
	return " %d" % from if from == to else "s %d–%d" % [from, to]


static func _describe_materials(available: Dictionary) -> String:
	var parts: Array[String] = []
	for m: EnchantmentMaterialDefinition in available:
		if available[m] > 0:
			parts.append("%d %s" % [available[m], InscriptionBoard.material_name(m)])
	return ", ".join(parts) if not parts.is_empty() else "none"
