class_name ChannelForm
extends WorkplaceForm
## How an item looks and collides in the workplace's channel (the main world).


func _ready() -> void:
	# Initialize correct collisions via code
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(CollisionLayers.WORKSPACE_OBJECT, true)
