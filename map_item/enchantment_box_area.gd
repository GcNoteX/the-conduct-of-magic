extends Area2D
class_name EnchantmentBoxArea

func get_enchantment_box() -> EnchantmentBox:
	var current: Node = self
	while current:
		if current is EnchantmentBox:
			return current
		current = current.get_parent()
	return null
