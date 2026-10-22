extends GutTest

## The shop loop end to end, through the real day scene: a customer is accepted, their stones
## are bought from the supplier, the item is carved on the board, and when they come back for it
## the money goes up by exactly what they agreed to pay.

const DAY_SCENE := preload("res://day/day.tscn")
const CATALOGUE := preload("res://counter/supplier/demo_catalogue.tres")


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
	if not day.is_day_over():
		day.end_side()
	if not day.is_day_over():
		day.end_side()
	day.start_next_day()


## Accepts customers until one with a legal slip is at the counter, refusing the others. With
## `fits`, only a customer whose whole job fits on their item will do.
func _accept_next_legal(day: Day, fits := false) -> CustomerVisit:
	while day.counter.current_visit() != null:
		var v := day.counter.current_visit()
		if day.counter.rulebook.problems(v, day.day_number).is_empty() and (not fits or _fits(v)):
			day.counter.accept()
			return v
		day.counter.refuse()
	return null


func _fits(v: CustomerVisit) -> bool:
	var inst := ItemInstance.new()
	inst.definition = v.slip.item
	var order := AutoCarver.best_order(inst, v.slip.enchantments, ShopActions.by_price(CATALOGUE))
	return order.size() == v.slip.enchantments.size()


func _commission_for(day: Day, v: CustomerVisit) -> Commission:
	for c in day.player.commissions:
		if c.visit == v:
			return c
	return null


func test_accepting_takes_the_item_in() -> void:
	var day := _make_day()
	var items_before := day.player.items.size()
	var v := _accept_next_legal(day)
	assert_not_null(v, "someone legal comes on day 1")
	var c := _commission_for(day, v)
	assert_not_null(c, "accepting records a commission")
	assert_eq(day.player.items.size(), items_before + 1, "their item joins the shop's items")
	assert_eq(c.item.definition, v.slip.item, "it's the item on their slip")
	assert_eq(c.accepted_day, 1, "accepted on day 1")
	assert_false(c.is_due(1), "they don't come back the same day")
	assert_true(c.is_due(2), "they come back the next day")


func test_refusing_takes_nothing_in() -> void:
	var day := _make_day()
	var items_before := day.player.items.size()
	var money_before := day.player.money
	day.counter.refuse()
	assert_eq(day.player.commissions.size(), 0, "no commission")
	assert_eq(day.player.items.size(), items_before, "no item")
	assert_eq(day.player.money, money_before, "no money changes hands")


func test_a_full_job_pays_the_agreed_price() -> void:
	var day := _make_day()
	day.player.money = 1000
	var v := _accept_next_legal(day, true)
	assert_not_null(v, "a legal customer with a job that fits comes on day 1")
	var c := _commission_for(day, v)
	day.switch_to(Day.ShopSide.INSCRIBING)
	var wanted := v.slip.enchantments.size()
	assert_eq(ShopActions.carve_commission(day.counter, c), wanted, "every enchantment is carved")
	assert_eq(c.fulfilled_count(), wanted, "the commission sees every enchantment done")
	var money_before := day.player.money
	_next_day(day)
	assert_eq(day.counter.current_return(), c, "%s is back first" % v.slip.customer_name)
	day.counter.hand_back()
	assert_eq(day.player.money, money_before + v.slip.payment, "money goes up by the offer")
	assert_true(c.collected, "the commission is collected")
	assert_eq(c.paid, v.slip.payment, "it records the full payment")
	assert_does_not_have(day.player.items, c.item, "the item leaves with them")


func test_stones_are_paid_for_at_the_supplier() -> void:
	var day := _make_day()
	day.player.material_inventory.clear()
	day.player.money = 1000
	var v := _accept_next_legal(day, true)
	assert_not_null(v, "a legal customer with a job that fits comes on day 1")
	var c := _commission_for(day, v)
	var expected := 0
	for e in v.slip.enchantments:
		expected += ShopActions.cost_of(
			ShopActions.stones_for(e, day.counter.catalogue), day.counter.catalogue
		)
	ShopActions.carve_commission(day.counter, c)
	assert_eq(day.player.money, 1000 - expected, "carving from empty costs the stones' price")
	assert_eq(day.player.material_inventory.size(), 0, "every stone bought went into the item")


func test_an_unfinished_job_pays_a_share() -> void:
	var day := _make_day()
	var v: CustomerVisit = null
	while day.counter.current_visit() != null:
		var next := day.counter.current_visit()
		if next.slip.enchantments.size() > 1:
			v = next
			day.counter.accept()
			break
		day.counter.refuse()
	if v == null:
		pending("No day-1 customer asks for more than one enchantment")
		return
	var c := _commission_for(day, v)
	day.player.money = 1000
	var board := InscriptionBoard.new(c.item, day.player)
	AutoCarver.new(board, ShopActions.by_price(day.counter.catalogue)).carve(v.slip.enchantments[0])
	var money_before := day.player.money
	_next_day(day)
	day.counter.hand_back()
	var share := v.slip.payment / v.slip.enchantments.size()
	assert_eq(day.player.money, money_before + share, "they pay for the one enchantment done")


func test_nothing_carved_pays_nothing() -> void:
	var day := _make_day()
	var v := _accept_next_legal(day)
	var c := _commission_for(day, v)
	var money_before := day.player.money
	_next_day(day)
	assert_eq(day.counter.current_return(), c, "they come back anyway")
	day.counter.hand_back()
	assert_eq(day.player.money, money_before, "they leave without paying")
	assert_true(c.collected, "and take their item")


func test_three_demo_days_balance_the_books() -> void:
	var day := _make_day()
	day.player.money = 1000
	var start := day.player.money
	var spent := 0
	var paid := 0
	var carved: Array[Commission] = []
	for d in 3:
		while day.counter.current_return() != null:
			var back := day.counter.current_return()
			day.counter.hand_back()
			paid += back.paid
		while _accept_next_legal(day) != null:
			pass
		for c in day.player.commissions:
			if c.collected or c in carved:
				continue
			var before := day.player.money
			ShopActions.carve_commission(day.counter, c)
			spent += before - day.player.money
			carved.append(c)
		_next_day(day)
	while day.counter.current_return() != null:
		var back := day.counter.current_return()
		day.counter.hand_back()
		paid += back.paid
	assert_gt(carved.size(), 0, "some commissions were taken on")
	assert_eq(day.player.money, start - spent + paid, "money is the start, less stones, plus pay")
	for c in carved:
		assert_true(c.collected, "%s collected their item" % c.visit.slip.customer_name)
