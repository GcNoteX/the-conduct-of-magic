extends Area2D
class_name WorkstationCursorProxy

var hovered_object: WorkspaceObject = null

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

#func _on_area_entered(area: Area2D) -> void:
	#var form := area as WorkplaceForm
	#if form and form.owner_object:
		#hovered_object = form.owner_object
#
#func _on_area_exited(area: Area2D) -> void:
	#var form := area as WorkplaceForm
	#if form and form.owner_object == hovered_object:
		#hovered_object = null

func _physics_process(_delta: float) -> void:
	_refresh_hover_authoritative()

func _refresh_hover_authoritative() -> void:
	var found: WorkspaceObject = null

	for a in get_overlapping_areas():
		var obj := _resolve_owner_object_strict(a)
		if obj:
			found = obj
			break

	if found != hovered_object:
		hovered_object = found
		#print("proxy hovered_object ->", hovered_object)

func _resolve_owner_object_strict(area: Area2D) -> WorkspaceObject:
	# Walk up to the WorkplaceForm that owns this collider (could be child detector Area2D)
	var n: Node = area
	while n != null:
		if n is WorkplaceForm:
			var form := n as WorkplaceForm

			# CRITICAL: ignore disabled forms (deferred toggles settle by physics frame)
			# monitorable false is the main one; visible is a nice secondary guard
			if form.monitorable == false:
				return null
			if form.visible == false:
				return null

			return form.owner_object
		n = n.get_parent()

	return null
