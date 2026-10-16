# material_activation_context.gd
class_name MaterialActivationContext
extends RefCounted

var source_node: MapNode # the source node (old play map)
var enchantment: EnchantmentGrid # local subgraph (old play map)
var map: EnchantmentMap # global graph (old play map)

var board: InscriptionBoard # hex inscribing board
var node_key: String = "" # the enchantment node being checked on the board

func _init(s: MapNode = null, e: EnchantmentGrid = null, m: EnchantmentMap = null) -> void:
	self.source_node = s
	self.enchantment = e
	self.map = m

static func for_board(b: InscriptionBoard, key: String) -> MaterialActivationContext:
	var ctx := MaterialActivationContext.new()
	ctx.board = b
	ctx.node_key = key
	return ctx

## Lines drawn directly onto the node
func get_line_count() -> int:
	if board:
		return board.line_count(node_key)
	return source_node.mapline_connections.size() if source_node else 0

## Magic nodes the node reaches through drawn lines (chains through magic nodes count)
func get_connection_count() -> int:
	if board:
		return board.reachable_magic_nodes(node_key).size()
	return source_node.mapnode_connections.size() if source_node else 0
