class_name EconomySim
extends RefCounted

## Plays the shop loop for many days without any UI, to see whether prices and payouts work.
## Each day: customers due back collect and pay, new customers walk in and are accepted or
## refused, and at night the player carves as many enchantments as their stamina allows,
## buying any stones they lack. Rent is paid at the end of each week.
## It uses the game's own Player, Commission, Rulebook and SupplierCatalogue, so the money
## rules are the real ones; only the carving itself is abstracted to a dice roll.

enum Policy { ACCEPT_ALL_LEGAL, ACCEPT_WHAT_FITS }

const POLICY_NAMES: Dictionary[Policy, String] = {
	Policy.ACCEPT_ALL_LEGAL: "Accept every legal customer",
	Policy.ACCEPT_WHAT_FITS: "Accept legal customers that fit tonight",
}


## What happened in one playthrough
class Run:
	extends RefCounted
	## Money at the end of each day, index 0 is day 1
	var money_by_day: Array[int] = []
	var paid_in: int = 0
	## Taken back by customers for enchantments left undone (what-if only)
	var penalties: int = 0
	var spent_on_stones: int = 0
	var rent_paid: int = 0
	var allowance: int = 0
	var rent_misses: int = 0
	## The day the run ended in the running out of money ending, or 0 if it didn't
	var ruined_on_day: int = 0
	var enchantments_requested: int = 0
	var enchantments_delivered: int = 0
	var stamina_available: int = 0
	var stamina_used: int = 0
	var customers_refused_legal: int = 0
	var customers_refused_illegal: int = 0
	var unaffordable_jobs: int = 0

	func final_money() -> int:
		return money_by_day[-1] if not money_by_day.is_empty() else 0


## One enchantment still to carve on a commission
class Job:
	extends RefCounted
	var commission: Commission
	var enchantment: Enchantment
	var value: float


var settings: EconomySimSettings
var policy: Policy
var stamina: int
var weekly_rent: int

var _rng := RandomNumberGenerator.new()
## The customers, with the what-if offer scale applied
var _pool: Array[CustomerVisit] = []
var _player: Player
var _run: Run


func _init(
	with_settings: EconomySimSettings, with_policy: Policy, night_stamina: int, rent: int
) -> void:
	settings = with_settings
	policy = with_policy
	stamina = night_stamina
	weekly_rent = rent
	for v in settings.customers:
		if is_equal_approx(settings.offer_scale, 1.0):
			_pool.append(v)
			continue
		var scaled: CustomerVisit = v.duplicate()
		scaled.slip = v.slip.duplicate()
		scaled.slip.payment = roundi(v.slip.payment * settings.offer_scale)
		_pool.append(scaled)


## Whether the visit passes the rulebook on the day it was written for
func is_legal(visit: CustomerVisit) -> bool:
	return settings.rulebook.problems(visit, visit.day).is_empty()


## The stone to put in a node: the cheapest one in stock that fits, else the cheapest one the
## supplier sells that fits. Null if nothing fits.
func stone_for(
	node: EnchantmentPatternNode, stock: Dictionary[EnchantmentMaterialDefinition, int]
) -> EnchantmentMaterialDefinition:
	var best: EnchantmentMaterialDefinition = null
	for m in stock:
		if stock[m] > 0 and node.accepts(m):
			if best == null or settings.catalogue.price_of(m) < settings.catalogue.price_of(best):
				best = m
	if best != null:
		return best
	for m in settings.catalogue.materials():
		if node.accepts(m):
			if best == null or settings.catalogue.price_of(m) < settings.catalogue.price_of(best):
				best = m
	return best


## The gold it costs to buy every stone for the enchantment from scratch, or -1 if some node
## takes nothing the supplier sells
func stone_cost(enchantment: Enchantment) -> int:
	var empty: Dictionary[EnchantmentMaterialDefinition, int] = {}
	var total := 0
	for node in enchantment.nodes:
		var m := stone_for(node, empty)
		if m == null:
			return -1
		total += settings.catalogue.price_of(m)
	return total


## Plays one run with the given seed
func play(run_seed: int) -> Run:
	_rng.seed = run_seed
	_player = settings.setup.create_player()
	_player.items.clear()
	_run = Run.new()
	for day in range(1, settings.days + 1):
		_collect(day)
		var accepted := _serve_counter(day)
		_carve(accepted)
		if day % settings.days_per_week == 0:
			_settle_week(day)
		_run.money_by_day.append(_player.money)
		if _run.ruined_on_day > 0:
			break
	return _run


func _collect(day: int) -> void:
	for c in _player.commissions:
		if not c.is_due(day):
			continue
		_run.paid_in += c.collect(_player)
		var wanted := c.visit.slip.enchantments.size()
		var undone := wanted - c.fulfilled_count()
		var penalty := roundi(
			settings.undelivered_penalty * undone * c.visit.slip.payment / float(wanted)
		)
		_player.money -= penalty
		_run.penalties += penalty


func _serve_counter(day: int) -> Array[Commission]:
	var accepted: Array[Commission] = []
	var booked := 0
	for i in settings.customers_per_day:
		var template: CustomerVisit = _pool[_rng.randi_range(0, _pool.size() - 1)]
		if not is_legal(template):
			_run.customers_refused_illegal += 1
			continue
		var wanted := template.slip.enchantments.size()
		if policy == Policy.ACCEPT_WHAT_FITS and booked + wanted > stamina:
			_run.customers_refused_legal += 1
			continue
		booked += wanted
		var inst := ItemInstance.new()
		inst.definition = template.slip.item
		inst.id = StringName("%s_d%d_%d" % [template.slip.item.id, day, i])
		inst.enchantment_graph_state = GraphState.new()
		_player.items.append(inst)
		var c := Commission.create(template, inst, day)
		_player.commissions.append(c)
		accepted.append(c)
		_run.enchantments_requested += wanted
	return accepted


func _carve(commissions: Array[Commission]) -> void:
	var jobs: Array[Job] = []
	for c in commissions:
		var share := float(c.visit.slip.payment) / c.visit.slip.enchantments.size()
		for e in c.visit.slip.enchantments:
			var job := Job.new()
			job.commission = c
			job.enchantment = e
			job.value = share - stone_cost(e)
			jobs.append(job)
	jobs.sort_custom(func(a: Job, b: Job) -> bool: return a.value > b.value)
	_run.stamina_available += stamina
	var left := stamina
	for job in jobs:
		if left <= 0:
			break
		var stones := _gather_stones(job.enchantment)
		if stones.is_empty() and not job.enchantment.nodes.is_empty():
			_run.unaffordable_jobs += 1
			continue
		left -= 1
		_run.stamina_used += 1
		if _rng.randf() >= settings.commit_chance:
			for m in stones:
				_player.add_material(m)
			continue
		var p := PlacementState.new()
		p.enchantment = job.enchantment
		p.materials = stones
		p.committed = true
		job.commission.item.enchantment_graph_state.placements.append(p)
		_run.enchantments_delivered += 1


## Takes a stone for each node out of the inventory, buying what's missing. Returns them in
## node order, or an empty array (with nothing taken) if the player can't afford them.
func _gather_stones(enchantment: Enchantment) -> Array[EnchantmentMaterialDefinition]:
	var stock := _player.material_inventory.duplicate()
	var picked: Array[EnchantmentMaterialDefinition] = []
	var to_buy: Dictionary[EnchantmentMaterialDefinition, int] = {}
	var cost := 0
	for node in enchantment.nodes:
		var m := stone_for(node, stock)
		if m == null:
			return [] as Array[EnchantmentMaterialDefinition]
		if stock.get(m, 0) > 0:
			stock[m] -= 1
		else:
			to_buy[m] = to_buy.get(m, 0) + 1
			cost += settings.catalogue.price_of(m)
		picked.append(m)
	if not _player.spend(cost):
		return [] as Array[EnchantmentMaterialDefinition]
	_run.spent_on_stones += cost
	for m in to_buy:
		_player.add_material(m, to_buy[m])
	for m in picked:
		_player.remove_material(m)
	return picked


func _settle_week(day: int) -> void:
	_player.money += settings.weekly_allowance
	_run.allowance += settings.weekly_allowance
	if _player.spend(weekly_rent):
		_run.rent_paid += weekly_rent
		return
	_run.rent_misses += 1
	if _run.rent_misses > settings.rent_misses_allowed:
		_run.ruined_on_day = day
