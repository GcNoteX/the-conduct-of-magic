@tool
class_name Enchantment
extends Resource
## One enchantment: its name, what it does, and its fixed hex shape of nodes and lines.
## The shape is authored in an EnchantmentScene and baked into this resource.

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
