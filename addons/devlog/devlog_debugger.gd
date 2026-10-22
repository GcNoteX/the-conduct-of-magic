@tool
extends EditorDebuggerPlugin

## Receives the running game's DevLog messages and shows them in a DevLog tab, one per debug
## session

const PREFIX := "devlog"
const DevLogPanel := preload("res://addons/devlog/devlog_panel.gd")

var _panels: Dictionary[int, DevLogPanel] = {}


func _has_capture(capture: String) -> bool:
	return capture == PREFIX


func _capture(message: String, data: Array, session_id: int) -> bool:
	if message != PREFIX + ":post" or not _panels.has(session_id):
		return false
	_panels[session_id].add_entry(data[0], data[1], data[2], data[3])
	return true


func _setup_session(session_id: int) -> void:
	var panel := DevLogPanel.new()
	panel.name = "DevLog"
	_panels[session_id] = panel
	var session := get_session(session_id)
	session.started.connect(panel.on_session_started)
	session.add_session_tab(panel)
