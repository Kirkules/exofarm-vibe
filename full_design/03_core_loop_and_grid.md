# Core Loop & Grid

## Platform & Core Loop Redesign (In Progress)

This section is a working checkpoint of an active redesign that **supersedes** several
sections below (The Grid's polyomino/multi-slot-piece content, Power System in its
entirety, Crafting & Merge Spaces' merge-space UI, Interaction Hierarchy's
double-tap-to-toggle-power gesture, and the mobile-tuned Screen Layout / UI Layout
content in Art Design). Those sections are left in place as reference material —
marked superseded inline — rather than deleted, since some of their content (e.g.
grid coordinate conventions, general resource/settler concepts) still applies. This
section will be reconciled with them once the redesign settles. **More is still in
flux; treat this whole section as provisional.**

### Why This Redesign

Early playtesting of the original (mobile, portrait) design surfaced a core problem:
too many low-impact, fiddly actions per season (precise polyomino placement/rotation,
manual merge-space ingredient arrangement, power-network management) diluted the few
decisions that actually mattered. The redesign's goal is a **small set of impactful
actions per season**, per the "difficulty from breadth of tradeoffs, not execution
precision" and "a passable plan should always be quick to reach" design principles —
both already established, now being applied more aggressively than the original
design achieved in practice.

### Platform

- **Target: PC first** (Mac/Linux, Windows if straightforward) — not mobile. Mobile
  scaling should remain *possible* later without a full overhaul, but nothing is being
  optimized for mobile at this stage.
- **Orientation: landscape**, not portrait.
- **Visual reference points: FTL: Faster Than Light and Into the Breach** (both Subset
  Games). Traits worth carrying over: moderate-resolution pixel art (well above
  blocky mobile 32px-tile density), dark UI panel chrome with bright functional accent
  colors, a dominant central grid viewport flanked by persistent side panels, and high
  spatial legibility prioritized over detailed character art. Both references are
  cooler/tenser in mood than ExoFarm's "cozy pioneering optimism" — the craft should
  transfer, but the palette should run warmer/brighter than either reference. The
  pixel-art commitment itself is still flagged for revisiting during a full Art Design
  pass, not locked in permanently by this reference.
- **Screen arrangement:** the settlement vista becomes a full-screen ambient backdrop
  behind everything (not a dedicated stacked zone as in the mobile layout). UI
  interaction panels float over it on the left and right; a status-reporting strip
  sits on top. Full layout detail (exact panel contents/placement) is deferred until
  the core loop below is stable.

### Two-Zone Grid Split

The single farm grid is replaced by two separate grids, both using **uniform
single-cell placement — no polyominoes, no rotation, no multi-slot pieces**.
Arrangement precision is deliberately de-emphasized; the puzzle now lives in resource
allocation (see Worker Assignment below), not spatial tessellation:

- **Base/Infrastructure grid** — has a limited number of slots, creating real (if
  minimal) opportunity cost in what gets built. Holds power/fabrication-type buildings
  (nature of what replaces the old Solar Rig/Matter Manipulator role TBD), the Drone
  Fabrication site, and similar.
- **Farm/Production grid** — holds all crop and animal production, and all
  planet-side mineral deposit locations (fixed terrain features are part of this grid
  now, not a separate concept).

### What Got Cut

- **The power grid system, entirely** — no broadcast range, no networks, no shared
  pools, no batteries, no on/off toggling. Removed as a whole layer of low-impact
  management overhead.
- **General neighbor-effect synergies** — removed, with two specific exceptions that
  remain as area-of-effect systems: **force-field/weather-protection coverage**, and
  **drone service footprints** (see Worker Assignment below).
- **Manual merge-space ingredient crafting** — no more dragging ingredients into a
  mini-grid to discover/confirm recipes. See Production Model below for what replaces
  it.

### Production Model

- Every production site has **one primary input→output conversion**. An idea for
  automatic higher-value alternative outputs when secondary ingredients happen to be
  in stock (e.g. an Advanced Bakery producing Garlic Butter Bread instead of Bread
  when Butter is available) was floated but is **not resolved** — it's vulnerable to
  race conditions when multiple sites complete a cycle simultaneously and compete for
  the same scarce secondary ingredient, and needs a conflict-resolution mechanism (or
  a simpler alternative, like making "better recipe" a separate building rather than
  smarter automatic selection) before it's viable.
- **Production runs on a continuous rate, not a discrete timer.** Progress accumulates
  at `100% / production_time` per second. A boost or penalty modifies that *rate*,
  not a countdown — a cycle 50% complete when a boost hits finishes at half the
  remaining time, and subsequent cycles run at the boosted rate until the effect ends.
  No discrete timer resets, no exploitable edge cases from boost timing.
- **Farm and infrastructure production are unified under this same model.** A wheat
  field runs the same continuous-rate production as a Bakery, modified by external
  effects (weather, fertilizer) instead of requiring a settler to walk over and tend
  it, as in the original design.

### Worker Assignment (Staffing)

Every production site needs a worker — settler or drone — assigned to produce at all
(with exceptions: some sites need no staffing, and some are multi-purpose combo
buildings — e.g. a Bakery with hydroponic wheat growing in it, staffed by one worker,
producing its own wheat *and* baking it, though the wheat-growing side runs slower
than a dedicated wheat field). An unstaffed site otherwise produces zero output for
the season. **Assignment is sticky by default** — a worker stays on their site across
seasons until explicitly reassigned, so a stable layout requires no repeated
staffing action; assignment can be revisited each planning phase but never must be.

**Worker types:**
- **Settlers** are universal — assignable to any job type — but can only cover one
  grid slot (one field or one building) each.
- **Drones** are built at a Drone Fabrication site, which is itself a staffed
  production site (a real early-game bootstrapping decision: dedicating a scarce
  settler to drone production instead of food, for a later payoff). Drones can be
  **all-purpose** (universal like a settler, but lower efficiency at the basic tier;
  advanced all-purpose drones match a settler's efficiency exactly) or **specialized**
  (restricted to a job category — e.g. Grain/Fruit/Food vs. Lumber/Cotton vs. animal
  products — with bonuses for that category).
- **Specialized drones can service a multi-cell footprint** rather than being limited
  to one slot — e.g. a harvester drone servicing every matching-category site within
  a 2×2 area. Footprint size scales with drone tier/upgrade, with scaling balanced
  per drone type. Within a footprint, only matching-category sites are serviced;
  non-matching or empty cells are simply unserviced — clustering same-category
  production together is a pure efficiency optimization, not a requirement. Footprints
  represent *reach*, not physical occupation, so they can overlap freely.
- **Effort stacks toward a per-site production cap.** A site has a maximum per-cycle
  output (scaling with its tier/upgrades); each worker (or each unit of overlapping
  drone coverage) contributes one unit of effort toward that cap. A single
  settler-level worker might only realize half an advanced site's potential output,
  requiring a second worker (another settler, or overlapping drone coverage) to reach
  the cap — creating a spread-thin-vs-concentrate tradeoff on top of the basic
  staffing decision.
- Left open: whether some special worker type could break the "one worker, one slot"
  default (settlers) or otherwise behave outside these rules.

### Worker Roster (UI)

A roster of small avatar icons sits along the left edge of the main viewport,
floating over the settlement-vista backdrop rather than in an opaque panel. **One row
per worker type actually present in the settlement** — a type with zero workers owned
simply has no row, so the roster stays exactly as long as it needs to be, never
padded with types the player hasn't built yet. Each row shows "A/B": A = currently
unassigned workers of that type, B = total owned.

- **Hovering** an avatar outlines it and simultaneously outlines every building/site
  currently serviced by workers of that type — a direct visual answer to "where is
  this worker type deployed right now," which matters for optimizing specialized
  drone footprint clustering.
- **The roster is also an assignment entry point**, not just informational: dragging
  an avatar with unassigned workers (A > 0) begins the same assign-to-site flow as
  picking up a worker directly, fusing "notice an idle worker" and "assign it" into
  one continuous interaction per the minimal-UI-interaction principle.

### Construction

Every settlement starts with **one construction robot**; more can be built at a
Robotics/Fabrication site, the same staffed-production pattern used for other drones.
A construction robot can, in a season, do one of three things: **build one new
building** (any type), **upgrade one existing building**, or **relocate one existing
built building** to a different valid, empty slot (or slots, for a multi-slot
building) — all three resolve the *following* season, consistent with how
production/crafting already resolves during simulation rather than instantly.

Relocation exists specifically to resolve a real edge case: an upgrade that expands a
building's footprint (see Building Schema's multi-slot buildings, e.g. Upgraded
Kitchen) is only offered/confirmable if the required adjacent cell(s) are actually
free — the same placement-validity check used for new construction, just applied to
the upgrade action. If a neighboring built building is in the way, relocating it is
the way to clear space. Since relocation costs one full robot-action (a season), this
makes "not leaving room to grow" a real, felt strategic misstep — clearing the space
and then performing the upgrade costs two robot-actions total (two seasons with one
robot, or one season if a second robot is available to do both at once) — without
ever permanently locking the upgrade out.

Construction robots are **purely single-purpose** — construction/upgrade tasks only,
never reassignable to production staffing. Assignment is **automatic**: queuing a
build or upgrade task consumes one robot from the available pool; canceling the task
(fully possible during the reversible planning phase) returns it to the pool. There's
no manual "pick which robot" step, and no persistent busy-state to track — since a
task always completes within the season it's started, every robot is available again
at the start of the next planning phase. The cap this creates is simply: **at most N
build/upgrade actions per season**, where N = robots owned — a rate limit on
infrastructure *growth*, distinct from the Base/Infrastructure grid's slot-count cap
on infrastructure *total*.

### Small Set of Impactful Actions (Current Draft)

1. **Queue a building construction or upgrade** — consumes one available construction
   robot; targets a slot in the Base/Infrastructure grid (limited slots) or the
   Farm/Production grid (including a revealed mineral deposit).
2. **Assign/reassign a worker (settler or drone) to a site** — the central recurring
   decision; sticky by default, so it's an occasional action, not a per-season chore.
3. **Place/reposition a force-field or weather-protection structure.**
4. **Assign a settler to an exploration task** (occasional, every 3rd season, per the
   existing Exploration Tasks design).
5. **Adjust food-for-consumption** (see Food & Nutrition) — sticky-defaulted to last
   season's diet, so only an action when the player wants to deviate from it.

---

## The Grid

The Farm/Production grid (see Platform & Core Loop Redesign) uses uniform
single-cell slots. Some slots are **fixed/environmental** rather than placeable:

- Impassable terrain (mountains, lakes)
- Permanent resource locations (e.g. metal ore, rare mineral deposits)
- Set at run start; cannot be moved or removed

---

## Season Structure

Each game round = one **season** on the planet.

### Planning Phase
- Player places and rearranges elements on the grid, assigns workers to sites, and
  manages the small set of impactful actions described in Platform & Core Loop
  Redesign
- All moves are **fully reversible** until "Proceed to Next Season" is confirmed
- **Moveable pieces** can be picked up (freeing their slots) and placed elsewhere or
  returned to the **inventory** (no separate workspace area — the inventory serves as
  the off-grid holding area)
- Tooltips and contextual information throughout

### Simulation Phase
- **Passive** — no player input required
- Production runs on the continuous-rate model described in Platform & Core Loop
  Redesign
- Playback speed controls: **1×, 2×, 3×, 5×**
- Results feed into the next planning phase

---

## Technology & Progression

### Within a Run
- Progression is **resource-gated, not time-gated or research-gated.**
- Settlers arrive with blueprints for all known designs. What limits fabrication is
  having enough of the required materials.
- **Basic designs** require only Energy and Matter.
- **Advanced designs** additionally require specific planet-side materials (ore types,
  rare deposits, etc.) that must be extracted or harvested on the planet.
- Finding a rich deposit of a rare material early can accelerate access to advanced
  technology within that run.

### Agriculture Branching

Every run starts with **greenhouse farming**: the settlers bring seeds and grow familiar
crops inside enclosed structures before they know how to work with the planet's biosphere.
The player can then branch along two paths depending on the planet's character:

- **Advanced Greenhouse Path** — build larger, more efficient greenhouse structures.
  Favored on planets with **hostile atmospheres or extreme weather** but **plentiful
  building materials** (energy, ore). Crop output scales with greenhouse quality rather
  than outside conditions.

- **Local Agriculture Path** — hybridize Earth crops with native planet-side flora,
  eventually farming directly in the open. Favored on planets with a **hospitable
  atmosphere** but **scarce building resources**. Unlocks planet-specific crops and
  higher long-term yield potential.

Both paths converge on the Cafeteria for meal crafting; the crops produced differ but
the food system is the same. The path taken affects score factors (efficiency vs.
adaptability) and which advanced designs become accessible.

*Planet types will be designed to make one path clearly more efficient while leaving
the other viable — not to make one path always correct.*

### Across Runs (Meta-Progression)
- Gathering enough of a **new resource type** (one not seen in prior runs) during a run
  causes Earth's designers to develop a new design using that material.
- That design is added to the **catalog** and available in all future runs.
- Creates incentive to explore varied exoplanet types, each with distinct resource
  profiles.
