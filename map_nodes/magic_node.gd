class_name MagicNode
extends MapNode
## A node of the item's own map: takes MagicLines that may connect to it and kills the rest, and
## can only be drawn from when activated. Takes its bounded identity from the nodes it reaches.

@onready
var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent


func _ready() -> void:
	_initialize_node()


func update_bounded_identity() -> void:
	# Collect all reachable nodes via DFS
	var connected_nodes := gather_connections(self)

	# Gather all identities
	var identities := {}
	for node in connected_nodes:
		# Only gather identities from those that are able to give it, but also are permanent
		# (i.e. are source's of identities)
		if (
			node
			and node.can_share_identity
			and not node.can_change_identity
			and node.bounded_identity
		):
			identities[node.bounded_identity] = true

	var keys := identities.keys()
	if keys.has(null):
		keys.erase(null)

	# Warn if multiple different identities are detected
	if keys.size() > 1:
		push_error("%s has mismatched connected identities %s" % [self, str(keys)])
		bounded_identity = keys[0]  # stable fallback
	elif keys.size() == 1:
		bounded_identity = keys[0]
	else:
		bounded_identity = null


func _detection_areas() -> Array[Area2D]:
	return [self, line_detector, cursor_detector]


## If both identities are bound to an EnchantmentGrid, they cannot be different
func _may_connect(l: MapLine) -> bool:
	return not (
		bounded_identity is EnchantmentGrid
		and l.bounded_identity is EnchantmentGrid
		and l.bounded_identity != bounded_identity
	)


func _on_connections_updated() -> void:
	update_bounded_identity()
