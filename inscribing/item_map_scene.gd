@tool
class_name ItemMapScene
extends Node2D
## Where an item's map is authored: paint cell and magic node tiles on a hex TileMapLayer,
## then press Bake to write them into the item's HexMapDefinition, which is what the game reads.
##
## A painted tile at (column, row) is the map cell at that odd-r offset position, so paint from
## column 0 and row 0 rightwards and downwards. A tile is a magic node when its tile data has
## MAGIC_NODE_DATA set; every other tile is a plain cell.

## The tile set custom data layer (a bool) that marks a tile as a magic node
const MAGIC_NODE_DATA := "magic_node"

## The HexMapDefinition that Bake writes the painted cells into
@export var map_definition: HexMapDefinition:
	set(value):
		map_definition = value
		update_configuration_warnings()

## The TileMapLayer holding the painted cells
@export var cells_layer: TileMapLayer:
	set(value):
		if cells_layer and cells_layer.changed.is_connected(update_configuration_warnings):
			cells_layer.changed.disconnect(update_configuration_warnings)
		cells_layer = value
		if cells_layer and Engine.is_editor_hint():
			cells_layer.changed.connect(update_configuration_warnings)
		update_configuration_warnings()

@export_tool_button("Bake", "Save") var bake_action: Callable = bake


## Writes the painted cells into map_definition and saves it
func bake() -> Error:
	if map_definition == null or map_definition.resource_path == "":
		push_error("Set Map Definition to a saved HexMapDefinition before baking")
		return ERR_UNCONFIGURED
	return bake_into(map_definition, map_definition.resource_path)


## Writes the painted cells into `target` and saves it to `path`. Other fields are kept.
func bake_into(target: HexMapDefinition, path: String) -> Error:
	var problem := check_cells()
	if problem != "":
		push_error("Can't bake %s: %s" % [name, problem])
		return ERR_INVALID_DATA
	target.layout = build_layout()
	var err := ResourceSaver.save(target, path)
	if err != OK:
		push_error("Could not save %s (error %d)" % [path, err])
	target.emit_changed()
	update_configuration_warnings()
	return err


## Why the painted cells can't be baked, or "" when they can
func check_cells() -> String:
	if cells_layer == null:
		return "Set Cells Layer to the TileMapLayer holding the painted cells"
	var tiles_err := _check_tile_set(cells_layer.tile_set)
	if tiles_err != "":
		return tiles_err
	var used := cells_layer.get_used_cells()
	if used.is_empty():
		return "No cells painted yet"
	for c in used:
		if c.x < 0 or c.y < 0:
			return "A cell at %s is left of column 0 or above row 0" % c
	return ""


## The layout rows the painted cells bake to
func build_layout() -> PackedStringArray:
	var cells: Array[Vector2i] = []
	var magic: Array[Vector2i] = []
	for c in cells_layer.get_used_cells():
		var a := Hex.offset_to_axial(c.x, c.y)
		cells.append(a)
		var data := cells_layer.get_cell_tile_data(c)
		if data and data.get_custom_data(MAGIC_NODE_DATA):
			magic.append(a)
	return HexMapDefinition.layout_from_cells(cells, magic)


## Whether map_definition already holds exactly the painted cells
func is_baked() -> bool:
	return (
		map_definition != null and check_cells() == "" and map_definition.layout == build_layout()
	)


## What's wrong with the scene, shown as warnings in the editor's scene tree
func get_problems() -> PackedStringArray:
	var out := PackedStringArray()
	if map_definition == null:
		out.append("Set Map Definition to the HexMapDefinition this map bakes into")
	var problem := check_cells()
	if problem != "":
		out.append(problem)
	elif map_definition and not is_baked():
		out.append("Not baked: the painted cells differ from the map definition. Press Bake.")
	return out


func _get_configuration_warnings() -> PackedStringArray:
	return get_problems()


func _check_tile_set(tiles: TileSet) -> String:
	if tiles == null:
		return "The cells layer has no tile set"
	if (
		tiles.tile_shape != TileSet.TILE_SHAPE_HEXAGON
		or tiles.tile_layout != TileSet.TILE_LAYOUT_STACKED
		or tiles.tile_offset_axis != TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	):
		return "The tile set has to be hexagon, stacked, horizontal offset (use hex_map_tiles.tres)"
	if tiles.get_custom_data_layer_by_name(MAGIC_NODE_DATA) == -1:
		return 'The tile set needs a bool custom data layer named "%s"' % MAGIC_NODE_DATA
	return ""
