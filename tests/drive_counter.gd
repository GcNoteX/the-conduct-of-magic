extends Node

"""
Plays the counter through two days, from a commission to its collection, and saves screenshots.
Run (needs a display): godot --path . res://tests/drive_counter.tscn -- <output_dir>
"""

var out_dir := "user://"
var day: Day


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(
		func():
			printerr("drive_counter timed out")
			get_tree().quit(1)
	)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	day = preload("res://day/day.tscn").instantiate()
	add_child(day)
	await _frames(5)
	day.switch_to(Day.ShopSide.INSCRIBING)
	await _frames(2)
	_shot("00_table_empty")
	day.switch_to(Day.ShopSide.COUNTER)
	await _frames(2)
	_shot("01_new_customer")

	# Accept Elsa, refuse Bram, then show Ines with her ID and permit
	day.counter.accept()
	day.counter.refuse()
	await _frames(2)
	_shot("02_id_and_permit")
	day.counter.accept()
	var yellow: EnchantmentMaterialDefinition = load(
		"res://items/enchantment_materials/yellow_stone/yellow_stone.tres"
	)
	day.counter.buy(yellow)
	await _frames(2)
	_shot("03_bought_from_supplier")

	# At the table, carve one of Elsa's two enchantments and all of Ines's
	day.end_side()
	await _frames(2)
	for c in day.player.commissions:
		var wanted := c.visit.slip.enchantments
		_carve(c.item, wanted.slice(0, 1) if wanted.size() > 1 else wanted)
	day.table.resume()
	var elsas := day.player.items.find(day.player.commissions[0].item)
	day.table._item_picker.select(elsas)
	day.table._open_item(elsas)
	await _frames(2)
	_shot("04_table_shows_owner")
	day.table.open_supplier()
	await _frames(2)
	_shot("04b_rush_order")
	day.table.close_supplier()
	day.end_side()
	await _frames(2)
	_shot("05_day_over")

	# Day 2: Elsa and Ines come back first
	day.start_next_day()
	await _frames(2)
	_shot("06_collector")
	day.counter.hand_back()
	await _frames(2)
	_shot("07_paid")
	day.counter.hand_back()
	day.end_side()
	day.end_side()
	await _frames(2)
	_shot("08_day_two_over")
	print("money: %dg" % day.player.money)
	get_tree().quit(0)


func _carve(inst: ItemInstance, carved: Array[Enchantment]) -> void:
	if inst.enchantment_graph_state == null:
		inst.enchantment_graph_state = GraphState.new()
	for e in carved:
		var p := PlacementState.new()
		p.enchantment = e
		p.materials.resize(e.nodes.size())
		p.committed = true
		inst.enchantment_graph_state.placements.append(p)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(shot_name + ".png"))
