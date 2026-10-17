class_name InstantFailCondition
extends EnchantmentCondition


func is_fulfilled(_ctx: MaterialActivationContext) -> bool:
	return false


func describe() -> String:
	return "never activates"


func progress(_ctx: MaterialActivationContext) -> String:
	return "never"
