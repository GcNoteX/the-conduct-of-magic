class_name InstantPassCondition
extends EnchantmentCondition


func is_fulfilled(_ctx: MaterialActivationContext) -> bool:
	return true


func describe() -> String:
	return "always activates"
