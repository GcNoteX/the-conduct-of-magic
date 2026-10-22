class_name BotErrorLog
extends Logger

## Catches the engine's errors and warnings while the bot plays, each tagged with what the
## bot was doing, so the report can say which action set them off. The engine may log from
## any thread, so entries are kept behind a mutex.

## The bot sets this before each action, like "run 2, day 14, counter: accept Elsa Marrow"
var context: String = ""

var _mutex := Mutex.new()
var _entries: Array[Dictionary] = []


func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	script_backtraces: Array[ScriptBacktrace]
) -> void:
	var where := "%s:%d" % [file, line]
	var trace := ""
	for bt in script_backtraces:
		if bt.get_frame_count() > 0:
			where = "%s:%d" % [bt.get_frame_file(0), bt.get_frame_line(0)]
			trace = bt.format()
			break
	var entry := {
		"kind": _kind_name(error_type),
		"where": where,
		"function": function,
		"text": rationale if rationale != "" else code,
		"context": context,
		"trace": trace,
	}
	_mutex.lock()
	_entries.append(entry)
	_mutex.unlock()


func take_entries() -> Array[Dictionary]:
	_mutex.lock()
	var out := _entries.duplicate()
	_entries.clear()
	_mutex.unlock()
	return out


func _kind_name(error_type: int) -> String:
	match error_type:
		ERROR_TYPE_WARNING:
			return "warning"
		ERROR_TYPE_SCRIPT:
			return "script error"
		ERROR_TYPE_SHADER:
			return "shader error"
	return "error"
