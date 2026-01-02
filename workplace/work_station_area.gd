extends Area2D

const ZOOM_LEVELS: Array[float] = [1.0, 2.0, 4.0]

@export var cursor_group: StringName = &"cursor"
@export var workstation_camera: Camera2D
@export var visual_root: Node2D                    # keep this for later item insertion
@export var subviewport_container: SubViewportContainer
@export var subviewport: SubViewport

@export var table_origin: Vector2 = Vector2.ZERO   # in SubViewport world coords
@export var table_size: Vector2 = Vector2(1080, 1080) # set to your table X by Y

var _zoom_index: int = 0
var _cursor_inside: bool = false
var _cursor_node: Node2D = null


func _ready() -> void:
	if workstation_camera == null:
		push_error("WorkstationArea: workstation_camera not assigned")
		return
	if visual_root == null:
		push_error("WorkstationArea: visual_root not assigned")
		return
	if subviewport_container == null:
		push_error("WorkstationArea: subviewport_container not assigned")
		return
	if subviewport == null:
		push_error("WorkstationArea: subviewport not assigned")
		return

	_cursor_node = get_tree().get_first_node_in_group(cursor_group) as Node2D
	if _cursor_node == null:
		push_warning("WorkstationArea: no cursor found in group '%s'" % String(cursor_group))

	monitoring = true
	monitorable = true

	_apply_zoom()
	_center_camera_on_table()
	_clamp_camera_to_table()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(cursor_group):
		_cursor_inside = true


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group(cursor_group):
		_cursor_inside = false


func _input(event: InputEvent) -> void:
	if not _cursor_inside:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_step(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_step(-1)


func _zoom_step(dir: int) -> void:
	var new_index: int = clampi(_zoom_index + dir, 0, ZOOM_LEVELS.size() - 1)
	if new_index == _zoom_index:
		return

	var vp_pixel: Vector2 = _cursor_to_subviewport_pixel()
	if vp_pixel == Vector2.INF:
		return

	var world_before: Vector2 = _subviewport_pixel_to_world(vp_pixel)

	_zoom_index = new_index
	_apply_zoom()

	# When fully zoomed out, snap to table center (your "default view")
	if _zoom_index == 0:
		_center_camera_on_table()
		_clamp_camera_to_table()
		return

	var world_after: Vector2 = _subviewport_pixel_to_world(vp_pixel)
	workstation_camera.position += (world_before - world_after)

	_clamp_camera_to_table()


func _apply_zoom() -> void:
	var level: float = ZOOM_LEVELS[_zoom_index]
	workstation_camera.zoom = Vector2(level, level)


func _center_camera_on_table() -> void:
	var rect := Rect2(table_origin, table_size)
	workstation_camera.position = rect.get_center()


func _clamp_camera_to_table() -> void:
	var rect := Rect2(table_origin, table_size)

	var vp_size: Vector2 = Vector2(subviewport.size)
	var zoom: float = workstation_camera.zoom.x

	# Visible world size shrinks as zoom increases (per your docs)
	var visible_size: Vector2 = vp_size / zoom
	var half: Vector2 = visible_size * 0.5

	# If view is larger than table, just center it
	if visible_size.x >= rect.size.x or visible_size.y >= rect.size.y:
		workstation_camera.position = rect.get_center()
		return

	var min_pos: Vector2 = rect.position + half
	var max_pos: Vector2 = rect.position + rect.size - half

	workstation_camera.position.x = clamp(workstation_camera.position.x, min_pos.x, max_pos.x)
	workstation_camera.position.y = clamp(workstation_camera.position.y, min_pos.y, max_pos.y)


func _cursor_to_subviewport_pixel() -> Vector2:
	if _cursor_node == null:
		return Vector2.INF

	var cursor_screen: Vector2 = _cursor_node.global_position
	var rect: Rect2 = subviewport_container.get_global_rect()

	if not rect.has_point(cursor_screen):
		return Vector2.INF

	var local: Vector2 = cursor_screen - rect.position
	var vp_size: Vector2 = Vector2(subviewport.size)

	return Vector2(
		local.x * (vp_size.x / rect.size.x),
		local.y * (vp_size.y / rect.size.y)
	)


func _subviewport_pixel_to_world(vp_pixel: Vector2) -> Vector2:
	var inv: Transform2D = workstation_camera.get_canvas_transform().affine_inverse()
	return inv * vp_pixel
