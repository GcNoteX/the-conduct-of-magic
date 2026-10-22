class_name EconomySimSettings
extends Resource

## The knobs for the economy balance sim: what the shop starts with, who walks in, and the
## numbers the design doc hasn't settled yet (stamina, rent, allowance), swept over ranges.

## Starting money and stones
@export var setup: DemoSetup
@export var catalogue: SupplierCatalogue
@export var rulebook: Rulebook
## The pool of customers each day's walk-ins are drawn from. Each keeps the papers it was
## authored with, and whether it is legal is judged on the day it was authored for.
@export var customers: Array[CustomerVisit] = []

@export_group("Runs")
@export var days: int = 28
@export var runs_per_scenario: int = 200
@export var random_seed: int = 1
@export var customers_per_day: int = 3

@export_group("Night")
## Stamina, counted as how many enchantments the player can attempt in one night
@export var enchantments_per_night: Array[int] = [1, 2, 3, 4]
## Chance that an attempted enchantment ends up committed. A miss costs the attempt but the
## stones go back to the inventory.
@export_range(0.0, 1.0) var commit_chance: float = 0.85

@export_group("Rent")
@export var days_per_week: int = 7
## Weekly rents to try, in gold
@export var weekly_rents: Array[int] = [0, 100, 200, 300, 400, 600]
## Gold the parents' letter brings each week, paid in before rent
@export var weekly_allowance: int = 0
## Missed rents that end the run (the running out of money ending)
@export var rent_misses_allowed: int = 1

@export_group("Sensitivity")
## The stamina the sensitivity table holds fixed while it varies customers and skill
@export var sensitivity_stamina: int = 2
@export var sensitivity_customers_per_day: Array[int] = [1, 2, 3, 4]
@export var sensitivity_commit_chances: Array[float] = [0.5, 0.85, 1.0]

@export_group("What if")
## Multiplies every customer's offer. 1.0 is the game as it is.
@export var offer_scale: float = 1.0
## What a customer takes back for each enchantment left undone, as a share of that
## enchantment's part of the offer. 0.0 is the game as it is (they just pay less).
@export_range(0.0, 2.0) var undelivered_penalty: float = 0.0
## Offer scales and penalties the what-if table tries
@export var what_if_offer_scales: Array[float] = [1.0, 0.5, 0.33]
@export var what_if_penalties: Array[float] = [0.0, 0.5]
## The weekly rent the what-if table checks for the running out of money ending
@export var what_if_rent: int = 150
