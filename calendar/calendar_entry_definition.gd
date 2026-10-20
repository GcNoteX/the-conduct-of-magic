class_name CalendarEntryDefinition
extends Resource
## A fixed entry on the wall calendar, set by designers: a seasonal event, application day or
## the acceptance letter. It only shows on the calendar; what happens on the day lives elsewhere.

enum Kind { SEASONAL_EVENT, APPLICATION_DAY, ACCEPTANCE_LETTER }

@export var kind: Kind = Kind.SEASONAL_EVENT
@export var title: String = ""
@export_multiline var details: String = ""
@export_range(1, 12) var month: int = 3
@export_range(1, 31) var day: int = 1
## Money it costs, shown on the calendar. 0 means no cost.
@export var cost: int = 0
