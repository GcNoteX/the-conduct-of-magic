class_name CollisionLayers
## The 2D physics layers named under Project Settings > Layer Names > 2D Physics, so code never
## sets a layer as a bare number. Layer numbers are 1-based, as in the editor; use bit() to turn
## one into a collision_layer / collision_mask bit.

const ENCHANTMENT_MAP_COMP := 1
const CURSOR := 2
const ENCHANTMENT_GRID := 3
const PHYSICAL_UI_ELEMENTS := 4
const WORKSPACE_ZONE := 5
const WORKSPACE_OBJECT := 6


## The collision_layer / collision_mask bit for a 1-based layer number
static func bit(layer: int) -> int:
	return 1 << (layer - 1)
