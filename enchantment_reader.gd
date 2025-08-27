class_name EnchantmentReader
extends Node

@export var map: EnchantmentMap

func _ready() -> void:
	map.updated.connect(evaluate_enchantment)
	await map.map_initialized
	evaluate_enchantment()

func evaluate_enchantment() -> void:
	pass
