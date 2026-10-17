class_name CollapsibleSidebar
extends PaletteLayout

## A panel on the left that slides over the board's edge. The handle or Tab opens and closes it,
## and the pin keeps it open while dragging (otherwise it slides away when a drag starts).

const WIDTH := 290.0
const HANDLE_WIDTH := 26.0
const SLIDE_SECONDS := 0.18

var is_open := true
var _panel: PanelContainer
var _handle: Button
var _pin: CheckBox
var _enchantment_box: VBoxContainer
var _material_box: VBoxContainer
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_LEFT_WIDE)
	custom_minimum_size.x = WIDTH + HANDLE_WIDTH

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.105, 0.135, 0.97)
	style.border_color = Color("45434f")
	style.border_width_right = 1
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.anchor_bottom = 1.0
	_panel.offset_right = WIDTH
	add_child(_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var title := Label.new()
	title.text = "Workbench"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_pin = CheckBox.new()
	_pin.text = "Pin"
	_pin.focus_mode = Control.FOCUS_NONE
	_pin.tooltip_text = "Keep the sidebar open while you drag"
	top.add_child(_pin)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.focus_mode = Control.FOCUS_NONE
	v.add_child(tabs)
	_enchantment_box = _tab(tabs, "Enchantments")
	_material_box = _tab(tabs, "Materials")
	var hint := Label.new()
	hint.text = "Drag a card onto the item. Tab opens and closes this panel."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	v.add_child(hint)

	_handle = Button.new()
	_handle.focus_mode = Control.FOCUS_NONE
	_handle.tooltip_text = "Open or close (Tab)"
	_handle.anchor_top = 0.5
	_handle.anchor_bottom = 0.5
	_handle.offset_left = WIDTH
	_handle.offset_right = WIDTH + HANDLE_WIDTH
	_handle.offset_top = -40
	_handle.offset_bottom = 40
	_handle.pressed.connect(toggle)
	add_child(_handle)
	_update_handle()


func set_cards(enchantments: Array[PaletteCard], materials: Array[PaletteCard]) -> void:
	_clear(_enchantment_box)
	_clear(_material_box)
	for c in enchantments:
		_enchantment_box.add_child(c)
	for c in materials:
		_material_box.add_child(c)


func on_drag_started() -> void:
	if not _pin.button_pressed:
		set_open(false)


func handle_key(event: InputEventKey) -> bool:
	if event.pressed and not event.echo and event.keycode == KEY_TAB:
		toggle()
		return true
	return false


func toggle() -> void:
	set_open(not is_open)


func set_open(open: bool) -> void:
	is_open = open
	_update_handle()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", 0.0 if open else -WIDTH, SLIDE_SECONDS)


func _update_handle() -> void:
	_handle.text = "‹" if is_open else "›"


func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	return box
