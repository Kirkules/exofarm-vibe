# Production & Technical

## Development Standards

### Version Control
- **Git** for version control; private repository on **GitHub**
  (https://github.com/Kirkules/exofarm-vibe)
- **License:** GPL v3 — note: revisit before any commercial release

*Project structure, autoloads, and save strategy moved to
[Code Architecture](07_production_and_technical.md#code-architecture) and [Backend & Data Persistence](07_production_and_technical.md#backend--data-persistence) below.*

### Grid Coordinate System
- Cells addressed as **(row, column)**, 1-indexed, with **(1, 1) at the top-left**
  corner of each grid
- Row increases downward; column increases rightward

### Language
- All game code written in **GDScript** — no C#

*Art style, screen layout, and asset formats moved to [Art Design](07_production_and_technical.md#art-design) below.
Testing conventions moved to [Testing Strategy](07_production_and_technical.md#testing-strategy) below.*

---

## Art Design

### Established
- **Sprites & pixel art:** `.png` — editable in **Krita** (free/open-source); Godot
  imports `.png` natively
- **Audio SFX:** `.ogg` — editable/trimmed in **Audacity** (free/open-source)
- **Music:** `.ogg` — composed in **FL Studio** (proprietary but exports open formats)
  or other tools; format remains portable and editable in free tools

> Art style, exact resolution/sprite size, and screen layout are no longer settled —
> see Platform & Core Loop Redesign above (PC/landscape, FTL/Into the Breach visual
> reference) — and are to be resolved in a full Art Design pass.

**Ambient Mid-Sim visuals for Outside-Sim-resolved activities.** An activity whose
mechanical resolution lives Outside-Sim (see Core Loop & Grid's Season Structure)
can still get a purely ambient visual depiction during the Mid-Sim window, for
legibility/immersion, with no coupling between the two — the visual never affects
or is affected by the actual resolution. Two confirmed examples: a Scanner Station
shows a radio-wave pulse effect centered on the building, repeating every few
seconds throughout the window; an Ore/Deposit Survey shows a settler sprite
wandering the grid and stopping/stooping at unoccupied cells, visually "searching,"
even though the actual reveal resolves Outside-Sim. Feeds into the still-open
"Animation budget" question below — this pattern is a cheap way to make Mid-Sim
feel alive without needing per-building mechanical animation.

### Open Questions — Art Design

> - **Settlers:** how are individual settlers visually represented? Currently
>   ColorRect placeholders during simulation. Distinct sprites per settler? Portraits
>   for the Mission Report / hub?
> - **Buildings & crops:** single static sprite per piece, or idle animation frames
>   (e.g. a panel glint, crops swaying)? Does an unstaffed site look visually
>   distinct from a staffed one?
> - **Color identity:** is there a defined palette (per planet type, or project-wide)?
>   Cozy-but-alien needs a distinct look from generic pixel-farm-game references.
> - **Reference points:** are there specific pixel-art games/palettes to anchor tone
>   against (e.g. Stardew Valley warmth vs. something starker/sci-fi)?
> - **Icon/UI chrome:** is there a defined icon set style for HUD elements (Energy,
>   Matter, worker roster avatars) beyond "pixel font, small sizes"?
> - **Planet identity:** do different exoplanet types get distinct color grading /
>   skybox treatment in the settlement-view background, or is that Phase 5+ scope?
> - **Animation budget:** given single-developer scope, what's the *minimum* animation
>   needed to feel alive (e.g. just the settlement-view ambient loop) vs. nice-to-have?

---

## Code Architecture

### Folder Layout
```
res://
├── scenes/
│   ├── game/       ← main run (grid, simulation, planning UI)
│   ├── hub/        ← Earth hub
│   └── menus/      ← main menu, settings
├── scripts/        ← pure logic scripts with no associated scene
├── resources/      ← Godot Resource files (piece definitions, planet types, recipes)
├── assets/
│   ├── sprites/
│   ├── fonts/
│   └── audio/
└── tests/          ← GUT test files
```

Scene scripts are co-located with their scene files. Pure logic scripts (no scene)
live in `scripts/`.

### Autoloads (Singletons)
- **GameState** — current run data: season number, settler count, inventory,
  Energy, Matter, grid layout, and all other mutable run state; responsible for
  triggering saves
- **Catalog** — known designs and recipes reflecting current meta-progression state
- **EventBus** — global signal bus for decoupled communication between systems
- **Settings** — user preferences: volume levels, drag offset toggle (offsets dragged
  items from the touch point so a finger doesn't obscure them on mobile), and other
  TBD preferences

### Data Definitions
- **Piece/building definitions, planet types, recipes:** defined as typed Godot
  Resource subclasses (`.tres`/`.res`); editable in the Godot editor without touching
  code
- **Pure logic** (grid calculations, rotation, outcome rolls, etc.): GDScript classes

### PIC (PieceInputController) Pattern
Established during the Phase 1/2 refactor (see CLAUDE.md for full detail): a single
`PieceInputController` owns all drag/input state; grids are passive and opt in via
`register_pickup_source` / `register_drop_target`. This pattern should extend to any
new draggable-piece surface introduced during a one-shot implementation, rather than
each new grid inventing its own input handling.

### Open Questions — Code Architecture

> - Is the current manager-per-concern split (BuildingManager, KitchenManager,
>   SettlerManager, SimulationController, all owned by a thin `game.gd` orchestrator)
>   the intended shape for a full implementation, or should new systems (exploration
>   tasks, planet selection, meta-progression catalog) get their own manager classes
>   following the same pattern?
> - Does a one-shot implementation from a finished design doc still build up
>   incrementally (Phase 0 → 5 as now), or does having a complete spec change that —
>   e.g. is it acceptable to generate more of the system in one pass since the design
>   is no longer being discovered as we go?
> - Should the code map / signal graph tooling (`.claude/code_map_*.md`,
>   `.claude/signal_graph.md`) be regenerated fresh once the one-shot implementation
>   lands, or maintained incrementally throughout it?

---

## Backend & Data Persistence

### Established (Local-Only, Current State)
- **Game save state:** `SaveData` — a custom Resource subclass saved as a binary
  `.res` file via `ResourceSaver` to `user://`; fast to write; strongly typed;
  consistent with the project's Resource usage
- **Settings:** `ConfigFile` (`.cfg`) saved to `user://` — purpose-built for
  key-value preferences, simpler than a full Resource
- **Save triggers:**
  - After every meaningful planning action (piece placed/removed, building toggled,
    meal assigned, explorer assigned, etc.)
  - On app pause (`NOTIFICATION_APPLICATION_PAUSED`) — critical on Android, where
    the OS can kill background apps without warning
  - Saves are handled by `GameState` and must be fast enough to run synchronously
    without perceptible lag

### Open Questions — Backend & Data Persistence
Monetization stance is currently **undecided** (see [Monetization](07_production_and_technical.md#monetization)),
which is the main fork point for this section:

> - **Local-only, no backend at all** (current implementation): single save slot on
>   device, no cross-device sync, no server costs, no accounts. Simplest to ship.
> - **Cloud save / cross-device continuity**: would require a hosting choice (e.g.
>   Google Play Games Services cloud save — no custom server needed — vs. a real
>   backend like Firebase/Supabase) and a lightweight identity (device ID or platform
>   account, not necessarily a full auth system).
> - **Leaderboards for viability-report scores**: if desired, this is the strongest
>   driver toward needing *some* backend, even if saves stay local. Google Play Games
>   Services leaderboards are the low-effort option (no custom server); a custom
>   backend is only needed for cross-platform leaderboards or richer social features.
> - **Multiple save slots / run history size limits**: currently unbounded run
>   history in the Earth hub — does this need pruning or pagination at some point?
> - Given this is currently a single-developer hobby project, is *any* hosted
>   component worth the ongoing maintenance/cost burden, or should the design commit
>   to local-only permanently regardless of monetization outcome?

---

## Authentication, Security & Privacy

### Open Questions — Authentication, Security & Privacy
This entire section is contingent on the [Backend & Data Persistence](07_production_and_technical.md#backend--data-persistence)
decision above — if the game stays local-only with no accounts, most of this section
resolves to "not applicable":

> - If no backend: is there anything here at all, beyond standard app-store privacy
>   disclosures (e.g. "this app collects no data")?
> - If Google Play Games Services is used for cloud save/leaderboards: authentication
>   is handled by Google's SDK (no custom auth to build), but a privacy policy is still
>   required for Play Store listing — who owns drafting that?
> - If a custom backend is ever introduced: what's the minimum viable identity model
>   (anonymous device-bound ID vs. real accounts with recovery)? Real accounts add
>   meaningful scope (password reset, email verification, GDPR-style data deletion
>   requests) that a solo hobby project may want to avoid entirely.
> - Any telemetry/analytics planned (crash reporting, anonymous usage stats)? If so,
>   that alone triggers privacy-policy and disclosure requirements even without accounts.
> - COPPA/age-rating considerations: is this game targeted at a general audience
>   (no special child-privacy handling needed) or could it appeal to a younger
>   audience in a way that changes data-handling obligations?

---

## Testing Strategy

### Unit Testing
- Unit tests written with the **GUT (Godot Unit Test)** plugin where sensible
- Tests are appropriate for pure logic (grid calculations, resource math, outcome
  rolls, food security scoring, etc.) but not required for UI or rendering code

### Open Questions — Unit Testing
> - Is there a target coverage bar for pure-logic systems (e.g. "every system in
>   `scripts/systems/` and `scripts/resources/` must have a GUT suite"), or is
>   coverage decided case-by-case as now?
> - Should unit tests run automatically (CI on push/PR via GitHub Actions headless
>   Godot), or remain a manually-run local check?

### Integration Testing
Not yet established. Per CLAUDE.md, GUT is scoped to "pure logic only, no UI tests" —
so integration testing (verifying managers, signals, and scenes cooperate correctly)
currently has no defined approach.

### Open Questions — Integration Testing
> - Should there be scene-level GUT tests that instance real manager/controller nodes
>   (not just pure logic classes) and assert on signal emissions / state transitions,
>   even without pixel-level UI assertions?
> - Is manual playtesting (per the `/run` skill, launching the app and driving a
>   scenario) the intended integration-test substitute for a solo project, formalized
>   as a checklist rather than automated?
> - Are there specific cross-system flows worth a standing regression checklist given
>   past bugs (e.g. the PIC drag-ownership handoff between BuildingManager/
>   KitchenManager/SettlerManager)?
> - Does a one-shot implementation change the calculus here — e.g. is a broader
>   automated integration suite worth building *because* the design is stable, versus
>   the current incremental-build context where tests would constantly need updating?

---

## Monetization

### Open Questions — Monetization
Currently **undecided** — no commitment made. This section exists to resolve that:

> - **Free, no monetization**: simplest, no store review complexity around IAP/ads,
>   no ongoing revenue-driven design pressure. Consistent with a hobby/portfolio project.
> - **Paid app (one-time purchase)**: no runtime monetization logic needed at all;
>   just a store listing price. Compatible with local-only backend.
> - **Free with ads**: would need to decide placement (e.g. only at hub between runs,
>   never mid-run) to avoid breaking the "cozy, low-friction" tone the design
>   principles establish; ad SDK integration is nontrivial on Godot/Android.
> - **Free with cosmetic IAP**: e.g. purchasable visual themes for the settlement view
>   or alternate settler sprite packs — would need the Art Design section's visual
>   identity resolved first, and doesn't affect gameplay balance (fits "numbers stay
>   small," non-pay-to-win).
> - Is this even a commercial release, or purely a personal/portfolio project with no
>   distribution plan yet? That answer changes whether this section needs resolving
>   before a one-shot implementation, or can stay deferred indefinitely.
