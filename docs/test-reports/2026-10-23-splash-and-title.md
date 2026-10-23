# Test report: Studio splash and title screen

**Date:** 2026-10-23
**Planning sheet:** [0010](../plans/0010-splash-and-title.md)
**PR:** #PR_NUMBER, stacked on #29 (Main menu, pause menu and save/load)

## Branches

| Branch | Contains | Test here? |
|---|---|---|
| `splash-and-title` | The splash and title art, on top of #29 | Yes |

One feature, so the feature branch is also the combined branch.

## What to test

### Studio splash and title screen
**Branch:** `splash-and-title`
**Scene to run:** the project's main scene (F5), which is now `res://menus/splash_screen.tscn`

How to test:
1. Press F5. The window opens dark with no white flash. A gold ring with a blue hex rune and "Studio name" fade in, hold, and fade out over about 2.5 seconds.
2. The main menu appears over a pixel-art workshop at night: a window with the moon, shelves of stones and jars, a candle and a parchment on the bench. "THE CONDUCT OF MAGIC" sits on a wooden plaque above the buttons.
3. Close the game, press F5 again, and press any key or click during the splash. The main menu appears straight away.
4. Everything from #29 still works from this menu: New game, Continue, and the pause menu in a run.
5. Optional: run `res://tools/make_title_art.tscn` headless. It redraws the three PNGs in `art/title/`.

Acceptance criteria:
- [ ] The game starts on the splash, on a dark background with no white flash.
- [ ] The splash fades in, holds and fades out, then opens the main menu by itself.
- [ ] Any key or click skips the splash.
- [ ] The main menu shows the pixel-art workshop and the title plaque, and the pixels are crisp squares, not blurred.
- [ ] The menu buttons and the save line are easy to read over the art.
- [ ] GUT passes, including the 6 tests in `tests/gut/test_splash.gd`.

## Known gaps
- **Placeholders:** "Studio name" is placeholder text (`SplashScreen.STUDIO_NAME`), and all three images are generated placeholders.
- **No music** on the splash or the menu yet. That comes from the placeholder music thread.
- **Pixel art is a style test** for these two screens only. The counter and the table keep their current look.
