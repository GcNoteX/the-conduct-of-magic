extends Area2D
class_name WorkspaceObject

## Emitted whenever the active visual form changes.
## The cursor listens to this to realign itself to the new form.
signal form_changed(obj: WorkplaceForm)

@export var item: ItemInstance

## Channel-space representation (main world)
var channel_form: ChannelForm = null
## Workstation-space representation (SubViewport world)
var workstation_form: WorkStationForm = null
## Currently active form (exactly one at a time)
var active_form: WorkplaceForm = null

## Reference to the workstation controller (handles coordinate conversion)
var _workstation_controller: Node = null


func _ready() -> void:
	## Cache controller once (single source of workstation conversions)
	_workstation_controller = get_tree().get_first_node_in_group("workstation_controller")

	## WorkspaceObject itself is a probe Area2D; it detects channel/workstation zones
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	## --- CHANNEL FORM SETUP ---
	if item.definition.channel_form:
		channel_form = item.definition.channel_form.instantiate()
		assert(channel_form is ChannelForm, "channel_form must be a ChannelForm node")
		channel_form.disable()

		var channel_area := get_tree().get_first_node_in_group("channel")
		if channel_area:
			channel_area.visual_root.add_child(channel_form)
			channel_form.global_position = global_position

		channel_form.owner_object = self

	## --- WORKSTATION FORM SETUP ---
	if item.definition.workstation_form:
		workstation_form = item.definition.workstation_form.instantiate()
		assert(workstation_form is WorkStationForm, "workstation_form must be a WorkStationForm node")

		## Inject inspectable runtime state if present
		if item.inspectable_state:
			workstation_form._item_state = item.inspectable_state.inspected

		workstation_form.disable()

		if _workstation_controller:
			_workstation_controller.visual_root.add_child(workstation_form)

			## Initial alignment: probe → workstation world
			if _workstation_controller.has_method("screen_to_workstation_world"):
				workstation_form.position = _workstation_controller.screen_to_workstation_world(global_position)

		workstation_form.owner_object = self

	## --- DEFAULT FORM ---
	if channel_form:
		change_form(channel_form)
	elif workstation_form:
		change_form(workstation_form)


## Moves the WorkspaceObject probe by a screen-space delta.
## The active form mirrors this movement in its own coordinate space.
func move(v: Vector2) -> void:
	## Probe always moves in main world
	global_position += v

	## Channel form lives in the same world → direct delta
	if active_form == channel_form and channel_form:
		channel_form.global_position += v
		return

	## Workstation form lives in SubViewport world → converted delta
	if active_form == workstation_form and workstation_form and _workstation_controller:
		if _workstation_controller.has_method("screen_delta_to_workstation_world_delta"):
			var delta_ws: Vector2 = _workstation_controller.screen_delta_to_workstation_world_delta(v)
			workstation_form.position += delta_ws


## Switches between channel/workstation forms.
## IMPORTANT:
## - WorkspaceObject (probe) is the single source of truth for position
## - The newly enabled form is aligned to the probe
## - Cursor alignment is handled externally via form_changed
func change_form(target_form: WorkplaceForm) -> void:
	assert(target_form == channel_form or target_form == workstation_form)

	if active_form:
		active_form.disable()

	## Align the form being enabled to the probe position
	if target_form == channel_form:
		_align_channel_form_to_probe()
	elif target_form == workstation_form:
		_align_workstation_form_to_probe()

	target_form.enable()
	active_form = target_form

	emit_signal("form_changed", target_form)


## Channel form alignment is trivial (same world as probe)
func _align_channel_form_to_probe() -> void:
	if channel_form == null:
		return
	channel_form.global_position = global_position


## Workstation form alignment requires coordinate conversion
func _align_workstation_form_to_probe() -> void:
	if workstation_form == null:
		return
	if _workstation_controller == null:
		push_warning("WorkspaceObject: workstation_controller not found")
		return

	if _workstation_controller.has_method("screen_to_workstation_world"):
		workstation_form.position = _workstation_controller.screen_to_workstation_world(
			global_position
		)


## Probe detects entering channel/workstation zones and switches form accordingly
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("channel") and channel_form:
		change_form(channel_form)
	elif area.is_in_group("workstation") and workstation_form:
		change_form(workstation_form)
