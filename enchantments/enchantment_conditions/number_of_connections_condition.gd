class_name NumberOfConnectionsConditon
extends EnchantmentCondition

## The number of MagicEdges that has to be connected to the holder of this condition
@export var number_of_lines: int = 0 

func is_fulfilled(ctx: MaterialActivationContext) -> bool:
	print("[NumberOfConnectionsConditon] Connections: ", ctx.start_node.connections.size())
	return ctx.start_node.connections.size() >= number_of_lines
