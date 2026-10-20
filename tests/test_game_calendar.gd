extends Node

"""
Headless checks for the calendar's date maths and reminders.
Run: godot --headless --path . res://tests/test_game_calendar.tscn
Exits with code 1 if any check fails.
"""

const YEAR := preload("res://calendar/apprenticeship_year.tres")
const GAME_CALENDAR := preload("res://globals/game_calendar.gd")
const MONDAY := 0
const THURSDAY := 3
const SUNDAY := 6

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_year_shape()
	test_dates()
	test_weekdays()
	test_seasons()
	test_entries()
	test_advance_day()
	test_notes()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func new_calendar() -> Node:
	var calendar: Node = GAME_CALENDAR.new()
	calendar.definition = YEAR
	return calendar


func test_year_shape() -> void:
	check(YEAR.year_length() == 365, "a year has 365 days")
	check(YEAR.month_at(0) == 3, "the year starts in March")
	check(YEAR.month_at(11) == 2, "the year ends in February")
	check(YEAR.year_at(0) == 2026, "March is in 2026")
	check(YEAR.year_at(10) == 2027, "January is in 2027")
	check(CalendarDefinition.month_length(2) == 28, "February has 28 days, no leap years")


func test_dates() -> void:
	check(YEAR.index_of(3, 1) == 0, "1 March is day 0")
	check(YEAR.index_of(3, 31) == 30, "31 March is day 30")
	check(YEAR.index_of(4, 1) == 31, "1 April is day 31")
	check(YEAR.index_of(12, 31) == 305, "31 December is day 305")
	check(YEAR.index_of(1, 1) == 306, "1 January is day 306")
	check(YEAR.index_of(2, 28) == 364, "28 February is the last day")
	check(YEAR.index_of(2, 29) == -1, "29 February doesn't exist")
	check(YEAR.index_of(4, 31) == -1, "31 April doesn't exist")
	for index in [0, 30, 31, 152, 305, 306, 364]:
		var month: int = YEAR.month_of(index)
		var day: int = YEAR.day_of_month(index)
		check(YEAR.index_of(month, day) == index, "day %d round trips" % index)
	check(YEAR.describe(0) == "Sunday 1 March 2026", "day 0 reads Sunday 1 March 2026")
	check(YEAR.describe(364) == "Sunday 28 February 2027", "last day reads Sunday 28 February 2027")


func test_weekdays() -> void:
	check(YEAR.weekday_of(0) == SUNDAY, "1 March 2026 is a Sunday")
	check(YEAR.weekday_of(1) == MONDAY, "2 March 2026 is a Monday")
	check(YEAR.weekday_of(YEAR.index_of(12, 25)) == 4, "25 December 2026 is a Friday")
	check(YEAR.weekday_of(YEAR.index_of(1, 1)) == 4, "1 January 2027 is a Friday")
	check(YEAR.weekday_of(YEAR.index_of(10, 1)) == THURSDAY, "1 October 2026 is a Thursday")


func test_seasons() -> void:
	var spring := CalendarDefinition.Season.SPRING
	var summer := CalendarDefinition.Season.SUMMER
	var autumn := CalendarDefinition.Season.AUTUMN
	var winter := CalendarDefinition.Season.WINTER
	check(YEAR.season_of(YEAR.index_of(3, 1)) == spring, "March is Spring")
	check(YEAR.season_of(YEAR.index_of(5, 31)) == spring, "31 May is Spring")
	check(YEAR.season_of(YEAR.index_of(6, 1)) == summer, "1 June is Summer")
	check(YEAR.season_of(YEAR.index_of(9, 1)) == autumn, "1 September is Autumn")
	check(YEAR.season_of(YEAR.index_of(12, 1)) == winter, "1 December is Winter")
	check(YEAR.season_of(YEAR.index_of(2, 28)) == winter, "28 February is Winter")


func test_entries() -> void:
	var application := YEAR.first_entry_of_kind(CalendarEntryDefinition.Kind.APPLICATION_DAY)
	check(application != null, "the year has an application day")
	if application != null:
		check(application.month == 2 and application.day == 1, "application day is 1 February")
		check(application.cost > 0, "application day costs money")
	var letter := YEAR.first_entry_of_kind(CalendarEntryDefinition.Kind.ACCEPTANCE_LETTER)
	check(letter != null and YEAR.entries_on(364).has(letter), "the letter comes on the last day")
	var seasons_with_events := {}
	for entry in YEAR.entries:
		check(YEAR.index_of(entry.month, entry.day) >= 0, "%s is on a real day" % entry.title)
		if entry.kind == CalendarEntryDefinition.Kind.SEASONAL_EVENT:
			seasons_with_events[CalendarDefinition.season_of_month(entry.month)] = true
	check(seasons_with_events.size() == 4, "every season has a sample event")


func test_advance_day() -> void:
	var calendar := new_calendar()
	var days: Array[int] = []
	var seasons: Array[int] = []
	calendar.day_changed.connect(func(day_index: int) -> void: days.append(day_index))
	calendar.season_changed.connect(func(season: int) -> void: seasons.append(season))
	check(calendar.get_today() == 0, "the year starts on day 0")
	calendar.advance_day()
	check(calendar.get_today() == 1 and days == [1], "next day moves on and signals")
	calendar.advance_day(YEAR.index_of(5, 31) - 1)
	check(seasons.is_empty(), "no season change within Spring")
	calendar.advance_day()
	check(seasons == [CalendarDefinition.Season.SUMMER], "1 June signals Summer")
	calendar.advance_day(1000)
	check(calendar.get_today() == 364, "the date stops on the last day")
	var signals_before := days.size()
	calendar.advance_day()
	check(days.size() == signals_before, "no signal once the year is over")
	check(calendar.days_until(0) == -364 and calendar.is_past(0), "day 0 has passed")
	calendar.free()


func test_notes() -> void:
	var calendar := new_calendar()
	var changes := [0]
	calendar.notes_changed.connect(func() -> void: changes[0] += 1)
	var deadline: CalendarNote = calendar.add_note(CalendarNote.Kind.DEADLINE, 5, "Sword")
	calendar.add_note(CalendarNote.Kind.CUSTOMER_RETURN, 5, "Baker")
	calendar.add_note(CalendarNote.Kind.CUSTOMER_RETURN, 6, "Farmer")
	check(calendar.notes_on(5).size() == 2, "two notes on day 5")
	check(calendar.notes_on(7).is_empty(), "no notes on day 7")
	check(changes[0] == 3, "each note signals")
	calendar.remove_note(deadline)
	check(calendar.notes_on(5).size() == 1, "a removed note is gone")
	calendar.remove_note(deadline)
	check(changes[0] == 4, "removing twice signals once")
	check(calendar.days_until(5) == 5, "day 5 is 5 days away")
	calendar.free()
