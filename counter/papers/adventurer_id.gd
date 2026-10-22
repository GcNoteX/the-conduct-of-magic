class_name AdventurerId
extends Resource

## An adventurer's ID card, as shown at the counter.
## Its tier limits which enchantments they may buy.

@export var holder_name: String = ""
@export var tier: int = 1
@export var kingdom: String = ""
## The last day the card is valid
@export var expires_day: int = 1
