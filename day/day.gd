class_name Day
extends Control

## The root of a play day. Owns the player, the day number and the clock, and decides which side
## is active: the counter or the inscribing table. Each day's plan gives each side its share of
## the clock; the counter comes first, and the day ends when the last side runs out of time.
## The inactive side is hidden and paused, so it picks up exactly where it stopped.
## Debug builds can jump between sides with the dev_switch_side action, whatever the plan says.

enum ShopSide { COUNTER, INSCRIBING }

const DEV_SWITCH_ACTION := &"dev_switch_side"
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
## Items accepted at the counter today, for the end-of-day summary
var accepted_today: Array[ItemInstance] = []

var _clock_label: Label
var _day_over: PanelContainer
var _day_over_text: RichTextLabel

@onready var counter: Counter = $Sides/Counter
@onready var table: InscribingTable = $Sides/InscribingTable


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player = setup.create_player()
	PlayerManager.set_player(player)
	_build_ui()
	counter.item_accepted.connect(_on_item_accepted)
	var shown: Array[EnchantmentMaterialDefinition] = []
	shown.assign(setup.materials.keys())
	table.open(player, shown)
	_start_day()


func _process(delta: float) -> void:
	advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or is_day_over():
		return
	if event.is_action_pressed(DEV_SWITCH_ACTION):
		switch_to(ShopSide.INSCRIBING if side == ShopSide.COUNTER else ShopSide.COUNTER)
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


func _start_day() -> void:
	plan = schedule.plan_for(day_number)
	time_left = {
		ShopSide.COUNTER: plan.counter_seconds,
		ShopSide.INSCRIBING: plan.inscribing_seconds,
	}
	accepted_today.clear()
	_day_over.visible = false
	switch_to(ShopSide.COUNTER if plan.counter_seconds > 0.0 else ShopSide.INSCRIBING)
	if time_left[side] <= 0.0:
		_end_day()


func _on_side_time_up() -> void:
	if side == ShopSide.COUNTER and time_left[ShopSide.INSCRIBING] > 0.0:
		switch_to(ShopSide.INSCRIBING)
	else:
		_end_day()


func _on_item_accepted(definition: EnchantableItemDefinition) -> void:
	var count := 0
	for inst in player.items:
		if inst.definition == definition:
			count += 1
	var inst := ItemInstance.new()
	inst.definition = definition
	inst.id = StringName("%s_%d" % [definition.id, count + 1])
	player.items.append(inst)
	accepted_today.append(inst)


func _end_day() -> void:
	_suspend(side)
	var text := "[b]Day %d is over.[/b]\n\nAccepted at the counter:\n" % day_number
	if accepted_today.is_empty():
		text += "• nothing\n"
	for inst in accepted_today:
		text += "• %s\n" % inst.display_name()
	text += "\nYour items:\n"
	for inst in player.items:
		text += "• %s: %s\n" % [inst.display_name(), inst.carved_effects()]
	text += "\nMaterials left:\n"
	var shown: Array[EnchantmentMaterialDefinition] = []
	shown.assign(setup.materials.keys())
	for m in player.materials_in_order(shown):
		text += "• %s ×%d\n" % [InscriptionBoard.material_name(m), player.get_material_count(m)]
	_day_over_text.text = text
	_day_over.visible = true
	_refresh_clock()


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
		"Day %d · %s · %02d:%02d left" % [day_number, SIDE_NAMES[side], secs / 60, secs % 60]
	)
	if side == ShopSide.COUNTER and time_left.get(ShopSide.INSCRIBING, 0.0) > 0.0:
		text += " · then inscribing"
	if OS.is_debug_build():
		text += "      (dev: F2 switches sides)"
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
	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 18)
	bar.add_child(_clock_label)

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
	card.custom_minimum_size = Vector2(480, 420)
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
	_day_over_text.custom_minimum_size.y = 320
	box.add_child(_day_over_text)
	var next := Button.new()
	next.text = "Start the next day"
	next.pressed.connect(start_next_day)
	box.add_child(next)
