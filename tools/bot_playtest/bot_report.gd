class_name BotReport
extends RefCounted

## What one bot playtest run saw: the problems it found, and the numbers behind them.
## Problems are things that shouldn't happen at all (an error, a day that can't end, a customer
## who never comes back, money below zero); notes are things worth a look (money running out or
## piling up, content nobody ever used).

enum Kind { ERROR, SOFTLOCK, STUCK_CUSTOMER, BROKEN_RULE }

const KIND_NAMES: Dictionary[Kind, String] = {
	Kind.ERROR: "Error",
	Kind.SOFTLOCK: "Softlock",
	Kind.STUCK_CUSTOMER: "Customer never left",
	Kind.BROKEN_RULE: "Broken rule",
}

var run_seed: int = 0
var days_planned: int = 0
var days_played: int = 0
## Chance, from 0 to 1, of the bot doing something at random instead of the sensible thing
var randomness: float = 0.0
## [{day, kind, text}]
var problems: Array[Dictionary] = []
var notes: Array[String] = []
var start_money: int = 0
## Money at the end of each day, index 0 is day 1
var money_by_day: Array[int] = []
var paid_in: int = 0
var spent_on_stones: int = 0
var accepted: int = 0
var refused: int = 0
var accepted_against_rules: int = 0
var refused_within_rules: int = 0
## Legal customers the sensible bot turned away because their job doesn't fit on their item
var refused_unfit: int = 0
var jobs_unaffordable: int = 0
## Enchantment name -> times a customer asked for it
var requested: Dictionary[String, int] = {}
## Enchantment name -> times the bot carved it
var carved: Dictionary[String, int] = {}
## "Enchantment on Item" -> times the bot couldn't fit it
var unfit: Dictionary[String, int] = {}
## Material name -> stones bought
var bought: Dictionary[String, int] = {}


func add_problem(day: int, kind: Kind, text: String) -> void:
	problems.append({"day": day, "kind": kind, "text": text})


func count(kind: Kind) -> int:
	return problems.filter(func(p): return p.kind == kind).size()


func final_money() -> int:
	return money_by_day[-1] if not money_by_day.is_empty() else start_money


static func bump(counts: Dictionary, key: String, by := 1) -> void:
	counts[key] = counts.get(key, 0) + by


func to_markdown() -> String:
	var md := "## Seed %d, %d%% random\n\n" % [run_seed, roundi(randomness * 100)]
	md += "Played %d of %d days.\n\n" % [days_played, days_planned]
	md += "### Problems\n\n"
	if problems.is_empty():
		md += "None.\n\n"
	else:
		var shown := 0
		for kind: Kind in KIND_NAMES:
			var of_kind := problems.filter(func(p): return p.kind == kind)
			if of_kind.is_empty():
				continue
			md += "- **%s** ×%d\n" % [KIND_NAMES[kind], of_kind.size()]
			for p in of_kind.slice(0, 5):
				md += "  - Day %d: %s\n" % [p.day, p.text]
				shown += 1
		md += "\n"
	md += "### Notes\n\n"
	if notes.is_empty():
		md += "None.\n\n"
	for n in notes:
		md += "- %s\n" % n
	md += "\n### Money\n\n"
	md += "| Day | Money |\n|---|---|\n| start | %dg |\n" % start_money
	for d in _sample_days():
		md += "| %d | %dg |\n" % [d, money_by_day[d - 1]]
	md += "\nPaid in %dg, spent %dg on stones.\n\n" % [paid_in, spent_on_stones]
	md += "### Counter\n\n"
	md += "Accepted %d, refused %d. " % [accepted, refused]
	md += (
		"Accepted against the rulebook %d, refused though allowed %d (%d because the job doesn't fit). "
		% [accepted_against_rules, refused_within_rules, refused_unfit]
	)
	md += "Jobs the bot couldn't afford: %d.\n\n" % jobs_unaffordable
	md += "### Enchantments\n\n| Enchantment | Asked for | Carved |\n|---|---|---|\n"
	var names := requested.keys()
	for n in carved:
		if n not in names:
			names.append(n)
	names.sort()
	for n in names:
		md += "| %s | %d | %d |\n" % [n, requested.get(n, 0), carved.get(n, 0)]
	if not unfit.is_empty():
		md += "\nCouldn't fit:\n"
		for k in unfit:
			md += "- %s ×%d\n" % [k, unfit[k]]
	md += "\n### Stones bought\n\n"
	if bought.is_empty():
		md += "None.\n"
	for k in bought:
		md += "- %s ×%d\n" % [k, bought[k]]
	return md


## Day 1, then every so often, then the last day
func _sample_days() -> Array[int]:
	var out: Array[int] = []
	var n := money_by_day.size()
	if n == 0:
		return out
	var step := maxi(1, n / 10)
	for d in range(1, n + 1, step):
		out.append(d)
	if out.back() != n:
		out.append(n)
	return out
