# 0001: Cell-path lines and clearer nodes

**Status:** Approved (2026-10-17), with question 6 clarified
**Design doc:** §7.4 Map layout: hex grid, §7.7 First prototype
**PRs:** [#5 Inscribing prototype](https://github.com/GcNoteX/the-conduct-of-magic/pull/5)

## Goal
The player draws lines cell by cell like a connect-the-dots puzzle: each line fills the cells it passes through, no other line can use them, and moving back along the line undoes it. Every enchantment node shows what it accepts, and once filled it shows how far its material's condition is from being met. Materials are dragged from the list and dropped onto nodes.

## Scope
**In:**
- Lines as cell paths: press on a node, drag through neighbouring cells, release on another node.
- Backtracking by moving the mouse back over the path.
- Blocked cells: the line stops growing, the blocked cell turns red, and a message says why.
- On-board requirement labels on empty enchantment nodes (tier and accepted attributes).
- A progress badge on filled nodes, for example "1/2 lines", red until met and green after.
- Drag and drop of materials onto nodes, with valid nodes highlighted while dragging.
- Tests rewritten for cell paths; screenshots refreshed.

**Out:**
- A custom cursor scene (see the design questions).
- Reshaping an enchantment's own fixed lines.
- Line length or distance conditions.
- Disenchanting.

## Design questions for Gavin
| # | Question | Answer |
|---|---|---|
| 1 | What happens when the line hits a blocked cell? | The line stops at the last free cell, the blocked cell glows red, and the message bar says why. The mouse is never moved for the player. |
| 2 | Can a line pass through a node without ending there? | No. Entering any node cell ends the line on that node. |
| 3 | Can a line join two neighbouring nodes with no cells between them? | Yes, it is a line with no middle cells. |
| 4 | What if the player releases the mouse on an empty cell? | The line is cancelled. Lines only exist between two nodes. |
| 5 | Can an enchantment be placed on cells a draft line runs through? | No. The placement shows red, and the player removes the line first. |
| 6 | How are an enchantment's own fixed lines laid out? | They take cells exactly like drawn lines. Each fixed line stores its path of cells in the pattern, the path turns with the enchantment, and the enchantment can only be placed where every one of those cells is free. The demo patterns get spaced-out nodes so their lines run through cells. |
| 7 | Do we need a custom cursor scene instead of the mouse? | No. The old cursor scene existed for physics collisions on the free-placement map. On a hex grid the board finds the cell under the mouse directly, and the normal mouse keeps Godot's drag and drop, buttons and tooltips working. "The cursor owns input" stays: one input controller on the board decides what a press means. |

## Approach
A line becomes the list of cells it passes through, from its start node to its end node. The board keeps a map of which cell belongs to which line, so "no crossing" becomes "no shared cell", and the straight-line geometry goes away. While dragging, the board view keeps the path so far: moving into a neighbouring free cell adds it, moving back onto the line removes cells, and a fast mouse move is filled in cell by cell, stopping at the first blocked cell. Conditions gain a short progress text so nodes can show "1/2 lines". The material list hands a material to Godot's drag and drop, and the board area accepts the drop on a node.

| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Resource | `LineState` | Changed | Adds `cells`, the path including both end nodes |
| Resource | `EnchantmentPatternLine` | New | One fixed line in a pattern: the two node indexes and the cells between them |
| Resource | `Enchantment` | Changed | `lines` becomes a list of `EnchantmentPatternLine` instead of index pairs |
| Class | `InscriptionBoard` | Changed | Cell occupancy, a check for each step of a path, placement blocked by lines; segment geometry removed |
| Resource | `EnchantmentCondition` and subclasses | Changed | Adds `progress(ctx)`, for example "1/2 lines" or "1/2 magic nodes" |
| Class | `BoardView` | Changed | Draws paths, the path being drawn and the red blocked cell; requirement labels and progress badges on nodes; drop highlighting |
| Class | `MaterialList` | New | An item list whose rows can be dragged as materials |
| Class | `BoardDropArea` | New | The board's container; passes mouse input to the board view and accepts a dropped material |
| Scene | `inscribing_table` | Changed | Uses the two new classes; node details move to a tooltip that follows the mouse |
| Content | Demo patterns and demo sword | Changed | Nodes spaced out so fixed lines run through cells; the sword's blade widened to fit them |
| Tests | `test_inscription_board` | Changed | Rewritten for paths: steps, blocked cells, placement over lines |

## Save data impact
None. Lines gain a `cells` field, but nothing saves the board yet.

## Alternatives considered
- **Straight lines with bend points.** Closer to the old code, but not what was asked for, and crossing checks stay geometric and fiddly.
- **Our own drag code inside the board instead of Godot's drag and drop.** It would work, but the built-in system gives the drag preview, cancelling and drop checks for free.

## Risks
- **Space on the demo sword.** Lines take cells, so the map fills up quickly. A wider demo map is a content change.
- **Fast mouse moves** can skip cells. The view fills the gap along the hex line.

## How to see it working
1. Run the project (the main scene is the inscribing table).
2. Drag Kindle onto the blade. Press on one of its nodes and drag through cells to a magic node: the line fills each cell.
3. Move back along the line: it shrinks. Drag into another line: the cell turns red and the line stops.
4. Drag Fire stone from the list onto Kindle's flame node. The node shows "0/2" in red, turning green with a tick after two lines.
5. Headless: `godot --headless --path . res://tests/test_inscription_board.tscn`.

## Steps
1. One update to PR #5: board rules and tests, then the view, then drag and drop, then screenshots.
