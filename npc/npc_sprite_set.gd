extends Resource
class_name NPCSpriteSet

enum NPCAction { IDLE, WALK, STEAL, CLEAN }

@export var frames: SpriteFrames  # Actual animation frames for this NPC
@export var action_to_animation: Dictionary[NPCAction, StringName]  # Map semantic action → animation name
