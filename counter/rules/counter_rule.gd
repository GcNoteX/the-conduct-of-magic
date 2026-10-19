class_name CounterRule
extends Resource

## One rule in the counter's rulebook. Subclasses say how a visit can break it.

## The rule as written in the rulebook
@export_multiline var description: String = ""


## Why the visit breaks this rule on the given day, or "" if it doesn't
func check(_visit: CustomerVisit, _day_number: int) -> String:
	return ""
