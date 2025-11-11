extends Area2D
class_name ItemBoxArea

func get_item_box() -> ItemBox:
	var current: Node = self
	while current:
		if current is ItemBox:
			return current
		current = current.get_parent()
	return null
