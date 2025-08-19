extends Node2D

@export var starting_socket: Socket = null
@export var ending_socket: Socket = null

@export_category("Debug Settings")
@export var is_debug: bool = false

func _ready() -> void:
	for child in get_children():
		assert(child is Socket, "ERROR: Socket Controller may only have children of type Socket during instantiation")
		child = child as Socket
		child.selected_as_start.connect(_on_start_socket_selected)
		child.selected_as_end.connect(_on_end_socket_selected)
		child.cancel_selection.connect(_on_cancel_selection)

func _on_start_socket_selected(s: Socket) -> void:
	starting_socket = s

func _on_end_socket_selected(s: Socket) -> void:
	ending_socket = s
	_attempt_make_edge()
	
func _on_cancel_selection() -> void:
	call_deferred("_cancel_saved_selections")

func _attempt_make_edge() -> void:
	if !starting_socket:
		push_warning(" No starting socket, attempt failed")
	if !ending_socket:
		push_warning(" No ending socket, attempt failed")
	if starting_socket and ending_socket:
		var edge: MagicEdge = MagicEdge.create_magic_edge(starting_socket, ending_socket, is_debug)
		add_child(edge)


func _cancel_saved_selections() -> void:
	# Cancel Selection
	starting_socket = null
	ending_socket = null


func enable_debug() -> void:
	is_debug = true
