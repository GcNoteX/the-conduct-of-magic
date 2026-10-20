# 0002: Map and enchantment editors

2026-10-17 · Gavin

**Status:** Approved by Gavin on 2026-10-17 ("yes to everything" on the Godot-editor approach and multi-cell nodes).

**Design doc:** §7.1 The three ingredients, §7.4 Map layout: hex grid

**PRs:** two (`map-painting`, then `enchantment-scenes`)

## Goal

You build item maps and enchantments inside the Godot editor, with tiles and scenes that can carry real sprites later, instead of typing rows of characters or editing arrays in the inspector. Short guides in the repo walk you through each.

## Scope

**In:**

- **Map painting:** an item's map is a scene with a hex `TileMapLayer`. You paint cell tiles and magic node tiles with Godot's tile tools. A **Bake** button in the inspector writes the painted cells into the item's `HexMapDefinition`, which the game already reads.
- **Enchantment scenes:** each enchantment is a scene built from small components: an enchantment node component (tier, accepted attributes, required) and a line component (which two nodes it joins and the cells it takes). A tool script snaps them to hex cells, draws the shape in the editor, and shows a warning when the shape is invalid. **Bake** writes the shape into the enchantment's resource.
- **Multi-cell nodes:** a node component lists the extra cells it covers. The data and the overlap checks support it now. How lines attach to a bigger node is decided later; until then lines attach at the node's main cell.
- **The four demo enchantments** (Kindle, Glow, Keen, Ward) and the demo sword map rebuilt this way, so there's a worked example of each.
- **Guides:** `docs/guides/build-a-map.md` and `docs/guides/build-an-enchantment.md`, step by step.

**Out:**

- Sprites and art. The scenes are ready for them, but they use placeholder drawing for now.
- The game loading the scenes directly at runtime. It keeps reading the baked resources for now.
- Disenchanting data (runes), which comes with sheet 0003.

## Approach

The scenes are the place you author; the baked `.tres` resources stay what the game reads, so nothing at runtime changes. Hex positions use the same odd-r offset layout as the board, so a painted tile at (col, row) is the same cell the game uses. Snapping and checks reuse `Hex` and the cell-path rules from the inscription board, so a shape that bakes cleanly behaves the same in play. Bake uses `ResourceSaver` so uids stay stable.

| Kind | Name | New / changed | Purpose |
| --- | --- | --- | --- |
| Resource | `hex_map_tiles.tres` | New | The hex `TileSet`: a cell tile and a magic node tile |
| Class | `ItemMapScene` | New | Tool script on a map scene; bakes its `TileMapLayer` into a `HexMapDefinition` |
| Class | `EnchantmentScene` | New | Tool script on an enchantment scene's root; snaps, validates and bakes |
| Class | `EnchantmentNodeComponent` | New | One enchantment node: requirements and the cells it covers |
| Class | `EnchantmentLineComponent` | New | One fixed line: its two nodes and its cells |
| Resource | `EnchantmentPatternNode` | Changed | Adds `extra_cells` for multi-cell nodes |
| Class | `InscriptionBoard` | Changed | Counts a node's extra cells as taken |
| Content | Demo maps and patterns | Changed | Rebuilt as scenes, re-baked |
| Docs | Two guides | New | How to build a map and an enchantment |
| Tests | `test_scene_bake` | New | Baking each demo scene gives back the shipped resource |

## Save data impact

One new field, `extra_cells` on `EnchantmentPatternNode`, empty by default, so existing files load unchanged.

## Alternatives considered

- **Custom editor scenes run with F6** (the earlier draft of this sheet). They would fight with sprites and scenes, which is why this sheet replaces them.
- **The game loading enchantment scenes at runtime.** Worth doing once there's art; baking keeps this change small and the rules untouched.

## Risks

- **Tool scripts run inside the editor**, so a bug can spam errors there. They're kept small, and the editor-only code sits behind `Engine.is_editor_hint()`.
- **Forgetting to bake** leaves the game on old data. The scene shows a "not baked" warning when its shape differs from the resource.

## How to see it working

1. Open `inscribing/demo/demo_sword_map.tscn`, paint a few cells, press Bake, then run the project: the table shows the new shape.
2. Open `enchantments/scenes/kindle.tscn`, drag a node, and watch it snap. Move it onto another node to see the warning, then fix it and press Bake.
3. Follow `docs/guides/build-an-enchantment.md` to make a new one from scratch.
4. Headless: `godot --headless --path . res://tests/test_scene_bake.tscn`.

## Steps

1. **PR `map-painting`:** the tile set, `ItemMapScene`, the demo sword map as a scene, the map guide, tests.
2. **PR `enchantment-scenes`:** the components, `EnchantmentScene`, multi-cell `extra_cells`, the four demos as scenes, the enchantment guide, tests.

## Revision 2 (Gavin, 2026-10-18)

After testing, Gavin confirmed these changes. They're built in one new PR on top of #18.

- **Magic nodes get their own layer.** A map scene has a Cells `TileMapLayer` and a Magic nodes `TileMapLayer` above it. Each rune kind is its own magic node tile (Fire node, Water node, and so on), and the tile carries what the node puts on its lines and gives back when freed. Painting a tile sets those runes. Bigger or custom magic nodes and tiles are **scene tiles**.
- **A full end-to-end example and tutorial.** One example magic node is built as a scene tile, step by step in the map guide: making the tile, setting its runes, painting it, baking, and seeing it in the game.
- **Big nodes with ports.** An enchantment node can cover several cells (for example 2 by 2) and has port markers where lines attach. It activates and deactivates as one node, with all its lines counted together.
- **More than one line between the same two nodes is allowed in enchantment shapes only.** Lines the player draws keep the current rule.
- **Placeholder art made by Claude.** It's saved as real asset files (PNG), so one enchantment, one map and one magic node show a complete example of art on nodes, cells and lines. It gets replaced when Gavin drops in real art.

**Steps:** one PR (`editor-layers-and-ports`) with the layer, the example scene node and tutorial, ports, double lines in shapes, the art example, updated guides and tests.
