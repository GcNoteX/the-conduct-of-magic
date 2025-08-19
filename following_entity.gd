extends RigidBody2D

@export var power: float = 1000
@export var speed: float = 1000
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed('left_click'):
		return
	if Input.is_action_pressed('right_click'):
		var dir = (get_global_mouse_position() - global_position).normalized()
		#linear_velocity = dir * speed
		linear_velocity = linear_velocity.lerp(dir.normalized() * speed, 0.05)
	else:
		#Comment
		apply_central_force(power*(get_global_mouse_position() - position))
