extends MapNode
class_name MagicNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicNode if one is detected
- Can only be drawn from when activated
"""

@onready var line_detector: LineDetector = $LineDetector
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent

"""
Handling Activation
"""

func _ready() -> void:
	_initialize_node()
	#connections_updated.connect(_on_connections_updated)

func update_bounded_identity() -> void:
	# Collect all reachable nodes via DFS
	var connected_nodes := gather_connections(self)
	
	# Gather all identities
	var identities := {}
	for node in connected_nodes:
		# Only gather identities from those that are able to give it, but also are permanent (i.e. are source's of identities)
		if node and node.can_share_identity and !node.can_change_identity and node.bounded_identity:
			identities[node.bounded_identity] = true
	
	var keys := identities.keys()
	#print(self, " valid identities ", keys)
	if keys.has(null):
		keys.erase(null)
	
	#print(self, " valid identities", identities)
	# Warn if multiple different identities are detected
	if keys.size() > 1:
		push_error(
			"%s has mismatched connected identities %s"
			% [self, str(keys)]
		)
		bounded_identity = keys[0]  # stable fallback
	elif keys.size() == 1:
		bounded_identity = keys[0]
	else:
		bounded_identity = null


func _on_connections_updated() -> void:
	update_bounded_identity()

func _on_line_connector_allowed_line_type_detected(l: MapLine) -> void:
	if l in mapline_connections: # Sometimes the detector will detect the same line again, these are ignored by this node
		return
	
	if !passes_base_conditions(l):
		#print("Failed base conditions")
		l.kill_line()
		return
	#print("Passed base conditions")

	## Condition1: If both identities are bound to an EnchantmentGrid, they cannot be different
	if bounded_identity is EnchantmentGrid and \
		l.bounded_identity is EnchantmentGrid and \
		l.bounded_identity != bounded_identity:
		
		l.kill_line()
		return
	
	add_line_connection(l)
	l.lock_line(self)


func _on_line_connector_invalid_line_type_detected(l: MapLine) -> void:
	# Destroys invalid 
	l.kill_line()

"""
Handling Cursor's
"""

func handle_drag_out(c: EnchantmentCursor) -> void:
	if c is DrawCursor:
		if !c.controlled_line and has_capacity():
			# Create a new MagicLine
			var l: MagicLine = preload(SceneReferences.magic_line).instantiate()
			l.start = self
			#print("Magic Line Created: ", l)
			# Draw the line from this node
			EmapUpdateManager.call_deferred("add_to_enchantment_map", l, global_position)
			# Attach it to the DrawCursor
			l.locked.connect(c._on_MagicLine_locked)
			c.controlled_line = l

"""
Detection Handling
"""

func enable_detection() -> void:
	monitorable = true
	monitoring = true
	line_detector.monitorable = true
	line_detector.monitoring = true
	cursor_detector.monitorable = true
	cursor_detector.monitoring = true

func disable_detection() -> void:
	monitorable = false
	monitoring = false
	line_detector.monitorable = false
	line_detector.monitoring = false
	cursor_detector.monitorable = false
	cursor_detector.monitoring = false
