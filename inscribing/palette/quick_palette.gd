class_name QuickPalette
extends PaletteLayout

## Summoned at the mouse: hold Space to show every card around the cursor, grab one and the
## palette gets out of the way. Releasing Space without grabbing hides it again.

const COLUMNS := 3

var _panel: PanelContainer
var _grid: GridContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.visible = false
	add_child(_panel)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	_panel.add_child(_grid)

	var hint := Label.new()
	hint.text = "Hold Space for the workbench"
	hint.theme_type_variation = UiStyles.CAPTION_LABEL
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -28
	hint.offset_left = -110
	add_child(hint)


func set_cards(enchantments: Array[PaletteCard], materials: Array[PaletteCard]) -> void:
	_clear(_grid)
	for c in enchantments:
		_grid.add_child(c)
	# Start materials on a new row
	for i in posmod(-enchantments.size(), COLUMNS):
		_grid.add_child(Control.new())
	for c in materials:
		_grid.add_child(c)


func on_drag_started() -> void:
	_panel.visible = false


func handle_key(event: InputEventKey) -> bool:
	if event.keycode != KEY_SPACE or event.echo:
		return false
	if event.pressed:
		open_at(get_global_mouse_position())
	else:
		_panel.visible = false
	return true


func open_at(at: Vector2) -> void:
	_panel.visible = true
	_panel.reset_size()
	var half := _panel.size / 2.0
	_panel.position = (at - half).clamp(Vector2.ZERO, (size - _panel.size).max(Vector2.ZERO))


func is_open() -> bool:
	return _panel.visible
