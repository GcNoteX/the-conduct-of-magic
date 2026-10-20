# The Conduct of Magic: working rules

Godot 4.7 (GDScript) game. The game design lives in [docs/design/game-design.md](docs/design/game-design.md).

Gavin is the designer. Only decisions he has confirmed go into documents, including this file and the design doc. Offer options and recommendations in conversation; write them down only after he confirms.

## Pipeline

1. **Design doc.** Gameplay decisions come from the design doc. If a task needs a design decision the doc doesn't settle, ask Gavin rather than inventing one.
2. **Planning sheet (macro work only).** Before writing any code for macro work, draft a planning sheet (format below) and get Gavin's approval.
3. **Branch and draft PR.** One branch per piece of work, with a readable name that says what it is (`map-editor`, `disenchanting-rules`). Open the PR as a draft.
4. **Checks.** The PR must pass the automatic checks (see "Checks").
5. **Review and merge.** Gavin reviews and merges. Claude never merges.

**Macro work** is anything that adds or reshapes a system:
- a new autoload, or a change to what an existing one owns;
- a new or changed Resource schema, or anything that changes save data;
- scene structure (what owns what, how scenes load each other);
- new signals between systems;
- a change across more than about 3 files.

Bug fixes, renames and one-function changes are not macro work. They skip the sheet and go straight to a PR.

## Planning sheets

- Copy [docs/plans/TEMPLATE.md](docs/plans/TEMPLATE.md). Keep it to about one page.
- Draft it as a Claude Doc so Gavin can comment inline.
- Once approved, commit it to `docs/plans/NNNN-short-title.md` (next free number) in the same PR as the code it describes, so later work can read it.
- Code follows the approved sheet. If the plan has to change mid-way, stop and update the sheet with Gavin before continuing.

## Coding style

Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): tabs, `snake_case` for files, functions and variables, `PascalCase` for `class_name`, `CONSTANT_CASE` for constants, and its ordering of class members. `gdformat` and `gdlint` (gdtoolkit) enforce it.

Principles for this codebase:
- **Static typing everywhere**: typed variables, parameters, return types and arrays.
- **Definition/instance split**: shared, immutable data in a `*Definition` Resource; per-object mutable state in an instance (as with `ItemDefinition` and `ItemInstance`).
- **Rules and conditions as Resources**, so they stay data-driven and editable in the inspector.
- **Components over deep inheritance**: small nodes that do one job (like `LineDetector`, `MaterialHolder`).
- **The cursor owns input** ("cursor is the brain"): player input is decided in the cursor, not in the things being hovered.
- **Signals go up, direct calls go down**: a node calls its children, children signal their parents.
- **No bare strings or magic numbers** for groups or collision layers: use named constants, and name layers in Project Settings.
- **No runtime state in `@export`**: exports are for designer-set data only.
- **No commented-out code**: delete it, git keeps history.
- **A `##` doc comment on every `class_name`** saying what the class is for.

## Merge policy

- `main` is protected. Every change goes through a PR.
- Only Gavin merges.
- A PR is mergeable when its checks are green and Gavin has approved it. A macro PR also links its approved planning sheet.
- One planning sheet maps to one PR, or to a short series of PRs listed in the sheet.
- Code PRs are squash-merged, so each change is one commit on `main`.

## Checks

Run these locally before pushing. CI runs the same on every PR.

- **Lint and format**: `pip install gdtoolkit==4.5.0`, then `gdformat --check <files>` and `gdlint <files>` on the `.gd` files you changed. CI only checks changed files, so a file you touch is brought up to style as part of that change.
- **Script check**: Godot 4.7.2 headless. `godot --headless --path . --import`, then `godot --headless --path . res://tools/ci/check_scripts.tscn`. It loads every project script (skipping `addons/` and `demo/`) and fails if any doesn't compile.
- **Rule tests**: `godot --headless --path . res://tests/test_inscription_board.tscn`. It exits with an error if any check fails. Add checks there when you change the inscribing rules.
