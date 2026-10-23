class_name MusicPlayer
extends Node

## Plays one looping music track at a time on the Music bus, cross-fading when the track changes.
## It keeps playing while the game is paused, so menus don't cut the music.

## Amplitude treated as silent, since decibels can't reach zero
const SILENT := 0.0001

@export_range(0.0, 5.0) var fade_seconds: float = 1.5
@export_range(-40.0, 6.0) var volume_db: float = -8.0

var _players: Array[AudioStreamPlayer] = []
var _current: int = 0
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = AudioBuses.MUSIC
		p.volume_db = volume_db + linear_to_db(SILENT)
		add_child(p)
		_players.append(p)


## Fades from the current track to `stream`. Asking for the track that is already playing does
## nothing, so it carries on from where it is.
func play(stream: AudioStream) -> void:
	if stream == current_stream():
		return
	var old := _players[_current]
	_current = 1 - _current
	var new := _players[_current]
	new.stream = stream
	if stream != null:
		new.play()
	if _tween:
		_tween.kill()
	if fade_seconds <= 0.0:
		old.stop()
		_set_level(1.0, new)
		return
	_tween = create_tween().set_parallel()
	_tween.tween_method(_set_level.bind(new), _level(new), 1.0, fade_seconds)
	_tween.tween_method(_set_level.bind(old), _level(old), 0.0, fade_seconds)
	_tween.chain().tween_callback(old.stop)


## The track playing (or fading in) now, or null for silence
func current_stream() -> AudioStream:
	if _players.is_empty():
		return null
	return _players[_current].stream


func _level(p: AudioStreamPlayer) -> float:
	return clampf(db_to_linear(p.volume_db - volume_db), 0.0, 1.0)


# Fades in linear amplitude, so the cross-fade has no dip in the middle
func _set_level(level: float, p: AudioStreamPlayer) -> void:
	p.volume_db = volume_db + linear_to_db(maxf(level, SILENT))
