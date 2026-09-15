# Design To-Do — Faction-Driven System Gaps

Tracks remaining content/system design work in `full_design/`, organized around
what each SEED Faction's scoring formula still needs to become concrete and
buildable. All five faction formulas are done (see Win/Lose Conditions); this
tracks what's needed *underneath* them.

> A per-system design audit (2026-09-02) is consolidated in **Design Audit
> (2026-09-02)** at the end of this file — organised by system rather than by
> faction. Full per-system reports live in `full_design/audits/`.

## Per-Faction Status

- [x] **Development Bloc** — formula done
  - [ ] Rarity weights per resource (not yet assigned)
  - [x] Real buildings/items catalog carrying `TechAchievement` values — see
    Buildings & Economy's [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog); the 0–4 rubric, the counting
    rule (each distinct entry counts once per run, not per unit/copy), and
    per-entry values are all written in. Exact numbers are a first pass,
    same as every other illustrative number in this design — revisit
    during balancing, not urgent to track here further.
- [x] **Frontier Legends** — formula done
  - [ ] Catalog of named "hard sites" with legend-values

## Open Items

- [ ] **Fabrication chain revisit — still open pieces**: this pass (see
  Buildings & Economy's Resources and Fabrication) replaced Matter with
  Lumber/Concrete as the universal construction-cost materials, split
  Carpenter's Shop into a starting Sawmill (Lumber only) + Carpenter's Shop
  upgrade, split Stone Processing into a starting Stone Processing I
  (Concrete only) + Stone Processing II upgrade (adds Silicon), introduced
  Leather (tanned from Pelts) alongside Fabric, added the Wooden Plow, and
  widened High-Tech Components into several more recipes and structures.
  **Wooden Plow's gameplay mechanics are now resolved** — a
  passive-stock-check item (same pattern as PPE/Temperature-Resistant Gear)
  reducing the Planting phase duration of all four plant-crop buildings
  settlement-wide (illustrative -15%, see Fabrication and Farm/Production's
  Production Cycle). Still to do:
  - Per-building **Lumber:Concrete construction-cost ratios** across the
    whole catalog — this pass established the rule (and Quarry's specific
    small-Lumber-only cost) but deferred assigning the actual ratio for
    every other building.
  - Sawmill→Carpenter's Shop and Stone Processing I→II **upgrade costs** —
    TBD.
- [x] **Farm production cycle (plant-crop buildings)** *(superseded — see
  "Plant-crop production redesign: per-building state machines" below: the
  shared three-phase model this item describes was later replaced by four
  genuinely distinct per-building state machines)* — resolved: the four
  plant-crop buildings (Grain Field, Fruit Orchard, Fiber Field, Timber
  Grove) now run a three-phase **Planting → Growing → Harvesting** cycle
  instead of the single continuous-rate model every other production site
  uses (see Core Loop & Grid's Production Model exception note and
  Buildings & Economy's Farm/Production's Production Cycle). Planting and
  Harvesting are Effort-driven (Planting additionally sped by Wooden Plow);
  Growing needs no worker present (still sticky-assigned, just idle),
  is governed by Alien Soil/Hybridization not Effort, and gates on a
  **water-draw queue** *(superseded — see the Post-Sim resolution-order
  pass below: this FIFO shape was later replaced by a random-shortfall
  pool matching Energy's)* — a single settlement-wide FIFO queue requesting
  each building's crop-specific Water amount, strictly ordered with no
  skip-ahead even when the pool could cover a smaller request further back
  (deliberate: the intended player skill is keeping total supply ahead of
  total demand, not gaming service order), ties broken by build/placement
  order, re-joining the back of the queue every cycle. The production
  progress overlay gained a farm-specific variant to match: fill resets
  and recolors per phase (brown/green/gold) with a redundant icon badge
  per Design Principles' color-accessibility rule (see Core Loop & Grid's
  Season Structure). Farm buildings stay pinned to a 1-tile/1-worker cap
  (upgrades only reduce `production_time`, never raise the cap). **Still
  open** at the time: exact per-phase duration split for each building —
  since resolved, see below.
- [x] **Plant-crop production redesign: per-building state machines
  (2026-09-04)** — resolved: the shared three-phase model above is replaced
  by four **genuinely distinct persistent per-site state machines** (see
  Buildings & Economy's [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model) and the four building
  entries), specifically so the four buildings stop reading as
  color-tinted versions of one shape: **Grain Field / Fiber Field**
  (`unprepared → plowed → growing → harvestable → unprepared → …`, replants
  every harvest — an annual-crop shape, 7s/8s full cycle); **Fruit Orchard**
  (one-time `unprepared → planted → mature`, 31s, then a repeating
  `mature ⇄ fruiting` loop forever, 4–6s per Fruit with `k` re-rolled every
  cycle — a tree-crop shape); **Timber Grove** (one-time
  `unprepared → growing → cycle-harvestable`, 16s, then a
  `cycle-harvestable → cycle-harvestable` self-loop forever, 5s/Wood — a
  managed-woodlot shape, with a unique completion gate: the self-loop's
  timer progresses without a worker, but only actually completes — adding
  Wood, restarting the loop — once a worker is present, so a fully-grown
  batch can sit ready-and-waiting rather than producing for free).
  **General rules established**: every transition is either short/worker-
  active (**restarts** from zero if interrupted at a season boundary) or
  long/passive-biological-wait (**pauses**, progress held); Water is drawn
  during every passive/biological-wait transition and only those (folded
  into the same random-shortfall pool as the Growing-phase draw always
  was); Alien Soil applies to the same passive set; every transition away
  from `unprepared` gets a drastic (≥50%, TBD exact) speed-up from a Wooden
  Plow (settler / All-Purpose Drone) or **inherently, no Plow needed, for a
  Farming-Specialized Drone** (stacks on top of its Effort multiplier — see
  Buildings & Economy's [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)). **Still open**: the production-progress
  overlay's color/icon mapping needs authoring per building now that each
  has its own distinct state count and shape, rather than one shared
  three-phase brown/green/gold mapping (an Art Design item); the four
  animal-based buildings' still-undefined Water draw and production model
  — a design pass for those is the immediate next step.
- [x] **Production building UI (planning phase)** — resolved: selecting
  any built production site (staffed or not) opens a **Site Panel** on the
  right edge, mirroring the Worker Roster's placement on the left (see
  Core Loop & Grid's new Site Panel (UI) section). Always shows: name/icon;
  a recipe section (a plain indicator for single-recipe buildings, a
  click-to-switch selector for multi-recipe ones); an assigned-worker slot
  (present-but-disabled for unstaffed buildings, valid drop target either
  there or on the building's own grid tile); a combined production-rate
  summary (base + Effort/Experience/Aptitude + other modifiers as one
  number); and a status section, including a power-sufficiency indicator
  (Green/Yellow/Red, shape-coded not just color-coded — see the resolved
  **Energy Pool per-building powered state** item below). Every element
  has its own hover tooltip — this is specifically where the assigned
  worker's Effort/Experience/Aptitude readout lives, and where the
  production-rate summary's full breakdown lives. **Still open**: any
  status-section content beyond power is unaddressed.
- [x] **Production queue & limit-amounts (2026-09-09)** — resolved: every
  production building runs an ordered queue of `(recipe, limit)` steps
  instead of one recipe/season (limit = cycle count or unlimited),
  advancing circularly, skipping steps whose inputs are unavailable
  (skip ≠ remove; limit-hit = remove for the season), going dormant with
  its worker idle if every step skips, and re-checking dormant queues each
  quarter-season. Inputs consumed and any success roll made at cycle start.
  Fuel-based Generator's fuel-limit is subsumed as a step `limit`. See Core
  Loop & Grid's Production Model / Site Panel and Buildings & Economy's
  Building Schema. **Still open**: whether animal-husbandry buildings sit
  inside this system (deferred to the husbandry cycle design).
- [x] **Food Storage / Rations / Ration Press rework (2026-09-09)** —
  resolved (surfaced by the parasite/infected-food design): long-term
  storage now holds **bulk sanitized Ration-content only**, fed exclusively
  by a Ration Press's new **Stockpile Fill** recipe — raw food, meat, and
  Meals can no longer be deposited directly, which dissolves the
  "invisible infected food into storage" problem by construction. The
  Ration Press becomes cycle-based (not instant), unstaffed, with
  player-selectable inputs (default-all + opt-out blacklist), two recipes
  (packaged Rations / Stockpile Fill), and its old `min(P,F,C,V)/2` formula
  dropped — Rations are now **flat sustenance** with no axis profile.
  Stockpiling is **reversible with friction**: a staffed Food Storage runs
  a poor-rate extraction (bulk → packaged Rations) as a last-resort valve.
  `NutritionStockpile` becomes a flat quantity (`sqrt`-flattened) measured
  at a **run-end snapshot**. `03` Planning Lock-in no longer lists Food
  Storage deposits. **Still open**: exact conversion ratios and extraction
  rate (balancing); Emergency Medical Kit recipe/role and PPE tier (see
  small-gaps items in the animal-system brainstorm).
- [ ] **Planning-phase undo/redo** — add a planning-wide undo/redo action
  covering every reversible planning choice (placement, assignment, queue
  edits, food-for-consumption, construction queuing): redo available after
  an undo only while nothing new has
  changed, undo reachable back to the start of the planning phase. Surfaced
  during the production-queue design pass (2026-09-09).
- [x] **Energy Pool per-building powered state** — resolved via a full
  redesign of Energy itself (see Buildings & Economy's Resources' Energy
  Income/Consumption Rates): the old Cap/Income/Draws accumulated-balance
  model is replaced entirely by two continuously-tracked **live rates**,
  Income and Consumption (Energy/s), with **no stockpile at all** — nothing
  is ever "spent" from a reserve. Income splits into **Reliable** (Solar
  Array, Geothermal — constant, no failure mode) and **Conditional**
  (Fuel-based Generator — contributes only while actively burning, can
  fall short of plan). When total Consumption exceeds total Income at any
  Mid-Sim moment, enough active consumers are shed **randomly** to close
  the gap — deliberately not by build order or player priority, so
  managing outage order never becomes optimizable play; recomputed only on
  real change events (a Conditional source's window starting/ending, a
  hazard starting/ending, a building built/destroyed/toggled), not every
  tick. Every building gets the active/inactive toggle Fuel-based Generator
  already had. Planning-phase UI is a bar from 0 to the season's optimistic
  max Income (assumes every Conditional source runs its full window),
  showing both planned Income and planned Consumption as separate
  indicator lines, with a tooltip caveat that it's a best case, not a
  guarantee. This directly resolves the Site Panel's power-sufficiency
  indicator too (see Core Loop & Grid's Site Panel (UI)): Green = covered
  by Reliable alone, Yellow = covered only with Conditional included (a
  genuine planning-phase *prediction*, not a live status), Red = not
  covered even optimistically — shape-coded, not color-alone, per Design
  Principles. Side effects also folded in: the exploration reroll cost
  moved from Energy to **Rations** (see Settlers & Exploration's
  Exploration Tasks — deliberately the same resource that funds launching
  a task, for a felt tension), Weather/Row Shield's event-driven cost and
  drone battery recharge are now both just "temporarily elevated
  Consumption," competing in the same random-shedding pool as everything
  else rather than needing their own bespoke mechanics.
- [ ] Remaining numeric TBDs from the Settler State / Injuries / Storied
  design pass: Storied's `legend_value` threshold; the Temperature
  Extremity settler death-probability on extreme exposure; Trapping's and
  Clear-Cutting's per-settler speed rates.

## Core Loop / Structural Gaps

- [ ] **Season simulation** — in progress. **Resolved so far**: fixed
  real-time window length (seasons correspond to fixed real-world time
  in-fiction; playback speed stays a pure time-multiplier); three resolution
  moments — **Planning Lock-in** (instantaneous, right before the Mid-Sim
  clock starts; reversible planning choices simply freeze into fixed
  inputs — food-for-consumption selection, per-building production-queue
  step order, construction/upgrade/relocate queuing — no consequence
  computed, nothing revealed), **Mid-Sim** (the only place real time passes
  — continuous production plus any discrete event with a genuine reason to
  occupy a specific interval, e.g. hazard events), and **Post-Sim** (instantaneous,
  merges the moment right after the clock ends with the top of the next
  planning phase, since neither involves real time passing — renamed from
  the old single "Outside-Sim" now that the pre-clock moment has its own
  Planning Lock-in bucket; hosts actual season-outcome resolution: Vaccine
  unlock checks, pooled nutrition consumption resolution — deliberately here
  rather than Planning Lock-in, so mid-season production is consumable that
  same season — Scanner Station report resolution, Deposit Discovery
  resolution, construction/upgrade/relocate completion); the "ambient
  Mid-Sim visual for a Post-Sim-resolved activity" pattern (see Art Design);
  the **log/event-feed system** (see Core Loop & Grid's Season Structure) —
  a single togglable log (no forced overlay), per-resource-type aggregated
  production lines that live-update/re-timestamp, individual lines for
  noteworthy events, Transmissions kept fully separate; the **production
  progress overlay** (see Core Loop & Grid's Season Structure) — a per-tick
  semi-transparent bottom-up fill on each active production site's sprite,
  driven directly by the continuous-rate progress value, established as the
  primary at-a-glance channel (deliberately redundant with the log, which
  serves slower retrospective parsing instead); the **internal sub-step
  order within Post-Sim** (see Core Loop & Grid's Season Structure) —
  Scanner Station report resolution, then Deposit Discovery resolution,
  then pooled nutrition consumption, then construction/upgrade/relocate
  completions (relative order among these four is arbitrary — no
  dependencies), then the Exploration Task confirmation UI at next
  planning-phase start, then the Vaccine unlock threshold check
  unconditionally last (after every `Confidence`-feeding source for the
  season, including exploration-driven ones, has landed); the **assigned-worker
  Mid-Sim depiction** (see Core Loop & Grid's Season Structure) — a static,
  non-walking sprite parked at/near the assigned site, purely an
  ownership/presence cue; and the **Worker Roster's Mid-Sim expansion**
  (see Core Loop & Grid's Worker Roster (UI)) — one icon per actual worker
  during simulation (vs. one row per type during planning), each showing
  working/hazard-affected/idle state, with drones additionally always
  showing a battery-remaining bar; **Hazard Event concurrency** (see Planets
  & Scoring's In-Simulation Hazard Events) — only Storm and Temperature
  Extremity manifest as discrete Mid-Sim events at all (Atmospheric Hazard
  is a continuous check, Bio-hazard only resolves via exploration
  encounters), each capped at most once per season by its one-report/season
  evidence source, and when both occur with overlapping windows at the same
  site their consequences stack independently (no double-destroy — a
  second destruction check against an already-emptied slot is a no-op);
  **Playback Speed** (see Core Loop & Grid's Season Structure) — the
  Mid-Sim window is now **30 seconds at 1×** (was 15s in the prior
  implementation, widened so unhurried 1× playback has room to not feel
  rushed); speed is a **continuous-feeling slider from 0× to 5×, snapping
  to 0.1 increments**, rather than discrete preset buttons, with **0× as
  an outright pause** (no separate pause control, and this is also the
  resolution to mid-simulation pause/resume — 0× on the same slider *is*
  pause); Mid-Sim visual legibility (production overlay, hazard events,
  ambient depictions) deliberately **targets 1× only**, with no minimum
  wall-clock floor at higher speeds — a legibility-for-time tradeoff placed
  entirely in the player's hands, on the same "log covers what you missed"
  precedent as the production progress overlay above; the standalone "Skip
  simulation" button from the prior implementation is **removed** —
  cranking the slider to its 5× max (30s → 6s) is the only rush-to-next-
  season option; and the **default per-season speed is sticky-carried**
  (the same pattern as food-for-consumption and other planning defaults),
  starting at 1× until the player first adjusts it, rather than a separate
  Settings-menu preference. No further specifically-identified open
  sub-items remain for Season Simulation at this pass — left unchecked
  below since this reflects the currently-known gap list, not a claim that
  every possible gap has been surfaced.
- [ ] **Run-start flow** — Surfaced while scoping the per-system design
  audit. **Largely resolved (2026-09-03):** the ordered screen sequence
  with its two commit points (wormhole confirmation, land-at-site
  confirmation), reversibility between them, the starting loadout, and
  Starting Settlement Placement (the T-tetromino) are written into Core
  Loop & Grid's Run-Start Flow / Starting Settlement Placement; the hub's
  five destinations are in Story & World's Earth Hub Contents; the
  Settlement Base is in Buildings & Economy; Season 1 is confirmed an
  ordinary season, and the one-time SEED summary transmission lands at the
  top of Season 1 planning. **Still open:** Run History's actual
  presentation (see also `12-SF7`), and the Settings screen(s), not
  designed anywhere yet (see `12-SF5`).
- [ ] **Meta-progression redesign** — cross-run progression is currently only
  a loose definition ("any cross-run change to the game outside of run
  history"; see Story & World's Meta-Progression and Core Loop & Grid's Across
  Runs). The earlier single mechanism — gather enough of a previously-unseen
  resource type during a run → Earth develops new catalog designs from it,
  unlocked for future runs — was **dropped as too narrow**: a story-era guess
  made before the surrounding systems were settled. Needs a real design
  spanning several intended avenues. Fodder, not yet designed:
  - Per-faction score thresholds unlock a game-changing element — e.g. once
    Frontier Legends passes a threshold, its recruitment ramp guarantees
    every future crew one legendary-tier "hero" settler.
  - A small chance, on establishing trade with a technologically advanced
    alien species, to unlock a technology humans do not (and in-fiction never
    would) invent on their own, via that relationship.
  - Better wormhole-opening technology raises the Specialization mass budget
    (see Core Loop & Grid's Specialization) and widens/cheapens its pool —
    e.g. affording an advanced worker, or two directions at once. This
    **absorbs the old "wormhole mass-threshold stabilization tech" axis**
    (audit `12-SF3`): the base starting loadout is now a flat "one
    Settlement Base + three other starting buildings + one construction
    robot" (see Core Loop & Grid's Run-Start Flow), and any cross-run
    variation on it belongs to this redesign rather than a separate axis.
  Sequenced **after** the initial-run-state work.
- [x] **Construction as a Mid-Sim progressive activity — decided against
  (2026-09-15).** Surfaced 2026-09-10 during the fence design, which
  wanted a robot to be able to build one building *and* fence a small area
  in the same season without one competing against the other. Considered
  generalizing Fencing's bespoke tile-by-tile Mid-Sim build into a full
  progressive-construction rework (partial progress carried across
  Mid-Sim, work costs per building, a new cross-season-carryover question)
  but chose a lighter model instead: construction robots get a **second,
  independent per-season budget** of *N* fence tiles (TBD), orthogonal to
  their one build/upgrade/relocate action, so both can happen the same
  season without competing for the same slot. Both budgets stay flat and
  atomic — no progress bars, no partial state, no new cross-season
  question — and scale with robot count, so an extra/upgraded robot is
  noticeably better at both; a construction robot's tooltip states both
  capacities plainly. Fence tiles now resolve at **Post-Sim** like any
  other construction completion (in the same planning-queue order as
  everything else in that step — see the Post-Sim resolution-order pass,
  below) instead of their own bespoke Mid-Sim mechanic; the tile-by-tile
  fill-in survives only as a purely cosmetic Mid-Sim depiction with no
  mechanical coupling. See `03` [Construction](03_core_loop_and_grid.md#construction) and `04` [Fencing](04_buildings_and_economy.md#fencing). Also
  resolves audit items `1-SF1`/`2-SF2` (intra-Post-Sim construction
  ordering — see the Post-Sim resolution-order pass, below); `1-SF7`/
  `1-SF8` remain untouched by this decision.
- [ ] **Run length — definiteness & motivation** — a run is currently
  **15 seasons**, but this number has no diegetic justification and the
  length should be revisited: does it want a clearer in-fiction reason
  (supply windows, the hypervelocity-star timeline, a SEED mandate), and is
  15 the right value — should some planets/factions/modes shorten or extend
  it? Surfaced 2026-09-10 during the wild-animal-population design.
- [ ] **Story mode vs. Atemporal mode** — two cross-run modes in the
  meta-progression frame:
  - **Story mode** — a real countdown of years to the **hypervelocity
    star's arrival** (the doomsday the whole expedition exists to outrun),
    plus faction-driven story events and special curated planets to target.
    Runs are finite in number; the countdown ending is the end of the game.
  - **Atemporal mode** — meta-progression but **no countdown**: the
    doomsday looms permanently, and the player takes as many runs as they
    want. The endless/practice framing.
  Needs design of what the countdown actually gates/changes, how story
  events slot in, what "curated planets" are, and how meta-progression
  differs (if at all) between the two. Surfaced 2026-09-10.

## Newly Surfaced Ideas (recorded, not yet designed in detail)

- [ ] **Multi-item production by skilled workers** — a high-Experience or
  high-Aptitude worker at certain sites should be able to produce
  **multiple item types at once** in a single production step, rather than
  the production queue's normal one-recipe-at-a-time sequencing. Motivation:
  as a run's commitments compound, the worker count needed to keep every
  early-tier recipe staffed separately grows fast; letting a skilled worker
  combine several low-tier outputs into one step is meant to blunt that
  growth without removing the underlying complexity. Needs careful
  integration with the production queue (see Buildings & Economy's
  [Building Schema](04_buildings_and_economy.md#building-schema) "Production queue") — this is a different kind of step
  (parallel outputs) than the queue's sequencing (ordered outputs) and the
  two need to compose cleanly. Which sites/tiers/skill thresholds qualify
  is entirely open. Surfaced 2026-09-14 during the tiny/small-animal-counter
  design (Traps' Carpenter's Shop recipe).
- [ ] **Luxury-item catalog & Habitation boosts** — Luxury Living Quarters
  (see Buildings & Economy's Habitation) gives one luxury-item slot per
  settler; each *distinct* luxury item held in a slot grants one
  settlement-wide boost. Undesigned: which luxury items exist, where they
  come from (fabrication? Trade Agreements? alliance rewards?), what each
  one boosts, and how strong the boosts are. Surfaced by the run-start /
  Settlement Base design pass (2026-09-03).
- [x] **Alien trade economy** — resolved as **Trade Agreements** (see
  Settlers & Exploration's Escalation Chains' Deepening an alliance):
  neither a dedicated interface nor an automatic passive trickle — a
  deepening follow-up exploration task's existing confirmation dialog can
  offer **three candidate agreements** (each a fixed expense/income
  resource pairing with per-season quantities), the player picks one with
  no reroll, and the first exchange happens **one season after acceptance**
  (not immediately). Resolves every season thereafter in Post-Sim
  (right after pooled nutrition consumption, before construction
  completions); missing the expense payment **permanently ends** the
  agreement (dialog-notified), freeing its slot toward the **cap of three
  concurrently active** agreements. Income-side resources are restricted
  to raw/harvested materials plus Lumber/Concrete/refined metals —
  excludes cooked Meals, Luxury Goods, Fabric/Leather, deep-manufactured
  goods, and Rations; expense side is unrestricted. Energy and Water are
  excluded entirely (income or expense), since both are rate-tracked with
  no stockpile to exchange. Also resolves Local Delicacy's ingredient
  sourcing (see Buildings & Economy's Food/Meal Conversion): the alliance
  unlocks the recipe, a Trade Agreement is what actually supplies the
  ingredient. Same underlying gap as "Peaceful Contact's base alliance
  rewards" below — that item's remaining scope is now just the *numeric*
  TBDs (exact resource pairs/quantities per offer, exact deepening tier
  count/cadence), not the structural question, which this resolves.
- [x] **Water resource open threads — settler shortfall + Reclamation gate
  resolved**: Water is now tracked as a live **Income rate** (Water/s), not
  an accumulated stock — the same shape as Energy's redesign (see
  Buildings & Economy's Water and Resources' Energy Income/Consumption
  Rates). Settler Water shortfall is **not** a mirror of nutrition's
  Tier-1 headcount-vs-quantity model — it's a single binary check resolved
  once per season at Post-Sim: zero Water Income anywhere this season kills
  every settler; any nonzero production avoids the consequence entirely,
  with no partial/proportional in-between and no competition with
  production's own Water draws. Reclamation's gate: the Water Processing
  Plant's upgrade cost now includes **High-Tech Components** alongside
  Lumber/Concrete, reusing the existing advanced-tech-gate pattern (e.g.
  Scanner Station) rather than a new mechanism; note its consumption-rate
  reduction has no bearing on the now-binary settler check, so it's really
  a farming-throughput upgrade (eases the plant-crop water-draw queue), not
  a settler-safety one. The plant-crop water-draw queue itself was updated
  to reserve a consumption-rate share instead of drawing a lump sum, to
  match the new rate model (see Farm/Production's Production Cycle).
  **Still open**: the four **animal-based buildings'** (Dairy Pasture,
  Poultry Coop, Sheep Pasture) flat per-cycle Water requirement still has
  no defined insufficient-Water behavior — unlike the plant-crop buildings'
  Growing-phase queue, nothing specifies what happens if available Water
  Income can't cover an animal building's draw. Goal remains getting *all*
  water usage across the catalog into a fully designed state.

## Other Fabrication-Adjacent Gaps

- [x] **Livestock vaccines** — *superseded* by the Animal System brainstorm
  below (husbandry-animal parasites, settlement-wide per type, resolved by
  the unified Medical Bay countermeasure with permanent auto-immunity).
- [ ] **Glass — broader uses** — Glass is currently input only to High-Tech
  Components, Temperature-Resistant Gear, PPE, and Biological Lab Materials.
  Worth 1–2 more homes so it isn't a one-purpose material — candidates:
  further hazard-resistant gear, a Luxury Good, Scanner Station optics.
  Surfaced 2026-09-09 when Glass was added as a Stone Processing II output.
- [ ] **Hydroelectric Generator + River feature** — surfaced as a side note
  during the Energy Pool redesign, not yet designed. Would need a new
  **River** grid feature first — checked, and confirmed this was only ever
  mentioned conceptually during the original Water design pass, never
  actually formalized as a feature anywhere. A genuinely new piece of scope,
  deliberately deferred rather than bundled into the Energy Pool rework.
- [ ] **Hybridization numeric details still TBD** — surfaced while building
  out the exploration content catalog. Exact Water-reduction amount (Arid),
  yield-boost amount (Verdant), Research Lab `production_time` per project,
  and the generic "broad yield improvement" magnitude for the
  planet-independent (meteorite-fragment-unlocked) hybridization path are
  all still unspecified — deferred to balancing like other numeric values
  in this design, but flagged here so they don't get lost.
- [x] **Alien civilization classes** — mostly resolved (see Settlers &
  Exploration's Escalation Chains): five axes (Technology Level, Openness,
  Economic Stability, Ubiquity, Unity) combine into four curated classes
  (Verdant Assembly, Hollow Kilns, Drift Caravans, Frostbound Remnant)
  rather than a full cross-product. First Contact surfaces as one pool slot
  with three switchable approaches — Peaceful Contact, Bluff/Coercive
  Exploitation, Military Exploitation — and Stewardship Caucus gained a new
  `ContactRestraint` formula term. **Still open, deferred to balancing:**
  - Exact `ContactRestraint` tier values
  - Exact Bluff success-probability curve vs. Technology Level
  - Exact Military success-probability curve vs. Technology Level + Unity
  - Peaceful Contact's base alliance rewards, and its per-tier deepening
    rewards — structurally resolved via **Trade Agreements** (see the
    now-resolved Alien trade economy item above and Settlers &
    Exploration's Escalation Chains); what's left here is purely numeric —
    exact resource pairs/quantities offered per agreement, exact deepening
    tier count/cadence
  - Bluff's on-success payout amount (relative to an undeepened alliance's
    baseline)
  - Military Exploitation's success rewards
  - Overwhelming Force Package's exact recipe (a first-pass placeholder is
    written into Buildings & Economy's Fabrication)
  - Exact legend-value-scaling formula shape (inverse of success
    probability, magnitude TBD)

---

## Animal System (brainstorm 2026-09-08 onward — mostly written in)

A large redesign worked out in discussion. **Written in so far
(2026-09-10/14):** the parasite/disease/countermeasure/recovery mechanics
(Settlers & Exploration's [Infections](05_settlers_and_exploration.md#infections) and [Infected Food](05_settlers_and_exploration.md#infected-food); Buildings & Economy's
Medical Bay's Biological Countermeasures tier, Recovery capacity,
Biological Lab Materials, PPE/Emergency Medical Kit; Kitchen's parasite
cook-out; the quarter-season epidemiology tick and Bio-hazard reframe in
Planets & Scoring's In-Simulation Hazard Events); the free-relocation-on-
upgrade rule; Glass; the Husbandry Experience group / Aptitude bucket
split; **wild animal populations and Fencing in full** (Planets & Scoring's
[Wild Animal Populations](06_planets_and_scoring.md#wild-animal-populations), including the Pollinator kind and its flat
site count; Buildings & Economy's [Fencing](04_buildings_and_economy.md#fencing); the shield Energy model
corrected to match — see below); the tiny/small-animal counters (Traps,
Grazer-immunity Hybridization, Hydroponic Farm); and the Husbandry
production-cycle structure itself — Buildings & Economy's [Animal
Husbandry](04_buildings_and_economy.md#animal-husbandry) (Husbandry Site incl. the two-tile Titan-tier upgrade,
Capture, the `{feed, produce...}` production cycle, Cull/Release/Neglect)
plus the general drone-Aptitude/Experience-equivalence rule in Settlers
& Exploration's [Drones, Experience, and Aptitude](05_settlers_and_exploration.md#drones-experience-and-aptitude). **Still brainstormed but not
yet written:** the Earth-livestock → native-fauna pivot itself (removing
Dairy Pasture/Poultry Coop/Sheep Pasture, rehoming Milk/Eggs/Wool onto
husbandry-animal analogs and Kitchen recipes, the archetype rosters,
below), and the pet/companion path. Supersedes the "Livestock vaccines"
item above.

### The pivot

Earth livestock is **dropped** — an expedition mass-constrained enough to
ration seed stock realistically can't bring herds. Milk/Eggs/Wool go away as
Earth-animal products; nutrition/textiles rehome onto crops, hunted meat
(Trapping already exists), and **native-fauna analogs**. Animal husbandry
becomes discovery-gated and planet-dependent, which is the point — it makes
runs diverge while crops + Trapping + Rations stay a reliable learnable core
on every planet type.

### Two paths

- **Husbandry** — common. Pipeline now fully written — see Buildings &
  Economy's [Animal Husbandry](04_buildings_and_economy.md#animal-husbandry): ambient **Discovery**, a risk-bearing
  **Capture** attempt (per-species difficulty, success ~ Aptitude, injury ~
  inverse Experience), a universal **Husbandry Site** seeded with captured
  specimens, then an automatic `{feed, produce...}` **production cycle**
  (a specialization of the general production-queue mechanic) until
  Cull/Release/or Neglect ends it. A two-tile **Titan-tier** site upgrade is
  required for Titan-sized animals, with `legend_value`, larger output, and
  possibly unique output as its reward.
- **Pet / Companion** — rare. Found via a rare exploration outcome, **bonds
  permanently to the finding settler** (acquisition = luck × that settler's
  Exploration Aptitude). One pet per settler; no run cap, probabilities
  tuned for 0–2 per run. Provides an *effect*, not a good — a mix of
  passive/settlement-wide and bonded-settler-activity-specific; pets follow
  their settler on exploration (a settlement-wide passive effect lapses
  while the pet is away). Bonded settler dies → pet lost (released), and
  befriending adds `legend_value` (Frontier Legends). Pets are immune to
  parasites/diseases and generally act like a buff on their settler. Pets
  can gate **non-systematized content** (e.g. a water-source exploration
  task that only ever appears if a water-diviner pet exists).

### Archetype value rule

Outcome values are **constant across all instances of an archetype** (a
Fiber beast is 1 Wool/cycle, always). Variety = naming + small % differences
on *secondary* attributes (grows 10% slower; lumbering, 20% easier to
capture). Planet-gen picks each type's roster, Seasoning-style.

### Rosters

- **Husbandry**: Grazer/herd (meat + milk-analog + droppings → Fertilizer +
  hide → Leather); Fiber beast (wool-analog → Fabric; insulating fiber →
  Temperature-Resistant Gear); Burrower (suppresses Alien Soil for
  plant-crop buildings while active — an alternative to Fertilizer/
  Hybridization); Pollinator hive (amplifies plant yield settlement-wide;
  honey-analog).
- **Pets**: Water-diviner (unlocks a unique water-source exploration task,
  flags aquifer tiles); Sentinel flyer (telegraphs a scheduled Storm/Temp
  event earlier than weather `Confidence` would); Draft animal (multiplies
  the bonded settler's Effort on hard-labor Outdoor tasks); Chem-scavenger
  (dual-mode: in-settlement, a pure-variance random-loot forage cycle —
  Seasonings, a small catch → 1 Pelt; on exploration, a serendipitous-
  discovery bonus).

### Parasites & diseases (settler + animal)

- **Parasites** populate the **Toxic/Parasitic Organism Threat** sub-factor.
  Infect **settlers** (per-settler, not communicable) or **husbandry animals**
  (settlement-wide per animal type; production debuff regardless of
  visibility; only interloper animals introduce it, or infection-at-capture).
  Do not spread building-to-building.
- **Diseases** populate the **Pathogen Threat** sub-factor. Settler-only
  except via a chosen **disease-carrier interloper** (blocked entirely if
  fencing/deterrence keeps raiders/predators out). **Communicable
  settler-to-settler** at the quarter-season tick if any infected settler is
  in the settlement and no vaccine exists. No food interaction.
- **Countermeasures** — one unified Medical Bay capability (vaccines +
  anti-parasitics). A countermeasure-assigned worker's cycle clears **one
  threat at random** from the list of *encountered/confirmed* threats
  (settler case, expert-witnessed food/animal case, or exploration report —
  never mere planet presence); each completed research permanently removes
  that threat. Vaccine = immunity + guaranteed recovery. Anti-parasitic =
  guaranteed/faster settler recovery (no immunity) + **permanent
  auto-immunity for husbandry animals** (existing infections instantly
  cleared).
- **Recovery** — parasites/diseases behave like a minor injury needing
  Medical Bay recovery. New **Recovery capacity** building property: 1
  (base) / 2 (upgraded Medical Bay, which becomes a **2-slot footprint** —
  the first concrete footprint-expanding upgrade, per `1-B2`). A recovering
  settler (slotted or overflow-queued) **cannot work**, cannot be sent
  exploring; slotted = recovery progresses, queued = it doesn't; **both face
  a death roll at each quarter-season epidemiology tick** (same tick as the
  disease-spread check) unless a countermeasure/vaccine exists. Triage is
  severity-ordered (not surfaced to the player). Any number of concurrent
  parasites + injuries + a disease. Explorers resolve injury/infection only
  at task completion — no mid-task affliction state. A held-but-recovering
  settler's site produces nothing; the Site Panel should say "worker
  recovering".
- **Infected food** — a property of animal-derived food items (`normal` vs
  `parasite-infected(type)`, Meals inherit, **Rations do not** — the Ration
  Press sanitizes; Food Storage is now sanitized-content-only, see the
  committed rework). Visible only via (a) that countermeasure researched, or
  a non-exploring settler with (b) max Kitchen/Medical *Experience* or (c)
  max Kitchen/Medical *Aptitude*. When visible: splits into its own
  inventory entry, auto-excluded from nutrition, manual-assign only. When
  *not* visible and used in the seasonal pool → every non-exploring settler
  infected. Two-tier knowledge: a threat can be *confirmed* (on the research
  list) while its infected items/animals are still *invisible*.
- **Cook-out** — a Kitchen worker who can see the infection auto-produces
  safe output, at a reduced success chance (illustrative 75%, scales with
  Kitchen skill; failure = ingredients destroyed, cycle output lost), shown
  alongside the recipe's production rate; a recipe-selection toggle lets the
  player knowingly cook infected output instead.
- **Cull / release** infected husbandry — a worker-action production task at
  the site (earns Husbandry Experience); low chance of a clean population,
  high chance of just ending domestication (restartable from the same
  infected wild source); odds scale with that worker. Cull yields Pelt/meat
  (infected meat if the herd was); release doesn't. Or: just don't produce
  from the site until a countermeasure exists.
- **Reveal beat** — the moment a countermeasure finishes *or* a settler
  crosses the Experience threshold to identify infection, every infected
  item in inventory splits out at once; both moments come with a
  Transmission that names the information source.
- **Beat-the-odds legend** — a settler who survives a no-countermeasure
  recovery roll gains `legend_value`.

### Medical Bay / materials — committed

Biological Lab Materials (Grain + Glass, made at the Medical Bay,
`TechAchievement` 2) replaces High-Tech Components for the countermeasure
research tier only; PPE (now Fabric + Glass, tier 2) and Emergency Medical
Kit (now low-tier, no HTC, a one-time field cure preventing a would-be
minor injury/infection on any exploration task) keep their own recipes.
Glass — the Stone Processing II output behind all of this — has TBD
**broader uses** left as its own item: more hazard-resistant gear, a
luxury good, Scanner optics. The `06` bio-hazard reframe (no more
"exploration-gated" language; the quarter-season epidemiology tick; the
planet-gen roster) is in; the deeper survey-vs-fixed-schedule reconciliation
(`11-B1`/`11-B2`) is still deferred to the Hazards & Data-Gathering theme.

### Structure-upgrade rule — committed

Every building upgrade includes a **free optional relocation** — the
construction robot rebuilds the (possibly larger) building, on its current
cell(s) or elsewhere, in one action. Upgrade-in-place is just choosing the
current location in the same placement UI. Deposit/feature-gated upgrades
are forced to stay on their deposit. Resolves the two-robot-action trap
in `1-B2`/`1-SF5`.

### Wild Animal Populations & Fencing — committed (2026-09-11)

The full system is written — see Planets & Scoring's
[Wild Animal Populations](06_planets_and_scoring.md#wild-animal-populations) and Buildings & Economy's [Fencing](04_buildings_and_economy.md#fencing) for the
mechanic in full (tracked populations by kind/size/tier/diet-or-prey/
carrier flag; grazer harvest-range reduction; predator site destruction +
settler kills + carrier infection; the predator↔prey growth/suppression
loop with its verified guaranteed-decay property; planet-gen and
season-by-season seeding; per-size reachability and wall destruction,
including the "outermost barrier first, never simultaneous" resolution for
deliberate double fencing; live Energy-shield exclusion from the
reachability graph). Along the way, the **shield Energy model was
corrected**: shields now draw a flat baseline whenever powered — providing
full protection (temperature, storm, and all-size animal blocking)
throughout, not just during an active event — plus an elevated draw while
an event is active (see Buildings & Economy's [Resources](04_buildings_and_economy.md#resources) and Planets & Scoring's
[In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)); `DisruptionFootprint` was extended to cover built and
planned fence tiles (Planets & Scoring's [SEED Factions](06_planets_and_scoring.md#seed-factions)).

**Tiny/small-animal counters — resolved (2026-09-14):** three, together
covering every animal size. **Tiny Trap / Small Trap** (Carpenter's Shop,
Wood + Fabric — see Buildings & Economy's [Fabrication](04_buildings_and_economy.md#fabrication)) are the only thing
that stops tiny/small at all, since no fence tier touches them: one unit
auto-consumed at Planning Lock-in per season a matching population would
otherwise reach a site, surplus banking freely. **Grazer immunity**, a new
planet-independent Hybridization discovery (Buildings & Economy's
[Hybridization](04_buildings_and_economy.md#hybridization)) — additive to, not a replacement for, the existing
planet-signature benefit — permanently removes one crop building type from
every grazer's diet, settlement-wide. The **Hydroponic Farm** (Buildings &
Economy's [Hydroponic Farm](04_buildings_and_economy.md#hydroponic-farm)), a new Indoor Grain/Fiber alternative, sidesteps
wild animals (and Storm/Temperature Extremity, and Alien Soil) entirely, at
the cost of a slower cycle, no Wooden Plow bonus, and being barred to
Farming-Specialized Drones.

**Still open, deliberately deferred:**
- **Guards, traps (the general kind — not the tiny/small-specific Traps
  above), and hunt/remove-population exploration tasks** — real but
  undesigned active counters (mentioned in discussion, never specified).
- **Farm-site archetypes** biasing wild-population generation — its own
  item, not detailed.
- The **shield/hazard-events focused revisit** (unbreakable-shield limits,
  stronger-event power scaling) — see the Post-Sim resolution-order pass
  section below.

---

## Design Audit (2026-09-02)

A per-system design audit of `full_design/` produced 14 reports in
`full_design/audits/` (indexed by `audits/00_system_inventory.md`), against a
9-section template. This section consolidates their **Blockers** and
**Should-fix** findings; full rationale plus each report's Internal-consistency,
Story-consistency, Nice-to-have, and Defer items stay in the individual reports.
Findings are cited as `system-B/SFn` (e.g. `5-B3`, `11-SF14`); `7a`/`7b` and
`10a`/`10b` are the split reports.

### Cross-cutting themes

1. **Season 1 / initial state is undefined and four systems block on it.** The
   run-start flow is unwritten (`12-B1`); nothing specifies the starting loadout
   or how starting buildings land on the grid (`12-B3`) → blocks the grid's
   initial state and `DisruptionFootprint` baseline (`1-B3`), Season 1's
   entry/seeding moment (`2-B1`), and the Energy/Water Season-1 baselines.
2. **Post-Sim resolution order is under-specified where steps depend on each
   other.** No sub-step applies accumulated production to inventory, yet
   nutrition, Trade-Agreement expense, and construction-cost accounting all read
   inventory (`2-B2`); construction completions are declared "arbitrary" order
   but relocate-then-build needs sequencing (`1-SF1` / `2-SF2`); Mid-Sim's
   process list omits the Energy/Water rate machinery and the plant-crop Water
   queue (`2-B3`, `4`); explorer Ration deduction and hazard-death-vs-nutrition
   interaction aren't placed (`10a-SF3`, `8-SF5`).
3. **The rate-scarcity mechanics can compound into no-decision run-enders.**
   Energy's random shedding can zero a Water building → the binary "zero Water →
   all settlers die" check (`5-B3`, `6-B2`), which has no temporal semantics; an
   armed shield may be shed during the event it counters (`5-B4`); random-shed →
   indoor worker exposed → extreme-event death roll (`11-SF7`). In tension with
   "no purely ambient randomness ends a run".
4. **Failure legibility is thin across systems.** No planning-phase Water readout
   (`6-B3`); "blocked in the Water queue" isn't a Site Panel state (`4-SF7`,
   `6-SF6`); bootstrap deadlocks have no in-game signal (`7a-A-P1`, `7b-B-P2`);
   the exploration outcome UI doesn't separate the success roll from the
   independent risk roll (`9-SF7`, `10a-SF1`); the log can't distinguish
   deterministic destruction from an unlucky roll (`2-SF8`, `11-SF12`).
5. **"Colour is never the sole channel" is recorded for no overlay or
   indicator** — grid overlays, log line types, roster idle state, deposit
   tiles, shield/preparedness states (`1-SF4`, `2-SF7`, `3-SF4`, `5-SF6`,
   `7b-B-P1`, `8-SF9`, `11-SF15`). One systemic fix.
6. **Systems don't state what they emit to the SEED scoring formulas, when, or
   normalized how.** `NutritionIncome`/`ResourceIncome` measurement points
   (`4-SF9`, `8-SF7`); `ExtractionRestraint`/`EmissionsRestraint` increments
   (`4-SF9`); luxury goods' "faction value" is unwired to any formula (`7a-A-CS5`);
   sub-factor→axis aggregation for the Safeguard `Score` is missing (`11-B2`);
   `DisruptionFootprint`'s baseline, per-type "changed" definition, and
   invisible-disruption case (`1-B3`, `6-SF7`, `7b-B-CS3`, `11-SF14`).
7. **Phantom scope — referenced as real, never designed.** Combo/multi-purpose
   buildings (`4-B1`); the automatic-alternative-output idea (`4-SF1`);
   effort-stacking toward a per-site cap has no building instance (`3-B1`); the
   meta-progression unlock trigger (`12-B2`); Peaceful Contact's base alliance
   reward has no shape (`10b-B1`); the recurring data-gathering exploration
   tasks that are the sole source for 3 of 5 hazard sub-factors (`11-SF9`).
8. **Turn-one bootstrap can hard-deadlock.** "Self-bootstraps from turn one" is
   asserted but unverified; no guaranteed turn-one Wood, and the Surface-deposit
   guarantee doesn't guarantee Stone (`7a-A-S1/A-S2`, `7b-B-S1`); rare-metal /
   Deep-tier discovery is softly circular through Portable Scanning Equipment
   (`7a-A-CS3`, `7b-B-CS1`).
9. **Injury acquisition is undefined** — no {nothing/SP/permanent/death} weights
   per risk tier, no rule for which permanent type is picked, no concurrent-injury
   stacking (`9-B1/B2`); `05`'s claimed hazard-shared injury taxonomy isn't
   delivered by `06` (`9-SF1`).
10. **Stale references to the deleted mobile design survive in several docs** —
    "assign food planning-action pattern" (`8-SF3`), "settler baseline of 1
    Water/season" (`6-SF2`), "Energy" in Solar Array's cost (`5-SF3`), the cut
    double-tap toggle (`5-SF4`), "four animal-based buildings" when three exist
    (`4-SF5`), `03`'s "(In Progress)" / "What Got Cut" framing (audit `1`
    Nice-to-have).

### Blockers by system

**1 — Grid, Placement & Construction** (`audits/01_grid_placement_and_construction.md`)
- `1-B1` — Whether Protection structures (shields) run through the
  construction-robot economy at all (Small Set of Impactful Actions #3 vs #1);
  determines the action economy and whether the player can react to a per-season
  hazard forecast.
- `1-B2` — No multi-slot footprint *shape* model and no footprint-expansion
  direction rule; even Upgraded Kitchen's 2-slot shape is unspecified.
- `1-B3` — Initial grid state undefined: starting-building positions, who places
  them, whether they are later relocatable, and the `DisruptionFootprint`
  "start of Season 1" baseline.

**2 — Season Structure & Simulation Flow** (`audits/02_season_structure_and_simulation_flow.md`)
- `2-B1` — Season 1's entry state unspecified — no Post-Sim precedes the first
  planning phase; what seeds it (starting grid/inventory, run-start SEED summary
  transmission, whether Season 1 has a normal Planning Lock-in) is unreconciled.
- `2-B2` — No Post-Sim sub-step applies the season's accumulated production to
  inventory, yet nutrition, Trade-Agreement expense, and construction-cost
  accounting all read inventory.
- `2-B3` — Mid-Sim's process list names only continuous production and discrete
  hazard events; it omits Energy/Water live-rate recompute + random shedding and
  the plant-crop Water-draw FIFO queue.

**3 — Worker Assignment, Roster & Site Panel** (`audits/03_worker_assignment_roster_site_panel.md`)
- `3-B1` — Effort-stacking toward a per-site production cap has no concrete
  building instance (Farm/Production is 1-worker-capped; Kitchen's tier is
  parallel stations) — decide whether it has real homes or is cut.
- `3-B2` — Site Panel gives one "Assigned worker slot" but multi-slot buildings
  need several, and worker-to-building vs. worker-to-slot is unspecified.
- `3-B3` — Roster hover-highlight and Mid-Sim per-worker expansion assume
  building targets; representation of Exploration-Task and Standing-Assignment
  workers is undefined.

**4 — Production Model** (`audits/04_production_model.md`)
- `4-B1` — Combo / multi-purpose buildings are referenced as existing but have
  no catalogue entry, no schema, and contradict "one primary input→output
  conversion".
- `4-B2` — Three-phase plant-crop cycle parameterization undefined —
  Planting/Harvesting are Effort-driven, Growing soil-driven, yet each building
  carries one combined `production_time` with no statement of what is authored
  vs. derived or the Effort→duration function.
- `4-B3` — Cross-season handling of an in-progress cycle is undefined for both
  models (partial continuous-rate cycle at Mid-Sim end; plant-crop mid-Growing
  whose held Water reservation cannot span a season boundary).

**5 — Energy** (`audits/05_energy.md`)
- `5-B1` — The temperature/protection/energy coupling is described as intent, not
  built spec, and four non-agreeing accounts exist of which buildings carry it
  and whether it is flat-at-placement or event-driven. Strategy dimension D
  depends on it.
- `5-B2` — The Green/Yellow/Red per-building power prediction requires
  apportioning total Income into a per-building "share", and no apportionment
  rule exists.
- `5-B3` — "Consumer" and "active" are undefined for random shedding, and it is
  unspecified whether staffed Water collection buildings are shed-eligible — if
  they are, an Energy shortfall can zero Water Income and trigger the
  all-settlers-die check.
- `5-B4` — Unresolved whether an armed Weather/Row Shield is shed-eligible during
  the Temperature Extremity event it is meant to counter, and whether its
  elevated cost is added before or after the shedding pass.

**6 — Water** (`audits/06_water.md`)
- `6-B1` — Animal-building Water-draw mechanism is undefined against the
  rate-not-stock model — not just the shortfall case; a "flat per-cycle" amount
  has no defined way to draw from a stockless rate.
- `6-B2` — "Zero Water Income anywhere this season" has no temporal semantics
  (instant vs. ever-nonzero vs. integrated); under the strict reading, Energy's
  random shedding can cause total colony loss with no decision behind it.
- `6-B3` — No planning-phase Water readout is specified — the player cannot see
  before committing whether the survival check passes or the Growing queue will
  stall.

**7a — Economy & Fabrication** (`audits/07a_economy_and_fabrication.md`)
- `7a-A-S1` — "Self-bootstraps from turn one" is unverified; the bootstrap-path
  Lumber:Concrete ratios are a structural precondition mislabelled as a
  balancing TBD.
- `7a-A-S2` — No guaranteed turn-one Wood source — a site with zero Forest tiles
  has no Lumber and cannot build anything.
- `7a-A-S3` — Fertilizer per-season consumption quantity undefined
  (settlement-wide unit vs. per-plant-crop-building) — sets whether Fertilizer
  is a real cost or a trivial side-effect.

**7b — Deposits & Surveys** (`audits/07b_deposits_and_surveys.md`)
- `7b-B-S1` — The Surface-deposit guarantee ("Stone OR Iron OR Copper") doesn't
  guarantee first Stone, and Stone is required to build a Quarry or a Mine — a
  site whose one Surface deposit is Ore can deadlock.
- `7b-B-S4/IC1` — Iron Ore vs. Copper Ore are described both as "distinct
  deposits" and as one site with a "70/30 mixed" split; the model needs one
  consistent representation.

**8 — Food & Nutrition** (`audits/08_food_and_nutrition.md`)
- `8-B1` — Tier-1 bulk-shortfall test undefined in units — "can't cover the
  settler headcount at all" vs. the summed worked example (3/3/5/5 vs. 4/4/4/4)
  admit different death outcomes.
- `8-B2` — How many settlers die on a Tier-1 shortfall is unspecified
  (proportional to the gap? feed-as-many-as-possible?).
- `8-B3` — Gourmet dishes and Local Delicacy have no defined ingredient list,
  nutrient profile, or `production_time`, and whether a Seasoning is consumed by
  the roll, by cooking, or neither is unstated.

**9 — Settlers** (`audits/09_settlers.md`)
- `9-B1` — Injury-acquisition distribution undefined — no {nothing/SP/permanent/
  death} weights per risk tier, no rule for which of the 4 permanent types is
  picked, no one-failure-multiple-injuries rule.
- `9-B2` — Multiple concurrent permanent injuries have no stacking rule — do
  speed cuts compound, do eligibility bars intersect to a possible "no eligible
  assignment" state.

**10a — Exploration Tasks & Standing Assignments** (`audits/10a_exploration_tasks_and_standing_assignments.md`)
- `10a-B1` — No pool-population/draw algorithm — filling the 3 (max 5) slots
  from the per-planet eligible set given Rarity, Season gate, and
  meta-progression unlocks is unspecified.
- `10a-B2` — Multi-season / multi-Ration payment timing undefined — 2 Rations
  upfront at sim-start vs. 1/season across the duration; "consumed at
  season-simulation-start" contradicts "seasons to complete = Ration cost".
- `10a-B3` — Reroll's interaction with partially-locked / in-progress pools
  undefined — which slots refresh, whether the flat cost scales, whether locks
  can starve the pool of refreshes (no lock cap).

**10b — Escalation Chains, Alien Contact & Trade** (`audits/10b_escalation_chains_alien_contact_trade.md`)
- `10b-B1` — Peaceful Contact base alliance reward has no defined *shape*, only
  "TBD" — deepening rewards, Trade Agreement availability, Local Delicacy
  sourcing, and the zero-staffing passive-food reward tier all depend on it.
  Structural, not numeric.
- `10b-B2` — Deepening-alliance tier *count* and cadence undefined — sets arc
  length and the number of guaranteed-escalation pool slots generated;
  mis-tagged "purely numeric" in this file's alien-classes item.
- `10b-B3` — No rule enforcing "at most one alien civilization per run" despite
  `ContactRestraint` assuming it — five triggers + Universal Ubiquity + the
  Unknown Radio Signal path can each reach Sentience Detection.
- `10b-B4` — Trade Agreement candidate generation unspecified — how the 3 fixed
  expense/income pairings are drawn has no algorithm.

**11 — Hazards, Protection & Data-Gathering** (`audits/11_hazards_protection_data_gathering.md`)
- `11-B1` — The per-season hazard draw's dependence on a data source is
  contradictory ("the report and the event are the same draw" vs. events firing
  at near-zero confidence before any surveying); must state the draw fires
  unconditionally at `P = TrueRisk` and a data source only converts it to a
  visible/counted report.
- `11-B2` — Sub-factor → hazard-axis aggregation for `Data` and `MatchedRisk` is
  undefined — `Score(Weather)` / `Score(Bio-hazard)` need axis-level values but
  the mechanism is entirely per-sub-factor and only `TrueRisk` has a stated
  aggregation.
- `11-B3` — The `adequately covered` vs. `under-covered` Storm boundary is
  undefined — only `severely under-covered → destroyed` is pinned.
- `11-B4` — Vaccine-Production gate granularity is ambiguous — axis-level
  `Confidence(Bio-hazard)` vs. per-discovered-pathogen; number of distinct
  pathogens per run undefined. **Resolved (2026-09-10, parasite/disease
  write pass):** the *tier* (renamed Biological Countermeasures) is
  axis-gated by `Confidence(Bio-hazard)`; individual vaccines/anti-parasitics
  are researched one confirmed threat at a time thereafter. Roster count is
  set by planet-gen (Animal System item above).
- `11-B5` — Atmospheric Hazard's exposure trigger is undefined — called a
  "continuous check with no event" yet the status effect "triggers on
  exposure"; no cause, frequency, or weighting given.
- `11-B6` — Event timing and duration within the 30s Mid-Sim window is
  unmodelled — consequences are scoped "for the event's duration" with no rule
  for start time or length.

**12 — Meta-Progression, Earth Hub & Run-Start Flow** (`audits/12_meta_progression_hub_run_start.md`)
- `12-B1` — The run-start flow (hub landing → Crew Selection → planet commitment
  → Farm Site Selection → starting loadout → SEED summary transmission → Season 1
  planning) is undesigned — sequence, transitions, and where each already-designed
  step sits.
- `12-B2` — Meta-progression unlock trigger undefined — the "enough of a
  previously-unseen resource type" threshold, the cross-run ledger it implies,
  the authored material→design mapping, and whether the unlock is surfaced to
  the player.
- `12-B3` — Starting-loadout ownership seam — this system produces the starting
  settlers/buildings/Rations/Solar Arrays but no doc defines the loadout or how
  starting buildings land on the grid; blocks Systems 1/5/6 baselines and the
  `DisruptionFootprint` Season-1 snapshot.

### Should-fix by system

Compressed to `id — label`; full rationale and doc citations are in each report's
§9.

**1 — Grid** — `SF1` intra-Post-Sim ordering of construction completions
(relocations before dependent builds); `SF2` rules for building on an
undiscovered deposit tile + its silent `DisruptionFootprint`; `SF3` add "except
via exploration Site Reveal" carve-out to "cannot be moved or removed"; `SF4`
non-colour channel for every grid overlay; `SF5` explicit cause messaging for
blocked/greyed grid actions; `SF6` construction-cost timing — leave inventory at
Planning Lock-in, restored on cancel; `SF7` transition-season behaviour of an
upgrading/relocating building + worker retention; `SF8` confirm relocate counts
against the N-actions cap.

**2 — Season Structure** — `SF1` reword Post-Sim "instantaneous" → "no
simulation clock runs"; `SF2` intra-step-(4) construction ordering (owned here);
`SF3` split Post-Sim into immediate (1–4) vs. next-planning-phase preamble
(5–6); `SF4` reconcile hazard-warning lead time with when the triggering draw is
rolled (no look-ahead mechanism exists); `SF5` fix the Mid-Sim log-line list —
vaccine/deposit/escalation resolve at Post-Sim; `SF6` state prior Post-Sim
outcomes are final, not reversible next phase; `SF7` non-colour cue for log line
types; `SF8` event log lines must carry luck-vs-certainty detail for
retrospective legibility.

**3 — Worker Assignment** — `SF1` modifier-combination rule for the Site Panel's
"one combined number" + what a 3-phase building shows; `SF2` per-building
worker-eligibility enforcement + "why rejected" messaging; `SF3` pre-assign to a
queued not-yet-built building? first-season-idle rule; `SF4` static cue for the
Mid-Sim roster "idle" state; `SF5` planning-phase signal that a drone recharge
may stall output; `SF6` which concrete worker a type-row drag assigns when
A > 1; `SF7` construction robots — roster row or separate budget indicator;
`SF8` if effort-stacking survives, Site Panel shows cap + headroom; `SF9` define
the unassign / send-to-idle gesture.

**4 — Production Model** — `SF1` resolve the automatic-alternative-output idea
(cut or scope; remove the paragraph if cut); `SF2` Fertilizer → Alien Soil
removal: settlement-wide boolean vs. rationed + amount consumed; `SF3` hazard
slowed/stopped behaviour for a plant-crop mid-Planting/mid-Growing + whether a
stopped Growing phase holds or releases its Water reservation; `SF4` quantify
"slowed" as a rate multiplier shared by both hazard types; `SF5` fix "the four
animal-based buildings" (three exist); `SF6` resolve the farm upgrade-rule
contradiction (cap raise allowed vs. forbidden); `SF7` per-building "waiting for
Water" indicator + surface queue order; `SF8` reconcile whether a 2nd worker
shortens a cycle or raises per-cycle output; `SF9` name the Production Model
scoring emission points; `SF10` what the Site Panel combined rate means for a
3-phase cycle + expected-yield legibility risk.

**5 — Energy** — `SF1` recompute-trigger list omits drone-recharge start/stop
and a shed building's own consumption drop; define the shedding pass's
termination; `SF2` shed staffed building — release worker or hold idle; `SF3`
remove "Energy" from Solar Array's construction cost; `SF4` define the
per-building active/inactive toggle interaction (the double-tap gesture was
cut); `SF5` surface random-shedding events in the log with cause; `SF6`
non-colour distinction for the Income bar's two indicator lines; `SF7` where the
temperature-coupling upkeep is surfaced to the player; `SF8` Fuel-based
Generator fuel-limit sticky/reversible + post-season "burned X of Y" readout.

**6 — Water** — `SF1` warning/confirmation gate for a season that will trigger
the zero-Water wipe; `SF2` stale anchor — "settler baseline of 1 Water/season"
no longer exists; ~~`SF3` canonical queue tiebreak~~ / ~~`SF4` queue advances
per sim-time, not wall-clock~~ **obsolete** — the Growing-phase Water-draw
FIFO queue was replaced by a random-shortfall pool (see the Post-Sim
resolution-order pass below), so there is no queue order left to tiebreak or
pace; `SF5` can a collection building's toggle turn off the only Water source,
and is that gated; `SF6` make a Water denial a named Site Panel status state
(reworded from "blocked in the Water queue" — no queue anymore, see below);
`SF7` does tapping an aquifer incur `DisruptionFootprint` (ExtractionRestraint
excludes water but the slot-state-changed rule does not); `SF8` confirm Deep
Well auto-upgrade and a Water-denied Growing phase emit log/Transmission
lines.

**7a — Economy & Fabrication** — `A-S4` Seasoning drop cadence for continuous
sources (per cycle vs. per season); `A-S5` drone upgrade-in-place has no
duration / resolution moment / Robotics Assembly slot cost; `A-IC1` multi-recipe
items get one `TechAchievement` tier that can exceed their cheapest recipe's
cost; `A-IC4/CS1/CS2` Sawmill/Smelter/Textile Workshop unplaced in the
Experience-group, Aptitude-bucket, and Manual-Labor taxonomies (Sawmill is a
*starting* staffed building); `A-CS3` rare-metal acquisition softly circular
(Portable Scanning Equipment needs a rare metal; systematic rare-metal discovery
needs the equipment); `A-CS4` the entire advanced catalog is single-threaded
through Silicon → the Stone Processing II upgrade, unacknowledged; `A-CS5`
luxury goods' "faction-reward value" is unwired — no SEED formula has a luxury
term; `A-P1` the bootstrap deadlock and the Silicon chokepoint have no in-game
legibility signal.

**7b — Deposits & Surveys** — `B-S2` "on success" for a Survey is undefined — a
success/failure roll or just "on completion"? conflicts with "safe, no risk";
`B-S3` Basic Deposit Survey's required "basic tools" unspecified (a fabricated
prereq would break its Season-1 availability); `B-IC3` Deep Survey can be
fabricated-for and assigned with zero effect when no tile is flagged — needs a
UI guard; `B-CS1` Deep-tier discovery softly circular through Portable
High-Powered Scanning Equipment; `B-CS3` the Stewardship `DisruptionFootprint`
penalty for discovering + mining a discovery-gated (esp. Deep) deposit is
invisible when the player commits; `B-CS5` `B-S1`'s deadlock degrades, for
informed players, into a Ration-spending site-reroll tax; `B-P1` no non-colour
marker for discovered deposits, flagged deep-eligible tiles, or per-depth reveal
state; `B-P2` the bootstrap-Stone deadlock has no in-game legibility signal.

**8 — Food & Nutrition** — `SF1` specify the food-for-consumption default UI
surface (the auto-queued-defaults transparency bar, shown at the very start of
planning); `SF2` reconcile Tier-1 "Rations plus any meals" with raw
crops/animal products also feeding settlers; `SF3` replace the superseded
"assign food planning-action pattern" reference with a defined interaction;
`SF4` Ration Press consumes only food present at the start of the planning
phase; `SF5` define the Post-Sim interaction between hazard/injury deaths and
the nutrition headcount + Lock-in-fixed food plan (is earmarked food refunded);
`SF6` define "food type" for the sticky-diet default (item id vs. category;
flavor-name variants); `SF7` define the per-season production measurement
feeding `NutritionIncome`, shared with `ResourceIncome`; `SF8` visible Rations
count + runway, and an unmistakable non-standard confirm for the rest-of-run
Food Storage commitment; `SF9` non-colour cue for the food-for-consumption /
axis-short indicators; `SF10` surface a signal that a settler is
Gourmet-*eligible*.

**9 — Settlers** — `SF1` resolve whether Atmospheric/Temperature hazards can
inflict SP or permanent injuries or only status effects + death (`05` claims a
shared taxonomy `06` doesn't deliver); `SF2` specify SP on-site recovery as a
variable-Effort model so it composes with the continuous-rate model; `SF3`
define the "idle" `current_assignment` state; `SF4` state whether a dead
settler's `legend_value` persists into the Frontier Legends totals; `SF5` which
`status_effect` the roster's single "hazard-affected" icon shows when a settler
carries more than one; `SF6` permanent-injury effects surfaced on the settler,
not inferred from failed attempts; `SF7` exploration outcome UI reports the
success roll and the independent risk roll separately; `SF8` explicit "X is now
Storied" surface at threshold crossing; `SF9` fix the plain-language tooltip
understatement when Storied's +1 and Exploration Aptitude's +1 stack to +2;
`SF10` mark Storied and permanent injuries as non-expiring `status_effect`
entries; `SF11` add the injury-acquisition gaps to this file's Settler/Injuries
TBD list.

**10a — Exploration loop** — `SF1` guaranteed-success-vs-independent-risk result
messaging (tell the player separately whether the discovery succeeded and
whether the environment harmed the settler); `SF2` where an accepted/in-progress
task lives relative to the 3 pool slots + full-pool escalation placement; `SF3`
add the explorer Ration deduction (sim-start) to the Season Structure
resolution-moment list; `SF4` name where Clear-Cutting/Trapping output lands
(Mid-Sim accumulation) vs. Survey's Post-Sim one-shot; `SF5` add the
injury/death-on-guaranteed-risk Frontier Legends bonus to `06`; `SF6` define the
"one-time `Confidence(Weather)` burst" in evidence-count terms; `SF7` reconcile
the two descriptions of how negative Exploration Aptitude reduces a "guaranteed"
Site Reveal; `SF8` tighten "Site Reveals get no optional item" (the exclusives
table lists mandatory items); `SF9` can an injury roll on a multi-season
High-risk task occur mid-task or only at resolution; `SF10` Mid-Sim progress
indication for Clear-Cutting / Trapping.

**10b — Escalation chains** — `SF1` define what a *base* alliance grants before
any deepening; `SF2` First Contact approach-selection reversibility (reserved
Rations/items released on switch/cancel); `SF3` how an unresolved sentience
chain is handled at run end + which `ContactRestraint` tier applies mid-arc;
`SF4` quantify the chain's "significantly elevated `EcologicalData` weight" in
evidence-count terms; `SF5` First Contact approach UI info content (cost, risk
tier, directional odds, `ContactRestraint` consequence) before commit; `SF6`
edge case: per-season expense is Rations and Post-Sim nutrition just consumed
the last — silently, permanently ends the agreement; `SF7` author the
vaccine-unlock region-reveal escalation as a real catalog entry; `SF8` "Observe
from a distance" keeps a flat elevated legend value; `SF9` guaranteed-escalation-
slot vs. pool-size-3 pressure — an alliance arc can dominate the pool; `SF10`
re-tag base-alliance-reward shape + deepening-tier-count as structural, not
"purely numeric".

**11 — Hazards, Protection & Data-Gathering** — `SF1` Storm's targeted-site
consequence ignores the severity band — gate "destroyed" on extreme severity;
`SF2` "Medical/Research facility" passive Pathogen data source is listed but
unspecified in `04`; `SF3` reconcile the two `MatchedRisk` descriptions (the
Bayes-theorem phrasing reads as superseded by the Beta-counter model); `SF4`
shield Energy behaviour during a Storm (event-driven upkeep is defined only vs.
Temperature Extremity); `SF5` which channel hazard reports use — Transmissions
vs. the simulation log; `SF6` telegraph lead time ≥ construction lead time, or
shields exempt from the next-season delay, or state prophylactic pre-building is
the intended response; `SF7` address the random-shed → indoor-worker-exposure →
extreme-event death-roll chain; `SF8` Atmospheric Hazard preparedness has no
scoring representation; `SF9` author the recurring data-gathering exploration
tasks (bio-survey, atmospheric sampling, weather balloon, probe); `SF10` present
shield-coverage UI as a prediction-with-confidence, mirroring the Site Panel
power indicator; `SF11` make the run-start SEED summary the explicit sole
failure-legibility instrument pre-`Confidence` + decide a `Confidence` floor /
early-season grace for the destructive/lethal tiers; `SF12` post-event log
distinguishes deterministic destruction from an unlucky roll + surfaces the
coverage state; `SF13` decide term weighting in `Score = Data + MatchedRisk ×
MatchedPreparedness` (Data saturates, the product term is biased small); `SF14`
reconcile mid-Mid-Sim building destruction into one ordered sequence
(slot-state/`DisruptionFootprint`, worker return, exposure); `SF15` distinct UI
language for "protected"'s three shield meanings; `SF16` confirm hazard-caused
death routes through the death-acknowledgment line.

**12 — Meta-Progression, Hub & Run-Start** — `SF1` decide Crew Selection ↔
filament-scan ordering (blind vs. planet-informed crew pick); `SF2` define the
run-start reversibility/commitment boundary; `SF3` decide whether the
"stabilization tech" meta-axis is real (design it) or cut it and fix the
starting loadout as a flat number; `SF4` specify pre-Phase-5 exoplanet selection
(candidate count, generation, whether shelf-life/reroll-limit is active,
random-vs-choose); `SF5` consolidate a Settings screen spec (°F/°C, global
dexterity/gesture-timing scale, volume, optional larger-font tier, drag-offset;
in-run vs. hub access); `SF6` resolve the interruptibility open principle here +
re-base `07`'s persistence section off its Android-lifecycle assumptions; `SF7`
define Run History's role and presentation (record vs. seeds next run; cross-run
score; no implied timeline); `SF8` add SEED Bulletin to the "Earth Hub Contents"
enumeration in `02`; `SF9` decide where the one-time Herald-naming step lives
(presumes an undesigned first-run intro/tutorial).

### Housekeeping the audits surfaced

- **Add a "deposit overlap audit" item.** `03` "Construction" and `04` "Deposit
  Discovery" both cite a deposit-overlap audit that was never written into this
  file. (audit `7b`)
- **Extend the Settler/Injuries TBD list** (under "Remaining numeric TBDs from
  the Settler State / Injuries / Storied design pass" above) with the
  now-known *structural* gaps: injury-acquisition distribution, concurrent-
  permanent-injury stacking, and whether Atmospheric/Temperature hazards share
  the SP/permanent injury taxonomy. (audit `9`)
- **Re-tag two "Alien civilization classes" sub-items** from "deferred to
  balancing" to structural: Peaceful Contact's base-alliance-reward *shape*, and
  the deepening-alliance tier *count*/cadence — these gate whether the arc is
  buildable, not just tunable. (audit `10b`)

### Addressed by the run-start / initial-state pass (2026-09-03)

Theme 1 work — written into Core Loop & Grid (Run-Start Flow, Starting
Settlement Placement), Buildings & Economy (Settlement Base, Habitation),
Settlers & Exploration (`status_effect` list), and Planets & Scoring
(`DisruptionFootprint` baseline).

- `2-B1` — **resolved.** Season 1 is an ordinary season: normal Planning
  Phase first, no preceding Post-Sim, no special seeding, same
  Lock-in/Mid-Sim/Post-Sim structure; the SEED summary transmission lands
  at the top of Season 1 planning.
- `1-B3` — **resolved.** Initial grid state = Starting Settlement Placement
  (a rotatable T-tetromino: Settlement Base centre, the three other
  starting buildings on the arms); all four become independent
  robot-relocatable buildings once the run starts; the `DisruptionFootprint`
  baseline is the site's pristine state captured at Farm Site Selection,
  before placement, and the placement is its first accrual (plus a small
  flat founding amount).
- `12-B1` — **resolved.** Full ordered run-start sequence with two commit
  points (wormhole confirmation; land-at-site confirmation) and the
  reversibility rules between them.
- `12-B3` — **resolved.** Starting loadout defined: 5 crew, Specialization
  additions, a starting Rations stock (amount TBD), one Settlement Base +
  Water Processing Plant + Sawmill + Stone Processing, one construction
  robot.
- `12-SF1` — **resolved.** Crew Selection is first, before any planet
  detail is shown (blind pick).
- `12-SF2` — **resolved.** Reversibility/commitment boundary defined (the
  two confirmations above).
- `12-SF3` — **resolved (direction).** No standalone "stabilization tech"
  axis; base loadout is a flat number, and cross-run variation on it is
  folded into the Meta-progression redesign item.
- `6-SF7` / `11-SF14` / `7b-B-CS3` — **partially addressed.** The
  `DisruptionFootprint` baseline and its "changed from baseline" definition
  are now pinned; the per-type weighting, the discovery-gated extra weight
  for aquifers, and the mid-Mid-Sim destruction ordering remain open.
- Energy/Water Season-1 baselines (theme 1) — **still blocked, deferred.**
  The starting buildings and their placement now exist, but the Season-1
  starting rates can't be set until the Energy/Water **consumption** rates
  of production buildings, other buildings, and drone recharge are
  designed. Sequenced after that Systems 5/6 consumption-rate pass, not
  part of the run-start work.

### Addressed by the rate-scarcity / run-ender pass (2026-09-03)

Theme 3 (rate-scarcity mechanics compounding into no-decision run-enders) —
written into Buildings & Economy (Resources' Energy un-powering rule,
Baseline Energy upkeep, Building Schema Indoor/Outdoor, Water, Habitation)
and Planets & Scoring (In-Simulation Hazard Events, Critical Failure).

- **Framing.** An Energy shortfall is now **throughput-only** — it can slow
  or pause production and nothing more; it can never kill a settler or end a
  run. Survival-critical buildings degrade instead of failing when
  un-powered.
- `5-B3` — **resolved.** "Consumer/active" defined: every Energy *draw* is
  eligible for un-powering, Energy *producers* draw nothing and are never
  picked; an un-powered building draws zero, pauses (progress held, not
  lost), and holds its worker idle; the pass iterates to a fixed point.
  Water collection buildings are eligible but degrade to a fail-safe trickle
  rather than zero, so un-powering one can't trigger the Water death check.
- `5-B4` — **resolved.** Shields draw Energy only while **active** (a Storm
  or Temperature Extremity event in their area, or an ambient temperature
  outside the 72°F band needing mitigation) — automatic, not
  player-managed — and draw nothing when inactive. The old "idle-armed
  baseline rate" is cut. A shield that can't be powered simply goes
  inactive (no protection) for that interval; there is no separate
  shed-ordering question because there is no idle cost to shed.
- `6-B2` — **resolved.** The zero-Water settler-death check is a check on
  **infrastructure existence**, not rate or power: it fires only if the
  settlement had no functioning (built + Water Processing Plant + staffed)
  collection building at any point in the season. An un-powered collection
  building still trickles enough for settler survival, so an Energy shortfall
  can never reach this.
- `11-SF7` — **resolved.** An un-powered Indoor building still shelters its
  worker from Atmospheric Hazard, but not from temperature (treated as
  Outdoor for Temperature Extremity, extreme-event death roll included).
  Principle-compliance rides on Temperature Extremity seasons being
  pre-scheduled and telegraphed (below), so any such death traces to a
  known-inbound event and an Energy-budget decision, not an ambush.
- `5-SF2` / `5-SF5` — **addressed.** Shed staffed building holds its worker
  idle (not returned to roster); every un-powering surfaces in the sim log
  with cause and counts as a noteworthy event.
- **Non-reactive hazard occurrence is now a fixed per-run schedule.** At run
  generation the game rolls which seasons carry a Storm and/or Temperature
  Extremity event and each event's severity band; deterministic once rolled;
  only the intra-season timing is rolled at sim time. Telegraphed at the top
  of each planning phase via Transmissions, with a lead-time window (and
  severity readout) that narrows as weather-data `Confidence` rises; the
  orbital probe shifts it one tier better. Storm can kill unprotected
  outdoor settlers / destroy outdoor drones, but **no hazard event is a
  direct run-ender** — the sole critical-failure trigger is all-settlers-dead
  (`06` Critical Failure rewritten; stale CLAUDE.md reference removed).
- `2-SF4` — **partly addressed.** Hazard-warning lead time now reconciles
  with a run-generation schedule the telegraph looks ahead at; the
  look-ahead mechanism exists.
- **Deferred to the Hazards & Data-Gathering theme:** how a survey accrues
  `Confidence` against a fixed schedule rather than a per-season Bernoulli
  draw, and how that feeds the Safeguard `Score` (`11-B1`, `11-B2`); whether
  Atmospheric Hazard also becomes a scheduled event or stays continuous
  (`11-B5`); the non-shield Indoor temperature/energy coupling and the
  `06` "scales with how extreme" reconciliation (`5-B1`).
- **Shields + active hazard events — focused revisit wanted** (surfaced
  2026-09-10 during the wild-animal design). The shield Energy model was
  updated again: shields draw a **flat baseline whenever powered** (like any
  building) — powered = protecting against temperature, storms, *and*
  animals of all sizes — **plus an elevated draw during an active hazard
  event**. Still to design: a strong-enough weather event should be able to
  **break a shield regardless of how much power is supplied**; stronger
  events should demand **more power** to shield against; and it may be
  cleanest if **only stronger events** incur any elevated shield cost at
  all (mild events shielded on the flat baseline). This subsumes the
  `5-B1` strategy-dimension-D coupling question.

### Addressed by the Post-Sim resolution-order pass (2026-09-04) — in progress

Theme 2 (Post-Sim resolution order under-specified). Being worked through
one issue at a time; this subsection is extended as each is resolved.

- `2-B2` — **resolved.** Production was never meant to batch at Post-Sim:
  every production cycle (continuous-rate or plant-crop three-phase) writes
  its output to inventory **the instant that cycle completes**, live during
  Mid-Sim — including a Fuel-based Generator's Fuel draw, deliberately, so
  Fuel gathered mid-season can be burned just-in-time (see Core Loop &
  Grid's Season Structure Mid-Sim bullet; Buildings & Economy's Fuel).
  Nutrition stays the one exception: it's deliberately **not** drawn down
  live — it resolves as a single lump at Post-Sim, same as before — but the
  player now gets a **planning-phase prediction readout** (mirroring the
  Energy bar's "optimistic estimate, not a guarantee") so a dire shortfall
  is visible and actionable during planning without adding per-tick
  consumption (see Settlers & Exploration's Food & Nutrition, Consumption —
  Pooled).
- **Water's Growing-phase reservation model unified with Energy's.** The
  strict-FIFO water-draw queue (front-only service, no skip-ahead, ties by
  build order) is replaced by the same random-shortfall mechanism Energy's
  Resources section already uses: reservations exceeding available Water
  Income are resolved by randomly denying enough to fit, recomputed to a
  fixed point; a denied Growing phase pauses (no progress lost) and
  re-enters the pool; a manual "turn Water off at this site" toggle exists
  on the same not-leaned-on footing as Energy's. This addresses the Energy
  audit's `E-CS5`/`NTH3` finding (Water and Energy claimed "the same shape"
  but resolved contention by opposite mechanisms) and obsoletes `6-SF3`/
  `6-SF4` (see Should-fix by system, above). The four animal-based
  buildings' Water draw is still undefined and is queued as part of the
  upcoming plant-/animal-based production design pass.
- `1-SF1`/`2-SF2` — **resolved (2026-09-15).** Post-Sim step (4)'s multiple
  construction/upgrade/relocate/fence-tile completions resolve in the same
  order the player originally queued the underlying actions during
  planning, not by a category-based rule — this falls out for free from
  the undo-history ordering planning already needs to record, and
  correctly sequences the two-robot "relocate a blocker, then
  build/upgrade into the freed space" case without a special-cased
  ordering rule. Decided alongside the "Construction as a Mid-Sim
  progressive activity" item, above, which folded Fencing's completion
  into this same step. See Core Loop & Grid's Season Structure.
- **Still open (this theme):** `4-B3` cross-season in-progress-cycle
  carryover; `2-SF1`/`2-SF3` Post-Sim's two-part structure; `2-SF5`
  log-line timing accuracy; `2-SF6` previous-season-outcomes-are-final;
  `10a-SF3`/`10a-B2` explorer Ration deduction placement + multi-season
  payment model; `10a-SF4` Standing Assignment output timing; `8-SF5`
  hazard/injury death vs. nutrition headcount.
