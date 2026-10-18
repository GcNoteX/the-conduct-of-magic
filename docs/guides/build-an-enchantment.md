# Build an enchantment

An enchantment's shape is built in a scene from node and line components. They snap to hex cells, the scene warns you while the shape is broken, and pressing **Bake** writes the shape into the enchantment's resource, which is what the game reads. The worked examples are in `enchantments/scenes/`: `kindle.tscn`, `glow.tscn`, `keen.tscn` and `ward.tscn`. `bastion.tscn` is an example only (not a real enchantment): a big node covering 2×2 cells with two ports, joined twice to one of its nodes. Kindle and Bastion show placeholder art on their nodes and lines.

## What's in an enchantment scene

| Node | Type | What it does |
| --- | --- | --- |
| Root | `EnchantmentScene` (a `Node2D`) | Holds the **Enchantment** resource to bake into and the **Bake** button. Draws the hex grid and the cells the lines take |
| `NodeA`, `NodeB`, ... | `EnchantmentNodeComponent` | One enchantment node: its tier, the attributes it accepts, any extra cells it covers and its ports. An optional `Sprite2D` child is its art |
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
4. If either node has more than one port (see below), set **From Port** and **To Port** to the port's number. Leave them at 0 otherwise.

A line has to run cell by cell, so two nodes in a straight row need at least one free cell between them, or none at all if they are neighbours. Nodes that aren't in a straight row get a line that zigzags along the closest cells.

**Bending a line.** Select the line. The point tools appear in the toolbar above the 2D view; use **Edit points** (selected by default). Click on the line between its ends to add a bend point there, and drag it to the cell the line should pass through. Bend points snap to cell centres, and the line runs cell by cell through them in order. Right-click a bend point to remove it. The two ends always stay on their nodes, so drag the nodes rather than the ends.

**Line looks.** Each line is a `Line2D`, so you can change its **Width** and **Default Color** in the Inspector. That changes only how it looks in the editor.

## Big nodes and ports

A node can cover more cells than its own. Select the node and add entries to **Extra Cells**. Each entry is a step from the node's own cell:

| Entry | Cell |
| --- | --- |
| (1, 0) | right |
| (-1, 0) | left |
| (0, -1) | up and left |
| (1, -1) | up and right |
| (-1, 1) | down and left |
| (0, 1) | down and right |

Add two steps together to reach further, for example (2, 0) is two cells to the right. Extra cells are taken like the node's own cell: nothing else can use them. A 2×2 node, like Bastion's, has extra cells (1, 0), (0, 1) and (1, 1).

**Ports** are the cells where lines attach, both the enchantment's own lines and the lines the player draws on the item. Add entries to **Ports**, using the same steps: (0, 0) is the node's own cell, and every other port has to be one of its extra cells. With no ports set, lines attach at the node's own cell. Each port is drawn with a green ring and its number, `P0`, `P1` and so on, in the order of the list; a line picks its port by that number (**From Port** or **To Port**).

However many cells and ports it has, it's still **one node**: it takes one material, it activates and deactivates as a whole, and every line at any of its ports counts towards its material's conditions. When disenchanting, it's freed (and gives back its runes) when the last line at any of its ports is cut.

To try it, open `bastion.tscn`. `BigNode` covers four cells with ports `P0` (its own cell) and `P1` (its bottom-right cell). On the table (F5), pick Bastion from the enchantments, place it, and draw a line from a magic node to each port.

## More than one line between the same two nodes

An enchantment's own shape can join the same two nodes with two or more lines, as long as each takes its own cells: add another `EnchantmentLineComponent` with the same **From Node** and **To Node** and bend it a different way. Bastion's `LineLeft` and `LineLeftTop` both join `NodeLeft` to `BigNode`. Each is a line of its own: when disenchanting, each is cut separately and costs its own runes.

This is only for the enchantment's own lines. Lines the player draws can't join two nodes that are already joined.

## Art

A node's art is a `Sprite2D` child of the node component. Select the node, add a child `Sprite2D` named `Art`, drag a PNG onto its **Texture**, and tick **Show Behind Parent** (under **CanvasItem > Visibility**) so the node's number and labels stay on top. Once a node has a sprite it stops drawing its placeholder circle. For a big node, move the sprite to the middle of its cells: Bastion's plate sits at **Position** (41.569, 24).

A line's look is its `Line2D` settings. Kindle's and Bastion's lines use a texture: **Texture** is `rune_line.png`, **Texture Mode** is **Tile** (under **Fill**), **Joint Mode**, **Begin Cap Mode** and **End Cap Mode** are **Round** (under **Capping**), and **CanvasItem > Texture > Repeat** is **Enabled**, so the texture repeats along the line. **Width** sets how thick it is.

The placeholder art is in `art/placeholder/` (`enchantment_socket.png`, `enchantment_big_node_2x2.png`, `rune_line.png`), drawn by `tools/placeholder_art/make_placeholder_art.py`. To swap in real art, overwrite a PNG with the same name, or point the sprite's **Texture** at a new file. Art only changes how the scene looks in the editor: the board in the game draws its own nodes and lines for now.

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
| Line 2: it runs the same way as line 0 | Two lines between the same ports with no cells between them are one line: bend one of them, or delete it |
| Node 0: its port (2, 0) isn't one of its cells | Add that cell to **Extra Cells**, or change the port |
| Node 0: the port (1, 1) is listed twice | Remove the second entry from **Ports** |
| LineAB: NodeA has no port 2 (set From Port) | Set **From Port** or **To Port** to one of the node's port numbers |
| LineAB: Set both From Node and To Node | Assign both nodes on the line |
| Set Enchantment... | Assign the `.tres` file on the root |

You can't bake while there's a warning other than "Not baked".

## Use the enchantment in the game

The game reads the baked resource, not the scene. To try a new enchantment on the inscribing table, open `inscribing/demo/demo_setup.tres` and add it to **Enchantments**. Then run the project (F5).

## Check it headless

`godot --headless --path . res://tests/test_scene_bake.tscn` checks that each demo scene (Bastion included) bakes to its shipped resource in `enchantments/patterns/`. `tools/build_demo_content.tscn` regenerates the shipped resources, so a shape changed by hand there has to be baked again from its scene.
