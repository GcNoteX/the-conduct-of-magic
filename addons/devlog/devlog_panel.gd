@tool
extends VBoxContainer

## The DevLog tab: the game's DevLog messages, filterable by channel, level and text, with clear
## and copy. Built in code so the addon has no scene to keep in sync.

const ALL_CHANNELS := "All channels"
const LEVEL_NAMES: Array[String] = ["Info", "Warning", "Error"]
const LEVEL_COLORS: Array[Color] = [Color("d0d0d0"), Color("ffd166"), Color("ff6b6b")]
const CHANNEL_COLOR := Color("8ecae6")
const TIME_COLOR := Color("7a7a7a")
const MAX_ENTRIES := 5000
## How many of the oldest messages go at once when the tab is full, so it isn't redrawn per message
const TRIM_ENTRIES := 500

## Each entry is [channel: String, level: int, text: String, msec: int]
var _entries: Array[Array] = []
var _channels: Array[String] = []
var _channel_filter: OptionButton
var _level_toggles: Array[CheckBox] = []
var _search: LineEdit
var _clear_on_run: CheckBox
var _output: RichTextLabel


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bar := HBoxContainer.new()
	add_child(bar)
	_channel_filter = OptionButton.new()
	_channel_filter.add_item(ALL_CHANNELS)
	_channel_filter.item_selected.connect(_on_filter_changed)
	bar.add_child(_channel_filter)
	for i in LEVEL_NAMES.size():
		var toggle := CheckBox.new()
		toggle.text = LEVEL_NAMES[i]
		toggle.button_pressed = true
		toggle.toggled.connect(_on_filter_changed)
		_level_toggles.append(toggle)
		bar.add_child(toggle)
	_search = LineEdit.new()
	_search.placeholder_text = "Filter messages"
	_search.clear_button_enabled = true
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_on_filter_changed)
	bar.add_child(_search)
	_clear_on_run = CheckBox.new()
	_clear_on_run.text = "Clear on run"
	_clear_on_run.button_pressed = true
	bar.add_child(_clear_on_run)
	var copy := Button.new()
	copy.text = "Copy"
	copy.tooltip_text = "Copy the shown messages to the clipboard"
	copy.pressed.connect(_on_copy_pressed)
	bar.add_child(copy)
	var clear := Button.new()
	clear.text = "Clear"
	clear.pressed.connect(clear_entries)
	bar.add_child(clear)
	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.selection_enabled = true
	_output.context_menu_enabled = true
	_output.scroll_following = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_output)


## Adds one message from the game and shows it if it passes the filters
func add_entry(channel: String, level: int, text: String, msec: int) -> void:
	var entry: Array = [channel, level, text, msec]
	_entries.append(entry)
	if not channel in _channels:
		_channels.append(channel)
		_channel_filter.add_item(channel)
	if _entries.size() > MAX_ENTRIES:
		_entries = _entries.slice(TRIM_ENTRIES)
		_rebuild()
	elif _passes(entry):
		_output.append_text(_format(entry))


## Removes every message
func clear_entries() -> void:
	_entries.clear()
	_output.clear()


## Called when the game starts again from the editor
func on_session_started() -> void:
	if _clear_on_run.button_pressed:
		clear_entries()


func _passes(entry: Array) -> bool:
	var channel := _channel_filter.get_item_text(_channel_filter.selected)
	if channel != ALL_CHANNELS and entry[0] != channel:
		return false
	if not _level_toggles[entry[1]].button_pressed:
		return false
	return _search.text == "" or (entry[2] as String).containsn(_search.text)


func _format(entry: Array) -> String:
	var secs := (entry[3] as int) / 1000.0
	return (
		"[color=#%s]%8.2f[/color] [color=#%s][%s][/color] [color=#%s]%s[/color]\n"
		% [
			TIME_COLOR.to_html(false),
			secs,
			CHANNEL_COLOR.to_html(false),
			entry[0],
			LEVEL_COLORS[entry[1]].to_html(false),
			(entry[2] as String).replace("[", "[lb]"),
		]
	)


func _rebuild() -> void:
	_output.clear()
	for entry in _entries:
		if _passes(entry):
			_output.append_text(_format(entry))


func _on_filter_changed(_value: Variant = null) -> void:
	_rebuild()


func _on_copy_pressed() -> void:
	var lines: Array[String] = []
	for entry in _entries:
		if _passes(entry):
			lines.append("[%s] %s" % [entry[0], entry[2]])
	DisplayServer.clipboard_set("\n".join(lines))
