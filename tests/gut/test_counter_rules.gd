extends GutTest

## Each counter rule on its own, with papers built in the test, so every way a visit can break a
## rule is checked once: missing papers, too low a tier, a permit that doesn't cover the
## enchantment or the customer's kingdom, and papers out of date or in someone else's name.
## Also the rulebook's order of reasons and when a call at the counter counts as right.

const GLOW := preload("res://enchantments/patterns/glow.tres")
const KEEN := preload("res://enchantments/patterns/keen.tres")
const KINDLE := preload("res://enchantments/patterns/kindle.tres")
const DEMO_RULEBOOK := preload("res://counter/demo/demo_rulebook.tres")
const NAME := "Ada Lane"
const KINGDOM := "Varn"


func _visit(wanted: Array[Enchantment]) -> CustomerVisit:
	var v := CustomerVisit.new()
	v.slip = CommissionSlip.new()
	v.slip.customer_name = NAME
	v.slip.kingdom = KINGDOM
	v.slip.enchantments = wanted
	return v


func _id(tier: int, expires_day := 10, holder := NAME) -> AdventurerId:
	var id := AdventurerId.new()
	id.holder_name = holder
	id.tier = tier
	id.kingdom = KINGDOM
	id.expires_day = expires_day
	return id


func _permit(covers: Array[Enchantment], kingdoms: Array[String], expires_day := 10) -> Permit:
	var p := Permit.new()
	p.holder_name = NAME
	p.covers = covers
	p.kingdoms = kingdoms
	p.expires_day = expires_day
	return p


func test_an_id_is_needed_only_for_listed_enchantments() -> void:
	var rule := IdRequiredRule.new()
	rule.enchantments = [KEEN]
	assert_eq(rule.check(_visit([GLOW]), 1), "", "Glow needs no ID")
	assert_eq(rule.check(_visit([GLOW, KEEN]), 1), "No adventurer ID shown for Keen")
	var v := _visit([KEEN])
	v.adventurer_id = _id(1)
	assert_eq(rule.check(v, 1), "", "any ID will do")


func test_the_tier_must_reach_the_minimum() -> void:
	var rule := TierRule.new()
	rule.min_tiers = {KEEN: 2}
	var v := _visit([KEEN])
	assert_eq(rule.check(v, 1), "", "no ID is the ID rule's business, not this one's")
	v.adventurer_id = _id(1)
	assert_eq(rule.check(v, 1), "Keen needs tier 2, but the ID is tier 1")
	v.adventurer_id = _id(2)
	assert_eq(rule.check(v, 1), "", "exactly the minimum tier is enough")
	v.slip.enchantments = [GLOW]
	v.adventurer_id = _id(1)
	assert_eq(rule.check(v, 1), "", "an enchantment with no minimum takes any tier")


func test_a_controlled_enchantment_needs_a_permit_that_fits() -> void:
	var rule := PermitRule.new()
	rule.controlled = [KINDLE]
	assert_eq(rule.check(_visit([GLOW]), 1), "", "an uncontrolled job needs no permit")
	var v := _visit([KINDLE])
	assert_eq(rule.check(v, 1), "No permit shown for Kindle")
	v.permit = _permit([KEEN], [KINGDOM])
	assert_eq(rule.check(v, 1), "The permit doesn't cover Kindle")
	v.permit = _permit([KINDLE], ["Osk"])
	assert_eq(rule.check(v, 1), "The permit isn't valid in Varn")
	v.permit = _permit([KINDLE], ["Osk", KINGDOM])
	assert_eq(rule.check(v, 1), "", "a permit for Kindle valid in Varn is fine")


func test_papers_must_be_in_date_and_in_the_right_name() -> void:
	var rule := PapersValidRule.new()
	assert_eq(rule.check(_visit([GLOW]), 1), "", "no papers, nothing to check")
	var v := _visit([GLOW])
	v.adventurer_id = _id(1, 3)
	assert_eq(rule.check(v, 3), "", "an ID is valid on its last day")
	assert_eq(rule.check(v, 4), "The ID ran out on day 3")
	v.adventurer_id = _id(1, 3, "Ada Lain")
	assert_eq(rule.check(v, 1), "The ID is in the name of Ada Lain", "a near miss still counts")
	v.adventurer_id = null
	v.permit = _permit([KINDLE], [KINGDOM], 2)
	assert_eq(rule.check(v, 2), "", "a permit is valid on its last day")
	assert_eq(rule.check(v, 3), "The permit ran out on day 2")
	v.permit.holder_name = "Bo Lane"
	assert_eq(rule.check(v, 1), "The permit is in the name of Bo Lane")


func test_the_rulebook_lists_every_reason_in_its_order() -> void:
	var v := _visit([KINDLE])
	v.adventurer_id = _id(1, 1)
	assert_eq(
		DEMO_RULEBOOK.problems(v, 2),
		[
			"Kindle needs tier 3, but the ID is tier 1",
			"No permit shown for Kindle",
			"The ID ran out on day 1",
		],
		"tier, then permit, then papers, as the demo rulebook lists them"
	)
	assert_eq(Rulebook.new().problems(v, 2), [], "an empty rulebook allows everything")


func test_a_call_is_right_when_it_agrees_with_the_rulebook() -> void:
	var v := _visit([GLOW])
	var none: Array[String] = []
	var some: Array[String] = ["No permit shown for Kindle"]
	assert_true(CounterDecision.new(v, true, none).is_right(), "accepting a clean job")
	assert_false(CounterDecision.new(v, false, none).is_right(), "refusing a clean job")
	assert_false(CounterDecision.new(v, true, some).is_right(), "accepting a broken one")
	assert_true(CounterDecision.new(v, false, some).is_right(), "refusing a broken one")


func test_a_slip_names_its_enchantments() -> void:
	var slip := CommissionSlip.new()
	assert_eq(slip.enchantment_names(), "", "nothing asked for")
	slip.enchantments = [GLOW]
	assert_eq(slip.enchantment_names(), "Glow")
	slip.enchantments = [GLOW, KEEN]
	assert_eq(slip.enchantment_names(), "Glow and Keen")
	slip.enchantments = [GLOW, KEEN, KINDLE]
	assert_eq(slip.enchantment_names(), "Glow, Keen and Kindle")
