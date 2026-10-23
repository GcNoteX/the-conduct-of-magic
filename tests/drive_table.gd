extends Node

"""
Drives the inscribing table, inside a Day, with simulated mouse input and saves screenshots.
Run (needs a display): godot --path . res://tests/drive_table.tscn -- <output_dir>
"""

const FIRE := preload("res://items/enchantment_materials/fire_stone/fire_stone.tres")
const YELLOW := preload("res://items/enchantment_materials/yellow_stone/yellow_stone.tres")
## The long sword's place in the demo player's items (dagger, short sword, long sword, carved)
const LONG_SWORD := 2
const BLUE := preload("res://items/enchantment_materials/blue_stone/blue_stone.tres")
const CARVED := preload("res://inscribing/demo/carved_demo_sword.tres")
const KINDLE := preload("res://enchantments/patterns/kindle.tres")
## Where Kindle is dropped on the long sword when it fits there (otherwise the first cell it fits)
const KINDLE_CELL := Vector2i(1, 5)
## The most lines drawn to one node while trying to make its material active
const MAX_LINES_PER_NODE := 4
## Somewhere off the board and the palettes, for ending drags that shouldn't drop anything
const NOWHERE := Vector2(1300, 900)
## Seconds to hover before a card's tooltip shows (the default tooltip delay is half a second)
const TOOLTIP_WAIT := 1.0

var out_dir := "user://"
var day: Day
var table: InscribingTable
var view: BoardView


func _ready() -> void:
	get_tree().create_timer(60.0).timeout.connect(
		func():
			printerr("drive_table timed out")
			get_tree().quit(1)
	)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	day = preload("res://day/day.tscn").instantiate()
	day.setup = preload("res://inscribing/demo/demo_setup.tres")  # The test bench's demo items
	add_child(day)
	day.switch_to(Day.ShopSide.INSCRIBING)
	table = day.table
	await _frames(5)
	view = table._view
	_shot("00_dagger")
	table._item_picker.select(1)
	table._open_item(1)
	await _frames(2)
	_shot("00_short_sword")
	# Carve on the long sword, the largest of the three
	table._item_picker.select(LONG_SWORD)
	table._open_item(LONG_SWORD)
	await _frames(2)
	_shot("01_empty")

	# Drag Kindle from the sidebar, rotating it once mid-drag to show the ghost turn, then turning
	# it the rest of the way round and dropping it unrotated where the plan says
	var plan := _kindle_plan()
	if plan.is_empty():
		print("FAIL: Kindle can't be made active anywhere on the long sword")
		get_tree().quit(1)
		return
	var origin: Vector2i = plan.origin
	_start_drag(_card(KINDLE))
	_move(_cell(origin))
	_key(KEY_R)
	_move(_cell(origin) + Vector2(1, 0))
	await _frames(2)
	_shot("02_dragging_rotated")
	for i in Hex.DIRECTIONS.size() - 1:
		_key(KEY_R)
	_move(_cell(origin))
	_release(_cell(origin))
	await _frames(2)
	var p: PlacementState = table.board.state.placements[0]
	var keys := _node_keys(p)
	print(
		"placed: ",
		table.board.state.placements.size(),
		" rotation: ",
		p.rotation_steps,
		" nodes: ",
		keys.size()
	)

	# Drag a material each node accepts onto it, showing the drop preview on the first
	table._layout.set_open(true)
	await _frames(15)
	for i in keys.size():
		var m: EnchantmentMaterialDefinition = plan.materials[i]
		var at := _cell(table.board.node_cell(keys[i]))
		_start_drag(_card(m))
		_move(at)
		if i == 0:
			await _frames(15)
			_shot("03_drop_preview")
		_release(at)
		await _frames(2)
	_move(_cell(table.board.node_cell(keys[0])))
	await _frames(2)
	_shot("04_inserted")
	var held: Array[String] = []
	for k in keys:
		held.append(InscriptionBoard.material_name(table.board.node_material(k)))
	print("materials: ", held)

	# Draw the plan's lines cell by cell, with a wobble on the first one, then an unconnected chain
	# of magic nodes
	var routes: Array = plan.routes
	for i in routes.size():
		_draw_path(_with_wobble(routes[i]) if i == 0 else routes[i])
	var guard: Array[Vector2i] = []
	for q in range(-7, 2):
		guard.append(Vector2i(q, 14))
	_draw_path(guard)
	await _frames(2)
	print(
		"lines: ", table.board.state.lines.size(), " active: ", table.board.is_placement_active(p)
	)
	# Try to cross the first line and hold the mouse there
	var cross := _crossing_path(keys, routes[0] if not routes.is_empty() else [])
	if not cross.is_empty():
		_draw_path(cross, false)
		await _frames(2)
		_shot("05_blocked")
		_release(_cell(cross.back()))
	_move(_cell(table.board.node_cell(keys[0])))
	await _frames(2)
	_shot("06_active")
	await _overview()

	# The unconnected chain blocks the commit until it's removed
	print("commit button: ", table._commit_button.text)
	_click(_cell(Vector2i(-4, 14)), MOUSE_BUTTON_RIGHT)
	await _frames(2)
	table._on_commit_pressed()
	await _frames(2)
	print("committed: ", p.committed, " message: ", table._message_label.text)
	_shot("07_committed")
	await _drag_used_up()

	await _disenchant()

	# Both palettes, back in Carve mode
	_click(table._carve_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	await _palettes()

	await _replay_checker_plans()
	await _bastion_ports()
	_key(ItemOverview.OPEN_KEY)
	await _frames(3)
	_shot("28_overview_bastion")
	_key(KEY_ESCAPE)
	await _frames(2)
	await _bastion_parallel_cut()
	await _art_on_and_off()

	day.time_left[Day.ShopSide.INSCRIBING] = 0.01
	await _frames(3)
	_shot("08_day_over")
	get_tree().quit()


## The item overview while the long sword holds planned materials: open it with I, hover the
## long sword's card for its tooltip, click the short sword's card, then go back to the long sword
func _overview() -> void:
	_key(ItemOverview.OPEN_KEY)
	await _frames(3)
	_shot("21_overview")
	# The overview keeps the palette's keys from reaching the table while it's open
	var was_open: bool = table._layout.is_open
	_key(KEY_TAB)
	await _frames(2)
	print("tab under the overview toggled the sidebar: ", table._layout.is_open != was_open)
	var cards: Array[ItemCard] = table._overview.cards()
	_move(cards[LONG_SWORD].get_global_rect().get_center())
	await get_tree().create_timer(TOOLTIP_WAIT).timeout
	await _frames(2)
	_shot("22_overview_tooltip")
	_click(cards[1].get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	print(
		"overview open: ",
		table._overview.visible,
		" opened: ",
		table._item_picker.get_item_text(table._item_picker.selected)
	)
	_shot("23_overview_chose_short_sword")
	table._item_picker.select(LONG_SWORD)
	table._open_item(LONG_SWORD)
	await _frames(2)


## Tries to drag a material the player has none of: no drag starts, and the table says why
func _drag_used_up() -> void:
	var count: int = table.player.get_material_count(BLUE)
	table.player.remove_material(BLUE, count)
	table._refresh_cards()
	table._layout.set_open(true)
	var tabs: TabContainer = table._layout.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await _frames(15)
	# What the GUI asks a card when a drag starts on it
	var data: Variant = _card(BLUE)._get_drag_data(Vector2.ZERO)
	await _frames(2)
	print("empty material drag data: ", data, " message: ", table._message_label.text)
	_shot("07b_used_up")
	tabs.current_tab = 0
	table._layout.set_open(false)
	table.player.add_material(BLUE, count)
	table._refresh_cards()
	await _frames(15)


## Disenchant mode on the pre-carved demo sword: costs on lines, a cut you can't afford, then the
## solvability check's way to clear Kindle done by hand (dissolving, cutting its chain, pulling it
## out), Keen cut with what's left until a cut can't be afforded, and committing
func _disenchant() -> void:
	var carved: int = table.player.items.size() - 1
	table._item_picker.select(carved)
	table._open_item(carved)
	_click(table._disenchant_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	var d: DisenchantBoard = table.disenchant
	print("disenchant mode: ", table.is_disenchanting(), " carvings: ", d.carvings().size())
	var kindle := _carving_of(d, KINDLE)
	if kindle == null:
		print("FAIL: the pre-carved sword has no Kindle")
		return
	var first: String = d.chain(kindle)[0]
	_move(_edge_key_point(first))
	await _frames(2)
	_shot("09_disenchant_costs")

	_click(_edge_key_point(first), MOUSE_BUTTON_LEFT)
	await _frames(2)
	print("blocked step: ", d.first_blocked(), " ", table._message_label.text)
	_shot("10_cant_afford")
	_click(_edge_key_point(first), MOUSE_BUTTON_RIGHT)
	await _frames(1)

	var targets: Array[PlacementState] = [kindle]
	var available: Dictionary = table.player.material_inventory.duplicate()
	var solutions := SolvabilityChecker.new(d).solve(targets, available)
	if solutions.is_empty():
		print("FAIL: Kindle can't be cleared with ", available)
		return
	var dissolves: Array[DisenchantStep] = []
	var others: Array[DisenchantStep] = []
	for step in solutions[0].steps(targets, d):
		if step.kind == DisenchantStep.Kind.DISSOLVE:
			dissolves.append(step)
		else:
			others.append(step)
	# Dissolve by double-clicking the material cards (the cards are rebuilt after each one)
	for step in dissolves:
		await _do_step(step, d)
	var m: EnchantmentMaterialDefinition = dissolves[0].material
	print(
		"planned ",
		InscriptionBoard.material_name(m),
		": ",
		table.board.planned_count(m),
		" card: ",
		_card(m).subtitle
	)
	table._layout.set_open(true)
	var tabs: TabContainer = table._layout.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await _frames(15)
	_shot("11a_sidebar_dissolved")
	tabs.current_tab = 0
	table._layout.set_open(false)
	await _frames(15)
	for step in others.slice(0, 2):
		await _do_step(step, d)
	_move(NOWHERE)
	await _frames(2)
	_shot("11_planning")
	for step in others.slice(2):
		await _do_step(step, d)

	# Keen cuts with what's left over until one can't be afforded, so it shows red
	var added := 0
	for p in d.carvings():
		if p == kindle or added > 0:
			continue
		for k in d.chain(p):
			if d.is_cut_planned(k) or d.first_blocked() >= 0:
				continue
			_click(_edge_key_point(k), MOUSE_BUTTON_LEFT)
			added += 1
	await _frames(2)
	print("plan: ", d.state.disenchant_plan.size(), " blocked: ", d.first_blocked())
	_shot("12_blocked_mid_plan")
	for i in added:
		table._on_undo_pressed()
	await _frames(2)
	print("commit button: ", table._commit_button.text)
	_shot("13_ready_to_commit")

	_click(table._commit_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	print(
		"after commit: ",
		table.disenchant.carvings().size(),
		" message: ",
		table._message_label.text
	)
	for step in dissolves:
		print(
			InscriptionBoard.material_name(step.material),
			" left: ",
			table.player.get_material_count(step.material)
		)
	_shot("14_committed")

	# Disenchant mode works on the sword carved earlier in this run too
	table._item_picker.select(LONG_SWORD)
	table._open_item(LONG_SWORD)
	await _frames(2)
	_shot("15_own_carving")


## Both palette layouts: in Carve mode the sidebar closed with Tab, kept open through a drag by its
## pin and put away by a drag without it, then the quick palette held open with Space and put away
## by a drag. Then both in Disenchant mode, where enchantment cards can't be dragged.
func _palettes() -> void:
	_refill_materials()
	table._layout.set_open(true)
	await _frames(20)
	_key(KEY_TAB)
	await _frames(20)
	print("sidebar open after Tab: ", table._layout.is_open)
	_shot("16_sidebar_closed")
	_key(KEY_TAB)
	await _frames(20)
	var pin: CheckBox = table._layout.find_children("*", "CheckBox", true, false)[0]
	for pinned in [true, false]:
		if pin.button_pressed != pinned:
			_click(pin.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
		await _frames(2)
		_start_drag(_card(FIRE))
		_move(_cell(Vector2i(0, 9)))
		await _frames(20)
		print("sidebar open during a drag, pinned ", pinned, ": ", table._layout.is_open)
		if pinned:
			_shot("17_sidebar_pinned_drag")
		_release(NOWHERE)
		await _frames(2)
		table._layout.set_open(true)
		await _frames(20)

	table._set_layout(table.Layout.QUICK_PALETTE)
	await _frames(2)
	_move(_cell(Vector2i(0, 9)))
	_key(KEY_SPACE, true)
	await _frames(3)
	print("quick palette open with Space held: ", table._layout.is_open())
	_shot("18_quick_palette")
	_start_drag(_card(FIRE))
	await _frames(3)
	print("quick palette open during a drag: ", table._layout.is_open())
	_shot("19_quick_palette_drag")
	_release(NOWHERE)
	_key(KEY_SPACE, false)
	await _frames(2)

	var carved := _fresh_carved_sword()
	table._item_picker.select(carved)
	table._open_item(carved)
	_click(table._disenchant_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	# Space and Tab reach the palette after a click on the mode buttons, instead of pressing them
	table._set_message("")
	_move(_cell(Vector2i(0, 9)))
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	await _frames(2)
	print("Space pressed a focused button: ", table._message_label.text != "")
	_key(KEY_SPACE, true)
	await _frames(3)
	var data: Variant = _card(KINDLE)._get_drag_data(Vector2.ZERO)
	await _frames(2)
	print("disenchant enchantment drag data: ", data, " message: ", table._message_label.text)
	_shot("20_quick_palette_disenchant")
	_key(KEY_SPACE, false)
	table._set_layout(table.Layout.SIDEBAR)
	await _frames(20)
	_shot("20b_sidebar_disenchant")


## The solvability check's plans, done by hand on a fresh pre-carved sword: Kindle alone (sidebar
## cards), Keen alone and both (quick palette, held open with Space for each dissolve). Each
## dissolves the named materials, clicks the named lines in order, clicks a node to pull out and
## presses Commit, then checks the table pulled out exactly what the report said it would.
func _replay_checker_plans() -> void:
	var cases := [
		["kindle", [0], table.Layout.SIDEBAR],
		["keen", [1], table.Layout.QUICK_PALETTE],
		["both", [0, 1], table.Layout.QUICK_PALETTE],
	]
	var report_text := ""
	for c: Array in cases:
		var carved := _fresh_carved_sword()
		table._set_layout(c[2])
		table._item_picker.select(carved)
		table._open_item(carved)
		_click(table._disenchant_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
		await _frames(3)
		var d: DisenchantBoard = table.disenchant
		var targets: Array[PlacementState] = []
		for i: int in c[1]:
			targets.append(d.carvings()[i])
		var available: Dictionary = table.player.material_inventory.duplicate()
		if c[0] == "kindle":
			report_text = SolvabilityCheck.report(d, available)
			_shot("24_labelled_board")
		var steps := SolvabilityChecker.new(d).solve(targets, available)[0].steps(targets, d)
		for s in steps:
			await _do_step(s, d)
		var planned: Array[String] = []
		for s in d.state.disenchant_plan:
			planned.append(d.describe_step(s))
		var wanted: Array[String] = []
		for s in steps:
			wanted.append(d.describe_step(s))
		var labels := " and ".join(targets.map(func(p: PlacementState): return d.carving_name(p)))
		print("checker plan (", labels, ") planned as reported: ", planned == wanted)
		if planned != wanted:
			print("  wanted: ", wanted, "\n  got:    ", planned)
		print("  blocked step: ", d.first_blocked(), " commit check: '", d.check_commit(), "'")
		if c[0] == "kindle":
			# The last cut: its tooltip, plan row and line name all name it the same way
			var row := -1
			for i in steps.size():
				if steps[i].kind == DisenchantStep.Kind.CUT:
					row = i
			var k := DisenchantBoard.step_edge_key(steps[row])
			_move(_edge_key_point(k))
			await _frames(3)
			print("  tooltip: ", table._tooltip_label.get_parsed_text().get_slice("\n", 0))
			print(
				"  plan row %d: " % (row + 1),
				d.describe_step(d.state.disenchant_plan[row]),
				" | ",
				d.edge_name(k)
			)
		_shot("25_%s_planned" % c[0])
		var before: int = d.carvings().size()
		_click(table._commit_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
		await _frames(3)
		var left: Array[String] = []
		for p in table.disenchant.carvings():
			left.append(table.disenchant.carving_name(p))
		print(
			"  committed: pulled out ",
			before - table.disenchant.carvings().size(),
			" of ",
			targets.size(),
			", still carved: ",
			left,
			" message: ",
			table._message_label.text
		)
		_shot("26_%s_committed" % c[0])
	var f := FileAccess.open(out_dir.path_join("solvability_report.txt"), FileAccess.WRITE)
	f.store_string(report_text)
	f.close()


## Puts a fresh copy of the pre-carved sword in its slot and the demo materials back. Returns its
## index.
func _fresh_carved_sword() -> int:
	var index: int = table.player.items.size() - 1
	var fresh: ItemInstance = CARVED.duplicate(true)
	fresh.id = table.player.items[index].id
	table.player.items[index] = fresh
	table.player.material_inventory.clear()
	for m: EnchantmentMaterialDefinition in day.setup.materials:
		table.player.add_material(m, day.setup.materials[m])
	table._refresh_cards()
	return index


## Does one planned step the way a player would: double-click the material's card (holding Space
## for the quick palette), click the line, or click one of the enchantment's nodes
func _do_step(s: DisenchantStep, d: DisenchantBoard) -> void:
	match s.kind:
		DisenchantStep.Kind.DISSOLVE:
			var quick: bool = table._layout is QuickPalette
			if quick:
				_key(KEY_SPACE, true)
				await _frames(1)
			_double_click(_card(s.material))
			if quick:
				_key(KEY_SPACE, false)
		DisenchantStep.Kind.CUT:
			_click(_edge_point(s.a, s.b, s.line), MOUSE_BUTTON_LEFT)
		_:
			var key := InscriptionBoard.enchantment_key(s.placement_id, 0)
			_click(
				(
					view.get_global_transform_with_canvas()
					* view.to_screen(d.board.node_position(key))
				),
				MOUSE_BUTTON_LEFT
			)
	await _frames(1)


## Bastion (the example big node) on the first sword it fits on with room to reach a magic node
## from each of its big node's two ports, with those two lines drawn by mouse
func _bastion_ports() -> void:
	table._set_layout(table.Layout.SIDEBAR)
	table._set_disenchanting(false)
	var found := []
	for item in [1, 2, 0]:
		if found.is_empty():
			table._item_picker.select(item)
			table._open_item(item)
			await _frames(2)
			found = _place_bastion()
	print("bastion placed: ", not found.is_empty())
	if found.is_empty():
		return
	for route in found:
		_draw_path(route)
		await _frames(1)
	var b: InscriptionBoard = table.board
	var big_key := InscriptionBoard.enchantment_key(b.state.placements.back().id, 0)
	print("lines at the big node: ", b.line_count(big_key))
	table._on_board_changed()
	_move(Vector2(1300, 900))  # Off the board, so no tooltip hides the lines
	await _frames(2)
	_shot("27_bastion_ports")


## Bastion, placed by _bastion_ports, filled and committed, then in Disenchant mode the second of
## the two lines joining its left node to its big node planned cut: the plan names it "line 2"
func _bastion_parallel_cut() -> void:
	var b: InscriptionBoard = table.board
	if (
		b.state.placements.is_empty()
		or b.state.placements.back().enchantment.enchantment_name != "Bastion"
	):
		return
	var p: PlacementState = b.state.placements.back()
	_refill_materials()
	# As in test_disenchant_board: fire in the big node (its two lines meet fire's condition) and
	# yellow, which always activates, in the two small ones
	table.player.add_material(YELLOW, 2)
	for i in p.enchantment.nodes.size():
		b.insert_material(InscriptionBoard.enchantment_key(p.id, i), FIRE if i == 0 else YELLOW)
	table._on_board_changed()
	_click(table._commit_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	print("bastion committed: ", p.committed, " ", table._message_label.text)
	_refill_materials()
	_click(table._disenchant_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	for m in [FIRE, YELLOW, BLUE]:
		_double_click(_card(m))
		await _frames(1)
	var big := InscriptionBoard.enchantment_key(p.id, 0)
	var left := InscriptionBoard.enchantment_key(p.id, 1)
	_click(_edge_point(left, big, 1), MOUSE_BUTTON_LEFT)
	await _frames(1)
	var d: DisenchantBoard = table.disenchant
	for s in d.state.disenchant_plan:
		print("  bastion plan: ", d.describe_step(s))
	_move(_edge_point(left, big, 1))
	await _frames(3)
	print("  tooltip: ", table._tooltip_label.get_parsed_text().get_slice("\n", 0))
	_shot("29_bastion_parallel_cut")


## The board with its art (sheet 0006) and flat, in both modes: the pre-carved sword in Carve mode
## while a material is dragged over it (green and red rings), then in Disenchant mode with the
## solvability check's Kindle plan entered (step numbers, rune chips, labels and green rings).
## The art pass drags from the sidebar, the flat one from the quick palette.
func _art_on_and_off() -> void:
	for art in [true, false]:
		table._set_layout(table.Layout.SIDEBAR if art else table.Layout.QUICK_PALETTE)
		table.use_art = art
		var look := "art" if art else "flat"
		var carved := _fresh_carved_sword()
		table._set_disenchanting(false)
		table._item_picker.select(carved)
		table._open_item(carved)
		var glow: Enchantment = load("res://enchantments/patterns/glow.tres")
		var at := Vector2i(-99, -99)
		for c in table.board.get_cells():
			if at.x == -99 and table.board.check_place(glow, c, 0) == "":
				at = c
		var p: PlacementState = table.board.place(glow, at, 0)
		print(look, ": placed Glow for the drop rings: ", p != null)
		table._on_board_changed()
		var node: Vector2i = table.board.node_cell(InscriptionBoard.enchantment_key(p.id, 0))
		_start_drag(_card(FIRE))
		await _frames(2)
		_move(_cell(node))
		await _frames(3)
		_shot("30_%s_carve" % look)
		_release(_cell(node))
		await _frames(2)
		print(
			look,
			": dropped fire on Glow: ",
			table.board.node_material(InscriptionBoard.enchantment_key(p.id, 0)) == FIRE
		)
		table._on_board_changed()
		_click(table._disenchant_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
		await _frames(2)
		var d: DisenchantBoard = table.disenchant
		var targets: Array[PlacementState] = [d.carvings()[0]]
		var available: Dictionary = table.player.material_inventory.duplicate()
		var steps := SolvabilityChecker.new(d).solve(targets, available)[0].steps(targets, d)
		for s in steps.slice(0, steps.size() - 2):
			await _do_step(s, d)
		_move(Vector2(1300, 900))
		await _frames(3)
		_shot("31_%s_disenchant" % look)
	table.use_art = true
	table._set_layout(table.Layout.SIDEBAR)


## Gives the player the demo's starting materials again
func _refill_materials() -> void:
	table.player.material_inventory.clear()
	for m: EnchantmentMaterialDefinition in day.setup.materials:
		table.player.add_material(m, day.setup.materials[m])
	table._refresh_cards()


## Places Bastion where both its big node's ports can reach a magic node; returns the two routes
func _place_bastion() -> Array:
	var bastion: Enchantment = load("res://enchantments/patterns/bastion.tres")
	var b: InscriptionBoard = table.board
	for c in b.get_cells():
		for r in 6:
			if b.check_place(bastion, c, r) != "":
				continue
			var p := b.place(bastion, c, r)
			var paths := []
			for port in b.node_ports(InscriptionBoard.enchantment_key(p.id, 0)):
				var route := _route_to_magic(port, paths)
				if not route.is_empty():
					paths.append(route)
			if paths.size() == 2:
				return paths
			b.remove_placement(p)
	return []


## The shortest free route from `start` to a magic node not used by `taken` routes, or []
func _route_to_magic(start: Vector2i, taken: Array) -> Array:
	var b: InscriptionBoard = table.board
	var used := {}
	for t in taken:
		for c in t:
			used[c] = true
	var prev := {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		for n in Hex.neighbours(at):
			if prev.has(n) or used.has(n) or not b.has_cell(n):
				continue
			# A magic node is only ever an end, so a longer way to it is tried from every side
			if b.is_magic(b.node_at(n)):
				var route: Array[Vector2i] = [at, n]
				while route[0] != start:
					route.push_front(prev[route[0]])
				if route.size() > 2 and b.check_line(route) == "":
					return route
				continue
			prev[n] = at
			if b.node_covering(n) == "" and not b.is_occupied(n):
				queue.append(n)
	return []


func _edge_point(a: String, b: String, which := 0) -> Vector2:
	return _edge_key_point(DisenchantBoard.edge_key(a, b, which))


## The middle of a committed line, by its edge key
func _edge_key_point(key: String) -> Vector2:
	return view.get_global_transform_with_canvas() * view._edge_middle(key)


## The committed placement of `e`, or null
func _carving_of(d: DisenchantBoard, e: Enchantment) -> PlacementState:
	for p in d.carvings():
		if p.enchantment == e:
			return p
	return null


## Where Kindle can go unrotated on the open item with a material in each node and lines to magic
## nodes that make it active, trying KINDLE_CELL first. Each spot is tried on the board itself and
## taken off again. Returns {origin, materials (one per node), routes (in drawing order)}, or {}.
func _kindle_plan() -> Dictionary:
	var b: InscriptionBoard = table.board
	var next_id := b.state.next_placement_id
	var spots: Array[Vector2i] = [KINDLE_CELL]
	spots.append_array(b.get_cells())
	for origin in spots:
		if b.check_place(KINDLE, origin, 0) != "":
			continue
		var p := b.place(KINDLE, origin, 0)
		var keys := _node_keys(p)
		var materials: Array[EnchantmentMaterialDefinition] = []
		for k in keys:
			var m := _material_for(b.node_definition(k))
			materials.append(m)
			if m:
				b.insert_material(k, m)
		var routes := _activating_routes(keys)
		var active := b.is_placement_active(p)
		b.remove_placement(p)
		b.state.next_placement_id = next_id
		if active:
			return {"origin": origin, "materials": materials, "routes": routes}
	return {}


## Adds lines from the nodes to magic nodes, one per node in turn, until every node's material is
## active or no more fit. Returns the lines' cells in the order they were added.
func _activating_routes(keys: Array[String]) -> Array:
	var b: InscriptionBoard = table.board
	var routes: Array = []
	for i in MAX_LINES_PER_NODE:
		for k in keys:
			if b.node_material(k) == null or b.is_node_active(k):
				continue
			var route := _route_from_node(k)
			if not route.is_empty():
				b.add_line(route)
				routes.append(route)
	return routes


## The node keys of a placement, in the enchantment's node order
func _node_keys(p: PlacementState) -> Array[String]:
	var out: Array[String] = []
	for i in p.enchantment.nodes.size():
		out.append(InscriptionBoard.enchantment_key(p.id, i))
	return out


## A material the node accepts and the player has, needing the fewest lines to activate (ties go
## to the one listed first)
func _material_for(def: EnchantmentPatternNode) -> EnchantmentMaterialDefinition:
	var best: EnchantmentMaterialDefinition = null
	for m in table.player.materials_in_order(table.material_order):
		if not def.accepts(m) or table.player.get_material_count(m) == 0:
			continue
		if best == null or _lines_needed(m) < _lines_needed(best):
			best = m
	return best


## How many lines a material's conditions ask for at its node (one per magic node it has to reach)
func _lines_needed(m: EnchantmentMaterialDefinition) -> int:
	var n := 0
	for c in m.activation_conditions:
		if c is NumberOfLinesConditon:
			n = maxi(n, (c as NumberOfLinesConditon).number_of_lines)
		elif c is NumberOfConnectionsConditon:
			n = maxi(n, (c as NumberOfConnectionsConditon).number_of_lines)
	return n


## The shortest free route from one of the node's ports to a magic node, or []
func _route_from_node(key: String) -> Array:
	for port in table.board.node_ports(key):
		var route := _route_to_magic(port, [])
		if not route.is_empty():
			return route
	return []


## The route with a step off it and back after its first cell, to show undoing cells while drawing
func _with_wobble(route: Array) -> Array:
	var b: InscriptionBoard = table.board
	for x in Hex.neighbours(route[1]):
		if x in route or not b.has_cell(x) or b.is_occupied(x) or b.node_covering(x) != "":
			continue
		return route.slice(0, 2) + [x] + route.slice(1)
	return route


## A short path from a node's port onto a middle cell of `route`, which the board refuses, or []
func _crossing_path(keys: Array[String], route: Array) -> Array:
	var b: InscriptionBoard = table.board
	var middle := route.slice(1, route.size() - 1)
	for i in range(keys.size() - 1, -1, -1):
		for port in b.node_ports(keys[i]):
			for f in Hex.neighbours(port):
				if not b.has_cell(f) or b.is_occupied(f) or b.node_covering(f) != "":
					continue
				if b.node_at(f) != "":
					continue
				for x in Hex.neighbours(f):
					if x in middle:
						return [port, f, x]
	return []


func _card(payload: Resource) -> PaletteCard:
	for c in table.find_children("*", "PaletteCard", true, false):
		if c.payload == payload and not c.is_queued_for_deletion():
			return c
	return null


func _start_drag(card: PaletteCard) -> void:
	card.force_drag(card.payload, card.make_preview())
	table._on_card_drag_started(card.payload)


func _key(code: Key, pressed := true) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	if code != KEY_SPACE and pressed:
		_key(code, false)


## A double-click on a card, sent straight to it
func _double_click(card: PaletteCard) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.double_click = pressed
		card._gui_input(ev)


func _cell(c: Vector2i) -> Vector2:
	return view.get_global_transform_with_canvas() * view.to_screen(Hex.to_pixel(c, 1.0))


func _move(pos: Vector2) -> void:
	Input.warp_mouse(pos)  # Keeps the real cursor with the simulated one, for the tooltip
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _click(pos: Vector2, button: MouseButton) -> void:
	_move(pos)
	_button(pos, button, true)
	_button(pos, button, false)


func _area(c: Vector2i) -> Vector2:
	return view.position + view.cell_screen(c)


## Presses on the first cell, moves through the rest one by one, then releases unless told not to
func _draw_path(cells: Array, release := true) -> void:
	var start := _cell(cells[0])
	_move(start)
	_button(start, MOUSE_BUTTON_LEFT, true)
	for c in cells.slice(1):
		_move(_cell(c))
	if release:
		_release(_cell(cells.back()))


func _release(pos: Vector2) -> void:
	_button(pos, MOUSE_BUTTON_LEFT, false)


func _button(pos: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = pos
	ev.global_position = pos
	ev.button_index = button
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
