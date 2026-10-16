extends Node

"""
Regenerates the placeholder content for the first inscribing build.
Run: godot --headless --path . res://tools/build_demo_content.tscn
Editing the generated .tres files in the editor is fine; rerunning this overwrites them.
"""

const STONES := "res://items/enchantment_materials/%s/%s.tres"
const A := EnchantmentMaterialDefinition.MATERIAL_ATTRIBUTES

func _ready() -> void:
	var fire := _stone("fire_stone", "Fire stone", Color("e8642c"), 1, [A.Flame], [_lines(2)])
	var water := _stone("water_stone", "Water stone", Color("3c8de0"), 1, [A.Water], [_connections(2)])
	var red := _stone("red_stone", "Red stone", Color("c8324b"), 1, [A.Soft, A.Shiny], [_lines(2)])
	var blue := _stone("blue_stone", "Blue stone", Color("4b5fc8"), 1, [A.Hard], [_lines(1)])
	var yellow := _stone("yellow_stone", "Yellow stone", Color("e6c235"), 2, [A.Shiny, A.Hard], [InstantPassCondition.new()])

	var kindle := _pattern("kindle", "Kindle", "Warm to the touch",
		[_node(Vector2i(0, 0), 1, [A.Flame]), _node(Vector2i(1, 0))],
		[Vector2i(0, 1)])
	var glow := _pattern("glow", "Glow", "Gives off a soft light",
		[_node(Vector2i(0, 0)), _node(Vector2i(1, 0)), _node(Vector2i(0, 1), 2, [A.Shiny])],
		[Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 0)])
	var keen := _pattern("keen", "Keen", "Cuts noticeably better",
		[_node(Vector2i(0, 0), 1, [A.Soft]), _node(Vector2i(1, 0), 1, [A.Hard]), _node(Vector2i(2, 0), 1, [A.Soft])],
		[Vector2i(0, 1), Vector2i(1, 2)])
	var ward := _pattern("ward", "Ward", "Shrugs off rust and water",
		[_node(Vector2i(0, 0), 1, [A.Water]), _node(Vector2i(1, 0), 1, [A.Hard]), _node(Vector2i(0, 1), 1, [A.Hard]), _node(Vector2i(1, 1), 1, [A.Water])],
		[Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 2)])

	var sword_map := HexMapDefinition.new()
	sword_map.map_name = "Demo sword"
	sword_map.layout = PackedStringArray([
		"...#...",
		"..###..",
		"..M#M..",
		"..###..",
		"..###..",
		"..#M#..",
		"..###..",
		"..###..",
		"..M#M..",
		"..###..",
		"..###..",
		"#######",
		"M##M##M",
		"...##..",
		"..##...",
		"...##..",
		"..#M#..",
	])
	_save(sword_map, "res://inscribing/demo/demo_sword_map.tres")

	var sword := EnchantableItemDefinition.new()
	sword.id = &"demo_sword"
	sword.display_name = "Demo sword"
	sword.map_template = load("res://inscribing/demo/demo_sword_map.tres")
	_save(sword, "res://inscribing/demo/demo_sword.tres")

	var setup := DemoSetup.new()
	setup.materials = {fire: 3, water: 3, red: 3, blue: 3, yellow: 1}
	setup.items = [load("res://inscribing/demo/demo_sword.tres"), load("res://inscribing/demo/demo_sword.tres")]
	setup.enchantments = [kindle, glow, keen, ward]
	setup.day_length_seconds = 3600.0
	_save(setup, "res://inscribing/demo/demo_setup.tres")
	print("Demo content written")
	get_tree().quit()

func _stone(folder: String, display: String, color: Color, tier: int, attributes: Array, conditions: Array) -> EnchantmentMaterialDefinition:
	var path := STONES % [folder, folder]
	var m: EnchantmentMaterialDefinition = load(path)
	m.id = StringName(folder)
	m.display_name = display
	m.color = color
	m.tier = tier
	var attrs: Array[EnchantmentMaterialDefinition.MATERIAL_ATTRIBUTES] = []
	attrs.assign(attributes)
	m.material_attributes = attrs
	var conds: Array[EnchantmentCondition] = []
	conds.assign(conditions)
	m.activation_conditions = conds
	_save(m, path)
	return load(path)

func _pattern(file: String, display: String, effect: String, nodes: Array, lines: Array) -> Enchantment:
	var path := "res://enchantments/patterns/%s.tres" % file
	var e := Enchantment.new()
	e.enchantment_name = display
	e.effect_description = effect
	var n: Array[EnchantmentPatternNode] = []
	n.assign(nodes)
	e.nodes = n
	var l: Array[Vector2i] = []
	l.assign(lines)
	e.lines = l
	_save(e, path)
	return load(path)

func _node(offset: Vector2i, tier := 1, attributes: Array = []) -> EnchantmentPatternNode:
	var n := EnchantmentPatternNode.new()
	n.offset = offset
	n.tier_requirement = tier
	var reqs: Array[MaterialCondition] = []
	for a in attributes:
		var c := MaterialCondition.new()
		c.attribute = a
		reqs.append(c)
	n.material_requirements = reqs
	return n

func _lines(n: int) -> NumberOfLinesConditon:
	var c := NumberOfLinesConditon.new()
	c.number_of_lines = n
	return c

func _connections(n: int) -> NumberOfConnectionsConditon:
	var c := NumberOfConnectionsConditon.new()
	c.number_of_lines = n
	return c

func _save(r: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	# Keep an existing file's uid so references to it elsewhere stay valid
	var uid := ResourceLoader.get_resource_uid(path) if ResourceLoader.exists(path) else ResourceUID.INVALID_ID
	var err := ResourceSaver.save(r, path)
	assert(err == OK, "Could not save %s" % path)
	if uid != ResourceUID.INVALID_ID:
		ResourceSaver.set_uid(path, uid)
