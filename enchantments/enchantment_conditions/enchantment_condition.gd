@abstract class_name EnchantmentCondition
extends Resource

@abstract func is_fulfilled(ctx: MaterialActivationContext) -> bool


## Player-facing description of the condition
func describe() -> String:
	return resource_name if resource_name != "" else "condition"
