@tool
extends Node
class_name MaterialHolder

"""
- Holds valid EnchantmentMaterialDefinition.
- Provides actions to insert, remove the EnchantmentMaterialDefinition.
- Can check if material conditions are fulfilled
"""

signal material_embedded
signal material_removed

@export var material_holder_owner: MapNode

var sealed = false ## An attribute to dictate whether the embedded_material can be removed and returned, or just removed.
@export var embedded_material: EnchantmentMaterialDefinition = null

## The tier the EnchantMaterial has to be or greater to be embedded into EnchantmentNode
@export var tier_requirement: int = 1
## The requirements an EnchantmentMaterialDefinition has to fulfill to be allowed to be embedded into EnchantmentNode, 
## checks the material_attributes attribute of EnchantmentMaterialDefinition
@export var material_requirements: Array[MaterialCondition]



func _ready() -> void:
	assert(material_holder_owner, " Material Holder needs an owner! ")

func can_embbed_material(m: EnchantmentMaterialDefinition) -> bool:
	"""
	You can only embed a material if it meets
	- The tier requirement
	- All the required material_requirements
	- At least 1 material_requirement
	"""
	# Tier check
	if m.tier < tier_requirement:
		return false

	# No requirements = automatically valid
	if material_requirements.is_empty():
		return true

	var has_valid := false

	for requirement in material_requirements:
		if requirement.is_material_valid(m):
			has_valid = true
		elif requirement.required:
			# If a required one fails, whole thing fails immediately
			return false

	# Only return true if at least one valid match found
	return has_valid

func embbed_material(m: EnchantmentMaterialDefinition) -> void:
	embedded_material = m
	emit_signal("material_embedded")

func remove_material() -> EnchantmentMaterialDefinition:
	var m = embedded_material
	embedded_material = null
	emit_signal("material_removed")
	return m

func get_embedded_material() -> EnchantmentMaterialDefinition:
	return embedded_material

func can_material_be_activated(ctx: MaterialActivationContext) -> bool: # NOTE: What should be inserted as a parameter to check
	"""
	A material component can be activated if:
		- All embedded material conditions are true
	"""
	if !embedded_material:
		return false
	for condition in embedded_material.activation_conditions:
		if not condition.is_fulfilled(ctx):
			return false
	return true
