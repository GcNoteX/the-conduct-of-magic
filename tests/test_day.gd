extends Node

"""
Headless checks for the day: which side is active, freezing the other side, items handed
over from the counter, the demo rulebook, customers collecting and paying, and the supplier.
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
	test_dev_end_side()
	test_payout_scales_with_enchantments_done()
	test_customer_collects_and_pays()
	test_supplier()
	test_counter_buttons_take_no_focus()
	test_dev_hint_names_the_bound_keys()
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
		day.table._item_picker.item_count == day.player.items.size(),
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


func test_dev_end_side() -> void:
	var day := _make_day([_plan(10.0, 0.0)])
	for n in [1, 2, 3]:
		check(
			day.day_number == n and day.side == Day.ShopSide.COUNTER,
			"day %d opens at the counter" % n
		)
		day.end_side()
		check(
			day.side == Day.ShopSide.INSCRIBING, "F3 at the counter goes to the table on day %d" % n
		)
		check(not day.is_day_over(), "F3 at the counter doesn't end day %d" % n)
		day.end_side()
		check(day.is_day_over(), "F3 at the table ends day %d" % n)
		day.start_next_day()
	day.queue_free()


## Commits a placement of each enchantment on the item, as if carved at the table
func _carve(inst: ItemInstance, carved: Array[Enchantment]) -> void:
	if inst.enchantment_graph_state == null:
		inst.enchantment_graph_state = GraphState.new()
	for e in carved:
		var p := PlacementState.new()
		p.enchantment = e
		p.materials.resize(e.nodes.size())
		p.committed = true
		inst.enchantment_graph_state.placements.append(p)


func test_payout_scales_with_enchantments_done() -> void:
	var glow: Enchantment = load("res://enchantments/patterns/glow.tres")
	var ward: Enchantment = load("res://enchantments/patterns/ward.tres")
	var keen: Enchantment = load("res://enchantments/patterns/keen.tres")
	var visit := CustomerVisit.new()
	visit.slip = CommissionSlip.new()
	visit.slip.enchantments = [glow, ward, keen]
	visit.slip.payment = 100
	var inst := ItemInstance.new()
	var c := Commission.create(visit, inst, 1)
	check(c.payout() == 0, "nothing carved pays nothing")
	_carve(inst, [ward])
	check(c.fulfilled() == [false, true, false], "only the carved enchantment counts")
	check(c.payout() == 33, "one of three pays a third, rounded down")
	var draft := PlacementState.new()
	draft.enchantment = glow
	inst.enchantment_graph_state.placements.append(draft)
	check(c.payout() == 33, "a planned but uncommitted enchantment doesn't count")
	_carve(inst, [glow, keen])
	check(c.payout() == 100, "all three pays the full offer")
	visit.slip.enchantments = [glow, glow]
	check(c.fulfilled_count() == 1, "each carving fulfils only one request")
	check(not c.is_due(1) and c.is_due(2), "the customer comes back on a later day")


func test_customer_collects_and_pays() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	var elsa := day.counter.current_visit()
	day.counter.accept()
	check(day.player.commissions.size() == 1, "accepting records a commission")
	var c := day.player.commissions[0]
	check(c.visit == elsa and c.item in day.player.items, "the commission holds Elsa's item")
	var wanted := elsa.slip.enchantments.size()
	check(wanted == 2, "Elsa wants two enchantments")
	day.switch_to(Day.ShopSide.INSCRIBING)
	day.table._open_item(day.player.items.find(c.item))
	_carve(c.item, [elsa.slip.enchantments[0]])
	# A half-planned second enchantment holds a material taken from the player
	var spare: EnchantmentMaterialDefinition = day.player.material_inventory.keys()[0]
	var spare_count := day.player.get_material_count(spare)
	day.player.remove_material(spare)
	var draft := PlacementState.new()
	draft.enchantment = elsa.slip.enchantments[1]
	draft.materials = [spare]
	c.item.enchantment_graph_state.placements.append(draft)
	var money := day.player.money
	day.end_side()
	day.start_next_day()
	check(day.counter.current_return() == c, "Elsa is first at the counter the next day")
	check(day.counter.current_visit() == null, "new customers wait behind collectors")
	day.counter.hand_back()
	var share := elsa.slip.payment / wanted
	check(day.player.money == money + share, "she pays for one of two enchantments")
	check(c.collected and c.paid == share, "the commission is marked collected and paid")
	check(c.item not in day.player.items, "her item leaves with her")
	check(
		day.player.get_material_count(spare) == spare_count,
		"materials planned on her item stay in the shop"
	)
	check(draft not in c.item.enchantment_graph_state.placements, "her item leaves without drafts")
	check(day.counter.collections == [c], "the counter remembers the collection")
	check(day.counter.current_visit() != null, "then the day's new customers step up")
	day.switch_to(Day.ShopSide.INSCRIBING)
	check(day.table.board == null or day.table.board.item != c.item, "the table drops her item")
	check(
		day.table._item_picker.item_count == day.player.items.size(),
		"the table lists only the items still in the shop"
	)
	day.end_side()
	day.start_next_day()
	check(day.counter.current_return() == null, "a collected commission doesn't come back")
	day.queue_free()


func test_supplier() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	var yellow: EnchantmentMaterialDefinition = load(
		"res://items/enchantment_materials/yellow_stone/yellow_stone.tres"
	)
	var price := day.counter.catalogue.price_of(yellow)
	check(price > 0, "the supplier sells Yellow stone")
	var money := day.player.money
	var count := day.player.get_material_count(yellow)
	check(day.counter.buy(yellow), "the player can afford a stone")
	check(day.player.money == money - price, "buying takes the price")
	check(day.player.get_material_count(yellow) == count + 1, "the stone joins the materials")
	day.player.money = price - 1
	check(not day.counter.buy(yellow), "a stone the player can't afford isn't sold")
	check(day.player.money == price - 1, "a failed purchase costs nothing")
	check(day.player.get_material_count(yellow) == count + 1, "and adds nothing")
	day.queue_free()


## A focused button would take Space or Enter, accepting the next customer or buying again
func test_counter_buttons_take_no_focus() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	var buttons := day.counter.find_children("*", "Button", true, false)
	check(not buttons.is_empty(), "the counter has buttons")
	for b in buttons:
		check(
			(b as Button).focus_mode == Control.FOCUS_NONE,
			"the counter's %s button can't take focus" % (b as Button).text
		)
	day.queue_free()


func test_dev_hint_names_the_bound_keys() -> void:
	var day := _make_day([_plan(10.0, 20.0)])
	if OS.is_debug_build():
		var hint := day._clock_label.text
		check(hint.contains("F2 switches sides"), "the dev hint names the switch key")
		check(hint.contains("F3 ends this side"), "the dev hint names the end-side key")
	day.queue_free()
