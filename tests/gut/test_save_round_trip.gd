extends GutTest

## Saving part way through a busy day and loading it brings everything back exactly: money,
## stones, items and what's carved on them (committed, still being planned, or planned to be
## disenchanted), commissions, the counter's queue and calls, and the clock. Each check compares
## a plain-data snapshot of the run before saving with one of the loaded run.

const DAY_SCENE := preload("res://day/day.tscn")
const DEMO_SETUP := preload("res://inscribing/demo/demo_setup.tres")
const TEST_PATH := "user://test_saves/gut_round_trip.tres"
const GLOW := preload("res://enchantments/patterns/glow.tres")


func after_all() -> void:
	SaveManager.delete_save(TEST_PATH)


func _make_day() -> Day:
	var day: Day = DAY_SCENE.instantiate()
	# The test bench's setup, which has the shop's own items, including a carved one to disenchant
	day.setup = DEMO_SETUP
	var plan := DayPlan.new()
	plan.counter_seconds = 60.0
	plan.inscribing_seconds = 90.0
	day.schedule = DaySchedule.new()
	day.schedule.days = [plan]
	add_child_autofree(day)
	return day


func _path(r: Resource) -> String:
	return r.resource_path if r != null else "<none>"


func _graph(g: GraphState) -> Dictionary:
	if g == null:
		return {}
	var placements := []
	for p in g.placements:
		placements.append(
			[
				p.id,
				_path(p.enchantment),
				p.origin,
				p.rotation_steps,
				p.committed,
				p.materials.map(_path)
			]
		)
	var lines := []
	for l in g.lines:
		lines.append([l.a, l.b, l.committed, l.cells])
	var plan := []
	for s in g.disenchant_plan:
		plan.append([s.kind, s.a, s.b, s.line, _path(s.material), s.placement_id])
	return {
		"placements": placements,
		"lines": lines,
		"next_id": g.next_placement_id,
		"plan": plan,
	}


func _commission(c: Commission) -> Array:
	return [_path(c.visit), String(c.item.id), c.accepted_day, c.collected, c.paid, c.fulfilled()]


## The run as plain data, so two runs can be compared with assert_eq
func _snapshot(day: Day) -> Dictionary:
	var stock := {}
	for m in day.player.material_inventory:
		stock[_path(m)] = day.player.material_inventory[m]
	var items := []
	for inst in day.player.items:
		items.append(
			[String(inst.id), _path(inst.definition), _graph(inst.enchantment_graph_state)]
		)
	var commissions := day.player.commissions.map(_commission)
	var decisions := []
	for d in day.counter.decisions:
		decisions.append([_path(d.visit), d.accepted, d.problems])
	return {
		"day": day.day_number,
		"side": day.side,
		"time_left":
		[
			snappedf(day.time_left[Day.ShopSide.COUNTER], 0.001),
			snappedf(day.time_left[Day.ShopSide.INSCRIBING], 0.001),
		],
		"money": day.player.money,
		"stock": stock,
		"items": items,
		"known": day.player.known_enchantments.map(_path),
		"commissions": commissions,
		"decisions": decisions,
		"collections": day.counter.collections.map(_commission),
		"at_counter": _path(day.counter.current_visit()),
		"collecting":
		_commission(day.counter.current_return()) if day.counter.current_return() else [],
	}


func _save_and_load(day: Day) -> Day:
	assert_eq(SaveManager.write_save(day.to_save(), TEST_PATH), OK, "the save is written")
	var game := SaveManager.read_save(TEST_PATH)
	assert_not_null(game, "the save reads back")
	var loaded := _make_day()
	loaded.load_game(game)
	return loaded


## Day 1: accept the legal customers and carve their jobs. Day 2: collect, accept the first
## new customer, start a Glow on one of the shop's own items without committing it, stock up
## and plan a disenchant on a carved item, then stop at the table with time left.
func _busy_day() -> Day:
	var day := _make_day()
	day.player.money = 1000
	while day.counter.current_visit() != null:
		var v := day.counter.current_visit()
		if day.counter.rulebook.problems(v, 1).is_empty():
			day.counter.accept()
		else:
			day.counter.refuse()
	for c in day.player.commissions:
		ShopActions.carve_commission(day.counter, c)
	day.end_side()
	day.end_side()
	day.start_next_day()
	if day.counter.current_return() != null:
		day.counter.hand_back()
	if day.counter.current_visit() != null:
		day.counter.accept()
	day.advance(20.0)
	day.switch_to(Day.ShopSide.INSCRIBING)
	day.advance(7.5)
	var plain := day.player.items[0]
	var board := InscriptionBoard.new(plain, day.player)
	var p: PlacementState = null
	for c in board.get_cells():
		p = board.place(GLOW, c, 0)
		if p != null:
			break
	if p != null:
		for m in ShopActions.by_price(day.counter.catalogue):
			if board.insert_material(InscriptionBoard.enchantment_key(p.id, 0), m) == "":
				break
	for m in day.counter.catalogue.materials():
		while day.player.get_material_count(m) < 4:
			day.counter.buy(m)
	for inst in day.player.items:
		var d := DisenchantBoard.new(InscriptionBoard.new(inst, day.player))
		if d.carvings().is_empty() or inst == plain:
			continue
		var found := SolvabilityChecker.new(d).solve(d.carvings(), day.player.material_inventory)
		if not found.is_empty():
			for m in found[0].dissolves:
				d.plan_dissolve(m)
			d.plan_cut(found[0].cuts[0])
			break
	return day


func test_the_busy_day_has_something_of_everything() -> void:
	var s := _snapshot(_busy_day())
	assert_eq(s.day, 2, "it's day 2")
	assert_gt(s.commissions.size(), 0, "commissions were taken on")
	assert_gt(s.collections.size(), 0, "someone collected today")
	var drafts := 0
	var committed := 0
	var plans := 0
	for item in s.items:
		var g: Dictionary = item[2]
		if g.is_empty():
			continue
		plans += g.plan.size()
		for p in g.placements:
			if p[4]:
				committed += 1
			else:
				drafts += 1
	assert_gt(committed, 0, "items have committed carvings")
	assert_gt(drafts, 0, "an item has a carving still being planned")
	assert_gt(plans, 0, "an item has a disenchant planned")


func test_a_mid_day_save_loads_back_identical() -> void:
	var day := _busy_day()
	var before := _snapshot(day)
	var loaded := _save_and_load(day)
	var after := _snapshot(loaded)
	for key in before:
		assert_eq(after[key], before[key], "%s comes back the same" % key)


func test_saving_a_loaded_run_changes_nothing() -> void:
	var loaded := _save_and_load(_busy_day())
	var once := _snapshot(loaded)
	var twice := _snapshot(_save_and_load(loaded))
	assert_eq(twice, once, "a second round trip is identical to the first")


func test_the_loaded_run_plays_on_the_same() -> void:
	var day := _busy_day()
	var loaded := _save_and_load(day)
	for run in [day, loaded]:
		while run.counter.current_visit() != null:
			run.counter.refuse()
		run.end_side()
		run.end_side()
		run.start_next_day()
		while run.counter.current_return() != null:
			run.counter.hand_back()
	assert_eq(_snapshot(loaded), _snapshot(day), "the next day goes the same way in both")


func test_planned_stones_stay_planned_after_loading() -> void:
	var day := _busy_day()
	var held := {}
	for inst in day.player.items:
		if inst.enchantment_graph_state:
			var planned := inst.enchantment_graph_state.planned_materials()
			for m in planned:
				held[_path(m)] = held.get(_path(m), 0) + planned[m]
	assert_gt(held.size(), 0, "some stones are held in plans")
	var loaded := _save_and_load(day)
	var after := {}
	for inst in loaded.player.items:
		if inst.enchantment_graph_state:
			var planned := inst.enchantment_graph_state.planned_materials()
			for m in planned:
				after[_path(m)] = after.get(_path(m), 0) + planned[m]
	assert_eq(after, held, "the same stones are held in the same plans")
	var count_before := 0
	var count_after := 0
	for m in day.player.material_inventory:
		count_before += day.player.material_inventory[m]
	for m in loaded.player.material_inventory:
		count_after += loaded.player.material_inventory[m]
	assert_eq(count_after, count_before, "and none of them came back into the stock")
