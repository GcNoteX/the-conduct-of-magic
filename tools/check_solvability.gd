extends Node

## Dev tool scene script: reports whether each carved demo item's disenchant board can be
## cleared, with the fewest materials from the demo player's inventory, and how. The same report
## prints when the game runs with Enabled ticked on the table's SolvabilityCheck node.
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
		print(SolvabilityCheck.report(board, player.material_inventory))
	get_tree().quit()
