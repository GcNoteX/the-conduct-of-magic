class_name PapersValidRule
extends CounterRule

## Any ID or permit shown must be in date and in the customer's own name.


func check(visit: CustomerVisit, day_number: int) -> String:
	var customer := visit.slip.customer_name
	var id := visit.adventurer_id
	if id != null:
		if id.expires_day < day_number:
			return "The ID ran out on day %d" % id.expires_day
		if id.holder_name != customer:
			return "The ID is in the name of %s" % id.holder_name
	var permit := visit.permit
	if permit != null:
		if permit.expires_day < day_number:
			return "The permit ran out on day %d" % permit.expires_day
		if permit.holder_name != customer:
			return "The permit is in the name of %s" % permit.holder_name
	return ""
