extends Node

@onready var workstation_cursor: WorkstationCursor = $Node2D/WorkstationCursor

func _ready() -> void:
	workstation_cursor.enable_cursor()
