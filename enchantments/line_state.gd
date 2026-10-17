class_name LineState
extends Resource

## A line the player drew between two nodes, by node key (see InscriptionBoard).
## It runs cell by cell and fills every cell between its two nodes.

@export var a: String = ""
@export var b: String = ""
@export var committed: bool = false
## Axial cells the line runs through, from node `a` to node `b`, both end cells included
@export var cells: Array[Vector2i] = []
