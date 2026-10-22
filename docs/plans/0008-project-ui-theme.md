# 0008: Project-wide UI theme

**Status:** Built without sign-off at Gavin's request (2026-10-20). It follows the recommendations in the [UI themes guide](https://claude.ai/code/artifact/6354bfbc-f04e-4383-a244-e8c092e366f8).
**Design doc:** none (presentation only)
**PRs:** the project UI theme PR, stacked on #24

## Goal
Every screen shares one look, set in one Theme resource that can be tuned in the Theme editor. Text is easier to read, and tooltips have a solid background.

## Decisions (the guide's recommendations)
| # | Question | Answer used |
|---|---|---|
| 1 | One project-wide theme, or a theme per screen? | One project theme, `ui/main_theme.tres`, set in Project Settings > GUI > Theme > Custom |
| 2 | Move styling out of code? | Yes. Code picks a look by type variation name, using the constants in `UiStyles` |
| 3 | Font? | Atkinson Hyperlegible (SIL Open Font License), regular and bold |
| 4 | Body text size? | 22 px (see "Changed from the guide") |
| 5 | Tooltip look? | Opaque light paper with a dark brown border and dark text |
| 6 | When? | Now: the theme, the font, tooltips, the calendar, and the counter's theme folded in |

## Changed from the guide
- **Body text is 22 px, not 20.** The counter asked for bigger text (24 px in #24), and the inscribing table was built for 16 px. 22 keeps the counter close to what was asked for and still fits the table.
- **The counter's own theme is gone instead of kept as a screen theme.** Godot looks at a screen's own theme first. A screen theme that changes only the base text size also hides every type variation in the project theme, so the counter's titles lost their size. One theme avoids that, and it's a rule worth keeping: a screen theme has to be a complete theme, not a small patch.
- **Panels have 12 px padding instead of the counter's 20**, so the inscribing sidebar's tabs still fit. Tabs use 18 px text.

## Approach
| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Resource | `ui/main_theme.tres` | New | The project theme: the counter's look (wood buttons, dark panels, parchment), the font, paper tooltips, and the calendar's styles |
| Font | `ui/fonts/AtkinsonHyperlegible-*.ttf` | New | Regular and bold, with `OFL.txt` |
| Class | `UiStyles` | New | Named constants for every type variation |
| Setting | `gui/theme/custom` | New | Points the project at the theme |
| Resource | `counter/counter_theme.tres` | Removed | Folded into the project theme |
| Scene | `counter/counter.tscn` | Changed | No longer sets its own theme |
| Class | `CalendarPanel` | Changed | Uses type variations instead of colours and sizes in code |
| Test | `test_ui_theme` | New | The project uses the theme, every `UiStyles` name exists in it, and the tooltip is opaque |

## Save data impact
None.

## Risks
- Every screen's buttons and panels now use the counter's wood and dark style, including the inscribing table.
- Code in other screens still sets some sizes and colours itself. Those screens move onto the theme as they're worked on.

## How to see it working
Run the game (F5) and play the counter and the table. Run `calendar/calendar_demo.tscn` and hover over a day. Open `ui/main_theme.tres` to see the Theme editor. Run `tests/test_ui_theme.tscn` headless.
