@abstract class_name EnchantmentCursor extends Area2D


@export var enabled: bool = true

var selection_manager: PriorityQueue = PriorityQueue.new()

func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventMouseMotion:
		global_position += event.relative
		#print("Global positon from cursor script:", global_position)


func enable_cursor() -> void:
	enabled = true
	visible = true
	monitoring = true
	monitorable = true
	set_physics_process(true)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func disable_cursor() -> void:
	enabled = false
	visible = false
	monitoring = false
	monitorable = false
	set_physics_process(false)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
