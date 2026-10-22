extends GutTest

## Disenchanting can't be done on credit, and backing out of a plan costs nothing. Runes are the
## currency here: you start a disenchant with none, and dissolving materials is how you pay
## for cuts (design doc §7.6). Uses the demo's starter content.

const SETUP := preload("res://inscribing/demo/demo_setup.tres")
const KINDLE := preload("res://enchantments/patterns/kindle.tres")
const LONG_SWORD := preload("res://inscribing/demo/long_sword.tres")

var _player: Player
var _inscription: InscriptionBoard
var _board: DisenchantBoard
var _carving: PlacementState


func before_each() -> void:
	_player = Player.new()
	for m in SETUP.materials:
		_player.add_material(m, SETUP.materials[m])
	var inst := ItemInstance.new()
	inst.definition = LONG_SWORD
	_inscription = InscriptionBoard.new(inst, _player)
	var materials: Array[EnchantmentMaterialDefinition] = []
	materials.assign(SETUP.materials.keys())
	_carving = AutoCarver.new(_inscription, materials).carve(KINDLE)
	assert_not_null(_carving, "Kindle carves on the long sword")
	_board = DisenchantBoard.new(_inscription)


func _stock() -> Dictionary:
	return _player.material_inventory.duplicate()


## Plans every cut and the pull-out, in the order the checker found, without dissolving anything
func _plan_cuts_only(solution: SolvabilityChecker.Solution) -> void:
	for k in solution.cuts:
		assert_eq(_board.plan_cut(k), "", "cut %s can be planned" % _board.edge_name(k))
	assert_eq(_board.plan_pull_out(_carving), "", "Kindle can be planned to come out")


func _solution() -> SolvabilityChecker.Solution:
	var found := SolvabilityChecker.new(_board).solve(_board.carvings(), _player.material_inventory)
	assert_gt(found.size(), 0, "the carving can be disenchanted")
	return found[0] if not found.is_empty() else null


func _plan(solution: SolvabilityChecker.Solution) -> void:
	for m in solution.dissolves:
		assert_eq(_board.plan_dissolve(m), "", "%s can be dissolved" % m.resource_path)
	_plan_cuts_only(solution)


func test_a_plan_without_runes_cannot_be_committed() -> void:
	var s := _solution()
	if s == null or s.dissolves.is_empty():
		pending("This carving can be cleared on harvests alone, so there's nothing to pay")
		return
	_plan_cuts_only(s)
	assert_ne(_board.first_blocked(), -1, "a cut is blocked without runes")
	assert_string_contains(_board.check_commit(), "can't be done")
	assert_eq(_board.commit().size(), 0, "nothing is pulled out")
	assert_true(_carving.committed, "Kindle is still carved")
	assert_eq(_inscription.committed_placements().size(), 1, "the item still holds its carving")


func test_runes_never_go_negative_in_a_replay() -> void:
	var s := _solution()
	if s == null:
		return
	_plan_cuts_only(s)
	for o in _board.outcomes():
		for amount in [o.runes.water, o.runes.fire, o.runes.wind, o.runes.stone]:
			assert_true(amount >= 0, "runes held never drop below zero")


func test_dissolving_needs_the_material_in_stock() -> void:
	var m: EnchantmentMaterialDefinition = SETUP.materials.keys()[0]
	while _player.get_material_count(m) > 0:
		assert_eq(_board.plan_dissolve(m), "")
	assert_ne(_board.check_dissolve(m), "", "can't dissolve a material you don't have")
	assert_ne(_board.plan_dissolve(m), "", "planning it is refused")


func test_cancelling_a_plan_refunds_every_material() -> void:
	var before := _stock()
	var s := _solution()
	if s == null:
		return
	_plan(s)
	if not s.dissolves.is_empty():
		assert_ne(_stock(), before, "planned dissolves hold their materials in the item")
	_board.clear_plan()
	assert_eq(_stock(), before, "every planned material is back in the inventory")
	assert_eq(_board.state.disenchant_plan.size(), 0, "the plan is empty")
	assert_true(_carving.committed, "the carving is untouched")


func test_undoing_step_by_step_refunds_every_material() -> void:
	var before := _stock()
	var s := _solution()
	if s == null:
		return
	_plan(s)
	while _board.undo_last() != null:
		pass
	assert_eq(_stock(), before, "every planned material is back in the inventory")


func test_cancelling_after_leaving_the_item_still_refunds() -> void:
	var before := _stock()
	var s := _solution()
	if s == null:
		return
	_plan(s)
	_board = DisenchantBoard.new(InscriptionBoard.new(_inscription.item, _player))
	assert_eq(
		_board.state.disenchant_plan.size(),
		s.steps(_board.carvings(), _board).size(),
		"the plan stayed with the item"
	)
	_board.clear_plan()
	assert_eq(_stock(), before, "reopening the item and cancelling refunds everything")


func test_a_paid_plan_commits_and_uses_up_only_the_dissolves() -> void:
	var before := _stock()
	var s := _solution()
	if s == null:
		return
	_plan(s)
	assert_eq(_board.check_commit(), "", "the full plan can be committed")
	var cells := _inscription.placement_cells(KINDLE, _carving.origin, _carving.rotation_steps)
	assert_eq(_board.commit().size(), 1, "Kindle is pulled out")
	assert_eq(_inscription.committed_placements().size(), 0, "the item is clean")
	assert_eq(_inscription.state.lines.size(), 0, "every line is gone")
	for c in cells:
		assert_eq(_inscription.node_covering(c), "", "the cell %s is free again" % c)
	var expected := before.duplicate()
	for m in s.dissolves:
		expected[m] -= 1
		if expected[m] <= 0:
			expected.erase(m)
	assert_eq(_stock(), expected, "only the dissolved materials are used up")
