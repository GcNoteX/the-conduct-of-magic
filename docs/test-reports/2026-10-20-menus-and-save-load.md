# Test report: Main menu, pause menu and save/load

**Date:** 2026-10-20
**Planning sheet:** None. Gavin asked for this overnight batch to go straight to a PR.
**PR:** [#29](https://github.com/GcNoteX/the-conduct-of-magic/pull/29), stacked on #24 (End-to-end shop loop), which is stacked on #20

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `claude/project-thread-co4f0w` | Menus and save/load, on top of #24's shop loop | Yes |

One feature, so the feature branch is also the combined branch.

## What to test

### Main menu, pause menu and save/load
**Branch:** `claude/project-thread-co4f0w`
**Scene to run:** the project's main scene (F5), which is now `res://menus/main_menu.tscn`

How to test:
1. Press F5. With no save yet, the menu shows New game and Quit only.
2. New game. Accept Elsa, refuse Bram, buy a stone. Note the money and the clock.
3. Press Escape (or the Menu button top right). The game pauses: the clock stops and the counter dims.
4. Press Save. "Saved." appears. Resume, and the clock carries on.
5. Escape again, then "Save and quit to main menu". The menu now shows Continue with "Day 1, saved <date time>".
6. Continue. You're back at the counter with Ines up next, the same money, the stone you bought and the same time left.
7. F3 to the table, carve one of Elsa's enchantments, then Escape and "Save and quit the game". Start the game again and Continue: you're at the table with the carving there and the table's clock where it was.
8. F3 to the day-over screen, quit from the pause menu, Continue. You start day 2 at the counter, and Elsa comes back to collect and pays as before.
9. On the main menu with a save, press New game. A dialog asks before replacing the save.
10. At the table, pick up an enchantment and press Escape. It's put down and the pause menu does not open. Press Escape again to open it.

Acceptance criteria:
- [ ] The game starts on the main menu. Continue only shows when there is a save, with the day and when it was saved.
- [ ] New game over an existing save asks first.
- [ ] Escape and the Menu button open the pause menu, which pauses the clock. Escape or Resume closes it.
- [ ] Save, "Save and quit to main menu" and "Save and quit the game" all save. Continue picks up on the same day, side and time left, with the same money, materials, items, carvings and commissions.
- [ ] Customers already accepted or refused today don't come back after Continue. The next one in line steps up.
- [ ] A save made on the day-over screen continues at the start of the next day.
- [ ] A run started from the main menu autosaves at the start and end of each day. Running `day/day.tscn` on its own (F6) never touches the save.
- [ ] Escape at the table puts down a held enchantment or line first, and only opens the menu when nothing is held.
- [ ] `tests/test_save_load.tscn` passes 46 checks.

## Known gaps
- **Settings:** the Settings button appears on both menus once the Settings menu thread adds `res://settings/settings_menu.tscn`. Until then it is hidden.
- **One save slot.** New game replaces it.
- **Not saved:** which item the table had open (it reopens on the first item), anything held in the hand, and the wall calendar's date and notes. The calendar isn't driven by the day loop yet, so there's nothing to keep in step.
- **Where the save lives:** `user://saves/run.tres`. On Windows that's `%APPDATA%\Godot\app_userdata\The Conduct of Magic\saves\`. Delete it to get a fresh start.
- **Old saves:** a save with a different format version is refused, and the menu says so. Saves only point at the game's own `res://` files; a save carrying code or pointing elsewhere is refused.
