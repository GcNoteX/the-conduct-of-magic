class_name BottomTray
extends PaletteLayout

## A strip under the board, like a hotbar: every card is always in view.

var _row: HBoxContainer


func _init() -> void:
	custom_minimum_size.y = 96
	var bg := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = WorkshopPalette.PANEL
	style.border_color = WorkshopPalette.BORDER
	style.border_width_top = 2
	style.set_content_margin_all(8)
	bg.add_theme_stylebox_override("panel", style)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bg.add_child(scroll)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 6)
	scroll.add_child(_row)


func slot() -> Slot:
	return Slot.BOTTOM


func set_cards(enchantments: Array[PaletteCard], materials: Array[PaletteCard]) -> void:
	_clear(_row)
	for c in enchantments:
		_row.add_child(c)
	var gap := VSeparator.new()
	gap.custom_minimum_size.x = 16
	_row.add_child(gap)
	for c in materials:
		_row.add_child(c)
