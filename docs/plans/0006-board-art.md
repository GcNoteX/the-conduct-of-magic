# 0006: Board art

2026-10-18 · Gavin

**Status:** Draft. Gavin asked for it on 2026-10-18 ("Do Board art"). Built overnight as a draft, to review together with the code in the morning.

**Design doc:** §7.4 Map layout: hex grid. Art direction itself isn't settled; this uses Claude-made placeholder PNGs until Gavin provides art.

**PRs:** one (`board-art`)

## Goal

The inscribing table draws the item's board with image tiles: cells, magic nodes for each rune kind, enchantment nodes, lines and the item outline. Swapping in real art later means replacing PNG files, not changing code.

## Scope

**In:**

- The board on the table draws its cells, magic nodes, enchantment nodes and lines from PNGs in `art/placeholder/`. These are the same files the map and enchantment editors use (sheet 0002, revision 2).
- Each image is set in one place, a board skin resource, so you can swap art in the inspector.
- Highlights stay drawn on top as they are now: drag ghost, green rings, red errors, rune chips and step numbers.
- A Use art toggle on the table switches between the art and the current flat drawing, so you can compare them.

**Out:**

- Final art, animation and effects.
- Art for cards, the sidebar or menus.

## Approach

The board view keeps its layout and hit testing and only changes how each cell is painted. A `BoardSkin` resource names a texture for each kind of thing on the board. The view draws the texture for each cell, tinted for state (free, taken, drafted), and falls back to the flat colour when a texture is missing. The table's skin points at the placeholder PNGs.

| Kind | Name | New / changed | Purpose |
| --- | --- | --- | --- |
| Resource | `BoardSkin` | New | One texture per board element, plus tints for each state |
| Content | `art/placeholder/board_skin.tres` | New | The skin using the placeholder PNGs |
| Class | `BoardView` | Changed | Draws textures from the skin; flat drawing stays as the fallback |
| Class | `InscribingTable` | Changed | Holds the skin and the Use art toggle |
| Tests | Drive screenshots | Changed | Both modes captured with art on and off |

## Save data impact

None.

## Alternatives considered

- **Replace the board with TileMapLayers at runtime.** It matches the editor, but hit testing, ghosts and highlights would all need rewriting. Possible later, once the game loads map scenes directly.
- **Hard-code the texture paths in the view.** It's less code, but you couldn't swap art in the inspector.

## Risks

- Placeholder art may make the board harder to read than flat colours. The toggle lets you compare the two.
- Rotated or multi-cell nodes need their textures placed carefully. Big 2x2 nodes use one image across their cells.

## How to see it working

1. Run the game (F5). The board shows the art tiles in Carve and Disenchant modes.
2. Untick Use art on the table's root node and run again. The flat drawing is back.
3. Swap one PNG in `art/placeholder/` and run again. The board picks up the new image.

## Steps

1. **PR `board-art`:** `BoardSkin`, the placeholder skin, the `BoardView` drawing, the toggle, screenshots.
