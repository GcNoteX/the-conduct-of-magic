class_name PlaytestBot
extends Node

## Plays one run of the real day scene, the way a player would, with no screen: it serves the
## counter, buys stones, carves at the table and starts the next day, sensibly or at random
## depending on its style. After every action it checks the game's books (money, stones, items,
## commissions) and notes anything that breaks, gets stuck or never ends. The runner adds it to
## the tree, awaits play() and reads the results.

const DAY_SCENE := preload("res://day/day.tscn")
const STYLE_NAMES: Dictionary[BotPlaytestSettings.Style, String] = {
	BotPlaytestSettings.Style.CAREFUL: "Careful",
	BotPlaytestSettings.Style.GREEDY: "Greedy",
	BotPlaytestSettings.Style.CHAOTIC: "Chaotic",
}

var settings: BotPlaytestSettings
var style: BotPlaytestSettings.Style
var run_number: int = 1
var error_log: BotErrorLog
var rng := RandomNumberGenerator.new()
var day: Day

## Problems found: {kind, summary, detail, day, context}
var issues: Array[Dictionary] = []
## Money at the end of each day, from day 1
var money_by_day: Array[int] = []
## [day, objects, nodes, resources], sampled every few days, for the leak check
var object_samples: Array = []
## Milliseconds each day took to play
var ms_by_day: Array[float] = []
## Counts by name, for the report: "seen", "accepted", "refused", "accepted_illegal",
## "refused_legal", "collected", "paid", "spent", "requested", "delivered", "no_customers",
## "carve_attempts", "carve_fails", "couldnt_afford"
var counts: Dictionary[String, int] = {}
## Name -> count, for the content tables
var enchantments_requested: Dictionary[String, int] = {}
var enchantments_carved: Dictionary[String, int] = {}
var materials_bought: Dictionary[String, int] = {}
var materials_used: Dictionary[String, int] = {}
var customers_seen: Dictionary[String, int] = {}
## "Enchantment on Item" -> [attempts, successes]
var carve_results: Dictionary[String, Array] = {}
## Failure reason -> count
var carve_failures: Dictionary[String, int] = {}
var days_played: int = 0
## Commissions and items the player holds when the run ends, collected ones included
var commissions_kept: int = 0
var items_kept: int = 0
## The enchantments the player knows, by name, in the order they're listed
var known_enchantments: Array[String] = []
var crashed: bool = false

var _carver: BotCarver
## The last day the counter has authored customers for; walk-ins start the day after
var _authored_last_day: int = 0
## What the bot is doing now, for issues it notes
var _context: String = ""
var _actions_this_side: int = 0
## Stones held anywhere (inventory and items' plans) before the action being checked
var _stones_before: Dictionary[EnchantmentMaterialDefinition, int] = {}


func play() -> void:
	rng.seed = hash([settings.random_seed, style, run_number])
	day = DAY_SCENE.instantiate()
	var counter: Counter = day.get_node("Sides/Counter")
	_carver = BotCarver.new(rng, counter.catalogue)
	_authored_last_day = 0
	for v in counter.visits:
		_authored_last_day = maxi(_authored_last_day, v.day)
	_add_walk_ins(counter, 1)
	# The dev solvability report prints pages for every carved item the bot opens
	var table: InscribingTable = day.get_node("Sides/InscribingTable")
	table.solvability_check = null
	_set_context("start", "opening the day scene")
	add_child(day)
	day.set_process(false)
	for e in day.player.known_enchantments:
		known_enchantments.append(e.enchantment_name)
	await get_tree().process_frame
	for d in settings.days:
		var started := Time.get_ticks_usec()
		_play_day()
		_check_end_of_day()
		money_by_day.append(day.player.money)
		ms_by_day.append((Time.get_ticks_usec() - started) / 1000.0)
		days_played += 1
		if d % settings.sample_every_days == 0:
			_sample_objects()
		await get_tree().process_frame
		if not day.is_day_over():
			_issue("softlock", "The day didn't end after both sides' time ran out", "")
			break
		_add_walk_ins(day.counter, day.day_number + 1)
		_set_context("day over", "start the next day")
		day.start_next_day()
	_sample_objects()
	commissions_kept = day.player.commissions.size()
	items_kept = day.player.items.size()
	day.queue_free()
	await get_tree().process_frame


func style_name() -> String:
	return STYLE_NAMES[style]


#
# ── A day ────────────────────────────────────────
#
func _play_day() -> void:
	_play_counter()
	_set_context("counter", "counter time runs out")
	var before := _snapshot()
	day.advance(day.time_left[Day.ShopSide.COUNTER] + 0.01)
	_check_unchanged(before, "the counter's time running out")
	if day.plan.inscribing_seconds > 0.0 and day.side != Day.ShopSide.INSCRIBING:
		_issue("softlock", "The table didn't open when the counter's time ran out", "")
		day.switch_to(Day.ShopSide.INSCRIBING)
	_play_table()
	_set_context("table", "table time runs out")
	before = _snapshot()
	day.advance(day.time_left[Day.ShopSide.INSCRIBING] + 0.01)
	_check_unchanged(before, "the table's time running out")


func _play_counter() -> void:
	var counter := day.counter
	_actions_this_side = 0
	if counter.current_visit() == null and counter.current_return() == null:
		_count("no_customers")
	var chaotic := style == BotPlaytestSettings.Style.CHAOTIC
	var random_left := settings.chaotic_actions_per_side if chaotic else 0
	while counter.current_visit() != null or counter.current_return() != null or random_left > 0:
		_actions_this_side += 1
		if _actions_this_side > settings.max_actions_per_side:
			_issue("softlock", "The counter never emptied", _who_is_waiting())
			return
		if chaotic or rng.randf() < settings.random_action_chance:
			random_left -= 1
			if _random_counter_action():
				return
			continue
		if counter.current_return() != null:
			_hand_back()
		else:
			_decide(_should_accept(counter.current_visit()))
	if not chaotic:
		_buy_for_tonight()


## Returns true when the bot walks away from the counter early
func _random_counter_action() -> bool:
	var counter := day.counter
	match rng.randi_range(0, 9):
		0, 1:
			if counter.current_return() != null:
				_hand_back()
			elif counter.current_visit() != null:
				_decide(rng.randf() < 0.5)
		2, 3, 4:
			var mats := counter.catalogue.materials()
			_buy(mats[rng.randi_range(0, mats.size() - 1)])
		5:
			_set_context("counter", "switch to the table and back")
			var before := _snapshot()
			day.switch_to(Day.ShopSide.INSCRIBING)
			day.switch_to(Day.ShopSide.COUNTER)
			_check_unchanged(before, "switching sides")
		6:
			return rng.randf() < 0.3
		_:
			_set_context("counter", "accept or refuse with no one waiting")
			if counter.current_visit() == null and counter.current_return() == null:
				var before := _snapshot()
				counter.accept()
				counter.refuse()
				counter.hand_back()
				_check_unchanged(before, "pressing the buttons at an empty counter")
	return false


func _should_accept(v: CustomerVisit) -> bool:
	if style == BotPlaytestSettings.Style.GREEDY:
		return true
	return day.counter.rulebook.problems(v, day.day_number).is_empty()


func _decide(accepted: bool) -> void:
	var counter := day.counter
	var v := counter.current_visit()
	var who := v.slip.customer_name
	_set_context("counter", "%s %s" % ["accept" if accepted else "refuse", who])
	var legal := counter.rulebook.problems(v, day.day_number).is_empty()
	var items_before := day.player.items.size()
	var commissions_before := day.player.commissions.size()
	var before := _snapshot()
	if accepted:
		counter.accept()
	else:
		counter.refuse()
	_check_unchanged(before, "a counter decision")
	_count("seen")
	customers_seen[who] = customers_seen.get(who, 0) + 1
	_count("accepted" if accepted else "refused")
	if accepted and not legal:
		_count("accepted_illegal")
	if not accepted and legal:
		_count("refused_legal")
	if counter.current_visit() == v:
		_issue("softlock", "A customer stayed at the counter after the decision", who)
	var gained := 1 if accepted and v.slip.item != null else 0
	if day.player.items.size() != items_before + gained:
		_issue(
			"books",
			"Deciding on a commission changed the items by the wrong amount",
			"%s: %d items before, %d after" % [who, items_before, day.player.items.size()]
		)
	if day.player.commissions.size() != commissions_before + gained:
		_issue("books", "Accepting didn't record exactly one commission", who)
	if accepted:
		for e in v.slip.enchantments:
			_count("requested")
			_bump(enchantments_requested, e.enchantment_name)


func _hand_back() -> void:
	var counter := day.counter
	var c := counter.current_return()
	var who := c.visit.slip.customer_name
	_set_context("counter", "hand %s their item back" % who)
	var expected := c.payout()
	var money_before := day.player.money
	var before := _snapshot()
	counter.hand_back()
	_check_unchanged(before, "a customer collecting (planned stones should come back)")
	if day.player.money != money_before + expected:
		_issue(
			"books",
			"A collecting customer paid a different amount from the payout shown",
			"%s: shown %dg, money went up %dg" % [who, expected, day.player.money - money_before]
		)
	if not c.collected:
		_issue("books", "A handed-back commission wasn't marked collected", who)
	if c.item in day.player.items:
		_issue("books", "A collected item stayed in the player's items", who)
	if counter.current_return() == c:
		_issue("softlock", "A collecting customer stayed at the counter", who)
	_count("collected")
	_count("paid", expected)
	_count("delivered", c.fulfilled_count())


func _buy(m: EnchantmentMaterialDefinition) -> bool:
	var counter := day.counter
	var price := counter.catalogue.price_of(m)
	_set_context("counter", "buy a %s" % InscriptionBoard.material_name(m))
	var money_before := day.player.money
	var before := _snapshot()
	var bought := counter.buy(m)
	if bought != (price <= money_before):
		_issue(
			"books",
			"Buying a stone was allowed or refused against the money held",
			(
				"%s at %dg with %dg: bought %s"
				% [m.resource_path.get_file(), price, money_before, bought]
			)
		)
	if bought:
		before[m] = before.get(m, 0) + 1
		_count("spent", price)
		_bump(materials_bought, InscriptionBoard.material_name(m))
	_check_unchanged(before, "buying a stone")
	var spent := money_before - day.player.money
	if spent != (price if bought else 0):
		_issue("books", "Buying a stone took the wrong money", "%dg taken for %dg" % [spent, price])
	return bought


## Buys the cheapest stones tonight's carving needs that the player doesn't hold
func _buy_for_tonight() -> void:
	var need: Dictionary[EnchantmentMaterialDefinition, int] = {}
	for job in _tonights_jobs():
		for node in job[1].nodes:
			var m := _carver.cheapest_for(node)
			if m:
				need[m] = need.get(m, 0) + 1
	for m in need:
		var short := need[m] - day.player.get_material_count(m)
		for i in short:
			if not _buy(m):
				_count("couldnt_afford")
				break


## The [commission, enchantment] pairs still to carve, oldest first, up to tonight's stamina
func _tonights_jobs() -> Array:
	var jobs := []
	for c in day.player.commissions:
		if c.collected or c.item not in day.player.items:
			continue
		var done := c.fulfilled()
		for i in done.size():
			if not done[i]:
				jobs.append([c, c.visit.slip.enchantments[i]])
	return jobs.slice(0, settings.enchantments_per_night)


#
# ── The table ────────────────────────────────────
#
func _play_table() -> void:
	_actions_this_side = 0
	if style == BotPlaytestSettings.Style.CHAOTIC:
		for i in settings.chaotic_actions_per_side:
			_random_table_action()
		_leave_disenchant_mode()
		return
	# A sensible player starts the night by clearing yesterday's stray plans
	for i in day.player.items.size():
		_open(i)
		_tidy_open_item()
	for job in _tonights_jobs():
		if rng.randf() < settings.random_action_chance:
			_random_table_action()
		_leave_disenchant_mode()
		_carve_job(job[0], job[1])


func _open(index: int) -> void:
	_set_context("table", "open %s" % InscriptionBoard.item_name(day.player.items[index]))
	var before := _snapshot()
	day.table._item_picker.select(index)
	day.table._on_item_picked(index)
	_check_unchanged(before, "opening an item")


## Takes every draft and the disenchant plan off the open item, handing their stones back
func _tidy_open_item() -> void:
	var board := day.table.board
	_set_context("table", "clear the plans on %s" % InscriptionBoard.item_name(board.item))
	var before := _snapshot()
	DisenchantBoard.new(board).clear_plan()
	for p in _drafts(board):
		board.remove_placement(p)
	for l in board.state.lines.duplicate():
		if not l.committed:
			board.remove_line(l)
	day.table._on_board_changed()
	_check_unchanged(before, "clearing an item's plans")


func _carve_job(c: Commission, e: Enchantment) -> void:
	var table := day.table
	var index := day.player.items.find(c.item)
	var label := "%s on %s" % [e.enchantment_name, c.item.definition.display_name]
	_open(index)
	if table.board == null or table.board.item != c.item:
		_issue("stuck", "Picking an item at the table didn't open it", label)
		return
	_tidy_open_item()
	_set_context("table", "carve %s for %s" % [label, c.visit.slip.customer_name])
	var before := _snapshot()
	_count("carve_attempts")
	var result: Array = carve_results.get(label, [0, 0])
	result[0] += 1
	var p := _carver.carve(table.board, e, settings.spots_per_attempt)
	_check_unchanged(before, "planning a carving")
	if p == null:
		_count("carve_fails")
		_bump(carve_failures, "%s: %s" % [label, _carver.last_failure])
		carve_results[label] = result
		return
	var used := _held_by(p)
	table._on_commit_pressed()
	if not p.committed:
		_issue(
			"stuck",
			"An active plan couldn't be committed",
			"%s: %s" % [label, table.board.check_commit()]
		)
		table.board.remove_placement(p)
		carve_results[label] = result
		return
	for m in used:
		before[m] -= used[m]
		_bump(materials_used, InscriptionBoard.material_name(m), used[m])
	_check_unchanged(before, "committing a carving")
	result[1] += 1
	carve_results[label] = result
	_bump(enchantments_carved, e.enchantment_name)


func _random_table_action() -> void:
	var table := day.table
	var player := day.player
	if player.items.is_empty():
		return
	if table.board == null or rng.randf() < 0.15:
		_open(rng.randi_range(0, player.items.size() - 1))
		return
	var board := table.board
	var roll := rng.randi_range(0, 11)
	if roll >= 9:
		_random_disenchant_action()
		return
	_leave_disenchant_mode()
	var before := _snapshot()
	var used: Dictionary = {}
	match roll:
		0, 1:
			var e := player.known_enchantments[rng.randi_range(
				0, player.known_enchantments.size() - 1
			)]
			_set_context("table", "plan %s somewhere at random" % e.enchantment_name)
			var spots := _carver.free_spots(board, e)
			if not spots.is_empty():
				var s: Array = spots[rng.randi_range(0, spots.size() - 1)]
				board.place(e, s[0], s[1])
		2, 3:
			var key := _random_draft_node(board)
			var mats := player.material_inventory.keys()
			if key != "" and not mats.is_empty():
				var m: EnchantmentMaterialDefinition = mats[rng.randi_range(0, mats.size() - 1)]
				_set_context("table", "put a %s in %s" % [InscriptionBoard.material_name(m), key])
				board.insert_material(key, m)
		4, 5:
			var keys := board.get_node_keys()
			var from: String = keys[rng.randi_range(0, keys.size() - 1)]
			_set_context("table", "draw a line from %s" % from)
			_carver.route_line(board, from, func(_end: String) -> bool: return rng.randf() < 0.5)
		6:
			var drafts := _drafts(board)
			if not drafts.is_empty():
				_set_context("table", "take a draft enchantment off")
				board.remove_placement(drafts[rng.randi_range(0, drafts.size() - 1)])
		7:
			var lines := board.state.lines.filter(
				func(l: LineState) -> bool: return not l.committed
			)
			if not lines.is_empty():
				_set_context("table", "rub out a draft line")
				board.remove_line(lines[rng.randi_range(0, lines.size() - 1)])
		_:
			_set_context("table", "press Commit")
			for p in board.commit_candidates():
				var held := _held_by(p)
				for m in held:
					used[m] = used.get(m, 0) + held[m]
			var ok := board.check_commit() == ""
			table._on_commit_pressed()
			if not ok:
				used.clear()
			for m in used:
				before[m] -= used[m]
				_bump(materials_used, InscriptionBoard.material_name(m), used[m])
	table._refresh_all()
	_check_unchanged(before, "a random table action")


func _random_disenchant_action() -> void:
	var table := day.table
	var before := _snapshot()
	if not table.is_disenchanting():
		_set_context("table", "switch to Disenchant")
		table._set_disenchanting(true)
		_check_unchanged(before, "switching to Disenchant")
		return
	var d := table.disenchant
	if d == null:
		_issue("stuck", "Disenchant mode is on but there's no disenchant plan", "")
		return
	match rng.randi_range(0, 5):
		0:
			var mats := day.player.material_inventory.keys()
			if not mats.is_empty():
				var m: EnchantmentMaterialDefinition = mats[rng.randi_range(0, mats.size() - 1)]
				_set_context("table", "plan dissolving a %s" % InscriptionBoard.material_name(m))
				d.plan_dissolve(m)
		1, 2:
			var edges := d.edges()
			if not edges.is_empty():
				var key: String = edges[rng.randi_range(0, edges.size() - 1)]
				_set_context("table", "plan cutting %s" % key)
				d.plan_cut(key)
		3:
			var carved := d.carvings()
			if not carved.is_empty():
				var p: PlacementState = carved[rng.randi_range(0, carved.size() - 1)]
				_set_context("table", "plan pulling out %s" % p.enchantment.enchantment_name)
				d.plan_pull_out(p)
		4:
			_set_context("table", "undo the last disenchant step")
			table._on_undo_pressed()
		_:
			_set_context("table", "commit the disenchant plan")
			var ok := d.check_commit() == ""
			var dissolved := _planned_dissolves(table.board.state)
			table._on_commit_pressed()
			if ok:
				for m in dissolved:
					before[m] -= dissolved[m]
	table._on_board_changed()
	_check_unchanged(before, "a disenchant action")


func _leave_disenchant_mode() -> void:
	if day.table.board != null and day.table.is_disenchanting():
		_set_context("table", "switch back to Carve")
		var before := _snapshot()
		day.table._set_disenchanting(false)
		_check_unchanged(before, "switching back to Carve")


func _planned_dissolves(state: GraphState) -> Dictionary:
	var out := {}
	for s in state.disenchant_plan:
		if s.kind == DisenchantStep.Kind.DISSOLVE and s.material:
			out[s.material] = out.get(s.material, 0) + 1
	return out


func _drafts(board: InscriptionBoard) -> Array[PlacementState]:
	var out: Array[PlacementState] = []
	for p in board.state.placements:
		if not p.committed:
			out.append(p)
	return out


func _random_draft_node(board: InscriptionBoard) -> String:
	var drafts := _drafts(board)
	if drafts.is_empty():
		return ""
	var p := drafts[rng.randi_range(0, drafts.size() - 1)]
	return InscriptionBoard.enchantment_key(
		p.id, rng.randi_range(0, p.enchantment.nodes.size() - 1)
	)


func _held_by(p: PlacementState) -> Dictionary:
	var out := {}
	for m in p.materials:
		if m:
			out[m] = out.get(m, 0) + 1
	return out


#
# ── Checks ───────────────────────────────────────
#
func _check_end_of_day() -> void:
	_set_context("day over", "end-of-day checks")
	var player := day.player
	if player.money < 0:
		_issue("books", "Money went below zero", "%dg" % player.money)
	for m in player.material_inventory:
		if player.material_inventory[m] <= 0:
			_issue("books", "A stone count of zero or less stayed in the inventory", str(m))
	var ids: Dictionary[StringName, bool] = {}
	for inst in player.items:
		if ids.has(inst.id):
			_issue("books", "Two items share an id", str(inst.id))
		ids[inst.id] = true
	for c in player.commissions:
		if c.collected:
			continue
		if c.item not in player.items:
			_issue(
				"books", "An uncollected commission's item is missing", c.visit.slip.customer_name
			)
		var waited := day.day_number - c.accepted_day
		if waited > settings.max_days_waiting and style != BotPlaytestSettings.Style.CHAOTIC:
			_issue(
				"softlock",
				"A customer never came back for their item",
				"%s, accepted day %d" % [c.visit.slip.customer_name, c.accepted_day]
			)
	for e in error_log.take_entries():
		e["run"] = run_number
		e["style"] = style_name()
		e["day"] = day.day_number
		_issue(e.kind, e.text, e.where, e)


func _snapshot() -> Dictionary:
	var out := {}
	var player := day.player
	for m in player.material_inventory:
		out[m] = out.get(m, 0) + player.material_inventory[m]
	for inst in player.items:
		if inst.enchantment_graph_state == null:
			continue
		var planned := inst.enchantment_graph_state.planned_materials()
		for m in planned:
			out[m] = out.get(m, 0) + planned[m]
	return out


## Every stone is still somewhere (the inventory or an item's plan), as many as before
func _check_unchanged(expected: Dictionary, what: String) -> void:
	var now := _snapshot()
	var keys := expected.keys()
	for m in now:
		if m not in keys:
			keys.append(m)
	var diffs: Array[String] = []
	for m in keys:
		var delta: int = now.get(m, 0) - expected.get(m, 0)
		if delta != 0:
			diffs.append("%+d %s" % [delta, InscriptionBoard.material_name(m)])
	if not diffs.is_empty():
		_issue(
			"lost stones",
			"Stones appeared or vanished during %s" % what,
			"%s (%s)" % [", ".join(diffs), _context]
		)


func _sample_objects() -> void:
	(
		object_samples
		. append(
			[
				days_played,
				Performance.get_monitor(Performance.OBJECT_COUNT),
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
			]
		)
	)


func _set_context(where: String, action: String) -> void:
	_context = "%s: %s" % [where, action]
	var day_number := day.day_number if day.is_node_ready() else 1
	error_log.context = "run %d (%s), day %d, %s" % [run_number, style_name(), day_number, _context]


func _issue(kind: String, summary: String, detail: String, extra: Dictionary = {}) -> void:
	var entry := {
		"kind": kind,
		"summary": summary,
		"detail": detail,
		"run": run_number,
		"style": style_name(),
		"day": day.day_number if day and day.is_node_ready() else 1,
		"context": extra.get("context", error_log.context),
	}
	if extra.has("trace"):
		entry["trace"] = extra.trace
	issues.append(entry)


func _count(what: String, amount: int = 1) -> void:
	counts[what] = counts.get(what, 0) + amount


func _bump(d: Dictionary, key: String, amount: int = 1) -> void:
	d[key] = d.get(key, 0) + amount


func _who_is_waiting() -> String:
	var c := day.counter
	if c.current_return():
		return "%s, collecting" % c.current_return().visit.slip.customer_name
	if c.current_visit():
		return c.current_visit().slip.customer_name
	return "no one"


## Adds the day's walk-ins once the authored days run out: copies of pool visits, their papers'
## dates moved by as many days as the copy is moved, so they're as legal as on their own day
func _add_walk_ins(counter: Counter, day_number: int) -> void:
	var kept: Array[CustomerVisit] = []
	for v in counter.visits:
		if v.day >= day_number:
			kept.append(v)
	counter.visits = kept
	if day_number <= _authored_last_day or settings.customer_pool.is_empty():
		return
	for i in settings.customers_per_day:
		var source := settings.customer_pool[rng.randi_range(0, settings.customer_pool.size() - 1)]
		var shift := day_number - source.day
		var v: CustomerVisit = source.duplicate()
		v.day = day_number
		if source.adventurer_id:
			v.adventurer_id = source.adventurer_id.duplicate()
			v.adventurer_id.expires_day += shift
		if source.permit:
			v.permit = source.permit.duplicate()
			v.permit.expires_day += shift
		counter.visits.append(v)
