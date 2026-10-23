# 0010: Studio splash and title screen

**Status:** Approved (2026-10-23). Gavin approved building with the recommended answers.
**Design doc:** none yet. The design doc doesn't cover what happens when the game starts.
**PRs:** one draft PR, stacked on #29 (Main menu, pause menu and save/load)

## Goal
When the game launches, the player sees a short studio splash. It fades into the main menu from #29, which now has title art behind it: the game's name over a pixel-art view of the workshop.

## Scope
**In:**
- A splash scene that fades the studio name in, holds it, then fades out. It runs on every launch, and any key or click skips it.
- Title art behind the main menu: a logo with the game's name and a pixel-art workshop background, both placeholders.
- A small tool that generates the placeholder PNGs, so they can be redrawn in another palette or size.
- The engine's boot splash set to the same plain background, so there's no white flash before the splash.
- A test: the splash hands over to the main menu after its time, and straight away on a key press.

**Out:**
- Final art, and any art-style change to the counter or the table.
- Title music. That comes from the placeholder music thread once it lands.
- A credits screen.

## Design questions for Gavin
Answered with the recommendations:
- **Studio name:** the placeholder text "Studio name" until Gavin picks one.
- **Title screen:** title art behind the main menu, with no separate "press any key" screen.
- **Art style:** pixel art, drawn small and scaled up crisply, as a style test for these two screens only.
- **Splash timing:** about 2.5 seconds on every launch, skippable with any key or click.

## Approach
The splash becomes the project's main scene. It runs its own clock (fade in, hold, fade out), then calls `SaveManager.open_main_menu()`. A key press or click jumps straight to the menu. The main menu adds two `TextureRect`s, one for the background and one for the logo. Pixel textures use nearest filtering so they stay sharp when scaled up. Timings and paths are named constants.

| Kind | Name | New / changed | Purpose |
|---|---|---|---|
| Scene + class | `SplashScreen` (`menus/splash_screen.tscn`) | New | Shows the studio name, then opens the main menu |
| Scene + class | `MainMenu` | Changed | Title background and logo behind the buttons |
| Autoload | `SaveManager.quit_to_main_menu()` | Renamed to `open_main_menu()` | The splash opens the menu the same way the pause menu does |
| Setting | `run/main_scene`, `application/boot_splash/*` | Changed | Start on the splash, with a plain boot splash in the same colour |
| Art | `art/title/*.png` | New | Placeholder pixel-art background, logo and studio mark |
| Tool | `tools/make_title_art.tscn` | New | Regenerates the placeholder PNGs headless, in GDScript like the other tools |
| Test | `tests/gut/test_splash.gd` | New | The splash hands over after its time, and straight away on a key press or click |

## Save data impact
None. The splash reads and writes nothing.

## Alternatives considered
- **Use only Godot's built-in boot splash.** It shows while the engine loads, but it can't fade or hold for a set time. It's kept only as a plain background so there's no flash.
- **A separate "press any key" title screen.** It's one more screen between launch and play, and easy to add later.

## Risks
- The pixel art may not suit the rest of the game. These are two screens only, so the change is cheap to undo.
- #27 (Settings) and #31 (UI theme) also edit `project.godot`. Whichever merges last needs a small conflict resolved there.

## How to see it working
1. Press F5. The studio name fades in and out, then the main menu appears with the title art.
2. Press F5 again and press any key during the splash. The menu appears straight away.
3. The GUT tests include `tests/gut/test_splash.gd`.

## Steps
1. One draft PR, stacked on #29: the splash, the title art, the art generator and the test.
