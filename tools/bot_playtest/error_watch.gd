class_name ErrorWatch
extends Logger

## Bot playtest helper: counts the engine and script errors logged while it's attached, so a run
## can report errors that GDScript would otherwise only print. Warnings aren't counted.

const MAX_KEPT := 20

var _mutex := Mutex.new()
var _count := 0
var _kept: Array[String] = []


func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace],
) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	_mutex.lock()
	_count += 1
	if _kept.size() < MAX_KEPT:
		_kept.append(
			"%s (%s:%d in %s)" % [rationale if rationale != "" else code, file, line, function]
		)
	_mutex.unlock()


func count() -> int:
	_mutex.lock()
	var n := _count
	_mutex.unlock()
	return n


## The first few errors, as "what (where)"
func first_errors() -> Array[String]:
	_mutex.lock()
	var out := _kept.duplicate()
	_mutex.unlock()
	return out
