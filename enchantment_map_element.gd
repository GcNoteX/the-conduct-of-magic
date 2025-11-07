@abstract class_name EnchantmentMapElement extends Area2D

var bounded_identity: Variant = null ## The entity bounded to
@export var can_share_identity: bool = true # Can share its identity when asked for it
@export var can_change_identity: bool = true # Something that's identity can be changed

## How the object will handle updating itself
@abstract func update_bounded_identity() -> void
