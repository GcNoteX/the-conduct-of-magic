class_name InstantPassCondition
extends EnchantmentCondition


func is_fulfilled(_ctx: MaterialActivationContext) -> bool:
	return true


func describe() -> String:
	return "always activates"


func progress(_ctx: MaterialActivationContext) -> String:
	return "ready"
