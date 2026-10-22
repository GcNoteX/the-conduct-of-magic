# Test report: Economy balance sim

**Date:** 2026-10-20
**Planning sheet:** None, as Gavin asked for this overnight batch
**PR:** see the PR for this branch

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `claude/project-thread-wzb8mx` | The economy sim, stacked on the shop loop (#24) | Yes |

It's a single feature, so the branch is its own combined branch. It sits on top of the shop loop branch because the sim plays that loop's money rules.

## What to test

### Economy sim
**Branch:** `claude/project-thread-wzb8mx`
**Scene to run:** `res://tools/economy_sim/run_economy_sim.tscn`

How to test:
1. Run `godot --headless --path . res://tools/economy_sim/run_economy_sim.tscn -- --out=economy_sim_report.md` (or press F6 on the scene in the editor). It takes a few minutes.
2. Read the report it prints and writes.
3. Open `res://tools/economy_sim/default_settings.tres` in the inspector, change a number (say `days` to 14 or `weekly_rents`), and run it again.

Acceptance criteria:
- [ ] The run finishes without script errors and writes a Markdown report.
- [ ] The stone cost table matches the supplier prices (Red and Blue 5g, Fire and Water 8g, Yellow 15g) and each enchantment's nodes.
- [ ] The demo customers table lists all nine visits with their real offers, and marks Bram, Oskar, Rhea and Wil as not legal, as the rulebook says.
- [ ] Changing a setting in `default_settings.tres` changes the report.
- [ ] No game prices or offers changed: the diff only adds files under `tools/economy_sim/` and this report.

## Known gaps
- Carving is a dice roll (the commit chance), not the real board. It doesn't check whether an item's map has room for every enchantment a customer asks for, or whether a stone's activation conditions can be met.
- Stamina, rent and the allowance have no numbers in the design doc yet, so the sim sweeps them. Stamina is counted as enchantments a night.
- The offer scale and undelivered penalty are sim-only what-ifs; the game still pays the way #24 does.
- A run takes a couple of minutes, so it isn't in CI.
