extends Area2D
class_name WorkstationCursorProxy

var hovered_object: WorkspaceObject = null

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _on_area_entered(area: Area2D) -> void:
	var form := area as WorkplaceForm
	if form and form.owner_object:
		hovered_object = form.owner_object

func _on_area_exited(area: Area2D) -> void:
	var form := area as WorkplaceForm
	if form and form.owner_object == hovered_object:
		hovered_object = null
