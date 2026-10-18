extends Control

"""
The inscribing (carving) table for the first build: pick an item, plan enchantments, lines and
materials on its hex map, then commit. Plans are drafts kept on each item, so switching items and
coming back keeps them. The day timer runs continuously; when it ends, the day is over.
In Disenchant mode the same table plans cuts, dissolves and pull-outs on the item's committed
carvings (see DisenchantBoard), with the runes in a bar above the board and the plan on the right.
"""

## The palette layouts being compared (sheet 0004); the losers go once one is picked
enum Layout { SIDEBAR, BOTTOM_TRAY, QUICK_PALETTE, LISTS }

const CARVE_HELP := (
	"Drag an enchantment onto the item (R rotates it), or click it to hold it. "
	+ "Press on a node and drag through cells to draw a line; move back to undo. "
	+ "Drag a material onto a node. Right click removes planned things. "
	+ "Commit when every node shows a tick."
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
	+ "you can't afford them. A green ring marks a node that pays out in the plan. "
	+ "Magic nodes show their number.\n"
	+ "Hover a node or line for its runes."
)
const LAYOUT_NAMES: Array[String] = [
	"Sidebar", "Bottom tray", "Quick palette (hold Space)", "Lists (original)"
]

@export var setup: DemoSetup = preload("res://inscribing/demo/demo_setup.tres")
## Dev tool: prints whether carved items can be disenchanted. Tick Enabled on it to use it.
@export var solvability_check: SolvabilityCheck

var player: Player
var board: InscriptionBoard
## The board's disenchant rules while in Disenchant mode, otherwise null
var disenchant: DisenchantBoard
var time_left: float = 0.0
var day: int = 1

var _view: BoardView
var _board_area: BoardDropArea
var _item_picker: OptionButton
var _layout_picker: OptionButton
var _layout: PaletteLayout
var _left_slot: Control
var _bottom_slot: Control
var _overlay: Control
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
var _legend: RichTextLabel
var _overview: ItemOverview


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player = setup.create_player()
	PlayerManager.set_player(player)
	time_left = setup.day_length_seconds
	_build_ui()
	_build_overview()
	_set_layout(Layout.SIDEBAR)
	_refresh_items()
	if not player.items.is_empty():
		_item_picker.select(0)
		_open_item(0)
	if solvability_check:
		solvability_check.check_items(player.items, player)


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
	_refresh_all()
	if board.get_cells().is_empty():
		_set_message("This item's map has no cells. Paint its map scene and press Bake.")


func _on_item_picked(index: int) -> void:
	_open_item(index)
	if solvability_check:
		solvability_check.check_item(player.items[index], player)


func is_disenchanting() -> bool:
	return _disenchant_button.button_pressed


func _set_disenchanting(on: bool) -> void:
	_disenchant_button.set_pressed_no_signal(on)
	_carve_button.set_pressed_no_signal(not on)
	_view.held_enchantment = null
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


## Click-to-hold, kept as a fallback to dragging
func _hold_enchantment(e: Enchantment) -> void:
	if is_disenchanting():
		_set_message("Switch to Carve to place enchantments")
		return
	_view.held_rotation = 0
	_view.held_enchantment = e
	_set_message(
		(
			"Click the item to place %s. Scroll or press R to rotate, right click to put it down."
			% e.enchantment_name
		)
	)


func _on_card_pressed(payload: Resource) -> void:
	if payload is Enchantment:
		_hold_enchantment(payload)
	elif is_disenchanting():
		_set_message(
			(
				"Double-click %s to dissolve it"
				% InscriptionBoard.material_name(payload as EnchantmentMaterialDefinition)
			)
		)
	elif _is_used_up(payload):
		_set_message(_used_up_message(payload))
	else:
		_set_message("Drag the material onto an enchantment node.")


## Whether `payload` is a material the player has none of
func _is_used_up(payload: Resource) -> bool:
	var m := payload as EnchantmentMaterialDefinition
	return m != null and player.get_material_count(m) == 0


func _used_up_message(payload: Resource) -> String:
	return "No %s left" % InscriptionBoard.material_name(payload as EnchantmentMaterialDefinition)


func _on_card_drag_started(payload: Resource) -> void:
	if is_disenchanting():
		_on_card_pressed(payload)
		return
	if _is_used_up(payload):
		_set_message(_used_up_message(payload))
		return
	_view.held_enchantment = null
	if _layout:
		_layout.on_drag_started()
	if payload is Enchantment:
		_view.held_rotation = 0
		_set_message(
			(
				"Drop %s onto the item. Press R or scroll to rotate it while dragging."
				% (payload as Enchantment).enchantment_name
			)
		)
	else:
		_set_message(
			(
				"Drop %s onto an enchantment node. Green rings show the nodes that accept it."
				% InscriptionBoard.material_name(payload as EnchantmentMaterialDefinition)
			)
		)


func _unhandled_key_input(event: InputEvent) -> void:
	if _handle_overview_key(event as InputEventKey):
		return
	if _layout and not _day_over.visible and _layout.handle_key(event as InputEventKey):
		get_viewport().set_input_as_handled()


func _set_layout(which: Layout) -> void:
	if _layout:
		_layout.queue_free()
	match which:
		Layout.SIDEBAR:
			_layout = CollapsibleSidebar.new()
		Layout.BOTTOM_TRAY:
			_layout = BottomTray.new()
		Layout.QUICK_PALETTE:
			_layout = QuickPalette.new()
		_:
			var lists := ClassicLists.new()
			lists.enchantment_chosen.connect(_on_card_pressed)
			lists.material_list().drag_started.connect(_on_card_drag_started)
			lists.material_activated.connect(_on_material_activated)
			_layout = lists
	match _layout.slot():
		PaletteLayout.Slot.LEFT:
			_left_slot.add_child(_layout)
			_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
		PaletteLayout.Slot.BOTTOM:
			_bottom_slot.add_child(_layout)
			_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
		_:
			_overlay.add_child(_layout)
	_left_slot.visible = _layout.slot() == PaletteLayout.Slot.LEFT
	_bottom_slot.visible = _layout.slot() == PaletteLayout.Slot.BOTTOM
	_bottom_slot.custom_minimum_size.y = _layout.custom_minimum_size.y
	_layout_picker.select(which)
	_refresh_cards()


## Plans dissolving `m` (a double-click on its card or list row)
func _on_material_activated(m: EnchantmentMaterialDefinition) -> void:
	if not is_disenchanting():
		_set_message("Drag materials onto enchantment nodes. Dissolving is for Disenchant mode.")
		return
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
	_refresh_items()
	_refresh_cards()
	_refresh_item_panel()
	_refresh_commit()
	_refresh_mode()
	_on_hovered("")


func _refresh_mode() -> void:
	var on := is_disenchanting()
	_rune_bar.visible = on
	_plan_panel.visible = on
	var texts := [DISENCHANT_LEGEND, DISENCHANT_HELP] if on else [CARVE_LEGEND, CARVE_HELP]
	_legend.text = "%s\n\n[b]Working[/b]\n%s" % texts
	if on and disenchant:
		_rune_bar.show_runes(disenchant.runes())
		_plan_panel.show_plan(disenchant)


func _refresh_items() -> void:
	var selected := _item_picker.selected
	_item_picker.clear()
	for inst in player.items:
		var carved := _item_effects(inst) != "nothing"
		_item_picker.add_item(_item_name(inst) + ("  (carved)" if carved else ""))
	if selected >= 0 and selected < _item_picker.item_count:
		_item_picker.select(selected)


func _refresh_cards() -> void:
	if _layout == null:
		return
	var on := is_disenchanting()
	var enchantment_cards: Array[PaletteCard] = []
	for e in player.known_enchantments:
		var card := _card(
			e, e.enchantment_name, "%d nodes" % e.nodes.size(), _enchantment_tooltip(e), on
		)
		card.draggable = not on
		enchantment_cards.append(card)
	var material_cards: Array[PaletteCard] = []
	for m in _material_order():
		var count := player.get_material_count(m)
		var planned := board.planned_count(m) if board else 0
		var sub := "×%d" % count
		if planned > 0:
			sub += "  (+%d planned here)" % planned
		var card := _card(
			m, InscriptionBoard.material_name(m), sub, _material_tooltip(m), count == 0
		)
		card.draggable = not on and count > 0
		material_cards.append(card)
	_layout.set_cards(enchantment_cards, material_cards)


func _card(
	payload: Resource, title: String, sub: String, tip: String, dimmed := false
) -> PaletteCard:
	var card := PaletteCard.new(payload, title, sub, tip, dimmed)
	card.drag_started.connect(_on_card_drag_started)
	card.pressed.connect(_on_card_pressed)
	card.double_clicked.connect(_on_card_double_clicked)
	return card


func _on_card_double_clicked(payload: Resource) -> void:
	if payload is EnchantmentMaterialDefinition:
		_on_material_activated(payload)


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
# ── Item overview ────────────────────────────────
#
## The Items button beside the item picker, and the overview under the day-over screen
func _build_overview() -> void:
	var button := Button.new()
	button.text = ItemOverview.OPEN_TEXT
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_open_overview)
	_item_picker.get_parent().add_child(button)
	_overview = ItemOverview.new()
	_overview.item_chosen.connect(_on_overview_item_chosen)
	_overview.close_requested.connect(_overview.close)
	add_child(_overview)
	move_child(_overview, _day_over.get_index())


func _open_overview() -> void:
	var names: Array[String] = []
	for inst in player.items:
		names.append(_item_name(inst))
	_tooltip.visible = false
	_overview.open(player.items, names)


## Opens the chosen item the same way the item picker does
func _on_overview_item_chosen(index: int) -> void:
	_overview.close()
	_item_picker.select(index)
	_on_item_picked(index)


func _handle_overview_key(event: InputEventKey) -> bool:
	if _day_over.visible or not event.pressed or event.echo:
		return false
	if event.keycode != ItemOverview.OPEN_KEY:
		return false
	_open_overview()
	get_viewport().set_input_as_handled()
	return true


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

	_left_slot = Control.new()
	_left_slot.custom_minimum_size.x = 290
	_left_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_left_slot)

	var board_column := VBoxContainer.new()
	board_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_column.add_theme_constant_override("separation", 0)
	board_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(board_column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	board_column.add_child(top)
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
	var board_stack := Control.new()  # The board, with the overlay layouts on top of it
	board_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_column.add_child(board_stack)
	_board_area = BoardDropArea.new()
	_board_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_area.resized.connect(_fit_board)
	board_stack.add_child(_board_area)
	_view = BoardView.new()
	_board_area.view = _view
	_view.message.connect(_set_message)
	_view.changed.connect(_on_board_changed)
	_view.hovered.connect(_on_hovered)
	_board_area.add_child(_view)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_stack.add_child(_overlay)
	_bottom_slot = Control.new()
	_bottom_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_column.add_child(_bottom_slot)

	var right := _panel(root, 320)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 22)
	right.add_child(_timer_label)
	_item_picker = _picker(right, "Item")
	_item_picker.item_selected.connect(_on_item_picked)
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
	_layout_picker = _picker(right, "Layout (experiment)")
	for n in LAYOUT_NAMES:
		_layout_picker.add_item(n)
	_layout_picker.item_selected.connect(func(i: int): _set_layout(i as Layout))

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


func _picker(parent: Control, title: String) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = title
	row.add_child(l)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.focus_mode = Control.FOCUS_NONE
	row.add_child(picker)
	return picker


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
