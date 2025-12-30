@abstract
class_name WorkplaceForm
extends Area2D

func enable() -> void:
	set_process(true)
	set_physics_process(true)
	show()

	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

	# Re-enable collisions for all nested Area2Ds
	for child in get_children(true):
		if child is Area2D:
			child.set_deferred("monitoring", true)
			child.set_deferred("monitorable", true)

func disable() -> void:
	set_process(false)
	set_physics_process(false)
	hide()

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Disable collisions for all nested Area2Ds
	for child in get_children(true):
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
