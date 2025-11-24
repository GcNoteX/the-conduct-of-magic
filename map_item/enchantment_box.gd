extends AspectRatioContainer
class_name EnchantmentBox

"""
- Represents an Enchantment to be dragged onto the map
"""

@export var enchantment: Enchantment

@onready var box_body: PanelContainer = %BoxBody
@onready var enchantment_icon: TextureRect = %EnchantmentIcon
@onready var physical_area: EnchantmentBoxArea = %PhysicalArea
@onready var physical_hitbox: CollisionShape2D = %PhysicalHitbox

func _ready() -> void:
	fill(enchantment)
	if physical_hitbox and physical_hitbox.shape:
		# Duplicate so we don't modify a shared resource
		physical_hitbox.shape = physical_hitbox.shape.duplicate()
		_on_box_body_resized()

func fill(i: Enchantment) -> void:
	enchantment = i
	enchantment_icon.texture = enchantment.icon

func get_enchantment() -> Enchantment:
	var e : Enchantment = enchantment
	return e
	

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
