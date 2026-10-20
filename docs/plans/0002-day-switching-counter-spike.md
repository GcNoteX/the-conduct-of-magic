# 0002: Day switching and counter spike

**Status:** Approved (2026-10-19)
**Design doc:** §3 Core loop, §4 The shop day, §5.1 Lifecycle, §9.2.1 Working the counter
**PRs:** PR 1 (Day and freeze and swap), PR 2 (the counter spike), links once open

## Goal
A spike to find out whether the customer side works as the game's medium. The player serves mock customers at a counter and accepts or refuses their commissions. Accepted items go to the inscribing table. A day can be all counter, all inscribing or split between them. In dev builds a hotkey freezes one side and jumps to the other.

## Scope
**In:**
- A Day scene above both sides. It owns the player, the day count, the day clock and which side is active.
- A day schedule: each day says how its time splits between counter and inscribing (all counter, all inscribing, half and half, or another ratio).
- Freeze and swap: the inactive side is hidden and paused, so it resumes exactly where it was.
- A dev hotkey (debug builds only) that jumps between sides whatever the schedule says.
- A counter with mock customers. Each one lays out a commission slip, sometimes an adventurer ID or a permit, and usually an item.
- A rulebook panel the player reads to check the papers.
- Accept or Refuse. The customer's item sits on the counter while you decide. A refused item goes back to the customer, and an accepted one goes to the inscribing table.
- An end-of-day summary that lists each call and whether the rulebook agreed with it.

**Out:**
- Flagging mismatches by linking fields (the stamp is enough to test the medium).
- Price and deadline negotiation, and Mr. Leywin's part at the counter.
- Customers coming back to collect, money, reputation and consequences.
- The isometric shop floor and NPCs walking in.
- Saving.

## Design questions for Gavin
Settled in the thread: a day can be all counter, all inscribing or a split. The player can't jump between sides in the real game, only with the dev hotkey. Gavin approved the answers below for the spike.

| # | Question | Answer |
|---|---|---|
| 1 | On a split day, which side comes first? | Counter first, then inscribing, one way only. Customers come by day and the work is done after (§3). |
| 2 | What ends a side? | One day clock. Each side gets its share of the clock from the schedule. When the counter's share runs out, any waiting customers leave and the day moves on to inscribing. When inscribing time runs out, the day ends. |
| 3 | Where does a customer's item sit while you decide? | It lies on the counter while you inspect it. Refuse, and it is handed back. Accept, and it moves to the inscribing table's item list. |
| 4 | What happens to the old workplace scene (`workplace/`, its cursors and channel and workstation forms)? | Build the counter fresh as a Control scene, the way the inscribing table is built, and leave `workplace/` untouched in this work. Delete it in a follow-up PR once the spike shows the counter is worth keeping. |
| 5 | Where do the mock customers come from? | A short hand-written list of visits for the demo, about six, mixing clean requests with an expired ID, a tier too low and a missing permit. The existing `npc/` resources stay as they are. |

## Approach
A new Day scene becomes the main scene and holds the Counter and the InscribingTable as children. Day owns the player, the day number and the clock. It reads today's plan from a schedule and decides which side is active. Switching hides the other side and sets its process mode to disabled, so its state and input simply stop until it is shown again. Day calls down into each side to open it with the player. The Counter signals up when a visit is decided, and Day then hands an accepted item to the player's items, so the table lists it the next time it opens. The table stops creating its own player and running its own timer, and Day shows the clock and the end-of-day panel. Counter rules are Resources, so the rulebook is data you can edit in the inspector.

| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Scene + class | `Day` (`day/day.tscn`) | New | Root of a day. Owns the player, day number, clock and active side; switches sides; dev hotkey; end-of-day summary |
| Resource | `DayPlan`, `DaySchedule` | New | Seconds for the counter and for inscribing on each day. The demo repeats a split day: 5 minutes at the counter, then 60 at the table |
| Scene + class | `InscribingTable` | Changed | Opened by Day with the player. Its own player setup, timer and day-over panel are removed |
| Scene + class | `Counter` (`counter/counter.tscn`) | New | Shows the current customer's papers and item, the rulebook panel, and Accept and Refuse. Signal `visit_decided(visit, accepted)` |
| Resource | `CustomerVisit` | New | One mock customer: name, slip, optional ID, optional permit, optional item |
| Resource | `CommissionSlip`, `AdventurerId`, `Permit` | New | The papers. Slip: enchantment wanted and the item. ID: name, tier, kingdom, expiry day. Permit: holder, enchantments covered, issuer, kingdoms, expiry day |
| Resource | `CounterRule` and subclasses | New | `check(visit, day) -> String` returns why a visit breaks the rule, or empty. First rules: ID required, tier high enough, permit for controlled enchantments, not expired |
| Resource | `Rulebook` | New | The rules in order, each with the text shown in the panel |
| Content | `counter/demo/` | New | About six visits and the demo rulebook |
| Project | `project.godot` | Changed | Main scene becomes Day. New input action `dev_switch_side`, read only in debug builds |
| Tests | `test_day`, `drive_table` | New / changed | Headless: switching freezes the clock, accept moves the item, refuse returns it. `drive_table` opens the table through Day |

## Save data impact
None. Nothing is saved yet. Accepted items are appended to the player's existing `items` list, so `Player` keeps its shape.

## Alternatives considered
- **Change scenes on each switch.** Loading one scene in place of the other throws away the frozen side, so every state would need to live in an autoload. Keeping both scenes loaded and pausing one is simpler and is exactly the freeze asked for.
- **A day-manager autoload.** It would also work, but it puts day state in a global. A root Day scene keeps calls going down and signals going up, and a test can build a whole day on its own.

## Risks
- **The table assumes it is the root.** It sizes the board from the viewport and sets the mouse mode in `_ready`. Inside Day it has to size from its own rect and set up when opened, not when loaded.
- **A drag in progress when you switch.** A material or enchantment held on the table must be dropped and cancelled before the table is frozen.
- **The spike may say no.** That is the point of a spike. The Day scene and freeze and swap are still needed whatever the counter becomes, so the first PR isn't wasted.

## How to see it working
1. Run the project. Day 1 opens on the counter with the first customer.
2. Read the slip and ID against the rulebook, then press Accept or Refuse. A refused item leaves with the customer.
3. When the counter's share of the clock ends, the day moves to the inscribing table, and the accepted items are in its item list.
4. Press the dev hotkey (F2) to jump back to the counter. The table's clock and plans stay exactly as you left them. Press it again to return.
5. At the end of the day, the summary lists each call and whether the rulebook agreed.
6. Headless: `godot --headless --path . res://tests/test_day.tscn`.

## Steps
1. **PR 1: Day and freeze and swap.** The Day scene, the schedule, the dev hotkey, and the table opened by Day. The counter side is a placeholder button that hands over a demo item.
2. **PR 2: The counter spike.** Papers, the rulebook, rules, demo visits, Accept and Refuse, and the end-of-day summary.
