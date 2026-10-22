@abstract
class_name EnchantmentCursor extends Area2D
## Base for the legacy play map's cursors: follows the mouse while enabled and keeps a
## PriorityQueue of what it hovers.

@export var enabled: bool = true

var selection_manager: PriorityQueue = PriorityQueue.new()


func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventMouseMotion:
		global_position += event.relative


func enable_cursor() -> void:
	enabled = true
	visible = true
	monitoring = true
	monitorable = true
	set_physics_process(true)


func disable_cursor() -> void:
	enabled = false
	visible = false
	monitoring = false
	monitorable = false
	set_physics_process(false)
