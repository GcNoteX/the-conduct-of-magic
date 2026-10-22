class_name ItemBox
extends MapSourceBox
## A sidebar box holding a material and its quantity. Hands out one MapItem at a time onto the
## EnchantmentMap.

signal emptied

@export var item: EnchantmentMaterialDefinition
@export var quantity: int

@onready var item_icon: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel


func fill(i: EnchantmentMaterialDefinition, q: int) -> void:
	item = i
	assert(q >= 0, " You cannot fill a box with negative quantity")
	quantity = q

	_update_box()

	item_icon.texture = item.enchantment_sprite_normal


func take_material() -> MapItem:
	if quantity <= 0:
		return null
	var map_item := UtilityFunctions.create_map_item(item)
	quantity -= 1
	_update_box()
	return map_item


func disable_box() -> void:
	pass


func _fill_from_exports() -> void:
	fill(item, quantity)


func _update_box() -> void:
	_update_label()
	if quantity == 0:
		disable_box()
		emptied.emit()


func _update_label() -> void:
	quantity_label.text = "x" + str(quantity)
