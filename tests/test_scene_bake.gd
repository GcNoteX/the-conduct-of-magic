extends Node

"""
Headless checks for the authoring scenes: each demo scene bakes to the resource the game ships.
Run: godot --headless --path . res://tests/test_scene_bake.tscn
Exits with code 1 if any check fails. Bakes go to user://, never over the shipped files.
"""

const TILES := preload("res://inscribing/tiles/hex_map_tiles.tres")
const SWORD_MAP := preload("res://inscribing/demo/demo_sword_map.tres")
const SWORD_MAP_SCENE := preload("res://inscribing/demo/demo_sword_map.tscn")
const CELL_TILE := Vector2i(0, 0)
const MAGIC_TILE := Vector2i(1, 0)

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_tile_layout_matches_hex()
	test_layout_round_trip()
	test_map_scene_bake()
	test_map_scene_warnings()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func new_map_scene() -> ItemMapScene:
	var scene: ItemMapScene = SWORD_MAP_SCENE.instantiate()
	add_child(scene)
	return scene


## A painted tile at (col, row) has to be the game's cell at odd-r offset (col, row)
func test_tile_layout_matches_hex() -> void:
	var layer := TileMapLayer.new()
	layer.tile_set = TILES
	add_child(layer)
	var size := float(TILES.tile_size.y) / 2.0
	var origin := layer.map_to_local(Vector2i.ZERO)
	var same_places := true
	var same_neighbours := true
	for row in range(-3, 4):
		for col in range(-3, 4):
			var tile := Vector2i(col, row)
			var a := Hex.offset_to_axial(col, row)
			var expected := Hex.to_pixel(a, size)
			var got := layer.map_to_local(tile) - origin
			# The tile set's width is rounded to whole pixels, so allow a little stretch
			same_places = same_places and absf(got.y - expected.y) < 0.01
			same_places = same_places and absf(got.x - expected.x) <= absf(expected.x) * 0.02 + 0.01
			var theirs := {}
			for n in layer.get_surrounding_cells(tile):
				theirs[n] = true
			var ours := {}
			for n in Hex.neighbours(a):
				ours[Hex.axial_to_offset(n)] = true
			same_neighbours = same_neighbours and theirs == ours
	check(same_places, "tile positions match the board's odd-r hex positions")
	check(same_neighbours, "tile neighbours match the board's hex neighbours")
	layer.free()


func test_layout_round_trip() -> void:
	check(
		(
			HexMapDefinition.layout_from_cells(SWORD_MAP.get_cells(), SWORD_MAP.get_magic_nodes())
			== SWORD_MAP.layout
		),
		"layout_from_cells rebuilds the demo sword layout"
	)
	var empty: Array[Vector2i] = []
	check(HexMapDefinition.layout_from_cells(empty, empty).is_empty(), "no cells, no rows")


func test_map_scene_bake() -> void:
	var scene := new_map_scene()
	check(scene.check_cells() == "", "demo sword scene has bakeable cells")
	check(scene.build_layout() == SWORD_MAP.layout, "demo sword scene bakes to the shipped layout")
	check(scene.is_baked(), "demo sword scene counts as baked")
	var target: HexMapDefinition = SWORD_MAP.duplicate()
	target.layout = PackedStringArray()
	var path := "user://test_scene_bake/sword_map.tres"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	check(scene.bake_into(target, path) == OK, "bake saves")
	var saved: HexMapDefinition = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	check(saved.layout == SWORD_MAP.layout, "the saved bake has the shipped layout")
	check(saved.map_name == SWORD_MAP.map_name, "bake keeps the map's other fields")
	check(saved.get_magic_nodes().size() == 10, "the saved bake has the 10 magic nodes")
	scene.free()


func test_map_scene_warnings() -> void:
	var scene := new_map_scene()
	check(scene.get_problems().is_empty(), "no warnings on the baked demo sword")
	scene.cells_layer.set_cell(Vector2i(4, 19), 0, CELL_TILE)
	check(not scene.is_baked(), "a new painted cell makes the scene unbaked")
	check(
		Array(scene.get_problems()).any(func(w: String) -> bool: return w.begins_with("Not baked")),
		"the unbaked scene warns"
	)
	scene.cells_layer.set_cell(Vector2i(4, 19), 0, MAGIC_TILE)
	check(scene.build_layout()[19] == "....M....", "magic node tile bakes as M on a new row")
	scene.cells_layer.erase_cell(Vector2i(4, 19))
	check(scene.is_baked(), "erasing the cell makes it baked again")
	scene.cells_layer.set_cell(Vector2i(-1, 3), 0, CELL_TILE)
	check(scene.check_cells().begins_with("A cell at"), "cells left of column 0 can't bake")
	check(
		scene.bake_into(SWORD_MAP.duplicate(), "user://test_scene_bake/bad.tres") != OK,
		"an invalid map refuses to bake"
	)
	scene.cells_layer = null
	check(scene.check_cells() != "", "no layer, no bake")
	scene.free()
