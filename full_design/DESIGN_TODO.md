# Design To-Do — Faction-Driven System Gaps

Tracks remaining content/system design work in `full_design/`, organized around
what each SEED Faction's scoring formula still needs to become concrete and
buildable. All five faction formulas are done (see Win/Lose Conditions); this
tracks what's needed *underneath* them.

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
- [x] **Farm production cycle (plant-crop buildings)** — resolved: the four
  plant-crop buildings (Grain Field, Fruit Orchard, Fiber Field, Timber
  Grove) now run a three-phase **Planting → Growing → Harvesting** cycle
  instead of the single continuous-rate model every other production site
  uses (see Core Loop & Grid's Production Model exception note and
  Buildings & Economy's Farm/Production's Production Cycle). Planting and
  Harvesting are Effort-driven (Planting additionally sped by Wooden Plow);
  Growing needs no worker present (still sticky-assigned, just idle),
  is governed by Alien Soil/Hybridization not Effort, and gates on a
  **water-draw queue** — a single settlement-wide FIFO queue requesting
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
  open**: exact per-phase duration split for each building (currently one
  combined `production_time` number per building, TBD how it divides
  across the three phases); the four animal-based buildings' still-undefined
  insufficient-Water behavior (see Water resource open threads below).
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
  inputs — Food Storage deposits, food-for-consumption selection,
  construction/upgrade/relocate queuing — no consequence computed, nothing
  revealed), **Mid-Sim** (the only place real time passes — continuous
  production plus any discrete event with a genuine reason to occupy a
  specific interval, e.g. hazard events), and **Post-Sim** (instantaneous,
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

## Newly Surfaced Ideas (recorded, not yet designed in detail)

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

- [ ] **Livestock vaccines** — back-burner idea, recorded not designed:
  protecting animal-production buildings (Dairy Pasture, Poultry Coop, Sheep
  Pasture) from Bio-hazard (and maybe Weather) via a produced vaccine *item*
  distinct from the human Vaccine Production unlock — would imply an actual
  recurring manufactured good rather than a one-time settlement-wide fact.
  Low-overhead, flavorful, not urgent.
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
