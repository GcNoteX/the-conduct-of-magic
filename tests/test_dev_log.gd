extends Node

## Headless checks for the DevLog autoload and the DevLog tab's filters.
## Run: godot --headless --path . res://tests/test_dev_log.tscn
## Exits with code 1 if any check fails.

const DevLogPanel := preload("res://addons/devlog/devlog_panel.gd")

var _failures := 0
var _checks := 0
var _received: Array[Array] = []


func _ready() -> void:
	test_posted_signal()
	test_panel_filters()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func test_posted_signal() -> void:
	DevLog.posted.connect(_on_posted)
	DevLog.info(DevLog.SOLVABILITY, "Kindle can be cleared")
	DevLog.warn(DevLog.MAP, "a line lacks update_bounded_identity()")
	DevLog.posted.disconnect(_on_posted)
	check(_received.size() == 2, "every post emits posted")
	check(_received[0] == [DevLog.SOLVABILITY, DevLog.Level.INFO, "Kindle can be cleared"], "info")
	check(_received[1][1] == DevLog.Level.WARNING, "warn posts a warning")


func test_panel_filters() -> void:
	var panel := DevLogPanel.new()
	add_child(panel)
	panel.add_entry("solvability", DevLog.Level.INFO, "Kindle can be cleared [M4]", 1200)
	panel.add_entry("map", DevLog.Level.WARNING, "Line lacks a node", 1500)
	var shown := panel._output.get_parsed_text()
	check(shown.contains("Kindle can be cleared [M4]"), "brackets in a message show as typed")
	check(shown.contains("Line lacks a node"), "every channel shows by default")
	panel._channel_filter.select(1)
	panel._on_filter_changed()
	shown = panel._output.get_parsed_text()
	check(shown.contains("Kindle") and not shown.contains("Line lacks"), "channel filter")
	panel._channel_filter.select(0)
	panel._search.text = "LINE"
	panel._on_filter_changed()
	shown = panel._output.get_parsed_text()
	check(not shown.contains("Kindle") and shown.contains("Line lacks"), "search ignores case")
	panel._search.text = ""
	panel._level_toggles[DevLog.Level.WARNING].button_pressed = false
	shown = panel._output.get_parsed_text()
	check(shown.contains("Kindle") and not shown.contains("Line lacks"), "level toggles")
	panel.clear_entries()
	check(panel._output.get_parsed_text() == "", "clear empties the tab")
	panel.free()


func _on_posted(channel: StringName, level: DevLog.Level, text: String) -> void:
	_received.append([channel, level, text])
