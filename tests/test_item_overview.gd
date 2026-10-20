extends Node

## Headless checks for the item overview: cards list each item's carvings, plans and held
## materials, and choosing a card (or pressing I, then Esc) works on the table.
## Run: godot --headless --path . res://tests/test_item_overview.tscn
## Exits with code 1 if any check fails.

const SETUP := preload("res://tests/fixtures/demo_setup.tres")
const TABLE := preload("res://inscribing/inscribing_table.tscn")
const KINDLE := preload("res://tests/fixtures/enchantments/kindle.tres")
const BLUE := preload("res://tests/fixtures/materials/blue_stone.tres")
## The fixture demo player's items: dagger, short sword, long sword, then the pre-carved long sword
const DAGGER := 0
const SHORT_SWORD := 1
const CARVED := 3

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_cards_list_carvings_plans_and_held_materials()
	test_clicking_a_card_chooses_it()
	await test_table_opens_the_chosen_item()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func test_cards_list_carvings_plans_and_held_materials() -> void:
	var player := SETUP.create_player()
	var held := plan_kindle(player.items[DAGGER], player)
	var carved_board := InscriptionBoard.new(player.items[CARVED], player)
	check(DisenchantBoard.new(carved_board).plan_dissolve(BLUE) == "", "dissolve planned")

	var overview := open_overview(player)
	var cards := overview.cards()
	check(cards.size() == player.items.size(), "one card per item")

	var dagger := cards[DAGGER]
	check(ItemCard.planned_enchantments(dagger.item) == [KINDLE], "dagger plans Kindle")
	check(ItemCard.carved_enchantments(dagger.item).is_empty(), "dagger has nothing carved")
	check(ItemCard.held_for_carving(dagger.item) == {held: 1}, "dagger holds the material")
	check(dagger.is_holding(), "dagger is marked as holding materials")
	var dagger_lines := dagger.summary()
	check("Carved: nothing" in dagger_lines, "dagger card: nothing carved")
	check("Planned: Kindle" in dagger_lines, "dagger card lists the plan")
	var held_line := "Held for carving: %s ×1" % InscriptionBoard.material_name(held)
	check(held_line in dagger_lines, "dagger card lists the held material: %s" % [dagger_lines])
	check(held_line in dagger.tooltip_text, "dagger tooltip lists the held material")
	check(label_texts(dagger).has(ItemCard.HOLDING_MARK), "dagger card shows the mark")
	for line in dagger_lines:
		check(label_texts(dagger).has(line), "dagger card shows %s" % line)

	var short_sword := cards[SHORT_SWORD]
	check(not short_sword.is_holding(), "untouched short sword holds nothing")
	check(not label_texts(short_sword).has(ItemCard.HOLDING_MARK), "short sword not marked")
	check(
		short_sword.summary() == ["Carved: nothing", "Planned: nothing"],
		"short sword card: %s" % [short_sword.summary()]
	)
	check(
		player.items[SHORT_SWORD].enchantment_graph_state == null,
		"the overview doesn't change an item it shows"
	)

	var carved := cards[CARVED]
	var carved_names := ItemCard.describe_enchantments(ItemCard.carved_enchantments(carved.item))
	check(carved_names == "Kindle, Keen", "carved sword shows Kindle and Keen: %s" % carved_names)
	check("Carved: Kindle, Keen" in carved.summary(), "carved sword card lists its carvings")
	check(ItemCard.held_for_disenchanting(carved.item) == {BLUE: 1}, "carved sword holds blue")
	check(
		"Held for disenchanting: Blue stone ×1" in carved.summary(),
		"carved sword card lists the dissolve: %s" % [carved.summary()]
	)
	check(ItemCard.held_for_carving(carved.item).is_empty(), "carved sword holds none for carving")
	check(carved.is_holding(), "carved sword is marked as holding materials")
	check("Keen: " in carved.tooltip_text, "tooltip lists each carving with its effect")
	overview.queue_free()


func test_clicking_a_card_chooses_it() -> void:
	var player := SETUP.create_player()
	var overview := open_overview(player)
	var chosen: Array[int] = []
	overview.item_chosen.connect(func(i: int) -> void: chosen.append(i))
	click(overview.cards()[SHORT_SWORD])
	check(chosen == [SHORT_SWORD], "clicking the short sword's card chooses it: %s" % [chosen])
	overview.queue_free()


func test_table_opens_the_chosen_item() -> void:
	var table: InscribingTable = TABLE.instantiate()
	add_child(table)
	table.open(SETUP.create_player(), SETUP.shown_materials())
	await get_tree().process_frame
	var overview: ItemOverview = table._overview
	check(not overview.visible, "the overview starts closed")
	key(ItemOverview.OPEN_KEY)
	check(overview.visible, "I opens the overview")
	check(overview.cards().size() == table.player.items.size(), "the table shows every item")
	key(KEY_ESCAPE)
	check(not overview.visible, "Esc closes the overview")
	table._open_overview()
	click(overview.cards()[SHORT_SWORD])
	check(not overview.visible, "choosing an item closes the overview")
	check(table.board.item == table.player.items[SHORT_SWORD], "the table opens the chosen item")
	check(table._item_picker.selected == SHORT_SWORD, "the item picker follows the choice")
	table.queue_free()


## Places Kindle somewhere it fits on `inst` and plans a material in its first node. Returns the
## material.
func plan_kindle(inst: ItemInstance, player: Player) -> EnchantmentMaterialDefinition:
	var board := InscriptionBoard.new(inst, player)
	for c in board.get_cells():
		if board.check_place(KINDLE, c, 0) == "":
			var p := board.place(KINDLE, c, 0)
			var k := InscriptionBoard.enchantment_key(p.id, 0)
			for m in player.material_inventory:
				if board.insert_material(k, m) == "":
					return m
	check(false, "Kindle and a material fit on the dagger")
	return null


func open_overview(player: Player) -> ItemOverview:
	var overview := ItemOverview.new()
	add_child(overview)
	var names: Array[String] = []
	for inst in player.items:
		names.append(str(inst.id))
	overview.open(player.items, names)
	return overview


func label_texts(card: ItemCard) -> Array[String]:
	var out: Array[String] = []
	for l in card.find_children("*", "Label", true, false):
		out.append((l as Label).text)
	return out


func click(card: ItemCard) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		card._gui_input(ev)


func key(code: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
