extends Node

## Dev tool scene script: runs the bot playtest and prints its report, also writing it to a file
## when asked. Exits with code 1 if any run found a problem.
## Run: godot --headless --path . res://tools/bot_playtest/run_bot_playtest.tscn
##   [-- --days=200 --seeds=1,2,3 --random=0,0.3 --out=bot_report.md]
## Each seed is played once at each randomness, from 0 (always sensible) to 1 (always random).

const DEFAULT_DAYS := 200
const DEFAULT_SEEDS: Array[int] = [1, 2, 3]
const DEFAULT_RANDOMNESS: Array[float] = [0.0, 0.3]


func _ready() -> void:
	var days := DEFAULT_DAYS
	var seeds := DEFAULT_SEEDS.duplicate()
	var randomness := DEFAULT_RANDOMNESS.duplicate()
	var out := ""
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		if parts.size() < 2:
			continue
		match parts[0]:
			"days":
				days = parts[1].to_int()
			"seeds":
				seeds.assign(Array(parts[1].split(",")).map(func(t): return t.to_int()))
			"random":
				randomness.assign(Array(parts[1].split(",")).map(func(t): return t.to_float()))
			"out":
				out = parts[1]
	var md := "# Bot playtest\n\n%d days per run.\n\n" % days
	var problems := 0
	for r in randomness:
		for s in seeds:
			var started := Time.get_ticks_msec()
			var report: BotReport = await BotPlayer.new(s, r).play(self, days)
			problems += report.problems.size()
			md += report.to_markdown()
			md += "\n_Took %.1fs._\n\n" % ((Time.get_ticks_msec() - started) / 1000.0)
	print(md)
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		if f:
			f.store_string(md)
			f.close()
		else:
			printerr("Couldn't write ", out)
	get_tree().quit(1 if problems > 0 else 0)
