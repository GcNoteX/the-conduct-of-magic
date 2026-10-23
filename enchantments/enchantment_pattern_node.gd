@tool
class_name EnchantmentPatternNode
extends Resource
## One enchantment node in an Enchantment's fixed shape.
## A material fits if it meets the minimum tier, passes every required condition, and passes at
## least one condition (any material passes when there are none).

## Axial offset from the enchantment's origin cell
@export var offset: Vector2i = Vector2i.ZERO
## The tier the material has to be or greater
@export var tier_requirement: int = 1
## The material's attribute conditions, checked as described above
@export var material_requirements: Array[MaterialCondition] = []
## Other cells this node covers, as axial offsets from the node's own cell (`offset`).
## They're taken like the node's own cell. Lines attach only at the node's ports.
@export var extra_cells: Array[Vector2i] = []
## The cells where lines attach (fixed lines and drawn lines), as axial offsets from the node's own
## cell: each is (0, 0) or one of extra_cells. Empty means lines attach at the node's own cell.
## However many ports it has, it's one node: all its lines count together.
@export var ports: Array[Vector2i] = []


## The node's ports as offsets from its own cell, (0, 0) when none are set
func port_offsets() -> Array[Vector2i]:
	if ports.is_empty():
		return [Vector2i.ZERO] as Array[Vector2i]
	return ports.duplicate()


## Every cell the node covers, as offsets from its own cell: (0, 0) first, then extra_cells
func covered_offsets() -> Array[Vector2i]:
	var out: Array[Vector2i] = [Vector2i.ZERO]
	out.append_array(extra_cells)
	return out


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
