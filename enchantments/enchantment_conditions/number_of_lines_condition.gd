class_name NumberOfLinesCondition
extends EnchantmentCondition
## Passes once at least `number_of_lines` lines are drawn onto the node holding the material.

## The number of lines that have to be drawn onto the holder of this condition
@export var number_of_lines: int = 0


func is_fulfilled(ctx: MaterialActivationContext) -> bool:
	return ctx.get_line_count() >= number_of_lines


func describe() -> String:
	return "%d+ lines drawn to it" % number_of_lines


func progress(ctx: MaterialActivationContext) -> String:
	return "%d/%d lines" % [mini(ctx.get_line_count(), number_of_lines), number_of_lines]
