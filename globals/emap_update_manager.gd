@tool
extends Node
## EmapUpdateManager: keeps the legacy play maps up to date. Map elements ask for an update when
## something changes; the manager collects those requests and runs one update per map at the end
## of the frame, however many changes came in.

## The roots waiting for an update at the end of this frame. A root is an EnchantmentMap, or the
## scene tree root for elements that are not on any map.
var _pending: Dictionary[Node, bool] = {}


#
# ────────────────────────────────────────────
#   PUBLIC: Master Update Pipeline
# ────────────────────────────────────────────
#
## Asks for the map that `element` sits in to be updated at the end of this frame. Several
## requests in one frame lead to one update.
func request_update(element: Node) -> void:
	if Engine.is_editor_hint():
		return
	var root := _root_of(element)
	if _pending.is_empty():
		_flush.call_deferred()
	_pending[root] = true


## The roots with an update still waiting for the end of the frame
func pending_roots() -> Array[Node]:
	return _pending.keys()


## Updates every element in the scene tree now
func update_all() -> void:
	update_map(get_tree().root)


## Updates every element below `root` now: identities of nodes, then lines, then overlaps, then
## enchantments.
func update_map(root: Node) -> void:
	if Engine.is_editor_hint():
		return

	_update_map_nodes(root)
	_update_map_lines(root)
	_update_overlaps(root)
	_update_enchantments(root)


#
# ────────────────────────────────────────────
#   UTILITY HELPERS
# ────────────────────────────────────────────
#
func add_to_enchantment_map(node: Node2D, global_pos: Vector2 = Vector2.ZERO) -> void:
	var map := get_tree().get_first_node_in_group(Groups.ENCHANTMENT_MAP) as Node2D
	if map:
		map.add_child(node)
		node.position = map.to_local(global_pos)
	else:
		push_error("No EnchantmentMap found in the current scene!")


func handle_unhandled_map_item(i: MapItem) -> void:
	print("Adding material back to player")
	PlayerManager.add_material(i.e_material)
	i.queue_free()


func _flush() -> void:
	var roots := _pending.keys()
	_pending.clear()
	for root: Node in roots:
		if is_instance_valid(root) and root.is_inside_tree():
			update_map(root)


## The map `element` sits in. Falls back to the whole tree for an element that is not on a map,
## or no longer in the tree.
func _root_of(element: Node) -> Node:
	if not is_instance_valid(element) or not element.is_inside_tree():
		return get_tree().root
	var map := EnchantmentMap.of(element)
	return map if map else get_tree().root


## The elements of `group` that sit below `root`
func _members(group: StringName, root: Node) -> Array[Node]:
	var members: Array[Node] = []
	for n in get_tree().get_nodes_in_group(group):
		if root.is_ancestor_of(n):
			members.append(n)
	return members


#
# ────────────────────────────────────────────
#   SECTION 1: MapNodes
# ────────────────────────────────────────────
#
func _update_map_nodes(root: Node) -> void:
	for node in _members(Groups.MAP_NODE, root):
		if node.has_method("update_bounded_identity"):
			node.update_bounded_identity()
		else:
			push_warning(
				"%s in group '%s' lacks update_bounded_identity()" % [node, Groups.MAP_NODE]
			)


#
# ────────────────────────────────────────────
#   SECTION 2: MapLines
# ────────────────────────────────────────────
#
func _update_map_lines(root: Node) -> void:
	for line in _members(Groups.MAP_LINE, root):
		if line.has_method("update_bounded_identity"):
			line.update_bounded_identity()
		else:
			push_warning(
				"%s in group '%s' lacks update_bounded_identity()" % [line, Groups.MAP_LINE]
			)


#
# ────────────────────────────────────────────
#   SECTION 3: Overlaps
# ────────────────────────────────────────────
#
func _update_overlaps(root: Node) -> void:
	for line in _members(Groups.MAP_LINE, root):
		if line.has_method("validate_current_overlaps"):
			line.validate_current_overlaps()


#
# ────────────────────────────────────────────
#   SECTION 4: Enchantments
# ────────────────────────────────────────────
#
func _update_enchantments(root: Node) -> void:
	for e in _members(Groups.ENCHANTMENT, root):
		if e.has_method("update_enchantment"):
			e.update_enchantment()
		else:
			push_warning("[MapSystem] %s lacks update_enchantment()!" % str(e))


#
# ────────────────────────────────────────────
#   SIGNAL ENTRY POINTS
# ────────────────────────────────────────────
#
func _on_MapNode_connections_updated(node: MapNode) -> void:
	request_update(node)


func _on_vertex_material_changed(v: MapNode) -> void:
	request_update(v)
