@tool
extends Node

func update_all() -> void:
	if Engine.is_editor_hint():
		return

	for e in get_tree().get_nodes_in_group("enchantment"):
		#print("Updating ", e)
		e.update_enchantment()

func update_enchantment(e: Enchantment) -> void:
	if Engine.is_editor_hint():
		return
	e.update_enchantment()

func _on_EnchantmentNode_updated() -> void:
	if Engine.is_editor_hint():
		return
	update_all()
	
func _on_MagicLine_locked() -> void:
	if Engine.is_editor_hint():
		return
	print("Call Locked")
	update_all()

func _on_MagicLine_destroyed(_l: MagicLine) -> void:
	if Engine.is_editor_hint():
		return
	print("Call Destroyed")
	update_all()

func _on_MagicLine_spawned() -> void:
	if Engine.is_editor_hint():
		return
	print("Call Spawn")
	update_all()
