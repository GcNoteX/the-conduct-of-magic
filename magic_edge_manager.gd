class_name MagicEdgeManager
extends Node2D

"""
- Start a MagicEdge at a Socket if Socket has capacity
- Allows to stretch the MagicEdge from starting Socket
- Automatically connects MagicEdge to a Socket it collides with.
- If cursor is not on Socket during collision, spawn another MagicEdge from Socket.

- Allows to select a MagicEdge (the MagicEdge on creation is automatically selected)
- Delete selected MagicEdge

- NOTE: MagicEdges created need to be inside EnchantmentMap 
"""

@export var enchantment_map: EnchantmentMap
@export var map_selection_manager: MapSelectionManager
@export var cursor: EnchantmentCursor

var chaining_counter: int = 0
var magic_edge_highlighted: MagicEdge = null
var selected_magic_edge: MagicEdge = null:
	set(i):
		#print("Magic Edge Selected:", i)
		selected_magic_edge = i

func _ready() -> void:
	if !enchantment_map:
		push_error("MagicEdgeManager has no map to manage!")
		return
	if !map_selection_manager:
		push_error("MagicEdgeManager has no selection manager!")
		return
		
	enchantment_map.starting_socket_selected.connect(attempt_create_magic_edge)
	enchantment_map.ending_socket_selected.connect(attempt_lock_magic_edge)

func _physics_process(_delta: float) -> void:
	#var selected_entity = map_selection_manager.determine_selected()

	if Input.is_action_just_pressed("left_click"):
		chaining_counter = 0
	if Input.is_action_just_released("left_click"):
		print("Chain Length: ", chaining_counter)
		
	if Input.is_action_just_released("left_click") and selected_magic_edge:
		release_selected_edge()
	if selected_magic_edge and !selected_magic_edge.is_locked:
		selected_magic_edge.stretch_magic_edge(cursor.get_location())

## Returns True if attempt successful, False otherwise.
func attempt_create_magic_edge(starting_socket: Socket) -> bool:
	if selected_magic_edge:
		return false
	# This code block ensures the first of a chain has to have had the socket clicked on.
	if chaining_counter == 0 and starting_socket.clicked_on == false: # First in the combo
		return false
	
	if starting_socket.can_connect_edge():
		var edge: MagicEdge = MagicEdge.start_magic_edge(starting_socket)
		enchantment_map.call_deferred("add_magic_edge_to_map", edge)
		await enchantment_map.magic_edge_added
		selected_magic_edge = edge
		#print("Updated selected edge to ", selected_magic_edge)
		return true
	return false


## Returns True if attempt successful, False otherwise.
func attempt_lock_magic_edge(ending_socket: Socket) -> bool:
	if selected_magic_edge:
		if !enchantment_map.is_edge_duplicate(ending_socket, selected_magic_edge):
			selected_magic_edge.ending_socket = ending_socket
			chaining_counter += 1
			var can_continue = selected_magic_edge.lock_line() # Lock line will tell us if we can continue or not as a signal is emitted to _on_socket_limit_reached
			
			selected_magic_edge = null
			# Continue line if the cursor is not on the ending socket and the ending socket has space
			if can_continue and map_selection_manager.determine_selected() != ending_socket: # Second boolean part is to ensure it doesnt double up with the Socket code to emit when used as start.
				attempt_create_magic_edge(ending_socket)
				
			return true
		else:
			#print("Attempting to connect a duplicate edge, destroying edge!")
			selected_magic_edge.kill_edge()
	return false


func release_selected_edge() -> void:
	selected_magic_edge.start_decay()
	selected_magic_edge = null
