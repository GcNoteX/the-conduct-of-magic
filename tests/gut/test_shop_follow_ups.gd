extends GutTest

## The table's rush-order supplier, the commission card and the Day starting without demo items,
## which live on the test bench instead.

const CATALOGUE := preload("res://counter/supplier/demo_catalogue.tres")
const DAY_SCENE := preload("res://day/day.tscn")
const BENCH_SCENE := preload("res://test_bench/test_bench.tscn")
const BENCH_SETUP := preload("res://inscribing/demo/demo_setup.tres")
const GLOW := preload("res://enchantments/patterns/glow.tres")
const WARD := preload("res://enchantments/patterns/ward.tres")
const KEEN := preload("res://enchantments/patterns/keen.tres")
const RED := preload("res://items/enchantment_materials/red_stone/red_stone.tres")
const FIRE := preload("res://items/enchantment_materials/fire_stone/fire_stone.tres")
const YELLOW := preload("res://items/enchantment_materials/yellow_stone/yellow_stone.tres")


func _placement(e: Enchantment, committed: bool) -> PlacementState:
	var p := PlacementState.new()
	p.enchantment = e
	p.materials.resize(e.nodes.size())
	p.committed = committed
	return p


func test_markup_rounds_up() -> void:
	assert_eq(CATALOGUE.price_of(RED), 5, "the counter sells Red stone at 5g")
	assert_eq(CATALOGUE.price_of(RED, 1.5), 8, "7.5g rounds up to 8g")
	assert_eq(CATALOGUE.price_of(FIRE, 1.5), 12, "8g becomes 12g")
	assert_eq(CATALOGUE.price_of(YELLOW, 1.5), 23, "15g becomes 23g")


func test_commission_progress() -> void:
	var visit := CustomerVisit.new()
	visit.slip = CommissionSlip.new()
	visit.slip.enchantments = [GLOW, WARD, KEEN]
	visit.slip.payment = 90
	var inst := ItemInstance.new()
	inst.enchantment_graph_state = GraphState.new()
	inst.enchantment_graph_state.placements = [_placement(GLOW, true), _placement(WARD, false)]
	var c := Commission.create(visit, inst, 1)
	var expected: Array[Commission.Progress] = [
		Commission.Progress.DONE, Commission.Progress.PLANNED, Commission.Progress.MISSING
	]
	assert_eq(c.progress(), expected, "committed, planned, not started")
	assert_eq(c.payout(), 30, "only the committed Glow counts towards pay")


func test_day_starts_without_demo_items() -> void:
	var day: Day = DAY_SCENE.instantiate()
	add_child_autofree(day)
	assert_eq(day.player.items.size(), 0, "no items until a customer leaves one")
	assert_eq(day.player.money, 50, "the day starts with 50g")
	day.switch_to(Day.ShopSide.INSCRIBING)
	assert_string_contains(day.table._item_label.text, "No items yet")
	assert_false(day.table._commission_card.visible, "no card without a customer's item")


func test_table_card_and_rush_order() -> void:
	var day: Day = DAY_SCENE.instantiate()
	add_child_autofree(day)
	day.counter.accept()
	day.end_side()
	var c := day.player.commissions[0]
	assert_eq(day.table.board.item, c.item, "the table opens the customer's item")
	assert_true(day.table._commission_card.visible, "the card shows for a customer's item")
	var card_text: String = day.table._commission_card._text.text
	assert_string_contains(card_text, c.visit.slip.customer_name)
	assert_true(day.table._supplier_button.visible, "the table has a Supplier button")
	day.table.open_supplier()
	assert_true(day.table._supplier_popup.visible, "the supplier opens over the table")
	var money := day.player.money
	var count := day.player.get_material_count(FIRE)
	assert_true(day.table.buy(FIRE), "a Fire stone is affordable")
	assert_eq(day.player.money, money - 12, "the table charges 12g, half as much again")
	assert_eq(day.player.get_material_count(FIRE), count + 1, "the stone joins the materials")
	day.player.money = 11
	assert_false(day.table.buy(FIRE), "11g can't buy a 12g stone")
	assert_eq(day.player.money, 11, "a failed purchase costs nothing")
	day.table.close_supplier()
	assert_false(day.table._supplier_popup.visible)


func test_bench_has_the_demo_items() -> void:
	var bench: TestBench = BENCH_SCENE.instantiate()
	add_child_autofree(bench)
	var expected := BENCH_SETUP.items.size() + BENCH_SETUP.carved_items.size()
	assert_eq(bench.table.player.items.size(), expected, "blank weapons and the carved sword")
	assert_not_null(bench.table.board, "the bench opens the first item")
