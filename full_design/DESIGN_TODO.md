# Design To-Do — Faction-Driven System Gaps

Tracks remaining content/system design work in `full_design/`, organized around
what each SEED Faction's scoring formula still needs to become concrete and
buildable. All five faction formulas are done (see Win/Lose Conditions); this
tracks what's needed *underneath* them.

## Per-Faction Status

- [x] **Sustenance Bloc** — formula done
  - [x] Meal production buildings/recipes — Kitchen designed (see
    Food/Meal Conversion)
  - [x] Food Storage building designed (see Storage) — resolves
    `NutritionStockpile` requiring real, felt commitment rather than passive
    surplus
- [x] **Safeguard Coalition** — formula + data-gathering mechanism done
  - [x] `Preparedness` buildings — Weather Shield and Medical Bay designed
    (see Protection)
- [x] **Stewardship Caucus** — formula done
  - [x] Mining buildings list — Mine, Quarry, Rare Metal Extractor designed
    (see Farm/Production); `DisruptionFootprint`/`ExtractionRestraint` still
    derive automatically from grid/mining state, no new scoring mechanism
    needed
- [x] **Development Bloc** — formula done
  - [ ] Rarity weights per resource (not yet assigned)
  - [ ] Real buildings/items catalog carrying `TechAchievement` values
- [x] **Frontier Legends** — formula done
  - [x] Individual-settler tracking system — resolved (see Settlers &
    Exploration's Settler State, Injuries, and Storied subsections):
    `current_assignment` (with sticky/locked default-population living on
    the assignment target, not the settler), a `status_effect` list
    (Injury, Atmospheric Hazard, Temperature Extremity, Storied), and a
    `legend_value` list. Also resolves the Atmospheric Hazard status-effect
    debuff's dependency, as flagged. A full injury taxonomy (semi-permanent
    vs. four permanent types, each with its own eligibility/speed rules)
    and the Storied positive status_effect were designed alongside it.
    Along the way, a settler relationship/pregnancy/child system was
    designed in detail, then explicitly cut as too complex and too far
    from the game's intended tone — relationships alone survive, as pure
    narrative flavor (see Story & World's Narrative-Only Flavor).
  - [x] Settler differentiation (Experience & Aptitude) — resolved (see
    Settlers & Exploration's Experience and Aptitude subsections):
    Experience is a per-task-group stack (0–3, +15% speed each) earned
    through play, permanent, no decay; Aptitude is an innate, per-bucket
    level (−3 to +3) fixed at Crew Selection, using coarser groupings that
    never cross an Experience group's boundary. A new **Smelter** building
    (Ore → Iron/Copper, see Buildings & Economy's Fabrication) surfaced
    while defining Aptitude's Mining-adjacent bucket. Exploration Aptitude
    has its own tiered, cumulative effect shape distinct from the other
    five buckets, stacking additively (not sequentially) with Storied.
  - [x] **Crew Selection phase and its balancing system** — resolved (see
    Core Loop & Grid's new Crew Selection section): a one-time pre-run
    screen before Farm Site Selection, free/uncapped whole-crew reroll.
    Balancing happens **per-settler**, not per-crew, via three weighted
    archetypes (Average 70% / Jack-of-several-trades 20% / Savant 10%),
    each constraining a settler's six Aptitude-bucket levels to a
    comparable total-value band — this specifically closes the exploit
    where a crew-level-only balance could let a player concentrate every
    negative where it's easiest to ignore while keeping every positive.
    Exact ordering relative to the expedition-commitment/filament-scan
    step is still unspecified, flagged in place rather than here.
  - [ ] Catalog of named "hard sites" with legend-values

## Proposed Approach

A buildings catalog unblocks the most at once (Safeguard's Preparedness
buildings, Sustenance's meal conversion, Stewardship's mining list, and
Development's `TechAchievement` carrier all live there). Work through it by
**Building Category** (see Resources section in `full_design/04_buildings_and_economy.md`):

1. [x] Basic Resource Production — Building Schema defined; Solar Array and
   Matter Extractor defined against it; old Solar Rig/Matter Manipulator
   replaced. (Note: the overflow-into-Matter breakdown mechanic mentioned here
   originally was later removed entirely — general inventory became fully
   uncapped when Storage, step 6, was designed.)
2. [x] Farm/Production — 8 basic crop/animal buildings (Grain Field, Fruit
   Orchard, Dairy Pasture, Poultry Coop, Sheep Pasture, Fiber Field, Timber
   Grove, Trapper's Den) with first-pass illustrative numbers, plus 3 mining
   buildings (Mine, Quarry, Rare Metal Extractor). Introduced the full Deposit
   Discovery system (Surface/Mid-depth/Deep tiers, world-gen-time placement,
   Basic Deposit Survey + repeatable Deep Survey exploration tasks with
   guaranteed-plus-probabilistic reveals). Also resolved the Weather
   Monitoring Station gap below by consolidating it with a new Deposit
   Scanner concept into one **Scanner Station** building (multi-mode,
   upgrades to unstaffed then to simultaneous-all-modes).
3. [x] Food/Meal Conversion — Kitchen building designed: parallel recipe slots
   (deviates from standard multi-recipe pattern), 4 base single-ingredient
   meals covering all PFCV axes, 4 fixed-ingredient combo meals with cosmetic
   flavor-name variant pools. Introduced the multi-slot building footprint
   schema (grid slots = worker capacity) and construction-robot relocation
   (third robot action, resolves the "upgrade needs space" edge case). Meal
   expiration left open, deferred to a consumption-mechanics revisit.
4. [x] Robotics/Fabrication — done out of order (worked backward from
   fabrication demand to confirm raw-material uses). Five buildings: Robotics
   Assembly (Construction Robot, All-Purpose Drone Basic/Advanced, Specialized
   Drone), Stone Processing (Concrete, Silicon), Textile Workshop (Fabric,
   Leather Boots), Tinkerer's Workshop (High-Tech Components, High-Res Screens,
   Portable Scanning Equipment, Temperature-Resistant Gear, Diplomatic Gear),
   Carpenter's Shop (Fine Furniture, Ornamental/Decorative Items). New
   multi-recipe building schema pattern established (player-selected active
   recipe, both multi-output and multi-input-path forms).
5. [x] Protection — Weather Shield (AOE, unstaffed, temperature-coupled
   Energy upkeep, no data-gating) and Medical Bay (staffed, base tier
   immediate, Vaccine Production tier gated behind a real
   `Confidence(Bio-hazard)` threshold — resolves the Medical/Vaccine gap
   below). Both consume High-Tech Components at their upgraded tier.
6. [x] Storage — General working inventory made fully uncapped (removed the
   old capacity/prioritization/overflow-breakdown mechanic entirely). Added
   **Food Storage**, the one deliberate low-effort-philosophy exception: a
   dedicated building that "consumes" deposited food (removing it from active
   use) in exchange for counting its nutrient value toward
   `NutritionStockpile` — uncommitted food in general inventory now
   contributes nothing to that score. Base-tier capacity deliberately
   insufficient for a max score, forcing upgrades/multiple buildings as an
   ongoing investment.
7. [x] Exploration Support — resolved: not warranted as a distinct building
   category. Cut from the Building Categories list (see Resources in
   `04_buildings_and_economy.md`); the Exploration Tasks system covers this
   need on its own.

Then close out:
- [ ] Development Bloc rarity weights
- [ ] `TechAchievement` values across the catalog
- [ ] Frontier Legends hard-sites catalog
- [ ] **Drone specification pass** — surfaced while designing Temperature
  Extremity's settler consequence: there's no existing drone battery/energy
  model anywhere in this design at all, so "battery drain scales with
  temperature deviation" (the drone-specific Temperature Extremity
  response, as opposed to settlers' slow-then-life-threatening shape)
  can't be written until a real drone energy system exists. Also open:
  whether advanced drone tiers get better temperature tolerance as an
  upgrade axis.
- [ ] Remaining numeric TBDs from the Settler State / Injuries / Storied
  design pass: Storied's `legend_value` threshold; the Temperature
  Extremity settler death-probability on extreme exposure; Trapping's and
  Clear-Cutting's per-settler speed rates.

## Core Loop / Structural Gaps

- [x] **Action/decision complexity accounting** — resolved: audited every
  current decision category (construction, worker/recipe assignment, Weather
  Shield placement, exploration tasks, Ration Press, Food Storage deposits,
  Transmission-driven reactions) against frequency and stickiness, then
  profiled a full 15-season run. Verdict: comfortably within the
  ~30-second-to-plan-a-season guideline for the large majority of seasons —
  sticky-by-default assignment means most non-exploration, non-construction
  seasons cost near-zero input, especially in the back half of a run.
  **Season 1 is the one expected exception** (60–90+ sec, no accumulated
  sticky state yet for several first-time placements at once) — acceptable
  as a one-time onboarding cost, same category as Farm Site Selection, but a
  pre-populated default first-season loadout would be worth considering if
  it should also hit the 30-second bar. Also identified where the
  *sanctioned* optimization ceiling (as opposed to the passable-plan floor)
  concentrates fastest: multi-recipe buildings and Kitchen slots, which by
  late-game could mean ~8 independent sticky recipe/mode dials for an
  engaged player to revisit — not a problem now, worth watching as more
  buildings are added. Confirmed the Weather/Row Shield Energy-funding
  mechanic (see Planets & Scoring's In-Simulation Hazard Events) does *not*
  add a new recurring action, per its own design intent — it's a background
  check against reserved Energy, not a manual per-event decision.
- [ ] **Season simulation** — in progress. **Resolved so far**: fixed
  real-time window length (seasons correspond to fixed real-world time
  in-fiction; playback speed stays a pure time-multiplier); two resolution
  contexts, Outside-Sim (merges pre-clock, post-clock, and
  start-of-next-planning into one mechanically-equivalent instantaneous
  bucket) and Mid-Sim (the only place real time passes — continuous
  production plus any discrete event with a genuine reason to occupy a
  specific interval, e.g. hazard events); the "ambient Mid-Sim visual for an
  Outside-Sim-resolved activity" pattern (see Art Design); the
  **log/event-feed system** (see Core Loop & Grid's Season Structure) — a
  single togglable log (no forced overlay), per-resource-type aggregated
  production lines that live-update/re-timestamp, individual lines for
  noteworthy events, Transmissions kept fully separate. **Still open**: how
  multiple buildings' continuous production cycles interleave *visually*
  beyond the log itself; the internal sub-step ordering within Outside-Sim.

## Cross-System Consistency Gaps (found via design audit)

- [x] **Forest tiles missing from the canonical Fixed/environmental slots
  list** — resolved: added as a third bullet in Core Loop & Grid's The Grid
  (Unified) section, alongside impassable terrain and deposit locations.
- [x] **`DisruptionFootprint`'s interaction with Forest/Clear-Cutting not
  stated** — resolved, and generalized beyond just Forest (see Win/Lose
  Conditions' Stewardship Caucus): `DisruptionFootprint` is now a weighted
  ratio — any fixed/environmental slot changed from its Season-1-start
  state counts as base-disrupted (uniformly across deposits, Forest tiles,
  everything); slots whose feature required active Mid-depth/Deep survey
  discovery before being acted on count as *further* disrupted, weighted
  higher than a base disruption (exact weight TBD). Surface-tier deposits
  and Forest tiles, never having been hidden, never get the extra weight.
- [x] **`ExtractionRestraint`'s scope is ambiguous beyond literal
  Ore/Stone/rare-metal mining** — resolved, and generalized into a full
  three-axis reconsideration of the whole Stewardship formula (see Win/Lose
  Conditions' Stewardship Caucus): `ExtractionRestraint` now covers any
  **non-sustainable** resource volume — Ore/Copper/Stone/rare metals
  (regardless of bounded/effectively-infinite deposit sub-type),
  Fossil Fuel, and specifically Clear-Cutting's (not Timber Grove's) Wood
  output — tracked at the point of harvest, not by tracing consumption, which is
  what lets Wood stay one fungible pooled resource with two sources rather
  than needing a separate item. Well and Geothermal stay excluded (ongoing,
  non-depleting). This also produced a clean three-axis mental model for
  the whole formula: `DisruptionFootprint` = did you disturb the tile at
  all, `ExtractionRestraint` = was the resource sustainable, `EmissionsRestraint`
  = did you burn it regardless of source sustainability. Also added, while
  here: an explicit **score bounds/units rule for all five SEED Factions**
  (0–100%, each faction's probability of recommending a seed-ship), since
  none of the formulas previously landed in a stated range at all.
- [x] **Relocation of deposit/feature-gated buildings not addressed** —
  resolved (see Core Loop & Grid's Construction): Mine, Quarry, Rare Metal
  Extractor, and Geothermal Generator *can* be relocated, but only to a
  different tile with an already-discovered, not-yet-built-on deposit of
  the matching type (Well excluded — it isn't actually deposit-gated).
  Also clarified, generally: relocation doesn't re-charge construction
  cost, which combined with the matching-type constraint is what makes
  relocating one of these buildings genuinely useful rather than just
  demolish-and-rebuild — most relevant when a single tile turns out to hold
  more than one extractable resource type (see the deposit overlap audit
  item below), letting a player free up a tile for a different building
  without losing the original structure's sunk cost. (Logging Camp was
  originally in this list too, at the time this was resolved — since
  superseded by Clear-Cutting, a Standing Assignment, not a building; see
  the Assignment-unification entry below.)
- [x] **Fuel-based Generator's fuel-selection doesn't cleanly match either
  established multi-recipe form** — resolved by removing the taxonomy
  entirely rather than adding a third form to it (see Buildings & Economy's
  Building Schema): **Input and Output are now universal properties** on
  every building (multisets of resources/items, independent of Staffing,
  possibly empty), not a "Production conversion" property conditional on
  category. A "recipe" is just one Input/Output pairing; a multi-recipe
  building simply defines more than one, with no named sub-shapes —
  Robotics Assembly (differs by output item), Diplomatic Gear (differs by
  input item), and Fuel-based Generator (differs by output rate for the
  same input/output types) are all just instances of the same general
  concept now, nothing to classify.
- [x] **Building Categories list's one-line descriptions are increasingly
  stale** — resolved (see Buildings & Economy's Building Categories):
  Basic Resource Production no longer claims blanket "zero-effort" (now
  notes Geothermal/Fuel-based Generator's real dependencies), Farm/Production
  now mentions forest harvesting, and — the one that had actually gone
  factually wrong, not just stale — Protection's description no longer
  claims the whole category carries temperature-coupled Energy upkeep;
  that's now correctly scoped to Weather Shield/Row Shield specifically,
  not Medical Bay. Cognitive load of accurate category descriptions turned
  out to matter enough to fix now rather than deferring.

## Newly Surfaced Ideas (recorded, not yet designed in detail)

- [x] **Remove Nutrient Paste and the Matter-Manipulator nutrition role
  entirely; replace with starting Rations** — resolved (see Buildings &
  Economy's Ration Press and Settlers & Exploration's Food & Nutrition):
  fixed non-replenishable starting stock (exact quantity TBD), manually
  replenishable via the new unstaffed, instant-conversion **Ration Press**
  building (`floor(min(P,F,C,V)/2)`, lossy), consumed as the concrete
  exploration-task food cost. Once exhausted with nothing else covering
  need, the existing Tier-1 bulk-shortfall mechanic applies unchanged.
- [x] **Farm-site-selection mini-flow** — resolved (see Core Loop & Grid's
  [Farm Site Selection](03_core_loop_and_grid.md#farm-site-selection)):
  one-time pre-run screen (ship-in-foreground/planet-in-background visual),
  after committing to an expedition and before Season 1 planning. Site
  choice varies only the specific grid instance — terrain layout and full
  deposit seeding (Surface/Mid-depth/Deep/aquifer) — never planet-type-level
  values (Hazard Priors, A/B/C/D pressures), which stay fixed once the
  planet type is chosen. 3 candidates shown, previewing only Surface-tier
  deposits and terrain (matching Deposit Discovery's existing visibility
  rule); reroll for 3 new candidates costs 1 Ration, uncapped otherwise.
- [x] **Water resource** — resolved (see Buildings & Economy's Water and
  Deposit Discovery): 1 Water/settler/season pooled baseline, no PFCV-style
  sub-axes; Farm/Production buildings all take a flat Water input per cycle;
  aquifers folded into Deposit Discovery as a fourth deposit type; five
  buildings (Water Condenser, Ice Melter, Cistern, Well — auto-upgrades to
  Deep Well on an aquifer tile — and the starting Water Processing Plant,
  which gates all collection and folds Reclamation into its upgrade tier).
  No dedicated water-storage buildings; water transport deliberately
  unmodeled. **Still open**: settler Water-shortfall consequence model
  (does it mirror nutrition's Tier-1 mechanic, or differ?); exact
  production-rate numbers (TBD, deferred to balancing like everything
  else); Reclamation's unlock gate (tech/resource prerequisite, not yet
  specified).

## Other Fabrication-Adjacent Gaps (found auditing while designing
Robotics/Fabrication)

- [x] **Medical/Vaccine production** — resolved by **Medical Bay** (see
  Protection): base tier immediate, Vaccine Production tier gated behind a
  `Confidence(Bio-hazard)` threshold, directly realizing the "can't produce
  a vaccine without enough bio-data" rule as a discrete build-order gate.
- [ ] **Livestock vaccines** — back-burner idea, recorded not designed:
  protecting animal-production buildings (Dairy Pasture, Poultry Coop, Sheep
  Pasture) from Bio-hazard (and maybe Weather) via a produced vaccine *item*
  distinct from the human Vaccine Production unlock — would imply an actual
  recurring manufactured good rather than a one-time settlement-wide fact.
  Low-overhead, flavorful, not urgent.
- [x] **Weather Monitoring Station** — resolved by consolidating into **Scanner
  Station** (see Farm/Production), alongside a new Deposit Scanning mode.
- [x] **In-simulation hazard events (weather gameplay effects)** — resolved
  (see Exoplanet Types' In-Simulation Hazard Events in
  `06_planets_and_scoring.md`): reuses the existing hidden per-observation
  Bernoulli draw as the event trigger; telegraphing via Transmissions scales
  continuously with `Confidence(hazard)` (near-zero confidence gets only a
  one-time run-start SEED-summary transmission surfacing planet-type
  priors); consequence severity scales with the `Preparedness` gap
  (Storm/Temperature: no-effect/pause/disable-and-rebuild tiers;
  Atmospheric: settler status-effect debuff, resolves PPE's farmland use
  case). Surfaced a new open thread below (settler identity/state).
- [x] **Energy usage/upkeep and Temperature mechanic** — resolved (see
  Buildings & Economy's Basic Resources for the upkeep rule, and Planets &
  Scoring's In-Simulation Hazard Events for Temperature Extremity/Storm):
  every building draws a flat per-season Energy upkeep decided at
  build-time, regardless of staffing, with exactly one exception — Weather
  Shield/Row Shield instead carry a variable, event-severity-banded cost
  (mild/extreme, weighted by `TrueRisk`) — the only place Energy management
  is meant to feel like an ongoing, reactive decision rather than a one-time
  build-time budget line. Temperature Extremity got its own concrete
  mechanism: a per-site Average Temperature (sampled at world-gen from
  `TrueRisk(Temp)`, shown at Farm Site Selection) tracked against a
  universal 72°F comfort target; funded shield coverage = zero effect,
  unfunded/uncovered = slowed (mild event) or stopped (extreme event),
  always temporary. Storm's existing 3-tier coverage model is unchanged but
  now explicit that its top tier means literal destruction, plus a new
  small chance (TBD) that an extreme-severity storm also destroys other
  unprotected buildings elsewhere on the grid. Also confirmed: destroying
  Medical Bay doesn't revoke an already-unlocked Vaccine (permanent
  settlement-wide fact, not tied to the building's continued existence).
- [x] **Alternative Energy sources** — resolved (see Buildings & Economy's
  Basic Resource Production and Deposit Discovery): **Geothermal
  Generator**, gated behind a new **Thermal Vent** deposit type
  (Volcanic-exclusive — guaranteed present on Volcanic, absent everywhere
  else, unlike the other four deposit types which merely vary in
  frequency). Unstaffed, like Solar Array — the real tradeoff is scarcity
  (capped by how many Vents exist) rather than a labor cost, which doesn't
  fit geothermal's actual real-world operating profile. Meaningfully
  outproduces Solar Array's Volcanic-tier rate, letting a Volcanic run
  offset Weather Shield's temperature-driven Energy cost — closing the loop
  back to why this building was proposed in the first place.
- [x] **Fuel-based Generator** — resolved (see Buildings & Economy's Fuel
  and Deposit Discovery, and Win/Lose Conditions' Stewardship Caucus): a
  genuine two-stage supply chain, not a single building. **Forest tiles**
  (visible from run start, count varies by planet/site, shown at Farm Site
  Selection) hold a bounded, non-regenerating quantity of **Wood** —
  updated after further discussion: this is the *same* Wood Timber Grove
  produces, not a separate "Fuel" item; see the `ExtractionRestraint`
  resolution below for how the two sources stay distinguished without
  splitting the resource — harvested via **Clear-Cutting** (further updated
  below — a Standing Assignment, not a building at all). **Fuel-based
  Generator** is unstaffed and burns Wood → Energy per cycle, drawn from
  pooled inventory automatically like Water. Upgrade tier burns discovered
  **Fossil Fuel** instead (a new 6th, hidden Deposit Discovery type, skewing
  Mid-depth/Deep, frequency tied to each planet type's existing
  `TrueRisk(Bio-hazard)` value as a biological-richness proxy) for a higher
  Energy return per unit. No further upgrade path beyond that — unlike
  Solar Array (scales toward a clean Fusion Generator payoff) or Geothermal
  (clean but scarcity-capped), this building's ceiling is "burn a better
  fuel," never "become clean." Available from run start, no unlock needed.
  New Stewardship formula term `EmissionsRestraint`, penalized by cumulative
  Energy produced this way, with Fossil Fuel penalized at a modestly higher
  flat per-unit rate than Fuel (not linearly scaling with output) — the
  direct playable echo of Ren's story thread: Stewardship rewards a new
  planet's climate stewardship on its own terms, independent of how Earth's
  own unresolved climate debate turns out.
- [x] **Logging Camp removed; Assignment unified into one general concept**
  — resolved (see Core Loop & Grid's Assignment, and Settlers &
  Exploration's Exploration Tasks and new Standing Assignments): Logging
  Camp never made sense as persistent infrastructure — a Forest tile is a
  one-time resource, not a deposit worth building on. Replaced with
  **Clear-Cutting**, a settler assignment with the same resolution shape as
  Exploration Tasks (gone for the season, returns with a result), yielding
  a portion of a Forest tile's bounded Wood per assignment, repeatable
  until exhausted. This prompted a bigger unification: **"Worker Assignment
  (Staffing)" renamed to "Assignment,"** now framed from the start as one
  concept — pair a worker with a target — with three target kinds
  (Production building: sticky, settlers or drones; Exploration Task:
  one-shot, pool-limited, risky, settler-only; **Standing Assignment**:
  one-shot, always available every season, safe, settler-only) rather than
  three separately-named systems. **Basic Deposit Survey and Deep Survey
  also moved into Standing Assignments** — available from Season 1, not
  gated to the every-3rd-season Exploration Tasks pool. (Further refined
  just after this: Basic Survey now covers a chosen rectangle and flags
  deep-eligible tiles rather than being a blanket unlock — see the deposit
  overlap audit resolution below for the current mechanism.) This replaces
  the old "guaranteed escalation into the next pool" mechanism, which
  still applies unchanged to genuine Exploration Tasks — the
  sentience-contact chain and Vaccine-unlock region reveal are untouched.
- [x] **Deposit overlap audit** — resolved (see Buildings & Economy's
  Deposit Discovery, new "Overlap" subsection): Ore/Stone/rare-metal are
  mutually exclusive with each other (one "rock type" per tile); Aquifer,
  Thermal Vent, and Fossil Fuel can each coexist with each other and with
  the tile's one mineral type (physically distinct resources — Aquifer +
  Thermal Vent is just a hot spring); Forest coexists with any hidden
  deposit/feature but is mutually exclusive with Surface-tier deposits
  specifically (a tile can't visually present as both at once). Delivers
  the "force a real choice" goal directly: overlapping deposits force a
  building-vs-building choice (only one fits the grid slot, resolved via
  relocation later if desired), while Forest+hidden-deposit overlap doesn't
  force anything, since Clear-Cutting isn't a building.

  This also prompted a genuine mechanic redesign for **Basic Deposit
  Survey and Deep Survey** (see Deposit Discovery and Settlers &
  Exploration's Standing Assignments): discovery now resolves per
  (tile, depth) pair, not per tile alone and not per type. Basic Survey
  covers a player-chosen rectangle of tiles (size TBD) rather than the
  whole farm, and as a side effect flags which surveyed tiles have a
  Deep-tier feature present (not what it is) — **deep-survey-eligible**.
  Deep Survey has no rectangle choice; it automatically targets every
  flagged tile so far, cumulative across however many Basic Surveys
  contributed to that set, and still requires Portable High-Powered
  Scanning Equipment to perform at all regardless of eligibility. This
  replaces the earlier "Basic Survey unlocks Deep Survey" framing with
  something that needs no separate unlock gate at all — Deep Survey is
  simply meaningless until a tile is flagged, meaningful the moment one
  is. Scanner Station's Deposit Scanning mode is unaffected by any of
  this — the rectangle/flagging pattern is specific to settler-performed
  surveys, not building-based scanning.
- [x] **Native-flora hybridization** — resolved (see Buildings & Economy's
  Farm/Production, Research Lab, and Resources; Core Loop & Grid's
  Agriculture Branching): a new general-purpose **Research Lab** building
  (Utilities, deliberately named/scoped to host future Basic-Science
  research beyond just this) lets the player research a specific
  exploration-discovered hybridization for **one plant-crop building at a
  time** (Grain Field, Fruit Orchard, Fiber Field, or Timber Grove — not
  the animal-based buildings). Completing research permanently changes
  every instance of that building type, no per-instance Construction Robot
  upgrade needed, since crop buildings replant every cycle anyway. Two
  benefits per hybridized building: **universal** immunity to a new
  **Alien Soil** standing growth penalty (all non-hybridized plant crops
  carry it, removed by **Fertilizer** — a new resource, passively produced
  by livestock buildings just by existing on the farm, drawn automatically
  once per season) that hybridized crops never need again; and a
  **planet-specific signature benefit** tied to that planet's defining
  hardship or opportunity — reduced Water on Arid, Temperature Extremity
  immunity on Ice/Volcanic (direct reuse of the existing hazard-consequence
  mechanic), higher yield on Verdant. Deliberately kept resource-gated, not
  research-gated, consistent with the existing Technology & Progression
  principle — no abstract research-points currency, just a bespoke
  per-discovery unlock.
- [x] **Livestock structures deserve a deeper design pass** — resolved for
  the Trapper's Den piece (see Buildings & Economy's Farm/Production and
  Settlers & Exploration's Standing Assignments); Dairy Pasture/Poultry
  Coop/Sheep Pasture deliberately left untouched, since they're uniform
  Earth-imported livestock with no reason to vary by planet. **Trapper's
  Den is gone as a building** — traps set on a tile are just that, no
  persistent structure, so it's now **Trapping**, a fourth Standing
  Assignment: assign a settler to any tile for the season, they return with
  Pelt (still one resource everywhere, per the existing catalog-bloat
  principle — cosmetic flavor-name variation by planet is a cheap optional
  touch, reusing Kitchen's combo-meal flavor-name pool pattern). Yield
  scales with the planet's biological richness (reusing the
  `TrueRisk(Bio-hazard)` correlation already established for Fossil Fuel,
  rather than a new dial) and with whether the target tile currently has
  Forest present — unforested or already-clear-cut land is less habitable
  for prey animals. That last point creates a direct, legible tension with
  Clear-Cutting: harvesting a Forest tile's Wood permanently reduces that
  tile's future trapping potential too. Unlike Clear-Cutting, Trapping is
  renewable and repeatable indefinitely on the same tile, not a bounded
  one-time harvest. Deliberately no Bio-hazard exposure risk added for
  trapping wild animals — that would pull in the not-yet-built per-settler
  state system (already flagged for Frontier Legends and the Atmospheric
  Hazard debuff), left out rather than folded in here.
- [x] **Category naming** and **Scanner Station's Building Category** —
  resolved together (see Buildings & Economy's Building Categories):
  **"Robotics/Fabrication" renamed to "Fabrication"** (it already held Stone
  Processing, Textile Workshop, Tinkerer's Workshop, and Carpenter's Shop —
  broader than "robotics" implied). **New 7th category, "Utilities"**,
  resolves Scanner Station's gap and a second one found in the same pass:
  **Water buildings had no Building Category assigned at all**, the same
  class of gap, just never flagged. Utilities now covers both — staffed
  settlement-support infrastructure that isn't farming, fabrication,
  storage, or protection. Confirmed before making the change that Building
  Category is purely a documentation/organizational taxonomy — nothing in
  scoring, staffing rules, or the separate (and unaffected) drone
  job-category system reads it — so the rename/regroup carries no gameplay
  or story dependency.
- [x] **Exploration Tasks framework iteration, and a full Energy Pool
  redesign it pulled in** — resolved (see Settlers & Exploration's
  Exploration Tasks, and Buildings & Economy's Resources and Fuel). The
  exploration pool is now **always available every season**, not gated to
  the old every-3rd-season window — since the player never has to commit to
  anything in it anyway. The whole pool (up to 3 tasks) refreshes on two
  triggers, automatic season-start and manual reroll, except any task the
  player has explicitly (and freely) **locked**. Manual reroll costs a flat
  amount of **Energy** — diegetically framed as re-scanning the region, the
  same principle already used for hub-level filament-scanning — which
  prompted formalizing **Energy as its own system, not an inventory item
  at all** (orthogonal to Storage's uncapped-inventory rules, not a second
  exception to them): a liquid pool with a **cap** (sum of Energy-producer
  capacity contributions minus total building upkeep — upkeep now
  permanently reduces the ceiling rather than being a recurring
  withdrawal), continuous **income** during Mid-Sim from constant-rate
  producers, and discrete **draws** against the current balance (Weather/Row
  Shield's existing event-driven funding, now joined by exploration reroll).
  Fuel-based Generator contributes to the cap unconditionally (assumed
  structural battery) but only contributes to income while actively
  burning — it now gets its own planning-phase active/inactive toggle plus
  a seasonal fuel limit, burning for a duration set by that limit (or fuel
  availability) against its efficiency, replacing the earlier "control
  lever lives upstream at Clear-Cutting" framing. The Energy meter reads as
  a smooth continuous fill, extending the existing continuous-rate
  Production Model principle to Energy's UI. Also **two new Outcome
  types** added to Exploration Tasks: **Hybridization opportunity** (a Site
  Reveal variant, formally linking exploration to the already-designed
  Hybridization mechanic) and **Legend outcome** (rare, little/no material
  reward, large one-time Frontier Legends value, always Neutral in the
  Strategy Dimensions framing since its value lives outside A/B/C/D —
  first-of-kind achievements are the first worked example; per-settler
  personal-story-moment outcomes are a natural extension but deliberately
  left undesigned, pending the not-yet-built per-settler tracking system).
  **Farm-wide Upgrade outcome** (also new) is confirmed as a second,
  exploration-specific pathway to the reward shape Water Processing
  Plant's Reclamation tier already established, not a replacement for it.
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
- [x] **Alien civilization classes** — resolved (see Settlers & Exploration's
  Escalation Chains): five axes (Technology Level, Openness, Economic
  Stability, Ubiquity, Unity) combine into four curated classes (Verdant
  Assembly, Hollow Kilns, Drift Caravans, Frostbound Remnant) rather than a
  full cross-product. Biological Compatibility deliberately left as
  per-class flavor text, not a mechanical axis. First Contact (formerly
  the Peaceful/Aggressive branching choice) now surfaces as one pool slot
  with three switchable approaches — Peaceful Contact, Bluff/Coercive
  Exploitation (new), and Military Exploitation (narrowed from the old
  Aggressive/Exploitative Contact) — and Stewardship Caucus gained a new
  `ContactRestraint` formula term scoring how the player handled any
  encounter. **Still open, deferred to balancing:**
  - Exact `ContactRestraint` tier values
  - Exact Bluff success-probability curve vs. Technology Level
  - Exact Military success-probability curve vs. Technology Level + Unity
  - Peaceful Contact's base alliance rewards, and its per-tier deepening
    rewards
  - Bluff's on-success payout amount (relative to an undeepened alliance's
    baseline)
  - Military Exploitation's success rewards
  - Overwhelming Force Package's exact recipe (a first-pass placeholder is
    written into Buildings & Economy's Fabrication)
  - Exact legend-value-scaling formula shape (inverse of success
    probability, magnitude TBD)
