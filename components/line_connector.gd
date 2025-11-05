@tool
extends Area2D
class_name LineConnector

"""
- Detects lines of allowed and invalid types coming from the map
"""

signal allowed_line_type_detected(l: MapLine)
signal invalid_line_type_detected(l: MapLine)

# Export flags with explicit bit values
@export_flags("MagicLine:2", "EnchantmentLine:4") var types: int = 0

# List of all line types (strings of class_name)
var LineTypes: Array = [MagicLine, EnchantmentLine]
var LineBitValues: Array = [2, 4]  # must match export_flags values

# Populated at runtime based on 'types'
var valid_types: Array = []

# --- Ready ---
func _ready() -> void:
	# Initialize valid_types based on selected export flags
	valid_types.clear()
	for i in LineTypes.size():
		if types & LineBitValues[i] != 0:
			valid_types.append(LineTypes[i])


## Check if a line instance is valid
func is_valid_line(line: MapLine) -> bool:
	for type in valid_types:
		if is_instance_of(line, type):
			return true
	return false


func _on_area_entered(area: Area2D) -> void:
	if area is MapLine:
		# If line  started from this component, ignore it
		if area.start == self:
			return
		# If line is not from this component, try to connect it.
		if is_valid_line(area):
			emit_signal("allowed_line_type_detected")
		else:
			emit_signal("invalid_line_type_detected")
