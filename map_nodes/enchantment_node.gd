@tool
extends MapNode
class_name EnchantmentNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicLineConnectableComponent if one is detected
- Can insert EnchantmentMaterial into to activate
- Can connect to EnchantmentLine's unlimitedly
"""

signal embedded_material_changed(m: MapNode)

@onready var line_detector: LineDetector = $LineDetector
@onready var material_held: Sprite2D = $MaterialHeld
@onready var material_holder: MaterialHolder = $MaterialHolder
@onready var material_dropper: MaterialDropper = $MaterialDropper

"""Animations"""
@onready var circular_motion_anim: CircularMotionAnim = $MaterialHeld/CircularMotionAnim

var is_activated: bool = false

const material_display_size: Vector2 = Vector2(64, 64)

func _ready() -> void:
	_initialize_node()
	bounded_identity = get_parent()
	assert(bounded_identity is EnchantmentGrid, " EchantmentNode must have EnchantmentGrid as a parent")
	embedded_material_changed.connect(EmapUpdateManager._on_vertex_material_changed)
	
	update_material_sprite()
	
func update_bounded_identity() -> void:
	bounded_identity = get_parent()

func _on_line_connector_allowed_line_type_detected(l: MapLine) -> void:
	if l in mapline_connections: # Sometimes the detector will detect the same line again, these are ignored by this node
		return
	
	if !passes_base_conditions(l):
		#print("Failed Base Conditions")
		l.kill_line()
		return
	
	## Condition1: EnchantmentNode does not allow a line from a different EnchantmentGrid
	if l.bounded_identity is EnchantmentGrid and \
		l.bounded_identity != bounded_identity:
		#print("Failed Condition2")
		l.kill_line()
		return
	
	add_line_connection(l)
	l.lock_line(self)

func _on_line_connector_invalid_line_type_detected(l: MapLine) -> void:
	# Destroys invalid 
	l.kill_line()

func update() -> void:
	update_activation()
	update_material_sprite()

"""
Handling Activation
"""
## Updates the state of the EnchantmentNode based on whether it can be activated.
## Returns whether the node can be activated.
func update_activation() -> bool:
	var ctx = MaterialActivationContext.new(self)
	if material_holder.can_material_be_activated(ctx):
		#print("Material activated! Activating node:")
		if !is_activated:
			_activate_node()
		return true
	else:
		#print("Material not activated.")
		if is_activated:
			_deactivate_node()
		return false


func _activate_node() -> void:
	is_activated = true
	self.modulate =Color(1.0, 0.306, 0.36, 1.0)


func _deactivate_node() -> void:
	is_activated = false
	self.modulate =Color(1, 1, 1, 1.0)



"""
Handling Material
"""
func _on_material_holder_material_embedded() -> void:
	emit_signal("embedded_material_changed", self)


func _on_material_holder_material_removed() -> void:
	emit_signal("embedded_material_changed", self)


func update_material_sprite() -> void:
	var m = material_holder.get_embedded_material()
	if m == null:
		material_held.texture = null
		circular_motion_anim.set_sprite(material_held)
		return
	material_held.texture = m.material_sprite
	UtilityFunctions.clamp_sprite_size(material_held, material_display_size)
	circular_motion_anim.set_sprite(material_held)
"""
Handling Cursors
"""

func handle_drag_out(c: EnchantmentCursor) -> void:
	if c is DrawCursor:
		if !c.controlled_line and has_capacity():
			# Create a new MagicLine
			var l: MagicLine = preload(SceneReferences.magic_line).instantiate()
			l.start = self
			# Draw the line from this node
			EmapUpdateManager.call_deferred("add_to_enchantment_map", l, global_position)
			# Attach it to the DrawCursor
			l.locked.connect(c._on_MagicLine_locked)
			c.controlled_line = l

"""
Detectiong Handling
"""

func enable_detection() -> void:
	monitorable = true
	monitoring = true
	line_detector.monitorable = true
	line_detector.monitoring = true
	material_dropper.monitorable = true
	material_dropper.monitoring = true

func disable_detection() -> void:
	monitorable = false
	monitoring = false
	line_detector.monitorable = false
	line_detector.monitoring = false
	material_dropper.monitorable = false
	material_dropper.monitoring = false
