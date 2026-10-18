@tool
class_name EnchantmentPatternLine
extends Resource

## One of an enchantment's own fixed lines: the two nodes it joins and the cells it runs through.
## Like a drawn line, it fills those cells so nothing else can use them.

## Index into Enchantment.nodes where the line starts
@export var from_node: int = 0
## Index into Enchantment.nodes where the line ends
@export var to_node: int = 1
## Axial offsets from the origin of the cells between the two nodes, in order from `from_node`.
## Each cell neighbours the one before it. Empty when the two nodes are neighbours.
@export var cells: Array[Vector2i] = []
