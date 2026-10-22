extends Node

## Runs the bot playtest: one bot per run, each playing the real day scene for many days, then
## writes a Markdown report of what went wrong and how the economy and content held up.
## Run: godot --headless --path . res://tools/bot_playtest/run_bot_playtest.tscn -- --out=<path>
## Optional: --days=<n> --runs=<n per style> --seed=<n>. Without --out the report goes to
## user://bot_playtest_report.md. Exits with 1 when the bots found errors, broken books or
## softlocks.

const DEFAULT_OUT := "user://bot_playtest_report.md"
const DEFAULT_SETTINGS := preload("res://tools/bot_playtest/default_settings.tres")

@export var settings: BotPlaytestSettings = DEFAULT_SETTINGS

var _error_log := BotErrorLog.new()


func _ready() -> void:
	var out := DEFAULT_OUT
	var s: BotPlaytestSettings = settings.duplicate()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--days="):
			s.days = arg.trim_prefix("--days=").to_int()
		elif arg.begins_with("--runs="):
			s.runs_per_style = arg.trim_prefix("--runs=").to_int()
		elif arg.begins_with("--seed="):
			s.random_seed = arg.trim_prefix("--seed=").to_int()
	OS.add_logger(_error_log)
	var started := Time.get_ticks_msec()
	var bots: Array[PlaytestBot] = []
	var run_number := 0
	for style in s.styles:
		for i in s.runs_per_style:
			run_number += 1
			var bot := PlaytestBot.new()
			bot.settings = s
			bot.style = style
			bot.run_number = run_number
			bot.error_log = _error_log
			add_child(bot)
			print("Run %d (%s)..." % [run_number, bot.style_name()])
			await bot.play()
			print("  %d days, %d problems noted" % [bot.days_played, bot.issues.size()])
			bots.append(bot)
	OS.remove_logger(_error_log)
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	var report := BotPlaytestReport.new(s, bots, seconds)
	var text := report.build()
	print(text)
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		printerr("Couldn't write the report to ", out)
		get_tree().quit(1)
		return
	file.store_string(text)
	file.close()
	print("Report written to ", ProjectSettings.globalize_path(out))
	get_tree().quit(1 if report.has_hard_problems() else 0)
