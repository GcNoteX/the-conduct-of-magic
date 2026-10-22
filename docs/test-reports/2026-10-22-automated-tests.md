# Test report: Automated tests, CI and a bot playtest

**Date:** 2026-10-22
**Planning sheet:** None, as Gavin asked for this overnight batch without sheets
**PR:** the GUT framework PR (`gut-tests`), and the combined PR (`automated-tests`)

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `automated-tests` | Everything below, on top of the save/load PR (#29), which contains the shop loop (#24) and Day and counter (#20) | Yes |
| `gut-tests` | GUT, the CI step, AutoCarver, the solvability and disenchanting tests. Branches from `main` | Only to check it alone before merging it |
| `shop-loop-tests` | Shop loop, economy and customer job tests, on `gut-tests` + #24 | No |
| `save-load-tests` | Save round-trip tests, on `shop-loop-tests` + #29 | No |
| `bot-playtest` | The bot playtest, on `shop-loop-tests` | No |

`gut-tests` has its own PR because it only needs `main`, so it can merge now. Everything else tests code that is still in open PRs (#20, #24, #29), so it goes in the combined PR, which should merge after those.

## What to test

### GUT and the CI step
**Branch:** `automated-tests` (or `gut-tests`)
**Scene to run:** none, it's a command

How to test:
1. Run `godot --headless --path . -s addons/gut/gut_cmdln.gd`.
2. In the editor, open the GUT panel at the bottom (the plugin is on in Project Settings → Plugins) and press Run All.
3. Look at the PR's checks: the "Godot script check" job now has a "Run GUT tests" step.
4. Optional: break a rule on purpose, for example delete the `board.inventory.add_material(s.material)` line in `DisenchantBoard.undo_last()`, and run step 1 again.

Acceptance criteria:
- [ ] Step 1 ends with "All tests passed" (3 pending, see Known gaps) and exits 0 in about 10 seconds.
- [ ] The GUT panel runs the same tests.
- [ ] The CI step is green on the PR.
- [ ] With the rule broken, step 1 reports failing tests and exits 1.

### Solvability (`tests/gut/test_solvability.gd`, `tests/gut/test_customer_jobs.gd`)
How to test: read the test names and messages in the GUT output.

Acceptance criteria:
- [ ] Every starter enchantment has a valid shape, takes a starter material in every node, and carves on at least one starter item (the output lists which).
- [ ] Every board that makes can be disenchanted with the starter stock.
- [ ] Each demo customer's whole job carves on the item they bring, except the three known ones, which show as pending with the reason.
- [ ] Each enchantment on a finished job can be taken off again with the starter stock.

### Disenchanting (`tests/gut/test_disenchanting.gd`)
Acceptance criteria:
- [ ] A plan with no runes to pay for its cuts can't be committed, and the carving stays.
- [ ] Dissolving needs the stone in stock.
- [ ] Cancelling a plan, undoing it step by step, or cancelling after leaving the item and coming back all give every stone back.
- [ ] A paid plan commits, frees the cells and uses up only the dissolved stones.

### Shop loop and economy (`tests/gut/test_shop_loop.gd`, `tests/gut/test_economy.gd`)
Acceptance criteria:
- [ ] Accepting brings the customer's item in; refusing brings nothing in.
- [ ] A job carved on the board with stones bought at the supplier pays exactly the agreed price when collected; a half-done job pays a share, an uncarved one nothing.
- [ ] Three demo days of accepting, carving and collecting end with money equal to the start, less stones, plus pay.
- [ ] Every demo job, and each enchantment's share of it, pays more than its stones; spending past zero is refused; 300 random purchases never sell on credit.

### Save and load (`tests/gut/test_save_round_trip.gd`)
Acceptance criteria:
- [ ] A busy day-2 save (carved commissions, a collection, a draft carving holding a stone, a planned disenchant) loads back with money, stock, items, carvings, lines, plans, commissions, the counter's calls and queue and the clock all identical.
- [ ] Saving the loaded run again changes nothing, and the loaded run plays the next day exactly like the original.

### Bot playtest
**Scene to run:** `res://tools/bot_playtest/run_bot_playtest.tscn`

How to test:
1. Run `godot --headless --path . res://tools/bot_playtest/run_bot_playtest.tscn -- --days=300 --seeds=1,2,3 --random=0,0.3,1 --out=bot_report.md` (about 90 seconds), or F6 on the scene for the default 200 days.
2. Read `bot_report.md`. A copy of tonight's run is in the project files at `testing/bot-playtest/2026-10-22-bot-report.md`.

Acceptance criteria:
- [ ] Every run plays all its days and lists no problems; the command exits 0.
- [ ] Each run's report has a money table, counter numbers, enchantments asked for and carved, and stones bought.
- [ ] The notes match what you'd expect from the demo: money piles up, nobody asks for Bastion, and Ward never fits on the Dagger or Short sword.

## What the tests found

- **Ward doesn't fit on the Dagger or the Short sword**, anywhere or in any rotation, so Elsa's, Tomas's and Jory's commissions can't be finished. They're listed in `KNOWN_UNFIT` in `test_customer_jobs.gd`; a fix to Ward's shape or to those customers' items will make the test say to take them off the list.
- **The carved demo sword is out of date**: Kindle now has 3 nodes, the saved carving has 2, so loading it prints "Kindle changed shape" and drops a line.
- **Money piles up**: over 300 days the sensible bot ends with about 20,000g (400× the start) and keeps gaining 60–75g a day, since nothing costs money except stones yet. Even a fully random bot ends near 12,000g.
- **No customer asks for Bastion.**
- A player who carves Kindle with all three starter Fire stones can't disenchant it with the stones left. Not a bug by the design doc's rule, which is about layouts, but worth knowing when the in-game solvability guarantee gets its numbers.

## Known gaps
- AutoCarver is greedy: it places each enchantment at the first spot it fits and draws shortest lines. A job it can't carve might still be carvable by hand; Ward on the Dagger is a real "no" because no placement fits at all.
- The bot's customers after day 3 are copies of the nine demo customers.
- The 3 pending tests are the known unfit jobs above, not skipped work.
- The existing hand-written test scenes (`tests/test_*.tscn`) still run in CI as before; nothing was moved to GUT.
