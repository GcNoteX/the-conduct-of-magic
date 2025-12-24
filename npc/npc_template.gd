extends Resource
class_name NPCTemplate



enum NPCAttribute { 
	MERCHANT, 
	QUEST_GIVER, 
	TALKABLE, 
	HOSTILE 
}


# -----------------
# Options for generation
# -----------------
@export var first_names: Array[String] = []           # Selection list
@export var last_names: Array[String] = []            # Selection list
@export var sprite_sets: Array[NPCSpriteSet] = []     # Selection list (Resource)
@export var dialogue: Dictionary[DialogueLines.DialogueType, DialogueLines]
@export var behavior_trees: Array[BehaviorTree] = []  # Selection list (Resource)
@export var attributes: Array[NPCAttribute] = []      # Enum flags (type-safe)
