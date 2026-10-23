# Test report: Tests for the day, counter, shop and economy

**Date:** 2026-10-23
**Planning sheet:** Not macro work (tests only, and Gavin asked for this overnight batch without sheets)
**PR:** #43

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `day-counter-tests` | Everything below. Branches from `main`, which now has the day and counter (#20) and the shop loop (#24) | Yes |

One feature, so this branch is also the combined branch.

The shop loop, economy and customer job tests used to wait in #35 because they needed #20 and #24. Those are on `main` now, so they moved here, and #35 keeps only the save/load tests, which still need #29.

## What to test

### Running the tests
**Branch:** `day-counter-tests`
**Scene to run:** none, it's a command

How to test:
1. Run `godot --headless --path . -s addons/gut/gut_cmdln.gd`, or press Run All in the GUT panel.
2. Look at the PR's checks: the "Run GUT tests" step runs the new scripts.

Acceptance criteria:
- [ ] All tests pass, with 3 pending (the known Ward jobs, see Known gaps), in about 10 seconds.
- [ ] The CI checks are green on the PR.

### Counter rules (`tests/gut/test_counter_rules.gd`)
Acceptance criteria:
- [ ] Keen or Kindle without an ID is refused by the rules; any ID will do for that rule.
- [ ] A tier below the minimum breaks the tier rule; exactly the minimum is fine.
- [ ] Kindle needs a permit that covers it and lists the customer's kingdom.
- [ ] An ID or permit is valid on its last day and not the day after, and must be in the customer's exact name.
- [ ] The rulebook lists every reason, in the order its rules are written.
- [ ] A call is right exactly when accepting matches "no problems".

### Who comes to the counter (`tests/gut/test_counter_queue.gd`)
Acceptance criteria:
- [ ] Each demo day brings its own customers in the order listed, and nobody after day 3.
- [ ] Customers not served by the end of the day leave for good.
- [ ] Collectors come before new customers, in the order they were accepted.
- [ ] A collector not handed their item comes back every day until they are, then never again.
- [ ] Each day's calls and collections start empty.
- [ ] Accept, Refuse and Hand back do nothing when there's no one for them, and Accept does nothing while someone is collecting.
- [ ] The counter signals each call and each collection.

### The day's clock (`tests/gut/test_day_clock.gd`)
Acceptance criteria:
- [ ] Each day gets its plan; days past the schedule repeat the last; an empty schedule gives a day with no time, which is over at once.
- [ ] Running past the counter's time doesn't eat into the table's, and no clock goes below zero.
- [ ] A finished day stays finished until the next one starts, with a full clock.
- [ ] Switching sides costs no time, and money, stones and items carry over to the next day.

### Shop loop and economy (`tests/gut/test_shop_loop.gd`, `tests/gut/test_economy.gd`, `tests/gut/test_customer_jobs.gd`)
These are the same tests that were in #35.

Acceptance criteria:
- [ ] Accepting brings the customer's item in; refusing brings nothing in.
- [ ] A job carved with stones bought at the supplier pays exactly the agreed price; a half-done job pays a share, an uncarved one nothing.
- [ ] Three demo days end with money equal to the start, less stones, plus pay.
- [ ] Every demo job, and each enchantment's share of it, pays more than its stones; spending past zero is refused; 300 random purchases never sell on credit.
- [ ] Each demo customer's whole job carves on their item, except the three known ones, and each enchantment on it can be taken off with the starter stock.

## Known gaps
- Ward still doesn't fit on the Dagger or the Short sword, so Elsa's, Tomas's and Jory's jobs show as pending.
- Loading the demo sword still prints "Kindle changed shape" (its saved carving predates Kindle's third node). It's a warning, not a failure.
- `tests/test_day.tscn` still runs in CI as before. The new GUT tests add to it and don't repeat its checks.
