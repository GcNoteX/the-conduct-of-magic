@tool
extends Node

#
# ────────────────────────────────────────────
#   PUBLIC: Master Update Pipeline
# ────────────────────────────────────────────
#
func update_all() -> void:
	if Engine.is_editor_hint():
		return

	_update_map_nodes()
	_update_map_lines()
	_update_overlaps()
	_update_enchantments()


#
# ────────────────────────────────────────────
#   SECTION 1: MapNodes
# ────────────────────────────────────────────
#
func _update_map_nodes() -> void:
	for node in get_tree().get_nodes_in_group("mapnode"):
		if node.has_method("update_bounded_identity"):
			node.update_bounded_identity()
		else:
			push_warning(
				"%s in group 'mapnode' lacks update_bounded_identity()" % str(node)
			)


#
# ────────────────────────────────────────────
#   SECTION 2: MapLines
# ────────────────────────────────────────────
#
func _update_map_lines() -> void:
	for line in get_tree().get_nodes_in_group("mapline"):
		if line.has_method("update_bounded_identity"):
			line.update_bounded_identity()
		else:
			push_warning(
				"%s in group 'mapline' lacks update_bounded_identity()" % str(line)
			)


#
# ────────────────────────────────────────────
#   SECTION 3: Overlaps
# ────────────────────────────────────────────
#
func _update_overlaps() -> void:
	for line in get_tree().get_nodes_in_group("mapline"):
		if line.has_method("validate_current_overlaps"):
			line.validate_current_overlaps()


#
# ────────────────────────────────────────────
#   SECTION 4: Enchantments
# ────────────────────────────────────────────
#
func _update_enchantments() -> void:
	for e in get_tree().get_nodes_in_group("enchantment"):
		if e.has_method("update_enchantment"):
			e.update_enchantment()
		else:
			push_warning("[MapSystem] %s lacks update_enchantment()!" % str(e))


#
# ────────────────────────────────────────────
#   UTILITY HELPERS
# ────────────────────────────────────────────
#
func add_to_enchantment_map(node: Node2D, global_pos: Vector2=Vector2.ZERO) -> void:
	var map := get_tree().get_first_node_in_group("enchantment_map") as Node2D
	if map:
		map.add_child(node)
		node.position = map.to_local(global_pos)
	else:
		push_error("No EnchantmentMap found in the current scene!")


func handle_unhandled_map_item(i: MapItem) -> void:
	print("Adding material back to player")
	PlayerManager.add_material(i.e_material)
	i.queue_free()


#
# ────────────────────────────────────────────
#   SIGNAL ENTRY POINTS
# ────────────────────────────────────────────
#
func _on_MapNode_connections_updated() -> void:
	if Engine.is_editor_hint():
		return
	update_all()

func _on_vertex_material_changed(_v: MapNode) -> void:
	if Engine.is_editor_hint():
		return
	update_all()

func _on_MapLine_changed(_l: MagicLine) -> void:
	if Engine.is_editor_hint():
		return
	update_all()

func _on_EnchantmentNode_updated() -> void:
	if Engine.is_editor_hint():
		return
	update_all()
