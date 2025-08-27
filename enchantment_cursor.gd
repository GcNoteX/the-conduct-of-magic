class_name EnchantmentCursor
extends Area2D

# The cursor used within the enchantment game
# CAUTION: Cursor hitbox should at least cover MagicEdge, else
# Buggy behaviour will occur in which the game will think you 
# want to do chain linking since the cursor is not on
# the socket when the edge locks.

@export var sensitivity: float = 1.0

func _ready() -> void:
	# Capture mouse and hide system cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = position + (event.relative) * sensitivity
		# Optional: Clamp within screen bounds
		var screen_size = get_viewport_rect().size
		position = position.clamp(Vector2.ZERO, screen_size)
		
## Get the location of the cursor
func get_location() -> Vector2:
	#return get_global_mouse_position()\
	return self.position
