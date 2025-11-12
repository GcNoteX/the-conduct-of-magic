@tool
extends Node
class_name CircularMotionAnim

@export var radius: float = 16.0       # Distance from the center
@export var speed: float = 2.0         # Revolutions per second
@export var offset_angle: float = 0.0  # Optional starting angle in radians
@export var center_position: Vector2   # Orbit center point
@export var sprite: Sprite2D

var angle: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	if !sprite or !sprite.texture:
		push_warning(str(self) + " does not have a sprite/sprite texture to animate")
		set_process(false)
		return

	# Only set center if it’s still default (e.g. (0,0))
	if center_position == Vector2.ZERO:
		center_position = sprite.position

	set_process(true)


func set_sprite(s: Sprite2D) -> void:
	sprite = s
	if sprite and sprite.texture:
		if center_position == Vector2.ZERO:
			center_position = sprite.position
		set_process(true)
	else:
		set_process(false)
	
	if Engine.is_editor_hint():
		set_process(false)
		return

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
		
	if !sprite or !sprite.texture:
		set_process(false)
		return

	# Increment the angle
	angle = fmod(angle + speed * delta * TAU, TAU)

	# Compute new position (orbit around center)
	var x = center_position.x + radius * cos(angle + offset_angle)
	var y = center_position.y + radius * sin(angle + offset_angle)
	sprite.position = Vector2(x, y)
