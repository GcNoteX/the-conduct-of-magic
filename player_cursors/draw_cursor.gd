class_name DrawCursor
extends EnchantmentCursor

"""
KEYNOTE: I have decided to make the Cursor the "Brain" of operations.
Nodes and Lines are stupid to what the cursor wants to do with them.
While this makes this script really long, it makes indetifying
logic easier. And protects against scenarios where the cursor
hovers over multiple entities.

The cursor needs to know what map entity it is hovering over and what component of the entity

- Controlled by the players mouse
- Can create MagicLines from MagicLineConnectableComponent
- Controls MagicLines that it creates
"""

var magic_line: PackedScene = preload(SceneReferences.magic_line)
var controlled_line: MagicLine = null

var selection_manager: MapPriorityQueue = MapPriorityQueue.new()

func _ready() -> void:
	if !enabled:
		disable_cursor()

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	if controlled_line and controlled_line.initialized:
		controlled_line.stretch_line(global_position - controlled_line.global_position)
	
	# Letting go of a line destroys it
	if Input.is_action_just_released("left_click"):
		if controlled_line:
			controlled_line.kill_line()
		controlled_line = null
		
	if Input.is_action_just_pressed("right_click"):
		var o = selection_manager.peek()
		if o is MagicLine:
			o.kill_line()

func _on_area_exited(area: Area2D) -> void:
	if !controlled_line and area is MapNode:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			area.handle_drag_out(self)
	
	if area is EnchantmentLine or area is MagicLine:
		selection_manager.remove(area)
	elif area is MapNode:
		selection_manager.remove(area)

func _on_MagicLine_locked(_l: MapLine) -> void:
	controlled_line = null


func _on_area_entered(area: Area2D) -> void:
	#print("Entered: ", area)
	if area is EnchantmentLine or area is MagicLine:
		selection_manager.push(area)
	elif area is MapNode:
		selection_manager.push(area)
