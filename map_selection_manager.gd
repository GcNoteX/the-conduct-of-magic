class_name MapSelectionManager
extends Node2D

"""
- Dragging out a Socket should create a MagicEdge
- If a MagicEdge Collides with a Socket, it should detect it - and attempt to merge into it.
- If the mouse is released, while holding a MagicEdge, it should release it.
- Clicking on a MagicEdge selects it
This class should just monitor and return the highest priority element. 
For logical functionality of tasks where overlapping elements may determine the code branch.
"""

signal variant_selected(v: Variant)

@export var map: EnchantmentMap
@export var selector: EnchantmentCursor

var socket_queue: Array = [] ## The queue of items, one in front takes priority
var edges_queue: Array = []

var selected: Variant:
	set(i):
		if selected != null: # Unhighlight previously highlighted if it can be
			if can_highlight(selected):
				selected.unhighlight()
		
		selected = i
		if can_highlight(selected):
			selected.highlight()

func _ready() -> void:
	assert(map, "MapSelectionManager is not selecting a map")
	map.magic_edge_added.connect(connect_edge)
	await map.map_initialized
	for socket in map.sockets:
		connect_socket(socket)
	for edge in map.magic_edges:
		connect_edge(edge)

func can_highlight(v: Variant) -> bool:
	if v == null:
		return false
	return v.has_method("highlight") and v.has_method("unhighlight")

func connect_socket(s: Socket) -> void:
	s.hovered_over.connect(add_socket_to_queue)
	s.unhovered_over.connect(remove_socket_from_queue)

func connect_edge(e: MagicEdge) -> void:
	e.hovered_over.connect(add_edge_to_queue)
	e.unhovered_over.connect(remove_edge_from_queue)

func add_socket_to_queue(s: Socket) -> void:
	#print("added to socket queue")
	socket_queue.append(s)
	selected = determine_selected()

func remove_socket_from_queue(s: Socket) -> void:
	#print("erased from socket queue")
	socket_queue.erase(s)
	selected = determine_selected()

func add_edge_to_queue(e: MagicEdge) -> void:
	#print("added to edge queue")
	edges_queue.append(e)
	selected = determine_selected()

func remove_edge_from_queue(e: MagicEdge) -> void:
	#print("erased from edge queue")
	edges_queue.erase(e)
	selected = determine_selected()

## Determines selected piece, returns null if none selected.
func determine_selected() -> Variant:
	if !socket_queue.is_empty():
		return socket_queue[0]
	elif !edges_queue.is_empty():
		return edges_queue[0]
	else:
		return null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click"):
		if selected is MagicEdge:
			selected.kill_edge()
	if event.is_action_pressed("left_click"):
		emit_signal("variant_selected", determine_selected())
