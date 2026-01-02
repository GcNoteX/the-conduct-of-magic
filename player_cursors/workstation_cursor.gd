extends EnchantmentCursor
class_name WorkstationCursor

## Proxy cursor that exists inside the workstation SubViewport world.
## Used only for collision / hover detection.
@export var workstation_cursor_proxy: WorkstationCursorProxy

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

## Currently dragged workspace object (if any)
var controlled_object: WorkspaceObject = null

## Previous cursor position (used to compute screen-space delta)
var _prev_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	## WorkspaceObjects have priority for selection
	selection_manager.set_priority_order([
		WorkspaceObject
	])

	## Mirror collision shape into the proxy cursor so both cursors
	## have identical interaction footprints
	workstation_cursor_proxy.collision_shape_2d.shape = collision_shape_2d.shape.duplicate()


func _physics_process(_delta: float) -> void:
	## Drag logic: cursor produces a screen-space delta,
	## WorkspaceObject decides how to apply it based on active form
	if controlled_object:
		controlled_object.move(global_position - _prev_pos)

	## Begin grab
	if Input.is_action_just_pressed("left_click"):
		var obj: WorkspaceObject = null

		## Prefer workstation hover if cursor is over a workstation form
		if workstation_cursor_proxy and workstation_cursor_proxy.hovered_object:
			obj = workstation_cursor_proxy.hovered_object
		else:
			obj = selection_manager.peek() as WorkspaceObject

		controlled_object = obj

		## Cursor listens to form changes to realign itself
		if obj and not obj.is_connected("form_changed", teleport_to_object):
			obj.form_changed.connect(teleport_to_object)

	## End grab
	if Input.is_action_just_released("left_click"):
		controlled_object = null

	_prev_pos = global_position


## Aligns the cursor to the newly enabled form.
## This is the ONLY place cursor teleportation happens.
func teleport_to_object(form: WorkplaceForm) -> void:
	if form is ChannelForm:
		## Same world → direct
		global_position = form.global_position

	elif form is WorkStationForm:
		## Convert workstation world → screen
		var controller := get_tree().get_first_node_in_group("workstation_controller")
		if controller and controller.has_method("workstation_world_to_screen"):
			global_position = controller.workstation_world_to_screen(form.position)

	_prev_pos = global_position


## Cursor overlap feeds the selection manager
func _on_area_entered(area: Area2D) -> void:
	if area is WorkplaceForm and area.owner_object:
		selection_manager.push(area.owner_object)


func _on_area_exited(area: Area2D) -> void:
	if area is WorkplaceForm and area.owner_object:
		selection_manager.remove(area.owner_object)
