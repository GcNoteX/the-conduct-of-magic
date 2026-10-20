# 0007: In-game calendar

**Status:** Approved (2026-10-20)
**Design doc:** §9.7 The wall calendar; §9.2.2 End of the workshop year
**Story:** Year calendar (draft) in the story bible
**PRs:** the in-game calendar PR

## Goal
The player has a personal wall calendar for the apprenticeship year. It lets them look over their plans: seasonal events in town, application day, the acceptance letter, commission deadlines and when customers said they'd come back. It only shows these things. Customers and events follow their own rules, so a customer might come back on a different day than the calendar shows.

## Decided by Gavin
- It follows the **2026 calendar** with real month names and no leap years. The year runs from 1 March 2026 (a Sunday) to 28 February 2027.
- Seasons are northern-hemisphere: Spring is March to May, Summer June to August, Autumn September to November, and Winter December to February.
- It's a **personal calendar**. Character visits don't go on it.
- It shows **seasonal events**, starting with sample ones.
- It's **not the source of truth**. It's a view of plans and expectations, and no system reads the calendar to decide what happens.
- Later it may be where the player changes their work schedule: how much of a day goes to the workshop and how much to inscribing.

## Scope
**In:**
- The current date, moving forward one day at a time.
- A calendar panel showing one month at a time, like a real wall calendar. Today is highlighted, the season is shown, and each entry has an icon on its day with a tooltip. Arrows page through the months.
- **Fixed entries** set by designers in the inspector: seasonal events, application day (with its cost and a countdown) and the acceptance letter.
- **Entries added while playing**: a commission deadline, or the day a customer said they'd come back. Other systems add them through one call. They're reminders only, and nothing reads them back.
- A demo scene with "Next day", "Add a test deadline" and "Add a test customer return" buttons, so it can be tried before commissions exist.
- Headless tests for the date maths: month and season roll-over, 2026 weekdays, and days until an entry.

**Out:**
- What happens on an event day.
- The commission system itself.
- Changing the work schedule from the calendar (question 5).
- Hanging it on the workshop wall, since there is no workshop scene yet.
- Saving and loading, since there is no save system yet.
- The calendar pick for negotiating dates (§5.6). It can reuse this panel later.

## Design questions for Gavin
All answered with the recommendation (approved 2026-10-20).

| # | Question | Answer |
|---|---|---|
| 1 | Sample seasonal events? | **One per season as placeholders:** Spring market (18 April), Midsummer festival (21 June), Harvest fair (26 September) and Winter lights (19 December). They only show on the calendar until the real ones are written. |
| 2 | When is application day? | **Placeholder: 1 February 2027**, with its cost and "N days left" shown. That leaves Winter to save up. The real date and cost are set in the inspector. |
| 3 | When does the acceptance letter arrive? | **The last day of the year, 28 February 2027.** |
| 4 | What happens to an entry once its day has passed? | **It stays, greyed out**, so the player can look back. The system that added it can remove it, for example when a commission is cancelled. |
| 5 | Should the first version let the player set how much of a day goes to the workshop and how much to inscribing? | **Not yet.** It depends on the day structure. The per-day schedule (all counter, all inscribing, or a split) is being planned with the Day scene in the Customer service thread. Once it exists, the calendar's day cells will edit that same schedule, not a separate one. |
| 6 | Does the calendar show every seasonal event from the start, or only ones the player has heard about? | **Everything for now.** A "hidden until known" flag can come later. |
| 7 | How does the player open it in this first version? | **A key (C) and a button in the demo scene.** Later it hangs on the workshop wall. |

## Approach
A `GameCalendar` autoload owns the current date as a day number, where day 0 is 1 March 2026. It turns that number into a month, day of month, weekday and season using the 2026 calendar. `advance_day()` moves the date on and emits `day_changed`, plus `season_changed` when a season rolls over. A `CalendarDefinition` Resource holds the designer-set data: the start of the year and the fixed entries. Each fixed entry is a `CalendarEntryDefinition` with a date, a type (seasonal event, application day, letter), a title, details and an optional cost. Entries added while playing are `CalendarNote` instances held by the autoload, not exported. `add_note()` and `remove_note()` emit `notes_changed`. The `CalendarPanel` reads the date and entries and never changes them.

| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Autoload | `GameCalendar` | New | Owns the current date and the notes. `advance_day()`, `add_note()`, `remove_note()`, `days_until()`, and what's on a given day |
| Signal | `day_changed`, `season_changed`, `notes_changed` | New | Lets the panel, and later the shop day, react |
| Resource | `CalendarDefinition` | New | Start of the year, the date maths and the fixed entries |
| Resource | `CalendarEntryDefinition` | New | One fixed entry: date, type, title, details, cost |
| Class | `CalendarNote` | New | A deadline or expected customer return added while playing: date, type, text |
| Resource | `apprenticeship_year.tres` | New | The year with the sample entries above |
| Scene | `calendar_panel.tscn` | New | The wall-calendar UI, one month at a time |
| Scene | `calendar_demo.tscn` | New | The panel plus the test buttons |
| Test | `test_game_calendar` | New | Headless checks for the date maths and notes |

## Save data impact
None yet. When saving exists, the calendar adds the current day number and the list of notes.

## Alternatives considered
- **Let the calendar own customer returns and deadlines.** It would be simpler to wire up, but it would make the calendar the source of truth, which was ruled out.
- **Notes as Resources.** They change while playing, and the rules keep runtime state out of designer data, so they're plain instances instead.

## Risks
- A real year has 365 days, which is long if every day is played. The pacing question may make "next day" skip ahead. The autoload keeps that in one place, so it can jump several days at once.
- Sample dates will move as the story is placed.

## How to see it working
Run `calendar/calendar_demo.tscn`. The calendar opens on Sunday 1 March 2026 in Spring. Press "Next day" and today moves. After 31 May the season turns to Summer. Add a test deadline and a test customer return and check they show on the right days with tooltips. Page to February and check that application day shows its cost and days left. Run `tests/test_game_calendar.tscn` headless for the checks.

## Steps
1. One PR: the autoload, the Resources and `CalendarNote`, the year data, the panel, the demo scene, the tests, this sheet and a test report. It also adds the design doc entry for the in-game calendar (§9.7).
