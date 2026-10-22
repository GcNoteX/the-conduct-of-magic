extends GutTest

## A short bot playtest on every PR: two months of play, one sensible and one half random,
## must finish without errors, softlocks, customers who never leave or broken money rules.
## The long run is tools/bot_playtest/run_bot_playtest.tscn.

const DAYS := 60


func _play(run_seed: int, randomness: float) -> BotReport:
	var report: BotReport = await BotPlayer.new(run_seed, randomness).play(self, DAYS)
	gut.p(report.to_markdown())
	return report


func _assert_clean(report: BotReport) -> void:
	assert_eq(report.days_played, DAYS, "every day was played")
	for p in report.problems:
		fail_test("Day %d: %s: %s" % [p.day, BotReport.KIND_NAMES[p.kind], p.text])
	for money in report.money_by_day:
		assert_true(money >= 0, "money never ends a day below zero")


func test_a_sensible_bot_plays_two_months_cleanly() -> void:
	var report: BotReport = await _play(1, 0.0)
	_assert_clean(report)
	assert_eq(report.accepted_against_rules, 0, "the sensible bot follows the rulebook")
	assert_eq(report.jobs_unaffordable, 0, "and only takes jobs it can pay for")
	assert_gt(report.paid_in, 0, "customers paid")


func test_a_half_random_bot_plays_two_months_cleanly() -> void:
	_assert_clean(await _play(7, 0.5))
