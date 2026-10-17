class_name Enchantment
extends Resource

@export var enchantment_name: String = "NULL"

@export var icon: Texture2D

@export var map: PackedScene  ## Should be an EnchantmentGrid (old free-placement play map)

@export_category("Hex pattern")
## What a customer can tell the enchantment does
@export_multiline var effect_description: String = ""
## The enchantment's nodes; the first node sits on the origin cell
@export var nodes: Array[EnchantmentPatternNode] = []
## The enchantment's own fixed lines; they take cells like drawn lines
@export var lines: Array[EnchantmentPatternLine] = []
