class_name EnchantmentBox
extends MapSourceBox
## A sidebar box holding an Enchantment to be dragged onto the map.

@export var enchantment: Enchantment

@onready var enchantment_icon: TextureRect = %EnchantmentIcon


func fill(i: Enchantment) -> void:
	enchantment = i
	enchantment_icon.texture = enchantment.icon


func get_enchantment() -> Enchantment:
	return enchantment


func _fill_from_exports() -> void:
	fill(enchantment)
