class_name PlacementState
extends Resource

## An enchantment placed on an item map

@export var id: int = 0
@export var enchantment: Enchantment
## Axial cell of the enchantment's origin node
@export var origin: Vector2i = Vector2i.ZERO
## Rotation in 60° clockwise steps
@export var rotation_steps: int = 0
## Material inserted in each node (null when empty), same order as enchantment.nodes
@export var materials: Array[EnchantmentMaterialDefinition] = []
@export var committed: bool = false
