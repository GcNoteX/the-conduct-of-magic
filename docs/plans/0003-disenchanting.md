# 0003: Disenchanting prototype

2026-10-17 · Gavin

**Status:** Approved by Gavin on 2026-10-17 ("yes to everything" on the decisions below).

**Design doc:** §7.6 Existing enchantments and disenchanting, Appendix A.5 Ways to guarantee solvability

**PRs:** three (`disenchanting-rules`, `disenchanting-table`, `solvability-checker`)

## Goal

On an item that already has carvings, you can plan which lines to cut and which materials to dissolve, watch your runes go up and down with each step, and commit to remove an enchantment.

## What §7.6 already settles

The build follows these as written; none are reopened here.

- Disenchanting means cutting every one of an enchantment's lines, then pulling it out. It uses plan, then commit.
- You start with 0 runes. There are 4 rune types. Runes don't carry over between sessions or items.
- Dissolving a material gives runes. It's planned too, and nothing is used up until you commit.
- An edge costs the runes of both nodes it touches, added together. A material puts the same cost on every edge it touches, and each magic node has its own fixed set.
- Cutting a line costs the runes it displays. What anything gives back is deterministic.
- When a node is freed, it gives runes back. An enchantment node gives what its material sets, and a magic node gives a fixed set chosen with the node arrangement.
- Who drew a line doesn't matter, and no par is shown.
- ~~If a planned material gets used somewhere else, the commit turns red.~~ Replaced by Gavin's decision below: planned materials stay with the item.
- Every disenchant board must be solvable.

## Gavin's decisions (2026-10-17)

- **Rune names:** water, fire, wind and stone, for now.
- **No inverses:** a material's runes are its own kind. A Fire stone puts fire runes on its edges, 1 per edge for now, and gives fire runes back when its node is freed. The same goes for every material, to encourage using different materials.
- **Dissolving:** each material has its own dissolve result, 1 or more runes of 1 or more types, and you get all of it.
- **Planned materials stay with the item.** Putting a material into a plan, for carving or disenchanting, takes it out of your inventory and holds it in that item. Taking it out of the plan gives it back. So commits never clash across items. A later feature will let you browse your items and see what each plan holds.
- **The lines to cut** are the enchantment's whole chain: its own lines, its lines to magic nodes, and magic-to-magic lines in that chain.
- **A node pays out once,** when its last line is cut, so cutting order decides when you get the runes.
- **No order rule** beyond being able to afford a cut.
- **No partial commits:** every enchantment in a plan must be fully cut and pulled out.
- **A pre-carved demo sword** to practise on, plus a Disenchant mode for any item you carved.
- **Solvability** is checked with a dev tool for now; the in-game guarantee waits for real numbers.
- **Pulled-out cells are free again,** as if the enchantment was never there.

Rune numbers for the demo stones and the sword's magic nodes are placeholders, listed in the PR for you to tune.

## Approach

Disenchanting gets its own rules class, built like the inscription board: plain logic you can test headless, reading the item's committed carvings. A plan is an ordered list of steps (cut this line, dissolve that material, pull out that enchantment). The rules replay the steps to show your runes after each one and to stop at the first step you can't afford. The table gains a Disenchant mode. In it, each line shows its rune cost, your runes sit in a bar at the top, and the plan is a list you can undo from the end. The checker is a small search over cut and dissolve orders, which is cheap because boards hold tens of lines.

| Kind | Name | New / changed | Purpose |
| --- | --- | --- | --- |
| Resource | `RuneSet` | New | Counts of each of the 4 rune types, with add, subtract and "can afford" |
| Resource | `EnchantmentMaterialDefinition` | Changed | Adds `edge_runes`, `harvest_runes` and `dissolve_runes` |
| Resource | `HexMapDefinition` | Changed | Adds each magic node's edge runes and harvest runes |
| Resource | `DisenchantStep` | New | One planned step: cut, dissolve or pull out |
| Class | `DisenchantBoard` | New | The rules: costs, replaying a plan, freeing nodes, commit |
| Class | `BoardView`, `InscribingTable` | Changed | Disenchant mode: rune costs on lines, rune bar, plan list |
| Scene | `tools/solvability_checker.tscn` | New | Reports whether a board can be cleared, and with which materials |
| Content | Demo stones, sword map, a pre-carved demo item | Changed | Placeholder rune numbers to tune |
| Tests | `test_disenchant_board` | New | Costs, payouts, replay, blocked steps, commit |
| Class | Material inventory and item plan | Changed | Planning a material moves it from the inventory into the item's plan; unplanning moves it back. Used by carving and disenchanting. |

## Save data impact

New fields on materials and maps, saved in their `.tres` files. Item carvings aren't saved to disk yet, so nothing else changes.

## Alternatives considered

- **Cut lines live, one at a time, with no plan.** It's simpler, but §7.6 decides plan, then commit.
- **Pick a system from Appendix A (load, countdowns, pins) instead of runes.** Runes are the decided system to build on, and the others stay archived.

## Risks

- **The numbers decide whether it's fun.** Placeholder rune values may make every board trivial or always blocked. The checker and a tuning table are there to find out quickly.
- **Disenchant mode reuses the carving view.** Keeping one board view for both modes saves code but risks tangling them. If it gets messy, it splits into two views.

## How to see it working

1. Run the project and pick the pre-carved demo sword, then switch to Disenchant.
2. Plan: dissolve a stone for starting runes, then cut lines. The rune bar updates after each step, and a step you can't afford shows red.
3. Cut every line of an enchantment, pull it out, and commit. The cells are free again, and the materials you dissolved are used up.
4. Run `tools/solvability_checker.tscn` on the demo item to see whether it can be cleared and with what.
5. Headless: `godot --headless --path . res://tests/test_disenchant_board.tscn`.

## Steps

1. **PR `disenchanting-rules`:** `RuneSet`, the material and map fields, `DisenchantBoard`, the inventory/item-plan change, placeholder numbers, tests.
2. **PR `disenchanting-table`:** Disenchant mode on the table and the pre-carved demo item.
3. **PR `solvability-checker`:** the dev checker.
