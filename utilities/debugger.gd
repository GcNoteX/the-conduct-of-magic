extends Node

@export var debug_all: bool = true 
@export var deep_search: bool = true
@export var nodes: Array[Node]

func _ready() -> void:
	if debug_all:
		var p = get_parent()
		if deep_search:
			deep_enable_search(p)
		else:
			for child in p.get_children():
				if child.has_method("enable_debug"):
					print("Enabling debug")
					child.enable_debug()
				
	else:
		for node in nodes:
			if node == null:
				continue
				
			if node.has_method("enable_debug"):
				node.enable_debug()
			else:
				print(node, "does not have enable_debug()")

func deep_enable_search(node: Node) -> void:
	for child in node.get_children():
		if child.has_method("enable_debug"):
			print("Enabling debug")
			child.enable_debug()
		deep_enable_search(child)
