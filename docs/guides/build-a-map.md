# Build an item map

An item's map is painted in a scene with Godot's tile tools. Pressing **Bake** writes the painted cells into the item's `HexMapDefinition` resource, which is what the game reads. The worked example is `inscribing/demo/demo_sword_map.tscn`.

## What's in a map scene

| Node | Type | What it does |
| --- | --- | --- |
| Root | `ItemMapScene` (a `Node2D`) | Holds the **Map Definition** to bake into and the **Bake** button |
| `Cells` | `TileMapLayer` | The painted cells, using the tile set `inscribing/tiles/hex_map_tiles.tres` |

The tile set has two tiles:

- **Cell** (left): a plain cell of the item.
- **Magic node** (right): a cell holding a magic node.

## Make a new map

1. **Create the resource the game reads.** In the FileSystem dock, right-click the item's folder and choose **Create New > Resource...**. Search for `HexMapDefinition`, pick it and save it, for example as `ring_map.tres`. In the Inspector, fill in **Map Name**.
2. **Create the scene.** Choose **Scene > New Scene**, then **Other Node**, search for `ItemMapScene` and create it. Rename the root to something like `RingMap`.
3. **Add the cell layer.** With the root selected, add a child node of type `TileMapLayer` and name it `Cells`. In the Inspector, set its **Tile Set** to `res://inscribing/tiles/hex_map_tiles.tres` (drag it in from the FileSystem dock, or use **Load**).
4. **Connect the root.** Select the root. In the Inspector, set **Map Definition** to your new `.tres` file and **Cells Layer** to the `Cells` node.
5. **Save the scene** next to the resource, for example as `ring_map.tscn`.

The quickest alternative is to duplicate `demo_sword_map.tscn` (right-click it in the FileSystem dock and choose **Duplicate...**), point its **Map Definition** at a new resource, and repaint it.

## Paint the cells

1. Select the `Cells` node. The **TileMap** panel opens at the bottom of the editor.
2. In its **Tiles** tab, click the cell tile or the magic node tile.
3. Pick a tool in the panel's toolbar: **Paint** (D) for single cells, **Line** (L), **Rect** (R) or **Bucket** (B) for larger areas, and **Eraser** (E) to remove cells. Right-click while painting also erases.
4. Paint the item's silhouette with cell tiles, then paint magic node tiles where the magic nodes go. A magic node tile replaces the cell under it.

**Stay right of and below the scene's origin.** The tile at the origin is column 0, row 0 of the map. Cells to the left of it or above it can't be baked, and the root shows a warning if any are there.

Every other row sits half a cell to the right. That's the same layout the game uses, so what you paint is exactly what the player sees.

## Bake

1. Select the root node.
2. Press **Bake** in the Inspector, under **Cells Layer**.
3. Save the scene (Ctrl+S) as well, so your painting is kept.

Bake only changes the map's cells. The map's name and any other fields on the resource stay as they are. A magic node that stays in the same cell keeps its runes; a new magic node starts with none, so set its runes under **Disenchanting** on the map resource. The Output panel prints what was baked, or why it couldn't be.

## Warnings

A yellow warning sign next to the root in the Scene dock means something needs fixing. Hover over it to read the message:

| Warning | What to do |
| --- | --- |
| Not baked: the painted cells differ from the map definition | Press **Bake** |
| Set Map Definition... | Assign the `.tres` file on the root |
| Set Cells Layer... | Assign the `Cells` node on the root |
| A cell at (x, y) is left of column 0 or above row 0 | Move the painting right or down, or erase that cell |
| The tile set has to be hexagon, stacked, horizontal offset | Use `hex_map_tiles.tres` on the `Cells` layer |

## Use the map in the game

The game reads the baked resource, not the scene. To give an item this map, open the item's `EnchantableItemDefinition` (for example `inscribing/demo/demo_sword.tres`) and set its **Map Template** to the baked `.tres` file. Then run the project (F5): the inscribing table shows the new shape.

## Check it headless

`godot --headless --path . res://tests/test_scene_bake.tscn` checks that the demo sword scene bakes to the shipped `demo_sword_map.tres`.
