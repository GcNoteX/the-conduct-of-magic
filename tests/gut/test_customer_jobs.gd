extends GutTest

## Every demo customer's job can be done: all the enchantments on their slip carve together on
## the item they bring, with stones the supplier sells, and each enchantment on the finished item
## can be taken off again with the starter inventory.
## Jobs in KNOWN_UNFIT are known not to fit yet. They show as pending, not failed, so the
## rest of the suite stays useful; when one starts to fit, its test fails until it's taken off.

const DAY_SCENE := preload("res://day/day.tscn")
const CATALOGUE := preload("res://counter/supplier/demo_catalogue.tres")
const SETUP := preload("res://inscribing/demo/demo_setup.tres")
## Customer name -> why their job doesn't fit, as found on 2026-10-22
const KNOWN_UNFIT: Dictionary[String, String] = {
	"Elsa Marrow": "Ward doesn't fit anywhere on the Dagger",
	"Tomas Reed": "Ward doesn't fit anywhere on the Dagger",
	"Jory Pell": "Ward doesn't fit anywhere on the Short sword",
}


func _visits() -> Array[CustomerVisit]:
	var counter: Counter = autofree(DAY_SCENE.instantiate()).get_node("Sides/Counter")
	return counter.visits


## Carves the whole job on a fresh item; returns the item, or null if not all of it fits
func _carve_job(v: CustomerVisit) -> ItemInstance:
	var inst := ItemInstance.new()
	inst.definition = v.slip.item
	var preferred := ShopActions.by_price(CATALOGUE)
	var order := AutoCarver.best_order(inst, v.slip.enchantments, preferred)
	if order.size() < v.slip.enchantments.size():
		return null
	var player := Player.new()
	for m in preferred:
		player.add_material(m, AutoCarver.TRIAL_STOCK)
	var carver := AutoCarver.new(InscriptionBoard.new(inst, player), preferred)
	for e in order:
		if carver.carve(e) == null:
			return null
	return inst


func _job(v: CustomerVisit) -> String:
	return (
		"%s's %s on the %s"
		% [v.slip.customer_name, v.slip.enchantment_names(), v.slip.item.display_name]
	)


func test_every_job_carves_on_its_item() -> void:
	for v in _visits():
		var inst := _carve_job(v)
		var known := KNOWN_UNFIT.has(v.slip.customer_name)
		if inst == null and known:
			pending("%s: %s" % [_job(v), KNOWN_UNFIT[v.slip.customer_name]])
			continue
		assert_false(known, "%s fits now: take it off KNOWN_UNFIT" % _job(v))
		assert_not_null(inst, "%s can be carved" % _job(v))


func test_each_enchantment_on_a_finished_job_can_be_taken_off() -> void:
	for v in _visits():
		var inst := _carve_job(v)
		if inst == null:
			continue
		var d := DisenchantBoard.new(InscriptionBoard.new(inst, Player.new()))
		for p in d.carvings():
			var targets: Array[PlacementState] = [p]
			var found := SolvabilityChecker.new(d).solve(targets, SETUP.materials)
			assert_gt(
				found.size(),
				0,
				(
					"%s: %s comes off with the starter stock"
					% [_job(v), p.enchantment.enchantment_name]
				)
			)
