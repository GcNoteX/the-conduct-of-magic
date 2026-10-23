class_name MaterialActivationContext
extends RefCounted
## What a material's activation conditions can see about its node on the inscribing board

var board: InscriptionBoard  # hex inscribing board
var node_key: String = ""  # the enchantment node being checked on the board


static func for_board(b: InscriptionBoard, key: String) -> MaterialActivationContext:
	var ctx := MaterialActivationContext.new()
	ctx.board = b
	ctx.node_key = key
	return ctx


## Lines drawn directly onto the node
func get_line_count() -> int:
	return board.line_count(node_key) if board else 0


## Magic nodes the node reaches through drawn lines (chains through magic nodes count)
func get_connection_count() -> int:
	return board.reachable_magic_nodes(node_key).size() if board else 0
