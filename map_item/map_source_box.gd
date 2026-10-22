@abstract class_name MapSourceBox
extends AspectRatioContainer
## Base for the sidebar boxes of the legacy play map that things are dragged out of onto the map
## (ItemBox, EnchantmentBox). Keeps the box's physical hitbox the size of its panel, so the
## cursor can hover it.

@onready var box_body: PanelContainer = %BoxBody
@onready var physical_area: Area2D = %PhysicalArea
@onready var physical_hitbox: CollisionShape2D = %PhysicalHitbox


func _ready() -> void:
	_fill_from_exports()
	if physical_hitbox and physical_hitbox.shape:
		# Duplicate so we don't modify a shared resource
		physical_hitbox.shape = physical_hitbox.shape.duplicate()
		_on_box_body_resized()


## Shows the box's exported contents when it enters the tree
@abstract func _fill_from_exports() -> void


func _on_box_body_resized() -> void:
	if physical_area and physical_hitbox and physical_hitbox.shape:
		# Get the global rectangle of the panel container
		var global_rect := box_body.get_global_rect()

		# Set the collision shape size to match the panel
		physical_hitbox.shape.size = global_rect.size

		# Center the Area2D on the panel
		physical_area.global_position = global_rect.position + global_rect.size / 2
