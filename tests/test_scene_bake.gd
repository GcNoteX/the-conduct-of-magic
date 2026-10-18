# gdlint: disable=max-public-methods
# One test function per check group, so the suite keeps many public functions.
extends Node

"""
Headless checks for the authoring scenes: each demo scene bakes to the resource the game ships.
Run: godot --headless --path . res://tests/test_scene_bake.tscn
Exits with code 1 if any check fails. Bakes go to user://, never over the shipped files.
"""

const TILES := preload("res://inscribing/tiles/hex_map_tiles.tres")
## The demo swords, smallest first. Each has a map scene and the map resource it bakes to.
const SWORDS := ["dagger", "short_sword", "long_sword"]
const SWORD_MAP := preload("res://inscribing/demo/long_sword_map.tres")
const CARVED := preload("res://inscribing/demo/carved_demo_sword.tres")
const DEMO_SETUP := preload("res://inscribing/demo/demo_setup.tres")
const TABLE := preload("res://inscribing/inscribing_table.tscn")
const ENCHANTMENTS := ["kindle", "glow", "keen", "ward", "bastion"]
const CELL_SOURCE := 0
const MAGIC_SOURCE := 1
const CELL_TILE := Vector2i(0, 0)
## Magic node tiles by rune kind, in RuneSet.Rune order
const WATER_TILE := Vector2i(0, 0)
const FIRE_TILE := Vector2i(1, 0)
const STONE_TILE := Vector2i(3, 0)
const SCENE_SOURCE := 2
## The Ember Well scene tile's id in the scenes source
const EMBER_WELL := 1

var _failures := 0
var _checks := 0


## Collects the script and engine errors raised while it's added, so a test can fail on them
class ErrorCatcher:
	extends Logger

	var errors: Array[String] = []

	func _log_error(
		_function: String,
		_file: String,
		_line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		_error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		errors.append("%s %s" % [code, rationale])


func _ready() -> void:
	test_tile_layout_matches_hex()
	test_layout_round_trip()
	test_demo_swords_are_clean()
	test_map_scene_bake()
	test_map_scene_warnings()
	test_enchantment_scenes_bake()
	test_enchantment_scene_snapping()
	test_enchantment_scene_warnings()
	test_enchantment_scene_lines()
	test_enchantment_scene_extra_cells()
	test_enchantment_scene_ports()
	test_bake_reads_tile_runes()
	test_magic_node_tiles()
	test_magic_node_scene_tile()
	await test_painted_map_runs_on_the_table()
	await test_empty_map_runs_on_the_table()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func new_map_scene(file := "long_sword") -> ItemMapScene:
	var packed: PackedScene = load("res://inscribing/demo/%s_map.tscn" % file)
	var scene: ItemMapScene = packed.instantiate()
	add_child(scene)
	return scene


func shipped_map(file: String) -> HexMapDefinition:
	return load("res://inscribing/demo/%s_map.tres" % file)


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
	for file: String in SWORDS:
		var map := shipped_map(file)
		check(
			(
				HexMapDefinition.layout_from_cells(map.get_cells(), map.get_magic_nodes())
				== map.layout
			),
			"layout_from_cells rebuilds the %s layout" % file
		)
	var empty: Array[Vector2i] = []
	check(HexMapDefinition.layout_from_cells(empty, empty).is_empty(), "no cells, no rows")


## Every demo sword is a clean silhouette: each row is one unbroken run of cells, centred on the
## same middle, so it's symmetric with no chipped edges. Each is smaller than the old 9x19 sword,
## each is bigger than the one before, and every demo enchantment fits on the largest.
func test_demo_swords_are_clean() -> void:
	var last_cells := 0
	for file: String in SWORDS:
		var map := shipped_map(file)
		var middle := -1.0
		var clean := true
		for row in map.layout.size():
			var line := map.layout[row].replace("M", "#")
			var first := line.find("#")
			var count := line.count("#")
			clean = clean and count > 0 and line.substr(first, count) == "#".repeat(count)
			var row_middle := first + count / 2.0 + (0.5 if row % 2 == 1 else 0.0)
			if middle < 0.0:
				middle = row_middle
			clean = clean and is_equal_approx(row_middle, middle)
		check(clean, "the %s is symmetric with unbroken rows" % file)
		check(
			map.layout.size() < 19 and map.get_cells().size() > last_cells,
			"the %s is smaller than the old sword and bigger than the last" % file
		)
		var magic := map.get_magic_nodes().size()
		check(magic >= 6 and magic <= 10, "the %s has 6 to 10 magic nodes" % file)
		check(
			map.magic_edge_runes.size() == magic and map.magic_harvest_runes.size() == magic,
			"every magic node on the %s has runes" % file
		)
		last_cells = map.get_cells().size()
	var item := EnchantableItemDefinition.new()
	item.map_template = SWORD_MAP
	var inst := ItemInstance.new()
	inst.definition = item
	var b := InscriptionBoard.new(inst, Player.new())
	for e: Enchantment in DEMO_SETUP.enchantments:
		var fits := false
		for c in b.get_cells():
			for r in 6:
				fits = fits or b.check_place(e, c, r) == ""
		check(fits, "%s fits on the long sword" % e.enchantment_name)


func test_map_scene_bake() -> void:
	for file: String in SWORDS:
		var map := shipped_map(file)
		var scene := new_map_scene(file)
		check(scene.check_cells() == "", "%s scene has bakeable cells" % file)
		check(scene.build_layout() == map.layout, "%s scene bakes to the shipped layout" % file)
		check(scene.is_baked(), "%s scene counts as baked" % file)
		check(scene.get_problems().is_empty(), "no warnings on the baked %s" % file)
		scene.free()
	var scene := new_map_scene()
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
	var below := SWORD_MAP.layout.size()
	scene.cells_layer.set_cell(Vector2i(4, below), CELL_SOURCE, CELL_TILE)
	check(not scene.is_baked(), "a new painted cell makes the scene unbaked")
	check(
		Array(scene.get_problems()).any(func(w: String) -> bool: return w.begins_with("Not baked")),
		"the unbaked scene warns"
	)
	scene.magic_layer.set_cell(Vector2i(4, below), MAGIC_SOURCE, FIRE_TILE)
	check(scene.build_layout()[below] == "....M....", "a magic node tile bakes as M on a new row")
	scene.magic_layer.set_cell(Vector2i(4, below + 1), MAGIC_SOURCE, FIRE_TILE)
	check(
		(
			scene.check_cells()
			== "The magic node at (4, %d) isn't on a cell: paint a cell under it" % [below + 1]
		),
		"a magic node has to sit on a cell"
	)
	scene.magic_layer.erase_cell(Vector2i(4, below + 1))
	scene.magic_layer.set_cell(Vector2i(4, below), CELL_SOURCE, CELL_TILE)
	check(
		scene.check_cells().ends_with("on the Magic nodes layer isn't a magic node tile"),
		"a plain cell tile on the magic layer warns"
	)
	scene.magic_layer.erase_cell(Vector2i(4, below))
	scene.cells_layer.set_cell(Vector2i(4, below), MAGIC_SOURCE, FIRE_TILE)
	check(
		scene.check_cells().ends_with("paint it on the Magic nodes layer"),
		"a magic node tile on the cells layer warns"
	)
	scene.cells_layer.erase_cell(Vector2i(4, below))
	check(scene.is_baked(), "erasing the new tiles makes it baked again")
	scene.cells_layer.set_cell(Vector2i(-1, 3), CELL_SOURCE, CELL_TILE)
	check(scene.check_cells().begins_with("A cell at"), "cells left of column 0 can't bake")
	check(
		scene.bake_into(SWORD_MAP.duplicate(), "user://test_scene_bake/bad.tres") != OK,
		"an invalid map refuses to bake"
	)
	scene.magic_layer = null
	check(scene.check_cells().begins_with("Set Magic Layer"), "no magic layer, no bake")
	scene.cells_layer = null
	check(scene.check_cells() != "", "no layer, no bake")
	scene.free()


func new_enchantment_scene(file: String) -> EnchantmentScene:
	var packed: PackedScene = load("res://enchantments/scenes/%s.tscn" % file)
	var scene: EnchantmentScene = packed.instantiate()
	add_child(scene)
	return scene


func shipped(file: String) -> Enchantment:
	return load("res://enchantments/patterns/%s.tres" % file)


func test_enchantment_scenes_bake() -> void:
	for file: String in ENCHANTMENTS:
		var scene := new_enchantment_scene(file)
		var e := shipped(file)
		check(scene.check_shape() == "", "%s scene has a sound shape" % file)
		check(
			(
				EnchantmentScene.shape_signature(scene.build_enchantment())
				== EnchantmentScene.shape_signature(e)
			),
			"%s scene builds the shipped shape" % file
		)
		check(scene.is_baked(), "%s scene counts as baked" % file)
		check(scene.get_problems().is_empty(), "%s scene has no warnings" % file)
		var target: Enchantment = e.duplicate(true)
		target.nodes = [] as Array[EnchantmentPatternNode]
		target.lines = [] as Array[EnchantmentPatternLine]
		var path := "user://test_scene_bake/%s.tres" % file
		check(scene.bake_into(target, path) == OK, "%s bakes" % file)
		var saved: Enchantment = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		check(
			EnchantmentScene.shape_signature(saved) == EnchantmentScene.shape_signature(e),
			"%s's saved bake has the shipped shape" % file
		)
		check(
			(
				saved.enchantment_name == e.enchantment_name
				and saved.effect_description == e.effect_description
			),
			"%s's bake keeps its name and description" % file
		)
		check(InscriptionBoard.check_shape(e) == "", "shipped %s passes the shape check" % file)
		scene.free()


func test_enchantment_scene_snapping() -> void:
	var scene := new_enchantment_scene("kindle")
	var b: EnchantmentNodeComponent = scene.node_components()[1]
	b.position += Vector2(9, -7)
	scene.snap()
	check(b.position == Hex.to_pixel(Vector2i(2, 0), EnchantmentScene.HEX_SIZE), "nodes snap")
	b.position = Hex.to_pixel(Vector2i(2, -2), EnchantmentScene.HEX_SIZE) + Vector2(5, 5)
	scene.snap()
	var line: EnchantmentLineComponent = scene.line_components()[0]
	check(b.cell() == Vector2i(2, -2), "a moved node lands on its new cell")
	check(line.points[line.points.size() - 1] == b.position, "the line's end follows its node")
	check(line.middle_cells() == ([Vector2i(1, -1)] as Array[Vector2i]), "the line reroutes")
	check(not scene.is_baked(), "a moved node makes the scene unbaked")
	check(
		Array(scene.get_problems()).any(func(w: String) -> bool: return w.begins_with("Not baked")),
		"the unbaked scene warns"
	)
	scene.free()


func test_enchantment_scene_warnings() -> void:
	var scene := new_enchantment_scene("ward")
	var nodes := scene.node_components()
	nodes[3].position = nodes[2].position
	scene.snap()
	check(scene.check_shape().begins_with("Node 3 overlaps node 2"), "nodes on one cell warn")
	check(scene.overlapping_cells().has(nodes[2].cell()), "the overlap is drawn")
	var target: Enchantment = shipped("ward").duplicate(true)
	check(
		scene.bake_into(target, "user://test_scene_bake/bad.tres") != OK,
		"an invalid shape refuses to bake"
	)
	scene.free()
	scene = new_enchantment_scene("keen")
	nodes = scene.node_components()
	nodes[2].position = Hex.to_pixel(Vector2i(-2, 0), EnchantmentScene.HEX_SIZE)
	scene.snap()
	check(scene.check_shape() == "Line 1: it runs over line 0", "lines can't cross")
	scene.free()
	scene = new_enchantment_scene("kindle")
	nodes = scene.node_components()
	nodes[1].position = Hex.to_pixel(Vector2i(1, 0), EnchantmentScene.HEX_SIZE)
	scene.snap()
	check(scene.check_shape() == "", "neighbouring nodes join with no cells between")
	var line: EnchantmentLineComponent = scene.line_components()[0]
	line.to_node = null
	check(scene.check_shape().begins_with("LineAB"), "a line without both nodes warns")
	scene.free()


func test_enchantment_scene_lines() -> void:
	var scene := new_enchantment_scene("kindle")
	var line: EnchantmentLineComponent = scene.line_components()[0]
	var bend := Hex.to_pixel(Vector2i(1, -1), EnchantmentScene.HEX_SIZE) + Vector2(4, -3)
	line.points = PackedVector2Array([line.points[0], bend, line.points[1]])
	scene.snap()
	check(
		line.points[1] == Hex.to_pixel(Vector2i(1, -1), EnchantmentScene.HEX_SIZE),
		"bend points snap to cell centres"
	)
	var path := line.path_cells()
	var joined := path.size() > 2
	for i in range(1, path.size()):
		joined = joined and Hex.distance(path[i - 1], path[i]) == 1
	check(joined and Vector2i(1, -1) in path, "a bent line runs cell by cell through its bend")
	check(scene.check_shape() == "", "a bent line is a sound shape")
	var built := scene.build_enchantment()
	check(built.lines[0].cells == line.middle_cells(), "the bent line's cells bake")
	scene.free()


func test_enchantment_scene_extra_cells() -> void:
	var scene := new_enchantment_scene("kindle")
	var b: EnchantmentNodeComponent = scene.node_components()[1]
	b.extra_cells = [Vector2i(1, 0), Vector2i(0, 1)] as Array[Vector2i]
	check(scene.check_shape() == "", "a node can cover extra cells")
	var built := scene.build_enchantment()
	check(built.nodes[1].extra_cells == b.extra_cells, "extra cells bake relative to their node")
	check(b.covered_cells().has(Vector2i(3, 0)), "a node covers its extra cells")
	b.extra_cells = [Vector2i(-1, 0)] as Array[Vector2i]
	check(
		scene.check_shape() == "Line 0: it runs over node 1",
		"an extra cell can't sit on the node's own line"
	)
	check(scene.overlapping_cells().has(Vector2i(1, 0)), "the extra cell overlap is drawn")
	scene.free()


## Bastion's lines end on the big node's ports, which bake with it
func test_enchantment_scene_ports() -> void:
	var scene := new_enchantment_scene("bastion")
	var big: EnchantmentNodeComponent = scene.node_components()[0]
	var right: EnchantmentLineComponent = scene.line_components()[1]
	check(big.port_cell(1) == Vector2i(1, 1), "port 1 is the big node's bottom right cell")
	check(right.points[0] == big.port_position(1), "a line snaps to its port")
	check(right.path_cells()[0] == Vector2i(1, 1), "and runs from it")
	var built := scene.build_enchantment()
	check(built.nodes[0].ports == big.ports and built.lines[1].from_port == 1, "ports bake")
	right.from_port = 3
	check(
		scene.check_shape() == "LineRight: BigNode has no port 3 (set From Port)",
		"a line naming a missing port warns"
	)
	right.from_port = 1
	big.ports = [Vector2i(0, 0), Vector2i(2, 2)] as Array[Vector2i]
	check(
		scene.check_shape() == "Node 0: its port (2, 2) isn't one of its cells",
		"a port off the node warns"
	)
	scene.free()


## Paints over the long sword: a plain cell and a new stone magic node under the bottom row, and
## the first magic node turned into a water node. Returns the scene, not yet baked.
func paint_over_sword() -> ItemMapScene:
	var scene := new_map_scene()
	var bottom := Vector2i(-1, -1)
	for c in scene.cells_layer.get_used_cells():
		if c.y > bottom.y:
			bottom = c
	scene.cells_layer.set_cell(bottom + Vector2i(0, 1), CELL_SOURCE, CELL_TILE)
	scene.cells_layer.set_cell(bottom + Vector2i(0, 2), CELL_SOURCE, CELL_TILE)
	scene.magic_layer.set_cell(bottom + Vector2i(0, 2), MAGIC_SOURCE, STONE_TILE)
	scene.magic_layer.set_cell(scene.magic_node_anchors()[0], MAGIC_SOURCE, WATER_TILE)
	return scene


## Baking takes each magic node's runes from its tile: the swords' magic nodes give the placeholder
## runes (1 of its kind on each line; 1 of its kind and 1 of the next kind back)
func test_magic_node_tiles() -> void:
	var kinds := ["water", "fire", "wind", "stone"]
	var tiles := TILES.get_source(MAGIC_SOURCE) as TileSetAtlasSource
	check(tiles.get_tiles_count() == 4, "one magic node tile per rune kind")
	for k in 4:
		var data := tiles.get_tile_data(Vector2i(k, 0), 0)
		var edge: RuneSet = data.get_custom_data(ItemMapScene.EDGE_RUNES_DATA)
		var harvest: RuneSet = data.get_custom_data(ItemMapScene.HARVEST_RUNES_DATA)
		var one := [0, 0, 0, 0]
		one[k] = 1
		var back := one.duplicate()
		back[(k + 1) % 4] += 1
		check(
			edge.to_array() == one and harvest.to_array() == back,
			"the %s tile puts 1 %s on its lines and gives back %s" % [kinds[k], kinds[k], back]
		)
		check(
			data.get_custom_data(ItemMapScene.MAGIC_NODE_DATA),
			"the %s tile is a magic node" % kinds[k]
		)
	for file: String in SWORDS:
		var scene := new_map_scene(file)
		var map := shipped_map(file)
		var built := scene.build_map()
		var same := built.magic_edge_runes.size() == map.magic_edge_runes.size()
		for i in mini(built.magic_edge_runes.size(), map.magic_edge_runes.size()):
			same = same and built.magic_edge_runes[i].equals(map.magic_edge_runes[i])
			same = same and built.magic_harvest_runes[i].equals(map.magic_harvest_runes[i])
		check(same, "the %s's magic node tiles bake to its shipped runes" % file)
		scene.free()


## The Ember Well is a 2-cell fire magic node scene tile on the short sword: Bake reads its runes
## and extra cell from the MagicNodeTile at the scene's root
func test_magic_node_scene_tile() -> void:
	var well: MagicNodeTile = load("res://items/maps/magic_nodes/ember_well.tscn").instantiate()
	check(well.edge_runes.equals(RuneSet.of(0, 1, 0, 0)), "the Ember Well puts 1 fire on its lines")
	check(well.harvest_runes.equals(RuneSet.of(0, 1, 1, 0)), "and gives back 1 fire and 1 wind")
	check(well.extra_cells == ([Vector2i(1, 0)] as Array[Vector2i]), "and covers the next cell")
	well.free()
	var scene := new_map_scene("short_sword")
	var at := Vector2i(0, 12)
	check(scene.magic_layer.get_cell_source_id(at) == SCENE_SOURCE, "the short sword has the well")
	check(scene.is_magic_tile(scene.magic_layer, at), "a MagicNodeTile scene tile is a magic node")
	check(
		scene.magic_node_cells(at) == ([at, Vector2i(1, 12)] as Array[Vector2i]),
		"the well covers its own cell and the one to its right"
	)
	var map := shipped_map("short_sword")
	var own := Hex.offset_to_axial(0, 12)
	check(
		map.magic_node_extra_cells == {own + Vector2i(1, 0): own},
		"the baked short sword knows the well's extra cell"
	)
	check(map.edge_runes_at(own).equals(RuneSet.of(0, 1, 0, 0)), "the baked well has its runes")
	check(map.magic_extra_cells(own) == ([own + Vector2i(1, 0)] as Array[Vector2i]), "lookup")
	scene.magic_layer.set_cell(Vector2i(1, 11), MAGIC_SOURCE, FIRE_TILE)
	scene.magic_layer.set_cell(Vector2i(0, 11), SCENE_SOURCE, Vector2i.ZERO, EMBER_WELL)
	check(
		scene.check_cells() == "Two magic nodes cover the cell at (1, 11)",
		"a well's extra cell can't sit on another magic node"
	)
	scene.magic_layer.erase_cell(Vector2i(1, 11))
	scene.magic_layer.erase_cell(Vector2i(0, 11))
	scene.magic_layer.set_cell(Vector2i(5, 11), SCENE_SOURCE, Vector2i.ZERO, EMBER_WELL)
	check(
		scene.check_cells() == "The magic node at (5, 11) isn't on a cell: paint a cell under it",
		"every cell a bigger magic node covers has to be on a cell"
	)
	scene.free()


## Baking a repainted map writes the runes of the tiles now painted, in reading order
func test_bake_reads_tile_runes() -> void:
	var scene := paint_over_sword()
	check(scene.refresh_if_painted(), "painting is noticed, so the warnings refresh")
	check(not scene.refresh_if_painted(), "and only once per change")
	check(not scene.is_baked(), "the painted sword is not baked yet")
	var path := "user://test_scene_bake/painted_map.tres"
	ResourceSaver.save(SWORD_MAP.duplicate(true), path)
	scene.map_definition = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	check(not scene.get_problems().is_empty(), "the painted sword warns before baking")
	check(scene.bake() == OK, "the painted sword bakes")
	check(scene.get_problems().is_empty(), "and its warning clears once baked")
	var saved: HexMapDefinition = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var nodes := saved.get_magic_nodes()
	check(nodes.size() == SWORD_MAP.get_magic_nodes().size() + 1, "one new magic node")
	check(
		(
			saved.magic_edge_runes.size() == nodes.size()
			and saved.magic_harvest_runes.size() == nodes.size()
		),
		"the rune lists match the magic nodes"
	)
	check(
		saved.edge_runes_at(nodes[0]).equals(RuneSet.of(1, 0, 0, 0)), "the repainted node is water"
	)
	check(
		saved.harvest_runes_at(nodes[0]).equals(RuneSet.of(1, 1, 0, 0)),
		"and gives back water and fire"
	)
	check(saved.edge_runes_at(nodes.back()).equals(RuneSet.of(0, 0, 0, 1)), "the new node is stone")
	var kept := true
	for i in range(1, SWORD_MAP.get_magic_nodes().size()):
		kept = kept and saved.edge_runes_at(nodes[i]).equals(SWORD_MAP.edge_runes_at(nodes[i]))
	check(kept, "the other magic nodes keep their tiles' runes")
	check(saved.map_name == SWORD_MAP.map_name, "bake keeps the map's name")
	scene.free()


## Opens every item on the table (carving and disenchanting, hovering every node) for a few frames
## and returns the errors raised
func run_table(map: HexMapDefinition) -> Array[String]:
	var item := EnchantableItemDefinition.new()
	item.id = &"painted_sword"
	item.display_name = "Painted sword"
	item.map_template = map
	var carved: ItemInstance = CARVED.duplicate(true)
	carved.definition = item
	var setup := DemoSetup.new()
	setup.materials = DEMO_SETUP.materials
	setup.items = [item] as Array[EnchantableItemDefinition]
	setup.carved_items = [carved] as Array[ItemInstance]
	setup.enchantments = DEMO_SETUP.enchantments
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)
	var table: Control = TABLE.instantiate()
	table.setup = setup
	add_child(table)
	for i in table.player.items.size():
		table._open_item(i)
		await get_tree().process_frame
		for on in [true, false]:
			table._set_disenchanting(on)
			for k: String in table.board.get_node_keys():
				table._on_hovered(k)
			await get_tree().process_frame
	OS.remove_logger(catcher)
	table.free()
	return catcher.errors


func test_painted_map_runs_on_the_table() -> void:
	var scene := paint_over_sword()
	var path := "user://test_scene_bake/painted_run.tres"
	scene.bake_into(SWORD_MAP.duplicate(true), path)
	scene.free()
	var map: HexMapDefinition = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var errors := await run_table(map)
	check(errors.is_empty(), "the painted, baked sword runs on the table: %s" % [errors])


## A map with no cells (a definition never baked) shows an empty board instead of failing
func test_empty_map_runs_on_the_table() -> void:
	var errors := await run_table(HexMapDefinition.new())
	check(errors.is_empty(), "a map with no cells runs on the table: %s" % [errors])
