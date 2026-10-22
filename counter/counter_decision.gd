class_name CounterDecision
extends RefCounted

## A call the player made at the counter, with what the rulebook said about it.

var visit: CustomerVisit
var accepted: bool
var problems: Array[String]


func _init(v: CustomerVisit, was_accepted: bool, found: Array[String]) -> void:
	visit = v
	accepted = was_accepted
	problems = found


## True when the call agrees with the rulebook
func is_right() -> bool:
	return accepted == problems.is_empty()
