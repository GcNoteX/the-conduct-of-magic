extends GutTest

## The money rules: every job pays more than its stones cost, and money can't go below zero
## without the game refusing the spend. Reads the demo customers, supplier and setup as they
## ship, so a price or offer change that breaks this shows up here.

const DAY_SCENE := preload("res://day/day.tscn")
const CATALOGUE := preload("res://counter/supplier/demo_catalogue.tres")
const SETUP := preload("res://inscribing/demo/demo_setup.tres")


func _visits() -> Array[CustomerVisit]:
	var counter: Counter = autofree(DAY_SCENE.instantiate()).get_node("Sides/Counter")
	return counter.visits


func _job_cost(v: CustomerVisit) -> int:
	var total := 0
	for e in v.slip.enchantments:
		var stones := ShopActions.stones_for(e, CATALOGUE)
		if stones.is_empty():
			return -1
		total += ShopActions.cost_of(stones, CATALOGUE)
	return total


func test_every_price_is_positive() -> void:
	for m in CATALOGUE.materials():
		assert_gt(CATALOGUE.price_of(m), 0, "%s has a price" % InscriptionBoard.material_name(m))


func test_the_supplier_sells_a_stone_for_every_node() -> void:
	for e in SETUP.enchantments:
		assert_false(
			ShopActions.stones_for(e, CATALOGUE).is_empty(),
			"every node of %s takes a stone the supplier sells" % e.enchantment_name
		)


func test_every_job_pays_more_than_its_stones() -> void:
	var visits := _visits()
	assert_gt(visits.size(), 0, "there are demo customers")
	for v in visits:
		var cost := _job_cost(v)
		var who := "%s (%s)" % [v.slip.customer_name, v.slip.enchantment_names()]
		assert_gt(cost, 0, "%s: the stones can be bought" % who)
		assert_gt(
			v.slip.payment, cost, "%s pays %dg for %dg of stones" % [who, v.slip.payment, cost]
		)


func test_each_enchantment_pays_for_its_own_stones() -> void:
	# A part-done job pays an equal share per enchantment, so each share has to cover its stones
	for v in _visits():
		var share := v.slip.payment / maxi(v.slip.enchantments.size(), 1)
		for e in v.slip.enchantments:
			var cost := ShopActions.cost_of(ShopActions.stones_for(e, CATALOGUE), CATALOGUE)
			assert_true(
				share >= cost,
				(
					"%s's %s: a %dg share covers %dg of stones"
					% [v.slip.customer_name, e.enchantment_name, share, cost]
				)
			)


func test_starting_money_buys_the_first_job() -> void:
	var cheapest := -1
	for v in _visits():
		if v.day == 1:
			var cost := _job_cost(v)
			cheapest = cost if cheapest < 0 else mini(cheapest, cost)
	assert_true(cheapest >= 0, "someone comes on day 1")
	var stock_value := 0
	for m in SETUP.materials:
		stock_value += CATALOGUE.price_of(m) * SETUP.materials[m]
	assert_true(
		SETUP.money + stock_value >= cheapest,
		(
			"starting money and stones (%dg) cover the cheapest day-1 job (%dg)"
			% [SETUP.money + stock_value, cheapest]
		)
	)


func test_spending_more_than_you_have_is_refused() -> void:
	var p := Player.new()
	p.money = 10
	assert_false(p.spend(11), "spending past zero is refused")
	assert_eq(p.money, 10, "a refused spend costs nothing")
	assert_true(p.spend(10), "spending down to zero is fine")
	assert_eq(p.money, 0)
	assert_false(p.spend(1), "nothing more can be spent at zero")
	assert_eq(p.money, 0)


func test_the_supplier_never_sells_on_credit() -> void:
	var day: Day = DAY_SCENE.instantiate()
	add_child_autofree(day)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var stock := CATALOGUE.materials()
	for i in 300:
		var m: EnchantmentMaterialDefinition = stock[rng.randi_range(0, stock.size() - 1)]
		var money := day.player.money
		var count := day.player.get_material_count(m)
		var sold := day.counter.buy(m)
		assert_eq(sold, money >= CATALOGUE.price_of(m), "a sale happens exactly when affordable")
		if sold:
			assert_eq(day.player.money, money - CATALOGUE.price_of(m), "a sale takes the price")
			assert_eq(day.player.get_material_count(m), count + 1, "and gives the stone")
		else:
			assert_eq(day.player.money, money, "a refused sale costs nothing")
			assert_eq(day.player.get_material_count(m), count, "and gives nothing")
		assert_true(day.player.money >= 0, "money never goes below zero")
		if i % 50 == 49:
			day.player.money += rng.randi_range(0, 60)


func test_a_collection_never_takes_money() -> void:
	for v in _visits():
		var c := Commission.create(v, ItemInstance.new(), 1)
		c.item.definition = v.slip.item
		var p := Player.new()
		assert_eq(c.collect(p), 0, "an uncarved %s pays nothing" % v.slip.customer_name)
		assert_eq(p.money, 0, "and takes nothing")
