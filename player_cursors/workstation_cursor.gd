extends EnchantmentCursor
class_name WorkstationCursor

var controlled_object: WorkspaceObject = null

var _prev_pos = Vector2.ZERO


func _ready() -> void:
	selection_manager.set_priority_order([
		WorkspaceObject
	])

func _physics_process(_delta: float) -> void:
	if controlled_object:
		controlled_object.move(global_position - _prev_pos)

	if Input.is_action_just_pressed("left_click"):
		# Attempt to grab a MapItem
		var obj = selection_manager.peek()
		controlled_object = obj
	
	if Input.is_action_just_released("left_click"):
		# Attempt to drop a MapItem
		controlled_object = null
	
	_prev_pos = global_position

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is WorkspaceObject:
		selection_manager.push(area.get_parent())


func _on_area_exited(area: Area2D) -> void:
	if area.get_parent() is WorkspaceObject:
		selection_manager.remove(area.get_parent())
