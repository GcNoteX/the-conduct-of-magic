extends EnchantmentCursor
class_name MaterialCursor

signal unhandled_MapItem_released(i: MapItem)

var magic_line: PackedScene = preload(SceneReferences.magic_line)
var controlled_item: MapItem = null

#var selection_manager: MaterialPriorityQueue = MaterialPriorityQueue.new()

func _ready() -> void:
	selection_manager.set_priority_order([
		ItemBox,
		MaterialDropper,
	])
	unhandled_MapItem_released.connect(EmapUpdateManager.handle_unhandled_map_item)
	if !enabled:
		disable_cursor()

func _physics_process(_delta: float) -> void:
	if controlled_item:
		controlled_item.global_position = global_position

	if Input.is_action_just_pressed("left_click"):
		# Attempt to grab a MapItem
		var obj = selection_manager.peek()
		#print("SM: ", selection_manager._queues)
		if obj and obj.has_method("take_material"):
			var m = obj.take_material() as MapItem
			if m is MapItem:
				EmapUpdateManager.add_to_enchantment_map(m, global_position)
				controlled_item = m
			elif m == null:
				controlled_item = m
			else:
				push_warning("take_material() should return a MapItem or null!")
	
	if Input.is_action_just_released("left_click"):
		# Attempt to drop a MapItem
		var obj = selection_manager.peek()
		var res = false
		#print(" Handle release on ", obj)
		if obj and obj.has_method("insert_material") and controlled_item:
			#print("Inserted material ")
			res = obj.insert_material(controlled_item.e_material)
		if res == true and controlled_item: # i.e. the MapItem was used for something
			print("Insertion successful")
			controlled_item.queue_free()
		elif res == false and controlled_item: # i.e. the MapItem was not used for something
			emit_signal("unhandled_MapItem_released", controlled_item)
		controlled_item = null
	
	if Input.is_action_just_pressed("right_click"):
		var o = selection_manager.peek()
		if o is MaterialDropper:
			# Pop the material
			var m = o.remove_material()
			# Pass back to player
			PlayerManager.add_material(m)

func _on_area_entered(area: Area2D) -> void:
	if area is ItemBoxArea:
		selection_manager.push(area.get_item_box())
	if area is MaterialDropper:
		selection_manager.push(area)


func _on_area_exited(area: Area2D) -> void:
	if area is ItemBoxArea:
		selection_manager.remove(area.get_item_box())
	if area is MaterialDropper:
		selection_manager.remove(area)
