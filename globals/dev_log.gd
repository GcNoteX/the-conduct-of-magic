@tool
extends Node

## Autoload DevLog: the one place game systems send debug messages. Each message goes to a
## channel (map, solvability, ...), is echoed to the Output panel so nothing is lost, and, when the
## game runs from the editor, is sent to the DevLog tab in the Debugger panel (addons/devlog),
## where it can be filtered by channel and searched.

## Emitted for every message, so an in-game panel can listen without changing any callers
signal posted(channel: StringName, level: Level, text: String)

enum Level { INFO, WARNING, ERROR }

const MAP := &"map"
const SOLVABILITY := &"solvability"
const INSCRIBING := &"inscribing"
## Debugger message name; the editor side captures everything starting with "devlog:"
const DEBUGGER_MESSAGE := "devlog:post"


## Posts an information message to `channel`
func info(channel: StringName, text: String) -> void:
	post(channel, text, Level.INFO)


## Posts a warning to `channel`; it also shows in the Debugger's Errors tab
func warn(channel: StringName, text: String) -> void:
	post(channel, text, Level.WARNING)


## Posts an error to `channel`; it also shows in the Debugger's Errors tab
func error(channel: StringName, text: String) -> void:
	post(channel, text, Level.ERROR)


## Echoes the message to Output, emits `posted` and forwards it to the editor's DevLog tab
func post(channel: StringName, text: String, level: Level = Level.INFO) -> void:
	var line := "[%s] %s" % [channel, text]
	match level:
		Level.WARNING:
			push_warning(line)
		Level.ERROR:
			push_error(line)
		_:
			print(line)
	posted.emit(channel, level, text)
	if EngineDebugger.is_active():
		EngineDebugger.send_message(DEBUGGER_MESSAGE, [channel, level, text, Time.get_ticks_msec()])
