extends Node

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
var _was_cursor_inside: bool = false
## Cached reference to the main cursor node
var _cursor_node: WorkstationCursor = null

## Panning state (middle mouse drag)
var _is_panning: bool = false
var _pan_last_screen: Vector2 = Vector2.ZERO

"""
This script handles zoom and provides a way
to map the main and subviewport pixels to be identical
"""

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
	_cursor_node = get_tree().get_first_node_in_group(cursor_group) as WorkstationCursor
	if _cursor_node == null:
		push_warning("WorkstationArea: no cursor found in group '%s'" % String(cursor_group))

	## Proxy cursor is required for workstation interactions
	if workstation_cursor == null:
		push_error("WorkstationArea: workstation_cursor not assigned")
		return

	## Set main cursor proxy cursor to controllers proxy
	_cursor_node.workstation_cursor_proxy = workstation_cursor

	## Get workstation area
	var workstation_area = get_tree().get_first_node_in_group("workstation") as Area2D
	if not workstation_area.area_entered.is_connected(_on_workstation_entered):
		workstation_area.area_entered.connect(_on_workstation_entered)
	if not workstation_area.area_exited.is_connected(_on_workstation_exited):
		workstation_area.area_exited.connect(_on_workstation_exited)

	## Initial camera setup
	_apply_zoom()
	_center_camera_on_table()
	_clamp_camera_to_table()


func _process(_delta: float) -> void:
	## While cursor is inside the workstation area, keep the proxy cursor
	## aligned to the cursor's position converted into workstation world.
	if _cursor_inside and _cursor_node and workstation_cursor:
		var world_pos := screen_to_workstation_world(_cursor_node.global_position)
		if world_pos != Vector2.INF:
			workstation_cursor.position = world_pos

		#if !_was_cursor_inside:
			#print(workstation_cursor.get_overlapping_areas())
			#workstation_cursor.refresh_hover()
	_was_cursor_inside = _cursor_inside


## --- AREA DETECTION ----------------------------------------------------------

func _on_workstation_entered(area: Area2D) -> void:
	if area.is_in_group(cursor_group):
		_cursor_inside = true


func _on_workstation_exited(area: Area2D) -> void:
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
				if _cursor_node:
					_pan_last_screen = _cursor_node.global_position
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

	if _cursor_node == null:
		return

	## Capture the workstation-world point under the cursor before zoom
	var screen_pos := _cursor_node.global_position
	var world_before := screen_to_workstation_world(screen_pos)
	if world_before == Vector2.INF:
		return

	_zoom_index = new_index
	_apply_zoom()

	## Fully zoomed out is the canonical "default view"
	if _zoom_index == 0:
		_center_camera_on_table()
		_clamp_camera_to_table()
		return

	## Adjust camera so the cursor stays over the same world point
	var world_after := screen_to_workstation_world(screen_pos)
	if world_after == Vector2.INF:
		return

	workstation_camera.position += (world_before - world_after)

	_clamp_camera_to_table()


func _apply_zoom() -> void:
	var level: float = ZOOM_LEVELS[_zoom_index]
	workstation_camera.zoom = Vector2(level, level)


## --- PAN ---------------------------------------------------------------------

func _pan_update() -> void:
	if _cursor_node == null:
		return

	var screen_now := _cursor_node.global_position
	var screen_prev := _pan_last_screen
	_pan_last_screen = screen_now

	var world_now := screen_to_workstation_world(screen_now)
	var world_prev := screen_to_workstation_world(screen_prev)

	if world_now == Vector2.INF or world_prev == Vector2.INF:
		return

	var world_delta := world_now - world_prev

	## Move camera opposite to cursor movement (grabbing the surface)
	workstation_camera.position -= world_delta

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
## Only TWO public functions:
## - screen_to_workstation_world()
## - workstation_world_to_screen()
##
## Everything else is private glue.

func _screen_to_container_local(screen_pos: Vector2) -> Vector2:
	# Accounts for canvas/UI scaling, anchors, stretch, etc.
	var inv := subviewport_container.get_global_transform_with_canvas().affine_inverse()
	return inv * screen_pos


func _container_local_to_screen(local: Vector2) -> Vector2:
	var xform := subviewport_container.get_global_transform_with_canvas()
	return xform * local


func _container_local_to_vp_pixel(local: Vector2) -> Vector2:
	# local is in displayed container pixels (0..subviewport_container.size)
	var rect_size := subviewport_container.size
	if rect_size.x == 0.0 or rect_size.y == 0.0:
		return Vector2.INF

	var vp_size := Vector2(subviewport.size)
	return Vector2(
		local.x * (vp_size.x / rect_size.x),
		local.y * (vp_size.y / rect_size.y)
	)


func _vp_pixel_to_container_local(vp_pixel: Vector2) -> Vector2:
	var rect_size := subviewport_container.size
	var vp_size := Vector2(subviewport.size)
	if vp_size.x == 0.0 or vp_size.y == 0.0:
		return Vector2.INF

	return Vector2(
		(vp_pixel.x / vp_size.x) * rect_size.x,
		(vp_pixel.y / vp_size.y) * rect_size.y
	)


func _vp_pixel_to_world(vp_pixel: Vector2) -> Vector2:
	# SubViewport pixel -> workstation world (through Camera2D)
	var inv := workstation_camera.get_canvas_transform().affine_inverse()
	return inv * vp_pixel


func _world_to_vp_pixel(world_pos: Vector2) -> Vector2:
	var xform := workstation_camera.get_canvas_transform()
	return xform * world_pos


## Public: screen/canvas position -> workstation world
func screen_to_workstation_world(screen_pos: Vector2) -> Vector2:
	var local := _screen_to_container_local(screen_pos)

	# Optional bounds guard: if you want INF when outside container:
	if local.x < 0.0 or local.y < 0.0 or local.x > subviewport_container.size.x or local.y > subviewport_container.size.y:
		return Vector2.INF

	var vp_pixel := _container_local_to_vp_pixel(local)
	if vp_pixel == Vector2.INF:
		return Vector2.INF

	return _vp_pixel_to_world(vp_pixel)


## Public: workstation world -> screen/canvas position
func workstation_world_to_screen(world_pos: Vector2) -> Vector2:
	var vp_pixel := _world_to_vp_pixel(world_pos)
	var local := _vp_pixel_to_container_local(vp_pixel)
	if local == Vector2.INF:
		return Vector2.INF

	return _container_local_to_screen(local)
