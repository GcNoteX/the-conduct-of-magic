# Test report: Placeholder art pass

**Date:** 2026-10-20
**Planning sheet:** None. Gavin asked for this to go straight to a PR, without a sheet.
**PR:** https://github.com/GcNoteX/the-conduct-of-magic/pull/32

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `placeholder-art-pass` | The art pass, stacked on PR #31 (UI theme), which is stacked on PR #24 (shop loop) | Yes |

It's a single feature, so the feature branch is also the branch to test. It's stacked on #31 because its panel, card and tooltip looks are type variations in #31's project theme. Merge #24, then #31, then this.

## What to test

### Placeholder art pass
**Branch:** `placeholder-art-pass`
**Scene to run:** the main scene (F5), which starts the day at the counter

How to test:
1. Run the game. At the counter, look at the supplier panel and the "On the counter" paper.
2. Accept a customer and buy a stone, then press F2 to go to the inscribing table.
3. Open the Item picker and press I for the item overview.
4. Open the pre-carved long sword (the last item) and look at its stones. Switch Layout to Bottom tray, then switch to Disenchant.
5. Drag a stone from the Materials tab onto a node.
6. On the InscribingTable node, untick Use art and run again.

Acceptance criteria:
- [ ] Each stone has its own picture, and they can be told apart by shape as well as colour: fire is a pointed flame cut, water a droplet, red a round glossy pebble, blue an upright crystal, and yellow a cut gem in a brass setting (it's the only tier 2 stone).
- [ ] The same stone pictures show in the supplier, on the palette cards, on the drag chip and in the nodes on the board.
- [ ] The dagger, short sword and long sword each have an icon, shown on the counter's "On the counter" paper, when a customer collects, in the item picker and on the item overview cards.
- [ ] The table sits on a wooden workbench with a green leather mat under the item. Its panels, cards and the top bar use the counter's dark wood, brass and cream colours, from the project theme.
- [ ] Hovering a board node shows a dark tooltip, so the pale rune colours stay readable. Other tooltips use the theme's paper style.
- [ ] Changing `CardPanel` or `BarPanel` in `ui/main_theme.tres` changes the palette cards and item cards, or the top bar, with no code changed.
- [ ] The day-over panel has the same dark wood and brass look.
- [ ] Ticks, progress numbers and node names on the board are still readable over the stones.
- [ ] With Use art off, nodes go back to plain colour discs. The board skin's Material art option does the same for stones alone.

Before and after screenshots are in the project files under `prototype/art-pass/`. `art_sheet.png` shows every new image.

## Known gaps
- The customer figure on the counter is still the old placeholder person.
- The enchantment cards still draw their shape in lilac, to match the enchantment lines on the board.
- The test fixtures' copies of the stones and swords (`tests/fixtures/`) have no icons, since the tests don't look at art.
