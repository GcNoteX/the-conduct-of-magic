class_name EnchantmentMap
extends Node2D

@export var sockets: Array[Socket]
@export var magic_edges: Array[MagicEdge]

func _ready() -> void:
	sockets.clear()
	magic_edges.clear()
	
	for child in get_children():
		if child is Socket:
			sockets.append(child)
		elif child is MagicEdge:
			magic_edges.append(child)
