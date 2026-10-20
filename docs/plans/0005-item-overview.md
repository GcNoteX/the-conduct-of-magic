# 0005: Item overview

2026-10-18 · Gavin

**Status:** Draft. Gavin picked this for the overnight build (or it was the default); built as a draft for review in the morning together with the code.

**Design doc:** §7.6 (planned materials stay with the item, Gavin 2026-10-17: "a feature for them to navigate and see all their items and a tooltip for what was currently being used in plans for each item")

**PRs:** one (`item-overview`)

## Goal

You can see all your items at once, with what each one's plans are holding, and jump straight to any of them.

## Scope

**In:**

- An **Items** button on the table (and the I key) opens an overview on top of the board.
- One card per item: its name, a small picture of its map with its carvings and drafts, the enchantments carved on it, the enchantments planned on it, and the materials its plans are holding (carving and disenchanting).
- Hovering a card shows the full list as a tooltip. Clicking a card opens that item and closes the overview.
- Items holding planned materials are marked, so you can spot where a missing material went.

**Out:**

- Sorting, filtering or searching.
- Anything outside the inscribing table, such as a shop or inventory screen.
- Saving (separate work).

## Design questions for Gavin

| # | Question | Recommendation |
| --- | --- | --- |
| 1 | Where does the overview live? | An overlay on the table, opened with an Items button or the I key, closed with Esc or by picking an item. The item dropdown stays as a quick switch. |

## Approach

The overview only reads what the items already know: their committed carvings, their draft plans and the materials those plans hold. Each card draws a small version of the item's hex map with the same colours as the board. Picking a card emits a signal up to the table, which opens the item the same way the dropdown does.

| Kind | Name | New / changed | Purpose |
| --- | --- | --- | --- |
| Class | `ItemOverview` | New | The overlay: a grid of item cards, opened and closed by the table |
| Class | `ItemCard` | New | One item: name, thumbnail, carvings, plans, held materials, tooltip |
| Class | `ItemThumbnail` | New | Draws a small hex map with carvings and drafts |
| Signal | `ItemOverview.item_chosen(index)` | New | Tells the table which item to open |
| Class | `InscribingTable` | Changed | Items button, I key, opens the chosen item |
| Tests | drive and unit checks | New | Cards list the right carvings, plans and held materials; clicking opens the item |

## Save data impact

None.

## Alternatives considered

- **Tooltips on the item dropdown only.** Smaller, but you can't see everything at once.
- **A separate screen.** Cleaner later, but the table is the only screen for now.

## Risks

- Thumbnails of big maps may be hard to read at card size. Cards can grow, or the thumbnail can show only carved cells.

## How to see it working

1. Run the game, plan a material on the Dagger, then press Items. The Dagger card shows it holds that material.
2. The pre-carved Long sword card shows Kindle and Keen as carved.
3. Click the Short sword card: the table opens it.

## Steps

1. **PR `item-overview`:** the overlay, cards, thumbnails, table hookup, tests.
