# Test report: Settings menu

**Date:** 2026-10-20
**Planning sheet:** None. Gavin asked for no planning sheet on this overnight batch.
**PR:** see the PR from `settings-menu`

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `settings-menu` | The settings menu, stacked on #24 (shop loop, which has the sounds) | Yes |

It's one feature, so the feature branch is also the combined branch.

Merge #24 first. After that, this can merge before or after #28 (music) and #31 (UI theme) with no conflict. With #29 (menus), whichever merges second has a small conflict in `project.godot` and `checks.yml`; keep both sides.

## What to test

### Settings menu
**Branch:** `settings-menu`
**Scene to run:** the main scene (`res://day/day.tscn`), or press F6 on any scene

How to test:
1. Run the game and press F10. The settings menu opens over the counter and the clock stops.
2. Accept or refuse a customer to hear a sound, then move the Sound effects slider down and do it again.
3. Set Text size to Larger. The counter, the menu and the inscribing table text all grow at once.
4. Turn Fullscreen on, then off.
5. Close the menu with Close or Esc, quit the game and run it again.

Acceptance criteria:
- [ ] F10 opens the menu and F10, Esc or Close shuts it. The day clock doesn't run while it's open.
- [ ] Master volume and Sound effects change how loud the counter's sounds are. At 0% they're silent.
- [ ] The Music slider is there for the music thread's loops, which play on the Music bus.
- [ ] Small, Normal, Large and Larger change the text size on the counter, the table and the menu, and Normal puts it back exactly.
- [ ] Fullscreen switches the window between fullscreen and windowed.
- [ ] After quitting and restarting, every setting is as you left it (they're kept in `user://settings.cfg`).

Screenshots are in the project files under `prototype/settings/`. The `_with_ui_theme` ones show it merged with #31.

## Known gaps
- F10 is a stand-in until the main and pause menus land; they open the same menu scene.
- A few labels set their own fixed font size (the day's top bar, the small hints on the table), so text size doesn't change them. Moving them onto the theme will fix that.
