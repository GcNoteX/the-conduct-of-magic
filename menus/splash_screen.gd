class_name SplashScreen
extends Control

## The studio splash shown when the game starts: the studio mark and name fade in, hold, and fade
## out, then the main menu opens. Any key or click skips straight to the menu.

const STUDIO_NAME := "Studio name"
## Borrowed until the project-wide theme replaces it, as in MainMenu
const FALLBACK_THEME_PATH := "res://counter/counter_theme.tres"
const MARK_ART := preload("res://art/title/studio_mark.png")
## The splash's background, also the engine's boot splash colour (application/boot_splash)
const BACKGROUND := Color("140c08")
const MARK_SCALE := 8
const FADE_IN_SECONDS := 0.6
const HOLD_SECONDS := 1.3
const FADE_OUT_SECONDS := 0.6

## Called once the splash is over. Opens the main menu unless something else was set first.
var hand_over: Callable
var elapsed := 0.0

var _done := false
var _content: Control


func _ready() -> void:
	if not hand_over.is_valid():
		hand_over = SaveManager.open_main_menu
	if ResourceLoader.exists(FALLBACK_THEME_PATH):
		theme = load(FALLBACK_THEME_PATH)
	_build_ui()
	_refresh()


func _process(delta: float) -> void:
	advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var mouse := event as InputEventMouseButton
	if (key and key.pressed and not key.echo) or (mouse and mouse.pressed):
		get_viewport().set_input_as_handled()
		finish()


## Runs the splash on, and hands over once it has faded out
func advance(delta: float) -> void:
	elapsed += delta
	_refresh()
	if elapsed >= total_seconds():
		finish()


func total_seconds() -> float:
	return FADE_IN_SECONDS + HOLD_SECONDS + FADE_OUT_SECONDS


## Ends the splash now; only the first call hands over
func finish() -> void:
	if _done:
		return
	_done = true
	hand_over.call()


func is_finished() -> bool:
	return _done


## How visible the mark and name are at this point in the splash, from 0 to 1
func opacity() -> float:
	if elapsed < FADE_IN_SECONDS:
		return elapsed / FADE_IN_SECONDS
	var fade_out_start := FADE_IN_SECONDS + HOLD_SECONDS
	if elapsed < fade_out_start:
		return 1.0
	return clampf(1.0 - (elapsed - fade_out_start) / FADE_OUT_SECONDS, 0.0, 1.0)


func _refresh() -> void:
	_content.modulate.a = opacity()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	centre.add_child(box)
	_content = box
	var mark := TextureRect.new()
	mark.texture = MARK_ART
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(MARK_ART.get_size() * MARK_SCALE)
	box.add_child(mark)
	var label := Label.new()
	label.text = STUDIO_NAME
	label.theme_type_variation = &"HeaderLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
