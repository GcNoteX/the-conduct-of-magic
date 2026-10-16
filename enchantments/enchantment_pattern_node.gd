class_name EnchantmentPatternNode
extends Resource

"""
One enchantment node in an Enchantment's fixed shape.
Acceptance uses the same rules as MaterialHolder: a minimum tier, then the attribute requirements.
"""

## Axial offset from the enchantment's origin cell
@export var offset: Vector2i = Vector2i.ZERO
## The tier the material has to be or greater
@export var tier_requirement: int = 1
## Same semantics as MaterialHolder.material_requirements
@export var material_requirements: Array[MaterialCondition] = []


func accepts(m: EnchantmentMaterialDefinition) -> bool:
	if m == null or m.tier < tier_requirement:
		return false
	if material_requirements.is_empty():
		return true
	var has_valid := false
	for requirement in material_requirements:
		if requirement.is_material_valid(m):
			has_valid = true
		elif requirement.required:
			return false
	return has_valid


func describe_requirements() -> String:
	var parts: Array[String] = []
	if tier_requirement > 1:
		parts.append("tier %d+" % tier_requirement)
	if material_requirements.is_empty():
		parts.append("any material")
	else:
		var names: Array[String] = []
		for req in material_requirements:
			var n: String = EnchantmentMaterialDefinition.MATERIAL_ATTRIBUTES.keys()[req.attribute]
			names.append(n + (" (required)" if req.required else ""))
		parts.append(" or ".join(names))
	return ", ".join(parts)
