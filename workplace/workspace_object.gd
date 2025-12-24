extends Area2D
class_name WorkspaceObject

@export var channel_form_tscn: PackedScene
@export var workstation_form_tscn: PackedScene

var channel_form: Area2D
var workstation_form: Area2D
var active_form: Area2D = null

func _ready() -> void:
	assert(channel_form_tscn, "Channel form required.")
	channel_form = channel_form_tscn.instantiate()
	assert(workstation_form_tscn, "Workstation form required.")
	workstation_form = workstation_form_tscn.instantiate()
	
	_disable_form(channel_form)
	_disable_form(workstation_form)
	add_child(channel_form)
	add_child(workstation_form)


func move(v: Vector2) -> void:
	global_position += v


# --- private methods ---
func _enable_form(f: Area2D) -> void:
	f.set_process(true)
	f.set_physics_process(true)
	f.show()

	f.set_deferred("monitoring", true)
	f.set_deferred("monitorable", true)

	# Re-enable collisions for all nested Area2Ds
	for child in f.get_children(true):
		if child is Area2D:
			child.set_deferred("monitoring", true)
			child.set_deferred("monitorable", true)


func _disable_form(f: Area2D) -> void:
	f.set_process(false)
	f.set_physics_process(false)
	f.hide()

	f.set_deferred("monitoring", false)
	f.set_deferred("monitorable", false)

	# Disable collisions for all nested Area2Ds
	for child in f.get_children(true):
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)



# --- public method ---
func change_form(target_form: Node2D) -> void:
	assert(target_form == channel_form or target_form == workstation_form, "Target form must be a valid form of this object.")

	if active_form:
		_disable_form(active_form)

	_enable_form(target_form)
	active_form = target_form


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("channel"):
		change_form(channel_form)
	elif area.is_in_group("workstation"):
		change_form(workstation_form)
