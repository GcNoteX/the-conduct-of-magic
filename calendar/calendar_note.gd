class_name CalendarNote
extends RefCounted
## A reminder another system puts on the calendar while playing, such as a commission deadline
## or the day a customer said they'd come back. It is only a reminder: nothing reads it back to
## decide what happens, so a customer can still come on a different day.

enum Kind { DEADLINE, CUSTOMER_RETURN }

var kind: Kind
var day_index: int
var text: String


func _init(note_kind: Kind, note_day_index: int, note_text: String) -> void:
	kind = note_kind
	day_index = note_day_index
	text = note_text
