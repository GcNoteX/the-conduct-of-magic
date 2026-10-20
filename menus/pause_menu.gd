class_name PauseMenu
extends Control

## The in-run menu: pauses the game while open. The day decides what saving and quitting mean;
## this menu only asks for them.

signal closed
signal save_requested
signal quit_to_main_menu_requested
signal quit_game_requested

const PAUSE_ACTION := &"pause_menu"
const THEME := preload("res://counter/counter_theme.tres")
const BUTTON_SIZE := Vector2(420, 64)

var _status_label: Label
var _settings_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	visible = false
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(PAUSE_ACTION):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_status_label.text = ""
	_settings_button.visible = SettingsOverlay.is_available()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func is_open() -> bool:
	return visible


## Shows how the last save went
func show_status(text: String) -> void:
	_status_label.text = text


func _open_settings() -> void:
	SettingsOverlay.open(self)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var card := PanelContainer.new()
	centre.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	card.add_child(box)
	var title := Label.new()
	title.text = "Paused"
	title.theme_type_variation = &"HeaderLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_button(box, "Resume", close)
	_button(box, "Save", save_requested.emit)
	_settings_button = _button(box, "Settings", _open_settings)
	_button(box, "Save and quit to main menu", quit_to_main_menu_requested.emit)
	_button(box, "Save and quit the game", quit_game_requested.emit)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status_label)


func _button(parent: Control, label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = BUTTON_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b
