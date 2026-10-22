extends Node

## Headless regression checks for the legacy play map (play_map.tscn): the line and connection
## conditions, taking materials out of slots, the player inventory the map hands them back to,
## which lines may connect, and the once-per-frame map updates.
## Run: godot --headless --path . res://tests/test_legacy_map_fixes.tscn
## Exits with code 1 if any check fails.

const FIRE := preload("res://tests/fixtures/materials/fire_stone.tres")
const WATER := preload("res://tests/fixtures/materials/water_stone.tres")
const BLUE := preload("res://tests/fixtures/materials/blue_stone.tres")
const MAGIC_NODE := preload("res://map_nodes/magic_node.tscn")
const MAGIC_LINE := preload("res://map_lines/magic_line.tscn")
const ENCHANTMENT_GRID := preload("res://enchantments/enchantments/e1.tscn")
const ENCHANTMENT_NODE := preload("res://map_nodes/enchantment_node.tscn")
const ITEM_BOX := preload("res://map_item/item_box.tscn")
const ENCHANTMENT_BOX := preload("res://map_item/enchantment_box.tscn")

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_condition_classes_load()
	test_lines_condition_counts_lines_not_neighbours()
	test_dropper_keeps_empty_and_sealed_slots()
	test_cursor_returns_only_real_materials()
	test_player_manager_follows_player_rules()
	test_connections_are_not_saved_into_scenes()
	test_nodes_decide_which_lines_may_connect()
	test_box_areas_find_their_box()
	await test_updates_wait_for_the_end_of_the_frame()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func test_condition_classes_load() -> void:
	check(FIRE.activation_conditions.size() == 1, "fire stone has one condition")
	check(FIRE.activation_conditions[0] is NumberOfLinesCondition, "fire stone: lines condition")
	check(
		WATER.activation_conditions.any(func(c): return c is NumberOfConnectionsCondition),
		"water stone: connections condition"
	)


func test_lines_condition_counts_lines_not_neighbours() -> void:
	var node: MagicNode = MAGIC_NODE.instantiate()
	var other: MagicNode = MAGIC_NODE.instantiate()
	var first: MagicLine = MAGIC_LINE.instantiate()
	var second: MagicLine = MAGIC_LINE.instantiate()
	# Two lines joining the same pair of nodes: two lines, one neighbour
	node.mapline_connections.append(first)
	node.mapline_connections.append(second)
	node.mapnode_connections[other] = 2
	var ctx := MaterialActivationContext.new(node)

	var lines := NumberOfLinesCondition.new()
	lines.number_of_lines = 2
	check(lines.is_fulfilled(ctx), "two lines pass a 2-line condition")
	check(
		lines.progress(ctx) == "2/2 lines", "line progress counts lines: %s" % lines.progress(ctx)
	)
	var connections := NumberOfConnectionsCondition.new()
	connections.number_of_lines = 2
	check(not connections.is_fulfilled(ctx), "one neighbour fails a 2-node condition")

	for n: Node in [node, other, first, second]:
		n.free()


func test_dropper_keeps_empty_and_sealed_slots() -> void:
	var holder := MaterialHolder.new()
	var dropper := MaterialDropper.new()
	dropper.holder = holder
	var removed := [0]
	holder.material_removed.connect(func(): removed[0] += 1)

	check(dropper.remove_material() == null, "an empty slot gives nothing")
	check(removed[0] == 0, "an empty slot is left alone")

	holder.embbed_material(FIRE)
	holder.sealed = true
	check(dropper.remove_material() == null, "a sealed slot gives nothing")
	check(holder.get_embedded_material() == FIRE, "a sealed slot keeps its material")

	holder.sealed = false
	check(dropper.remove_material() == FIRE, "an open slot gives its material back")
	check(holder.get_embedded_material() == null, "and is empty afterwards")

	dropper.free()
	holder.free()


func test_cursor_returns_only_real_materials() -> void:
	var previous := PlayerManager.get_player()
	var player := Player.new()
	PlayerManager.set_player(player)
	var holder := MaterialHolder.new()
	var dropper := MaterialDropper.new()
	dropper.holder = holder
	var cursor := MaterialCursor.new()

	cursor.return_material_to_player(dropper)
	check(player.material_inventory.is_empty(), "right-clicking an empty slot adds nothing")

	holder.embbed_material(BLUE)
	holder.sealed = true
	cursor.return_material_to_player(dropper)
	check(player.material_inventory.is_empty(), "right-clicking a sealed slot adds nothing")

	holder.sealed = false
	cursor.return_material_to_player(dropper)
	check(player.get_material_count(BLUE) == 1, "right-clicking a filled slot returns it")
	check(holder.get_embedded_material() == null, "and empties the slot")

	cursor.free()
	dropper.free()
	holder.free()
	PlayerManager.set_player(previous)


func test_player_manager_follows_player_rules() -> void:
	var previous := PlayerManager.get_player()
	var player := Player.new()
	PlayerManager.set_player(player)

	PlayerManager.add_material(null)
	check(player.material_inventory.is_empty(), "a null material is not added")
	PlayerManager.add_material(BLUE, 2)
	check(player.get_material_count(BLUE) == 2, "adding goes to the player")
	PlayerManager.remove_material(BLUE, 2)
	check(not player.material_inventory.has(BLUE), "using up a material drops its entry")

	PlayerManager.set_player(previous)


func test_connections_are_not_saved_into_scenes() -> void:
	var node: MagicNode = MAGIC_NODE.instantiate()
	for p in ["mapnode_connections", "mapline_connections"]:
		check(not is_stored(node, p), "MapNode.%s is not saved into scenes" % p)
	node.free()

	var grid: EnchantmentGrid = ENCHANTMENT_GRID.instantiate()
	for p in ["enodes", "elines"]:
		check(not is_stored(grid, p), "EnchantmentGrid.%s is not saved into scenes" % p)
	grid.free()


func is_stored(o: Object, property: String) -> bool:
	for p in o.get_property_list():
		if p.name == property:
			return p.usage & PROPERTY_USAGE_STORAGE != 0
	return false


func test_nodes_decide_which_lines_may_connect() -> void:
	var grid_a := EnchantmentGrid.new()
	var grid_b := EnchantmentGrid.new()
	var line: MagicLine = MAGIC_LINE.instantiate()
	var magic: MagicNode = MAGIC_NODE.instantiate()
	var enode: EnchantmentNode = ENCHANTMENT_NODE.instantiate()
	enode.bounded_identity = grid_a

	check(magic._may_connect(line), "a free magic node takes a free line")
	check(enode._may_connect(line), "an enchantment node takes a free line")
	line.bounded_identity = grid_a
	check(magic._may_connect(line), "a free magic node takes a grid's line")
	check(enode._may_connect(line), "an enchantment node takes its own grid's line")
	magic.bounded_identity = grid_b
	check(not magic._may_connect(line), "a magic node bound to another grid refuses it")
	line.bounded_identity = grid_b
	check(magic._may_connect(line), "a magic node takes a line of its own grid")
	check(not enode._may_connect(line), "an enchantment node refuses another grid's line")

	for n: Node in [grid_a, grid_b, line, magic, enode]:
		n.free()


func test_box_areas_find_their_box() -> void:
	var item_box: ItemBox = ITEM_BOX.instantiate()
	var item_area: ItemBoxArea = item_box.get_node("PhysicalArea")
	check(item_area.get_item_box() == item_box, "an item box area finds its box")
	var enchantment_box: EnchantmentBox = ENCHANTMENT_BOX.instantiate()
	var enchantment_area: EnchantmentBoxArea = enchantment_box.get_node("PhysicalArea")
	check(
		enchantment_area.get_enchantment_box() == enchantment_box,
		"an enchantment box area finds its box"
	)
	check(item_area.get_box() is MapSourceBox, "box areas share the parent walk")
	item_box.free()
	enchantment_box.free()


func test_updates_wait_for_the_end_of_the_frame() -> void:
	var map := EnchantmentMap.new()
	var other_map := EnchantmentMap.new()
	add_child(map)
	add_child(other_map)
	var grid: EnchantmentGrid = ENCHANTMENT_GRID.instantiate()
	map.add_child(grid)
	var other_grid: EnchantmentGrid = ENCHANTMENT_GRID.instantiate()
	other_map.add_child(other_grid)
	await get_tree().process_frame
	check(EmapUpdateManager.pending_roots().is_empty(), "nothing waits once the maps are set up")

	var enode: EnchantmentNode = grid.get_node("EnchantmentNode")
	var ctx := enode.activation_context()
	check(ctx.source_node == enode, "the context names the node")
	check(ctx.enchantment == grid, "the context names the node's grid")
	check(ctx.map == map, "the context names the node's map")

	var always := EnchantmentMaterialDefinition.new()
	enode.material_holder.embbed_material(always)
	EmapUpdateManager.request_update(enode)
	EmapUpdateManager.request_update(grid)
	check(not enode.is_activated, "a change does not update the map straight away")
	check(EmapUpdateManager.pending_roots() == [map], "several changes wait as one update")
	EmapUpdateManager.request_update(other_grid)
	check(EmapUpdateManager.pending_roots().size() == 2, "each map waits on its own")
	await get_tree().process_frame
	check(enode.is_activated, "the map is updated at the end of the frame")
	check(EmapUpdateManager.pending_roots().is_empty(), "and nothing waits afterwards")

	map.free()
	other_map.free()
