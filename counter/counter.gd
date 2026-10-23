class_name Counter
extends Control

## The counter side of the day. Customers come one at a time. Those back for a finished
## commission come first: the player hands their item back and they pay for each enchantment
## carved on it. New customers bring a commission slip, perhaps an adventurer ID or a permit, and
## the item they want enchanted, which lies on the counter while the player checks the papers
## against the rulebook. Accept, and the item goes to the inscribing table; refuse, and it is
## handed back. A supplier sells materials across the counter for the player's money.

signal visit_decided(visit: CustomerVisit, accepted: bool)
signal commission_collected(commission: Commission)

const SFX_BELL := &"bell"
const SFX_PAPER := &"paper"
const SFX_STAMP := &"stamp"
const SFX_COINS := &"coins"
const SFX_PURCHASE := &"purchase"
const SFX_ERROR := &"error"
const CUSTOMER_ART := preload("res://placeholder_assets/human.png")
const WOOD_ART := preload("res://counter/art/counter_wood.png")
const COIN_ART := preload("res://counter/art/coin.png")
const STONE_ART := preload("res://counter/art/stone.png")
const SIDE_WIDTH := 600.0
const PORTRAIT_HEIGHT := 220.0
const ID_TINT := Color("dce8f4")
const PERMIT_TINT := Color("e2f0d6")
const DONE_COLOR := "#2f7a3a"
const MISSING_COLOR := "#a03028"

@export var visits: Array[CustomerVisit] = []
@export var rulebook: Rulebook
@export var catalogue: SupplierCatalogue

## Today's calls on new commissions, in order, for the end-of-day summary
var decisions: Array[CounterDecision] = []
## Commissions collected today, in order, for the end-of-day summary
var collections: Array[Commission] = []
var player: Player

var _day_number: int = 1
var _queue: Array[CustomerVisit] = []
var _returns: Array[Commission] = []
var _current: CustomerVisit = null
var _current_return: Commission = null
var _portrait: TextureRect
var _customer_label: Label
var _tag_label: Label
var _slip_text: RichTextLabel
var _id_panel: PanelContainer
var _id_text: RichTextLabel
var _permit_panel: PanelContainer
var _permit_text: RichTextLabel
var _item_text: RichTextLabel
var _accept_button: Button
var _refuse_button: Button
var _hand_back_button: Button
var _status_label: Label
var _rules_text: RichTextLabel
var _money_label: Label
var _supplier_rows: GridContainer

@onready var _sounds: SoundBank = $Sounds


func _ready() -> void:
	_build_ui()


## Gives the counter the player whose money, items and commissions it works with
func open(p: Player) -> void:
	player = p
	_refresh_supplier()


## Lines up the day's customers: those back to collect first, then the new ones. Anyone still
## waiting from before has left, and a collector who left comes back the next day.
func open_day(day_number: int) -> void:
	_day_number = day_number
	decisions.clear()
	collections.clear()
	_returns.clear()
	if player != null:
		for c in player.commissions:
			if c.is_due(day_number):
				_returns.append(c)
	_queue.clear()
	for v in visits:
		if v.day == day_number:
			_queue.append(v)
	_status_label.text = ""
	_refresh_rules()
	_refresh_supplier()
	_next_customer()


## Called when the counter becomes the active side
func resume() -> void:
	_show_current()
	_refresh_supplier()


## Called before the counter is frozen
func suspend() -> void:
	pass


func current_visit() -> CustomerVisit:
	return _current


## The commission whose customer is at the counter to collect it, if any
func current_return() -> Commission:
	return _current_return


func accept() -> void:
	_decide(true)


func refuse() -> void:
	_decide(false)


## Gives the collecting customer their item; they pay for what was carved on it
func hand_back() -> void:
	var c := _current_return
	if c == null:
		return
	var wanted := c.visit.slip.enchantments.size()
	var done := c.fulfilled_count()
	var paid := c.collect(player)
	collections.append(c)
	var who := c.visit.slip.customer_name
	if done == wanted:
		_status_label.text = "%s is delighted and pays the full %dg." % [who, paid]
	elif done > 0:
		_status_label.text = (
			"%s pays %dg for %d of the %d enchantments." % [who, paid, done, wanted]
		)
	else:
		_status_label.text = "Nothing %s asked for was carved. They leave without paying." % who
	_sounds.play(SFX_COINS if paid > 0 else SFX_ERROR)
	commission_collected.emit(c)
	_refresh_supplier()
	_next_customer()


## Buys one of a material from the supplier; returns whether the player could afford it
func buy(m: EnchantmentMaterialDefinition) -> bool:
	var price := catalogue.price_of(m)
	var mat_name := InscriptionBoard.material_name(m)
	if not player.spend(price):
		_status_label.text = "You can't afford a %s (%dg)." % [mat_name, price]
		_sounds.play(SFX_ERROR)
		return false
	player.add_material(m)
	_status_label.text = "Bought a %s for %dg." % [mat_name, price]
	_sounds.play(SFX_PURCHASE)
	_refresh_supplier()
	return true


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
	_sounds.play(SFX_STAMP if accepted else SFX_PAPER)
	visit_decided.emit(visit, accepted)
	_next_customer()


func _next_customer() -> void:
	_current_return = null if _returns.is_empty() else _returns.pop_front()
	_current = null
	if _current_return == null and not _queue.is_empty():
		_current = _queue.pop_front()
	if _current != null or _current_return != null:
		_sounds.play(SFX_BELL)
	_show_current()


func _show_current() -> void:
	var v := _current if _current != null else (_current_return.visit if _current_return else null)
	var collecting := _current_return != null
	_accept_button.visible = not collecting
	_refuse_button.visible = not collecting
	_hand_back_button.visible = collecting
	_accept_button.disabled = _current == null
	_refuse_button.disabled = _current == null
	_id_panel.visible = not collecting
	_permit_panel.visible = not collecting
	_portrait.visible = v != null
	if v == null:
		_customer_label.text = "No one is waiting."
		_tag_label.text = ""
		_slip_text.text = "[i]The counter is empty.[/i]"
		_id_text.text = ""
		_permit_text.text = ""
		_item_text.text = ""
		return
	var slip := v.slip
	_portrait.self_modulate = _customer_tint(slip.customer_name)
	_customer_label.text = "%s, from %s" % [slip.customer_name, slip.kingdom]
	_tag_label.text = (
		"Back to collect from day %d" % _current_return.accepted_day
		if collecting
		else "A new commission"
	)
	_slip_text.text = (
		"[b]Commission slip[/b]\nName: %s\nKingdom: %s\nEnchantments: %s\nItem: %s\nOffers: %dg"
		% [
			slip.customer_name,
			slip.kingdom,
			slip.enchantment_names(),
			slip.item.display_name if slip.item else "none",
			slip.payment,
		]
	)
	if collecting:
		_item_text.text = _return_text(_current_return)
		return
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


## The item being collected, each enchantment asked for ticked or crossed, and the payout
func _return_text(c: Commission) -> String:
	var text := "[b]Their %s[/b]\n" % InscriptionBoard.item_name(c.item)
	var done := c.fulfilled()
	for i in done.size():
		var e := c.visit.slip.enchantments[i]
		text += (
			"[color=%s]%s %s[/color]\n"
			% [
				DONE_COLOR if done[i] else MISSING_COLOR,
				"✓" if done[i] else "✗",
				e.enchantment_name,
			]
		)
	text += "\nThey will pay [b]%dg[/b] of the %dg offered." % [c.payout(), c.visit.slip.payment]
	return text


func _refresh_rules() -> void:
	var text := "[b]Rulebook[/b]   Today is day %d.\n\n" % _day_number
	for i in rulebook.rules.size():
		text += "%d. %s\n" % [i + 1, rulebook.rules[i].description]
	_rules_text.text = text


func _refresh_supplier() -> void:
	if player == null or _supplier_rows == null:
		return
	_money_label.text = "%dg" % player.money
	for child in _supplier_rows.get_children():
		_supplier_rows.remove_child(child)
		child.queue_free()
	for m in catalogue.materials():
		var icon := TextureRect.new()
		icon.texture = STONE_ART
		icon.self_modulate = m.color
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_supplier_rows.add_child(icon)
		var mat_label := Label.new()
		mat_label.text = InscriptionBoard.material_name(m)
		mat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_supplier_rows.add_child(mat_label)
		var owned := Label.new()
		owned.text = "×%d" % player.get_material_count(m)
		owned.custom_minimum_size.x = 60
		_supplier_rows.add_child(owned)
		var price := catalogue.price_of(m)
		var buy_button := Button.new()
		buy_button.text = "Buy %dg" % price
		buy_button.custom_minimum_size.x = 140
		buy_button.disabled = price > player.money
		buy_button.focus_mode = Control.FOCUS_NONE
		buy_button.pressed.connect(buy.bind(m))
		_supplier_rows.add_child(buy_button)


## A steady colour per customer, so the placeholder figure tells them apart
func _customer_tint(customer_name: String) -> Color:
	return Color.from_hsv(float(hash(customer_name) % 360) / 360.0, 0.35, 0.95)


#
# ── UI construction ──────────────────────────────
#
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = WOOD_ART
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)

	var front := VBoxContainer.new()
	front.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	front.add_theme_constant_override("separation", 18)
	root.add_child(front)
	_build_customer(front)

	var side_column := VBoxContainer.new()
	side_column.custom_minimum_size.x = SIDE_WIDTH
	side_column.add_theme_constant_override("separation", 18)
	root.add_child(side_column)
	_build_side(side_column)


func _build_customer(parent: VBoxContainer) -> void:
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 20)
	parent.add_child(who)
	_portrait = TextureRect.new()
	_portrait.texture = CUSTOMER_ART
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(PORTRAIT_HEIGHT * 0.45, PORTRAIT_HEIGHT)
	who.add_child(_portrait)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_child(names)
	_customer_label = Label.new()
	_customer_label.theme_type_variation = &"HeaderLabel"
	names.add_child(_customer_label)
	_tag_label = Label.new()
	_tag_label.theme_type_variation = &"TagLabel"
	names.add_child(_tag_label)

	var papers := HBoxContainer.new()
	papers.add_theme_constant_override("separation", 18)
	parent.add_child(papers)
	_slip_text = _paper(papers, Color.WHITE).get_child(0)
	_id_panel = _paper(papers, ID_TINT)
	_id_text = _id_panel.get_child(0)
	_permit_panel = _paper(papers, PERMIT_TINT)
	_permit_text = _permit_panel.get_child(0)
	_item_text = _paper(parent, Color.WHITE).get_child(0)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	parent.add_child(buttons)
	_accept_button = _button(buttons, "Accept", accept, &"AcceptButton")
	_refuse_button = _button(buttons, "Refuse", refuse, &"RefuseButton")
	_hand_back_button = _button(buttons, "Hand the item back", hand_back, &"AcceptButton")
	_status_label = Label.new()
	_status_label.theme_type_variation = &"TagLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_status_label)


func _build_side(parent: VBoxContainer) -> void:
	var rules_panel := PanelContainer.new()
	rules_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(rules_panel)
	_rules_text = RichTextLabel.new()
	_rules_text.bbcode_enabled = true
	rules_panel.add_child(_rules_text)

	var supplier := PanelContainer.new()
	parent.add_child(supplier)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	supplier.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	var title := Label.new()
	title.text = "Supplier"
	title.theme_type_variation = &"TagLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var coin := TextureRect.new()
	coin.texture = COIN_ART
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(40, 40)
	header.add_child(coin)
	_money_label = Label.new()
	_money_label.theme_type_variation = &"MoneyLabel"
	header.add_child(_money_label)
	_supplier_rows = GridContainer.new()
	_supplier_rows.columns = 4
	_supplier_rows.add_theme_constant_override("h_separation", 14)
	_supplier_rows.add_theme_constant_override("v_separation", 10)
	box.add_child(_supplier_rows)


## A paper on the counter: dark text on parchment, tinted per kind of paper
func _paper(parent: Control, tint: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PaperPanel"
	panel.self_modulate = tint
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var text := RichTextLabel.new()
	text.theme_type_variation = &"PaperText"
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size = Vector2(260, 200)
	panel.add_child(text)
	return panel


func _button(parent: Control, label: String, action: Callable, variation: StringName) -> Button:
	var b := Button.new()
	b.text = label
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(220, 64)
	# Unfocusable, so Space or Enter after a click doesn't accept the next customer unseen
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b
