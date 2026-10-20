class_name PaletteCard
extends PanelContainer

## One enchantment or material the player can drag onto the board. Every palette layout holds
## these same cards, so the layouts differ only in where the cards sit.

signal drag_started(payload: Resource)
signal pressed(payload: Resource)
## A double-click; the table uses it to dissolve a material in Disenchant mode
signal double_clicked(payload: Resource)

const COLOR_BG := Color("2b2a33")
const COLOR_BG_HOVER := Color("35343f")
const COLOR_ENCHANTMENT := Color("9b8fd1")
const COLOR_SUBTITLE := Color("a8a4b0")

## The Enchantment or EnchantmentMaterialDefinition this card hands out
var payload: Resource
var title: String
var subtitle: String
var dimmed: bool
## False when the card can't be dragged right now; a drag attempt then only emits drag_started
var draggable := true:
	set(value):
		draggable = value
		mouse_default_cursor_shape = Control.CURSOR_DRAG if value else Control.CURSOR_ARROW
var _style := StyleBoxFlat.new()
var _dragging := false


func _init(
	item: Resource, title_text: String, subtitle_text: String, tip: String, is_dimmed := false
) -> void:
	payload = item
	title = title_text
	subtitle = subtitle_text
	tooltip_text = tip
	dimmed = is_dimmed
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	custom_minimum_size = Vector2(150, 56)
	_style.bg_color = COLOR_BG
	_style.border_color = accent()
	_style.border_width_left = 4
	_style.set_corner_radius_all(6)
	_style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", _style)
	if is_dimmed:
		modulate = Color(1, 1, 1, 0.45)
	mouse_entered.connect(func(): _style.bg_color = COLOR_BG_HOVER)
	mouse_exited.connect(func(): _style.bg_color = COLOR_BG)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var icon := PatternPreview.new()
	icon.enchantment = payload as Enchantment
	icon.color = accent()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var name_label := Label.new()
	name_label.text = title_text
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(name_label)
	var sub := Label.new()
	sub.text = subtitle_text
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", COLOR_SUBTITLE)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(sub)


func accent() -> Color:
	if payload is EnchantmentMaterialDefinition:
		return (payload as EnchantmentMaterialDefinition).color
	return COLOR_ENCHANTMENT


func _get_drag_data(_at_position: Vector2) -> Variant:
	_dragging = true
	if not draggable:
		drag_started.emit(payload)
		return null
	set_drag_preview(make_preview())
	drag_started.emit(payload)
	return payload


## A floating chip that follows the mouse during a drag
func make_preview() -> Control:
	var holder := Control.new()
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = accent()
	style.set_corner_radius_all(14)
	style.set_content_margin_all(6)
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = (
		(payload as Enchantment).enchantment_name
		if payload is Enchantment
		else InscriptionBoard.material_name(payload as EnchantmentMaterialDefinition)
	)
	label.add_theme_color_override("font_color", Color.BLACK)
	chip.add_child(label)
	chip.position = Vector2(14, 14)
	holder.add_child(chip)
	return holder


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed and button.double_click:
		_dragging = true  # So the release doesn't also count as a press
		double_clicked.emit(payload)
	elif button.pressed:
		_dragging = false
	elif not _dragging:
		pressed.emit(payload)
