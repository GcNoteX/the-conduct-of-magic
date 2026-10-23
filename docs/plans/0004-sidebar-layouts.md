# 0004: Sidebar and drag-and-drop UI experiments

**Status:** Approved (2026-10-17), with all recommendations
**Design doc:** §7.2 How an enchantment comes together ("drag an enchantment onto the item map")
**PRs:** `table-sidebar`

## Goal
Try a few ways of handing enchantments and materials to the board, side by side, and keep the one that feels best. The main one is a sidebar that slides open and closed. Enchantments are dragged onto the item like materials, instead of click-to-hold.

## Scope
**In:**
- Collapsible sidebar with Enchantments and Materials tabs of cards (swatch or shape, name, count). A handle or Tab slides it, and a pin keeps it open while dragging.
- Dragging enchantments onto the board, with the ghost following the mouse and R or the wheel rotating it.
- Two other layouts behind a switch: a bottom tray, and a quick palette at the mouse while Space is held.
- The original lists as a fourth option, for comparison.

**Out:**
- Art and animation polish beyond a simple slide.
- Disenchanting controls (sheet 0003).

## Design questions for Gavin
| # | Question | Answer |
|---|---|---|
| 1 | Should enchantments move to drag and drop too? | Yes. Click-to-hold stays as a fallback for now. |
| 2 | Which side should the sidebar go on? | Left. The right panel keeps the timer, commit button and messages. |
| 3 | Does the board resize when the sidebar opens? | No. The sidebar slides over the board's edge. |
| 4 | Which other layouts are worth trying? | A bottom tray and a quick palette at the mouse. |
| 5 | How do you switch between layouts? | A dropdown on the table, for this experiment only. The losing layouts are deleted once one is picked. |

## Approach
Each enchantment or material is a `PaletteCard` that starts a drag. The layouts are containers holding the same cards, so the comparison is fair and the losers are cheap to delete. The board's drop area accepts enchantments too and shows the placement ghost during the drag.

| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Class | `PaletteCard`, `PatternPreview` | New | A draggable enchantment or material card, with a small drawing of the shape |
| Class | `PaletteLayout` | New | Base for the layouts: where they sit, their cards, their keys |
| Class | `CollapsibleSidebar`, `BottomTray`, `QuickPalette`, `ClassicLists` | New | The four layouts (all but one deleted after the experiment) |
| Class | `BoardDropArea`, `BoardView` | Changed | Accept dropped enchantments; show and rotate the ghost during a drag |
| Class | `InscribingTable` | Changed | Item picker and layout dropdown on the right; builds the chosen layout |

## Save data impact
None.

## Steps
1. PR `table-sidebar`: cards, the four layouts, dragging enchantments, the dropdown.
2. Once a layout is picked, a small follow-up PR deletes the others.

## Outcome
Gavin (2026-10-20): keep the sidebar, with its pin, and the quick palette, and maintain both. They stay switchable with the dropdown, now labelled Palette, with the sidebar as the default. The branch `keep-sidebar-and-quick-palette` deletes the bottom tray and the original lists.
