class_name Day
extends Control

## The root of a play day. Owns the player, the day number and the clock, and decides which side
## is active: the counter or the inscribing table. Each day's plan gives each side its share of
## the clock; the counter comes first, and the day ends when the last side runs out of time.
## The inactive side is hidden and paused, so it picks up exactly where it stopped.
## Debug builds can jump between sides with the dev_switch_side action, whatever the plan says,
## and run out the active side's time with dev_end_side.
## Escape or the Menu button opens the pause menu, which can save the run.

enum ShopSide { COUNTER, INSCRIBING }

const DEV_SWITCH_ACTION := &"dev_switch_side"
const DEV_END_SIDE_ACTION := &"dev_end_side"
const PAUSE_ACTION := PauseMenu.PAUSE_ACTION
const BAR_HEIGHT := 40.0
const SIDE_NAMES: Dictionary[ShopSide, String] = {
	ShopSide.COUNTER: "Counter",
	ShopSide.INSCRIBING: "Inscribing",
}

@export var setup: DemoSetup = preload("res://inscribing/demo/demo_setup.tres")
@export var schedule: DaySchedule = preload("res://day/demo/demo_schedule.tres")

var player: Player
var day_number: int = 1
var side: ShopSide = ShopSide.COUNTER
var plan: DayPlan
## Seconds left today on each side
var time_left: Dictionary[ShopSide, float] = {}

var _clock_label: Label
var _day_over: PanelContainer
var _day_over_text: RichTextLabel
var _pause_menu: PauseMenu

@onready var counter: Counter = $Sides/Counter
@onready var table: InscribingTable = $Sides/InscribingTable


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	counter.visit_decided.connect(_on_visit_decided)
	var pending := SaveManager.take_pending_load()
	if pending != null:
		load_game(pending)
		return
	_open_player(setup.create_player())
	_start_day()
	SaveManager.autosave(to_save())


func _process(delta: float) -> void:
	advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(PAUSE_ACTION):
		open_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if not OS.is_debug_build() or is_day_over():
		return
	if event.is_action_pressed(DEV_SWITCH_ACTION):
		switch_to(ShopSide.INSCRIBING if side == ShopSide.COUNTER else ShopSide.COUNTER)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(DEV_END_SIDE_ACTION):
		end_side()
		get_viewport().set_input_as_handled()


## Runs the active side's clock on, and moves the day along when that side's time runs out
func advance(delta: float) -> void:
	if is_day_over():
		return
	var left: float = time_left[side]
	if left > 0.0:
		time_left[side] = maxf(left - delta, 0.0)
		if time_left[side] <= 0.0:
			_on_side_time_up()
	_refresh_clock()


## Dev: ends the active side now. The counter always hands over to the table, even on a day
## with no table time, and the table ends the day.
func end_side() -> void:
	if is_day_over():
		return
	time_left[side] = 0.0
	if side == ShopSide.COUNTER:
		switch_to(ShopSide.INSCRIBING)
	else:
		_end_day()


## Makes a side active, freezing the other one where it is
func switch_to(new_side: ShopSide) -> void:
	if new_side != side:
		_suspend(side)
	side = new_side
	for s: ShopSide in [ShopSide.COUNTER, ShopSide.INSCRIBING]:
		var node := _side_node(s)
		node.visible = s == side
		node.process_mode = Node.PROCESS_MODE_INHERIT if s == side else Node.PROCESS_MODE_DISABLED
	if side == ShopSide.COUNTER:
		counter.resume()
	else:
		table.resume()
	_refresh_clock()


func is_day_over() -> bool:
	return _day_over.visible


func start_next_day() -> void:
	day_number += 1
	_start_day()
	SaveManager.autosave(to_save())


func open_pause_menu() -> void:
	_suspend(side)
	_pause_menu.open()


## A snapshot of the run as it stands. Saved on the day-over screen, it opens on the next day.
func to_save() -> SaveGame:
	var game := SaveGame.new()
	game.player = player
	if is_day_over():
		var next_plan := schedule.plan_for(day_number + 1)
		game.day_number = day_number + 1
		game.counter_seconds_left = next_plan.counter_seconds
		game.inscribing_seconds_left = next_plan.inscribing_seconds
		game.side = ShopSide.COUNTER if next_plan.counter_seconds > 0.0 else ShopSide.INSCRIBING
		return game
	game.day_number = day_number
	game.side = side
	game.counter_seconds_left = time_left[ShopSide.COUNTER]
	game.inscribing_seconds_left = time_left[ShopSide.INSCRIBING]
	game.decisions = counter.decisions.duplicate()
	game.collections = counter.collections.duplicate()
	return game


## Picks the run up where a save left it: same day, same side, same time left, and the counter's
## queue without the customers already seen today
func load_game(game: SaveGame) -> void:
	_open_player(game.player)
	day_number = game.day_number
	plan = schedule.plan_for(day_number)
	time_left = {
		ShopSide.COUNTER: game.counter_seconds_left,
		ShopSide.INSCRIBING: game.inscribing_seconds_left,
	}
	_day_over.visible = false
	counter.resume_day(day_number, game.decisions, game.collections)
	switch_to(game.side)
	if time_left[side] <= 0.0:
		_on_side_time_up()


func _open_player(p: Player) -> void:
	player = p
	PlayerManager.set_player(player)
	counter.open(player)
	table.open(player, setup.shown_materials())


func _start_day() -> void:
	plan = schedule.plan_for(day_number)
	time_left = {
		ShopSide.COUNTER: plan.counter_seconds,
		ShopSide.INSCRIBING: plan.inscribing_seconds,
	}
	_day_over.visible = false
	counter.open_day(day_number)
	switch_to(ShopSide.COUNTER if plan.counter_seconds > 0.0 else ShopSide.INSCRIBING)
	if time_left[side] <= 0.0:
		_end_day()


func _on_side_time_up() -> void:
	if side == ShopSide.COUNTER and time_left[ShopSide.INSCRIBING] > 0.0:
		switch_to(ShopSide.INSCRIBING)
	else:
		_end_day()


func _on_visit_decided(visit: CustomerVisit, accepted: bool) -> void:
	var definition := visit.slip.item
	if not accepted or definition == null:
		return
	var taken: Array[StringName] = []
	for held in player.items:
		taken.append(held.id)
	var number := player.items.size() + 1
	while StringName("%s_%d" % [definition.id, number]) in taken:
		number += 1
	var inst := ItemInstance.new()
	inst.definition = definition
	inst.id = StringName("%s_%d" % [definition.id, number])
	player.items.append(inst)
	player.commissions.append(Commission.create(visit, inst, day_number))


func _end_day() -> void:
	_suspend(side)
	_side_node(side).process_mode = Node.PROCESS_MODE_DISABLED
	var text := "[b]Day %d is over.[/b]\n\nAt the counter:\n" % day_number
	if counter.decisions.is_empty():
		text += "• no one was served\n"
	for d in counter.decisions:
		text += "• %s\n" % _describe(d)
	var earned := 0
	if not counter.collections.is_empty():
		text += "\nCollected:\n"
	for c in counter.collections:
		earned += c.paid
		text += (
			"• %s paid %dg for %d of %d enchantments\n"
			% [
				c.visit.slip.customer_name,
				c.paid,
				c.fulfilled_count(),
				c.visit.slip.enchantments.size(),
			]
		)
	text += "\nEarned today: %dg. Money: %dg.\n" % [earned, player.money]
	var waiting: Array[String] = []
	for c in player.commissions:
		if not c.collected:
			waiting.append(c.visit.slip.customer_name)
	if not waiting.is_empty():
		text += "Coming back tomorrow: %s.\n" % ", ".join(waiting)
	text += "\nYour items:\n"
	for inst in player.items:
		text += "• %s: %s\n" % [InscriptionBoard.item_name(inst), inst.carved_effects()]
	text += "\nMaterials left:\n"
	for m in player.materials_in_order(setup.shown_materials()):
		text += "• %s ×%d\n" % [InscriptionBoard.material_name(m), player.get_material_count(m)]
	_day_over_text.text = text
	_day_over.visible = true
	_refresh_clock()
	SaveManager.autosave(to_save())


func _describe(d: CounterDecision) -> String:
	var call := (
		"%s %s's %s"
		% [
			"Accepted" if d.accepted else "Refused",
			d.visit.slip.customer_name,
			d.visit.slip.enchantment_names(),
		]
	)
	if d.is_right():
		return "[color=#7ee08a]✓[/color] %s. The rulebook agrees." % call
	if d.accepted:
		return "[color=#f06060]✗[/color] %s. The rulebook says: %s." % [call, "; ".join(d.problems)]
	return "[color=#f06060]✗[/color] %s, though the rulebook allowed it." % call


func _suspend(s: ShopSide) -> void:
	if s == ShopSide.COUNTER:
		counter.suspend()
	else:
		table.suspend()


func _side_node(s: ShopSide) -> Control:
	return counter if s == ShopSide.COUNTER else table


func _refresh_clock() -> void:
	var secs := int(ceil(time_left.get(side, 0.0)))
	var text := (
		"Day %d · %s · %02d:%02d left · %dg"
		% [day_number, SIDE_NAMES[side], secs / 60, secs % 60, player.money]
	)
	if side == ShopSide.COUNTER and time_left.get(ShopSide.INSCRIBING, 0.0) > 0.0:
		text += " · then inscribing"
	if OS.is_debug_build():
		text += "      (dev: F2 switches sides, F3 ends this side)"
	_clock_label.text = text


func _build_ui() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size.y = BAR_HEIGHT
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color("24232b")
	bar_style.set_content_margin_all(8)
	bar.add_theme_stylebox_override("panel", bar_style)
	add_child(bar)
	var bar_row := HBoxContainer.new()
	bar.add_child(bar_row)
	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 20)
	_clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(_clock_label)
	var menu_button := Button.new()
	menu_button.text = "Menu"
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.pressed.connect(open_pause_menu)
	bar_row.add_child(menu_button)

	# Day-over screen: a dimmer that blocks both sides, with a summary panel on top
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
	card.custom_minimum_size = Vector2(820, 760)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("24232b")
	card_style.set_corner_radius_all(8)
	card_style.set_content_margin_all(20)
	card.add_theme_stylebox_override("panel", card_style)
	centre.add_child(card)
	var box := VBoxContainer.new()
	card.add_child(box)
	_day_over_text = RichTextLabel.new()
	_day_over_text.bbcode_enabled = true
	_day_over_text.custom_minimum_size.y = 640
	_day_over_text.add_theme_font_size_override("normal_font_size", 22)
	_day_over_text.add_theme_font_size_override("bold_font_size", 26)
	box.add_child(_day_over_text)
	var next := Button.new()
	next.text = "Start the next day"
	next.custom_minimum_size.y = 56
	next.add_theme_font_size_override("font_size", 24)
	next.pressed.connect(start_next_day)
	box.add_child(next)

	_pause_menu = PauseMenu.new()
	_pause_menu.save_requested.connect(_on_save_requested)
	_pause_menu.quit_to_main_menu_requested.connect(_on_quit_requested.bind(false))
	_pause_menu.quit_game_requested.connect(_on_quit_requested.bind(true))
	_pause_menu.closed.connect(_on_pause_menu_closed)
	add_child(_pause_menu)


func _on_save_requested() -> void:
	var err := SaveManager.write_save(to_save())
	_pause_menu.show_status("Saved." if err == OK else "Couldn't save (error %d)." % err)


func _on_quit_requested(to_desktop: bool) -> void:
	if SaveManager.write_save(to_save()) != OK:
		_pause_menu.show_status("Couldn't save, so the game is still open.")
		return
	if to_desktop:
		get_tree().quit()
	else:
		SaveManager.open_main_menu()


func _on_pause_menu_closed() -> void:
	if not is_day_over():
		switch_to(side)
