extends GutTest

## Who stands at the counter and when, through the real day scene with the demo customers:
## each day's new customers in order, collectors before them, customers who weren't served
## leaving, collectors who weren't served coming back, and the day's calls starting afresh.
## Also what the counter tells the rest of the game through its signals.

const DAY_SCENE := preload("res://day/day.tscn")


func _make_day() -> Day:
	var day: Day = DAY_SCENE.instantiate()
	var plan := DayPlan.new()
	plan.counter_seconds = 60.0
	plan.inscribing_seconds = 60.0
	day.schedule = DaySchedule.new()
	day.schedule.days = [plan]
	add_child_autofree(day)  # No frames run in a test, so only advance() moves the clock
	return day


func _next_day(day: Day) -> void:
	while not day.is_day_over():
		day.end_side()
	day.start_next_day()


## The names of everyone still to come today, refusing each new customer to move the line on.
## Stops at the first collector.
func _refuse_all(day: Day) -> Array[String]:
	var names: Array[String] = []
	while day.counter.current_visit() != null:
		names.append(day.counter.current_visit().slip.customer_name)
		day.counter.refuse()
	return names


func _demo_names(day_number: int, day: Day) -> Array[String]:
	var names: Array[String] = []
	for v in day.counter.visits:
		if v.day == day_number:
			names.append(v.slip.customer_name)
	return names


func test_each_day_brings_its_own_customers_in_order() -> void:
	var day := _make_day()
	for d in [1, 2, 3]:
		assert_eq(day.day_number, d)
		var want := _demo_names(d, day)
		assert_gt(want.size(), 0, "the demo has customers on day %d" % d)
		assert_eq(_refuse_all(day), want, "day %d's customers come in the order listed" % d)
		assert_null(day.counter.current_return(), "nobody is collecting")
		_next_day(day)
	assert_null(day.counter.current_visit(), "nobody new comes after the last demo day")


func test_customers_not_served_by_the_end_of_the_day_leave() -> void:
	var day := _make_day()
	var first := day.counter.current_visit()
	day.counter.accept()
	_next_day(day)
	assert_eq(day.counter.current_return().visit, first, "the accepted customer is back")
	day.counter.hand_back()
	assert_eq(_refuse_all(day), _demo_names(2, day), "only day 2's customers, no one left over")
	var items := day.player.items.size()
	assert_eq(day.player.commissions.size(), 1, "the unserved ones left no commission")
	assert_eq(items, day.player.items.size(), "or item")


func test_collectors_come_first_in_the_order_they_were_accepted() -> void:
	var day := _make_day()
	var accepted: Array[CustomerVisit] = []
	while day.counter.current_visit() != null:
		accepted.append(day.counter.current_visit())
		day.counter.accept()
	_next_day(day)
	for v in accepted:
		assert_null(day.counter.current_visit(), "new customers wait behind collectors")
		assert_eq(day.counter.current_return().visit, v, "%s collects" % v.slip.customer_name)
		day.counter.hand_back()
	assert_null(day.counter.current_return(), "everyone collected")
	assert_eq(day.counter.collections.size(), accepted.size(), "the counter remembers each")
	assert_not_null(day.counter.current_visit(), "then day 2's customers step up")


func test_a_collector_not_served_comes_back_the_next_day() -> void:
	var day := _make_day()
	day.counter.accept()
	var c := day.player.commissions[0]
	_next_day(day)
	assert_eq(day.counter.current_return(), c, "back on day 2")
	_next_day(day)
	assert_eq(day.counter.current_return(), c, "not handed back, so back again on day 3")
	assert_false(c.collected, "and still not collected")
	day.counter.hand_back()
	assert_true(c.collected, "handed back on day 3")
	_next_day(day)
	assert_null(day.counter.current_return(), "a collected commission doesn't come back")


func test_the_days_calls_start_afresh_each_day() -> void:
	var day := _make_day()
	day.counter.accept()
	day.counter.refuse()
	assert_eq(day.counter.decisions.size(), 2, "two calls on day 1")
	_next_day(day)
	assert_eq(day.counter.decisions.size(), 0, "day 2 starts with no calls")
	day.counter.hand_back()
	assert_eq(day.counter.collections.size(), 1, "one collection on day 2")
	_next_day(day)
	assert_eq(day.counter.collections.size(), 0, "day 3 starts with no collections")


func test_buttons_do_nothing_with_no_one_to_serve() -> void:
	var day := _make_day()
	_refuse_all(day)
	var decided := day.counter.decisions.size()
	var money := day.player.money
	day.counter.accept()
	day.counter.refuse()
	day.counter.hand_back()
	assert_eq(day.counter.decisions.size(), decided, "no call is recorded")
	assert_eq(day.player.money, money, "no money changes hands")
	assert_eq(day.player.commissions.size(), 0, "no commission appears")


func test_accepting_while_someone_collects_does_nothing() -> void:
	var day := _make_day()
	day.counter.accept()
	_next_day(day)
	assert_not_null(day.counter.current_return(), "a collector is at the counter")
	day.counter.accept()
	day.counter.refuse()
	assert_eq(day.counter.decisions.size(), 0, "there's no slip to accept or refuse")
	assert_eq(day.player.commissions.size(), 1, "and no new commission")


func test_a_commission_is_due_from_the_day_after_it_was_accepted() -> void:
	var day := _make_day()
	_next_day(day)
	day.counter.accept()
	var c := day.player.commissions[0]
	assert_eq(c.accepted_day, 2, "accepted on day 2")
	assert_false(c.is_due(2), "not due the same day")
	assert_true(c.is_due(3), "due on day 3")
	c.collect(day.player)
	assert_false(c.is_due(4), "never due once collected")


func test_the_counter_signals_each_call_and_collection() -> void:
	var day := _make_day()
	watch_signals(day.counter)
	var first := day.counter.current_visit()
	day.counter.accept()
	assert_signal_emitted_with_parameters(day.counter, "visit_decided", [first, true])
	var second := day.counter.current_visit()
	day.counter.refuse()
	assert_signal_emitted_with_parameters(day.counter, "visit_decided", [second, false])
	assert_signal_emit_count(day.counter, "visit_decided", 2)
	_next_day(day)
	var c := day.counter.current_return()
	day.counter.hand_back()
	assert_signal_emitted_with_parameters(day.counter, "commission_collected", [c])


func test_a_commission_with_nothing_asked_pays_nothing() -> void:
	var v := CustomerVisit.new()
	v.slip = CommissionSlip.new()
	v.slip.payment = 50
	var c := Commission.create(v, ItemInstance.new(), 1)
	var p := Player.new()
	p.items.append(c.item)
	assert_eq(c.payout(), 0, "an empty slip pays nothing rather than dividing by zero")
	assert_eq(c.collect(p), 0)
	assert_true(c.collected, "it's still collected")
	assert_does_not_have(p.items, c.item, "and the item still leaves")
