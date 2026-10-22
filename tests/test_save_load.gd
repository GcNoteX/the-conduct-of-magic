extends Node

"""
Headless checks for saving and loading a run: what a save holds, picking a day up part way
through, saving on the day-over screen, and refusing saves that can't be used.
Run: godot --headless --path . res://tests/test_save_load.tscn
Exits with code 1 if any check fails. Saves go to TEST_DIR, never to the real save slot.
"""

const DAY_SCENE := preload("res://day/day.tscn")
const TEST_DIR := "user://test_saves"
const TEST_PATH := TEST_DIR + "/run.tres"

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_mid_day_round_trip()
	test_collecting_after_load()
	test_save_on_day_over_opens_next_day()
	test_unusable_saves_are_refused()
	test_running_the_day_alone_does_not_autosave()
	SaveManager.delete_save(TEST_PATH)
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func _make_day(plans: Array[DayPlan]) -> Day:
	var day: Day = DAY_SCENE.instantiate()
	day.schedule = DaySchedule.new()
	day.schedule.days = plans
	add_child(day)  # No frames pass during the checks, so only advance() runs the clock
	return day


func _plan(counter_seconds: float, inscribing_seconds: float) -> DayPlan:
	var p := DayPlan.new()
	p.counter_seconds = counter_seconds
	p.inscribing_seconds = inscribing_seconds
	return p


## Writes the day's save to the test slot and reads it back as a fresh copy
func _round_trip(day: Day) -> SaveGame:
	check(SaveManager.write_save(day.to_save(), TEST_PATH) == OK, "the save is written")
	var game := SaveManager.read_save(TEST_PATH)
	check(game != null, "the save reads back")
	return game


func _carve(inst: ItemInstance, carved: Array[Enchantment]) -> void:
	if inst.enchantment_graph_state == null:
		inst.enchantment_graph_state = GraphState.new()
	for e in carved:
		var p := PlacementState.new()
		p.enchantment = e
		p.materials.resize(e.nodes.size())
		p.committed = true
		inst.enchantment_graph_state.placements.append(p)


func test_mid_day_round_trip() -> void:
	var day := _make_day([_plan(30.0, 40.0)])
	var elsa := day.counter.current_visit()
	day.counter.accept()
	var bram := day.counter.current_visit()
	day.counter.refuse()
	var next_up := day.counter.current_visit()
	var yellow: EnchantmentMaterialDefinition = load(
		"res://items/enchantment_materials/yellow_stone/yellow_stone.tres"
	)
	day.counter.buy(yellow)
	day.advance(12.0)
	var money := day.player.money
	var stones := day.player.get_material_count(yellow)
	var item_ids: Array[StringName] = []
	for inst in day.player.items:
		item_ids.append(inst.id)
	var game := _round_trip(day)
	day.queue_free()
	if game == null:
		return
	check(game.player != day.player, "the loaded player is a fresh copy")
	check(game.saved_at != "", "the save records when it was made")
	check(game.summary().begins_with("Day 1, saved "), "the menu line names the day")

	var loaded := _make_day([_plan(30.0, 40.0)])
	loaded.load_game(game)
	check(loaded.day_number == 1, "the loaded run is on the same day")
	check(loaded.side == Day.ShopSide.COUNTER, "and the same side")
	check(
		is_equal_approx(loaded.time_left[Day.ShopSide.COUNTER], 18.0),
		"with the counter's time left as it was"
	)
	check(
		is_equal_approx(loaded.time_left[Day.ShopSide.INSCRIBING], 40.0),
		"and the table's time untouched"
	)
	check(loaded.player.money == money, "money is kept")
	check(loaded.player.get_material_count(yellow) == stones, "bought stones are kept")
	var loaded_ids: Array[StringName] = []
	for inst in loaded.player.items:
		loaded_ids.append(inst.id)
	check(loaded_ids == item_ids, "the same items are in the shop")
	check(loaded.player.commissions.size() == 1, "Elsa's commission is kept")
	var c := loaded.player.commissions[0]
	check(c.visit == elsa, "the commission points at Elsa's visit file, not a copy")
	check(c.item in loaded.player.items, "and at the item in the shop")
	check(loaded.counter.decisions.size() == 2, "today's two calls are kept")
	check(loaded.counter.current_visit() == next_up, "the counter picks up with the next customer")
	for d in loaded.counter.decisions:
		check(d.visit != loaded.counter.current_visit(), "decided customers don't come back")
	check(
		loaded.counter.decisions[1].visit == bram and not loaded.counter.decisions[1].accepted,
		"Bram stays refused"
	)
	check(PlayerManager.get_player() == loaded.player, "PlayerManager holds the loaded player")
	loaded.queue_free()


func test_collecting_after_load() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	var elsa := day.counter.current_visit()
	day.counter.accept()
	day.switch_to(Day.ShopSide.INSCRIBING)
	var c := day.player.commissions[0]
	_carve(c.item, [elsa.slip.enchantments[0]])
	day.advance(5.0)
	var game := _round_trip(day)
	day.queue_free()
	if game == null:
		return
	var loaded := _make_day([_plan(10.0, 20.0)])
	loaded.load_game(game)
	check(loaded.side == Day.ShopSide.INSCRIBING, "a save made at the table opens at the table")
	check(loaded.table.visible and not loaded.counter.visible, "only the table is shown")
	check(
		is_equal_approx(loaded.time_left[Day.ShopSide.INSCRIBING], 15.0),
		"the table's clock is where it was"
	)
	var loaded_c := loaded.player.commissions[0]
	check(loaded_c.fulfilled() == [true, false], "the carving still counts for Elsa's request")
	var money := loaded.player.money
	loaded.end_side()
	loaded.start_next_day()
	check(loaded.counter.current_return() == loaded_c, "Elsa comes back the next day")
	loaded.counter.hand_back()
	check(
		loaded.player.money == money + elsa.slip.payment / 2, "and pays for one of two enchantments"
	)
	loaded.queue_free()


func test_save_on_day_over_opens_next_day() -> void:
	var day := _make_day([_plan(10.0, 20.0), _plan(0.0, 25.0)])
	day.counter.accept()
	day.end_side()
	day.end_side()
	check(day.is_day_over(), "the day is over")
	var game := _round_trip(day)
	day.queue_free()
	if game == null:
		return
	check(game.day_number == 2, "a save on the day-over screen is for the next day")
	check(game.decisions.is_empty(), "with nothing decided yet")
	var loaded := _make_day([_plan(10.0, 20.0), _plan(0.0, 25.0)])
	loaded.load_game(game)
	check(loaded.day_number == 2 and not loaded.is_day_over(), "it opens on day 2")
	check(loaded.side == Day.ShopSide.INSCRIBING, "at the table, since day 2 has no counter time")
	check(
		is_equal_approx(loaded.time_left[Day.ShopSide.INSCRIBING], 25.0),
		"with the whole of day 2's time"
	)
	loaded.queue_free()


func test_unusable_saves_are_refused() -> void:
	SaveManager.delete_save(TEST_PATH)
	check(not SaveManager.has_save(TEST_PATH), "a deleted save is gone")
	check(SaveManager.read_save(TEST_PATH) == null, "a missing save reads as none")

	var day := _make_day([_plan(10.0, 20.0)])
	var game := day.to_save()
	day.queue_free()
	check(SaveManager.write_save(game, TEST_PATH) == OK, "the save is written")
	var text := FileAccess.get_file_as_string(TEST_PATH)
	check(not text.contains('type="GDScript"'), "a save carries no code of its own")
	var version_line := "format_version = %d" % SaveGame.FORMAT_VERSION
	check(text.contains(version_line), "the save records its format version")
	_write(text.replace(version_line, "format_version = %d" % (SaveGame.FORMAT_VERSION + 1)))
	check(SaveManager.read_save(TEST_PATH) == null, "a save from another version isn't loaded")
	_write(text + '\n[sub_resource type="GDScript" id="x"]\n')
	check(SaveManager.read_save(TEST_PATH) == null, "a save with code in it isn't loaded")
	_write("not a save")
	check(SaveManager.read_save(TEST_PATH) == null, "a broken file isn't loaded")
	SaveManager.delete_save(TEST_PATH)


func test_running_the_day_alone_does_not_autosave() -> void:
	var had_save := SaveManager.has_save()
	var before := FileAccess.get_modified_time(SaveManager.SAVE_PATH) if had_save else 0
	var day := _make_day([_plan(10.0, 20.0)])
	day.end_side()
	day.end_side()
	day.start_next_day()
	day.queue_free()
	var after := FileAccess.get_modified_time(SaveManager.SAVE_PATH) if had_save else 0
	check(SaveManager.has_save() == had_save and before == after, "the real save is untouched")


func _write(text: String) -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()
