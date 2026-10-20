class_name SettingsMenu
extends Control

## The settings menu: a slider per volume, a choice of text size and a fullscreen switch. Each
## change goes straight to the Settings autoload, which applies and saves it, so closing the menu
## needs nothing more. Esc or the Close button close it.

signal closed

const PANEL_WIDTH := 640.0
const DIM_COLOR := Color(0, 0, 0, 0.55)
const PANEL_COLOR := Color("2b2622")
const BORDER_COLOR := Color("8a7350")
const FONT_SIZE := 26
const TITLE_SIZE := 40
const VOLUME_STEP := 0.05
const SLIDER_WIDTH := 320.0
const VOLUME_LABELS: Dictionary[StringName, String] = {
	Settings.BUS_MASTER: "Master volume",
	Settings.BUS_MUSIC: "Music",
	Settings.BUS_SFX: "Sound effects",
}
const TEXT_SIZE_LABELS: Array[String] = ["Small", "Normal", "Large", "Larger"]

var _sliders: Dictionary[StringName, HSlider] = {}
var _percent_labels: Dictionary[StringName, Label] = {}
var _text_size: OptionButton
var _fullscreen: CheckButton
var _close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = _make_theme()
	Settings.register_theme(theme)
	_build_ui()
	_refresh()
	Settings.changed.connect(_refresh)
	_close_button.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	margin.add_child(column)

	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = &"HeaderLabel"
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 16)
	column.add_child(grid)

	for bus in Settings.BUSES:
		_add_volume_row(grid, bus)

	_add_label(grid, "Text size")
	_text_size = OptionButton.new()
	for label in TEXT_SIZE_LABELS:
		_text_size.add_item(label)
	_text_size.item_selected.connect(_on_text_size_selected)
	grid.add_child(_text_size)
	grid.add_child(Control.new())

	_add_label(grid, "Fullscreen")
	_fullscreen = CheckButton.new()
	_fullscreen.toggled.connect(Settings.set_fullscreen)
	grid.add_child(_fullscreen)
	grid.add_child(Control.new())

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.pressed.connect(closed.emit)
	column.add_child(_close_button)


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_type_variation(&"HeaderLabel", &"Label")
	t.set_font_size(&"font_size", &"HeaderLabel", TITLE_SIZE)
	return t


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _add_volume_row(grid: GridContainer, bus: StringName) -> void:
	_add_label(grid, VOLUME_LABELS.get(bus, String(bus)))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = VOLUME_STEP
	slider.custom_minimum_size.x = SLIDER_WIDTH
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	grid.add_child(slider)
	_sliders[bus] = slider
	var percent := Label.new()
	grid.add_child(percent)
	_percent_labels[bus] = percent


func _add_label(grid: GridContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	grid.add_child(label)


## Shows what Settings holds now, without sending the values back to it
func _refresh() -> void:
	for bus in _sliders:
		var volume := Settings.get_volume(bus)
		_sliders[bus].set_value_no_signal(volume)
		_show_percent(bus, volume)
	_text_size.select(_nearest_text_scale_index(Settings.get_text_scale()))
	_fullscreen.set_pressed_no_signal(Settings.is_fullscreen())


func _show_percent(bus: StringName, volume: float) -> void:
	_percent_labels[bus].text = "%d%%" % roundi(volume * 100.0)


func _nearest_text_scale_index(text_scale: float) -> int:
	var best := 0
	for i in Settings.TEXT_SCALES.size():
		if (
			absf(Settings.TEXT_SCALES[i] - text_scale)
			< absf(Settings.TEXT_SCALES[best] - text_scale)
		):
			best = i
	return best


func _on_volume_changed(volume: float, bus: StringName) -> void:
	Settings.set_volume(bus, volume)
	_show_percent(bus, volume)


func _on_text_size_selected(index: int) -> void:
	Settings.set_text_scale(Settings.TEXT_SCALES[index])
