class_name ShopActions
extends RefCounted

## Test and bot helper: the shop-loop moves a player makes between the counter and the table,
## done through the game's own Counter, Player and InscriptionBoard. It buys stones from the
## supplier, cheapest first, and carves with AutoCarver.


## The supplier's materials, cheapest first
static func by_price(catalogue: SupplierCatalogue) -> Array[EnchantmentMaterialDefinition]:
	var out := catalogue.materials()
	out.sort_custom(func(a, b): return catalogue.price_of(a) < catalogue.price_of(b))
	return out


## The cheapest stone the supplier sells for each node of `e` ({material: count}), or an empty
## dictionary if some node takes nothing the supplier sells
static func stones_for(
	e: Enchantment, catalogue: SupplierCatalogue
) -> Dictionary[EnchantmentMaterialDefinition, int]:
	var out: Dictionary[EnchantmentMaterialDefinition, int] = {}
	for node in e.nodes:
		var found: EnchantmentMaterialDefinition = null
		for m in by_price(catalogue):
			if node.accepts(m):
				found = m
				break
		if found == null:
			return {} as Dictionary[EnchantmentMaterialDefinition, int]
		out[found] = out.get(found, 0) + 1
	return out


## What buying `stones` from scratch costs
static func cost_of(
	stones: Dictionary[EnchantmentMaterialDefinition, int], catalogue: SupplierCatalogue
) -> int:
	var total := 0
	for m in stones:
		total += catalogue.price_of(m) * stones[m]
	return total


## Buys whatever the player lacks of `stones` at the counter; returns whether they now have all
## of them. It stops at the first stone they can't afford.
static func top_up(
	counter: Counter, stones: Dictionary[EnchantmentMaterialDefinition, int]
) -> bool:
	for m in stones:
		while counter.player.get_material_count(m) < stones[m]:
			if not counter.buy(m):
				return false
	return true


## Buys the stones for, then carves, the enchantments on the commission's slip, in the order
## that fits the most of them on the item. Returns how many it carved; it stops at the first it
## can't afford or fit.
static func carve_commission(counter: Counter, c: Commission) -> int:
	var preferred := by_price(counter.catalogue)
	var board := InscriptionBoard.new(c.item, counter.player)
	var carver := AutoCarver.new(board, preferred)
	var done := 0
	for e in AutoCarver.best_order(c.item, c.visit.slip.enchantments, preferred):
		if not top_up(counter, stones_for(e, counter.catalogue)):
			break
		if carver.carve(e) == null:
			break
		done += 1
	return done
