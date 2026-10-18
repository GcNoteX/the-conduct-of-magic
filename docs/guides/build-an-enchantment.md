# Build an enchantment

An enchantment's shape is built in a scene from node and line components. They snap to hex cells, the scene warns you while the shape is broken, and pressing **Bake** writes the shape into the enchantment's resource, which is what the game reads. The worked examples are in `enchantments/scenes/`: `kindle.tscn`, `glow.tscn`, `keen.tscn` and `ward.tscn`.

## What's in an enchantment scene

| Node | Type | What it does |
| --- | --- | --- |
| Root | `EnchantmentScene` (a `Node2D`) | Holds the **Enchantment** resource to bake into and the **Bake** button. Draws the hex grid and the cells the lines take |
| `NodeA`, `NodeB`, ... | `EnchantmentNodeComponent` | One enchantment node: its tier, the attributes it accepts, and any extra cells it covers |
| `LineAB`, ... | `EnchantmentLineComponent` (a `Line2D`) | One of the enchantment's own fixed lines: the two nodes it joins and the cells it runs through |

All the components go directly under the root.

**Numbering.** Nodes are numbered in the order they appear in the Scene dock, starting at 0. Node 0 is the enchantment's origin and is drawn with a gold ring. Drag nodes up or down in the Scene dock to renumber them. Lines are baked in Scene dock order too.

**Labels.** Each node shows its number and what it accepts: `T2` for a minimum tier above 1, then the attributes (`So` soft, `Ha` hard, `Sh` shiny, `Fl` flame, `Wa` water). A star marks a required attribute, and `any` means any material.

## Make a new enchantment

1. **Create the resource the game reads.** In the FileSystem dock, right-click `enchantments/patterns/` and choose **Create New > Resource...**. Search for `Enchantment`, pick it and save it, for example as `quench.tres`. In the Inspector, fill in **Enchantment Name** and **Effect Description**.
2. **Create the scene.** Choose **Scene > New Scene**, then **Other Node**, search for `EnchantmentScene` and create it. Rename the root to the enchantment's name.
3. **Connect the root.** In the Inspector, set **Enchantment** to your new `.tres` file.
4. **Save the scene** in `enchantments/scenes/`, for example as `quench.tscn`.

The quickest alternative is to duplicate one of the demo scenes (right-click it in the FileSystem dock and choose **Duplicate...**) and point its **Enchantment** at a new resource.

## Add nodes

1. Select the root, click **+** (Add Child Node), search for `EnchantmentNodeComponent` and create it. Give it a name, like `NodeA`.
2. Drag it in the 2D view. It snaps to the centre of the nearest cell.
3. In the Inspector, set what it accepts:
   - **Tier Requirement**: the lowest material tier it takes.
   - **Material Requirements**: add an element, choose **New MaterialCondition**, then set its **Attribute** and whether it's **Required**. A node with no requirements accepts any material.
4. Repeat for each node. The first one in the Scene dock is the origin.

## Add lines

1. Select the root and add a child `EnchantmentLineComponent`. Name it after its nodes, like `LineAB`.
2. In the Inspector, set **From Node** and **To Node** (click **Assign...** and pick the node).
3. The line runs straight between the two nodes, and the cells it takes are shaded.

A line has to run cell by cell, so two nodes in a straight row need at least one free cell between them, or none at all if they are neighbours. Nodes that aren't in a straight row get a line that zigzags along the closest cells.

**Bending a line.** Select the line. The point tools appear in the toolbar above the 2D view; use **Edit points** (selected by default). Click on the line between its ends to add a bend point there, and drag it to the cell the line should pass through. Bend points snap to cell centres, and the line runs cell by cell through them in order. Right-click a bend point to remove it. The two ends always stay on their nodes, so drag the nodes rather than the ends.

**Line looks.** Each line is a `Line2D`, so you can change its **Width** and **Default Color** in the Inspector. That changes only how it looks in the editor.

## Nodes that cover several cells

A node can cover more cells than its own. Select the node and add entries to **Extra Cells**. Each entry is a step from the node's own cell:

| Entry | Cell |
| --- | --- |
| (1, 0) | right |
| (-1, 0) | left |
| (0, -1) | up and left |
| (1, -1) | up and right |
| (-1, 1) | down and left |
| (0, 1) | down and right |

Add two steps together to reach further, for example (2, 0) is two cells to the right. Extra cells are taken like the node's own cell: nothing else can use them. Lines still join the node at its own cell, the one with the circle.

## Bake

1. Select the root.
2. Press **Bake** in the Inspector, under **Enchantment**.
3. Save the scene (Ctrl+S) as well, so your work is kept.

Bake only changes the shape: the nodes and lines. The name, description and icon on the resource stay as they are.

## Warnings

A yellow warning sign next to the root in the Scene dock means something needs fixing. Hover over it to read the message. Cells that two things are trying to use are drawn in red.

| Warning | What to do |
| --- | --- |
| Not baked: the shape differs from the enchantment resource | Press **Bake** |
| Node 2 overlaps node 1 | Move one of the nodes, or remove the extra cell that lands on the other node |
| Line 1: it runs over node 0 / line 0 | Move a node, or bend the line around it |
| Line 0: it has to join two different nodes | Set **To Node** to a different node from **From Node** |
| Line 2: nodes 0 and 1 are already joined | Delete one of the two lines between those nodes |
| LineAB: Set both From Node and To Node | Assign both nodes on the line |
| Set Enchantment... | Assign the `.tres` file on the root |

You can't bake while there's a warning other than "Not baked".

## Use the enchantment in the game

The game reads the baked resource, not the scene. To try a new enchantment on the inscribing table, open `inscribing/demo/demo_setup.tres` and add it to **Enchantments**. Then run the project (F5).

## Check it headless

`godot --headless --path . res://tests/test_scene_bake.tscn` checks that each demo scene bakes to its shipped resource in `enchantments/patterns/`.
