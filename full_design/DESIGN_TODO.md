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
  - [ ] Individual-settler tracking system (doesn't exist at all yet — now
    also needed by the Atmospheric Hazard status-effect debuff, see
    In-Simulation Hazard Events; design both together, not twice)
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
7. [ ] Exploration Support (if warranted as distinct from Exploration Tasks
   itself)

Then close out:
- [ ] Development Bloc rarity weights
- [ ] `TechAchievement` values across the catalog
- [ ] Frontier Legends individual-settler tracking system
- [ ] Frontier Legends hard-sites catalog

## Core Loop / Structural Gaps

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

## Newly Surfaced Ideas (recorded, not yet designed in detail)

- [x] **Remove Nutrient Paste and the Matter-Manipulator nutrition role
  entirely; replace with starting Rations** — resolved (see Buildings &
  Economy's Ration Press and Settlers & Exploration's Food & Nutrition):
  fixed non-replenishable starting stock (exact quantity TBD), manually
  replenishable via the new unstaffed, instant-conversion **Ration Press**
  building (`floor(min(P,F,C,V)/2)`, lossy), consumed as the concrete
  exploration-task food cost. Once exhausted with nothing else covering
  need, the existing Tier-1 bulk-shortfall mechanic applies unchanged.
- [ ] **Farm-site-selection mini-flow** — after choosing a planet (via the
  filament-scanning mechanic), a new pre-run screen to choose a specific
  farm site/grid layout from among candidates on that planet: a small
  spaceship in the foreground orbiting the target planet (planet visible in
  background), plus a UI showing the candidate site's grid layout and a
  summary of known features (surface Ore/Stone deposits, and other
  potentially space-scannable features not yet designed). Open question:
  does site choice vary planet-type-level parameters (hazard priors, etc.),
  or only the specific grid layout/deposit arrangement within a fixed
  planet type?
- [ ] **Water resource** — a new basic resource, ambiguous units (e.g. "3
  Water"), no complicated irrigation system. Needed for settler survival
  (alongside nutrition) and for plant/animal production — **this has a real
  retroactive impact on every already-designed Farm/Production building**,
  all currently specified as "no resource input." Collection methods:
  **Springs** (discoverable like ore deposits, planet-type-based frequency),
  **Water Condenser** (draws from air/humidity — best on Volcanic; Verdant
  has humidity too but easier direct liquid-water access makes condensing
  non-optimal there; Ice and Arid/Desert too low-humidity to be effective),
  **Deep Well** (sub-surface water, usable on any planet type, lower
  production rate than specialized methods). More collection methods
  wanted — flagged for brainstorming.

## Other Fabrication-Adjacent Gaps (found auditing while designing
Robotics/Fabrication)

- [x] **Medical/Vaccine production** — resolved by **Medical Bay** (see
  Protection): base tier immediate, Vaccine Production tier gated behind a
  `Confidence(Bio-hazard)` threshold, directly realizing the "can't produce
  a vaccine without enough bio-data" rule as a discrete build-order gate.
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
- [ ] **Alternative Energy sources** — the old design had "Fuel-based power
  buildings" as a tech-gated alternative to Solar. Given strategy dimension D
  (Energy Management) is supposed to have real teeth, are there other
  Energy-producing buildings beyond Solar Array (e.g. something
  Volcanic-specific, tying into the hazard↔resource correlation)? Unexplored.
- [ ] **Native-flora hybridization** — the Local Agriculture path/strategy
  dimension B is referenced repeatedly but has no actual building/mechanic for
  *how* hybridizing with native flora works in gameplay terms. A real content
  gap.
- [ ] **Category naming** — minor: "Robotics/Fabrication" now holds Stone
  Processing, Textile Workshop, Tinkerer's Workshop, and Carpenter's Shop, which
  are broader than "robotics." Worth a rename (e.g. to "Manufacturing") at some
  point, not urgent.
- [ ] **Scanner Station's Building Category** — doesn't cleanly fit any of the
  7 established categories (data-gathering/sensing isn't quite Basic Resource
  Production, Farm/Production, or Exploration Support). Related to the
  Category naming item above — worth resolving both together, possibly by
  adding an 8th category.
