@tool
class_name Socket
extends Node2D


signal selected_as_start(s: Socket)
signal selected_as_end(s: Socket)
signal cancel_selection(s: Socket)

var is_selected_as_start = false
var is_hovered_over = false

@export var max_capacity: int = 0: ## Number of magic edges that can be connected to this socket
	set(c):
		if c < 0:
			return
		max_capacity = c
var cur_capacity: int = 0

@export_category("Debug Settings")
@export var is_debug: bool = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Select the socket with clicking leftclick over it
	if Input.is_action_just_pressed('left_click') and is_hovered_over:
		#is_selected_as_start = true
		if is_debug: print(self, "selected as start")
		emit_signal("selected_as_start", self)
	
	if Input.is_action_just_released("left_click") and is_hovered_over:
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


func _on_area_2d_mouse_entered() -> void:
	is_hovered_over = true


func _on_area_2d_mouse_exited() -> void:
	is_hovered_over = false


func enable_debug() -> void:
	is_debug = true
