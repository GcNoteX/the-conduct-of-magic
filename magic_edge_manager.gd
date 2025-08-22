class_name MagicEdgeManager
extends Node2D

"""
- Start a MagicEdge at a Socket if Socket has capacity
- Allows to stretch the MagicEdge from starting Socket
- Allows connecting MagicEdge to another Socket if it has capacity
- Allows to select a MagicEdge (the MagicEdge on creation is automatically selected)
- Delete selected MagicEdge
- NOTE: MagicEdges created need to be inside EnchantmentMap 
"""

@export var enchantment_map: EnchantmentMap

var magic_edge_selected: MagicEdge = null:
	set(i):
		#print("Magic Edge Selected:", i)
		magic_edge_selected = i

func _ready() -> void:
	if !enchantment_map:
		push_warning("MagicEdgeManager has no map to manage!")
		return
	enchantment_map.starting_socket_selected.connect(attempt_create_magic_edge)
	enchantment_map.ending_socket_selected.connect(attempt_lock_magic_edge)

func _process(_delta: float) -> void:
	if Input.is_action_just_released("left_click") and magic_edge_selected:
		release_selected_edge()
	if magic_edge_selected:
		magic_edge_selected.stretch_magic_edge(get_global_mouse_position())

## Returns True if attempt successful, False otherwise.
func attempt_create_magic_edge(starting_socket: Socket) -> bool:
	#print("Attempting to create edge with", starting_socket)
	if starting_socket.can_connect_edge():
		var edge: MagicEdge = MagicEdge.start_magic_edge(starting_socket)
		enchantment_map.add_magic_edge_to_map(edge)
		magic_edge_selected = edge
		return true
	return false


## Returns True if attempt successful, False otherwise.
func attempt_lock_magic_edge(ending_socket: Socket) -> bool:
	if ending_socket.can_connect_edge() and magic_edge_selected:
		magic_edge_selected.lock_line(ending_socket)
		#magic_edge_selected = null
		return true
	#magic_edge_selected = null
	return false


func release_selected_edge() -> void:
	magic_edge_selected.start_decay()
	magic_edge_selected = null
	
