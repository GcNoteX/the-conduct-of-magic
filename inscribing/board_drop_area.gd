class_name BoardDropArea
extends Control

## The area the board is drawn in. Passes mouse input down to its BoardView and accepts materials
## dragged from a MaterialList, so drag and drop lands on the node under the mouse.

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
	if view == null or not data is EnchantmentMaterialDefinition:
		return false
	view.check_drop(data, _to_view(at_position))
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	view.drop_material(data, _to_view(at_position))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and view:
		view.end_drop_preview()


func _on_mouse_exited() -> void:
	if view:
		view.mouse_left()


func _to_view(local: Vector2) -> Vector2:
	return view.transform.affine_inverse() * local
