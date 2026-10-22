# Test report: Bot playtest

**Date:** 2026-10-22
**Planning sheet:** Not macro work (a dev tool in its own folder, no game code changed)
**PR:** see the PR for branch `claude/project-thread-ggc1tm`

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `claude/project-thread-ggc1tm` | The bot playtest, stacked on the shop loop (#24) | Yes |

It is a single feature, so there is no combined branch. It is stacked on #24 because it plays the shop loop, so it retargets to `main` once #24 merges.

## What to test

### Bot playtest
**Branch:** `claude/project-thread-ggc1tm`
**Scene to run:** `res://tools/bot_playtest/run_bot_playtest.tscn`

How to test:
1. Run `godot --headless --path . res://tools/bot_playtest/run_bot_playtest.tscn -- --out=bot_playtest_report.md`. The full run (9 runs of 200 days) takes about 4 to 5 minutes. For a quick look add `--days=20 --runs=1`.
2. Open `bot_playtest_report.md`.
3. In `tools/bot_playtest/default_settings.tres`, change `customers_per_day`, `enchantments_per_night` or `days` and run again.

Acceptance criteria:
- [ ] The run finishes, writes the report and exits with code 0. The only problems listed are the two warnings about the out-of-date demo sword.
- [ ] The report has sections for problems found, economy, content use, carving, fit on a fresh item and performance.
- [ ] "Fit on a fresh item" shows Ward with no room on the dagger and short sword, and fitting on the long sword.
- [ ] Changing the settings changes the report (for example `customers_per_day = 1` lowers the money columns).
- [ ] No game files changed: the diff only adds `tools/bot_playtest/` and this report.

## Known gaps
- The bot plays through the game's own objects (the counter's and table's methods and the inscription board's rules), not by moving the mouse, so it can't find bugs that only happen with real input, drag and drop or layout.
- Its line routing is simple (shortest route to the nearest free magic node), so a "couldn't meet" carving failure may be possible by hand.
- After the authored days (1 to 3) it brings in copies of the 9 demo customers with their papers' dates moved along; the game itself has no customers after day 3.
- It doesn't save or load, since save/load (#29) isn't on this branch.
- Not added to CI: a full run is minutes long and fails on the open findings.
