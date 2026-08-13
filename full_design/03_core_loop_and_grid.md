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

### The Grid (Unified)

*(originally designed as two separate grids — Base/Infrastructure and
Farm/Production — later unified into one; see below for why)*

A single grid holds every building, crop, animal pen, and mining site, using
**uniform single-cell placement — no polyominoes, no rotation** (multi-slot
buildings still exist — see Building Schema — but as fixed, non-rotatable
footprints, not a return to arrangement puzzles). Arrangement precision is
deliberately de-emphasized; the puzzle now lives in resource allocation (see
Assignment below), not spatial tessellation.

**Any building can go on any cell**, subject only to building-specific
placement rules already established elsewhere (e.g. a Mine requires an Ore
deposit cell; fixed/environmental terrain is immovable) — there is no
zone-based restriction on what can be built where.

The grid has **one total size**, which is now the single lever controlling
overall settlement density: buildings, crops, and mining sites all compete
for the same finite pool of cells, so infrastructure investment directly
costs farmland and vice versa — a more consequential tradeoff than the old
two-grid split's independently-tunable scarcity. **Working target: 10×8**
(80 cells) — landscape-shaped to match the PC platform pivot, and sized from
a rough building/deposit density pass (see `DESIGN_TODO.md`'s resolved
farm-site-selection entry) showing the old 8×6 mobile grid would already be
short of a late-game building count even before accounting for deposit
cells, while 10×8 leaves comfortable slack. Still nominally subject to
revision in a real balancing pass, but no longer a completely open unknown.

**Why unified, not split:** the original two-grid split existed mostly for
conceptual clarity ("base" vs. "fields") and independently-tunable slot
scarcity — neither of which is a hard mechanical requirement, especially once
the design moved away from spatial-arrangement-driven difficulty entirely (no
polyominoes, no rotation). A concrete wrinkle exposed the seam: Weather Shield
and Row Shield are Protection-category buildings, but needed to sit on the
Farm/Production grid specifically so their area-of-effect could reach the
crops they protect — meaning the category↔grid mapping was already not clean.
Unifying removes that wrinkle (a Protection structure now meaningfully covers
whatever's nearby, farm or infrastructure alike) and removes a
building-placement classification step that didn't map onto a real
strategic decision.

**Fixed/environmental slots.** Some cells on the grid are fixed/environmental
rather than placeable:
- Impassable terrain (mountains, lakes)
- Permanent resource locations (e.g. metal ore, rare mineral deposits — see
  Buildings & Economy's Deposit Discovery)
- Forest tiles (bounded Wood quantity — see Buildings & Economy's Fuel)
- Set at run start; cannot be moved or removed

### Farm Site Selection

A one-time pre-run screen that determines the actual grid instance a run
plays out on — terrain layout, fixed/environmental slots, and deposit
seeding (see Buildings & Economy's [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery))
are all generated here, not before. It happens **after** committing to an
expedition (the planet-type choice made via filament-scan, see Story &
World's [Filaments and Exoplanet Discovery](02_story_and_world.md#background-story--gameplay-story-integration))
and before Season 1 planning opens.

**What varies by site vs. by planet type.** Planet-type-level values —
Hazard Priors, the A/B/C/D strategy-dimension pressures — are fixed once the
planet type is chosen at the filament-scan stage; site selection never
touches them. What a specific site *does* determine is the grid instance
itself: its terrain shape (impassable cells) and where every deposit
(Ore/Stone/rare-metal/aquifer, at all three depth tiers) is actually seeded.
This keeps the number of planet-level variables small while still making
site choice a real decision.

**Presentation.** A small ship sits in the foreground, orbiting the target
planet (visible in the background); a UI panel over this scene shows **3**
candidate sites as grid-layout thumbnails. Each thumbnail is annotated with
its known features — terrain shape, **Surface-tier** deposit positions only
(matching Deposit Discovery's existing rule that Surface deposits are the
one tier visible from run start), **Forest tile** positions (see Buildings &
Economy's Fuel — visible from run start the same way Surface deposits are,
just not part of the hidden-deposit system at all), and the site's
**Average Temperature** (see Planets & Scoring's In-Simulation Hazard
Events — sampled per-site at world-gen from the planet type's
`TrueRisk(Temp)`-parameterized distribution). Mid-depth, Deep, and aquifer
deposits (including Fossil Fuel) are never previewed here, even though
they're already seeded on the candidate's hidden grid — revealing them at
this stage would undercut the discovery gameplay loop that's supposed to
gate them.

**Selection.** Picking a candidate locks in that grid instance — terrain and
the full deposit seeding (hidden tiers included) — for the entire run.

**Reroll.** The player may discard all 3 candidates and generate 3 entirely
new ones, at a cost of **1 Ration** (see Settlers & Exploration's
[Rations](05_settlers_and_exploration.md#rations-basic-sustenance)) —
flavored as the additional orbital scanning taking enough time that the
settlers eat while they wait, though not a full season's worth. Rerolling
is uncapped other than by the player's Ration stock, so it draws on the same
scarcity already established for Rations rather than introducing a new
limiting resource.

### What Got Cut

- **The power grid system, entirely** — no broadcast range, no networks, no shared
  pools, no batteries, no on/off toggling. Removed as a whole layer of low-impact
  management overhead.
- **General neighbor-effect synergies** — removed, with two specific exceptions that
  remain as area-of-effect systems: **force-field/weather-protection coverage**, and
  **drone service footprints** (see Assignment below).
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

### Assignment

An **Assignment** pairs one worker — settler or drone — with a target. Every
target is one of three kinds, and what differs between them is purely a
property of the target, not the assignment mechanism itself, which is
always the same: pick a worker, pick a target, done — a normal, fully
reversible planning-phase action until Next Season is confirmed.

- **Production building** — sticky by default: a worker stays on their site
  across seasons until explicitly reassigned, so a stable layout requires no
  repeated action; can be revisited each planning phase but never must be.
  Accepts settlers or drones (see Worker types below). Every production site
  needs a worker assigned to produce at all (with exceptions: some sites
  need no staffing, and some are multi-purpose combo buildings — e.g. a
  Bakery with hydroponic wheat growing in it, staffed by one worker,
  producing its own wheat *and* baking it, though the wheat-growing side
  runs slower than a dedicated wheat field). An unstaffed site produces zero
  output for the season.
- **Exploration Task** (see Settlers & Exploration) — one-shot: the worker
  is gone for the season and returns with a result. Drawn from a small,
  periodically-refreshed pool (up to 3 at a time, every 3rd season) — a
  side-quest, event-like, not a routine option. Settlers only (some tasks
  are unmanned, needing no assignment at all). Risk-bearing; may require
  Rations to sustain the settler away from the farm.
- **Standing Assignment** (see Settlers & Exploration) — also one-shot, same
  resolution as Exploration Tasks, but always available every season rather
  than pool-limited, and safe (no risk spectrum, no Rations — the work
  stays on or near the farm). Settlers only, for the same reason Exploration
  Tasks are — this work needs a person's judgment, not just mechanical
  labor. Covers Basic Deposit Survey, Deep Survey (see Buildings &
  Economy's Deposit Discovery), and Clear-Cutting (see Buildings &
  Economy's Fuel).

**Worker types** (Production-building assignments specifically — Exploration
Tasks and Standing Assignments are settler-only, per above):
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
Fabrication site, the same staffed-production pattern used for other drones.
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

**Relocation reuses the building — it doesn't re-charge its construction
cost.** The resources spent building the original structure aren't spent
again for the move; relocation costs only the one robot-action (a season),
same as any other construction-robot task.

**Deposit/feature-gated buildings** (Mine, Quarry, Rare Metal Extractor,
Geothermal Generator — see Buildings & Economy's Deposit Discovery and Fuel)
can be relocated too, but only to a different tile with
an already-discovered, not-yet-built-on deposit/feature of the **matching
type** — a Mine can only relocate to another discovered, unbuilt Ore
deposit, never to an arbitrary empty tile. (Well is excluded from this
special case — it isn't actually deposit-gated, since it's freely buildable
on any tile and a detected aquifer just upgrades it to Deep Well
automatically, so it already follows the ordinary relocation rule.) The
vacated origin tile keeps its underlying deposit/feature — it reverts to an
empty-but-still-discovered, buildable tile, not lost. Combined with
construction cost not being re-charged, this is what makes relocating a
deposit-gated building a genuinely useful choice rather than something
you'd only ever demolish-and-rebuild: if a single tile turns out to hold
more than one type of extractable resource (see `DESIGN_TODO.md`'s deposit
overlap audit), moving an existing Mine to a different discovered Ore
deposit frees up its original tile for a different building targeting
whatever else was found there, without losing the Mine's sunk cost.

Construction robots are **purely single-purpose** — construction/upgrade tasks only,
never reassignable to production staffing. Assignment is **automatic**: queuing a
build or upgrade task consumes one robot from the available pool; canceling the task
(fully possible during the reversible planning phase) returns it to the pool. There's
no manual "pick which robot" step, and no persistent busy-state to track — since a
task always completes within the season it's started, every robot is available again
at the start of the next planning phase. The cap this creates is simply: **at most N
build/upgrade actions per season**, where N = robots owned — a rate limit on
infrastructure *growth*, distinct from the grid's own slot-count cap on
infrastructure *total*.

### Small Set of Impactful Actions (Current Draft)

1. **Queue a building construction or upgrade** — consumes one available construction
   robot; targets a slot on the grid (limited slots total, including a revealed
   mineral deposit for mining buildings).
2. **Assign/reassign a worker (settler or drone) to a site** — the central recurring
   decision; sticky by default, so it's an occasional action, not a per-season chore.
3. **Place/reposition a force-field or weather-protection structure.**
4. **Assign a settler to an exploration task** (occasional, every 3rd season, per the
   existing Exploration Tasks design).
5. **Adjust food-for-consumption** (see Food & Nutrition) — sticky-defaulted to last
   season's diet, so only an action when the player wants to deviate from it.

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

**Fixed real-time window.** A season corresponds to a fixed length of real
time in the story-world, so the simulation window has a fixed real-time
duration regardless of what's built — playback speed is a pure time-multiplier
that compresses wall-clock time without changing what happens. Production
`production_time` values and event occurrence rates are all calibrated
against this same fixed window.

**Two resolution contexts, not a single timeline:**
- **Outside-Sim** — instantaneous, discrete resolution with no clock running
  and no continuous production ticking. Merges what could otherwise be three
  separate moments (right before the clock starts, right after it ends, and
  the top of the next planning phase) into one mechanically-equivalent
  bucket, since none of them involve real time passing. Hosts: Vaccine
  unlock threshold checks, pooled nutrition consumption resolution, Food
  Storage commitments becoming final, Scanner Station report resolution
  (the mechanical `Confidence`/`MatchedRisk` update), Deposit Discovery
  survey mechanical resolution, construction/upgrade/relocate actions
  completing. An internal order of sub-steps still applies within this
  bucket (not yet fully specified — TBD). Exploration task results are a
  special case within Outside-Sim: they get a **dedicated confirmation UI**
  at the start of the next planning phase, rather than resolving silently.
- **Mid-Sim** — the only place real time actually passes. Continuous
  production ticks live here, plus any discrete event with a genuine reason
  to occupy a specific interval rather than resolving instantly — In-Simulation
  Hazard Events are the clearest example (a storm has a start time and
  duration, not lasting the whole season). Purely ambient visual depictions
  of Outside-Sim-resolved activities also happen here for legibility/immersion
  (see Art Design) — e.g. a Scanner Station's radio-wave pulse, or a survey
  settler wandering the grid — with no coupling to the actual mechanical
  resolution.

**The log/event-feed system.** Replaces the old live-log-overlay/outcome-log
split with a single, simpler structure:
- **No separate always-visible overlay.** The default simulation view has no
  forced log clutter — just ambient visuals and the progress bar. A single
  log is opened via a button/icon (as the old outcome log was), but now it
  can be opened **during** simulation too, live-updating in real time, not
  just reviewed after the fact.
- **Routine production is aggregated, not logged tick-by-tick.** One running,
  live-updating log line **per resource type** (not per building) — e.g. a
  single "+N Grain" line that increments and re-timestamps itself to the most
  recent contributing tick, regardless of how many sites are producing it.
  This avoids a dozen-plus simultaneous production sites spamming the log
  with individual tick entries. Aggregated production lines are still fully
  legible entries, not hidden or deprioritized — they're just consolidated.
- **Noteworthy events get their own individual, timestamped lines**,
  interspersed with the aggregated production lines: hazard occurrences,
  settler deaths, vaccine unlocks, Deposit Discovery reveals, exploration
  escalations unlocking, and similar.
- **Transmissions stays fully separate** — the persistent, cross-season,
  narrative-flavored channel (see Story & World's Gameplay-Story
  Integration) serves a distinct purpose (advance warnings, flavor, Herald's-
  voice reports) from this per-season mechanical log, and that split is
  preserved rather than merged.

> **Still open**: how multiple buildings' continuous production cycles
> interleave *visually* (beyond the log itself — is there any per-building
> animation, or is the log the primary way production is communicated?); the
> internal sub-step ordering within Outside-Sim.

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
