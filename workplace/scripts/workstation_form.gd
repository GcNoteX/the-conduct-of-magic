class_name WorkStationForm
extends WorkplaceForm

"""
Contains the hitbox of an item split into one or more inspectable components.
Automatically updates the shared inspectable state dictionary if provided.
"""

@export var _item_state: Dictionary[StringName, bool]

func _ready():
	# Ensure dictionary exists even if none was passed (runtime only)
	if not _item_state:
		_item_state = {}
	
	for node in find_children("*", "Area2D"):
		if node is InspectableComponent:
			# Initialize key if missing
			if not _item_state.has(node.inspect_key):
				_item_state[node.inspect_key] = false
			node.inspected.connect(_on_inspected)

func _on_inspected(key: StringName):
	_item_state[key] = true
