class_name Commission
extends Resource

## A commission the player accepted: the customer's visit and the item left with the shop.
## The customer comes back on a later day to collect it and pays for each enchantment carved.

## How far along one requested enchantment is on the item
enum Progress { MISSING, PLANNED, DONE }

@export var visit: CustomerVisit
@export var item: ItemInstance
## The day the commission was accepted, counting from 1
@export var accepted_day: int = 1
@export var collected: bool = false
## What the customer paid on collecting it
@export var paid: int = 0


static func create(v: CustomerVisit, inst: ItemInstance, day_number: int) -> Commission:
	var c := Commission.new()
	c.visit = v
	c.item = inst
	c.accepted_day = day_number
	return c


## The customer is back to collect on this day
func is_due(day_number: int) -> bool:
	return not collected and day_number > accepted_day


## Whether each enchantment on the slip is committed on the item, in slip order. Each committed
## placement fulfils at most one request, so asking for Glow twice needs two Glows.
func fulfilled() -> Array[bool]:
	var used: Array[PlacementState] = []
	var out: Array[bool] = []
	var placements: Array[PlacementState] = []
	if item.enchantment_graph_state != null:
		placements = item.enchantment_graph_state.placements
	for wanted in visit.slip.enchantments:
		var found := false
		for p in placements:
			if p.committed and p.enchantment == wanted and p not in used:
				used.append(p)
				found = true
				break
		out.append(found)
	return out


## Each requested enchantment's progress, in slip order: committed, only planned, or neither
func progress() -> Array[Progress]:
	var done := fulfilled()
	var used: Array[PlacementState] = []
	var out: Array[Progress] = []
	var placements: Array[PlacementState] = []
	if item.enchantment_graph_state != null:
		placements = item.enchantment_graph_state.placements
	for i in done.size():
		if done[i]:
			out.append(Progress.DONE)
			continue
		var wanted := visit.slip.enchantments[i]
		var state := Progress.MISSING
		for p in placements:
			if not p.committed and p.enchantment == wanted and p not in used:
				used.append(p)
				state = Progress.PLANNED
				break
		out.append(state)
	return out


func fulfilled_count() -> int:
	return fulfilled().count(true)


## The offer scaled by the share of enchantments done, rounded down
func payout() -> int:
	var wanted := visit.slip.enchantments.size()
	if wanted == 0:
		return 0
	return visit.slip.payment * fulfilled_count() / wanted


## Hands the item back to the customer, who pays the payout; returns what they paid. Materials
## still planned on the item go back to the player rather than leaving with it.
func collect(player: Player) -> int:
	paid = payout()
	collected = true
	player.money += paid
	if item.enchantment_graph_state != null:
		var held := item.enchantment_graph_state.drop_plans()
		for m in held:
			player.add_material(m, held[m])
	player.items.erase(item)
	return paid
