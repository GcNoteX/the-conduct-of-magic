class_name ItemOverview
extends PanelContainer

## The item overview: an overlay on the inscribing table with one ItemCard per item, so you can
## see every item's carvings, plans and held materials at once. The table opens and closes it.
## While open it takes the keyboard; Esc or the Close button asks the table to close it, and
## clicking a card emits `item_chosen` with that item's index.

## A card was clicked: the table opens player.items[index]
signal item_chosen(index: int)
## Esc or the Close button
signal close_requested

## The table's button and key that open the overview
const OPEN_TEXT := "Items (I)"
const OPEN_KEY := KEY_I
const TITLE := "Your items"
const CLOSE_TEXT := "Close (Esc)"
const HINT := "Click an item to open it. Hover a card for everything on it."
const COLOR_DIM := Color(0, 0, 0, 0.65)
const COLOR_PANEL := WorkshopPalette.PANEL
const COLOR_HINT := WorkshopPalette.TEXT_DIM
const MAX_COLUMNS := 4
const SEPARATION := 12
const PANEL_MARGIN := 20
const CORNER_RADIUS := 8
const TITLE_FONT_SIZE := 22
## The most of the screen the card area takes before it scrolls
const MAX_SCREEN_FRACTION := 0.8

var _grid: GridContainer
var _scroll: ScrollContainer


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := StyleBoxFlat.new()
	dim.bg_color = COLOR_DIM
	add_theme_stylebox_override("panel", dim)
	_build()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Shows one card per item, `names[i]` naming `items[i]`
func open(items: Array[ItemInstance], names: Array[String]) -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for i in items.size():
		var card := ItemCard.new(items[i], names[i])
		card.pressed.connect(func() -> void: item_chosen.emit(i))
		_grid.add_child(card)
	_grid.columns = clampi(items.size(), 1, _columns_that_fit())
	visible = true
	_fit_scroll()


func close() -> void:
	visible = false


func cards() -> Array[ItemCard]:
	var out: Array[ItemCard] = []
	for child in _grid.get_children():
		out.append(child as ItemCard)
	return out


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if (
		event.is_pressed()
		and not event.is_echo()
		and (event as InputEventKey).keycode == KEY_ESCAPE
	):
		close_requested.emit()


## How many cards fit side by side in MAX_SCREEN_FRACTION of the screen, up to MAX_COLUMNS
func _columns_that_fit() -> int:
	if not is_inside_tree():
		return MAX_COLUMNS
	var width := get_viewport_rect().size.x * MAX_SCREEN_FRACTION
	return clampi(int((width + SEPARATION) / (ItemCard.CARD_WIDTH + SEPARATION)), 1, MAX_COLUMNS)


## Sizes the scroll area to its cards, up to MAX_SCREEN_FRACTION of the screen
func _fit_scroll() -> void:
	if not is_inside_tree():
		return
	var limit := get_viewport_rect().size * MAX_SCREEN_FRACTION
	_scroll.custom_minimum_size = _grid.get_combined_minimum_size().min(limit)


func _build() -> void:
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = WorkshopPalette.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(PANEL_MARGIN)
	panel.add_theme_stylebox_override("panel", style)
	centre.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", SEPARATION)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = TITLE
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = CLOSE_TEXT
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close_requested.emit)
	header.add_child(close_button)
	var hint := Label.new()
	hint.text = HINT
	hint.add_theme_color_override("font_color", COLOR_HINT)
	box.add_child(hint)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", SEPARATION)
	_grid.add_theme_constant_override("v_separation", SEPARATION)
	_grid.minimum_size_changed.connect(_fit_scroll)
	_scroll.add_child(_grid)
