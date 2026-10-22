class_name NumberOfConnectionsCondition
extends EnchantmentCondition
## Passes once the node holding the material reaches at least `number_of_lines` magic nodes.

## The number of magic nodes the holder of this condition has to reach (directly or through a chain)
@export var number_of_lines: int = 0


func is_fulfilled(ctx: MaterialActivationContext) -> bool:
	return ctx.get_connection_count() >= number_of_lines


func describe() -> String:
	return "reach %d+ magic nodes" % number_of_lines


func progress(ctx: MaterialActivationContext) -> String:
	return (
		"%d/%d magic nodes" % [mini(ctx.get_connection_count(), number_of_lines), number_of_lines]
	)
