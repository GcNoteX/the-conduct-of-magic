class_name BotPlayer
extends RefCounted

## Plays the real day scene the way a player would, with no one watching, for as many days as
## asked, and writes down what went wrong in a BotReport. Each day it serves everyone at the
## counter, carves the accepted jobs at the table (buying stones as it goes), and ends the day.
## Most of the time it plays sensibly: it follows the rulebook, takes only jobs that fit and
## that it can afford, and carves them in full. With `randomness` it sometimes doesn't: it
## accepts or refuses on a coin flip, buys stones it doesn't need, or skips carving.
## The demo only has customers for its first few days, so after them the bot sends in copies of
## demo customers, with their papers' dates moved along so each stays as legal as it was.

const DAY_SCENE := preload("res://day/day.tscn")
## More customers than this in one day means the counter isn't moving on
const MAX_CUSTOMERS_A_DAY := 50
const MOST_NEW_CUSTOMERS := 4
## Money above this many times the start, at the end of a run, is worth a look
const PILING_UP_FACTOR := 20

var report := BotReport.new()

var _rng := RandomNumberGenerator.new()
var _day: Day
var _pool: Array[CustomerVisit] = []
var _last_pool_day := 0
var _worked: Dictionary[Commission, bool] = {}
var _reported_stuck: Dictionary[Commission, bool] = {}
var _fits_cache: Dictionary[String, int] = {}
var _errors := ErrorWatch.new()
var _errors_seen := 0
var _shop_items: Array[ItemInstance] = []


func _init(run_seed: int, randomness: float) -> void:
	report.run_seed = run_seed
	report.randomness = randomness
	_rng.seed = run_seed


## Plays `days` days on a fresh day scene added under `host`, then frees it. A frame passes
## after each day, so call it with await.
func play(host: Node, days: int) -> BotReport:
	report.days_planned = days
	OS.add_logger(_errors)
	_day = DAY_SCENE.instantiate()
	var plan := DayPlan.new()
	plan.counter_seconds = 60.0
	plan.inscribing_seconds = 60.0
	_day.schedule = DaySchedule.new()
	_day.schedule.days = [plan]
	host.add_child(_day)
	_pool = _day.counter.visits.duplicate()
	for v in _pool:
		_last_pool_day = maxi(_last_pool_day, v.day)
	_shop_items = _day.player.items.duplicate()
	report.start_money = _day.player.money
	for d in days:
		var ok := _play_day()
		# Let a frame pass, as the game would, so the nodes the UI freed are really freed
		await host.get_tree().process_frame
		_check_errors()
		if not ok:
			break
		report.days_played += 1
	OS.remove_logger(_errors)
	_add_notes()
	host.remove_child(_day)
	_day.free()
	return report


func _chance(p: float) -> bool:
	return _rng.randf() < p


## One whole day; returns false if the run can't go on
func _play_day() -> bool:
	var today := _day.day_number
	if not _serve_counter(today):
		return false
	_check_collections(today)
	_day.end_side()
	if _day.side == Day.ShopSide.INSCRIBING and not _day.is_day_over():
		_work_table()
		_day.end_side()
	if not _day.is_day_over():
		report.add_problem(
			today, BotReport.Kind.SOFTLOCK, "The day didn't end when its time ran out"
		)
		return false
	_check_rules(today)
	report.money_by_day.append(_day.player.money)
	_send_customers(today + 1)
	_day.start_next_day()
	if _day.day_number != today + 1 or _day.is_day_over():
		report.add_problem(today, BotReport.Kind.SOFTLOCK, "The next day didn't start")
		return false
	return true


func _serve_counter(today: int) -> bool:
	var counter := _day.counter
	var served := 0
	while counter.current_return() != null or counter.current_visit() != null:
		if served >= MAX_CUSTOMERS_A_DAY:
			report.add_problem(
				today,
				BotReport.Kind.SOFTLOCK,
				"The counter still had someone waiting after %d customers" % served
			)
			return false
		served += 1
		var back := counter.current_return()
		if back != null:
			counter.hand_back()
			report.paid_in += back.paid
			if counter.current_return() == back:
				report.add_problem(
					today, BotReport.Kind.SOFTLOCK, "%s stayed after collecting" % _who(back.visit)
				)
				return false
		else:
			_decide(counter.current_visit(), today)
		if _chance(report.randomness * 0.3):
			_buy_something()
	return true


func _decide(v: CustomerVisit, today: int) -> void:
	for e in v.slip.enchantments:
		BotReport.bump(report.requested, e.enchantment_name)
	var legal := _day.counter.rulebook.problems(v, today).is_empty()
	var fits := _fits(v)
	var accept := legal and fits and _job_cost(v) <= _day.player.money + _stock_value()
	if _chance(report.randomness):
		accept = _chance(0.5)
	elif legal and not fits:
		report.refused_unfit += 1
	if accept:
		report.accepted += 1
		if not legal:
			report.accepted_against_rules += 1
		_day.counter.accept()
	else:
		report.refused += 1
		if legal:
			report.refused_within_rules += 1
		_day.counter.refuse()
	if _day.counter.current_visit() == v:
		report.add_problem(today, BotReport.Kind.SOFTLOCK, "%s stayed after a decision" % _who(v))


func _buy_something() -> void:
	var stock := _day.counter.catalogue.materials()
	var m: EnchantmentMaterialDefinition = stock[_rng.randi_range(0, stock.size() - 1)]
	var money := _day.player.money
	if _day.counter.buy(m):
		report.spent_on_stones += money - _day.player.money
		BotReport.bump(report.bought, InscriptionBoard.material_name(m))


func _work_table() -> void:
	for c in _day.player.commissions:
		if c.collected or _worked.has(c):
			continue
		_worked[c] = true
		if _chance(report.randomness * 0.5):
			continue
		_carve(c)


## Carves the commission's job, buying the stones each enchantment needs first
func _carve(c: Commission) -> void:
	var catalogue := _day.counter.catalogue
	var preferred := ShopActions.by_price(catalogue)
	var wanted := c.visit.slip.enchantments
	var order := AutoCarver.best_order(c.item, wanted, preferred)
	for e in wanted:
		if e not in order:
			BotReport.bump(report.unfit, "%s on the %s" % [e.enchantment_name, _item_name(c)])
	var carver := AutoCarver.new(InscriptionBoard.new(c.item, _day.player), preferred)
	for e in order:
		var stones := ShopActions.stones_for(e, catalogue)
		var money := _day.player.money
		var before: Dictionary[EnchantmentMaterialDefinition, int] = {}
		for m in stones:
			before[m] = _day.player.get_material_count(m)
		var afforded := ShopActions.top_up(_day.counter, stones)
		report.spent_on_stones += money - _day.player.money
		for m in stones:
			var got := _day.player.get_material_count(m) - before[m]
			if got > 0:
				BotReport.bump(report.bought, InscriptionBoard.material_name(m), got)
		if not afforded:
			report.jobs_unaffordable += 1
			return
		if carver.carve(e) == null:
			BotReport.bump(report.unfit, "%s on the %s" % [e.enchantment_name, _item_name(c)])
			return
		BotReport.bump(report.carved, e.enchantment_name)


## Whether the whole job fits on a fresh copy of the customer's item
func _fits(v: CustomerVisit) -> bool:
	var names: Array[String] = []
	for e in v.slip.enchantments:
		names.append(e.resource_path)
	var key := "%s|%s" % [v.slip.item.resource_path, ",".join(names)]
	if not _fits_cache.has(key):
		var inst := ItemInstance.new()
		inst.definition = v.slip.item
		var preferred := ShopActions.by_price(_day.counter.catalogue)
		_fits_cache[key] = AutoCarver.best_order(inst, v.slip.enchantments, preferred).size()
	return _fits_cache[key] == v.slip.enchantments.size()


func _job_cost(v: CustomerVisit) -> int:
	var total := 0
	for e in v.slip.enchantments:
		var stones := ShopActions.stones_for(e, _day.counter.catalogue)
		total += ShopActions.cost_of(stones, _day.counter.catalogue)
	return total


func _stock_value() -> int:
	var total := 0
	for m in _day.player.material_inventory:
		total += _day.counter.catalogue.price_of(m) * _day.player.material_inventory[m]
	return total


## Customers collect the day after they were accepted. Anyone still waiting after that was
## turned away or forgotten.
func _check_collections(today: int) -> void:
	for c in _day.player.commissions:
		if not c.collected and c.accepted_day < today and not _reported_stuck.has(c):
			_reported_stuck[c] = true
			report.add_problem(
				today,
				BotReport.Kind.STUCK_CUSTOMER,
				"%s, accepted on day %d, didn't collect" % [_who(c.visit), c.accepted_day]
			)


## The rules that should hold at the end of every day
func _check_rules(today: int) -> void:
	var p := _day.player
	if p.money < 0:
		report.add_problem(today, BotReport.Kind.BROKEN_RULE, "Money is %dg" % p.money)
	var ids: Array[StringName] = []
	for inst in p.items:
		if inst.id in ids:
			report.add_problem(
				today, BotReport.Kind.BROKEN_RULE, "Two items share the id %s" % inst.id
			)
		ids.append(inst.id)
	for c in p.commissions:
		var held := c.item in p.items
		if c.collected and held:
			report.add_problem(
				today, BotReport.Kind.BROKEN_RULE, "%s's item is still in the shop" % _who(c.visit)
			)
		elif not c.collected and not held:
			report.add_problem(
				today, BotReport.Kind.BROKEN_RULE, "%s's item went missing" % _who(c.visit)
			)
	for m in p.material_inventory:
		if p.material_inventory[m] <= 0:
			report.add_problem(
				today,
				BotReport.Kind.BROKEN_RULE,
				(
					"%s shows %d in stock"
					% [InscriptionBoard.material_name(m), p.material_inventory[m]]
				)
			)
	for inst in _shop_items:
		if inst not in p.items:
			report.add_problem(
				today,
				BotReport.Kind.BROKEN_RULE,
				"The shop's own %s went missing" % InscriptionBoard.item_name(inst)
			)
			_shop_items.erase(inst)
			break


func _check_errors() -> void:
	var now := _errors.count()
	if now == _errors_seen:
		return
	var first := _errors.first_errors()
	var text := "%d error(s) logged" % (now - _errors_seen)
	if _errors_seen < first.size():
		text += ", first: " + first[_errors_seen]
	report.add_problem(_day.day_number, BotReport.Kind.ERROR, text)
	_errors_seen = now


## Copies of demo customers for a day past the demo's own, papers moved along with them
func _send_customers(day_number: int) -> void:
	if day_number <= _last_pool_day:
		return
	for i in _rng.randi_range(1, MOST_NEW_CUSTOMERS):
		var original := _pool[_rng.randi_range(0, _pool.size() - 1)]
		var shift := day_number - original.day
		var v: CustomerVisit = original.duplicate()
		v.day = day_number
		if original.adventurer_id:
			v.adventurer_id = original.adventurer_id.duplicate()
			v.adventurer_id.expires_day += shift
		if original.permit:
			v.permit = original.permit.duplicate()
			v.permit.expires_day += shift
		_day.counter.visits.append(v)


func _add_notes() -> void:
	var cheapest := -1
	for m in _day.counter.catalogue.materials():
		var price := _day.counter.catalogue.price_of(m)
		cheapest = price if cheapest < 0 else mini(cheapest, price)
	for d in report.money_by_day.size():
		if report.money_by_day[d] < cheapest:
			report.notes.append(
				"Money fell below the cheapest stone (%dg) on day %d" % [cheapest, d + 1]
			)
			break
	if report.jobs_unaffordable > 0:
		report.notes.append(
			"%d accepted jobs couldn't be finished for lack of money" % report.jobs_unaffordable
		)
	var start := maxi(report.start_money, 1)
	if report.final_money() > start * PILING_UP_FACTOR:
		var n := report.money_by_day.size()
		var recent := mini(n - 1, 30)
		var per_day := 0.0
		if recent > 0:
			per_day = (
				float(report.money_by_day[n - 1] - report.money_by_day[n - 1 - recent]) / recent
			)
		report.notes.append(
			(
				"Money piled up to %dg, %d× the start, still gaining about %dg a day"
				% [report.final_money(), report.final_money() / start, roundi(per_day)]
			)
		)
	for e in _day.setup.enchantments:
		if report.requested.get(e.enchantment_name, 0) == 0:
			report.notes.append("No customer ever asked for %s" % e.enchantment_name)
		elif report.carved.get(e.enchantment_name, 0) == 0:
			report.notes.append("%s was asked for but never carved" % e.enchantment_name)
	for m in _day.counter.catalogue.materials():
		if report.bought.get(InscriptionBoard.material_name(m), 0) == 0:
			report.notes.append("No %s was ever bought" % InscriptionBoard.material_name(m))
	for k in report.unfit:
		report.notes.append("%s couldn't be fitted (%d tries)" % [k, report.unfit[k]])


func _who(v: CustomerVisit) -> String:
	return v.slip.customer_name


func _item_name(c: Commission) -> String:
	return c.visit.slip.item.display_name
