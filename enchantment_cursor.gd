class_name EnchantmentCursor
extends Area2D

# The cursor used within the enchantment game
# CAUTION: Cursor hitbox should at least cover MagicEdge, else
# Buggy behaviour will occur in which the game will think you 
# want to do chain linking since the cursor is not on
# the socket when the edge locks.

func _physics_process(delta: float) -> void:
	position = get_global_mouse_position()

## Get the location of the cursor
func get_location() -> Vector2:
	return get_global_mouse_position()
