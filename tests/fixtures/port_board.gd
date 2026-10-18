extends RefCounted

## A test board for big nodes with ports: an open 12 x 8 map with Bastion placed at ORIGIN and
## three magic nodes around its big node. Bastion's big node covers ORIGIN, +(1, 0), +(0, 1) and
## +(1, 1), with ports at ORIGIN and +(1, 1).

const BASTION := preload("res://enchantments/patterns/bastion.tres")
const ORIGIN := Vector2i(4, 3)
## Two cells up and right of port 0, two cells below port 1, and next to the big node's top
## right cell
const MAGIC_ABOVE := Vector2i(5, 1)
const MAGIC_BELOW := Vector2i(5, 6)
const MAGIC_SIDE := Vector2i(6, 2)


static func map() -> HexMapDefinition:
	var cells: Array[Vector2i] = []
	for row in 8:
		for col in 12:
			cells.append(Hex.offset_to_axial(col, row))
	var magic: Array[Vector2i] = [MAGIC_ABOVE, MAGIC_BELOW, MAGIC_SIDE]
	var m := HexMapDefinition.new()
	m.layout = HexMapDefinition.layout_from_cells(cells, magic)
	for i in m.get_magic_nodes().size():
		m.magic_edge_runes.append(RuneSet.of(0, 1, 0, 0))
		m.magic_harvest_runes.append(RuneSet.of(0, 2, 0, 0))
	return m


## A board on the open map with nothing placed yet
static func board(player: Player) -> InscriptionBoard:
	var item := EnchantableItemDefinition.new()
	item.map_template = map()
	var inst := ItemInstance.new()
	inst.definition = item
	return InscriptionBoard.new(inst, player)


static func path(cells: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(cells)
	return out
