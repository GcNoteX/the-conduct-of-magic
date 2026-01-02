class_name ItemInstance
extends Resource

@export var id: StringName
@export var definition: ItemDefinition

# Optional runtime state (composition)
@export var inspectable_state: InspectableState = null
@export var enchantment_graph_state: GraphState = null
