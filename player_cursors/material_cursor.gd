class_name MaterialCursor
extends EnchantmentCursor
## Cursor for the legacy play map that picks materials out of item boxes, drops them into
## material holders, and takes them back out with a right-click.

signal unhandled_map_item_released(i: MapItem)

var magic_line: PackedScene = preload(SceneReferences.magic_line)
var controlled_item: MapItem = null


func _ready() -> void:
	selection_manager.set_priority_order([ItemBox, MaterialDropper])
	unhandled_map_item_released.connect(EmapUpdateManager.handle_unhandled_map_item)
	if not enabled:
		disable_cursor()


func _physics_process(_delta: float) -> void:
	if controlled_item:
		controlled_item.global_position = global_position

	if Input.is_action_just_pressed("left_click"):
		# Attempt to grab a MapItem
		var obj: Object = selection_manager.peek()
		if obj and obj.has_method("take_material"):
			var m := obj.take_material() as MapItem
			if m is MapItem:
				EmapUpdateManager.add_to_enchantment_map(m, global_position)
				controlled_item = m
			elif m == null:
				controlled_item = m
			else:
				push_warning("take_material() should return a MapItem or null!")

	if Input.is_action_just_released("left_click"):
		# Attempt to drop a MapItem
		var obj: Object = selection_manager.peek()
		var res := false
		if obj and obj.has_method("insert_material") and controlled_item:
			res = obj.insert_material(controlled_item.e_material)
		if res and controlled_item:  # i.e. the MapItem was used for something
			print("Insertion successful")
			controlled_item.queue_free()
		elif not res and controlled_item:  # i.e. the MapItem was not used for something
			unhandled_map_item_released.emit(controlled_item)
		controlled_item = null

	if Input.is_action_just_pressed("right_click"):
		var o: Object = selection_manager.peek()
		if o is MaterialDropper:
			return_material_to_player(o)


## Takes the material out of a dropper and gives it back to the player. An empty or sealed
## slot gives nothing back.
func return_material_to_player(dropper: MaterialDropper) -> void:
	var m := dropper.remove_material()
	if m:
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
