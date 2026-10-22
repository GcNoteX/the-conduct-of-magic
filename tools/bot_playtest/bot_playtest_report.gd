class_name BotPlaytestReport
extends RefCounted

## Turns the bots' runs into a Markdown report: the problems they hit, grouped and counted,
## then the economy, which content got used, how carving went, and whether the game slowed
## down or leaked objects over the long runs.

## Kinds of problem that make the run fail
const HARD_KINDS: Array[String] = ["script error", "error", "books", "softlock", "lost stones"]
## Days the economy table reports money on, when the runs are that long
const MONEY_DAYS: Array[int] = [7, 28, 100, 200]
## Days averaged at the start and end of a run for the slowdown check
const TIMING_WINDOW := 10
## Stones of each kind the fresh-item fit check holds
const FIT_CHECK_STONES := 20

var settings: BotPlaytestSettings
var bots: Array[PlaytestBot] = []
var seconds: float = 0.0


func _init(s: BotPlaytestSettings, played: Array[PlaytestBot], took_seconds: float) -> void:
	settings = s
	bots = played
	seconds = took_seconds


func has_hard_problems() -> bool:
	for bot in bots:
		for i in bot.issues:
			if i.kind in HARD_KINDS:
				return true
	return false


func build() -> String:
	var lines: Array[String] = []
	var total_days := 0
	for bot in bots:
		total_days += bot.days_played
	lines.append("# Bot playtest report")
	lines.append("")
	(
		lines
		. append(
			(
				(
					"%d runs (%d per style), %d days each, %d days in all, seed %d, %.0f s. "
					+ "After the authored days, %d walk-ins a day are drawn from %d visits. "
					+ "%d enchantments a night; Careful and Greedy take a random action %d%% of the time."
				)
				% [
					bots.size(),
					settings.runs_per_style,
					settings.days,
					total_days,
					settings.random_seed,
					seconds,
					settings.customers_per_day,
					settings.customer_pool.size(),
					settings.enchantments_per_night,
					roundi(settings.random_action_chance * 100.0),
				]
			)
		)
	)
	lines.append("")
	lines.append_array(_problems())
	lines.append_array(_economy())
	lines.append_array(_content())
	lines.append_array(_carving())
	lines.append_array(_fresh_fit())
	lines.append_array(_performance())
	return "\n".join(lines)


func _problems() -> Array[String]:
	var groups: Dictionary[String, Dictionary] = {}
	for bot in bots:
		for i in bot.issues:
			var key: String = (
				"%s|%s|%s"
				% [
					i.kind,
					i.summary,
					i.detail if i.kind.contains("error") or i.kind == "warning" else ""
				]
			)
			if not groups.has(key):
				groups[key] = {"first": i, "count": 0, "runs": {}, "styles": {}}
			groups[key].count += 1
			groups[key].runs[i.run] = true
			groups[key].styles[i.style] = true
	var out: Array[String] = ["## Problems found", ""]
	if groups.is_empty():
		out.append("None.")
		out.append("")
		return out
	var keys := groups.keys()
	keys.sort_custom(
		func(a: String, b: String) -> bool:
			var ha: bool = groups[a].first.kind in HARD_KINDS
			var hb: bool = groups[b].first.kind in HARD_KINDS
			if ha != hb:
				return ha
			return groups[a].count > groups[b].count
	)
	out.append("| Kind | Problem | Times | Runs | Styles | First seen | Example |")
	out.append("|---|---|---|---|---|---|---|")
	for key in keys:
		var g: Dictionary = groups[key]
		var f: Dictionary = g.first
		var styles: Array = g.styles.keys()
		(
			out
			. append(
				(
					"| %s | %s | %d | %d of %d | %s | run %d, day %d | %s |"
					% [
						f.kind,
						_cell(f.summary),
						g.count,
						g.runs.size(),
						bots.size(),
						", ".join(styles),
						f.run,
						f.day,
						_cell(
							"%s. While: %s" % [f.detail, f.context] if f.detail != "" else f.context
						),
					]
				)
			)
		)
	out.append("")
	for key in keys:
		var f: Dictionary = groups[key].first
		if f.has("trace") and f.trace != "":
			out.append('Trace for "%s":' % f.summary)
			out.append("```")
			out.append(f.trace.strip_edges())
			out.append("```")
			out.append("")
	return out


func _economy() -> Array[String]:
	var out: Array[String] = ["## Economy", ""]
	var header := "| Style | Runs |"
	var rule := "|---|---|"
	var shown_days: Array[int] = []
	for d in MONEY_DAYS:
		if d <= settings.days:
			shown_days.append(d)
			header += " Money day %d |" % d
			rule += "---|"
	header += _row(
		[
			"Earned a day",
			"Stones a day",
			"Delivered",
			"Accepted illegal",
			"Refused legal",
			"Days with no one",
			"Couldn't afford",
		]
	)
	rule += "---|---|---|---|---|---|---|"
	out.append(header)
	out.append(rule)
	for style in settings.styles:
		var runs := _runs_of(style)
		if runs.is_empty():
			continue
		var row := "| %s | %d |" % [runs[0].style_name(), runs.size()]
		for d in shown_days:
			var values: Array[int] = []
			for bot in runs:
				if bot.money_by_day.size() >= d:
					values.append(bot.money_by_day[d - 1])
			row += " %s |" % _spread(values)
		var days := 0
		for bot in runs:
			days += bot.days_played
		row += (
			" %dg | %dg | %s | %d | %d | %d | %d |"
			% [
				_sum(runs, "paid") / maxi(days, 1),
				_sum(runs, "spent") / maxi(days, 1),
				_share(_sum(runs, "delivered"), _sum(runs, "requested")),
				_sum(runs, "accepted_illegal"),
				_sum(runs, "refused_legal"),
				_sum(runs, "no_customers"),
				_sum(runs, "couldnt_afford"),
			]
		)
		out.append(row)
	out.append("")
	(
		out
		. append(
			(
				"Money is the median across runs, with the lowest and highest in brackets. Delivered is "
				+ "enchantments carved on collected items out of those asked for on accepted slips."
			)
		)
	)
	out.append("")
	return out


func _content() -> Array[String]:
	var out: Array[String] = ["## Content use", ""]
	var requested := _merge("enchantments_requested")
	var carved := _merge("enchantments_carved")
	out.append("| Enchantment | Asked for | Carved |")
	out.append("|---|---|---|")
	var names: Array[String] = bots[0].known_enchantments.duplicate()
	for n in requested:
		if n not in names:
			names.append(n)
	for n in names:
		out.append("| %s | %d | %d |" % [n, requested.get(n, 0), carved.get(n, 0)])
	out.append("")
	var bought := _merge("materials_bought")
	var used := _merge("materials_used")
	out.append("| Stone | Bought | Used in carvings |")
	out.append("|---|---|---|")
	var stones: Array[String] = []
	for n in bought:
		stones.append(n)
	for n in used:
		if n not in stones:
			stones.append(n)
	stones.sort()
	for n in stones:
		out.append("| %s | %d | %d |" % [n, bought.get(n, 0), used.get(n, 0)])
	out.append("")
	var seen := _merge("customers_seen")
	var who: Array = seen.keys()
	who.sort()
	var parts: Array[String] = []
	for n in who:
		parts.append("%s %d" % [n, seen[n]])
	out.append("Customers served: %s." % (", ".join(parts) if not parts.is_empty() else "none"))
	out.append("")
	return out


func _carving() -> Array[String]:
	var out: Array[String] = ["## Carving (Careful and Greedy)", ""]
	var results: Dictionary = {}
	var failures: Dictionary = {}
	for bot in bots:
		if bot.style == BotPlaytestSettings.Style.CHAOTIC:
			continue
		for label in bot.carve_results:
			var r: Array = results.get(label, [0, 0])
			r[0] += bot.carve_results[label][0]
			r[1] += bot.carve_results[label][1]
			results[label] = r
		for why in bot.carve_failures:
			failures[why] = failures.get(why, 0) + bot.carve_failures[why]
	if results.is_empty():
		out.append("No carving was attempted.")
		out.append("")
		return out
	out.append("| Enchantment on item | Attempts | Committed |")
	out.append("|---|---|---|")
	var labels := results.keys()
	labels.sort()
	for label in labels:
		var r: Array = results[label]
		out.append("| %s | %d | %s |" % [label, r[0], _share(r[1], r[0])])
	out.append("")
	if not failures.is_empty():
		out.append("Why attempts failed:")
		out.append("")
		var whys := failures.keys()
		whys.sort_custom(func(a: String, b: String) -> bool: return failures[a] > failures[b])
		for why in whys:
			out.append("- %s: %d" % [why, failures[why]])
		out.append("")
	return out


## Whether each enchantment fits a fresh item at all, with plenty of every stone: every spot
## the shape fits is tried
func _fresh_fit() -> Array[String]:
	var out: Array[String] = ["## Fit on a fresh item", ""]
	if settings.setup == null or settings.catalogue == null:
		return out
	var carver := BotCarver.new(RandomNumberGenerator.new(), settings.catalogue)
	var header := "| Enchantment |"
	var rule := "|---|"
	for item in settings.setup.items:
		header += " %s |" % item.display_name
		rule += "---|"
	out.append(header)
	out.append(rule)
	for e in settings.setup.enchantments:
		var row := "| %s |" % e.enchantment_name
		for item in settings.setup.items:
			var player := Player.new()
			for m in settings.catalogue.materials():
				player.add_material(m, FIT_CHECK_STONES)
			var inst := ItemInstance.new()
			inst.definition = item
			var board := InscriptionBoard.new(inst, player)
			var spots := carver.free_spots(board, e).size()
			var p := carver.carve(board, e, spots)
			if p != null:
				row += " fits (%d spots) |" % spots
			elif spots == 0:
				row += " **no room** |"
			else:
				row += " **can't activate** (%d spots; %s) |" % [spots, carver.last_failure]
		out.append(row)
	out.append("")
	out.append(
		(
			"Spots count every origin and rotation where the shape fits. The bot routes each "
			+ "node's lines to the nearest free magic nodes, so a \"can't activate\" may still "
			+ "be possible by hand."
		)
	)
	out.append("")
	return out


func _performance() -> Array[String]:
	var out: Array[String] = ["## Performance over long runs", ""]
	var columns: Array[String] = [
		"Run",
		"Style",
		"ms a day, first %d" % TIMING_WINDOW,
		"ms a day, last %d" % TIMING_WINDOW,
		"Objects start → end",
		"Nodes start → end",
		"Resources start → end",
		"Commissions kept",
		"Items held",
	]
	out.append("|" + _row(columns))
	out.append("|" + "---|".repeat(columns.size()))
	for bot in bots:
		if bot.object_samples.size() < 2:
			continue
		var first: Array = bot.object_samples[0]
		var last: Array = bot.object_samples[-1]
		var cells: Array[String] = [
			str(bot.run_number),
			bot.style_name(),
			"%.1f" % _mean(bot.ms_by_day.slice(0, TIMING_WINDOW)),
			"%.1f" % _mean(bot.ms_by_day.slice(-TIMING_WINDOW)),
			"%d → %d" % [first[1], last[1]],
			"%d → %d" % [first[2], last[2]],
			"%d → %d" % [first[3], last[3]],
			str(bot.commissions_kept),
			str(bot.items_kept),
		]
		out.append("|" + _row(cells))
	out.append("")
	out.append(
		(
			"Objects are sampled every %d days. A count that climbs run after run is a leak."
			% settings.sample_every_days
		)
	)
	out.append("")
	return out


func _runs_of(style: BotPlaytestSettings.Style) -> Array[PlaytestBot]:
	var out: Array[PlaytestBot] = []
	for bot in bots:
		if bot.style == style:
			out.append(bot)
	return out


func _merge(field: String) -> Dictionary:
	var out := {}
	for bot in bots:
		var d: Dictionary = bot.get(field)
		for k in d:
			out[k] = out.get(k, 0) + d[k]
	return out


func _sum(runs: Array[PlaytestBot], what: String) -> int:
	var total := 0
	for bot in runs:
		total += bot.counts.get(what, 0)
	return total


func _spread(values: Array[int]) -> String:
	if values.is_empty():
		return "-"
	var sorted := values.duplicate()
	sorted.sort()
	return "%dg (%d–%d)" % [sorted[sorted.size() / 2], sorted[0], sorted[-1]]


func _share(part: int, whole: int) -> String:
	if whole == 0:
		return "-"
	return "%d%%" % roundi(100.0 * part / whole)


func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


## Cells as a Markdown row's tail: " a | b |"
func _row(cells: Array[String]) -> String:
	return " %s |" % " | ".join(cells)


func _cell(text: String) -> String:
	return text.replace("|", "\\|").replace("\n", " ")
