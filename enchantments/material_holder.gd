@tool
class_name MaterialHolder
extends Node
## Holds one EnchantmentMaterialDefinition for its owning MapNode: checks whether a material may
## be embedded, embeds and removes it, and checks the material's activation conditions.

signal material_embedded
signal material_removed

@export var material_holder_owner: MapNode
@export var embedded_material: EnchantmentMaterialDefinition = null
## The tier the EnchantMaterial has to be or greater to be embedded into EnchantmentNode
@export var tier_requirement: int = 1
## The requirements an EnchantmentMaterialDefinition has to fulfill to be allowed to be embedded
## into EnchantmentNode, checks the material_attributes attribute of EnchantmentMaterialDefinition
@export var material_requirements: Array[MaterialCondition]

## A sealed holder keeps its embedded material: it cannot be taken back out.
var sealed: bool = false


func _ready() -> void:
	assert(material_holder_owner, " Material Holder needs an owner! ")


## You can only embed a material if it meets
## - The tier requirement
## - All the required material_requirements
## - At least 1 material_requirement
func can_embbed_material(m: EnchantmentMaterialDefinition) -> bool:
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
	material_embedded.emit()


func remove_material() -> EnchantmentMaterialDefinition:
	var m := embedded_material
	embedded_material = null
	material_removed.emit()
	return m


func get_embedded_material() -> EnchantmentMaterialDefinition:
	return embedded_material


## A material can be activated if all of the embedded material's conditions are fulfilled
func can_material_be_activated(ctx: MaterialActivationContext) -> bool:
	if not embedded_material:
		return false
	for condition in embedded_material.activation_conditions:
		if not condition.is_fulfilled(ctx):
			return false
	return true
