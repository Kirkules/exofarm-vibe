# Core Loop & Grid

## Platform & Core Loop Redesign (In Progress)

**At a glance:**
- **Platform** — PC first, landscape; FTL/Into the Breach-style pixel art
  reference, warmer palette.
- **The Grid** — one unified grid, single-cell placement, no
  polyominoes/rotation; fixed/environmental slots (terrain, deposits,
  Forest) set at run start.
- **Run-Start Flow** — Hub → Crew Selection → Specialization → wormhole
  confirmation (1st point of no return) → Farm Site Selection → Starting
  Settlement Placement → land-at-site confirmation (2nd point of no
  return) → Season 1.
- **Crew Selection** — starting crew, each settler independently rolled an
  Average/Jack-of-several-trades/Savant Aptitude archetype; free, uncapped
  reroll.
- **Specialization** — one-time pre-run mass-budget allocation (Extra
  Rations / extra worker / orbital probe), additive on top of the base
  loadout.
- **Farm Site Selection** — pick 1 of 3 candidate grid instances;
  Ration-cost reroll; locks terrain/deposit seeding for the run.
- **Starting Settlement Placement** — the four starting buildings land as
  one rigid T-tetromino, freely repositioned until land-at-site
  confirmation.
- **Production Model** — continuous-rate cycles plus an ordered
  production queue; plant-crop buildings run a persistent state machine
  instead.
- **Assignment** — one worker to one of three target kinds (Production
  building / Exploration Task / Standing Assignment); settlers universal,
  drones built at Robotics Assembly.
- **Worker Roster / Site Panel (UI)** — collapsed per-type counts during
  planning, per-worker icons during Mid-Sim; Site Panel always shows
  recipe queue, worker slot, rate summary, status.
- **Construction** — one robot = one build/upgrade/relocate action per
  season, plus a separate settlement-wide fence-tile budget.
- **Small Set of Impactful Actions** — construction, worker assignment,
  shield placement, exploration-task assignment, food-for-consumption
  adjustment.

**More is still in flux; treat this whole section as provisional.**

### Why This Redesign

The core loop targets a **small set of impactful actions per season**, per
the "difficulty from breadth of tradeoffs, not execution precision" and "a
passable plan should always be quick to reach" design principles —
deliberately minimizing low-impact, fiddly per-season actions (precise
spatial placement, manual ingredient arrangement, network management) that
would otherwise dilute the few decisions that actually matter.

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

A single grid holds every building, crop, animal pen, and mining site, using
**uniform single-cell placement — no polyominoes, no rotation** (multi-slot
buildings still exist — see [Building Schema](04_buildings_and_economy.md#building-schema) — but as fixed, non-rotatable
footprints, not a return to arrangement puzzles). Arrangement precision is
deliberately de-emphasized; the puzzle now lives in resource allocation (see
[Assignment](03_core_loop_and_grid.md#assignment) below), not spatial tessellation.

**Any building can go on any cell**, subject only to building-specific
placement rules already established elsewhere (e.g. a Mine requires an Ore
deposit cell; fixed/environmental terrain is immovable) — there is no
zone-based restriction on what can be built where.

The grid has **one total size**, which is the single lever controlling
overall settlement density: buildings, crops, and mining sites all compete
for the same finite pool of cells, so infrastructure investment directly
costs farmland and vice versa. Size: see
`data/misc_balancing_values.csv`'s "The Grid" row — landscape-shaped to
match the PC platform pivot, and sized from a rough building/deposit
density pass showing a smaller grid would already be short of a late-game
building count even before accounting for deposit cells.

**Weather Shield and Row Shield** (Protection-category buildings) cover
whatever's nearby on the single grid, farm or infrastructure alike — their
area-of-effect isn't restricted by building category or zone.

**Fixed/environmental slots.** Some cells on the grid are fixed/environmental
rather than placeable:
- Impassable terrain (mountains, lakes)
- Permanent resource locations (e.g. metal ore, rare mineral deposits — see
  Buildings & Economy's [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery))
- Forest tiles (bounded Wood quantity — see Buildings & Economy's [Fuel](04_buildings_and_economy.md#fuel))
- Set at run start; cannot be moved or removed

### Run-Start Flow

The screens between "start a run" and the first Planning Phase, in order.
Most are detailed in their own subsection below; the hub is in Story &
World's [Meta-Progression](02_story_and_world.md#meta-progression) & Earth Hub.

1. **Hub** — the player picks a planet from the candidate pool. The pool is
   rerollable *here, in the hub*, and nowhere later.
2. **[Crew Selection](03_core_loop_and_grid.md#crew-selection)** — settle on the starting crew.
3. **[Specialization](03_core_loop_and_grid.md#specialization)** — allocate the wormhole mass budget.
4. **Wormhole confirmation** — an explicit, deliberate confirm and the
   **first point of no return:** the planet is now locked and can never be
   rerolled. Nothing about the specific planet has been shown yet; it is
   revealed only from here on.
5. **[Farm Site Selection](03_core_loop_and_grid.md#farm-site-selection)** — choose the grid instance from 3
   candidates (the candidate set is rerollable here, for a Ration cost).
6. **[Starting Settlement Placement](03_core_loop_and_grid.md#starting-settlement-placement)** — position the starting
   buildings on the chosen grid.
7. **Land-at-site confirmation** — a second explicit confirm and the
   **second point of no return:** the site and the settlement's placement
   are locked, and Farm Site Selection can no longer be revisited.
8. **Season 1 planning** — the first Planning Phase opens.

**Reversibility between the commit points.** Everything up to the wormhole
confirmation is freely revisited: the player can back out to Crew
Selection, and re-confirming the crew restarts Specialization fresh (see
[Specialization](03_core_loop_and_grid.md#specialization)). Between the wormhole confirmation and the
land-at-site confirmation the planet is fixed, so the only "back" action
is rerolling the Farm Site Selection candidate set; Starting Settlement
Placement itself is freely repositioned until the land-at-site confirm.

**Season 1 is an ordinary season.** It opens directly on a normal
[Planning Phase](03_core_loop_and_grid.md#planning-phase) — no Post-Sim precedes it, there is no special
first-season seeding step, and it runs the same Planning Lock-in / Mid-Sim
/ Post-Sim structure as every other season (see [Season Structure](03_core_loop_and_grid.md#season-structure)).
The only Season-1-specific content is the one-time SEED summary
transmission (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events),
near-zero-`Confidence` telegraphing), which arrives at the **top of Season
1 planning**, once the settlement is on the grid.

**Starting loadout.** A run begins with: the crew (see [Crew Selection](03_core_loop_and_grid.md#crew-selection));
whatever [Specialization](03_core_loop_and_grid.md#specialization) added on top; a starting Rations stock
(see Settlers & Exploration's [Rations](05_settlers_and_exploration.md#rations-basic-sustenance)); one **Settlement Base** plus the three other
starting buildings — Water Processing Plant, Sawmill, and Stone Processing
(see Buildings & Economy's [Basic Resource Production](04_buildings_and_economy.md#basic-resource-production), [Water](04_buildings_and_economy.md#water), and
[Fabrication](04_buildings_and_economy.md#fabrication)); and one construction robot.

### Crew Selection

A one-time pre-run screen — the first decision of a run, immediately after
the planet is picked in the hub and before anything about the planet is
shown. It is followed by [Specialization](03_core_loop_and_grid.md#specialization), then the wormhole
confirmation, then [Farm Site Selection](03_core_loop_and_grid.md#farm-site-selection) (see [Run-Start Flow](03_core_loop_and_grid.md#run-start-flow)
for the full ordering). The player settles here on their starting crew of
settlers (size: see `data/misc_balancing_values.csv`'s "Crew Selection" row).

**What it determines.** Each candidate crew is a full set of settlers with
independently-rolled Aptitude profiles (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's
[Aptitude](05_settlers_and_exploration.md#aptitude)) — names and everything
else about a settler are otherwise uninvolved in this screen. Selecting a
crew locks in every settler's Aptitude levels, across all six buckets, for
the entire run; Aptitude never changes afterward.

**Archetypes.** Each settler in a candidate crew is independently assigned
one of three archetypes (weights: see `data/misc_balancing_values.csv`'s
"Crew Selection" row):
- **Average** — every bucket's level falls within [−1, +1], and the total
  across all six buckets also falls within [−1, +1]. Low variance, safe,
  no guaranteed extremes either direction.
- **Jack-of-several-trades** — 2–3 buckets at +2 (no bucket exceeds +2 for
  this archetype), with the remaining buckets carrying whatever mix of −1s
  and −2s is needed to land the total between −2 and 0, centered on −1.
  Moderate specialization at a moderate cost.
- **Savant** — at least one bucket at +3, at least one bucket at −3, every
  other bucket unconstrained, with the total across all six always summing
  to exactly −3. The highest ceiling in the game, at the steepest built-in
  cost.

This keeps crew balance **per-settler** rather than per-crew — a crew of
independently-rolled settlers can't be gamed by concentrating every
settler's downside where it's easiest to ignore (e.g. one settler eating
every negative bucket while never being assigned there, leaving every
other settler's upside free). A full-Savant crew is possible
(0.1⁵ ≈ 0.001% for the 5-settler crew) but vanishingly rare, matching the
intent that an optimal roll should be a real, felt outlier, not something
worth grinding for.

**Presentation.** Shows the full candidate crew — names and Aptitude
profiles as plain-language readouts per bucket (e.g. "+30% Mining speed"),
never raw levels or formulas — see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Aptitude](05_settlers_and_exploration.md#aptitude).

**Reroll.** The player may discard the entire shown crew and generate a
new one. Unlike [Farm Site Selection](03_core_loop_and_grid.md#farm-site-selection)'s reroll below, this one is **free and
uncapped** — no Ration cost, no limit — since it's the very first decision
of a run, before there's anything in inventory to spend.

### Specialization

A one-time pre-run screen after [Crew Selection](03_core_loop_and_grid.md#crew-selection) and before the wormhole is
committed. Framed as the small amount of extra mass that fits through the
wormhole alongside the crew and the basic starting materials — an opportunity to
begin the run leaning in one direction.

**Mechanic.** The player has a **mass budget** — set by current
meta-progression state — and fills a bucket with elements from the **full list
of possibilities**, each carrying a mass cost. An element can be added only
while the remaining budget covers its cost. The full list is always shown,
including elements the current budget cannot afford (they appear but
unselectable), so the screen doubles as a visible signpost for what
meta-progression will later open up. There is no randomness and nothing to
reroll — it is pure allocation, freely filled, rearranged, or emptied, and fully
reversible up to the wormhole confirmation (backing out to Crew Selection and
re-confirming the crew starts Specialization fresh).

**Base budget** (see `data/misc_balancing_values.csv`'s "Specialization" row)
affords exactly one atomic element, so at the start of the game
this is effectively a single mutually-exclusive pick; specializing in more than
one direction at once is a meta-progression reward (a larger budget, plus a
wider and cheaper pool — see Story & World's [Meta-Progression](02_story_and_world.md#meta-progression)). Whatever is
chosen is **additive** on top of the base starting loadout (the crew, a starting
Rations stock, the starting buildings, and one construction robot).

**Base pool.**
- **Extra Rations** — a fixed additional Rations amount (see
  `data/misc_balancing_values.csv`'s "Specialization" row; larger bundles are
  a later meta-progression option), intended to fund early exploration
  without an immediate pivot to farming.
- **Extra worker** — one additional worker, the player choosing a **construction
  robot** or a basic **all-purpose drone** (see Buildings & Economy's
  [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)).
- **Orbital probe** — a small satellite placed in a semi-stable orbit that holds
  for the whole run. It has no grid presence — no slot, no staffing, no Energy —
  and is an abstract run modifier surfaced through the planetary-assessment
  readout and Transmissions. Two effects:
  - **Weather warning boost.** It shifts hazard telegraphing (see Planets &
    Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)) **one tier better** than the
    settlement's current weather-data `Confidence` alone would give — at
    near-zero `Confidence` that means the settlement gets the wide "some time
    in the next several seasons" warning of a scheduled Storm or Temperature
    Extremity instead of possibly nothing, and at higher `Confidence` it
    sharpens the lead-time window and severity readout by one step (capped at
    the exact-lead-time tier). It adds no separate channel — it advances the
    player along the existing `Confidence`-scaled telegraph.
  - **Civilization scan.** Once, early in the run, the probe rolls a chance
    (see `data/misc_balancing_values.csv`'s "Specialization" row) to detect
    organized life on the planet. On success the player
    receives a Transmission and a **guaranteed slot in the Exploration Task
    pool to initiate contact** — feeding the sentience-contact chain (see
    Settlers & Exploration's [Escalation Chains](05_settlers_and_exploration.md#escalation-chains)) exactly as a completed
    Sentience Detection task would. On failure there is **no report and no
    Transmission**: a null result is deliberately ambiguous between "no
    civilization here" and "the scan missed," and the player can still reach
    Sentience Detection through ordinary exploration.

### Farm Site Selection

A one-time pre-run screen that determines the actual grid instance a run
plays out on — terrain layout, fixed/environmental slots, and deposit
seeding (see Buildings & Economy's [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery))
are all generated here, not before. It happens **after** the wormhole
confirmation (which locks the planet type — the choice made via
filament-scan, see Story & World's [Filaments and Exoplanet Discovery](02_story_and_world.md#background-story--gameplay-story-integration))
and **before** [Starting Settlement Placement](03_core_loop_and_grid.md#starting-settlement-placement) and Season 1 planning
(see [Run-Start Flow](03_core_loop_and_grid.md#run-start-flow)).

**What varies by site vs. by planet type.** Planet-type-level values —
Hazard Priors, the four strategy-dimension pressures (Protection/Enclosure,
Biosphere Integration, Synthesis/Self-Sufficiency, Energy Management) — are fixed once the
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
Economy's [Fuel](04_buildings_and_economy.md#fuel) — visible from run start the same way Surface deposits are,
just not part of the hidden-deposit system at all), and the site's
**Average Temperature** (see Planets & Scoring's In-Simulation Hazard
Events — sampled per-site at world-gen from the planet type's
`TrueRisk(Temp)`-parameterized distribution). Mid-depth, Deep, and aquifer
deposits (including Fossil Fuel) are never previewed here, even though
they're already seeded on the candidate's hidden grid — revealing them at
this stage would undercut the discovery gameplay loop that's supposed to
gate them.

**Selection.** Picking a candidate locks in that grid instance — terrain and
the full deposit seeding (hidden tiers included) — for the entire run. The
site's **pristine state at this moment** — before any building is placed —
is the baseline the Stewardship `DisruptionFootprint` score is measured
against for the rest of the run (see Planets & Scoring's [SEED Factions](06_planets_and_scoring.md#seed-factions)).
World generation guarantees every candidate admits at least one legal
Starting Settlement Placement (below).

**Reroll.** The player may discard all 3 candidates and generate 3 entirely
new ones, at a Ration cost (see `data/misc_balancing_values.csv`'s "Farm
Site Selection" row) — flavored as the additional orbital scanning taking
enough time that the settlers eat while they wait, though not a full
season's worth. Rerolling
is uncapped other than by the player's Ration stock, so it draws on the same
scarcity already established for Rations rather than introducing a new
limiting resource.

### Starting Settlement Placement

The step between [Farm Site Selection](03_core_loop_and_grid.md#farm-site-selection) and the land-at-site
confirmation, where the player positions the starting buildings on the
chosen grid.

**The footprint.** The four starting buildings land together as one rigid
**T-tetromino** (four cells): the centre — the cell adjacent to the other
three — holds the **Settlement Base** (see Buildings & Economy's
[Settlement Base](04_buildings_and_economy.md#settlement-base)), and the three arm cells hold the **Water
Processing Plant**, **Sawmill**, and **Stone Processing** (arm-to-building
assignment is fixed, not random; the specific mapping is a balancing-pass
detail). The player slides the tetromino across the grid and **rotates it
through its four orientations**; there is no other arrangement freedom at
this step.

**Placement validity.** Every one of the four cells must be in-bounds,
passable, and empty. Covering a visible feature (a Surface-tier deposit,
a Forest tile) is permitted and resolves under the general
building-on-a-feature rule (its own open item — see `DESIGN_TODO.md`).
World generation guarantees at least one legal placement exists on every
candidate site, so this step can never dead-end.

**After placement.** The tetromino is rigid only during this step. Once
the run begins, the four buildings are independent, ordinary fixed
buildings, each relocatable by a construction robot like any other (see
[Construction](03_core_loop_and_grid.md#construction)).

**Reversibility.** Freely repositioned and rotated until the land-at-site
confirmation; that confirmation is the second point of no return (see
[Run-Start Flow](03_core_loop_and_grid.md#run-start-flow)).

**Disruption.** Placing the starting settlement is the first change
measured against the run-start `DisruptionFootprint` baseline (see
Planets & Scoring's [SEED Factions](06_planets_and_scoring.md#seed-factions)). Founding a settlement always
carries a small `DisruptionFootprint` — there is no zero-impact way to
settle an alien world — and it is deliberately a minor term, not a
dominant one.

### Production Model

- Every production site has **one primary input→output conversion**.
- **Production runs on a continuous rate, not a discrete timer.** Progress accumulates
  at `100% / production_time` per second. A boost or penalty modifies that *rate*,
  not a countdown — a cycle 50% complete when a boost hits finishes at half the
  remaining time, and subsequent cycles run at the boosted rate until the effect ends.
  No discrete timer resets, no exploitable edge cases from boost timing.
  **Inputs are consumed, and any non-guaranteed-output success roll is made,
  at cycle *start*** — the outcome is committed up front, not at completion.
- **Every production building runs an ordered production queue** of
  `(recipe, limit)` steps rather than one recipe per season — the player
  sequences a season's output ahead of time (limits, ordering, an
  "unlimited" tail), and it advances on its own through missing-input cases
  without stalling. Full mechanic in Buildings & Economy's [Building Schema](04_buildings_and_economy.md#building-schema)
  ("Production queue"); the queue advances during Mid-Sim as cycles
  complete.
- **Farm and infrastructure production are largely unified under this same
  model.** Most farm buildings run the same continuous-rate production as
  any other building, modified by external effects (weather, fertilizer)
  rather than requiring a settler to walk over and tend it.
  **Exception**: the four plant-crop buildings (Grain Field, Fruit Orchard,
  Fiber Field, Timber Grove) instead each track a **persistent per-site
  state**, advancing through a named sequence of transitions rather than one
  uniform cycle — and each building's sequence is genuinely different
  (an annual replant-every-harvest shape for Grain/Fiber, a one-time
  establishment followed by a repeating fruit-bearing loop for the Orchard,
  a one-time establishment followed by a repeating harvest self-loop for
  Timber Grove) so the four don't just read as color-tinted versions of the
  same building — see Buildings & Economy's [Farm/Production](04_buildings_and_economy.md#farmproduction) for the full
  per-building mechanism.

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
  needs a worker assigned to produce at all, apart from the sites that need
  no staffing. An unstaffed site produces zero output for the season.
- **Exploration Task** (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration) — one-shot: the settler
  is gone for the season and returns with a result. Drawn from a small
  pool, always available (not gated to a periodic window), refreshed on
  season-start and manual reroll — a side-quest, event-like, not a routine
  option. **Settler-only, full stop** — no drone of any tier is ever
  eligible (see Buildings & Economy's [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)). Risk-bearing;
  may require Rations to sustain the settler away from the farm.
- **Standing Assignment** (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration) — also one-shot, same
  resolution as Exploration Tasks, but always available every season rather
  than pool-limited, and safe (no risk spectrum, no Rations — the work
  stays on or near the farm). Covers Basic Deposit Survey, Deep Survey (see
  Buildings & Economy's [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery)), Clear-Cutting (see Buildings &
  Economy's [Fuel](04_buildings_and_economy.md#fuel)), and Trapping (see Buildings & Economy's [Farm/Production](04_buildings_and_economy.md#farmproduction))
  — worker-type eligibility varies per assignment, not uniformly
  settler-only (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Standing Assignments](05_settlers_and_exploration.md#standing-assignments)).

**Worker types** (Production-building assignments specifically — Exploration
Tasks and Research are settler-only, full stop; see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration
and Buildings & Economy's [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly) for why):
- **Settlers** are universal — assignable to any job type Injuries/Aptitude
  don't bar them from — but can only cover one grid slot (one field or one
  building) each, contributing **1.0 Effort** as their unmodified baseline
  (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Aptitude](05_settlers_and_exploration.md#aptitude) and [Experience](05_settlers_and_exploration.md#experience) for modifiers).
- **Drones** are built at Robotics Assembly, a staffed production site (a
  real early-game bootstrapping decision: dedicating a scarce settler to
  drone production instead of food, for a later payoff). Every drone is
  assigned to exactly one site, the same as a settler — no multi-cell
  service footprint. The full drone taxonomy (Basic/Advanced All-Purpose,
  Basic/Advanced Specialized, their Effort values, task eligibility, and
  battery system) lives in Buildings & Economy's Robotics Assembly rather
  than here.
- **Effort is a rate multiplier, not a pooled quantity.** A worker's Effort
  scales the rate of the site they're assigned to — 1.0 for an unmodified
  settler, varying by tier for drones (see [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)). Sites take
  one worker per slot; a building wanting genuine parallel work gets
  multiple slots, each running its own recipe independently (Kitchen is the
  model — see Buildings & Economy's [Kitchen](04_buildings_and_economy.md#kitchen)).
- **Every worker-speed modifier is a multiplicative factor** on that
  worker's base rate — Aptitude, Experience, Storied, permanent injuries,
  and sleep quality alike (see `data/settler_modifiers.csv`). They combine
  as a single product, so no application order needs defining.
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
  this worker type deployed right now."
- **The roster is also an assignment entry point**, not just informational: dragging
  an avatar with unassigned workers (A > 0) begins the same assign-to-site flow as
  picking up a worker directly, fusing "notice an idle worker" and "assign it" into
  one continuous interaction per the minimal-UI-interaction principle.
- **During Mid-Sim, each type's single row expands into one icon per actual
  worker** of that type — e.g. 3 settlers means 3 small individual icons,
  not "A/B" text — each independently showing that worker's current state,
  worker-centric rather than site-centric:
  - **Actively working** — animated (subtle, matching the low-animation-budget
    bias elsewhere in Art Design)
  - **Hazard-affected** — small overlay icon matching the worker's active
    `status_effect` (e.g. a tiny heat icon for a Temperature Extremity
    effect)
  - **Not working** — the default/idle (non-animated) appearance otherwise;
    covers any reason the worker isn't currently producing, including their
    site being unpowered when power is actually relevant to that work (not
    the case for e.g. outdoor farms) — no separate dedicated "unpowered"
    icon, it's just the absence of the working animation
  - **Drones** additionally get a permanent tiny battery-remaining bar on
    their icon, shown regardless of working state
  - Reverts to the collapsed per-type "A/B" row once the next planning
    phase opens; this expansion is Mid-Sim-only.

### Site Panel (UI)

**Selecting any built production site during Planning Phase** — staffed or
not — opens a floating **Site Panel** on the right edge of the viewport,
mirroring the Worker Roster's placement on the left (per Platform's "UI
interaction panels float over [the settlement vista] on the left and
right"). One consistent interaction regardless of building type, rather
than a UI that behaves differently depending on whether there's a real
choice to make at that particular site. Contents, always in this order:

- **Name/icon** — the site's identity, same icon used everywhere else it
  appears (grid tile, Worker Roster highlight, etc.).
- **Recipe / queue section — always present.** Shows the building's
  **production queue** (see Buildings & Economy's Building Schema) as an
  ordered list of `(recipe, limit)` steps. A single-recipe building shows
  its one recipe with an optional cycle `limit`; a multi-recipe building
  shows the full editable ordered list — add/remove/reorder steps, set each
  step's limit or mark it unlimited. An ordinary reversible planning-phase
  choice, same as any other planning action; a building with a single
  unlimited step reads as "just runs this," no different from before.
- **Assigned worker slot — always present**, including for **unstaffed**
  buildings, where it's shown but **visibly disabled** (greyed out, not
  simply absent) rather than omitted — so the panel's layout never shifts
  shape based on staffing type, and "this building can't be staffed" reads
  as clearly as "this building can be staffed but currently isn't." A
  valid drop target for assigning a worker: dragging a worker (from the
  Worker Roster, or picked up directly) **either onto this slot or onto
  the building's own grid tile** assigns them — two drop targets for the
  same action, not two different actions.
- **Production rate summary** — the site's current effective output rate,
  combining every applicable modifier into one readout: base rate, the
  assigned worker's Effort/Experience/Aptitude contribution, and any other
  active effect (Alien Soil, Fertilizer, Hybridization, and similar,
  where applicable). One combined number, not a breakdown by default — the
  breakdown lives in this element's tooltip (below).
- **Status section** — anything about the site's current standing beyond
  its production rate. Confirmed for launch: a **power-sufficiency
  indicator**, three states — **Green** (covered by Reliable Income alone,
  powered no matter what happens to fuel or weather), **Yellow** (covered
  only once Conditional Income sources are included — powered under the
  optimistic plan, genuinely at risk if fuel runs out early or a hazard
  disrupts production), **Red** (not covered even by the full optimistic
  estimate, won't be powered this season) — a planning-phase *prediction*,
  not a live Mid-Sim status, per Buildings & Economy's Resources' Energy
  Income/Consumption Rates. Each paired with a distinct **icon shape**, not
  color alone, per Design Principles' color-accessibility rule
  (illustrative: a filled circle for Green, a half-filled triangle for
  Yellow, an empty/crossed square for Red — exact shapes TBD, just
  confirmed to be shape-distinct, not color-distinct, alongside color).
  Other status-section content (beyond power) is left open for whatever
  future mechanics turn out to need a per-site status readout.
- **Every element has its own hover tooltip** (a separate small box, not a
  single panel-wide tooltip) surfacing that element's key details in
  plain language — this is specifically where the assigned worker's
  Effort/Experience/Aptitude readout lives (hovering the worker slot),
  using the existing plain-language convention ("+30% Farming speed",
  never the underlying formula) already established for those stats. The
  production rate summary's tooltip is where its full breakdown (base +
  each contributing modifier) lives, per the "one combined number by
  default" note above.

### Construction

Every settlement starts with **one construction robot**; more can be built at
Robotics Assembly, the same staffed-production pattern used for other drones.
A construction robot can, in a season, do one of three things: **build one new
building** (any type), **upgrade one existing building**, or **relocate one existing
built building** to a different valid, empty slot (or slots, for a multi-slot
building) — all three resolve the *following* season, consistent with how
production/crafting already resolves during simulation rather than instantly.

Standalone relocation moves a building the player simply wants elsewhere.
The **footprint-expanding upgrade** case is handled differently: **every
upgrade bundles a free relocation** (see [Building Schema](04_buildings_and_economy.md#building-schema)'s Upgrade
path) — the one upgrade action rebuilds the larger building on its current
cell(s) or on any other valid empty slot(s), so a lack of adjacent free
cells never blocks or double-charges the upgrade. Deposit/feature-gated
buildings stay on their deposit.

**Relocation reuses the building — it doesn't re-charge its construction
cost.** The resources spent building the original structure aren't spent
again for the move; relocation costs only the one robot-action (a season),
same as any other construction-robot task.

**Deposit/feature-gated buildings** (Mine, Quarry, Rare Metal Extractor,
Geothermal Generator — see Buildings & Economy's [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery) and [Fuel](04_buildings_and_economy.md#fuel))
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

**A second, independent per-season budget covers Fencing** (see Buildings
& Economy's [Fencing](04_buildings_and_economy.md#fencing)): construction robots together contribute a
per-season fence-tile budget (see `data/misc_balancing_values.csv`'s
"Construction" row) to a shared settlement-wide pool,
regardless of whether their one build/upgrade/relocate slot is also used
that season. The two budgets don't compete — a robot can complete its one
building **and** the settlement can still spend its fence-tile budget in
the same season, so fencing a modest area never costs a building. More
robots raise both caps, so a second (or upgraded) robot is noticeably
more capable at both. A construction robot's tooltip states both
capacities plainly (illustrative: "1 structure/season, N fence
tiles/season"). Fence tiles resolve at Post-Sim exactly like any other
construction completion (see Season Structure, below) — a painted-but-
unbuilt fence tile provides zero protection until then.

### Small Set of Impactful Actions (Current Draft)

1. **Queue a building construction or upgrade** — consumes one available construction
   robot; targets a slot on the grid (limited slots total, including a revealed
   mineral deposit for mining buildings).
2. **Assign/reassign a worker (settler or drone) to a site** — the central recurring
   decision; sticky by default, so it's an occasional action, not a per-season chore.
3. **Place/reposition a force-field or weather-protection structure.**
4. **Assign a settler to an exploration task** (occasional, every 3rd season, per the
   existing Exploration Tasks design).
5. **Adjust food-for-consumption** (see [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)) — sticky-defaulted to last
   season's diet, so only an action when the player wants to deviate from it.

---

## Season Structure

**At a glance:**
- **Planning Phase** — fully reversible; grid placement, worker
  assignment, small set of impactful actions.
- **Simulation Phase** — passive; fixed real-time window per season,
  player-adjustable playback speed (0×–5×). Three resolution moments:
  Planning Lock-in (freeze) → Mid-Sim (live production, hazard events) →
  Post-Sim (discrete outcome resolution, in a fixed sub-step order).
- **Log/event-feed** — one live-updating aggregated line per resource
  type, plus individual timestamped lines for noteworthy events; separate
  from the persistent Transmissions channel.
- **Production progress overlay** — a per-site fill gauge driven by the
  same continuous-rate value as production itself; plant-crop buildings
  get a per-transition color/icon variant instead of one continuous fill.

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
- **Passive** — no decision is ever required; adjusting playback speed
  (including pausing) is an available control, not a gameplay decision
- Production runs on the continuous-rate model described in Platform & Core Loop
  Redesign
- **Playback speed**: a continuous-feeling slider, snapping to **0.1
  increments**, rather than discrete preset buttons. **0× pauses the
  simulation outright** — no separate pause control needed, it's just the
  bottom of the same slider. See Playback Speed below for range and
  defaulting.
- Results feed into the next planning phase

**Fixed real-time window.** A season corresponds to a fixed length of real
time in the story-world (see `data/misc_balancing_values.csv`'s "Season
Structure" row, chosen to give unhurried 1× playback room to not feel
rushed) — so the simulation window has a fixed duration regardless of
what's built; playback speed is a pure time-multiplier that compresses (or
stretches, below 1×) wall-clock time without changing what happens.
Production `production_time` values and event occurrence rates are all
calibrated against this same fixed window.

**Playback Speed.** Legibility of Mid-Sim visuals (the production progress
overlay, hazard event visuals, ambient depictions) is targeted at **1×
only** — there is deliberately **no minimum wall-clock floor** guaranteeing
any visual stays perceptible at higher speeds. Increasing speed is a
legibility-for-time tradeoff placed entirely in the player's hands: a
player who wants to rush to the next planning phase without watching
things play out can do so, at the explicit cost of missing visuals (the
log remains available afterward regardless, per its retrospective-catch-up
role above).

- **Range** (see `data/misc_balancing_values.csv`'s "Season Structure"
  row): at the top of the range, the full simulation window compresses to
  a handful of wall-clock seconds — fast enough that no separate "skip
  simulation" affordance exists; cranking the slider to its max **is** the
  rush-to-next-season option.
- **Default per-season speed is sticky-carried**, the same pattern as
  food-for-consumption and other planning defaults elsewhere in this
  design: whatever speed the player last used persists automatically as
  the starting point for the next season's Simulation Phase, defaulting to
  **1×** for a player who has never adjusted it. Not a separate
  Settings-menu preference — adjusting the slider in-season is itself what
  updates the default.

**Three resolution moments, not a single timeline:**
- **Planning Lock-in** — instantaneous, right before the Mid-Sim clock
  starts. Purely a freeze: reversible planning-phase choices become fixed
  inputs for the season. No consequence is computed and nothing is revealed
  to the player here — that's Post-Sim's job, below. Hosts: the
  food-for-consumption selection becoming fixed for the season, production
  queues freezing into their season's step order (see Production Model),
  construction/upgrade/relocate actions being queued (a robot is consumed
  from the available pool the instant the action is queued, not when it
  later completes), and an Exploration Task's Ration cost and required item
  being consumed (see Settlers & Exploration's [Assignment](05_settlers_and_exploration.md#assignment)).
- **Mid-Sim** — the only place real time actually passes. What actually
  runs here:
  - **Production, landing live.** Every production cycle (continuous-rate,
    or a plant-crop building's own persistent state-transition sequence —
    see Buildings & Economy's [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model)) writes its
    output to the general inventory **the instant that cycle completes** —
    not batched to
    Post-Sim. This repeats every time a short cycle finishes within the
    30s window. A Fuel-based Generator's Fuel draw is likewise live, so it
    can burn Wood/Fossil Fuel arriving from a concurrent Clear-Cutting or
    mining operation in the same window — the deliberate "gather fuel
    just-in-time" tension (see Buildings & Economy's [Fuel](04_buildings_and_economy.md#fuel)).
  - **The Energy/Water live-rate machinery** (see Buildings & Economy's
    [Resources](04_buildings_and_economy.md#resources) and [Water](04_buildings_and_economy.md#water)): continuous Income/Consumption recomputation,
    the random un-powering/un-watering pass on a shortfall, and the
    plant-crop buildings' Water-reservation pool (drawn during each
    building's passive/biological-wait transitions) all run here,
    recomputed on every event that changes the totals.
  - **Discrete events** with a genuine reason to occupy a specific interval
    rather than resolving instantly — In-Simulation Hazard Events are the
    clearest example (a storm has a start time and duration, not lasting
    the whole season).
  - **Purely ambient visual depictions** of Post-Sim-resolved activities,
    for legibility/immersion (see [Art Design](07_production_and_technical.md#art-design)) — e.g. a Scanner Station's
    radio-wave pulse, or a survey settler wandering the grid — with no
    coupling to the actual mechanical resolution.
- **Post-Sim** — discrete resolution with no running simulation,
  right after the Mid-Sim clock ends. Merges what could otherwise be two
  separate moments (right after the clock ends, and the top of the next
  planning phase) into one mechanically-equivalent bucket, since neither
  involves real time passing. (Post-Sim is named for when it happens —
  unlike Planning Lock-in, it never occurs before a season's Mid-Sim has
  actually run.) This is where the season's actual outcomes resolve:
  Vaccine unlock threshold checks, pooled nutrition consumption resolution,
  Scanner Station report resolution (the mechanical `Confidence`/`MatchedRisk`
  update), Deposit Discovery survey mechanical resolution, Trade Agreement
  resolution (see Settlers & Exploration's Escalation Chains), and
  construction/upgrade/relocate actions completing. Exploration task results
  are a special case within Post-Sim: they get a **dedicated confirmation
  UI** at the start of the next planning phase, rather than resolving
  silently — the resolution itself, not just its reveal, sits at that tail
  moment (this is also where a Trade Agreement's own three-way offer dialog
  appears, since it rides the same confirmation-UI mechanism).
  - **Internal sub-step order**: (1) Scanner Station report resolution, (2)
    Deposit Discovery survey resolution, (3) pooled nutrition consumption
    resolution, (3.5) Trade Agreement resolution — deliberately right after
    nutrition, so survival needs get first claim on any resource an
    agreement also happens to use (Rations, most notably), before trade
    obligations are paid — (3.6) wild animal population resolution, itself
    ordered **carrier infections → husbandry-site destruction → population
    growth** (see Planets & Scoring's [Wild Animal Populations](06_planets_and_scoring.md#wild-animal-populations); infections land
    here since a carrier case can itself be what confirms a bio-threat for
    step 6, below) — (4) construction/upgrade/relocate/fence-tile
    completions, (5)
    Exploration Task confirmation UI (start of next planning phase), (6)
    Vaccine/countermeasure threshold check — placed **last, unconditionally**,
    after every `Confidence`-feeding source for the season has landed
    (including exploration-driven and carrier-infection-driven ones), rather
    than branching on which source pushed it over the threshold. Steps 1, 2,
    3.6, and 4 have no dependencies on each other; their relative order is
    arbitrary except that 3.6 must precede 6.
  - **Step (4)'s internal order**: its multiple completions resolve in the
    same order the player originally queued the underlying actions during
    planning — the same order already backing planning's undo-history, not
    a category-based rule (e.g. "relocations before upgrades"). This is
    what makes a same-season "relocate a blocker off tile T, then
    build/upgrade onto T" sequence sound at all: the later action could
    only have been planned without a footprint conflict because the
    relocation was queued first, so replaying that same order at
    resolution preserves it for free. Fence tiles (see Buildings &
    Economy's [Fencing](04_buildings_and_economy.md#fencing)) resolve here too, interleaved in the same
    planning-queue order as everything else in the step.
  - **Why nutrition consumption waits for Post-Sim** rather than resolving
    at Planning Lock-in alongside the food-for-consumption selection: food
    produced *during* the season should itself be consumable that same
    season, and it already lands live in inventory through Mid-Sim (above)
    — but nutrition itself is deliberately **not** drawn down in real time
    as it's produced. The whole season's consumption resolves as one lump
    at Post-Sim, which is also the natural point to apply its Tier-1/Tier-2
    consequences (see Settlers & Exploration's [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)) as
    season outcomes rather than a pre-season freeze. This keeps nutrition a
    once-a-season concern, not a fifth live rate alongside Energy/Water —
    the player's forward visibility into it comes from a **planning-phase
    prediction readout** instead (see Food & Nutrition's [Consumption — Pooled, Not Per-Settler](05_settlers_and_exploration.md#consumption--pooled-not-per-settler)),
    the same "optimistic estimate, not a guarantee" role the Energy bar
    already plays.

**The log/event-feed system** is a single, live-updating log covering only
the most recent season and its following Post-Sim:
- **No separate always-visible overlay.** The default simulation view has no
  forced log clutter — just ambient visuals and the progress bar. A single
  log is opened via a button/icon, and can be opened **during** simulation
  too, live-updating in real time, not just reviewed after the fact.
- **Routine production is aggregated, not logged tick-by-tick.** One running,
  live-updating log line **per resource type** (not per building) — e.g. a
  single "+N Grain" line that increments and re-timestamps itself to the most
  recent contributing tick, regardless of how many sites are producing it.
  This avoids a dozen-plus simultaneous production sites spamming the log
  with individual tick entries. Aggregated production lines are still fully
  legible entries, not hidden or deprioritized — they're just consolidated.
- **Noteworthy Mid-Sim events get their own individual, timestamped
  lines**, interspersed with the aggregated production lines: hazard
  occurrences, settler deaths, and similar.
- **Post-Sim outcomes go in an after-the-season section** at the end of the
  log, stamped at season end: vaccine unlocks, Deposit Discovery reveals,
  exploration escalations unlocking, and similar.
- **Transmissions stays fully separate** — the persistent, cross-season,
  narrative-flavored channel (see Story & World's Gameplay-Story
  Integration) serves a distinct purpose (advance warnings, flavor, Herald's-
  voice reports) from this per-season mechanical log, and that split is
  preserved rather than merged.

**Production progress overlay.** Every active production site gets a
per-tick visual during Mid-Sim: the building/field sprite is rendered
semi-transparent, with an opaque fill rising from the bottom as the current
cycle progresses, capped by a thin white line marking the opaque/transparent
boundary — a fill gauge shaped by the sprite itself rather than a separate
UI bar. Driven directly by the same continuous-rate progress value from
[Production Model](#production-model) (`100% / production_time` per
second), so it costs nothing new to compute — a scaling overlay mask on a
sprite that's already at a fixed grid location for the whole simulation
window. This is the *primary* at-a-glance channel for "what's happening
right now" during simulation — deliberately redundant with the aggregated
log above, which serves a different purpose: players won't be parsing log
text in real time during simulation (at best skimming it), so the log's
real job is slow, retrospective understanding of what happened, especially
after fast/skipped playback, not moment-to-moment legibility. The overlay
carries that moment-to-moment job instead.

**Farm-specific variant: state-colored fill.** The four plant-crop
buildings (see Buildings & Economy's Farm/Production) each track a
persistent per-site state sequence instead of one continuous-rate cycle
(and the sequence genuinely differs per building — see Production Model,
above), so their overlay differs from every other production site in two
ways: the fill **resets to empty and refills from 0% at the start of each
transition** rather than one continuous 0–100% arc across the whole cycle,
and the fill color changes per transition, per Design Principles' "color is
never the sole channel of information" rule paired with a small **icon
badge** per transition (e.g. a plow / seed / sprout / sheaf icon) so it
reads without relying on color alone. **Open**: the exact color/icon
mapping needs to be authored per building, since each one has its own
distinct state count and shape — see `DESIGN_TODO.md`. Every other production
site — the four animal-based buildings (for now) and all non-farm
infrastructure — keeps the single continuous fill described above,
unaffected.

**Assigned-worker Mid-Sim depiction.** A worker stickily assigned to a
production site is shown as a static sprite parked at/near that site for the
whole Mid-Sim window — no walking, since Production Model no longer requires
a worker to physically move to tend a site; a minor idle frame (bob, subtle
gesture) is fine, but no locomotion. This is purely an ownership/presence
cue, not a legibility mechanism — "where is this worker deployed" is already
answered by the Worker Roster's hover-highlight (see [Worker Roster
(UI)](#worker-roster-ui)), and per-worker status (working / hazard-affected
/ battery) lives on the roster's per-worker icon (see Worker Roster (UI)),
not on this on-site sprite.

---

## Technology & Progression

**At a glance:**
- **Within a Run** — resource-gated, not time- or research-gated; basic
  designs need Energy + Lumber/Concrete, advanced designs need
  planet-side materials.
- **Agriculture Branching** — Advanced Greenhouse path vs. Local
  Agriculture path (Hybridization); both converge on the Kitchen.
- **Across Runs** — meta-progression, not yet designed.

### Within a Run
- Progression is **resource-gated, not time-gated or research-gated.**
- Settlers arrive with blueprints for all known designs. What limits fabrication is
  having enough of the required materials.
- **Basic designs** require only Energy and the two universal construction
  materials, Lumber and Concrete.
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

- **Local Agriculture Path** — hybridize Earth crops with native planet-side flora.
  Favored on planets with a **hospitable atmosphere** but **scarce building
  resources**. Concretely realized as **Hybridization** (see Buildings &
  Economy's [Farm/Production](04_buildings_and_economy.md#farmproduction) and [Research Lab](04_buildings_and_economy.md#research-lab)): an exploration discovery
  unlocks research for one specific plant-crop building at a Research Lab;
  completing it permanently changes that building type for the rest of the
  run, immune to the Alien Soil growth penalty every non-hybridized plant
  crop otherwise carries, plus a planet-specific signature benefit (reduced
  Water need, Temperature Extremity immunity, or higher yield, depending on
  what defines that planet's identity).

Both paths converge on the Kitchen for meal crafting; the crops produced differ but
the food system is the same. The path taken affects score factors (efficiency vs.
adaptability) and which advanced designs become accessible.

*Planet types will be designed to make one path clearly more efficient while leaving
the other viable — not to make one path always correct.*

### Across Runs (Meta-Progression)

Cross-run progression — any permanent change a completed run makes to future
runs, beyond the run-history record — is **not yet designed**; several avenues
are intended. See Story & World's [Meta-Progression](02_story_and_world.md#meta-progression)
and `DESIGN_TODO.md`.
