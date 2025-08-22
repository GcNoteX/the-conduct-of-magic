@tool
class_name Socket
extends Node2D

signal hovered_over(s: Socket)
signal unhovered_over(s: Socket)
signal selected_as_start(s: Socket)
signal selected_as_end(s: Socket)

@onready var cap_labal: Label = $Label


var is_selected_as_start = false
var is_hovered_over = false:
	set(h):
		is_hovered_over = h
		if is_hovered_over:
			emit_signal("hovered_over", self)
		else:
			emit_signal("unhovered_over", self)

@export var max_capacity: int = 0: ## Number of magic edges that can be connected to this socket
	set(c):
		if c < 0:
			return
		max_capacity = c
		call_deferred("update_capacity_label")
var cur_capacity: int = 0:
	set(c):
		cur_capacity = c
		call_deferred("update_capacity_label")

@export_category("Debug Settings")
@export var is_debug: bool = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	# Select the socket with clicking leftclick over it
	if Input.is_action_just_pressed('left_click') and is_hovered_over:
		is_selected_as_start = true
		#if is_debug: print(self, "selected as start")
		#emit_signal("selected_as_start", self)
	
	if Input.is_action_just_released("left_click") and is_hovered_over:
		is_selected_as_start = false
		if is_debug: print(self, "selected as end")
		emit_signal("selected_as_end", self)
	
	#if Input.is_action_just_released("left_click"):
		## If it was not selected, but was released on, it was selected as an end (how parent logic handles this is important)
		#if is_hovered_over and !is_selected_as_start:
			#if is_debug: print(self, "selected as end")
			#emit_signal("selected_as_end", self)
		
		# Cancel selection only if it was start (we do not want this signal continuously sending)
		#if is_selected_as_start:
			#is_selected_as_start = false
			#if is_debug: print(self, "cancelled selection")
			#emit_signal("cancel_selection", self)


func add_connection(_magic_edge: MagicEdge) -> void:
	#print("Adding connection")
	cur_capacity += 1

func remove_connection(_magic_edge: MagicEdge) -> void:
	cur_capacity -= 1

func can_connect_edge(e: MagicEdge = MagicEdge.new()) -> bool:
	# Has capacity, and not connecting to itself
	#print("Capacity Check:", cur_capacity < max_capacity )
	#print("Does not connect to self check:", !(e.starting_socket == self))
	return cur_capacity < max_capacity and !(e.starting_socket == self)


func _on_area_2d_mouse_entered() -> void:
	is_hovered_over = true
	is_selected_as_start = false


func _on_area_2d_mouse_exited() -> void:
	is_hovered_over = false
	if is_selected_as_start:
		if is_debug: print(self, "selected as start")
		emit_signal("selected_as_start", self)


func enable_debug() -> void:
	is_debug = true


func update_capacity_label() -> void:
	cap_labal.text = str(cur_capacity) + '/' + str(max_capacity)
