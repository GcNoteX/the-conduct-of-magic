# 0011: Shop loop follow-ups

**Status:** Approved (2026-10-23; Gavin said to skip sheet approval and build on the recommended answers)
**Design doc:** §4.4 Material supply, §5.1 Lifecycle
**PRs:** one, off main after #24

## Goal
Gavin tested #24 and asked for three changes. You can buy stones while inscribing, at about 50% more than at the counter. You can see what the customer asked for while you carve their item. The normal game starts without the pre-made demo items, which move to a separate test bench scene where they stay available.

## Scope
**In:**
- **Supplier at the table.** The same supplier panel as at the counter, opened from a Supplier button on the table, with every price × 1.5 (rounded up).
- **Commission card at the table.** When the open item belongs to a customer, a parchment card shows their name, each enchantment they asked for (✓ committed, ○ planned, ✗ not started), the offer and what they'd pay right now.
- **Game start without demo items.** The Day starts with money, stones and known enchantments, but no items.
- **Test bench.** A new scene that opens the inscribing table on its own with the current demo items, to try carving and disenchanting without playing a day.

**Out:**
- Different or limited stock at the table.
- Delivery times for rush orders. A stone bought at the table arrives at once.
- Changes to the counter, apart from moving its supplier into a shared panel.

## Design questions for Gavin
| # | Question | Answer |
|---|---|---|
| 1 | How are table prices rounded? | × 1.5, rounded up: 5g → 8g, 8g → 12g, 15g → 23g. |
| 2 | Where does the supplier sit on the table? | A Supplier button in the right panel opens it as a pop-up over the board. Close it with the button or Esc. |
| 3 | What does the card show for a planned enchantment? | ○ planned, which doesn't count towards pay. |
| 4 | Does the game start with any items of your own? | No. Day 1 begins with 50g, the stones and all known enchantments. |
| 5 | What goes on the test bench? | Everything the demo setup has: three blank weapons, the pre-carved sword, the stones and every enchantment, plus the solvability check. |

## Approach
The counter's supplier becomes its own component, `SupplierPanel`, with a price multiplier. The counter uses it at × 1.0 and the table at × 1.5. The panel owns its purchase sounds. The table gains a `CommissionCard` that reads the open item's commission from the player and refreshes with the board. The Day gets its own starting setup without items. The current demo setup, which the tests and solvability tools already load, becomes the test bench's setup.

| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Class | `SupplierPanel` (`counter/supplier/supplier_panel.gd`) | New | Stones with your count and price × `price_multiplier`; buys them. Own `SoundBank`. Signals `purchased(material, price)`, `message(text)` |
| Class | `SupplierCatalogue` | Changed | `price_of(m, multiplier)` rounds up |
| Scene + class | `Counter` | Changed | Uses `SupplierPanel`; `buy()` passes through |
| Class | `CommissionCard` (`inscribing/commission_card.gd`) | New | Customer, each wanted enchantment's state, the offer and current payout |
| Class | `Commission` | Changed | `Progress` enum and `progress()` |
| Scene + class | `InscribingTable` | Changed | Commission card; Supplier button and pop-up; exports `supplier_catalogue`, `supplier_markup` |
| Resource | `day/demo/shop_start.tres` | New | The Day's start: 50g, stones, enchantments, no items |
| Scene | `Day` | Changed | `setup` points at `shop_start.tres` |
| Scene + class | `TestBench` (`test_bench/test_bench.tscn`) | New | The table on a player built from `inscribing/demo/demo_setup.tres` |
| Tests | `tests/gut/test_shop_follow_ups.gd` | New | Rounding, card states, empty start, table purchase, the bench |

## Save data impact
None. Nothing is saved yet.

## Alternatives considered
- **A debug toggle in the Day that adds the demo items.** It would keep test items in the real game's code path, and testing carving would mean playing through the counter first.
- **A second catalogue with table prices.** That doubles the price data. One catalogue with a multiplier keeps the 50% rule in one place.

## Risks
- **Theme PR #31** moves `counter/counter_theme.tres` into `ui/main_theme.tres`. The card and the table's supplier pop-up preload the counter theme, so whichever merges second repoints them.
- **An empty table on day 1.** The table says "No items yet" rather than showing an empty board with no explanation.

## How to see it working
1. Run the game. Day 1 opens at the counter. Accept Elsa, then press F3. The table lists only Elsa's dagger.
2. The commission card shows Glow ✗ and Ward ✗. Plan Glow and it turns ○; commit it and it turns ✓, with "Pays 40g if collected now".
3. Press Supplier (rush order). Fire stone costs 12g. Buy one: money and the count update.
4. Open `test_bench/test_bench.tscn` and press F6. The table opens with the demo items.
5. Headless: the GUT suite includes `test_shop_follow_ups.gd`.

## Steps
1. One PR off main with all of the above and a test report.
