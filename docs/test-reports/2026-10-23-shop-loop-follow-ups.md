# Test report: Shop loop follow-ups

**Date:** 2026-10-23
**Planning sheet:** [0008-shop-loop-follow-ups.md](../plans/0008-shop-loop-follow-ups.md)
**PR:** draft PR from `shop-loop-follow-ups`

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `shop-loop-follow-ups` | Table supplier, commission card, item-free start, test bench | Yes |

One branch: the three changes are small and share files, so there's nothing to combine.

## What to test

### Rush orders at the table
**Branch:** `shop-loop-follow-ups`
**Scene to run:** the main scene (Day)

How to test:
1. Accept Elsa at the counter, then press F3 to go to the table.
2. Press **Supplier (rush order)** in the right panel.
3. Buy a Fire stone, then try to buy something you can't afford.
4. Close it with Esc.

Acceptance criteria:
- [ ] Prices are the counter's × 1.5, rounded up: Red and Blue 8g, Fire and Water 12g, Yellow 23g.
- [ ] Buying takes the money (top bar and pop-up), adds the stone to the Materials tab, and plays the till sound.
- [ ] Stones you can't afford are greyed out.
- [ ] Esc or Close shuts the pop-up. Switching sides with F2 shuts it too.

### Commission card
**Branch:** `shop-loop-follow-ups`
**Scene to run:** the main scene (Day)

How to test:
1. At the table with Elsa's dagger open, look at the card at the top of the right panel.
2. Place Glow on the dagger without committing, then commit it.

Acceptance criteria:
- [ ] The card names Elsa Marrow and lists Glow and Ward, each with ✗ at first.
- [ ] A placed but uncommitted Glow shows ○ (planned). Once committed it shows ✓, and the card says "Pays 40g if collected now".
- [ ] The card is hidden on an item that isn't a customer's (try the test bench).

### Starting without demo items, and the test bench
**Branch:** `shop-loop-follow-ups`
**Scenes to run:** the main scene, then `res://test_bench/test_bench.tscn` (F6)

How to test:
1. Run the game and press F2 on day 1 before accepting anyone.
2. Open `test_bench/test_bench.tscn` and press F6.

Acceptance criteria:
- [ ] On day 1 the table has no items and says "No items yet…". The Item list fills only with customers' items.
- [ ] The test bench opens the table on its own (no day clock, no counter), with the dagger, short sword, long sword and the pre-carved sword, ready to carve or disenchant.

## Known gaps
- The card and the pop-up use the counter's theme file. The theme PR #31 moves that file, so it needs a one-line repoint when either merges.
