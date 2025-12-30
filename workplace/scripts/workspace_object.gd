extends Area2D
class_name WorkspaceObject

"""
Represents an item in the workspace with channel and workstation forms.
Handles switching between forms and links runtime states (inspection, enchantments, etc.).
"""

signal form_changed(obj: WorkplaceForm)

@export var item: ItemInstance

var channel_form: ChannelForm = null
var workstation_form: WorkStationForm = null
var active_form: WorkplaceForm = null

func _ready() -> void:
	# Instantiate channel form if available
	if item.definition.channel_form:
		channel_form = item.definition.channel_form.instantiate()
		assert(channel_form is ChannelForm, "channel_form must be a ChannelForm node")
		channel_form.disable()
		add_child(channel_form)

	# Instantiate workstation form if available
	if item.definition.workstation_form:
		workstation_form = item.definition.workstation_form.instantiate()
		assert(workstation_form is WorkStationForm, "workstation_form must be a WorkStationForm node")

		# Pass inspectable state if it exists
		if item.inspectable_state:
			workstation_form._item_state = item.inspectable_state.inspected

		workstation_form.disable()
		add_child(workstation_form)

# --- movement helper ---
func move(v: Vector2) -> void:
	global_position += v

# --- public method ---
func change_form(target_form: WorkplaceForm) -> void:
	assert(target_form == channel_form or target_form == workstation_form, "Target form must be a valid form of this object.")
	if active_form:
		active_form.disable()
	target_form.enable()
	active_form = target_form

# --- signal handler for area detection ---
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("channel") and channel_form:
		change_form(channel_form)
		emit_signal("form_changed", channel_form)
	elif area.is_in_group("workstation") and workstation_form:
		change_form(workstation_form)
		emit_signal("form_changed", workstation_form)
