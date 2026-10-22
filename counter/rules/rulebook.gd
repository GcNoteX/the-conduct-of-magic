class_name Rulebook
extends Resource

## The counter's rules, in the order the rulebook lists them.

@export var rules: Array[CounterRule] = []


## Every reason the visit breaks the rulebook on the given day; empty when it breaks none
func problems(visit: CustomerVisit, day_number: int) -> Array[String]:
	var out: Array[String] = []
	for rule in rules:
		var why := rule.check(visit, day_number)
		if why != "":
			out.append(why)
	return out
