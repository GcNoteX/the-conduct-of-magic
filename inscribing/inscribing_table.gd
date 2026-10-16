extends Control

"""
The inscribing (carving) table for the first build: pick an item, plan enchantments, lines and
materials on its hex map, then commit. Plans are drafts kept on each item, so switching items and
coming back keeps them. The day timer runs continuously; when it ends, the day is over.
"""

@export var setup: DemoSetup = preload("res://inscribing/demo/demo_setup.tres")

var player: Player
var board: InscriptionBoard
var time_left: float = 0.0
var day: int = 1

var _view: BoardView
var _board_area: Control
var _items: ItemList
var _enchantments: ItemList
var _materials: ItemList
var _timer_label: Label
var _item_label: RichTextLabel
var _hover_label: RichTextLabel
var _message_label: Label
var _commit_button: Button
var _day_over: PanelContainer
var _day_over_text: RichTextLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player = setup.create_player()
	PlayerManager.set_player(player)
	time_left = setup.day_length_seconds
	_build_ui()
	_refresh_lists()
	if not player.items.is_empty():
		_items.select(0)
		_open_item(0)


func _process(delta: float) -> void:
	if _day_over.visible:
		return
	time_left = maxf(time_left - delta, 0.0)
	var s := int(ceil(time_left))
	_timer_label.text = "Day %d · %02d:%02d left" % [day, s / 60, s % 60]
	if time_left <= 0.0:
		_end_day()


#
# ── Actions ──────────────────────────────────────
#
func _open_item(index: int) -> void:
	board = InscriptionBoard.new(player.items[index])
	_view.board = board
	_fit_board()
	_view.held_enchantment = null
	_view.held_material = null
	_enchantments.deselect_all()
	_materials.deselect_all()
	_refresh_all()


func _on_enchantment_selected(index: int) -> void:
	_materials.deselect_all()
	_view.held_rotation = 0
	_view.held_enchantment = player.known_enchantments[index]
	_set_message(
		(
			"Click the item to place %s. Scroll or press R to rotate, right click to put it down."
			% player.known_enchantments[index].enchantment_name
		)
	)


func _on_material_selected(index: int) -> void:
	var mats := _material_order()
	if index >= mats.size():
		return
	_enchantments.deselect_all()
	_view.held_material = mats[index]
	_set_message(
		(
			"Click an enchantment node to insert %s. Right click to put it down."
			% InscriptionBoard.material_name(mats[index])
		)
	)


func _can_use_material(m: EnchantmentMaterialDefinition) -> String:
	if player.get_material_count(m) - board.reserved_in_drafts(m) <= 0:
		return "You don't have another %s for this item's plan" % InscriptionBoard.material_name(m)
	return ""


func _on_commit_pressed() -> void:
	var err := board.check_commit(player)
	if err != "":
		_set_message(err)
		return
	var done := board.commit(player)
	var names: Array[String] = []
	for p in done:
		names.append(p.enchantment.enchantment_name)
	_set_message("Committed %s. The materials are used up." % ", ".join(names))
	_view.queue_redraw()
	_refresh_all()


func _end_day() -> void:
	var text := "[b]The day is over.[/b]\n\nYour inventory:\n"
	for inst in player.items:
		text += "• %s: %s\n" % [_item_name(inst), _item_effects(inst)]
	text += "\nMaterials left:\n"
	for m in _material_order():
		text += "• %s ×%d\n" % [InscriptionBoard.material_name(m), player.get_material_count(m)]
	_day_over_text.text = text
	_day_over.visible = true


func _start_next_day() -> void:
	day += 1
	time_left = setup.day_length_seconds
	_day_over.visible = false


#
# ── Refreshing ───────────────────────────────────
#
func _refresh_all() -> void:
	_refresh_lists()
	_refresh_item_panel()
	_refresh_commit()
	_on_hovered("")


func _refresh_lists() -> void:
	var selected_item := _items.get_selected_items()
	_items.clear()
	for inst in player.items:
		_items.add_item(_item_name(inst))
	if not selected_item.is_empty():
		_items.select(selected_item[0])

	if _enchantments.item_count != player.known_enchantments.size():
		_enchantments.clear()
		for e in player.known_enchantments:
			_enchantments.add_item("%s  (%d nodes)" % [e.enchantment_name, e.nodes.size()])
			_enchantments.set_item_tooltip(_enchantments.item_count - 1, _enchantment_tooltip(e))

	var selected_mat := _materials.get_selected_items()
	_materials.clear()
	for m in _material_order():
		var planned := board.reserved_in_drafts(m) if board else 0
		var label := "%s ×%d" % [InscriptionBoard.material_name(m), player.get_material_count(m)]
		if planned > 0:
			label += "  (%d planned)" % planned
		_materials.add_item(label)
		var idx := _materials.item_count - 1
		_materials.set_item_custom_fg_color(idx, m.color.lightened(0.3))
		_materials.set_item_tooltip(idx, _material_tooltip(m))
	if not selected_mat.is_empty() and selected_mat[0] < _materials.item_count:
		_materials.select(selected_mat[0])


func _refresh_item_panel() -> void:
	if board == null:
		return
	var text := "[b]%s[/b]\n" % _item_name(board.item)
	text += "Carved: %s\n" % _item_effects(board.item)
	var drafts: Array[String] = []
	for p in board.state.placements:
		if not p.committed:
			drafts.append(
				(
					"%s (%s)"
					% [
						p.enchantment.enchantment_name,
						"active" if board.is_placement_active(p) else "not active yet"
					]
				)
			)
	text += "Planned: %s" % (", ".join(drafts) if not drafts.is_empty() else "nothing")
	_item_label.text = text


func _refresh_commit() -> void:
	if board == null:
		return
	var candidates := board.commit_candidates()
	var missing := board.missing_materials(player)
	_commit_button.disabled = candidates.is_empty()
	_commit_button.modulate = Color(1, 0.45, 0.45) if not missing.is_empty() else Color.WHITE
	if candidates.is_empty():
		_commit_button.text = "Commit (nothing active yet)"
	elif not missing.is_empty():
		_commit_button.text = "Commit (missing materials)"
	else:
		var names: Array[String] = []
		for p in candidates:
			names.append(p.enchantment.enchantment_name)
		_commit_button.text = "Commit " + ", ".join(names)


func _on_hovered(key: String) -> void:
	if board == null or key == "" or not board.has_node(key):
		_hover_label.text = "[i]Hover a node for details.[/i]"
		return
	var text := ""
	if board.is_magic(key):
		text = "[b]Magic node[/b]\n"
		if board.is_node_committed(key):
			text += "Part of a committed carving."
		elif board.is_dead(key):
			text += "Not chained to an enchantment node, so it's ignored on commit."
		else:
			text += "Chained to an enchantment."
		text += "\nLines: %d" % board.line_count(key)
	else:
		var p := board.node_placement(key)
		var def := board.node_definition(key)
		text = (
			"[b]%s node[/b]%s\n"
			% [p.enchantment.enchantment_name, " (committed)" if p.committed else ""]
		)
		text += "Accepts: %s\n" % def.describe_requirements()
		text += (
			"Lines drawn to it: %d\nMagic nodes reached: %d\n"
			% [board.line_count(key), board.reachable_magic_nodes(key).size()]
		)
		var mat := board.node_material(key)
		if mat == null:
			text += "Material: none"
		else:
			text += "Material: %s\n" % InscriptionBoard.material_name(mat)
			for c in board.condition_status(key):
				text += (
					"%s %s\n"
					% ["[color=#7ee08a]✓[/color]" if c[1] else "[color=#f06060]✗[/color]", c[0]]
				)
	_hover_label.text = text


func _on_board_changed() -> void:
	_refresh_all()


func _set_message(t: String) -> void:
	_message_label.text = t


#
# ── Helpers ──────────────────────────────────────
#
func _material_order() -> Array[EnchantmentMaterialDefinition]:
	var out: Array[EnchantmentMaterialDefinition] = []
	for m in setup.materials:
		out.append(m)
	for m in player.material_inventory:
		if m not in out:
			out.append(m)
	return out


func _item_name(inst: ItemInstance) -> String:
	var n := (
		inst.definition.display_name
		if inst.definition.display_name != ""
		else str(inst.definition.id)
	)
	return "%s #%s" % [n, str(inst.id).get_slice("_", str(inst.id).get_slice_count("_") - 1)]


func _item_effects(inst: ItemInstance) -> String:
	if inst.enchantment_graph_state == null:
		return "nothing"
	var effects: Array[String] = []
	for p in inst.enchantment_graph_state.placements:
		if p.committed:
			effects.append(
				"%s (%s)" % [p.enchantment.enchantment_name, p.enchantment.effect_description]
			)
	return ", ".join(effects) if not effects.is_empty() else "nothing"


func _enchantment_tooltip(e: Enchantment) -> String:
	var t := "%s: %s\n" % [e.enchantment_name, e.effect_description]
	for i in e.nodes.size():
		t += "Node %d accepts %s\n" % [i + 1, e.nodes[i].describe_requirements()]
	return t


func _material_tooltip(m: EnchantmentMaterialDefinition) -> String:
	var attrs: Array[String] = []
	for a in m.material_attributes:
		attrs.append(EnchantmentMaterialDefinition.MATERIAL_ATTRIBUTES.keys()[a])
	var conds: Array[String] = []
	for c in m.activation_conditions:
		if c:
			conds.append(c.describe())
	return (
		"Tier %d · %s\nActivates with: %s"
		% [m.tier, ", ".join(attrs), ", ".join(conds) if not conds.is_empty() else "nothing needed"]
	)


func _fit_board() -> void:
	if board == null or _board_area == null:
		return
	var area := _board_area.size
	var unit := _view.unit_size()
	if unit.x <= 0 or unit.y <= 0 or area.x <= 0 or area.y <= 0:
		return
	_view.hex_size = clampf(minf(area.x / unit.x, area.y / unit.y), 8.0, 48.0)
	_view.position = area / 2.0


#
# ── UI construction ──────────────────────────────
#
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let board clicks reach the BoardView
	var bg := ColorRect.new()
	bg.color = Color("17161c")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var left := _panel(root, 300)
	_items = _list(left, "Items", 2)
	_items.item_selected.connect(_open_item)
	_enchantments = _list(left, "Enchantments", 4)
	_enchantments.item_selected.connect(_on_enchantment_selected)
	_materials = _list(left, "Materials", 6)
	_materials.item_selected.connect(_on_material_selected)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = (
		"Pick an enchantment and click the item to place it. Drag between nodes to draw lines. "
		+ "Pick a material and click a node to insert it. Right click removes planned things. "
		+ "Commit when an enchantment glows green."
	)
	help.add_theme_font_size_override("font_size", 13)
	left.add_child(help)

	_board_area = Control.new()
	_board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_area.clip_contents = true
	_board_area.resized.connect(_fit_board)
	root.add_child(_board_area)
	_view = BoardView.new()
	_view.can_use_material = _can_use_material
	_view.message.connect(_set_message)
	_view.changed.connect(_on_board_changed)
	_view.hovered.connect(_on_hovered)
	_board_area.add_child(_view)

	var right := _panel(root, 320)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 22)
	right.add_child(_timer_label)
	_item_label = _rich(right, 110)
	_commit_button = Button.new()
	_commit_button.custom_minimum_size.y = 44
	_commit_button.clip_text = true
	_commit_button.pressed.connect(_on_commit_pressed)
	right.add_child(_commit_button)
	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size.y = 60
	_message_label.add_theme_color_override("font_color", Color("f0d68a"))
	right.add_child(_message_label)
	_hover_label = _rich(right, 220)
	_hover_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Day-over screen: a dimmer that blocks the board, with a summary panel on top
	_day_over = PanelContainer.new()
	_day_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_day_over.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := StyleBoxFlat.new()
	dim.bg_color = Color(0, 0, 0, 0.6)
	_day_over.add_theme_stylebox_override("panel", dim)
	_day_over.visible = false
	add_child(_day_over)
	var centre := CenterContainer.new()
	_day_over.add_child(centre)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(480, 380)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("24232b")
	card_style.set_corner_radius_all(8)
	card_style.set_content_margin_all(20)
	card.add_theme_stylebox_override("panel", card_style)
	centre.add_child(card)
	var box := VBoxContainer.new()
	card.add_child(box)
	_day_over_text = _rich(box, 280)
	var next := Button.new()
	next.text = "Start the next day"
	next.pressed.connect(_start_next_day)
	box.add_child(next)


func _panel(parent: Control, width: float) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.custom_minimum_size.x = width
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	parent.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)
	return v


func _list(parent: Control, title: String, rows: int) -> ItemList:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 18)
	parent.add_child(l)
	var list := ItemList.new()
	list.custom_minimum_size.y = rows * 30 + 8
	parent.add_child(list)
	return list


func _rich(parent: Control, height: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = false
	r.custom_minimum_size.y = height
	parent.add_child(r)
	return r
