@tool
extends Area2D
class_name LineConnector

"""
- Detects lines of allowed types
- Has capacity limits
"""

signal line_connected(l: MapLine)
signal line_disconnected(l: MapLine)

# Export flags with explicit bit values
@export_flags("MagicLine:2", "EnchantmentLine:4") var types: int = 0

# List of all line types (strings of class_name)
var LineTypes: Array = [MagicLine, EnchantmentLine]
var LineBitValues: Array = [2, 4]  # must match export_flags values

# Populated at runtime based on 'types'
var valid_types: Array = []

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0:
	set(c):
		if c < 0:
			return
		max_capacity = c

@export var connected_lines: Array[MapLine] = []

# --- Ready ---
func _ready() -> void:
	# Initialize valid_types based on selected export flags
	valid_types.clear()
	for i in LineTypes.size():
		if types & LineBitValues[i] != 0:
			valid_types.append(LineTypes[i])

	connected_lines = []

## Check if a line instance is valid
func is_valid_line(line: MapLine) -> bool:
	for type in valid_types:
		if is_instance_of(line, type):
			return true
	return false

func can_connect(l: MapLine) -> bool:
	# If the end is already selected, allow regardless (for prebuilds)
	if l.end:
		return true

	# Prevent duplicate connections (ignore direction)
	for line in connected_lines:
		if (l.start == line.start and l.end == line.end) or (l.start == line.end and l.end == line.start):
			return false

	# Has capacity, and not connecting to itself
	return is_unlimited_capacity or connected_lines.size() < max_capacity

func add_connection(line: MapLine) -> void:
	connected_lines.append(line)
	emit_signal("line_connected", line)

func remove_connection(line: MapLine) -> void:
	connected_lines.erase(line)
	emit_signal("line_disconnected", line)

func _on_area_entered(area: Area2D) -> void:
	if area is MapLine:
		# If line  started from this component, ignore it
		if area.start == self:
			return
		# If line is not from this component, try to connect it.
		if is_valid_line(area):
			add_connection(area)
		else:
			area.kill_line()
