@tool
extends Node

func update_all() -> void:
	if Engine.is_editor_hint():
		return

	for e in get_tree().get_nodes_in_group("enchantment"):
		if e.has_method("update_enchantment"):
			e.update_enchantment()
		else:
			push_warning("[EnchantmentUpdateManager]", e, " does not have method update_enchantment()!")

func update_enchantment(_e: Enchantment) -> void:
	if Engine.is_editor_hint():
		return
	return
	#e.update_enchantment()

func _on_EnchantmentNode_updated() -> void:
	if Engine.is_editor_hint():
		return
	return
	#print("Call ENode updated")
	#update_all()
	
func _on_MapLine_locked(_l: MapLine) -> void:
	if Engine.is_editor_hint():
		return
	return
	#print("Call Locked")
	#update_all()

func _on_MapLine_destroyed(_l: MapLine) -> void:
	if Engine.is_editor_hint():
		return
	return
	#print("Call Destroyed")
	#update_all()

func _on_MapLine_spawned(_l: MapLine) -> void:
	if Engine.is_editor_hint():
		return
	return
	#print("Call Spawn")
	#update_all()
