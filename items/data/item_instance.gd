class_name ItemInstance
extends Resource

## One physical item the player holds: which definition it is, plus its own mutable state.

@export var id: StringName
@export var definition: ItemDefinition

# Optional runtime state (composition)
@export var inspectable_state: InspectableState = null
@export var enchantment_graph_state: GraphState = null


## The committed enchantments and what they do, or "nothing"
func carved_effects() -> String:
	if enchantment_graph_state == null:
		return "nothing"
	var effects: Array[String] = []
	for p in enchantment_graph_state.placements:
		if p.committed:
			effects.append(
				"%s (%s)" % [p.enchantment.enchantment_name, p.enchantment.effect_description]
			)
	return ", ".join(effects) if not effects.is_empty() else "nothing"
