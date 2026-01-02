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
		print(selection_manager._queues)
		var obj = selection_manager.peek() as WorkspaceObject
		controlled_object = obj
		print("Controlling ", controlled_object)
		if obj and !obj.is_connected("form_changed", teleport_to_object):
			obj.form_changed.connect(teleport_to_object)
	
	if Input.is_action_just_released("left_click"):
		controlled_object = null
	
	_prev_pos = global_position

func teleport_to_object(obj: Node2D) -> void:
	global_position = obj.global_position
	_prev_pos = global_position


func _on_area_entered(area: Area2D) -> void:
	print(area, " entered")
	# BUG: Currently not working due to workspace object adding the channel and
	# workstation scene differently and not under itself.
	if area.get_parent() is WorkspaceObject:
		print(area, " entered")
		selection_manager.push(area.get_parent())


func _on_area_exited(area: Area2D) -> void:
	print(area, " exited")
	if area.get_parent() is WorkspaceObject:
		print(area, " exited")
		selection_manager.remove(area.get_parent())
