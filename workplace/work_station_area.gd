extends Area2D

## Discrete zoom levels for the workstation camera.
## Higher values = more zoomed in (Camera2D semantics).
const ZOOM_LEVELS: Array[float] = [1.0, 2.0, 4.0]

## Group name for the main cursor (screen-space cursor)
@export var cursor_group: StringName = &"cursor"

## Camera rendering the workstation SubViewport
@export var workstation_camera: Camera2D

## Root node inside the SubViewport where workstation visuals live
## (items, forms, inspectable components, etc.)
@export var visual_root: Node2D

## Container used to map screen-space <-> SubViewport-space
@export var subviewport_container: SubViewportContainer

## The SubViewport itself (used for size reference)
@export var subviewport: SubViewport

## Proxy cursor that exists inside the workstation world
@export var workstation_cursor: WorkstationCursorProxy

## Logical bounds of the workstation table in workstation-world units
@export var table_origin: Vector2 = Vector2.ZERO
@export var table_size: Vector2 = Vector2(1080, 1080)


## Current zoom index into ZOOM_LEVELS
var _zoom_index: int = 0

## Whether the main cursor is currently inside the workstation area
var _cursor_inside: bool = false

## Cached reference to the main cursor node
var _cursor_node: Node2D = null

## Panning state (middle mouse drag)
var _is_panning: bool = false
var _pan_last_vp_pixel: Vector2 = Vector2.ZERO


func _ready() -> void:
	## --- VALIDATION ---
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

	## Cache main cursor (screen-space)
	_cursor_node = get_tree().get_first_node_in_group(cursor_group) as Node2D
	if _cursor_node == null:
		push_warning("WorkstationArea: no cursor found in group '%s'" % String(cursor_group))

	## Proxy cursor is required for workstation interactions
	if workstation_cursor == null:
		push_error("WorkstationArea: workstation_cursor not assigned")
		return

	monitoring = true
	monitorable = true

	## Initial camera setup
	_apply_zoom()
	_center_camera_on_table()
	_clamp_camera_to_table()


func _process(_delta: float) -> void:
	## While cursor is inside the workstation area, keep the proxy cursor
	## aligned to the cursor's position converted into workstation world.
	if _cursor_inside and _cursor_node and workstation_cursor:
		workstation_cursor.position = screen_to_workstation_world(
			_cursor_node.global_position
		)


## --- AREA DETECTION ----------------------------------------------------------

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(cursor_group):
		_cursor_inside = true


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group(cursor_group):
		_cursor_inside = false


## --- INPUT HANDLING ----------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _cursor_inside:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_step(1)
			return

		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_step(-1)
			return

		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_is_panning = true
				_pan_last_vp_pixel = _cursor_to_subviewport_pixel()
			else:
				_is_panning = false
			return

	if event is InputEventMouseMotion and _is_panning:
		_pan_update()


## --- ZOOM --------------------------------------------------------------------

func _zoom_step(dir: int) -> void:
	var new_index: int = clampi(_zoom_index + dir, 0, ZOOM_LEVELS.size() - 1)
	if new_index == _zoom_index:
		return

	## Capture the workstation-world point under the cursor before zoom
	var vp_pixel: Vector2 = _cursor_to_subviewport_pixel()
	if vp_pixel == Vector2.INF:
		return

	var world_before: Vector2 = _subviewport_pixel_to_world(vp_pixel)

	_zoom_index = new_index
	_apply_zoom()

	## Fully zoomed out is the canonical "default view"
	if _zoom_index == 0:
		_center_camera_on_table()
		_clamp_camera_to_table()
		return

	## Adjust camera so the cursor stays over the same world point
	var world_after: Vector2 = _subviewport_pixel_to_world(vp_pixel)
	workstation_camera.position += (world_before - world_after)

	_clamp_camera_to_table()


func _apply_zoom() -> void:
	var level: float = ZOOM_LEVELS[_zoom_index]
	workstation_camera.zoom = Vector2(level, level)


## --- PAN ---------------------------------------------------------------------

func _pan_update() -> void:
	var vp_pixel: Vector2 = _cursor_to_subviewport_pixel()
	if vp_pixel == Vector2.INF:
		return

	## Cursor movement in SubViewport pixel space
	var delta_px: Vector2 = vp_pixel - _pan_last_vp_pixel
	_pan_last_vp_pixel = vp_pixel

	## Convert pixel delta → workstation world delta
	## Higher zoom = fewer world units per pixel
	var zoom: float = workstation_camera.zoom.x
	var delta_world: Vector2 = delta_px / zoom

	## Move camera opposite to cursor movement (grabbing the surface)
	workstation_camera.position -= delta_world

	_clamp_camera_to_table()


## --- CAMERA CONSTRAINTS ------------------------------------------------------

func _center_camera_on_table() -> void:
	var rect := Rect2(table_origin, table_size)
	workstation_camera.position = rect.get_center()


func _clamp_camera_to_table() -> void:
	var rect := Rect2(table_origin, table_size)

	var vp_size: Vector2 = Vector2(subviewport.size)
	var zoom: float = workstation_camera.zoom.x

	## Visible world size shrinks as zoom increases
	var visible_size: Vector2 = vp_size / zoom
	var half: Vector2 = visible_size * 0.5

	## If the view is larger than the table, force center
	if visible_size.x >= rect.size.x or visible_size.y >= rect.size.y:
		workstation_camera.position = rect.get_center()
		return

	var min_pos: Vector2 = rect.position + half
	var max_pos: Vector2 = rect.position + rect.size - half

	workstation_camera.position.x = clamp(workstation_camera.position.x, min_pos.x, max_pos.x)
	workstation_camera.position.y = clamp(workstation_camera.position.y, min_pos.y, max_pos.y)


## --- COORDINATE CONVERSION HELPERS -------------------------------------------
## These functions define the authoritative mapping between:
## screen space <-> SubViewport pixel space <-> workstation world space.

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


## Convert a screen-space position into workstation-world coordinates
func screen_to_workstation_world(screen_pos: Vector2) -> Vector2:
	var rect: Rect2 = subviewport_container.get_global_rect()
	var local: Vector2 = screen_pos - rect.position

	var vp_size: Vector2 = Vector2(subviewport.size)
	var vp_pixel := Vector2(
		local.x * (vp_size.x / rect.size.x),
		local.y * (vp_size.y / rect.size.y)
	)

	var inv: Transform2D = workstation_camera.get_canvas_transform().affine_inverse()
	return inv * vp_pixel


## Convert a screen-space delta into a workstation-world delta
## Used for dragging objects inside the workstation
func screen_delta_to_workstation_world_delta(screen_delta: Vector2) -> Vector2:
	var rect: Rect2 = subviewport_container.get_global_rect()
	var vp_size: Vector2 = Vector2(subviewport.size)

	var px_scale := Vector2(
		vp_size.x / rect.size.x,
		vp_size.y / rect.size.y
	)

	var vp_delta := Vector2(
		screen_delta.x * px_scale.x,
		screen_delta.y * px_scale.y
	)

	return vp_delta / workstation_camera.zoom.x


## Convert workstation-world coordinates back into screen-space
## Used by the cursor when reacting to form changes
func workstation_world_to_screen(world_pos: Vector2) -> Vector2:
	var canvas_xform := workstation_camera.get_canvas_transform()
	var vp_pixel := canvas_xform * world_pos

	var rect := subviewport_container.get_global_rect()
	var vp_size := Vector2(subviewport.size)

	return Vector2(
		rect.position.x + (vp_pixel.x / vp_size.x) * rect.size.x,
		rect.position.y + (vp_pixel.y / vp_size.y) * rect.size.y
	)
