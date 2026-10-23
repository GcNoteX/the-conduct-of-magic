class_name DaySchedule
extends Resource

## The plan for each day, in order. Days past the end of the list repeat its last plan.

@export var days: Array[DayPlan] = []


## The plan for a day, counting from 1
func plan_for(day_number: int) -> DayPlan:
	if days.is_empty():
		return DayPlan.new()
	return days[clampi(day_number - 1, 0, days.size() - 1)]
