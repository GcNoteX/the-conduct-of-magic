extends Control

"""
The inscribing (carving) table for the first build: pick an item, plan enchantments, lines and
materials on its hex map, then commit. Plans are drafts kept on each item, so switching items and
coming back keeps them. The day timer runs continuously; when it ends, the day is over.
In Disenchant mode the same table plans cuts, dissolves and pull-outs on the item's committed
carvings (see DisenchantBoard), with the runes in a bar above the board and the plan on the right.
"""

const CARVE_HELP := (
	"Pick an enchantment and click the item to place it. Press on a node and drag through "
	+ "cells to draw a line; move back to undo. Drag a material onto a node to insert it. "
	+ "Right click removes planned things. Commit when every node shows a tick."
)
const DISENCHANT_HELP := (
	"Double-click a material to dissolve it for runes. Click a line to plan cutting it: it costs "
	+ "the runes shown on it. A node gives runes back when its last line is cut. Click an "
	+ "enchantment node to pull it out once all its lines are cut. Right click undoes the last step."
)
const CARVE_LEGEND := (
	"[b]Reading the board[/b]\n"
	+ "Empty nodes show what they need: Fl flame, Wa water, So soft, Ha hard, Sh shiny, "
	+ "any for any material. A gold number means that tier or higher.\n"
	+ "Filled nodes show their material's progress, like 1/2 lines, with a red ring "
	+ "until it's met and a green ring and tick after.\n"
	+ "Hover a node for the details."
)
const DISENCHANT_LEGEND := (
	"[b]Reading the board[/b]\n"
	+ "Each committed line shows what cutting it costs: [color=#4aa3ff]water[/color], "
	+ "[color=#ff7a3d]fire[/color], [color=#bfeccb]wind[/color] and "
	+ "[color=#b49a74]stone[/color] runes. Planned cuts show their step number, red when "
	+ "you can't afford them. A green ring marks a node that pays out in the plan.\n"
	+ "Hover a node or line for its runes."
)

@export var setup: DemoSetup = preload("res://inscribing/demo/demo_setup.tres")

var player: Player
var board: InscriptionBoard
## The board's disenchant rules while in Disenchant mode, otherwise null
var disenchant: DisenchantBoard
var time_left: float = 0.0
var day: int = 1

var _view: BoardView
var _board_area: BoardDropArea
var _items: ItemList
var _enchantments: ItemList
var _materials: MaterialList
var _timer_label: Label
var _item_label: RichTextLabel
var _tooltip: PanelContainer
var _tooltip_label: RichTextLabel
var _message_label: Label
var _commit_button: Button
var _day_over: PanelContainer
var _day_over_text: RichTextLabel
var _carve_button: Button
var _disenchant_button: Button
var _rune_bar: RuneBar
var _plan_panel: DisenchantPlanPanel
var _help: Label
var _legend: RichTextLabel


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
	if _tooltip.visible:
		_place_tooltip()


#
# ── Actions ──────────────────────────────────────
#
func _open_item(index: int) -> void:
	board = InscriptionBoard.new(player.items[index], player)
	_view.board = board
	disenchant = DisenchantBoard.new(board) if is_disenchanting() else null
	_view.disenchant = disenchant
	_fit_board()
	_view.held_enchantment = null
	_enchantments.deselect_all()
	_refresh_all()


func is_disenchanting() -> bool:
	return _disenchant_button.button_pressed


func _set_disenchanting(on: bool) -> void:
	_disenchant_button.set_pressed_no_signal(on)
	_carve_button.set_pressed_no_signal(not on)
	_view.held_enchantment = null
	_enchantments.deselect_all()
	disenchant = DisenchantBoard.new(board) if on and board else null
	_view.disenchant = disenchant
	if on and disenchant.carvings().is_empty():
		_set_message(
			"Nothing is carved on this item yet. Commit a carving first, or pick the carved sword."
		)
	elif on:
		_set_message(
			"Plan how to take carvings out. Dissolve a material first: you start with no runes."
		)
	else:
		_set_message("Carving. Your disenchant plan stays on the item.")
	_refresh_all()


func _on_enchantment_selected(index: int) -> void:
	if is_disenchanting():
		_enchantments.deselect_all()
		_set_message("Switch to Carve to place enchantments")
		return
	_view.held_rotation = 0
	_view.held_enchantment = player.known_enchantments[index]
	_set_message(
		(
			"Click the item to place %s. Scroll or press R to rotate, right click to put it down."
			% player.known_enchantments[index].enchantment_name
		)
	)


func _on_material_drag_started(m: EnchantmentMaterialDefinition) -> void:
	if is_disenchanting():
		_set_message("Double-click %s to dissolve it" % InscriptionBoard.material_name(m))
		return
	_enchantments.deselect_all()
	_view.held_enchantment = null
	_set_message(
		(
			"Drop %s onto an enchantment node. Green rings show the nodes that accept it."
			% InscriptionBoard.material_name(m)
		)
	)


func _on_material_activated(index: int) -> void:
	if not is_disenchanting():
		_set_message("Drag materials onto enchantment nodes. Dissolving is for Disenchant mode.")
		return
	var m := _materials.materials[index]
	var err := disenchant.plan_dissolve(m)
	if err != "":
		_set_message(err)
		return
	_set_message(
		(
			"Planned: dissolve %s for %s. It's held by this item until you commit or undo."
			% [InscriptionBoard.material_name(m), RuneSet.copy_of(m.dissolve_runes).describe()]
		)
	)
	_on_board_changed()


func _on_undo_pressed() -> void:
	var undone := disenchant.undo_last()
	if undone:
		_set_message("Undid: %s" % disenchant.describe_step(undone))
	_on_board_changed()


func _on_commit_pressed() -> void:
	if is_disenchanting():
		_commit_disenchant()
		return
	var err := board.check_commit()
	if err != "":
		_set_message(err)
		return
	var done := board.commit()
	var names: Array[String] = []
	for p in done:
		names.append(p.enchantment.enchantment_name)
	_set_message("Committed %s. The materials are used up." % ", ".join(names))
	_view.queue_redraw()
	_refresh_all()


func _commit_disenchant() -> void:
	var err := disenchant.check_commit()
	if err != "":
		_set_message(err)
		return
	var done := disenchant.commit()
	var names: Array[String] = []
	for p in done:
		names.append(p.enchantment.enchantment_name)
	_set_message(
		(
			(
				"Pulled out %s. Its cells are free again, the dissolved materials are used up and "
				% ", ".join(names)
			)
			+ "leftover runes disperse."
		)
	)
	_on_board_changed()


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
	_refresh_mode()
	_on_hovered("")


func _refresh_mode() -> void:
	var on := is_disenchanting()
	_rune_bar.visible = on
	_plan_panel.visible = on
	_enchantments.modulate = Color(1, 1, 1, 0.4) if on else Color.WHITE
	_help.text = DISENCHANT_HELP if on else CARVE_HELP
	_legend.text = DISENCHANT_LEGEND if on else CARVE_LEGEND
	if on and disenchant:
		_rune_bar.show_runes(disenchant.runes())
		_plan_panel.show_plan(disenchant)


func _refresh_lists() -> void:
	var selected_item := _items.get_selected_items()
	_items.clear()
	for inst in player.items:
		var carved := _item_effects(inst) != "nothing"
		_items.add_item(_item_name(inst) + ("  (carved)" if carved else ""))
	if not selected_item.is_empty():
		_items.select(selected_item[0])

	if _enchantments.item_count != player.known_enchantments.size():
		_enchantments.clear()
		for e in player.known_enchantments:
			_enchantments.add_item("%s  (%d nodes)" % [e.enchantment_name, e.nodes.size()])
			_enchantments.set_item_tooltip(_enchantments.item_count - 1, _enchantment_tooltip(e))

	_materials.clear()
	_materials.materials = _material_order()
	for m in _materials.materials:
		var planned := board.planned_count(m) if board else 0
		var label := "%s ×%d" % [InscriptionBoard.material_name(m), player.get_material_count(m)]
		if planned > 0:
			label += "  (+%d planned here)" % planned
		_materials.add_item(label)
		var idx := _materials.item_count - 1
		_materials.set_item_custom_fg_color(idx, m.color.lightened(0.3))
		_materials.set_item_tooltip(idx, _material_tooltip(m))


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
	var steps := board.state.disenchant_plan.size()
	if steps > 0:
		text += "\nDisenchant plan: %d step%s" % [steps, "" if steps == 1 else "s"]
	_item_label.text = text


func _refresh_commit() -> void:
	if board == null:
		return
	_commit_button.modulate = Color.WHITE
	if is_disenchanting():
		_refresh_disenchant_commit()
		return
	var candidates := board.commit_candidates()
	var inactive := board.inactive_drafts()
	_commit_button.disabled = candidates.is_empty() or not inactive.is_empty()
	_commit_button.disabled = _commit_button.disabled or not board.dead_lines().is_empty()
	if not board.dead_lines().is_empty():
		_commit_button.text = "Commit (unconnected magic nodes)"
	elif not inactive.is_empty():
		_commit_button.text = "Commit (%s not active)" % inactive[0].enchantment.enchantment_name
	elif candidates.is_empty():
		_commit_button.text = "Commit (nothing planned)"
	else:
		var names: Array[String] = []
		for p in candidates:
			names.append(p.enchantment.enchantment_name)
		_commit_button.text = "Commit " + ", ".join(names)


func _refresh_disenchant_commit() -> void:
	var err := disenchant.check_commit()
	var blocked := disenchant.first_blocked()
	_commit_button.disabled = err != ""
	if blocked >= 0:
		_commit_button.text = "Commit (step %d can't be done)" % (blocked + 1)
		_commit_button.modulate = Color(1, 0.45, 0.45)
	elif disenchant.state.disenchant_plan.is_empty():
		_commit_button.text = "Commit (nothing planned)"
	elif disenchant.planned_pull_outs().is_empty():
		_commit_button.text = "Commit (pull out an enchantment)"
	elif err != "":
		_commit_button.text = "Commit (finish every enchantment you cut)"
	else:
		var names: Array[String] = []
		for p in disenchant.planned_pull_outs():
			names.append(p.enchantment.enchantment_name)
		_commit_button.text = "Commit: pull out " + ", ".join(names)


## Shows the node's (or in Disenchant mode, the line's) details in a tooltip that follows the mouse
func _on_hovered(key: String) -> void:
	if board and disenchant and key != "":
		var tip := _disenchant_tooltip(key)
		if tip != "":
			_show_tooltip(tip)
			return
	if board == null or key == "" or not board.has_node(key):
		_tooltip.visible = false
		return
	var text := ""
	if board.is_magic(key):
		text = "[b]Magic node[/b]\n"
		if board.is_node_committed(key):
			text += "Part of a committed carving."
		elif board.is_dead(key):
			text += "Not chained to an enchantment node. Connect or remove it before committing."
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
		text += "Needs: %s\n" % def.describe_requirements()
		text += (
			"Lines drawn to it: %d\nMagic nodes reached: %d\n"
			% [board.line_count(key), board.reachable_magic_nodes(key).size()]
		)
		var mat := board.node_material(key)
		if mat == null:
			text += "Material: none yet. Drag one here from the list."
		else:
			text += "Material: %s\nTo activate:\n" % InscriptionBoard.material_name(mat)
			for c in board.condition_status(key):
				text += (
					"%s %s (%s)\n"
					% [
						"[color=#7ee08a]✓[/color]" if c[1] else "[color=#f06060]✗[/color]",
						c[0],
						c[2]
					]
				)
	_show_tooltip(text)


func _show_tooltip(text: String) -> void:
	_tooltip_label.text = text.strip_edges()
	_tooltip.visible = true
	_tooltip.reset_size()
	_place_tooltip()


## The runes of a committed line or node, or "" to fall back to the carving tooltip
func _disenchant_tooltip(key: String) -> String:
	if disenchant.has_edge(key):
		var ends := disenchant.edge_ends(key)
		var text := (
			"[b]Line[/b] of %s\n" % disenchant.edge_placement(key).enchantment.enchantment_name
		)
		text += "Cutting costs %s\n" % disenchant.edge_cost(key).describe()
		for n in ends:
			text += (
				"  %s puts %s on it\n"
				% [disenchant.node_label(n), disenchant.node_edge_runes(n).describe()]
			)
		var step := disenchant.planned_step_of_edge(key)
		text += (
			"Planned as step %d. Right click undoes the last step." % (step + 1)
			if step >= 0
			else "Click to plan cutting it."
		)
		return text
	if not board.has_node(key) or disenchant.node_edges(key).is_empty():
		return ""
	var label := disenchant.node_label(key)
	var text := "[b]%s%s[/b]\n" % [label.left(1).to_upper(), label.substr(1)]
	text += "Puts %s on each of its lines\n" % disenchant.node_edge_runes(key).describe()
	text += (
		"Gives back %s when its last line is cut\n" % disenchant.node_harvest_runes(key).describe()
	)
	text += "Committed lines: %d" % disenchant.node_edges(key).size()
	var p := board.node_placement(key)
	if p:
		text += (
			"\nClick to pull %s out once all %d lines of its chain are planned cut."
			% [p.enchantment.enchantment_name, disenchant.chain(p).size()]
		)
	return text


func _place_tooltip() -> void:
	var at := get_global_mouse_position() + Vector2(20, 20)
	var limit := get_viewport_rect().size - _tooltip.size
	_tooltip.position = at.clamp(Vector2.ZERO, limit.max(Vector2.ZERO))


func _on_board_changed() -> void:
	_view.queue_redraw()
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
	_items = _list(left, "Items", 3)
	_items.item_selected.connect(_open_item)
	_enchantments = _list(left, "Enchantments", 4)
	_enchantments.item_selected.connect(_on_enchantment_selected)
	_materials = MaterialList.new()
	_list(left, "Materials", 6, _materials)
	_materials.drag_started.connect(_on_material_drag_started)
	_materials.item_activated.connect(_on_material_activated)
	_help = Label.new()
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.add_theme_font_size_override("font_size", 13)
	left.add_child(_help)

	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(middle)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	middle.add_child(top)
	var modes := ButtonGroup.new()
	_carve_button = _mode_button(top, "Carve", modes)
	_disenchant_button = _mode_button(top, "Disenchant", modes)
	_carve_button.button_pressed = true
	_carve_button.pressed.connect(_set_disenchanting.bind(false))
	_disenchant_button.pressed.connect(_set_disenchanting.bind(true))
	var gap := Control.new()
	gap.custom_minimum_size.x = 24
	top.add_child(gap)
	_rune_bar = RuneBar.new()
	top.add_child(_rune_bar)

	_board_area = BoardDropArea.new()
	_board_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_area.resized.connect(_fit_board)
	middle.add_child(_board_area)
	_view = BoardView.new()
	_board_area.view = _view
	_view.message.connect(_set_message)
	_view.changed.connect(_on_board_changed)
	_view.hovered.connect(_on_hovered)
	_board_area.add_child(_view)

	var right := _panel(root, 320)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 22)
	right.add_child(_timer_label)
	_item_label = _rich(right, 130)
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
	_plan_panel = DisenchantPlanPanel.new()
	_plan_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plan_panel.undo_requested.connect(_on_undo_pressed)
	right.add_child(_plan_panel)
	_legend = _rich(right, 200)
	_legend.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_tooltip = PanelContainer.new()
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.top_level = true
	_tooltip.visible = false
	var tip_style := StyleBoxFlat.new()
	tip_style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	tip_style.border_color = Color("45434f")
	tip_style.set_border_width_all(1)
	tip_style.set_corner_radius_all(6)
	tip_style.set_content_margin_all(10)
	_tooltip.add_theme_stylebox_override("panel", tip_style)
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(_tooltip_label)
	add_child(_tooltip)

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


func _list(parent: Control, title: String, rows: int, list: ItemList = null) -> ItemList:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 18)
	parent.add_child(l)
	if list == null:
		list = ItemList.new()
	list.custom_minimum_size.y = rows * 30 + 8
	parent.add_child(list)
	return list


func _mode_button(parent: Control, text: String, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(120, 36)
	parent.add_child(b)
	return b


func _rich(parent: Control, height: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = false
	r.custom_minimum_size.y = height
	parent.add_child(r)
	return r
