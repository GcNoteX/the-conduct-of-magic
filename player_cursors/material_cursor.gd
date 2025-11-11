extends EnchantmentCursor
class_name MaterialCursor

var magic_line: PackedScene = preload(SceneReferences.magic_line)
var controlled_item: MapItem = null

var selection_manager: MaterialPriorityQueue = MaterialPriorityQueue.new()

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	if controlled_item:
		controlled_item.global_position = global_position

	if Input.is_action_just_pressed("left_click"):
		var obj = selection_manager.peek()
		print("SM: ", selection_manager._queues)
		if obj and obj.has_method("take_material"):
			var m = obj.take_material()
			get_tree().root.add_child(m)
			if m is MapItem:
				controlled_item = m
			else:
				push_warning("take_material() should return a MapItem!")


func _on_area_entered(area: Area2D) -> void:
	if area is ItemBoxArea:
		selection_manager.push(area.get_item_box())
	if area is EnchantmentNode:
		selection_manager.push(area)


func _on_area_exited(area: Area2D) -> void:
	if area is ItemBoxArea:
		selection_manager.remove(area.get_item_box())
	if area is EnchantmentNode:
		selection_manager.remove(area)
