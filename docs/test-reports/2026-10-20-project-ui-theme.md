# Test report: Project-wide UI theme

**Date:** 2026-10-20
**Planning sheet:** [0008: Project-wide UI theme](../plans/0008-project-ui-theme.md) (built without sign-off, as asked)
**PR:** #31

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `claude/project-thread-naec78` | The project theme | Yes |

It's a single feature, so there's no combined branch. #24 is merged, so this PR now targets main.

## What to test

### The project theme
**Branch:** `claude/project-thread-naec78`
**Scene to run:** the main scene (F5), then `res://calendar/calendar_demo.tscn` (F6)

How to test:
1. Press F5. Play the counter for a customer or two, then press F2 to switch to the inscribing table.
2. Hover over a few things that have tooltips (a material card, a board node, the sidebar handle).
3. Open `calendar/calendar_demo.tscn` and press F6. Press **Next week** twice, add a test deadline and a test customer return, and hover over some days.
4. Double-click `ui/main_theme.tres` in the FileSystem dock. The Theme editor opens at the bottom. Change `CalendarToday`'s panel colour, then run the calendar again.

Acceptance criteria:
- [ ] Every screen uses the new font, Atkinson Hyperlegible. Its zeros have a slash (0), which is part of the font's design.
- [ ] The counter looks as it did in #24: wood buttons, dark panels, parchment papers, big customer name, gold money. Its base text is a little smaller, 22 px instead of 24.
- [ ] The inscribing table uses the same wood buttons. Its text is bigger than before and nothing is cut off. The sidebar shows both the **Enchantments** and **Materials** tabs.
- [ ] Every tooltip has a solid light paper background with a dark border and dark text. You can't see the board through it.
- [ ] The calendar's dates and entries are easy to read: bold dark day numbers, gold weekday names, and coloured entry text on light cells. Today has a gold cell with a border, and past days are grey.
- [ ] A change made in the Theme editor shows up the next time you run the scene, with no code changed.

### Theme checks
**Run:** `godot --headless --path . res://tests/test_ui_theme.tscn`

Acceptance criteria:
- [ ] It prints **23 checks, 0 failed**.

## Known gaps
- Other screens still set some sizes and colours in their own code (the inscribing table, the sidebar, the counter's spacing). They'll move onto the theme as they're worked on.
- There is no decorative heading font yet. The guide suggests one later, for titles only.
