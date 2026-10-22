class_name GraphState
extends Resource

"""
Everything carved on (or planned for) one item: placed enchantments, drawn lines and the
disenchant plan. Drafts live here too, so leaving an item and coming back keeps the plan.
Planned materials live here as well: planning one takes it out of the player's inventory and
holds it in this item until the plan is committed or the material is taken back out.
"""

@export var placements: Array[PlacementState] = []
@export var lines: Array[LineState] = []
@export var next_placement_id: int = 1
## The planned disenchant, in order (see DisenchantBoard)
@export var disenchant_plan: Array[DisenchantStep] = []


## The materials this item's plans hold: {material: count}, from draft enchantments' nodes and
## planned dissolves
func planned_materials() -> Dictionary[EnchantmentMaterialDefinition, int]:
	var out: Dictionary[EnchantmentMaterialDefinition, int] = {}
	for p in placements:
		if not p.committed:
			for m in p.materials:
				if m:
					out[m] = out.get(m, 0) + 1
	for s in disenchant_plan:
		if s.kind == DisenchantStep.Kind.DISSOLVE and s.material:
			out[s.material] = out.get(s.material, 0) + 1
	return out


## Drops every plan that isn't committed (draft enchantments, their lines and the disenchant
## plan) and returns the materials those plans held, so the caller can give them back
func drop_plans() -> Dictionary[EnchantmentMaterialDefinition, int]:
	var held := planned_materials()
	for p in placements.duplicate():
		if not p.committed:
			placements.erase(p)
	for l in lines.duplicate():
		if not l.committed:
			lines.erase(l)
	disenchant_plan.clear()
	return held
