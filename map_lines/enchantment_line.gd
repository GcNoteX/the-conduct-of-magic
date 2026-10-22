@tool
class_name EnchantmentLine
extends MapLine
## A line between the EnchantmentNodes of one EnchantmentGrid. Placed by whoever builds the
## enchantment and only moved as part of its grid; its bounded identity is always its grid.
##
## When an EnchantmentLine overlaps with:
## - EnchantmentLine of EnchantmentGrid -> Nothing
## - EnchantmentNode of EnchantmentGrid -> Invalid except owner (This is on Coder to not happen)
## - EnchantmentLine of Other EnchantmentGrid -> Invalid
## - EnchantmentNode of Other EnchantmentGrid -> Invalid


func _ready() -> void:
	_initialize_line()
	bounded_identity = get_parent()
	assert(
		bounded_identity is EnchantmentGrid, " EchantmentLine must have EnchantmentGrid as a parent"
	)


func update_bounded_identity() -> void:
	bounded_identity = get_parent()
