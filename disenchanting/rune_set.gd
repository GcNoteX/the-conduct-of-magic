class_name RuneSet
extends Resource

## A count of each of the four rune types: what a line costs, what a node gives back when it's
## freed, what a material gives when dissolved, or what the player holds while disenchanting.
## Sets are treated as values: plus() and minus() return new sets and never change this one.

enum Rune { WATER, FIRE, WIND, STONE }

const NAMES: Array[String] = ["water", "fire", "wind", "stone"]

@export var water: int = 0
@export var fire: int = 0
@export var wind: int = 0
@export var stone: int = 0


static func of(water_count: int, fire_count: int, wind_count: int, stone_count: int) -> RuneSet:
	var r := RuneSet.new()
	r.water = water_count
	r.fire = fire_count
	r.wind = wind_count
	r.stone = stone_count
	return r


## A copy of `r`, or an empty set when `r` is null
static func copy_of(r: RuneSet) -> RuneSet:
	return RuneSet.new() if r == null else r.plus(null)


func get_count(rune: Rune) -> int:
	match rune:
		Rune.WATER:
			return water
		Rune.FIRE:
			return fire
		Rune.WIND:
			return wind
		_:
			return stone


func to_array() -> Array[int]:
	return [water, fire, wind, stone]


func plus(other: RuneSet) -> RuneSet:
	if other == null:
		return RuneSet.of(water, fire, wind, stone)
	return RuneSet.of(
		water + other.water, fire + other.fire, wind + other.wind, stone + other.stone
	)


func minus(other: RuneSet) -> RuneSet:
	if other == null:
		return plus(null)
	return RuneSet.of(
		water - other.water, fire - other.fire, wind - other.wind, stone - other.stone
	)


## Whether this set holds at least `cost` of every rune type
func covers(cost: RuneSet) -> bool:
	if cost == null:
		return true
	return water >= cost.water and fire >= cost.fire and wind >= cost.wind and stone >= cost.stone


## What this set is short of to pay `cost`, as a set of positive counts
func shortfall(cost: RuneSet) -> RuneSet:
	if cost == null:
		return RuneSet.new()
	return RuneSet.of(
		maxi(cost.water - water, 0),
		maxi(cost.fire - fire, 0),
		maxi(cost.wind - wind, 0),
		maxi(cost.stone - stone, 0)
	)


func total() -> int:
	return water + fire + wind + stone


func is_empty() -> bool:
	return water == 0 and fire == 0 and wind == 0 and stone == 0


func equals(other: RuneSet) -> bool:
	return to_array() == RuneSet.copy_of(other).to_array()


## Like "2 fire, 1 stone", or "nothing"
func describe() -> String:
	var parts: Array[String] = []
	var counts := to_array()
	for i in counts.size():
		if counts[i] != 0:
			parts.append("%d %s" % [counts[i], NAMES[i]])
	return ", ".join(parts) if not parts.is_empty() else "nothing"
