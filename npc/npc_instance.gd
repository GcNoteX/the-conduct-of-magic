extends Resource
class_name NPCInstance

# -----------------
# Identification
# -----------------
var instance_id: int             # Unique per NPC (save/load key)

# -----------------
# Selected generation data
# -----------------
var first_name: String           # Chosen from template
var last_name: String            # Chosen from template
var sprite_set: NPCSpriteSet     # Resource reference; save path used
var behavior_tree: BehaviorTree  # Resource reference; save path used
var attributes: Array[NPCTemplate.NPCAttribute]  # Copied from template

# -----------------
# Runtime / persistent state
# -----------------
var has_been_interacted_with: bool = false
var quest_flags: Dictionary = {}
