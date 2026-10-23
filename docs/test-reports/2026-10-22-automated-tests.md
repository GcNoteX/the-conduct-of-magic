# Test report: Save and load tests

**Date:** 2026-10-22 (trimmed 2026-10-23)
**Planning sheet:** None, as Gavin asked for this overnight batch without sheets
**PR:** #35

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `automated-tests` | The save round-trip tests, on top of the save/load PR (#29) and the day, counter, shop and economy tests (#43) | Yes |

The rest of this batch has already moved out: GUT and the solvability and disenchanting tests merged as #34, and the shop loop, economy and customer job tests are in #43, which needs only `main`. What's left here tests save/load code that is still in #29, so merge this after #29 and #43. Its diff shrinks to one test file as they land.

The bot playtest is not in this batch. A separate thread built a fuller one in #33.

## What to test

### Save and load (`tests/gut/test_save_round_trip.gd`)
**Branch:** `automated-tests`
**Scene to run:** none, it's a command

How to test:
1. Run `godot --headless --path . -s addons/gut/gut_cmdln.gd`, or press Run All in the GUT panel.
2. Look at the PR's checks.

Acceptance criteria:
- [ ] All tests pass, with 3 pending (the known Ward jobs from #43).
- [ ] A busy day-2 save (carved commissions, a collection, a draft carving holding a stone, a planned disenchant) loads back with money, stock, items, carvings, lines, plans, commissions, the counter's calls and queue and the clock all identical.
- [ ] Saving the loaded run again changes nothing, and the loaded run plays the next day exactly like the original.
- [ ] Stones held in plans stay in those plans after loading, and none come back into the stock.
- [ ] The CI checks are green on the PR.

## Known gaps
- The carved demo sword is out of date (Kindle has 3 nodes, the saved carving has 2), so loading it prints "Kindle changed shape". It's a warning, not a failure.
