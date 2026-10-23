# 0009: Remove the old play map and workplace

**Status:** Approved (2026-10-23), with the recommended answer to each question
**Design doc:** none. This removes code from before the hex inscribing table and adds no gameplay.
**PRs:** one PR, `remove-old-play-map`. It replaces the clean-up PRs #37 to #41, which are closed.

## Goal
The project contains only what the inscribing table, counter, day loop, disenchanting and their tests use. The free-placement play map, the workplace and the code only they needed are gone, so nobody has to keep them building or following the house rules.

## Scope
**In:**
- Delete `play_map.tscn`, `enchantment_map.tscn` and their scripts, the empty `main.tscn`, and the folders `workplace/`, `player_cursors/`, `map_nodes/`, `map_lines/`, `map_detectors/`, `map_item/`, `attribute_components/`, `animation_components/` and `mocking/`.
- Remove the autoloads that only served the old map: `SceneReferences`, `UtilityFunctions`, `EmapUpdateManager` and `Mocker`.
- Delete the old map pieces in `enchantments/`: `EnchantmentGrid`, `MaterialDropper`, the old grid scenes `e1.tscn`, `e2.tscn` and `item1.tscn`, and the old-map half of `MaterialActivationContext`.
- Delete the item and material scenes only the workplace used (the `*_cf` and `*_wsf` scenes, `items/enchantable_items_definitions/`, `items/custom_enchantables/`).
- Drop the fields that pointed at that code: `ItemDefinition.iso_sprite_normal`, `workstation_form` and `channel_form`, and `Enchantment.map`. Re-save the `.tres` files that set them.
- Remove the project settings only the old map used: the input actions (`toggle`, `left_click`, `right_click` and the cursor and editor toggles), the `enchantment`, `mapline` and `mapnode` global groups, and the physics layer names. Nothing live reads them. *(Added while building.)*

**Out:**
- Anything the table, counter, day, disenchanting, tools or tests use, including the enchantment scene authoring tool (`EnchantmentScene` and its node and line components), `GraphState`, `Player` and `PlayerManager`. A file is removed only if nothing live reaches it.
- Renaming the `Conditon` classes, or other clean-up inside the code that stays.
- The `GODOT Game Reference images/` folder.

## Design questions for Gavin
1. **The `npc/` folder.** Nothing uses it, and the counter has its own customer data. *Answer: delete it.*
2. **The `GODOT Game Reference images/` folder.** *Answer: keep it.*
3. **When to merge.** One open PR (the DevLog change) edits `EmapUpdateManager`, which this deletes. *Answer: build it now and merge it last in the merge plan, after #35.*

## Approach
A script walks every reference in the project (`res://` paths, uids, `class_name` uses and autoload names), starting from the table, counter, day, disenchanting, tools and tests. Anything it can't reach is deleted. The few live files that still pointed at old code through leftover types or fields are cut first, then the script runs again to confirm the old folders are unreachable.

| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Resource | `ItemDefinition` | Changed | Drops `iso_sprite_normal`, `workstation_form` and `channel_form` (workplace only) |
| Resource | `Enchantment` | Changed | Drops `map` (the old `EnchantmentGrid` scene) |
| Class | `MaterialActivationContext` | Changed | Keeps only the board path; the `MapNode`, `EnchantmentGrid` and `EnchantmentMap` fields and fallbacks go |
| Resource | `EnchantmentMaterialDefinition` | Changed | Doc comments stop naming `EnchantmentNode`. No field changes |
| Autoload | `PlayerManager` | Changed | Stops reading from `Mocker` |
| Autoload | `SceneReferences`, `UtilityFunctions`, `EmapUpdateManager`, `Mocker` | Removed | Only the old map used them |
| Scenes and scripts | Old map, workplace, cursors, map items, workplace item forms | Removed | See Scope |
| `.tres` | Resources that set dropped fields | Re-saved | So no stale properties stay in the files |

## Save data impact
None for players. The save system stores the table, counter and day state, and none of the removed fields.

## Alternatives considered
- **Merge the clean-up PRs #37 to #41.** That keeps about 80 files nothing uses, which still have to build and follow the house rules.
- **Move the old code to an `archive/` folder.** The script check would still load it and gdlint would still flag it. Git history already keeps it.

## Risks
- **A hidden live link**, such as a path built at runtime. The script check, every test scene, GUT and a run of `day/day.tscn` would catch a missing class or scene.
- **Editor class cache.** After pulling, Godot may report missing classes until you reload the project or delete `.godot`.
- **Conflicts with open PRs.** Only the DevLog change touches a deleted file; keep the deletion.

## How to see it working
- The project opens with no missing-resource or parser errors, and Project Settings > Autoload no longer lists the four removed autoloads.
- `inscribing_table.tscn` and `day/day.tscn` play as before.
- CI is green: lint, the script check, GUT and the rule tests.

## Steps
1. One PR, `remove-old-play-map`, built on main and merged after #35.
