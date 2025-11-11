@tool
extends Node

func update_all() -> void:
	if Engine.is_editor_hint():
		return

	# Process MapNodes first
	for node in get_tree().get_nodes_in_group("mapnode"):
		if node.has_method("update_bounded_identity"):
			node.update_bounded_identity()
		else:
			push_warning(
				"%s in group 'mapnode' lacks method 'update_bounded_identity'" % str(node)
			)

	# Then process MapLines
	#print("===Updating All Lines===")
	for line in get_tree().get_nodes_in_group("mapline"):
		if line.has_method("update_bounded_identity"):
			line.update_bounded_identity()
		else:
			push_warning(
				"%s in group 'mapline' lacks method 'update_bounded_identity'" % str(line)
			)
	
	OverlapsUpdateManager.revalidate_all_overlaps()
	EnchantmentUpdateManager.update_all()

func _on_MapNode_connections_updated() -> void:
	update_all()
