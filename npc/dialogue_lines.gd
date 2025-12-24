extends Resource
class_name DialogueLines

"""
This is in a seperate file not for saving/loading purposes
But for better type hinting across NPCs.
"""

enum DialogueType {
	GREETINGS,
	CONFIRMATION,
	GRATITUDE
}

@export var lines: Array[String]
