# ExoFarm — CLAUDE.md

## Status

ExoFarm is in **active design — no implementation exists yet.** The
pre-redesign prototype (mobile/portrait, polyomino grid, union-find power,
Nutrient Paste, morale) has been removed; it remains in git history if ever
needed. Nothing is being built on top of it.

**`full_design/` is the sole source of truth.** Do not reconstruct
requirements, architecture, or terminology from old code or old docs.

- `full_design/00_index.md` — table of contents for the numbered design files
- `full_design/DESIGN_TODO.md` — open gaps and change log
- `full_design/audits/` — per-system design audits
- `full_design/01_design_principles.md` — the design principles (load before
  any design consideration)

## Project

- Single-player roguelike grid-based farm settlement builder.
- **Engine:** Godot 4.6.1, GDScript only (no C#).
- **Platform:** PC first, landscape (see `full_design/03_core_loop_and_grid.md`).
- Organizing body: **SEED** — Survival and Emigration Expedition Dispatch.

## Tone

Cozy pioneering optimism with mild survival tension — an optimistic science
expedition, not post-apocalyptic desperation. Forgiving season-to-season;
critical failure is possible but never an ambush.

## Code Style and Naming Conventions

Carried over from the prototype; revisit when implementation begins.

- **Explicit type annotations on every `var` declaration.** Non-negotiable.
- **Enums instead of integer sentinels** for any discrete multi-valued
  variable; named constants for any other magic numbers.
- **Typed Array assignment from a Dictionary needs `.assign()`, not `=`** —
  `arr = dict["key"]` silently no-ops for a typed array in GDScript 4.
- **Every script declares `class_name`.** Exception: autoload singletons must
  not — Godot registers the node name globally and a matching `class_name`
  conflicts.
- **Use `git mv` to rename source files**, not plain `mv`.
- Scene scripts co-located with their `.tscn`; pure logic under `scripts/`.
- Private helpers `_`-prefixed; public API carries `##` doc comments.
- Signals named `past_tense_verb` (e.g. `piece_placed`, `next_season_pressed`).
