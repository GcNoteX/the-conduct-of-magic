class_name BoardDropArea
extends Control

## The area the board is drawn in. Passes mouse input down to its BoardView and accepts dragged
## materials and enchantments, so a drop lands on the cell under the mouse.

var view: BoardView


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if view and event is InputEventMouse:
		view.handle_mouse(event, _to_view(event.position))
		accept_event()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if view == null:
		return false
	if data is EnchantmentMaterialDefinition:
		view.check_drop(data, _to_view(at_position))
		return true
	if data is Enchantment:
		view.check_enchantment_drop(data, _to_view(at_position))
		return true
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is Enchantment:
		view.drop_enchantment(data, _to_view(at_position))
	else:
		view.drop_material(data, _to_view(at_position))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and view:
		view.end_drop_preview()


func _on_mouse_exited() -> void:
	if view:
		view.mouse_left()


func _to_view(local: Vector2) -> Vector2:
	return view.transform.affine_inverse() * local
