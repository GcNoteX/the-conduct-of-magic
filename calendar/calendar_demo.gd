extends Control
## Demo for the wall calendar before the shop day exists: move the date on and add test
## reminders. Press C to show or hide the calendar.

const TOGGLE_KEY := KEY_C
const TEST_DEADLINE_DAYS_AHEAD := 3
const TEST_RETURN_DAYS_AHEAD := 2
const DAYS_IN_WEEK := 7

var _note_count: int = 0

@onready var _panel: CalendarPanel = $Center/CalendarPanel


func _ready() -> void:
	var buttons := VBoxContainer.new()
	buttons.position = Vector2(24, 24)
	add_child(buttons)
	_add_button(buttons, "Next day", func() -> void: GameCalendar.advance_day())
	_add_button(buttons, "Next week", func() -> void: GameCalendar.advance_day(DAYS_IN_WEEK))
	_add_button(buttons, "Add a test deadline", _add_test_deadline)
	_add_button(buttons, "Add a test customer return", _add_test_return)
	_add_button(buttons, "Show or hide calendar (C)", _toggle_panel)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == TOGGLE_KEY:
		_toggle_panel()


func _add_button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)


func _add_test_deadline() -> void:
	_note_count += 1
	var day := GameCalendar.get_today() + TEST_DEADLINE_DAYS_AHEAD
	GameCalendar.add_note(CalendarNote.Kind.DEADLINE, day, "Test commission %d" % _note_count)


func _add_test_return() -> void:
	_note_count += 1
	var day := GameCalendar.get_today() + TEST_RETURN_DAYS_AHEAD
	GameCalendar.add_note(CalendarNote.Kind.CUSTOMER_RETURN, day, "Test customer %d" % _note_count)


func _toggle_panel() -> void:
	_panel.visible = not _panel.visible
