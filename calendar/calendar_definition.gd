class_name CalendarDefinition
extends Resource
## The shape of the apprenticeship year and its fixed entries. The year follows the real
## calendar from its start month for twelve months, with no leap years. A date is a day index:
## 0 is the first day of the start month.

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const MONTHS_IN_YEAR := 12
const DAYS_IN_WEEK := 7
const MONTH_NAMES: Array[String] = [
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
]
## No leap years, so February always has 28 days
const MONTH_LENGTHS: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const WEEKDAY_NAMES: Array[String] = [
	"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
]
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
## Northern hemisphere: Spring starts in March
const FIRST_SPRING_MONTH := 3
const MONTHS_PER_SEASON := 3
const SECONDS_PER_DAY := 86400
## 1 January 1970 was a Thursday (Monday is 0)
const EPOCH_WEEKDAY := 3

@export var start_year: int = 2026
@export_range(1, 12) var start_month: int = 3
@export var entries: Array[CalendarEntryDefinition] = []


static func season_of_month(month: int) -> Season:
	@warning_ignore("integer_division")
	var months_into_spring := (month - FIRST_SPRING_MONTH + MONTHS_IN_YEAR) % MONTHS_IN_YEAR
	return (months_into_spring / MONTHS_PER_SEASON) as Season


static func month_length(month: int) -> int:
	return MONTH_LENGTHS[month - 1]


func year_length() -> int:
	var total := 0
	for length in MONTH_LENGTHS:
		total += length
	return total


## Month (1 to 12) of the given slot in the year, where slot 0 is the start month
func month_at(slot: int) -> int:
	return (start_month - 1 + slot) % MONTHS_IN_YEAR + 1


## Calendar year of the given slot in the year
func year_at(slot: int) -> int:
	return start_year + (start_month - 1 + slot) / MONTHS_IN_YEAR


## Slot in the year (0 to 11) of a month, counted from the start month
func slot_of_month(month: int) -> int:
	return (month - start_month + MONTHS_IN_YEAR) % MONTHS_IN_YEAR


## Day index of the first day of the given slot
func first_day_of_slot(slot: int) -> int:
	var index := 0
	for s in slot:
		index += month_length(month_at(s))
	return index


## Day index of a month and day, or -1 if that day doesn't exist
func index_of(month: int, day: int) -> int:
	if month < 1 or month > MONTHS_IN_YEAR or day < 1 or day > month_length(month):
		return -1
	return first_day_of_slot(slot_of_month(month)) + day - 1


## Slot in the year of a day index
func slot_of(day_index: int) -> int:
	var remaining := day_index
	for slot in MONTHS_IN_YEAR:
		var length := month_length(month_at(slot))
		if remaining < length:
			return slot
		remaining -= length
	return MONTHS_IN_YEAR - 1


func month_of(day_index: int) -> int:
	return month_at(slot_of(day_index))


func day_of_month(day_index: int) -> int:
	return day_index - first_day_of_slot(slot_of(day_index)) + 1


func year_of(day_index: int) -> int:
	return year_at(slot_of(day_index))


func season_of(day_index: int) -> Season:
	return season_of_month(month_of(day_index))


## Weekday of a day index, Monday is 0
func weekday_of(day_index: int) -> int:
	var start := {"year": start_year, "month": start_month, "day": 1}
	var epoch_days := Time.get_unix_time_from_datetime_dict(start) / SECONDS_PER_DAY
	return (epoch_days + EPOCH_WEEKDAY + day_index) % DAYS_IN_WEEK


## For example "Sunday 1 March 2026"
func describe(day_index: int) -> String:
	return (
		"%s %d %s %d"
		% [
			WEEKDAY_NAMES[weekday_of(day_index)],
			day_of_month(day_index),
			MONTH_NAMES[month_of(day_index) - 1],
			year_of(day_index),
		]
	)


func entries_on(day_index: int) -> Array[CalendarEntryDefinition]:
	var out: Array[CalendarEntryDefinition] = []
	for entry in entries:
		if index_of(entry.month, entry.day) == day_index:
			out.append(entry)
	return out


## The first entry of a kind, or null if there is none
func first_entry_of_kind(kind: CalendarEntryDefinition.Kind) -> CalendarEntryDefinition:
	for entry in entries:
		if entry.kind == kind:
			return entry
	return null
