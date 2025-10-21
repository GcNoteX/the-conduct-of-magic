class_name EnchantmentCursor
extends Area2D

"""
- Controlled by the players mouse
- Can create MagicLines through dragging from MagicNode
"""

# The cursor used within the enchantment game
# CAUTION: Cursor hitbox should at least cover MagicEdge, else
# Buggy behaviour will occur in which the game will think you 
# want to do chain linking since the cursor is not on
# the socket when the edge locks.

@export var sensitivity: float = 1.0

var is_captured: bool = true

func _ready() -> void:
	# Capture mouse and hide system cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = position + (event.relative) * sensitivity
		# Optional: Clamp within screen bounds
		var screen_size = get_viewport_rect().size
		position = position.clamp(Vector2.ZERO, screen_size)
	
	if event.is_action_pressed("editor_toggle_enchant_mouse"):
		if is_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			is_captured = !is_captured
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			self.position = get_global_mouse_position()
			is_captured = !is_captured
			
## Get the location of the cursor
func get_location() -> Vector2:
	return self.position
