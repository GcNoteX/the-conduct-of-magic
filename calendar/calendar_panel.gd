class_name CalendarPanel
extends PanelContainer
## The player's wall calendar: one month at a time, with today highlighted and the fixed
## entries and reminders on their days. It only reads the GameCalendar and never changes it.

const GRID_ROWS := 6
const CELL_SIZE := Vector2(150, 104)
const ENTRY_STYLES := {
	CalendarEntryDefinition.Kind.SEASONAL_EVENT: UiStyles.CALENDAR_SEASONAL_EVENT,
	CalendarEntryDefinition.Kind.APPLICATION_DAY: UiStyles.CALENDAR_APPLICATION_DAY,
	CalendarEntryDefinition.Kind.ACCEPTANCE_LETTER: UiStyles.CALENDAR_LETTER,
}
const NOTE_STYLES := {
	CalendarNote.Kind.DEADLINE: UiStyles.CALENDAR_DEADLINE,
	CalendarNote.Kind.CUSTOMER_RETURN: UiStyles.CALENDAR_CUSTOMER_RETURN,
}
const NOTE_PREFIXES := {
	CalendarNote.Kind.DEADLINE: "Due: ",
	CalendarNote.Kind.CUSTOMER_RETURN: "Expected: ",
}

var _shown_slot: int = 0
var _title_label: Label
var _footer_label: Label
var _previous_button: Button
var _next_button: Button
var _grid: GridContainer


func _ready() -> void:
	_build_ui()
	GameCalendar.day_changed.connect(_on_day_changed)
	GameCalendar.notes_changed.connect(refresh)
	show_month_of(GameCalendar.get_today())


## Shows the month that holds the given day
func show_month_of(day_index: int) -> void:
	_shown_slot = GameCalendar.definition.slot_of(day_index)
	refresh()


func show_previous_month() -> void:
	_shown_slot = maxi(_shown_slot - 1, 0)
	refresh()


func show_next_month() -> void:
	_shown_slot = mini(_shown_slot + 1, CalendarDefinition.MONTHS_IN_YEAR - 1)
	refresh()


func refresh() -> void:
	var calendar := GameCalendar.definition
	var month := calendar.month_at(_shown_slot)
	var first_day := calendar.first_day_of_slot(_shown_slot)
	var season := CalendarDefinition.season_of_month(month)
	_title_label.text = (
		"%s %d · %s"
		% [
			CalendarDefinition.MONTH_NAMES[month - 1],
			calendar.year_at(_shown_slot),
			CalendarDefinition.SEASON_NAMES[season],
		]
	)
	_previous_button.disabled = _shown_slot == 0
	_next_button.disabled = _shown_slot == CalendarDefinition.MONTHS_IN_YEAR - 1
	for child in _grid.get_children():
		child.queue_free()
	var leading := calendar.weekday_of(first_day)
	var length := CalendarDefinition.month_length(month)
	for cell in GRID_ROWS * CalendarDefinition.DAYS_IN_WEEK:
		var day := cell - leading + 1
		if day < 1 or day > length:
			_grid.add_child(_make_blank_cell())
		else:
			_grid.add_child(_make_day_cell(first_day + day - 1, day))
	_footer_label.text = _footer_text()


func _on_day_changed(day_index: int) -> void:
	show_month_of(day_index)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	_previous_button = Button.new()
	_previous_button.text = "<"
	_previous_button.pressed.connect(show_previous_month)
	header.add_child(_previous_button)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.theme_type_variation = UiStyles.HEADER_LABEL
	header.add_child(_title_label)
	_next_button = Button.new()
	_next_button.text = ">"
	_next_button.pressed.connect(show_next_month)
	header.add_child(_next_button)

	var weekdays := GridContainer.new()
	weekdays.columns = CalendarDefinition.DAYS_IN_WEEK
	box.add_child(weekdays)
	for weekday_name in CalendarDefinition.WEEKDAY_NAMES:
		var label := Label.new()
		label.text = weekday_name.substr(0, 3)
		label.custom_minimum_size.x = CELL_SIZE.x
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_type_variation = UiStyles.CALENDAR_WEEKDAY
		weekdays.add_child(label)

	_grid = GridContainer.new()
	_grid.columns = CalendarDefinition.DAYS_IN_WEEK
	box.add_child(_grid)

	_footer_label = Label.new()
	box.add_child(_footer_label)


func _make_blank_cell() -> Control:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.theme_type_variation = UiStyles.CALENDAR_OUTSIDE
	return cell


func _make_day_cell(day_index: int, day: int) -> Control:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.theme_type_variation = UiStyles.CALENDAR_DAY
	if day_index == GameCalendar.get_today():
		cell.theme_type_variation = UiStyles.CALENDAR_TODAY
	elif GameCalendar.is_past(day_index):
		cell.theme_type_variation = UiStyles.CALENDAR_PAST
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	cell.add_child(lines)
	lines.add_child(_make_line(str(day), UiStyles.CALENDAR_DAY_NUMBER))

	var tooltip: Array[String] = [GameCalendar.definition.describe(day_index)]
	for entry in GameCalendar.entries_on(day_index):
		lines.add_child(_make_line(entry.title, ENTRY_STYLES[entry.kind]))
		tooltip.append(_entry_tooltip(entry, day_index))
	for note in GameCalendar.notes_on(day_index):
		var text: String = NOTE_PREFIXES[note.kind] + note.text
		lines.add_child(_make_line(text, NOTE_STYLES[note.kind]))
		tooltip.append(text)
	cell.tooltip_text = "\n".join(tooltip)
	return cell


func _make_line(text: String, style: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.theme_type_variation = style
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _entry_tooltip(entry: CalendarEntryDefinition, day_index: int) -> String:
	var parts: Array[String] = [entry.title]
	if entry.details != "":
		parts.append(entry.details)
	if entry.cost > 0:
		parts.append("Costs %dg" % entry.cost)
	if entry.kind == CalendarEntryDefinition.Kind.APPLICATION_DAY:
		parts.append(_countdown(day_index))
	return "\n".join(parts)


func _countdown(day_index: int) -> String:
	var days := GameCalendar.days_until(day_index)
	if days > 1:
		return "%d days left" % days
	if days == 1:
		return "Tomorrow"
	if days == 0:
		return "Today"
	return "Passed"


func _footer_text() -> String:
	var calendar := GameCalendar.definition
	var today := GameCalendar.get_today()
	var text := "Today: %s" % calendar.describe(today)
	var application := calendar.first_entry_of_kind(CalendarEntryDefinition.Kind.APPLICATION_DAY)
	if application != null:
		var day_index := calendar.index_of(application.month, application.day)
		text += "    %s: %s" % [application.title, _countdown(day_index)]
	return text
