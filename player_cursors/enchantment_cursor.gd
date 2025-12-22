@abstract class_name EnchantmentCursor extends Area2D


@export var enabled: bool = true

var selection_manager: PriorityQueue = PriorityQueue.new()

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()

func enable_cursor() -> void:
	#if enabled:
		#push_warning("Cursor already enabled!")
		#return
	#print("Enabling", self)
	enabled = true
	visible = true
	monitoring = true
	monitorable = true
	set_physics_process(true)


func disable_cursor() -> void:
	#if not enabled:
		#push_warning("Cursor already disabled!")
		#return
	#print("Disabling", self)
	enabled = false
	visible = false
	monitoring = false
	monitorable = false
	set_physics_process(false)
