class_name ItemInstance
extends Resource

## One physical item the player holds: which definition it is, plus its own mutable state.

@export var id: StringName
@export var definition: ItemDefinition

# Optional runtime state (composition)
@export var inspectable_state: InspectableState = null
@export var enchantment_graph_state: GraphState = null


## The item's name with its number, like "Short sword #2"
func display_name() -> String:
	var n := definition.display_name if definition.display_name != "" else str(definition.id)
	return "%s #%s" % [n, str(id).get_slice("_", str(id).get_slice_count("_") - 1)]


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
