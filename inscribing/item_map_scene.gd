@tool
@icon("res://editor/icons/item_map_scene.svg")
class_name ItemMapScene
extends Node2D
## Where an item's map is authored: paint cell tiles on the Cells layer and magic node tiles on
## the Magic nodes layer above it, then press Bake to write them into the item's HexMapDefinition,
## which is what the game reads.
##
## A painted tile at (column, row) is the map cell at that odd-r offset position, so paint from
## column 0 and row 0 rightwards and downwards. Each magic node tile carries its runes as tile
## custom data (EDGE_RUNES_DATA and HARVEST_RUNES_DATA), and Bake copies them into the map.
## Bigger or custom magic nodes are scene tiles whose root is a MagicNodeTile, which holds the
## runes and the extra cells the node covers.

## The tile set custom data layer (a bool) that marks a tile as a magic node
const MAGIC_NODE_DATA := "magic_node"
## The tile set custom data layer (a RuneSet) with the runes a magic node puts on each of its lines
const EDGE_RUNES_DATA := "edge_runes"
## The tile set custom data layer (a RuneSet) with the runes a magic node gives back when freed
const HARVEST_RUNES_DATA := "harvest_runes"
## How often, in seconds, the editor looks for newly painted cells to refresh the warnings.
## TileMapLayer doesn't signal cell edits, so painting is noticed by polling.
const PAINT_POLL_SECONDS := 0.25

## The HexMapDefinition that Bake writes the painted cells into
@export var map_definition: HexMapDefinition:
	set(value):
		if map_definition and map_definition.changed.is_connected(update_configuration_warnings):
			map_definition.changed.disconnect(update_configuration_warnings)
		map_definition = value
		if map_definition and Engine.is_editor_hint():
			map_definition.changed.connect(update_configuration_warnings)
		update_configuration_warnings()

## The TileMapLayer holding the painted cells
@export var cells_layer: TileMapLayer:
	set(value):
		cells_layer = value
		update_configuration_warnings()

## The TileMapLayer holding the magic node tiles, drawn above the cells
@export var magic_layer: TileMapLayer:
	set(value):
		magic_layer = value
		update_configuration_warnings()

@export_tool_button("Bake", "Save") var bake_action: Callable = bake

var _poll_left := 0.0
var _painted_hash := 0


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	_painted_hash = painted_hash()
	update_configuration_warnings()


func _process(delta: float) -> void:
	_poll_left -= delta
	if _poll_left > 0.0:
		return
	_poll_left = PAINT_POLL_SECONDS
	refresh_if_painted()


## Refreshes the editor warnings when the painted cells changed since the last look.
## Returns whether they changed.
func refresh_if_painted() -> bool:
	var h := painted_hash()
	if h == _painted_hash:
		return false
	_painted_hash = h
	update_configuration_warnings()
	return true


## A hash of the painted tiles on both layers, to notice painting
func painted_hash() -> int:
	return hash(
		[
			cells_layer.tile_map_data if cells_layer else PackedByteArray(),
			magic_layer.tile_map_data if magic_layer else PackedByteArray(),
		]
	)


## Writes the painted map into map_definition and saves it
func bake() -> Error:
	if map_definition == null or map_definition.resource_path == "":
		push_error("Set Map Definition to a saved HexMapDefinition before baking")
		update_configuration_warnings()
		return ERR_UNCONFIGURED
	return bake_into(map_definition, map_definition.resource_path)


## Writes the painted map (cells, magic nodes and their runes) into `target` and saves it to
## `path`. The map's name is kept.
func bake_into(target: HexMapDefinition, path: String) -> Error:
	var problem := check_cells()
	if problem != "":
		push_error("Can't bake %s: %s" % [name, problem])
		update_configuration_warnings()
		return ERR_INVALID_DATA
	var built := build_map()
	target.layout = built.layout
	target.magic_node_extra_cells = built.magic_node_extra_cells
	target.magic_edge_runes = built.magic_edge_runes
	target.magic_harvest_runes = built.magic_harvest_runes
	var err := ResourceSaver.save(target, path)
	if err != OK:
		push_error("Could not save %s (error %d)" % [path, err])
	else:
		print(
			(
				"Baked %s into %s: %d cells, %d magic nodes"
				% [name, path, target.get_cells().size(), target.get_magic_nodes().size()]
			)
		)
	target.emit_changed()
	update_configuration_warnings()
	return err


## Why the painted map can't be baked, or "" when it can
func check_cells() -> String:
	if cells_layer == null:
		return "Set Cells Layer to the TileMapLayer holding the painted cells"
	if magic_layer == null:
		return "Set Magic Layer to the TileMapLayer holding the magic node tiles"
	for layer: TileMapLayer in [cells_layer, magic_layer]:
		var tiles_err := _check_tile_set(layer)
		if tiles_err != "":
			return tiles_err
	var cells_err := _check_cells_layer()
	return cells_err if cells_err != "" else _check_magic_nodes()


## Whether the tile at `cell` (offset) on `layer` is a magic node tile
func is_magic_tile(layer: TileMapLayer, cell: Vector2i) -> bool:
	if not scene_tile_info(layer, cell).is_empty():
		return true
	var data := layer.get_cell_tile_data(cell)
	return data != null and data.get_custom_data(MAGIC_NODE_DATA) == true


## The cells (offset) the magic node painted at `cell` takes: its own cell first, then the extra
## cells of a scene tile
func magic_node_cells(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [cell]
	var info := scene_tile_info(magic_layer, cell)
	var own := Hex.offset_to_axial(cell.x, cell.y)
	for step: Vector2i in info.get("extra_cells", []):
		out.append(Hex.axial_to_offset(own + step))
	return out


## The runes of the magic node painted at `cell`: [edge runes, harvest runes]
func magic_node_runes(cell: Vector2i) -> Array[RuneSet]:
	var info := scene_tile_info(magic_layer, cell)
	if not info.is_empty():
		return [RuneSet.copy_of(info.edge_runes), RuneSet.copy_of(info.harvest_runes)]
	var data := magic_layer.get_cell_tile_data(cell)
	var edge: RuneSet = data.get_custom_data(EDGE_RUNES_DATA) as RuneSet if data else null
	var harvest: RuneSet = data.get_custom_data(HARVEST_RUNES_DATA) as RuneSet if data else null
	return [RuneSet.copy_of(edge), RuneSet.copy_of(harvest)]


## What the MagicNodeTile scene painted at `cell` (offset) on `layer` holds:
## {edge_runes, harvest_runes, extra_cells}, or {} when that isn't a magic node scene tile
static func scene_tile_info(layer: TileMapLayer, cell: Vector2i) -> Dictionary:
	var id := layer.get_cell_source_id(cell)
	if id == -1 or layer.tile_set == null or not layer.tile_set.has_source(id):
		return {}
	var source := layer.tile_set.get_source(id) as TileSetScenesCollectionSource
	var alternative := layer.get_cell_alternative_tile(cell)
	if source == null or not source.has_scene_tile_id(alternative):
		return {}
	var packed := source.get_scene_tile_scene(alternative)
	if packed == null:
		return {}
	var root := packed.instantiate()
	var info := {}
	if root is MagicNodeTile:
		var tile := root as MagicNodeTile
		info = {
			"edge_runes": tile.edge_runes,
			"harvest_runes": tile.harvest_runes,
			"extra_cells": tile.extra_cells.duplicate(),
		}
	root.free()
	return info


## The magic nodes' own cells (offset) in reading order: top row first, left to right
func magic_node_anchors() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(magic_layer.get_used_cells())
	out.sort_custom(_reading_order)
	return out


## The painted map as an unsaved HexMapDefinition (call when check_cells() is "")
func build_map() -> HexMapDefinition:
	var map := HexMapDefinition.new()
	map.map_name = map_definition.map_name if map_definition else ""
	var cells: Array[Vector2i] = []
	for c in cells_layer.get_used_cells():
		cells.append(Hex.offset_to_axial(c.x, c.y))
	var magic: Array[Vector2i] = []
	var edge: Array[RuneSet] = []
	var harvest: Array[RuneSet] = []
	var extra: Dictionary[Vector2i, Vector2i] = {}
	for c in magic_node_anchors():
		var a := Hex.offset_to_axial(c.x, c.y)
		magic.append(a)
		var runes := magic_node_runes(c)
		edge.append(runes[0])
		harvest.append(runes[1])
		for o in magic_node_cells(c).slice(1):
			extra[Hex.offset_to_axial(o.x, o.y)] = a
	map.layout = HexMapDefinition.layout_from_cells(cells, magic)
	map.magic_node_extra_cells = extra
	map.magic_edge_runes = edge
	map.magic_harvest_runes = harvest
	return map


## The layout rows the painted cells bake to
func build_layout() -> PackedStringArray:
	return build_map().layout


## Whether map_definition already holds exactly the painted map
func is_baked() -> bool:
	return (
		map_definition != null
		and check_cells() == ""
		and map_signature(map_definition) == map_signature(build_map())
	)


## A text form of a map's baked fields (not its name), equal for equal maps
static func map_signature(map: HexMapDefinition) -> String:
	var edge := []
	for r in map.magic_edge_runes:
		edge.append(RuneSet.copy_of(r).to_array())
	var harvest := []
	for r in map.magic_harvest_runes:
		harvest.append(RuneSet.copy_of(r).to_array())
	var extra := []
	for c in map.magic_node_extra_cells:
		extra.append([c, map.magic_node_extra_cells[c]])
	extra.sort()
	return var_to_str([map.layout, edge, harvest, extra])


## What's wrong with the scene, shown as warnings in the editor's scene tree
func get_problems() -> PackedStringArray:
	var out := PackedStringArray()
	if map_definition == null:
		out.append("Set Map Definition to the HexMapDefinition this map bakes into")
	var problem := check_cells()
	if problem != "":
		out.append(problem)
	elif map_definition and not is_baked():
		out.append("Not baked: the painted map differs from the map definition. Press Bake.")
	return out


func _get_configuration_warnings() -> PackedStringArray:
	return get_problems()


func _check_cells_layer() -> String:
	var used := cells_layer.get_used_cells()
	if used.is_empty():
		return "No cells painted yet"
	for c in used:
		if c.x < 0 or c.y < 0:
			return "A cell at %s is left of column 0 or above row 0" % c
		if is_magic_tile(cells_layer, c):
			return (
				"The magic node tile at %s is on the Cells layer: paint it on the Magic nodes layer"
				% c
			)
	return ""


func _check_magic_nodes() -> String:
	var covered := {}  ## offset cell -> true, every cell a magic node takes
	for c in magic_node_anchors():
		if not is_magic_tile(magic_layer, c):
			return "The tile at %s on the Magic nodes layer isn't a magic node tile" % c
		for o in magic_node_cells(c):
			if cells_layer.get_cell_source_id(o) == -1:
				return "The magic node at %s isn't on a cell: paint a cell under it" % c
			if covered.has(o):
				return "Two magic nodes cover the cell at %s" % o
			covered[o] = true
	return ""


func _check_tile_set(layer: TileMapLayer) -> String:
	var tiles := layer.tile_set
	if tiles == null:
		return "The %s layer has no tile set" % layer.name
	if (
		tiles.tile_shape != TileSet.TILE_SHAPE_HEXAGON
		or tiles.tile_layout != TileSet.TILE_LAYOUT_STACKED
		or tiles.tile_offset_axis != TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	):
		return "The tile set has to be hexagon, stacked, horizontal offset (use hex_map_tiles.tres)"
	for data_name: String in [MAGIC_NODE_DATA, EDGE_RUNES_DATA, HARVEST_RUNES_DATA]:
		if tiles.get_custom_data_layer_by_name(data_name) == -1:
			return 'The tile set needs a custom data layer named "%s"' % data_name
	return ""


static func _reading_order(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
