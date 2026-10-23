extends GutTest

## The day's clock and schedule beyond what tests/test_day.tscn covers: which plan each day
## gets, time that never goes below zero or spills from one side to the other, a day with no
## time at all, and a day that's over staying over.

const DAY_SCENE := preload("res://day/day.tscn")


func _plan(counter_seconds: float, inscribing_seconds: float) -> DayPlan:
	var p := DayPlan.new()
	p.counter_seconds = counter_seconds
	p.inscribing_seconds = inscribing_seconds
	return p


func _make_day(plans: Array[DayPlan]) -> Day:
	var day: Day = DAY_SCENE.instantiate()
	day.schedule = DaySchedule.new()
	day.schedule.days = plans
	add_child_autofree(day)  # No frames run in a test, so only advance() moves the clock
	return day


func test_the_schedule_picks_each_days_plan() -> void:
	var first := _plan(10.0, 0.0)
	var second := _plan(0.0, 20.0)
	var schedule := DaySchedule.new()
	schedule.days = [first, second]
	assert_eq(schedule.plan_for(1), first, "day 1 gets the first plan")
	assert_eq(schedule.plan_for(2), second, "day 2 gets the second")
	assert_eq(schedule.plan_for(9), second, "later days repeat the last plan")
	assert_eq(schedule.plan_for(0), first, "a day before 1 gets the first plan")


func test_an_empty_schedule_gives_a_day_with_no_time() -> void:
	var plan := DaySchedule.new().plan_for(1)
	assert_not_null(plan, "there's still a plan")
	assert_eq(plan.counter_seconds, 0.0)
	assert_eq(plan.inscribing_seconds, 0.0)


func test_a_day_with_no_time_is_over_at_once() -> void:
	var day := _make_day([_plan(0.0, 0.0), _plan(5.0, 5.0)])
	assert_true(day.is_day_over(), "nothing to do on day 1")
	day.start_next_day()
	assert_false(day.is_day_over(), "day 2 has time")
	assert_eq(day.side, Day.ShopSide.COUNTER)


func test_running_over_doesnt_spill_into_the_table() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	day.advance(25.0)
	assert_eq(day.side, Day.ShopSide.INSCRIBING, "the counter ran out")
	assert_eq(day.time_left[Day.ShopSide.COUNTER], 0.0, "its clock stops at zero")
	assert_eq(day.time_left[Day.ShopSide.INSCRIBING], 20.0, "the table keeps all its time")
	day.advance(100.0)
	assert_true(day.is_day_over(), "the table ran out too")
	assert_eq(day.time_left[Day.ShopSide.INSCRIBING], 0.0, "and its clock stops at zero")


func test_a_day_thats_over_stays_over() -> void:
	var day := _make_day([_plan(10.0, 0.0)])
	day.advance(10.0)
	assert_true(day.is_day_over())
	day.advance(5.0)
	day.end_side()
	assert_true(day.is_day_over(), "nothing restarts it but the next day")
	assert_eq(day.day_number, 1)
	assert_eq(day.counter.process_mode, Node.PROCESS_MODE_DISABLED, "the counter is paused")


func test_switching_back_and_forth_costs_no_time() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	day.advance(3.0)
	for i in 5:
		day.switch_to(Day.ShopSide.INSCRIBING)
		day.switch_to(Day.ShopSide.COUNTER)
	day.switch_to(Day.ShopSide.COUNTER)
	assert_almost_eq(day.time_left[Day.ShopSide.COUNTER], 7.0, 0.001, "the counter lost nothing")
	assert_eq(day.time_left[Day.ShopSide.INSCRIBING], 20.0, "nor did the table")


func test_each_day_starts_with_a_full_clock() -> void:
	var day := _make_day([_plan(10.0, 20.0), _plan(30.0, 40.0)])
	day.advance(15.0)
	day.start_next_day()
	assert_eq(day.time_left[Day.ShopSide.COUNTER], 30.0, "day 2's counter time")
	assert_eq(day.time_left[Day.ShopSide.INSCRIBING], 40.0, "day 2's table time")
	assert_eq(day.plan, day.schedule.days[1], "day 2's plan")


func test_the_player_keeps_money_and_stones_overnight() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	day.player.money = 321
	var stones := day.player.material_inventory.duplicate()
	var items := day.player.items.duplicate()
	day.end_side()
	day.end_side()
	day.start_next_day()
	assert_eq(day.player.money, 321, "money carries over")
	assert_eq(day.player.material_inventory, stones, "so do stones")
	assert_eq(day.player.items, items, "and items")
