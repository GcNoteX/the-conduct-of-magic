extends Node

"""
Regenerates the placeholder content for the first inscribing build.
Run: godot --headless --path . res://tools/build_demo_content.tscn
Editing the generated .tres files in the editor is fine; rerunning this overwrites them.
"""

const STONES := "res://items/enchantment_materials/%s/%s.tres"
## Placeholder icons from tools/placeholder_art/make_workshop_art.py, by file name
const STONE_ART := "res://art/placeholder/stones/%s.png"
const ITEM_ART := "res://art/placeholder/items/%s.png"
const A := EnchantmentMaterialDefinition.MATERIAL_ATTRIBUTES
const TILES := preload("res://inscribing/tiles/hex_map_tiles.tres")
## The tile set's sources: plain cells, and magic nodes (one tile per rune kind, in RuneSet.Rune
## order, each carrying its runes as custom data)
const CELL_SOURCE := 0
const MAGIC_SOURCE := 1
const SCENE_SOURCE := 2
const CELL_TILE := Vector2i(0, 0)
## The Ember Well, the example magic node scene tile (items/maps/magic_nodes/ember_well.tscn)
const EMBER_WELL_TILE := 1
## Placeholder magic node kinds, to tune: the magic nodes of each sword in reading order get
## these tiles in turn. A magic node tile puts 1 rune of its kind on each line and gives back 1 of
## its kind and 1 of the next kind when freed (see hex_map_tiles.tres).
const MAGIC_KINDS: Array[RuneSet.Rune] = [
	RuneSet.Rune.WIND,
	RuneSet.Rune.WATER,
	RuneSet.Rune.FIRE,
	RuneSet.Rune.STONE,
	RuneSet.Rune.FIRE,
	RuneSet.Rune.WATER,
	RuneSet.Rune.STONE,
	RuneSet.Rune.WIND,
	RuneSet.Rune.STONE,
	RuneSet.Rune.WATER,
]


func _ready() -> void:
	var fire := _stone("fire_stone", "Fire stone", Color("e8642c"), 1, [A.Flame], [_lines(2)])
	var water := _stone(
		"water_stone", "Water stone", Color("3c8de0"), 1, [A.Water], [_connections(2)]
	)
	var red := _stone("red_stone", "Red stone", Color("c8324b"), 1, [A.Soft, A.Shiny], [_lines(2)])
	var blue := _stone("blue_stone", "Blue stone", Color("4b5fc8"), 1, [A.Hard], [_lines(1)])
	var yellow := _stone(
		"yellow_stone",
		"Yellow stone",
		Color("e6c235"),
		2,
		[A.Shiny, A.Hard],
		[InstantPassCondition.new()]
	)
	# Placeholder rune numbers, to tune. Each stone's runes are its own kind.
	_runes(fire, RuneSet.of(0, 1, 0, 0), RuneSet.of(0, 2, 0, 0), RuneSet.of(0, 3, 0, 0))
	_runes(water, RuneSet.of(1, 0, 0, 0), RuneSet.of(2, 0, 0, 0), RuneSet.of(3, 0, 0, 0))
	_runes(red, RuneSet.of(0, 0, 1, 0), RuneSet.of(0, 0, 2, 0), RuneSet.of(0, 1, 2, 0))
	_runes(blue, RuneSet.of(0, 0, 0, 1), RuneSet.of(0, 0, 0, 2), RuneSet.of(0, 0, 0, 3))
	_runes(yellow, RuneSet.of(0, 0, 1, 0), RuneSet.of(0, 0, 2, 0), RuneSet.of(1, 0, 2, 1))

	# Nodes are spaced out so each fixed line runs through cells, like a drawn line
	var kindle := _pattern(
		"kindle",
		"Kindle",
		"Warm to the touch",
		[_node(Vector2i(0, 0), 1, [A.Flame]), _node(Vector2i(2, 0))],
		[_line(0, 1, [Vector2i(1, 0)])]
	)
	var glow := _pattern(
		"glow",
		"Glow",
		"Gives off a soft light",
		[_node(Vector2i(0, 0)), _node(Vector2i(2, 0)), _node(Vector2i(0, 2), 2, [A.Shiny])],
		[
			_line(0, 1, [Vector2i(1, 0)]),
			_line(1, 2, [Vector2i(1, 1)]),
			_line(2, 0, [Vector2i(0, 1)]),
		]
	)
	var keen := _pattern(
		"keen",
		"Keen",
		"Cuts noticeably better",
		[
			_node(Vector2i(0, 0), 1, [A.Soft]),
			_node(Vector2i(2, 0), 1, [A.Hard]),
			_node(Vector2i(4, 0), 1, [A.Soft])
		],
		[_line(0, 1, [Vector2i(1, 0)]), _line(1, 2, [Vector2i(3, 0)])]
	)
	var ward := _pattern(
		"ward",
		"Ward",
		"Shrugs off rust and water",
		[
			_node(Vector2i(0, 0), 1, [A.Water]),
			_node(Vector2i(2, 0), 1, [A.Hard]),
			_node(Vector2i(0, 2), 1, [A.Hard]),
			_node(Vector2i(2, 2), 1, [A.Water])
		],
		[
			_line(0, 1, [Vector2i(1, 0)]),
			_line(0, 2, [Vector2i(0, 1)]),
			_line(1, 3, [Vector2i(2, 1)]),
			_line(2, 3, [Vector2i(1, 2)]),
			_line(1, 2, [Vector2i(1, 1)]),
		]
	)

	# An example, not a real enchantment: one node covering 2x2 cells with two ports, joined twice
	# to its left node
	var bastion := _pattern(
		"bastion",
		"Bastion",
		"Example: a big node with two ports",
		[
			_node(
				Vector2i(0, 0),
				1,
				[],
				[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
				[Vector2i(0, 0), Vector2i(1, 1)]
			),
			_node(Vector2i(-2, 0)),
			_node(Vector2i(3, 1)),
		],
		[
			_line(1, 0, [Vector2i(-1, 0)]),
			_line(0, 2, [Vector2i(2, 1)], 1, 0),
			# A second line between the same two nodes, over the top: shapes may do that
			_line(1, 0, [Vector2i(-1, -1), Vector2i(0, -1)]),
		]
	)

	# Three swords of different sizes. Every row is centred, so the edges are clean and the
	# silhouette is symmetric: even rows have an odd number of cells and odd rows an even number.
	var dagger := _sword(
		"dagger",
		"Dagger",
		PackedStringArray(
			[
				"...#...",
				"..##...",
				"..#M#..",
				"..##...",
				"..#M#..",
				"..##...",
				"..#M#..",
				"######.",
				"M#####M",
				"..##...",
				"..#M#..",
			]
		)
	)
	var short_sword := _sword(
		"short_sword",
		"Short sword",
		PackedStringArray(
			[
				"...#...",
				"..##...",
				"..#M#..",
				"..##...",
				"..###..",
				"..##...",
				"..M#M..",
				"..##...",
				"..###..",
				"..##...",
				"..#M#..",
				"######.",
				"M#####M",
				"..##...",
				"..#M#..",
			]
		),
		{4: EMBER_WELL_TILE}
	)
	var long_sword := _sword(
		"long_sword",
		"Long sword",
		PackedStringArray(
			[
				"....#....",
				"...##....",
				"...#M#...",
				"..####...",
				"..#####..",
				"..####...",
				"..M###M..",
				"..####...",
				"..##M##..",
				"..####...",
				"..M###M..",
				"..####...",
				"..##M##..",
				".######..",
				"M#######M",
				"...##....",
				"...#M#...",
			]
		)
	)

	var carved := _carved_sword(long_sword, kindle, keen, [fire, water, red, blue])
	_save(carved, "res://inscribing/demo/carved_demo_sword.tres")

	var setup := DemoSetup.new()
	setup.materials = {fire: 3, water: 3, red: 3, blue: 3, yellow: 1}
	setup.items = [dagger, short_sword, long_sword]
	setup.carved_items = [load("res://inscribing/demo/carved_demo_sword.tres")]
	setup.enchantments = [kindle, glow, keen, ward, bastion]
	_save(setup, "res://inscribing/demo/demo_setup.tres")
	print("Demo content written")
	get_tree().quit()


func _stone(
	folder: String, display: String, color: Color, tier: int, attributes: Array, conditions: Array
) -> EnchantmentMaterialDefinition:
	var path := STONES % [folder, folder]
	var m: EnchantmentMaterialDefinition = load(path)
	m.id = StringName(folder)
	m.display_name = display
	m.color = color
	m.inventory_sprite_normal = load(STONE_ART % folder)
	m.tier = tier
	var attrs: Array[EnchantmentMaterialDefinition.MATERIAL_ATTRIBUTES] = []
	attrs.assign(attributes)
	m.material_attributes = attrs
	var conds: Array[EnchantmentCondition] = []
	conds.assign(conditions)
	m.activation_conditions = conds
	_save(m, path)
	return load(path)


## A long sword that arrives already carved, to practise disenchanting on: Kindle (fire, water)
## on the blade with a magic-to-magic chain, and Keen (red, blue, red) on the crossguard
func _carved_sword(
	sword: EnchantableItemDefinition, kindle: Enchantment, keen: Enchantment, stones: Array
) -> ItemInstance:
	var fire: EnchantmentMaterialDefinition = stones[0]
	var water: EnchantmentMaterialDefinition = stones[1]
	var red: EnchantmentMaterialDefinition = stones[2]
	var blue: EnchantmentMaterialDefinition = stones[3]
	var carver := Player.new()
	for m in stones:
		carver.add_material(m, 9)
	var inst := ItemInstance.new()
	inst.id = &"carved_demo_sword"
	inst.definition = sword
	var b := InscriptionBoard.new(inst, carver)
	var k := b.place(kindle, Vector2i(1, 5), 0)
	b.insert_material(InscriptionBoard.enchantment_key(k.id, 0), fire)
	b.insert_material(InscriptionBoard.enchantment_key(k.id, 1), water)
	_carve(b, [Vector2i(1, 5), Vector2i(0, 6), Vector2i(-1, 6)])
	_carve(b, [Vector2i(1, 5), Vector2i(1, 6), Vector2i(0, 7), Vector2i(0, 8)])
	_carve(b, [Vector2i(3, 5), Vector2i(3, 6)])
	_carve(b, [Vector2i(3, 6), Vector2i(2, 7), Vector2i(1, 8), Vector2i(0, 8)])
	var e := b.place(keen, Vector2i(-5, 13), 0)
	b.insert_material(InscriptionBoard.enchantment_key(e.id, 0), red)
	b.insert_material(InscriptionBoard.enchantment_key(e.id, 1), blue)
	b.insert_material(InscriptionBoard.enchantment_key(e.id, 2), red)
	_carve(b, [Vector2i(-5, 13), Vector2i(-6, 14), Vector2i(-7, 14)])
	_carve(b, [Vector2i(-5, 13), Vector2i(-4, 12), Vector2i(-3, 12), Vector2i(-2, 12)])
	_carve(b, [Vector2i(-3, 13), Vector2i(-3, 14), Vector2i(-3, 15), Vector2i(-4, 16)])
	_carve(b, [Vector2i(-1, 13), Vector2i(-1, 12), Vector2i(-2, 12)])
	_carve(b, [Vector2i(-1, 13), Vector2i(0, 13), Vector2i(0, 14), Vector2i(1, 14)])
	var done := b.commit()
	assert(done.size() == 2, "The carved demo sword didn't commit: " + b.check_commit())
	return inst


## Writes a sword's map scene (cells and magic node tiles painted from `layout`), bakes it into
## the sword's map, and writes the item definition. `scene_tiles` paints some magic nodes (by
## number in reading order, from 0) with a magic node scene tile instead: {number: scene tile id}.
func _sword(
	file: String, display: String, layout: PackedStringArray, scene_tiles := {}
) -> EnchantableItemDefinition:
	var map_path := "res://inscribing/demo/%s_map.tres" % file
	var map: HexMapDefinition = (
		load(map_path) if ResourceLoader.exists(map_path) else HexMapDefinition.new()
	)
	map.map_name = display
	map.layout = layout
	_map_scene(map, map_path, "res://inscribing/demo/%s_map.tscn" % file, scene_tiles)
	var item := EnchantableItemDefinition.new()
	item.id = StringName(file)
	item.display_name = display
	item.inventory_sprite_normal = load(ITEM_ART % file)
	item.map_template = load(map_path)
	var path := "res://inscribing/demo/%s.tres" % file
	_save(item, path)
	return load(path)


## Writes the scene a map is painted in, painted from the map's layout, and bakes it into the map
func _map_scene(
	map: HexMapDefinition, map_path: String, path: String, scene_tiles: Dictionary
) -> void:
	var root := ItemMapScene.new()
	root.name = path.get_file().get_basename().to_pascal_case()
	var cells := TileMapLayer.new()
	cells.name = "Cells"
	cells.tile_set = TILES
	root.add_child(cells)
	cells.owner = root
	var magic := TileMapLayer.new()
	magic.name = "MagicNodes"
	magic.tile_set = TILES
	root.add_child(magic)
	magic.owner = root
	for a in map.get_cells():
		cells.set_cell(Hex.axial_to_offset(a), CELL_SOURCE, CELL_TILE)
	var nodes := map.get_magic_nodes()
	for i in nodes.size():
		var at := Hex.axial_to_offset(nodes[i])
		if scene_tiles.has(i):
			magic.set_cell(at, SCENE_SOURCE, Vector2i.ZERO, scene_tiles[i])
		else:
			var kind := MAGIC_KINDS[i % MAGIC_KINDS.size()]
			magic.set_cell(at, MAGIC_SOURCE, Vector2i(kind, 0))
	root.map_definition = map
	root.cells_layer = cells
	root.magic_layer = magic
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var uid := (
		ResourceLoader.get_resource_uid(map_path)
		if ResourceLoader.exists(map_path)
		else ResourceUID.INVALID_ID
	)
	var err := root.bake_into(map, map_path)
	assert(err == OK and root.is_baked(), "The %s scene doesn't bake" % path)
	if uid != ResourceUID.INVALID_ID:
		ResourceSaver.set_uid(map_path, uid)
	var scene := PackedScene.new()
	scene.pack(root)
	_save(scene, path)
	root.free()


func _carve(b: InscriptionBoard, cells: Array) -> void:
	var path: Array[Vector2i] = []
	path.assign(cells)
	var err := b.check_line(path)
	assert(err == "", "Can't carve %s: %s" % [cells, err])
	b.add_line(path)


func _runes(
	m: EnchantmentMaterialDefinition, edge: RuneSet, harvest: RuneSet, dissolve: RuneSet
) -> void:
	m.edge_runes = edge
	m.harvest_runes = harvest
	m.dissolve_runes = dissolve
	_save(m, m.resource_path)


func _pattern(
	file: String, display: String, effect: String, nodes: Array, lines: Array
) -> Enchantment:
	var path := "res://enchantments/patterns/%s.tres" % file
	var e := Enchantment.new()
	e.enchantment_name = display
	e.effect_description = effect
	var n: Array[EnchantmentPatternNode] = []
	n.assign(nodes)
	e.nodes = n
	var l: Array[EnchantmentPatternLine] = []
	l.assign(lines)
	e.lines = l
	_save(e, path)
	return load(path)


func _line(
	from: int, to: int, cells: Array[Vector2i], from_port := 0, to_port := 0
) -> EnchantmentPatternLine:
	var l := EnchantmentPatternLine.new()
	l.from_node = from
	l.to_node = to
	l.from_port = from_port
	l.to_port = to_port
	l.cells = cells
	return l


func _node(
	offset: Vector2i, tier := 1, attributes: Array = [], extra: Array = [], ports: Array = []
) -> EnchantmentPatternNode:
	var n := EnchantmentPatternNode.new()
	n.offset = offset
	n.extra_cells.assign(extra)
	n.ports.assign(ports)
	n.tier_requirement = tier
	var reqs: Array[MaterialCondition] = []
	for a in attributes:
		var c := MaterialCondition.new()
		c.attribute = a
		reqs.append(c)
	n.material_requirements = reqs
	return n


func _lines(n: int) -> NumberOfLinesCondition:
	var c := NumberOfLinesCondition.new()
	c.number_of_lines = n
	return c


func _connections(n: int) -> NumberOfConnectionsCondition:
	var c := NumberOfConnectionsCondition.new()
	c.number_of_lines = n
	return c


func _save(r: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	# Keep an existing file's uid so references to it elsewhere stay valid
	var uid := (
		ResourceLoader.get_resource_uid(path)
		if ResourceLoader.exists(path)
		else ResourceUID.INVALID_ID
	)
	var err := ResourceSaver.save(r, path)
	assert(err == OK, "Could not save %s" % path)
	if uid != ResourceUID.INVALID_ID:
		ResourceSaver.set_uid(path, uid)
