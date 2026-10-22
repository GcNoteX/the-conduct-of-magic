extends Node

## Runs the economy balance sim over every scenario in the settings and prints a Markdown report.
## Run: godot --headless --path . res://tools/economy_sim/run_economy_sim.tscn -- --out=<path>
## Without --out the report goes to user://economy_sim_report.md. It is also printed.

const DEFAULT_OUT := "user://economy_sim_report.md"

@export var settings: EconomySimSettings = preload("res://tools/economy_sim/default_settings.tres")


func _ready() -> void:
	var report := build_report()
	print(report)
	var out := DEFAULT_OUT
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		printerr("Couldn't write the report to ", out)
		get_tree().quit(1)
		return
	file.store_string(report)
	file.close()
	print("Report written to ", ProjectSettings.globalize_path(out))
	get_tree().quit(0)


func build_report() -> String:
	var lines: Array[String] = []
	lines.append("# Economy sim report")
	lines.append("")
	(
		lines
		. append(
			(
				(
					"%d runs per scenario, %d days each, %d customers a day drawn from %d demo visits, "
					+ "%d%% of attempted enchantments committed. Rent is paid every %d days."
				)
				% [
					settings.runs_per_scenario,
					settings.days,
					settings.customers_per_day,
					settings.customers.size(),
					roundi(settings.commit_chance * 100.0),
					settings.days_per_week,
				]
			)
		)
	)
	lines.append("")
	lines.append_array(_enchantment_table())
	lines.append_array(_customer_table())
	for policy: EconomySim.Policy in EconomySim.POLICY_NAMES:
		lines.append_array(_policy_tables(policy))
	lines.append_array(_sensitivity_table())
	lines.append_array(_what_if_table())
	return "\n".join(lines)


func _enchantment_table() -> Array[String]:
	var sim := EconomySim.new(settings, EconomySim.Policy.ACCEPT_ALL_LEGAL, 1, 0)
	var empty: Dictionary[EnchantmentMaterialDefinition, int] = {}
	var out: Array[String] = ["## Stone cost of each enchantment", ""]
	out.append("| Enchantment | Nodes | Cheapest stones | Cost |")
	out.append("|---|---|---|---|")
	for e in settings.setup.enchantments:
		var names: Array[String] = []
		for node in e.nodes:
			var m := sim.stone_for(node, empty)
			names.append(m.resource_path.get_file().get_basename() if m != null else "none sold")
		out.append(
			(
				"| %s | %d | %s | %dg |"
				% [e.enchantment_name, e.nodes.size(), ", ".join(names), sim.stone_cost(e)]
			)
		)
	out.append("")
	return out


func _customer_table() -> Array[String]:
	var sim := EconomySim.new(settings, EconomySim.Policy.ACCEPT_ALL_LEGAL, 1, 0)
	var out: Array[String] = ["## Demo customers", ""]
	out.append("| Customer | Wants | Offer | Stones | Margin | Per enchantment | Legal |")
	out.append("|---|---|---|---|---|---|---|")
	for v in settings.customers:
		var cost := 0
		for e in v.slip.enchantments:
			cost += sim.stone_cost(e)
		var count := v.slip.enchantments.size()
		(
			out
			. append(
				(
					"| %s | %s | %dg | %dg | %dg | %dg | %s |"
					% [
						v.slip.customer_name,
						v.slip.enchantment_names(),
						v.slip.payment,
						cost,
						v.slip.payment - cost,
						(v.slip.payment - cost) / maxi(count, 1),
						"yes" if sim.is_legal(v) else "no",
					]
				)
			)
		)
	out.append("")
	return out


func _policy_tables(policy: EconomySim.Policy) -> Array[String]:
	var out: Array[String] = ["## %s" % EconomySim.POLICY_NAMES[policy], ""]
	var weeks := float(settings.days) / settings.days_per_week
	out.append("Without rent:")
	out.append("")
	out.append(
		(
			(
				"| Enchantments a night | Earned a week | Stones a week | Stones share | Delivered "
				+ "| Stamina used | Money day %d | Money day %d | Money day %d (worst 10%%) "
				+ "| Couldn't afford stones | Refused legal a day |"
			)
			% [settings.days_per_week, settings.days, settings.days]
		)
	)
	out.append("|---|---|---|---|---|---|---|---|---|---|---|")
	for s in settings.enchantments_per_night:
		var runs := _play_all(policy, s, 0)
		var paid := _mean(runs, func(r: EconomySim.Run) -> float: return r.paid_in)
		var stones := _mean(runs, func(r: EconomySim.Run) -> float: return r.spent_on_stones)
		var finals := _values(runs, func(r: EconomySim.Run) -> float: return r.final_money())
		var first_week := _mean(
			runs,
			func(r: EconomySim.Run) -> float: return r.money_by_day[settings.days_per_week - 1]
		)
		out.append(
			(
				"| %d | %dg | %dg | %d%% | %d%% | %d%% | %dg | %dg | %dg | %.1f | %.1f |"
				% [
					s,
					roundi(paid / weeks),
					roundi(stones / weeks),
					roundi(100.0 * stones / maxf(paid, 1.0)),
					roundi(_ratio(runs, "enchantments_delivered", "enchantments_requested")),
					roundi(_ratio(runs, "stamina_used", "stamina_available")),
					roundi(first_week),
					roundi(_mean_of(finals)),
					roundi(_percentile(finals, 0.1)),
					_mean(runs, func(r: EconomySim.Run) -> float: return r.unaffordable_jobs),
					(
						_mean(
							runs, func(r: EconomySim.Run) -> float: return r.customers_refused_legal
						)
						/ settings.days
					),
				]
			)
		)
	out.append("")
	out.append("Share of runs that hit the running out of money ending, by weekly rent:")
	out.append("")
	var header := "| Enchantments a night |"
	var rule := "|---|"
	for rent in settings.weekly_rents:
		header += " %dg |" % rent
		rule += "---|"
	out.append(header)
	out.append(rule)
	for s in settings.enchantments_per_night:
		var row := "| %d |" % s
		for rent in settings.weekly_rents:
			var runs := _play_all(policy, s, rent)
			var ruined := runs.filter(func(r: EconomySim.Run) -> bool: return r.ruined_on_day > 0)
			row += " %d%% |" % roundi(100.0 * ruined.size() / runs.size())
		out.append(row)
	out.append("")
	return out


## Weekly earnings after stones, without rent, as customers a day and the commit chance change
func _sensitivity_table() -> Array[String]:
	var out: Array[String] = [
		(
			"## Sensitivity: %d enchantments a night, accepting every legal customer"
			% settings.sensitivity_stamina
		),
		"",
		"Earned a week after stones, without rent, by customers a day and commit chance:",
		"",
	]
	var header := "| Customers a day |"
	var rule := "|---|"
	for chance in settings.sensitivity_commit_chances:
		header += " %d%% |" % roundi(chance * 100.0)
		rule += "---|"
	out.append(header)
	out.append(rule)
	var weeks := float(settings.days) / settings.days_per_week
	for per_day in settings.sensitivity_customers_per_day:
		var row := "| %d |" % per_day
		for chance in settings.sensitivity_commit_chances:
			var varied: EconomySimSettings = settings.duplicate()
			varied.customers_per_day = per_day
			varied.commit_chance = chance
			var sim := EconomySim.new(
				varied, EconomySim.Policy.ACCEPT_ALL_LEGAL, settings.sensitivity_stamina, 0
			)
			var net := 0.0
			for i in settings.runs_per_scenario:
				var r := sim.play(settings.random_seed + i)
				net += r.paid_in - r.spent_on_stones
			row += " %dg |" % roundi(net / settings.runs_per_scenario / weeks)
		out.append(row)
	out.append("")
	return out


## How scaling offers down and charging for undone enchantments change both policies
func _what_if_table() -> Array[String]:
	var out: Array[String] = [
		"## What if: %d enchantments a night" % settings.sensitivity_stamina,
		"",
		(
			(
				"Earned a week after stones and penalties, without rent, then the share of runs ruined "
				+ "by a %dg weekly rent. The penalty is what a customer takes back for each undone "
				+ "enchantment, as a share of its part of the offer."
			)
			% settings.what_if_rent
		),
		"",
		"| Offer scale | Penalty | Accept all legal | Ruined | Accept what fits | Ruined |",
		"|---|---|---|---|---|---|",
	]
	var weeks := float(settings.days) / settings.days_per_week
	for scale in settings.what_if_offer_scales:
		for penalty in settings.what_if_penalties:
			var varied: EconomySimSettings = settings.duplicate()
			varied.offer_scale = scale
			varied.undelivered_penalty = penalty
			var row := "| %.2f | %d%% |" % [scale, roundi(penalty * 100.0)]
			for policy: EconomySim.Policy in EconomySim.POLICY_NAMES:
				var free := EconomySim.new(varied, policy, settings.sensitivity_stamina, 0)
				var rented := EconomySim.new(
					varied, policy, settings.sensitivity_stamina, settings.what_if_rent
				)
				var net := 0.0
				var ruined := 0
				for i in settings.runs_per_scenario:
					var r := free.play(settings.random_seed + i)
					net += r.paid_in - r.spent_on_stones - r.penalties
					if rented.play(settings.random_seed + i).ruined_on_day > 0:
						ruined += 1
				row += (
					" %dg | %d%% |"
					% [
						roundi(net / settings.runs_per_scenario / weeks),
						roundi(100.0 * ruined / settings.runs_per_scenario),
					]
				)
			out.append(row)
	out.append("")
	return out


func _play_all(policy: EconomySim.Policy, stamina: int, rent: int) -> Array[EconomySim.Run]:
	var sim := EconomySim.new(settings, policy, stamina, rent)
	var runs: Array[EconomySim.Run] = []
	for i in settings.runs_per_scenario:
		runs.append(sim.play(settings.random_seed + i))
	return runs


func _values(runs: Array[EconomySim.Run], pick: Callable) -> Array[float]:
	var out: Array[float] = []
	for r in runs:
		out.append(pick.call(r))
	return out


func _mean(runs: Array[EconomySim.Run], pick: Callable) -> float:
	return _mean_of(_values(runs, pick))


func _mean_of(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


func _percentile(values: Array[float], at: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[clampi(int(at * sorted.size()), 0, sorted.size() - 1)]


## Total of one field over total of another, as a percentage
func _ratio(runs: Array[EconomySim.Run], top: StringName, bottom: StringName) -> float:
	var t := 0.0
	var b := 0.0
	for r in runs:
		t += r.get(top)
		b += r.get(bottom)
	return 100.0 * t / maxf(b, 1.0)
