class_name MainMenu
extends Control

## The title screen: continue the saved run, start a new one, open settings or quit.

const THEME := preload("res://counter/counter_theme.tres")
const WOOD_ART := preload("res://counter/art/counter_wood.png")
const BUTTON_SIZE := Vector2(480, 72)
const GAME_TITLE := "The Conduct of Magic"

var _continue_button: Button
var _save_label: Label
var _settings_button: Button
var _status_label: Label
var _confirm_new: ConfirmationDialog


func _ready() -> void:
	theme = THEME
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	refresh()


## Shows or hides Continue and Settings for what exists now
func refresh() -> void:
	var game := SaveManager.read_save()
	_continue_button.visible = game != null
	_save_label.visible = game != null
	_save_label.text = game.summary() if game else ""
	_settings_button.visible = SettingsOverlay.is_available()
	if game == null and SaveManager.has_save():
		_status_label.text = "The saved run is from another version and can't be continued."
	else:
		_status_label.text = ""


func _on_continue() -> void:
	if not SaveManager.continue_game():
		refresh()


func _on_new_game() -> void:
	if SaveManager.has_save():
		_confirm_new.popup_centered()
	else:
		SaveManager.start_new_game()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = WOOD_ART
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var card := PanelContainer.new()
	centre.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)
	var title := Label.new()
	title.text = GAME_TITLE
	title.theme_type_variation = &"HeaderLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_continue_button = _button(box, "Continue", _on_continue)
	_save_label = Label.new()
	_save_label.theme_type_variation = &"TagLabel"
	_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_save_label)
	_button(box, "New game", _on_new_game)
	_settings_button = _button(box, "Settings", func() -> void: SettingsOverlay.open(self))
	_button(box, "Quit", get_tree().quit)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size.x = BUTTON_SIZE.x
	box.add_child(_status_label)

	_confirm_new = ConfirmationDialog.new()
	_confirm_new.title = "Start a new game?"
	_confirm_new.dialog_text = "This replaces your saved run."
	_confirm_new.ok_button_text = "Start a new game"
	_confirm_new.confirmed.connect(SaveManager.start_new_game)
	add_child(_confirm_new)


func _button(parent: Control, label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = BUTTON_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b
