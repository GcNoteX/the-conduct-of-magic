class_name Permit
extends Resource

## A permit to buy controlled enchantments, issued by a kingdom or an association of kingdoms.

@export var holder_name: String = ""
@export var issuer: String = ""
@export var covers: Array[Enchantment] = []
@export var kingdoms: Array[String] = []
## The last day the permit is valid
@export var expires_day: int = 1
