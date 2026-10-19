class_name Counter
extends Control

## The counter side of the day. Customers come one at a time with a commission slip, perhaps an
## adventurer ID or a permit, and the item they want enchanted, which lies on the counter while
## the player checks the papers against the rulebook. Accept, and the item goes to the inscribing
## table; refuse, and it is handed back.

signal visit_decided(visit: CustomerVisit, accepted: bool)

@export var visits: Array[CustomerVisit] = []
@export var rulebook: Rulebook

## Today's calls, in order, for the end-of-day summary
var decisions: Array[CounterDecision] = []

var _day_number: int = 1
var _queue: Array[CustomerVisit] = []
var _current: CustomerVisit = null
var _customer_label: Label
var _slip_text: RichTextLabel
var _id_text: RichTextLabel
var _permit_text: RichTextLabel
var _item_text: RichTextLabel
var _accept_button: Button
var _refuse_button: Button
var _status_label: Label
var _rules_text: RichTextLabel


func _ready() -> void:
	_build_ui()


## Lines up the customers who come on this day; anyone still waiting from before has left
func open_day(day_number: int) -> void:
	_day_number = day_number
	decisions.clear()
	_queue.clear()
	for v in visits:
		if v.day == day_number:
			_queue.append(v)
	_status_label.text = ""
	_refresh_rules()
	_next_customer()


## Called when the counter becomes the active side
func resume() -> void:
	_show_current()


## Called before the counter is frozen
func suspend() -> void:
	pass


func current_visit() -> CustomerVisit:
	return _current


func accept() -> void:
	_decide(true)


func refuse() -> void:
	_decide(false)


func _decide(accepted: bool) -> void:
	if _current == null:
		return
	var visit := _current
	decisions.append(CounterDecision.new(visit, accepted, rulebook.problems(visit, _day_number)))
	var item := visit.slip.item
	var who := visit.slip.customer_name
	if accepted:
		_status_label.text = (
			"Accepted %s's commission. The %s goes to the inscribing table."
			% [who, item.display_name if item else "item"]
		)
	else:
		_status_label.text = (
			"Refused %s. %s" % [who, "You hand the %s back." % item.display_name if item else ""]
		)
	visit_decided.emit(visit, accepted)
	_next_customer()


func _next_customer() -> void:
	_current = null if _queue.is_empty() else _queue.pop_front()
	_show_current()


func _show_current() -> void:
	var v := _current
	_accept_button.disabled = v == null
	_refuse_button.disabled = v == null
	if v == null:
		_customer_label.text = "No one is waiting."
		_slip_text.text = ""
		_id_text.text = ""
		_permit_text.text = ""
		_item_text.text = ""
		return
	var slip := v.slip
	_customer_label.text = "%s, from %s" % [slip.customer_name, slip.kingdom]
	_slip_text.text = (
		"[b]Commission slip[/b]\nName: %s\nKingdom: %s\nEnchantment: %s\nItem: %s\nOffers: %dg"
		% [
			slip.customer_name,
			slip.kingdom,
			slip.enchantment.enchantment_name,
			slip.item.display_name if slip.item else "none",
			slip.payment,
		]
	)
	var id := v.adventurer_id
	_id_text.text = (
		(
			"[b]Adventurer ID[/b]\nName: %s\nTier: %d\nKingdom: %s\nValid until: day %d"
			% [id.holder_name, id.tier, id.kingdom, id.expires_day]
		)
		if id
		else "[i]No adventurer ID shown[/i]"
	)
	var permit := v.permit
	if permit:
		var covers: Array[String] = []
		for e in permit.covers:
			covers.append(e.enchantment_name)
		_permit_text.text = (
			"[b]Permit[/b]\nName: %s\nIssued by: %s\nCovers: %s\nValid in: %s\nValid until: day %d"
			% [
				permit.holder_name,
				permit.issuer,
				", ".join(covers),
				", ".join(permit.kingdoms),
				permit.expires_day,
			]
		)
	else:
		_permit_text.text = "[i]No permit shown[/i]"
	_item_text.text = (
		"[b]On the counter[/b]\n%s" % (slip.item.display_name if slip.item else "Nothing")
	)


func _refresh_rules() -> void:
	var text := "[b]Rulebook[/b]\nToday is day %d.\n\n" % _day_number
	for i in rulebook.rules.size():
		text += "%d. %s\n\n" % [i + 1, rulebook.rules[i].description]
	_rules_text.text = text


#
# ── UI construction ──────────────────────────────
#
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1c1a17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var papers := _column(root, 0.0)
	papers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_customer_label = Label.new()
	_customer_label.add_theme_font_size_override("font_size", 24)
	papers.add_child(_customer_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	papers.add_child(row)
	_slip_text = _card(row, Color("e8dcc0"))
	_id_text = _card(row, Color("c9d8e8"))
	_permit_text = _card(row, Color("d8e8c9"))
	_item_text = _card(papers, Color("b8a890"))
	_item_text.custom_minimum_size.y = 80

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	papers.add_child(buttons)
	_accept_button = _button(buttons, "Accept", accept)
	_refuse_button = _button(buttons, "Refuse", refuse)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color("f0d68a"))
	papers.add_child(_status_label)

	var rules := _column(root, 360.0)
	_rules_text = RichTextLabel.new()
	_rules_text.bbcode_enabled = true
	_rules_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules.add_child(_rules_text)


func _column(parent: Control, width: float) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.custom_minimum_size.x = width
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	parent.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)
	return v


## A paper on the counter: dark text on a light card
func _card(parent: Control, paper: Color) -> RichTextLabel:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = paper
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size = Vector2(200, 140)
	text.add_theme_color_override("default_color", Color("2a2620"))
	panel.add_child(text)
	return text


func _button(parent: Control, label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(160, 48)
	b.pressed.connect(action)
	parent.add_child(b)
	return b
