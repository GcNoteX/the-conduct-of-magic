extends Node2D

func _ready() -> void:
	Input.warp_mouse(Vector2(10,10))

func _process(delta: float) -> void:
	Input.warp_mouse_position(Vector2(10,10))
