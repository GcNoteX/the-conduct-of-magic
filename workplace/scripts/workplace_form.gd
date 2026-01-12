@abstract
class_name WorkplaceForm
extends Area2D

var owner_object: WorkspaceObject = null

func enable() -> void:
	set_process(true)
	set_physics_process(true)
	show()

	set_deferred("monitorable", true)
	set_deferred("monitoring", true)

	# Re-enable collisions for all nested Area2Ds (recursive)
	for child in find_children("*", "Area2D", true, false):
		var area := child as Area2D
		area.set_deferred("monitorable", true)
		area.set_deferred("monitoring", true)


func disable() -> void:
	set_process(false)
	set_physics_process(false)
	hide()

	set_deferred("monitorable", false)
	set_deferred("monitoring", false)

	# Disable collisions for all nested Area2Ds (recursive)
	for child in find_children("*", "Area2D", true, false):
		var area := child as Area2D
		area.set_deferred("monitorable", false)
		area.set_deferred("monitoring", false)
