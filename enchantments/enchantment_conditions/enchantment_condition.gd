@abstract class_name EnchantmentCondition
extends Resource

@abstract func is_fulfilled(ctx: MaterialActivationContext) -> bool


## Player-facing description of the condition
func describe() -> String:
	return resource_name if resource_name != "" else "condition"


## Short progress shown on the board node, for example "1/2 lines"
func progress(ctx: MaterialActivationContext) -> String:
	return "ok" if is_fulfilled(ctx) else "not yet"
