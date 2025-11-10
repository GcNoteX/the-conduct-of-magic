extends Node

func revalidate_all_overlaps() -> void:
	for line in get_tree().get_nodes_in_group("mapline"):
		if line.has_method("validate_current_overlaps"):
			line.validate_current_overlaps()
