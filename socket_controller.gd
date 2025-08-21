extends Node2D

var starting_socket: Socket = null
var ending_socket: Socket = null

var floating_magic_edge: MagicEdge
var is_drawing: bool = false

@export_category("Debug Settings")
@export var is_debug: bool = false

func _ready() -> void:
	for child in get_children():
		assert(child is Socket, "ERROR: Socket Controller may only have children of type Socket during instantiation")
		child = child as Socket
		child.selected_as_start.connect(_on_start_socket_selected)
		child.selected_as_end.connect(_on_end_socket_selected)
		child.cancel_selection.connect(_on_cancel_selection)

func _process(delta: float) -> void:
	if is_drawing:
		floating_magic_edge.update_floating_line(get_global_mouse_position())

func _on_start_socket_selected(s: Socket) -> void:
	starting_socket = s
	floating_magic_edge = MagicEdge.create_magic_edge(starting_socket)
	add_child(floating_magic_edge)
	is_drawing = true


func _on_end_socket_selected(s: Socket) -> void:
	ending_socket = s

## Occurs at the end of an attempt to draw a line. A socket that was selected sends a signal when it is released (left click gold stops) which indicates that the use of the line is complete.
func _on_cancel_selection(s: Socket) -> void:
	call_deferred("_attempt_lock_line")

func _attempt_lock_line() -> void:
	if !starting_socket:
		push_warning("No starting socket, attempt failed")
	if !ending_socket:
		push_warning("No ending socket, attempt failed")
	if starting_socket and ending_socket:
		floating_magic_edge.lock_line(ending_socket)
		# TODO: Store line in a list
	else:
		# When there was not start and end - i.e. line not drawn
		floating_magic_edge.queue_free()
		
	_clear_saved_selections()

func _clear_saved_selections() -> void:
	# Cancel Selection
	starting_socket = null
	ending_socket = null
	floating_magic_edge = null
	is_drawing = false


func enable_debug() -> void:
	is_debug = true
