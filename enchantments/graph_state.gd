class_name GraphState
extends Resource

"""
Everything carved on (or planned for) one item: placed enchantments and drawn lines.
Drafts live here too, so leaving an item and coming back keeps the plan.
"""

@export var placements: Array[PlacementState] = []
@export var lines: Array[LineState] = []
@export var next_placement_id: int = 1
