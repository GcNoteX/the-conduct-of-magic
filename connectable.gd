# connectable.gd
extends RefCounted
class_name IConnectable

func get_bounded_identity() -> String:
	push_error("get_bounded_identity not implemented!")
	return ""
