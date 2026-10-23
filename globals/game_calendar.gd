extends Node
## GameCalendar: owns today's date in the apprenticeship year and the reminders other systems
## put on the calendar. The calendar is a view of plans and expectations, not the source of
## truth: no system should read it to decide what happens.

signal day_changed(day_index: int)
signal season_changed(season: CalendarDefinition.Season)
signal notes_changed

var definition: CalendarDefinition = preload("res://calendar/apprenticeship_year.tres")

var _today: int = 0
var _notes: Array[CalendarNote] = []


## Moves today forward, stopping on the last day of the year
func advance_day(days: int = 1) -> void:
	var last_day := definition.year_length() - 1
	var new_today := clampi(_today + days, 0, last_day)
	if new_today == _today:
		return
	var old_season := definition.season_of(_today)
	_today = new_today
	day_changed.emit(_today)
	var new_season := definition.season_of(_today)
	if new_season != old_season:
		season_changed.emit(new_season)


func get_today() -> int:
	return _today


func is_past(day_index: int) -> bool:
	return day_index < _today


## Days from today until the given day; negative once it has passed
func days_until(day_index: int) -> int:
	return day_index - _today


## Puts a reminder on the calendar and returns it, so the caller can remove it later
func add_note(kind: CalendarNote.Kind, day_index: int, text: String) -> CalendarNote:
	var note := CalendarNote.new(kind, day_index, text)
	_notes.append(note)
	notes_changed.emit()
	return note


func remove_note(note: CalendarNote) -> void:
	if not _notes.has(note):
		return
	_notes.erase(note)
	notes_changed.emit()


func notes_on(day_index: int) -> Array[CalendarNote]:
	var out: Array[CalendarNote] = []
	for note in _notes:
		if note.day_index == day_index:
			out.append(note)
	return out


func entries_on(day_index: int) -> Array[CalendarEntryDefinition]:
	return definition.entries_on(day_index)
