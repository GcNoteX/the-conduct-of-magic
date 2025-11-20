extends AspectRatioContainer
class_name ItemBox

"""
- Represents an item and its quantity
- Can produce item's onto the EnchantmentMap
"""

signal emptied()

@export var item: EnchantmentMaterial
@export var quantity: int

@onready var box_body: PanelContainer = %BoxBody
@onready var item_icon: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel
@onready var physical_area: ItemBoxArea = %PhysicalArea
@onready var physical_hitbox: CollisionShape2D = %PhysicalHitbox

func _ready() -> void:
	fill(item, quantity)
	if physical_hitbox and physical_hitbox.shape:
		# Duplicate so we don't modify a shared resource
		physical_hitbox.shape = physical_hitbox.shape.duplicate()
		_on_box_body_resized()

func fill(i: EnchantmentMaterial, q: int) -> void:
	item = i
	assert(q >= 0, " You cannot fill a box with negative quantity")
	quantity = q
	
	_update_box()
	item_icon.texture = item.material_sprite

func take_material() -> MapItem:
	if quantity <= 0:
		return
	var map_item := UtilityFunctions.create_map_item(item)
	quantity -= 1
	_update_box()
	#print(map_item, " created")
	return map_item

func _update_box() -> void:
	_update_label()
	if quantity == 0:
		disable_box()
		emit_signal("emptied")

func _update_label() -> void:
	quantity_label.text = "x" + str(quantity)

func disable_box() -> void:
	pass
	

func _on_box_body_resized() -> void:
	if physical_area and physical_hitbox and physical_hitbox.shape:
		# Get the global rectangle of the panel container
		var global_rect = box_body.get_global_rect()

		# Set the collision shape size to match the panel
		physical_hitbox.shape.size = global_rect.size

		# Center the Area2D on the panel
		physical_area.global_position = global_rect.position + global_rect.size / 2

		#print("Physical hitbox updated to ", physical_hitbox.shape.size)
		#print("Physical area centered at ", physical_area.global_position)
