# Test report: Placeholder music

**Date:** 2026-10-20
**Planning sheet:** None. Gavin asked for this one to go straight to a PR without a sheet.
**PR:** https://github.com/GcNoteX/the-conduct-of-magic/pull/PR_NUMBER

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `claude/project-thread-2k4j2o` | Placeholder music, stacked on the shop loop (#24) | Yes |

One feature, so the feature branch is also the branch to test. It is stacked on #24 because #24 added the sound effects this puts on their own bus.

## What to test

### Music for the counter and the table
**Branch:** `claude/project-thread-2k4j2o`
**Scene to run:** `res://day/day.tscn` (the main scene, so F5 works)

How to test:
1. Run the game. The day starts at the counter with a light folk tune: plucked lute, a recorder melody, bass and a soft drum.
2. Let it play for more than 40 seconds. It loops back to the start with no gap or click.
3. Press F2 to go to the table. Over about 1.5 seconds the counter tune fades out and a slow, calm loop of pads and glassy bells fades in.
4. Press F2 again. The counter tune fades back in.
5. Accept or refuse a customer and buy a stone. The sound effects still play over the music, a little louder than it.
6. Open the Audio panel at the bottom of the editor. There are Music and SFX buses, both sending to Master. Lower or mute one while the game runs: only the music, or only the sound effects, changes.

Acceptance criteria:
- [ ] The counter and the table each have their own music, and it starts with the day.
- [ ] Switching sides cross-fades between the two tracks with no silence in the middle.
- [ ] Both tracks loop without a gap or click (counter 40 s, table 58 s).
- [ ] Music is on the Music bus and sound effects on the SFX bus, so each can be turned down separately.
- [ ] The music sits under the sound effects and doesn't get tiring after a few loops.

## Known gaps
- The music is generated placeholder audio, made by `tools/placeholder_audio/make_placeholder_music.py`. It is meant to be replaced.
- There are no volume sliders yet. The Settings menu thread adds them, using these buses.
- The day-over screen keeps the last side's music playing; it has no track of its own.
