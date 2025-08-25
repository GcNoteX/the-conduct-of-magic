@tool
class_name Socket
extends Node2D

signal hovered_over(s: Socket)
signal unhovered_over(s: Socket)
signal selected_as_start(s: Socket)
signal selected_as_end(s: Socket)

@onready var cap_labal: Label = $Label

var clicked_on: bool = false
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

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if Input.is_action_just_pressed("left_click") and is_hovered_over:
		clicked_on = true
	if Input.is_action_just_released("left_click"):
		clicked_on = false

func add_connection(_magic_edge: MagicEdge) -> void:
	cur_capacity += 1

func remove_connection(_magic_edge: MagicEdge) -> void:
	cur_capacity -= 1

func can_connect_edge(e: MagicEdge = MagicEdge.new()) -> bool:
	# Has capacity, and not connecting to itself
	#print("Capacity Check:", cur_capacity < max_capacity )
	#print("Does not connect to self check:", !(e.starting_socket == self))
	return cur_capacity < max_capacity and !(e.starting_socket == self)


#func _on_area_2d_mouse_entered() -> void:
	#is_hovered_over = true
#
#
#func _on_area_2d_mouse_exited() -> void:
	#is_hovered_over = false
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#if can_connect_edge():
			#if is_debug: print(self, "selected as start")
			#emit_signal("selected_as_start", self)
			
func enable_debug() -> void:
	is_debug = true


func update_capacity_label() -> void:
	cap_labal.text = str(cur_capacity) + '/' + str(max_capacity)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is EnchantmentCursor:
		is_hovered_over = true
		
	if area is MagicEdge:
		# If the area is someone else and capacity == max
		if area.starting_socket == self: # Ignore if point to self
			return

		if can_connect_edge():
			#print(area, " selected as end")
			emit_signal("selected_as_end", self)
		else:
			area.kill_edge()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area is EnchantmentCursor:
		is_hovered_over = false
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if can_connect_edge():
				if is_debug: print(self, "selected as start")
				emit_signal("selected_as_start", self)
