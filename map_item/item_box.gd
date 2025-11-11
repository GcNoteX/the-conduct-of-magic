extends Control
class_name ItemBox

"""
Represents an item and its quantity
"""

signal emptied()

@export var item: EnchantmentMaterial
@export var quantity: int

@onready var label: Label = $AspectRatioContainer/Label
@onready var texture_rect: TextureRect = $AspectRatioContainer/TextureRect
@onready var collision_shape_2d: CollisionShape2D = $AspectRatioContainer/Area2D/CollisionShape2D

func _ready() -> void:
	fill(item, quantity)
	var shape = collision_shape_2d.shape as RectangleShape2D
	shape.size = self.size * scale

func fill(i: EnchantmentMaterial, q: int) -> void:
	item = i
	assert(q >= 0, " You cannot fill a box with negative quantity")
	quantity = q
	
	_update_box()
	texture_rect.texture = item.material_sprite

func take_material() -> MapItem:
	if quantity <= 0:
		return
	var map_item := UtilityFunctions.create_map_item(item)
	quantity -= 1
	_update_box()
	print(map_item, " created")
	return map_item

func _update_box() -> void:
	_update_label()
	if quantity == 0:
		disable_box()
		emit_signal("emptied")

func _update_label() -> void:
	label.text = "x" + str(quantity)

func disable_box() -> void:
	pass
	
