class_name ItemCard
extends PanelContainer

## One item on the item overview: its name, a thumbnail of its map, the enchantments carved and
## planned on it, and the materials its plans hold. Hovering shows the full list as a tooltip;
## clicking emits `pressed`. A card whose item holds planned materials is marked, so you can see
## where a missing material went. It only reads the item.

signal pressed

## The mark on a card whose item holds planned materials
const COLOR_HOLDING := Color(0.96, 0.82, 0.46)
const CARD_WIDTH := 320.0
const THUMBNAIL_SIZE := Vector2(304, 170)
const HOLDING_BORDER_WIDTH := 3
const NAME_FONT_SIZE := 18
const ICON_SIZE := Vector2(32, 32)
const NOTHING := "nothing"
const CARVED := "Carved: %s"
const PLANNED := "Planned: %s"
const HELD_FOR_CARVING := "Held for carving: %s"
const HELD_FOR_DISENCHANTING := "Held for disenchanting: %s"
const HOLDING_MARK := "Holding materials"
const NO_MATERIALS_YET := "no materials yet"
const TOOLTIP_INDENT := "    "

var item: ItemInstance
var item_name: String

var _style: StyleBox
var _hover_style: StyleBox


func _init(inst: ItemInstance, display_name: String) -> void:
	item = inst
	item_name = display_name
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size.x = CARD_WIDTH
	tooltip_text = tooltip()
	_style = _card_style(UiStyles.CARD_PANEL)
	_hover_style = _card_style(UiStyles.CARD_PANEL_HOVER)
	add_theme_stylebox_override("panel", _style)
	mouse_entered.connect(func() -> void: add_theme_stylebox_override("panel", _hover_style))
	mouse_exited.connect(func() -> void: add_theme_stylebox_override("panel", _style))
	_build()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		accept_event()
		pressed.emit()


## Whether the item's plans hold any materials (carving drafts or planned dissolves)
func is_holding() -> bool:
	return not held_for_carving(item).is_empty() or not held_for_disenchanting(item).is_empty()


## The card's lines below the thumbnail, as shown
func summary() -> Array[String]:
	var out: Array[String] = []
	for row in _summary_rows():
		out.append(row[0])
	return out


## [[text, theme type variation], ...]: carvings and plans dimmed when there are none, held
## materials marked
func _summary_rows() -> Array:
	var rows := []
	for pair in [[CARVED, carved_enchantments(item)], [PLANNED, planned_enchantments(item)]]:
		var list: Array[Enchantment] = pair[1]
		rows.append(
			[
				pair[0] % describe_enchantments(list),
				UiStyles.CAPTION_LABEL if list.is_empty() else &""
			]
		)
	for pair in [
		[HELD_FOR_CARVING, held_for_carving(item)],
		[HELD_FOR_DISENCHANTING, held_for_disenchanting(item)]
	]:
		var held: Dictionary[EnchantmentMaterialDefinition, int] = pair[1]
		if not held.is_empty():
			rows.append([pair[0] % describe_materials(held), UiStyles.TAG_LABEL])
	return rows


## The full list: each carving with its effect, each planned enchantment with the materials in
## its nodes, and the held materials
func tooltip() -> String:
	var carved: Array[String] = []
	for p in _placements(item, true):
		carved.append("%s: %s" % [p.enchantment.enchantment_name, p.enchantment.effect_description])
	var planned: Array[String] = []
	for p in _placements(item, false):
		var held: Array[String] = []
		for m in p.materials:
			if m:
				held.append(InscriptionBoard.material_name(m))
		planned.append(
			(
				"%s (%s)"
				% [
					p.enchantment.enchantment_name,
					", ".join(held) if not held.is_empty() else NO_MATERIALS_YET
				]
			)
		)
	var lines: Array[String] = [item_name]
	lines.append_array(_tooltip_list(CARVED, carved))
	lines.append_array(_tooltip_list(PLANNED, planned))
	lines.append(HELD_FOR_CARVING % describe_materials(held_for_carving(item)))
	lines.append(HELD_FOR_DISENCHANTING % describe_materials(held_for_disenchanting(item)))
	return "\n".join(lines)


## The tooltip in the table's tooltip style, with the item's name in bold
func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	panel.theme_type_variation = UiStyles.DARK_TOOLTIP_PANEL
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var first := for_text.get_slice("\n", 0)
	label.text = "[b]%s[/b]%s" % [first, for_text.substr(first.length())]
	panel.add_child(label)
	return panel


## "Carved: nothing" when `entries` is empty, otherwise a heading and one indented line each
static func _tooltip_list(heading: String, entries: Array[String]) -> Array[String]:
	if entries.is_empty():
		return [heading % NOTHING]
	var out: Array[String] = [(heading % "").strip_edges()]
	for e in entries:
		out.append(TOOLTIP_INDENT + e)
	return out


static func carved_enchantments(inst: ItemInstance) -> Array[Enchantment]:
	return _enchantments(_placements(inst, true))


## Draft enchantments placed on the item but not committed yet
static func planned_enchantments(inst: ItemInstance) -> Array[Enchantment]:
	return _enchantments(_placements(inst, false))


## The materials in the item's draft enchantment nodes: {material: count}
static func held_for_carving(inst: ItemInstance) -> Dictionary[EnchantmentMaterialDefinition, int]:
	var out: Dictionary[EnchantmentMaterialDefinition, int] = {}
	for p in _placements(inst, false):
		for m in p.materials:
			if m:
				out[m] = out.get(m, 0) + 1
	return out


## The materials the item's disenchant plan will dissolve: {material: count}
static func held_for_disenchanting(
	inst: ItemInstance
) -> Dictionary[EnchantmentMaterialDefinition, int]:
	var out: Dictionary[EnchantmentMaterialDefinition, int] = {}
	if inst.enchantment_graph_state == null:
		return out
	for s in inst.enchantment_graph_state.disenchant_plan:
		if s.kind == DisenchantStep.Kind.DISSOLVE and s.material:
			out[s.material] = out.get(s.material, 0) + 1
	return out


static func describe_enchantments(list: Array[Enchantment]) -> String:
	var names: Array[String] = []
	for e in list:
		names.append(e.enchantment_name)
	return ", ".join(names) if not names.is_empty() else NOTHING


static func describe_materials(held: Dictionary[EnchantmentMaterialDefinition, int]) -> String:
	var parts: Array[String] = []
	for m in held:
		parts.append("%s ×%d" % [InscriptionBoard.material_name(m), held[m]])
	return ", ".join(parts) if not parts.is_empty() else NOTHING


static func _placements(inst: ItemInstance, committed: bool) -> Array[PlacementState]:
	var out: Array[PlacementState] = []
	if inst.enchantment_graph_state == null:
		return out
	for p in inst.enchantment_graph_state.placements:
		if p.committed == committed:
			out.append(p)
	return out


static func _enchantments(placements: Array[PlacementState]) -> Array[Enchantment]:
	var out: Array[Enchantment] = []
	for p in placements:
		out.append(p.enchantment)
	return out


## The theme's card style, edged in brass when the item holds planned materials
func _card_style(type_name: StringName) -> StyleBox:
	var style := WorkshopPalette.theme_stylebox(type_name)
	var flat := style as StyleBoxFlat
	if flat and is_holding():
		flat.border_color = COLOR_HOLDING
		flat.set_border_width_all(HOLDING_BORDER_WIDTH)
	return style


func _build() -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)
	var art := item.definition.inventory_sprite_normal if item.definition else null
	if art:
		var icon := TextureRect.new()
		icon.texture = art
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = ICON_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(icon)
	var title := _label(header, item_name)
	title.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_holding():
		var mark := _label(header, HOLDING_MARK)
		mark.theme_type_variation = UiStyles.TAG_LABEL
	var thumbnail := ItemThumbnail.new()
	thumbnail.item = item
	thumbnail.custom_minimum_size = THUMBNAIL_SIZE
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(thumbnail)
	for row in _summary_rows():
		var l := _label(box, row[0])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.theme_type_variation = row[1]


func _label(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
