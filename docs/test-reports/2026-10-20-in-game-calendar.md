# Test report: In-game calendar

**Date:** 2026-10-20
**Planning sheet:** [0007: In-game calendar](../plans/0007-in-game-calendar.md)
**PR:** the in-game calendar PR

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `claude/project-thread-naec78` | The in-game calendar | Yes |

It's a single feature, so there's no combined branch. It doesn't touch the inscribing table, so it doesn't need the open feature PRs.

## What to test

### The wall calendar
**Branch:** `claude/project-thread-naec78`
**Scene to run:** `res://calendar/calendar_demo.tscn` (open it and press F6)

How to test:
1. Run the scene. The calendar opens on March 2026.
2. Press **Next day** a few times, then **Next week** until you reach June.
3. Press **Add a test deadline** and **Add a test customer return**.
4. Hover over days that have entries.
5. Page through the months with the arrows, to February 2027.
6. Press C, then press it again.
7. Select `calendar/apprenticeship_year.tres` in the FileSystem dock and change an entry's date or title in the inspector, then run the scene again.

Acceptance criteria:
- [ ] The calendar opens on **March 2026 · Spring**, with 1 March on a **Sunday** and today highlighted in yellow.
- [ ] Months have their real lengths, and February 2027 has **28 days** and starts on a Monday.
- [ ] **Next day** moves the yellow day on by one. Days that have passed turn grey.
- [ ] After 31 May the title reads **June 2026 · Summer**. September is Autumn and December is Winter.
- [ ] A test deadline shows 3 days ahead as "Due: …" in orange. A test customer return shows 2 days ahead as "Expected: …" in purple.
- [ ] The sample events show on their days: Spring market (18 April), Midsummer festival (21 June), Harvest fair (26 September) and Winter lights (19 December).
- [ ] **Application day** is on 1 February 2027 in red. Its tooltip shows its cost (500g) and how many days are left. The footer under the grid shows the same countdown.
- [ ] The **Acceptance letter** is on 28 February 2027 in blue.
- [ ] Hovering a day shows a tooltip with its full date and each entry's details.
- [ ] The arrows stop at March 2026 and February 2027.
- [ ] C hides and shows the calendar.
- [ ] Changing an entry in `apprenticeship_year.tres` changes the calendar the next time you run it.

### Date checks
**Run:** `godot --headless --path . res://tests/test_game_calendar.tscn`

Acceptance criteria:
- [ ] It prints **58 checks, 0 failed**.

## Known gaps
- Nothing happens on an event day yet, since the calendar only shows dates.
- Nothing adds deadlines or customer returns yet, apart from the demo buttons. The commission system will call `GameCalendar.add_note()` once it exists.
- The work schedule isn't on the calendar yet (sheet question 5).
- The calendar isn't saved, and it isn't on the workshop wall yet.
- The leak warnings printed when Godot quits come from the existing autoloads. The existing inscribing tests print the same ones.
