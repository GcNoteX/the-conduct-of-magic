# Build an item map

An item's map is painted in a scene with Godot's tile tools: cells on one layer, magic nodes on a layer above it. Pressing **Bake** writes the painted map into the item's `HexMapDefinition` resource, which is what the game reads. The worked examples are the three demo swords: `inscribing/demo/dagger_map.tscn`, `short_sword_map.tscn` and `long_sword_map.tscn`. The short sword has the **Ember Well**, an example of a bigger magic node made as a scene tile.

## What's in a map scene

| Node | Type | What it does |
| --- | --- | --- |
| Root | `ItemMapScene` (a `Node2D`) | Holds the **Map Definition** to bake into and the **Bake** button |
| `Cells` | `TileMapLayer` | The item's cells: paint its silhouette here |
| `MagicNodes` | `TileMapLayer` | The magic nodes, drawn above the cells. Every magic node sits on a cell |

Both layers use the tile set `inscribing/tiles/hex_map_tiles.tres`. It has three sources (a source is one group of tiles in the tile set):

| Source | Tiles | Paint on |
| --- | --- | --- |
| **Cells** | The steel cell | `Cells` |
| **Magic nodes** | Water, Fire, Wind and Stone nodes, one tile per rune kind | `MagicNodes` |
| **Magic node scenes** | The Ember Well (a scene tile) | `MagicNodes` |

## What a magic node costs and gives back

Each magic node has two sets of runes, and the tile you paint decides them:

- **Edge runes**: what it puts on each line at it. Cutting a line while disenchanting costs the edge runes of both its ends.
- **Harvest runes**: what it gives back, once, when its last line is cut.

The four plain tiles use the placeholder numbers for now: a node puts 1 rune of its kind on each line, and gives back 1 of its kind and 1 of the next kind (water then fire, fire then wind, wind then stone, stone then water).

| Tile | Edge runes | Harvest runes |
| --- | --- | --- |
| Water node | 1 water | 1 water, 1 fire |
| Fire node | 1 fire | 1 fire, 1 wind |
| Wind node | 1 wind | 1 wind, 1 stone |
| Stone node | 1 stone | 1 stone, 1 water |
| Ember Well (2 cells) | 1 fire | 1 fire, 1 wind |

## Make a new map

1. **Create the resource the game reads.** In the FileSystem dock, right-click the item's folder and choose **Create New > Resource...**. Search for `HexMapDefinition`, pick it and save it, for example as `ring_map.tres`. In the Inspector, fill in **Map Name**.
2. **Create the scene.** Choose **Scene > New Scene**, then **Other Node**, search for `ItemMapScene` and create it. Rename the root to something like `RingMap`.
3. **Add the cell layer.** With the root selected, add a child node of type `TileMapLayer` and name it `Cells`. In the Inspector, set its **Tile Set** to `res://inscribing/tiles/hex_map_tiles.tres` (drag it in from the FileSystem dock, or use **Load**).
4. **Add the magic node layer.** Select the root again and add a second `TileMapLayer` named `MagicNodes`. It has to come after `Cells` in the Scene dock so it's drawn on top. Give it the same **Tile Set**.
5. **Connect the root.** Select the root. In the Inspector, set **Map Definition** to your new `.tres` file, **Cells Layer** to `Cells` and **Magic Layer** to `MagicNodes`.
6. **Save the scene** next to the resource, for example as `ring_map.tscn`.

The quickest alternative is to duplicate `long_sword_map.tscn` (right-click it in the FileSystem dock and choose **Duplicate...**), point its **Map Definition** at a new resource, and repaint it.

## Paint the cells

1. Select the `Cells` node. The **TileMap** panel opens at the bottom of the editor.
2. In its **Tiles** tab, pick the **Cells** source in the list on the left, then click the steel cell.
3. Pick a tool in the panel's toolbar: **Paint** (D) for single cells, **Line** (L), **Rect** (R) or **Bucket** (B) for larger areas, and **Eraser** (E) to remove cells. Right-click while painting also erases.
4. Paint the item's silhouette.

**Stay right of and below the scene's origin.** The tile at the origin is column 0, row 0 of the map. Cells to the left of it or above it can't be baked, and the root shows a warning if any are there.

Every other row sits half a cell to the right. That's the same layout the game uses, so what you paint is exactly what the player sees. For a clean, symmetric edge, centre every row on the same middle: rows 0, 2, 4... get an odd number of cells and rows 1, 3, 5... an even number (see the demo swords).

## Paint the magic nodes

1. Select the `MagicNodes` node.
2. In the **Tiles** tab, pick the **Magic nodes** source and click the kind of node you want (water, fire, wind or stone). For the Ember Well, pick the **Magic node scenes** source and click it.
3. Paint it on top of a cell with **Paint** (D). Erase a magic node with the **Eraser** on this layer; the cell under it stays.

Magic nodes are numbered in reading order: top row first, left to right. Those numbers show on the board in Disenchant mode and in the solvability check.

## Bake

1. Select the root node.
2. Press **Bake** in the Inspector, under **Magic Layer**.
3. Save the scene (Ctrl+S) as well, so your painting is kept.

Bake writes the cells, the magic nodes, the cells a bigger magic node covers, and every magic node's runes (taken from its tile). The map's name stays as it is. The Output panel prints what was baked, or why it couldn't be. Don't edit the runes on the map resource by hand: the next bake overwrites them from the tiles.

## Tutorial: make your own magic node

There are two ways to make a magic node. A **plain tile** is one picture in the tile set with its runes stored on the tile; it's the quickest way to add a node that takes one cell. A **scene tile** is a small scene of its own; use it for a node that covers more than one cell, or one with art made of several parts. The Ember Well in `items/maps/magic_nodes/ember_well.tscn` is a finished scene tile you can copy.

### Way 1: a plain tile

This adds a fifth tile, for example a stronger fire node, to the **Magic nodes** source.

1. **Draw the art.** Open `art/placeholder/magic_node_tiles.png` in your paint program. It's a strip of 56×64 tiles, one per node. Make the canvas 56 pixels wider and draw the new node in the new space, centred, with a clear background (the cell underneath shows through). Save it. Godot reimports it on its own.
2. **Open the tile set.** Select `MagicNodes` in any map scene, then click the **TileSet** tab at the bottom of the editor (next to **TileMap**).
3. **Create the tile.** In the **Tiles** list on the left, click **Magic nodes**. In the middle pane, make sure **Setup** is selected at the top, then click the empty space where your new art is. A tile appears there. (If Godot asks whether to create tiles automatically in non-transparent areas, choose **Yes**.)
4. **Mark it as a magic node.** Switch the middle pane's top bar from **Setup** to **Select** and click the new tile. The tile's properties show in the left pane. Open **Custom Data** and tick **magic_node**.
5. **Set what it costs.** Still under **Custom Data**, click the empty field next to **edge_runes**, choose **New Resource...**, search for `RuneSet` and create it. Click the new RuneSet to open it, then set the counts, for example **Fire** 2. These are the runes the node puts on each of its lines.
6. **Set what it gives back.** Do the same for **harvest_runes**, for example **Fire** 2 and **Wind** 1. These are the runes it gives back when its last line is cut.
7. **Save the tile set**: with the tile set open, press Ctrl+S, or right-click `hex_map_tiles.tres` in the FileSystem dock and choose **Save**.

The quickest way to get a working tile is to start from a copy of an existing one: in **Select** mode, click the Fire node, look at its **Custom Data**, and set the same up on your tile.

### Way 2: a scene tile (bigger or custom nodes)

This walks through how the Ember Well was made: a fire node that covers two cells, its own cell and the one to its right.

1. **Draw the art.** Make a PNG the size the node covers. One map cell is 56×64 pixels and the next cell to the right is 56 pixels further along, so a two-cell node is 112×64. The Ember Well's art is `art/placeholder/ember_well.png`.
2. **Create the scene.** Choose **Scene > New Scene**, then **Other Node**, search for `MagicNodeTile` and create it. Name the root after the node, for example `EmberWell`.
3. **Add the art.** With the root selected, add a child `Sprite2D` named `Art` and drag your PNG onto its **Texture**. The root's position is the centre of the node's own cell (the cell you paint it on, and where lines attach), so move the sprite to line the art up: the Ember Well's sprite sits at **Position** (28, 0), halfway to the next cell, because its art spans both. A yellow outline shows each cell the node covers, to line the art up against.
4. **Set what it costs and gives back.** Select the root. Next to **Edge Runes**, choose **New RuneSet** and set **Fire** 1. Next to **Harvest Runes**, choose **New RuneSet** and set **Fire** 1 and **Wind** 1. A warning stays on the root until both are set.
5. **Set the cells it covers.** Still on the root, add an entry to **Extra Cells** for each cell besides its own, as a step from its own cell. The Ember Well has one: (1, 0), the cell to the right.

   | Entry | Cell |
   | --- | --- |
   | (1, 0) | right |
   | (-1, 0) | left |
   | (0, -1) | up and left |
   | (1, -1) | up and right |
   | (-1, 1) | down and left |
   | (0, 1) | down and right |

   Add two steps together to reach further, for example (2, 0) is two cells to the right. Lines can't run through the extra cells; they attach at the node's own cell.
6. **Save the scene** in `items/maps/magic_nodes/`, for example as `ember_well.tscn`.
7. **Add it to the tile set.** Select `MagicNodes` in a map scene and open the **TileSet** tab. In the **Tiles** list, click **Magic node scenes**. Drag your `.tscn` from the FileSystem dock into the list of scenes in the middle pane (or click the **+** button there and set its **Scene**). Leave **Display Placeholder** off, so the map shows the art itself. Save the tile set.

### Paint it, bake it, see it in the game

1. **Paint it.** Open the map scene (the Ember Well is on `inscribing/demo/short_sword_map.tscn`), select `MagicNodes`, and in the **TileMap** tab pick the node: a plain tile from **Magic nodes**, a scene tile from **Magic node scenes**. Paint it on a cell. For a bigger node, every cell it covers needs a cell under it: the root warns "The magic node at (x, y) isn't on a cell" otherwise.
2. **Bake it.** Select the root and press **Bake**, then save the scene. The Output panel says how many magic nodes it baked. To check the runes, open the map resource (for example `short_sword_map.tres`): under **Disenchanting**, the magic node's entry in **Magic Edge Runes** and **Magic Harvest Runes** shows the new numbers. Magic nodes are listed in reading order. A bigger node's other cells are listed under **Magic Node Extra Cells**.
3. **See it in the game.** Run the project (F5) and pick the item, for example **Short sword #2**. In **Carve** mode the node is a blue dot; a bigger node shades its other cells and joins them to its dot. Draw lines from an enchantment's node to it like any magic node.
4. **See its runes.** Commit an enchantment chained to it, then press **Disenchant** above the board. Each magic node shows its number, and each committed line shows rune chips with what cutting it costs: the magic node's edge runes plus the other end's. Hover the magic node to read what it puts on each line and what it gives back.

To try a node on a carved item straight away, use the solvability check: in `inscribing/inscribing_table.tscn` select `SolvabilityCheck`, tick **Enabled**, run the project, and the Output panel shows the cut order with each magic node by its number.

## Warnings

A yellow warning sign next to the root in the Scene dock means something needs fixing. Hover over it to read the message:

| Warning | What to do |
| --- | --- |
| Not baked: the painted map differs from the map definition | Press **Bake** |
| Set Map Definition... | Assign the `.tres` file on the root |
| Set Cells Layer... / Set Magic Layer... | Assign the `Cells` and `MagicNodes` nodes on the root |
| A cell at (x, y) is left of column 0 or above row 0 | Move the painting right or down, or erase that cell |
| The magic node at (x, y) isn't on a cell | Paint a cell under it, and under every cell a bigger node covers |
| Two magic nodes cover the cell at (x, y) | Move one of them: a bigger node's extra cell is on another node |
| The magic node tile at (x, y) is on the Cells layer | Erase it there and paint it on `MagicNodes` |
| The tile at (x, y) on the Magic nodes layer isn't a magic node tile | Erase it there: cells go on `Cells` |
| The tile set has to be hexagon, stacked, horizontal offset | Use `hex_map_tiles.tres` on both layers |

## Use the map in the game

The game reads the baked resource, not the scene. To give an item this map, open the item's `EnchantableItemDefinition` (for example `inscribing/demo/long_sword.tres`) and set its **Map Template** to the baked `.tres` file. Then run the project (F5): the inscribing table shows the new shape.

## Swapping in real art

All the art in the map scenes is placeholder art in `art/placeholder/`, drawn by `tools/placeholder_art/make_placeholder_art.py` (run it with `python3` from the project root; it needs Pillow). To swap in real art, keep the file's name and size and overwrite the PNG: Godot reimports it and every map picks it up. Tiles are 56×64 pixels. For a scene tile, change the texture on its `Art` sprite. Art only changes how the map looks in the editor: the board in the game draws its own cells for now.

## Check it headless

`godot --headless --path . res://tests/test_scene_bake.tscn` checks that each demo sword scene bakes to its shipped map, that the magic node tiles and the Ember Well carry the right runes, and that the demo swords are clean, symmetric silhouettes. `tools/build_demo_content.tscn` regenerates the demo swords' maps, scenes and items from the layouts written in it.
