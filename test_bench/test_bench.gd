class_name TestBench
extends Control

## A place to try carving and disenchanting without playing a day: the inscribing table on its
## own, opened on a player with the demo items (blank weapons and a pre-carved sword). Run this
## scene from the editor (F6).

@export var setup: DemoSetup = preload("res://inscribing/demo/demo_setup.tres")

@onready var table: InscribingTable = $InscribingTable


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var player := setup.create_player()
	PlayerManager.set_player(player)
	table.open(player, setup.shown_materials())
