class_name SoundBank
extends Node

## Plays short sound effects by name. Each sound gets its own player, so different sounds can
## overlap while a repeated one restarts.

@export var sounds: Dictionary[StringName, AudioStream] = {}
@export_range(-40.0, 6.0) var volume_db: float = -6.0

var _players: Dictionary[StringName, AudioStreamPlayer] = {}


func _ready() -> void:
	for key in sounds:
		var p := AudioStreamPlayer.new()
		p.stream = sounds[key]
		p.volume_db = volume_db
		p.bus = Settings.BUS_SFX
		add_child(p)
		_players[key] = p


func play(key: StringName) -> void:
	if key in _players:
		_players[key].play()
	else:
		push_warning("No sound named %s" % key)
