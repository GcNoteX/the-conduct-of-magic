# Test report: Remove the old play map and workplace

**Date:** 2026-10-23
**Planning sheet:** [0009](../plans/0009-remove-old-play-map.md)
**PR:** the `remove-old-play-map` PR

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `remove-old-play-map` | The removal | Yes |

This is a single change, so it has no separate combined branch. Merge it last in the merge plan, after #35.

## What to test

### Old code removed, game unchanged
**Branch:** `remove-old-play-map`
**Scene to run:** `res://inscribing/inscribing_table.tscn` (the main scene)

How to test:
1. Close Godot, delete the project's `.godot` folder, then open the project. That clears the old class list.
2. Check the Output panel for errors while it imports.
3. Open Project Settings > Autoload.
4. Run the main scene. Carve an enchantment, place a material, then switch to Disenchant and plan a dissolve.

Acceptance criteria:
- [ ] The project opens with no parser or missing-resource errors.
- [ ] Autoload lists only `PlayerManager` and `GameCalendar`.
- [ ] The FileSystem dock has no `workplace`, `player_cursors`, `map_nodes`, `map_lines`, `map_detectors`, `map_item`, `mocking` or `npc` folders, and no `play_map.tscn`.
- [ ] Carving, materials and disenchanting work as before.
- [ ] `enchantments/scenes/kindle.tscn` still opens, snaps nodes and bakes.

## Known gaps
- When this merges after the other open PRs, any of them that uses something deleted here has to be fixed in this PR first. The DevLog change edits `EmapUpdateManager` (keep the deletion). `drive_table` and `AutoCarver` use the `Conditon` classes, which stay.
- CLAUDE.md still gives `LineDetector` and `MaterialHolder` as examples of components. Both are deleted here, so that line needs new examples.
