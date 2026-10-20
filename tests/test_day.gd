extends Node

"""
Headless checks for the day: which side is active, freezing the other side, and items handed
over from the counter, and the demo rulebook.
Run: godot --headless --path . res://tests/test_day.tscn
Exits with code 1 if any check fails.
"""

const DAY_SCENE := preload("res://day/day.tscn")

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_split_day()
	test_freeze_and_dev_switch()
	test_counter_hands_over_items()
	test_rulebook()
	test_counter_only_and_inscribing_only_days()
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


func test_split_day() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	check(day.side == Day.ShopSide.COUNTER, "a split day starts at the counter")
	check(day.counter.visible and not day.table.visible, "only the counter is shown")
	check(
		day.table.process_mode == Node.PROCESS_MODE_DISABLED, "the table is paused at the counter"
	)
	day.advance(4.0)
	check(is_equal_approx(day.time_left[Day.ShopSide.COUNTER], 6.0), "the counter's clock runs")
	check(is_equal_approx(day.time_left[Day.ShopSide.INSCRIBING], 20.0), "the table's clock waits")
	day.advance(6.0)
	check(
		day.side == Day.ShopSide.INSCRIBING, "the day moves to inscribing when the counter is done"
	)
	check(day.table.visible and not day.counter.visible, "only the table is shown")
	check(day.counter.process_mode == Node.PROCESS_MODE_DISABLED, "the counter is paused")
	day.end_side()
	check(day.is_day_over(), "the day ends when inscribing time runs out")
	day.start_next_day()
	check(day.day_number == 2 and not day.is_day_over(), "the next day starts")
	check(day.side == Day.ShopSide.COUNTER, "the next day starts at the counter again")
	day.queue_free()


func test_freeze_and_dev_switch() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	day.switch_to(Day.ShopSide.INSCRIBING)
	day.advance(5.0)
	var board := day.table.board
	check(is_equal_approx(day.time_left[Day.ShopSide.COUNTER], 10.0), "the counter's clock froze")
	check(is_equal_approx(day.time_left[Day.ShopSide.INSCRIBING], 15.0), "the table's clock ran")
	day.switch_to(Day.ShopSide.COUNTER)
	day.advance(2.0)
	check(is_equal_approx(day.time_left[Day.ShopSide.INSCRIBING], 15.0), "the table's clock froze")
	day.switch_to(Day.ShopSide.INSCRIBING)
	check(day.table.board == board, "the table comes back on the same item and plan")
	day.queue_free()


func test_counter_hands_over_items() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	var before := day.player.items.size()
	var first := day.counter.current_visit()
	check(first != null and first.day == 1, "the first customer of day 1 is waiting")
	day.counter.accept()
	check(day.player.items.size() == before + 1, "an accepted commission's item joins the items")
	check(day.counter.current_visit() != first, "the next customer steps up")
	day.counter.refuse()
	check(day.player.items.size() == before + 1, "a refused customer's item is handed back")
	check(day.counter.decisions.size() == 2, "the counter remembers both calls")
	check(day.counter.decisions[0].is_right(), "accepting a clean commission agrees with the rules")
	check(day.counter.decisions[1].is_right(), "refusing a tier-1 Keen agrees with the rules")
	var ids: Array[StringName] = []
	for inst in day.player.items:
		check(inst.id not in ids, "item ids stay unique (%s)" % inst.id)
		ids.append(inst.id)
	day.switch_to(Day.ShopSide.INSCRIBING)
	check(
		day.table._items.item_count == day.player.items.size(),
		"the table lists the new item when it opens"
	)
	day.queue_free()


func test_rulebook() -> void:
	var book: Rulebook = load("res://counter/demo/demo_rulebook.tres")
	var expected := {
		"01_elsa": "",
		"02_bram": "Keen needs tier 2, but the ID is tier 1",
		"03_ines": "",
		"04_oskar": "No permit shown for Kindle",
		"05_rhea": "The ID ran out on day 1",
		"06_tomas": "",
		"07_wil": "The ID is in the name of Wil Hartley",
	}
	for key: String in expected:
		var visit: CustomerVisit = load("res://counter/demo/visit_%s.tres" % key)
		var found := book.problems(visit, visit.day)
		var want: String = expected[key]
		if want == "":
			check(found.is_empty(), "%s breaks no rule (got %s)" % [key, found])
		else:
			check(found == [want], "%s: %s (got %s)" % [key, want, found])


func test_counter_only_and_inscribing_only_days() -> void:
	var day := _make_day([_plan(10.0, 0.0), _plan(0.0, 20.0)])
	check(day.side == Day.ShopSide.COUNTER, "a counter-only day starts at the counter")
	day.advance(10.0)
	check(day.is_day_over(), "a counter-only day ends when the counter is done")
	day.end_side()
	check(day.day_number == 1, "ending a side after the day is over does nothing")
	day.start_next_day()
	check(day.side == Day.ShopSide.INSCRIBING, "an inscribing-only day starts at the table")
	check(not day.counter.visible, "the counter stays hidden on an inscribing-only day")
	day.start_next_day()
	check(day.side == Day.ShopSide.INSCRIBING, "days past the schedule repeat its last plan")
	day.queue_free()
