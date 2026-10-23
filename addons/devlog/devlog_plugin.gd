@tool
extends EditorPlugin

## Registers the DevLog debugger plugin, which adds the DevLog tab to the Debugger panel

var _debugger: EditorDebuggerPlugin


func _enter_tree() -> void:
	_debugger = preload("res://addons/devlog/devlog_debugger.gd").new()
	add_debugger_plugin(_debugger)


func _exit_tree() -> void:
	remove_debugger_plugin(_debugger)
	_debugger = null
