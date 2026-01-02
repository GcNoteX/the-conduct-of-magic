extends Camera2D

@export var auto_center: bool = true

func _ready() -> void:
	if auto_center:
		_center_in_viewport()


func _center_in_viewport() -> void:
	# Center the camera based on the SubViewport resolution
	var vp_size: Vector2 = get_viewport().size
	position = vp_size * 0.5
