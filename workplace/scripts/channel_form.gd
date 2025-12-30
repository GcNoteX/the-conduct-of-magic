class_name ChannelForm
extends WorkplaceForm

func _ready() -> void:
	# Initialize correct collisions via code
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true)
