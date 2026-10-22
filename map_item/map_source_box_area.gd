class_name MapSourceBoxArea
extends Area2D
## The hoverable area inside a MapSourceBox. The cursor hovers this area and asks it for the
## box it belongs to.


## The nearest ancestor (or this area itself) that is a MapSourceBox, or null
func get_box() -> MapSourceBox:
	var current: Node = self
	while current:
		if current is MapSourceBox:
			return current
		current = current.get_parent()
	return null
