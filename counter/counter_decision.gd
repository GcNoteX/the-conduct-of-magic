class_name CounterDecision
extends Resource

## A call the player made at the counter, with what the rulebook said about it.

@export var visit: CustomerVisit
@export var accepted: bool = false
@export var problems: Array[String] = []


func _init(v: CustomerVisit = null, was_accepted: bool = false, found: Array[String] = []) -> void:
	visit = v
	accepted = was_accepted
	problems = found


## True when the call agrees with the rulebook
func is_right() -> bool:
	return accepted == problems.is_empty()
