extends Node

## Dev tool scene script: reports whether each carved demo item's disenchant board can be
## cleared, with the fewest materials from the demo player's inventory, and how.
## Run: godot --headless --path . res://tools/solvability_checker.tscn [-- res://path/item.tres]
## With an ItemInstance .tres given, it checks that item against the demo inventory instead.

const SETUP := preload("res://inscribing/demo/demo_setup.tres")


func _ready() -> void:
	var player := SETUP.create_player()
	var items: Array[ItemInstance] = []
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		items = player.items
	else:
		for path in args:
			items.append((load(path) as ItemInstance).duplicate(true))
	for inst in items:
		var board := DisenchantBoard.new(InscriptionBoard.new(inst, player))
		if board.carvings().is_empty():
			continue
		print(report(board, player.material_inventory))
	get_tree().quit()


## A readable report: the whole board, then each carving on its own
static func report(board: DisenchantBoard, available: Dictionary) -> String:
	var checker := SolvabilityChecker.new(board)
	var all := board.carvings()
	var name := "%s (%s)" % [board.board.item.definition.display_name, board.board.item.id]
	var out := "%s (%d carvings, %d lines)\n" % [name, all.size(), board.edges().size()]
	out += _line("Everything", checker, all, available, board)
	for p in all:
		var one: Array[PlacementState] = [p]
		out += _line(p.enchantment.enchantment_name, checker, one, available, board)
	return out


static func _line(
	label: String,
	checker: SolvabilityChecker,
	targets: Array[PlacementState],
	available: Dictionary,
	board: DisenchantBoard
) -> String:
	var found := checker.solve(targets, available)
	if found.is_empty():
		return "  %s: can't be cleared with up to %d dissolves\n" % [label, checker.max_dissolves]
	var options: Array[String] = []
	for s in found:
		options.append(s.describe_dissolves())
	var first := found[0]
	var cuts: Array[String] = []
	for k in first.cuts:
		cuts.append("%s (%s)" % [k, board.edge_cost(k).describe()])
	return (
		"  %s: clearable with %d dissolve(s). Options: %s\n    e.g. dissolve %s, cut %s; %s left\n"
		% [
			label,
			first.dissolves.size(),
			" | ".join(options),
			first.describe_dissolves(),
			" → ".join(cuts),
			first.runes_left.describe()
		]
	)
