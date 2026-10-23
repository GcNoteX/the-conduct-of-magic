class_name BotPlaytestSettings
extends Resource

## The knobs for the bot playtest: how many runs and days, which play styles, how many
## customers walk in once the authored days run out, and how much stamina the bot has a night.

## The play styles, each run plays one. Careful follows the rulebook and carves what it can;
## Greedy accepts everyone; Chaotic does random things everywhere.
enum Style { CAREFUL, GREEDY, CHAOTIC }

## What the fresh-item fit check carves on, with which stones. The runs themselves use the day
## scene's own setup and supplier.
@export var setup: DemoSetup
@export var catalogue: SupplierCatalogue

@export_group("Runs")
@export var styles: Array[Style] = [Style.CAREFUL, Style.GREEDY, Style.CHAOTIC]
@export var runs_per_style: int = 3
@export var days: int = 200
@export var random_seed: int = 1

@export_group("Customers")
## The pool walk-ins are drawn from once the counter's authored days run out. Each copy keeps
## its papers, with their dates moved along so they stay as legal as they were on the
## authored day.
@export var customer_pool: Array[CustomerVisit] = []
## Walk-ins a day after the authored days. 0 keeps the game as authored: no one comes.
@export var customers_per_day: int = 3

@export_group("Play")
## Enchantments the bot attempts a night (Chaotic ignores it)
@export var enchantments_per_night: int = 3
## Chance that a Careful or Greedy bot does a random action instead of the sensible one
@export_range(0.0, 1.0) var random_action_chance: float = 0.1
## Random actions a Chaotic bot takes on each side of the day
@export var chaotic_actions_per_side: int = 25
## Spots on the item a carving attempt tries before giving up
@export var spots_per_attempt: int = 12

@export_group("Checks")
## Actions on one side of a day before the bot calls the side stuck
@export var max_actions_per_side: int = 200
## Days a commission may stay uncollected while the bot serves every collector
@export var max_days_waiting: int = 3
## Days between object count samples, for the leak check
@export var sample_every_days: int = 10
