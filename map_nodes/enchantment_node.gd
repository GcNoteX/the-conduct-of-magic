@tool
class_name EnchantmentNode
extends MapNode
## A node of an EnchantmentGrid: holds a material, activates when the material's conditions are
## met, connects to its grid's EnchantmentLines without limit, and kills MagicLines that may not
## connect to it.

signal embedded_material_changed(m: MapNode)

const MATERIAL_DISPLAY_SIZE: Vector2 = Vector2(64, 64)

var is_activated: bool = false

@onready var material_held: Sprite2D = $MaterialHeld
@onready var material_holder: MaterialHolder = $MaterialHolder
@onready var material_dropper: MaterialDropper = $MaterialDropper
# Animations
@onready var circular_motion_anim: CircularMotionAnim = $MaterialHeld/CircularMotionAnim


func _ready() -> void:
	_initialize_node()
	bounded_identity = get_parent()
	assert(
		bounded_identity is EnchantmentGrid, " EchantmentNode must have EnchantmentGrid as a parent"
	)
	embedded_material_changed.connect(EmapUpdateManager._on_vertex_material_changed)

	update_material_sprite()


func update_bounded_identity() -> void:
	bounded_identity = get_parent()


func update() -> void:
	update_activation()
	update_material_sprite()


# Handling Activation


## Updates the state of the EnchantmentNode based on whether it can be activated.
## Returns whether the node can be activated.
func update_activation() -> bool:
	var ctx := MaterialActivationContext.new(self)
	if material_holder.can_material_be_activated(ctx):
		if not is_activated:
			_activate_node()
		return true

	if is_activated:
		_deactivate_node()
	return false


# Handling Material


func update_material_sprite() -> void:
	var m := material_holder.get_embedded_material()
	if m == null:
		material_held.texture = null
		circular_motion_anim.set_sprite(material_held)
		return
	material_held.texture = m.enchantment_sprite_normal
	UtilityFunctions.clamp_sprite_size(material_held, MATERIAL_DISPLAY_SIZE)
	circular_motion_anim.set_sprite(material_held)


func _detection_areas() -> Array[Area2D]:
	return [self, line_detector, material_dropper]


## EnchantmentNode does not allow a line from a different EnchantmentGrid
func _may_connect(l: MapLine) -> bool:
	return not (l.bounded_identity is EnchantmentGrid and l.bounded_identity != bounded_identity)


func _activate_node() -> void:
	is_activated = true
	modulate = Color(1.0, 0.306, 0.36, 1.0)


func _deactivate_node() -> void:
	is_activated = false
	modulate = Color(1, 1, 1, 1.0)


func _on_material_holder_material_embedded() -> void:
	embedded_material_changed.emit(self)


func _on_material_holder_material_removed() -> void:
	embedded_material_changed.emit(self)
