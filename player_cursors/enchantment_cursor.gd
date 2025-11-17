@abstract class_name EnchantmentCursor extends Area2D

@export var enabled: bool = true

func enable_cursor() -> void:
	if enabled:
		push_warning("Cursor already enabled!")
		return

	enabled = true
	visible = true
	monitoring = true
	monitorable = true
	set_physics_process(true)


func disable_cursor() -> void:
	if not enabled:
		push_warning("Cursor already disabled!")
		return

	enabled = false
	visible = false
	monitoring = false
	monitorable = false
	set_physics_process(false)
