extends GutTest

## The starter content fits together: every starter enchantment can be carved on the starter
## items with the starter materials, and every board that makes can be disenchanted again with
## the starter inventory (design doc §7.6). Reads the demo setup as it ships, so a content
## change that breaks either shows up here.

const SETUP := preload("res://inscribing/demo/demo_setup.tres")
## Enough of every material that carving is about the shapes and the map, not the stock
const PLENTY := 20


func _starter_materials() -> Array[EnchantmentMaterialDefinition]:
	var out: Array[EnchantmentMaterialDefinition] = []
	out.assign(SETUP.materials.keys())
	return out


func _stocked_player() -> Player:
	var p := Player.new()
	for m in _starter_materials():
		p.add_material(m, PLENTY)
	return p


func _fresh_item(definition: EnchantableItemDefinition) -> ItemInstance:
	var inst := ItemInstance.new()
	inst.definition = definition
	inst.id = definition.id
	return inst


## Carves `e` alone on a fresh copy of `definition`; returns the board, or null if it didn't fit
func _carve_alone(e: Enchantment, definition: EnchantableItemDefinition) -> InscriptionBoard:
	var board := InscriptionBoard.new(_fresh_item(definition), _stocked_player())
	var carver := AutoCarver.new(board, _starter_materials())
	return board if carver.carve(e) != null else null


func test_starter_content_is_there() -> void:
	assert_gt(SETUP.enchantments.size(), 0, "the demo setup lists enchantments")
	assert_gt(SETUP.items.size(), 0, "the demo setup lists items")
	assert_gt(SETUP.materials.size(), 0, "the demo setup lists materials")


func test_every_enchantment_shape_is_valid() -> void:
	for e in SETUP.enchantments:
		assert_eq(InscriptionBoard.check_shape(e), "", "%s has a valid shape" % e.enchantment_name)


func test_every_node_takes_a_starter_material() -> void:
	for e in SETUP.enchantments:
		for i in e.nodes.size():
			var fits := _starter_materials().filter(func(m): return e.nodes[i].accepts(m))
			assert_gt(
				fits.size(),
				0,
				(
					"%s node %d (%s) takes a starter material"
					% [e.enchantment_name, i, e.nodes[i].describe_requirements()]
				)
			)


func test_every_enchantment_can_be_carved_on_a_starter_item() -> void:
	for e in SETUP.enchantments:
		var fits_on: Array[String] = []
		for definition in SETUP.items:
			if _carve_alone(e, definition) != null:
				fits_on.append(definition.display_name)
		assert_gt(fits_on.size(), 0, "%s can be carved on some starter item" % e.enchantment_name)
		gut.p("%s carves on: %s" % [e.enchantment_name, ", ".join(fits_on)])


func test_every_carving_can_be_disenchanted_with_the_starter_inventory() -> void:
	for e in SETUP.enchantments:
		for definition in SETUP.items:
			var board := _carve_alone(e, definition)
			if board == null:
				continue
			var what := "%s on the %s" % [e.enchantment_name, definition.display_name]
			var d := DisenchantBoard.new(board)
			var targets := d.carvings()
			var solutions := SolvabilityChecker.new(d).solve(targets, SETUP.materials)
			assert_gt(solutions.size(), 0, "%s can be disenchanted" % what)
			if solutions.is_empty():
				continue
			for o in d.replay(solutions[0].steps(targets, d)):
				assert_eq(o.error, "", "%s: the checker's plan replays through the rules" % what)


func test_the_shipped_carved_items_can_be_disenchanted() -> void:
	var player := SETUP.create_player()
	for inst in player.items:
		var d := DisenchantBoard.new(InscriptionBoard.new(inst, player))
		if d.carvings().is_empty():
			continue
		var solutions := SolvabilityChecker.new(d).solve(d.carvings(), player.material_inventory)
		assert_gt(solutions.size(), 0, "%s can be cleared" % InscriptionBoard.item_name(inst))
