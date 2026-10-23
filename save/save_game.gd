class_name SaveGame
extends Resource

## One saved run: the player and where the day stood when it was saved. Definitions (items,
## enchantments, materials, customers) are saved as references to their files; everything the
## player changed is saved inside this resource.

## Bump when a change makes older saves unreadable. Saves from another version aren't loaded.
const FORMAT_VERSION := 1

## Set on writing. It defaults to 0 so that it is always written out.
@export var format_version: int = 0
## When it was saved, as the system's local date and time
@export var saved_at: String = ""
## The day, counting from 1
@export var day_number: int = 1
@export var side: Day.ShopSide = Day.ShopSide.COUNTER
@export var counter_seconds_left: float = 0.0
@export var inscribing_seconds_left: float = 0.0
@export var player: Player
## Today's calls at the counter so far
@export var decisions: Array[CounterDecision] = []
## Commissions collected today so far
@export var collections: Array[Commission] = []


## A line for the main menu, such as "Day 3, saved 2026-10-20 23:41"
func summary() -> String:
	return "Day %d, saved %s" % [day_number, saved_at.replace("T", " ").left(16)]
