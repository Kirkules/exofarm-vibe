# Buildings & Economy

## Resources

### Basic Resources
- **Energy** — a colony-wide **rate**, not a stockpile (see [Resources](04_buildings_and_economy.md#resources)'
  Energy Income/Consumption Rates below). Base production is
  **zero-effort/unstaffed** (see [Building Categories](04_buildings_and_economy.md#building-categories) below), unlike ordinary staffed
  production sites.
- **Water** — also a colony-wide **rate**, not a stockpile, same shape as
  Energy (see [Water](04_buildings_and_economy.md#water) below); no complicated irrigation/transport system to
  model. Unlike Energy, collection requires staffed buildings and a
  prerequisite structure (Water Processing Plant) — not zero-effort.
- **Matter no longer exists as a resource.** It's been removed entirely,
  along with Matter Extractor as a starting building — construction costs
  now run on Lumber and Concrete (see Baseline Farm/Mined Resources below
  and Sawmill/Stone Processing under Fabrication) instead of a generic
  filler resource, and the settlement's initial footing comes from a
  starting Rations stockpile (see Settlers & Exploration's Rations) plus
  what Clear-Cutting and the two starting Fabrication buildings can
  self-bootstrap from turn one — no separate starting-materials stockpile
  is needed.

**Energy Income/Consumption Rates.** Energy is not an inventory item — it
never appears in the general inventory list alongside Wood, Stone, food,
etc.; it's tracked as its own separate system (a dedicated bar in the UI),
**orthogonal** to Storage's uncapped-inventory rules entirely, not a second
exception to them. Unlike every other resource, **Energy is never
stockpiled at all** — there's no accumulated balance carried between
moments or across the season boundary, only two continuously-tracked live
rates: total **Income** (Energy/s) and total **Consumption** (Energy/s).
Whether the settlement is "keeping the lights on" is purely a live
comparison of these two numbers, never a depleting reserve.

- **Income** splits into two kinds. **Reliable** sources (Solar Array,
  Geothermal Generator — see [Basic Resource Production](04_buildings_and_economy.md#basic-resource-production)) produce at a
  genuinely constant rate for the whole season, no failure mode. **Conditional**
  sources (Fuel-based Generator — see [Fuel](04_buildings_and_economy.md#fuel)) contribute only while actively
  burning, per its planning-phase active/fuel-limit control, dropping to
  zero the instant fuel runs out or a hazard disrupts production — it
  doesn't necessarily cover the whole season, and unlike Reliable sources
  carries genuine risk of falling short of plan.
- **Consumption** is every building's flat per-season baseline rate (below)
  summed together, plus any temporarily **elevated** consumption from an
  active source — Weather/Row Shield's event-driven cost during an active
  hazard, or a drone's battery recharge (see [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)) — layered
  on top for as long as that source is active, then dropping back to
  baseline.
- **When total Consumption exceeds total available Income** at any Mid-Sim
  moment, the shortfall is resolved by **randomly** selecting enough
  currently-drawing consumers to un-power until Consumption fits back under
  Income — deliberately random, not by build order or any player-set
  priority, so *which specific building goes dark* is never something a
  player can optimize or needs to manage; the player's real levers are
  building more Income capacity and the active/inactive toggle **every**
  building has (generalizing Fuel-based Generator's existing control, see
  its entry), not triaging an outage order. This keeps the tension real
  ("build enough Income for what you're running") without turning outages
  into a minigame, which would sit oddly against the cozy tone. **The
  design does not lean on the toggle** — no other system is built assuming
  routine use of it; it's an available mitigation, not an expected
  season-to-season chore.
  - **Eligibility.** Every Energy *draw* is eligible. Energy *producers*
    (Solar Array, Settlement Base, Geothermal Generator, Fuel-based
    Generator) draw no Energy at all — they only produce it — so they are
    never un-powered by this pass.
  - **An un-powered building draws zero Energy** and its cycle **pauses —
    progress is held, never lost** — resuming the instant it is re-powered.
    A staffed building that goes dark **holds its worker idle** (the worker
    is not returned to the roster mid-Mid-Sim).
  - **The pass iterates to a fixed point:** after each building is
    un-powered, total Consumption is recomputed and the check repeats,
    re-rolling the random pick among still-powered draws, until Consumption
    ≤ Income. Recomputed on every event that changes the total — a
    Conditional source's window starting/ending, a hazard event
    starting/ending, a drone battery recharge starting/ending, a building
    built/destroyed/toggled — not continuously every tick, so the unpowered
    set doesn't flicker without a real cause.
  - **Consequence is throughput only.** An Energy shortfall can slow or
    pause production, nothing more — it can never kill a settler or end a
    run. Buildings with a survival-critical function keep that function in
    a reduced form when un-powered: a Water collection building still
    produces a minimal fail-safe trickle (see [Water](04_buildings_and_economy.md#water)); crew quarters
    still shelter the crew for sleep, just without the sleep bonus (see
    [Habitation](04_buildings_and_economy.md#habitation)); an Indoor building still shelters its worker from
    Atmospheric Hazard, though not from temperature (see [Building Schema](04_buildings_and_economy.md#building-schema)'s
    Indoor/Outdoor). A Weather/Row Shield that cannot be powered simply
    goes **inactive** (no protection) for that interval.
  - **Legibility.** Every un-powering surfaces in the simulation log with
    its cause (`"Energy shortfall — [building] offline"`) and counts as a
    noteworthy event, so an unexplained production gap is never mistaken
    for a bug and bad luck is never mistaken for a preventable certainty.
- **Planning-phase UI**: a horizontal bar, **0 to the season's optimistic
  max Income rate** (sum of every currently-placed producer's maximum
  rate — Reliable plus Conditional, assuming every Conditional source runs
  its full planned window uninterrupted), with two indicator lines on it:
  current planned Income rate and current planned Consumption rate. This is
  explicitly a best-case estimate, not a guarantee — the bar's hover
  tooltip states plainly that actual results can come in lower if fuel runs
  out early or a hazard disrupts production, so the player never mistakes
  the bar for a promise.
- **Per-building prediction (see Core Loop & Grid's Site Panel (UI))**: a
  building is **Green** if Reliable Income alone already covers its share
  (powered no matter what happens to fuel or weather), **Red** if not even
  the full optimistic estimate covers it (will never be powered this
  season), and **Yellow** if it's covered only *with* Conditional sources
  included — powered under the optimistic plan, genuinely at risk if fuel
  runs out early or a hazard cuts production. A real, calculable
  distinction, not a live status — see Design Principles' "color is never
  the sole channel of information" rule for why this also needs a
  shape-coded icon, not color alone.

**Baseline Energy upkeep.** Every building — staffed or not, and regardless
of category — draws a flat per-season Energy **consumption rate** just for
existing on the grid (lights, climate-neutral operation, idle machinery
draw), with exactly one exception: **Weather Shield and Row Shield** (only
these two — not the rest of Protection, so Medical Bay follows the ordinary
flat-baseline rule like any other staffed building). A shield draws
**nothing at all when it is inactive**, and draws only while **active** —
its activation is automatic, never player-managed: a shield is active
exactly when either a Storm or Temperature Extremity event is affecting its
coverage area, **or** the site's ambient temperature sits outside the 72°F
comfort band and needs continuous mitigating for the settlers or crops
there (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)). While
active its draw is **banded** — a lower rate for ambient mitigation or a
mild event, a higher rate for an extreme event. This is still a deliberate
simplicity choice: no individual building's own baseline rate ever needs
re-examining once built, fixed the moment it's placed — but the *aggregate*
relationship between total Consumption and total Income genuinely can shift
over a season now, both because Conditional Income sources can fall short
of plan and because shield draw comes and goes with events. Juggling
Energy in response to short-lived threats (via the two shield buildings,
drone recharge, and Conditional-source risk) is meant to be a real,
occasional consideration; juggling it just to keep the lights on everywhere
else is not. Exact per-building values TBD, deferred to balancing like
other numeric values in this design.

### Building Categories
1. **Basic Resource Production** — Energy generation, always
   unstaffed — though not all zero-effort in practice: Geothermal Generator
   needs a discovered Thermal Vent, and Fuel-based Generator needs a real
   Wood/Fossil Fuel supply chain and carries an ongoing Stewardship cost
   (see [Fuel](04_buildings_and_economy.md#fuel)).
2. **Farm/Production** — crops, animal products, and mining, staffed sites
   (see [Baseline Farm/Mined Resources](04_buildings_and_economy.md#baseline-farmmined-resources) below).
3. **Food/Meal Conversion** — turns raw farm output into meals with nutrient profiles
   (see [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)).
4. **Fabrication** — staffed sites producing drones, construction robots, and
   other fabricated goods (Concrete, Fabric, High-Tech Components, Fine
   Furniture, etc. — see [Platform](03_core_loop_and_grid.md#platform) & Core Loop Redesign's [Construction](03_core_loop_and_grid.md#construction) and
   Worker Assignment sections).
5. **Protection** — force-field/weather-protection structures and Medical
   Bay. Weather Shield/Row Shield specifically (not Medical Bay) carry a
   variable, event-driven Energy cost tied to Temperature Extremity events
   (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)) — always
   explicitly listed when it has an impact, never a hidden drain.
6. **Storage** — contributes inventory capacity, carried over from the original
   design.
7. **Utilities** — staffed settlement-support infrastructure that isn't
   itself farming, fabrication, storage, or protection: Water collection
   (see [Water](04_buildings_and_economy.md#water)), Scanner Station (see [Scanner Station](04_buildings_and_economy.md#scanner-station)), and Research Lab (see
   [Research Lab](04_buildings_and_economy.md#research-lab)). The thing these share isn't output type, it's role —
   keeping the place running rather than producing, protecting, or storing
   anything directly.
8. **Habitation** — crew sleeping quarters (see [Habitation](04_buildings_and_economy.md#habitation)). Unstaffed;
   its output is a settlement-wide settler effect ("Sleep quality"), not a
   tracked resource. The starting Settlement Base fills this role for free
   at the baseline level; a dedicated building is an upgrade over it.

### Baseline Farm/Mined Resources
A small set of **generic resource categories**, common to every mission
(Earth-origin crops/animals, or geologically-common minerals) — multiple
planet-specific sources (native flora/fauna, distinct deposits) can all produce into
the *same* generic category rather than each needing its own tracked resource type,
keeping the catalog from exploding as more planet types are added:

- **Grain** and **Fruit** — baseline crops (Earth seed stock, plantable everywhere).
- **Milk** and **Eggs** — baseline animal products (small-mass "seed stock"
  livestock, plausible to actually bring on a mass-constrained expedition).
- **Wool, Fiber/Cotton, Wood, Pelts** — baseline non-food farm materials
  (construction/fabrication inputs, not nutrition). Advanced/planet-specific
  variants are an open thread, not yet designed.
- **Iron Ore** and **Copper Ore** — mined from distinct deposits (differentiated
  at the source, not from a generic "Ore"). A single site can have multiple ore
  kinds mixed in some percentage distribution (e.g. 70% Iron Ore / 30% Copper
  Ore); each unit mined is an independent random draw from that distribution —
  fine since this randomness resolves during simulation, not planning, per the
  reversibility principle. Basic exploration windfalls (e.g. Exposed Mineral
  Outcrop — see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Task Catalog](05_settlers_and_exploration.md#task-catalog)) also yield Ore, never
  refined metal.
- **Iron** and **Copper** — the refined, usable form of the Ore above, produced
  at the Smelter (see [Fabrication](04_buildings_and_economy.md#fabrication)). Iron: structural strength (robot bodies).
  Copper: electronics components. Higher-tier exploration tasks can skip the
  Ore stage and yield refined metal directly, as part of the reward for their
  added difficulty/rarity.
- **Stone** — mined raw material. Refines at Stone Processing into **Concrete**
  (base tier — the other universal base construction material, alongside
  Lumber) and, once upgraded to Stone Processing II, **Silicon** (electronics
  fabrication) and **Glass** (optics/screens — used by High-Tech Components,
  PPE, hazard-resistant gear, and Biological Lab Materials; broader uses an
  open thread, see `DESIGN_TODO.md`) — see Fabrication.
- **Rare metals** — findable on any planet, but with probability strongly biased by
  planet type. Needed for high-tech applications, including energy-shielding
  devices. Governed by a standing planet-design principle (see Planet Types below):
  a planet's dominant hazard and the materials that counter it are positively
  correlated, but only as a correlation, not a guarantee — a temperate planet can
  still yield them, just less often.
- **Wood has two sources with different sustainability profiles, not two
  separate resources.** Timber Grove's ordinary output (see [Farm/Production](04_buildings_and_economy.md#farmproduction))
  is renewable/ongoing; Clear-Cutting (see [Fuel](04_buildings_and_economy.md#fuel) — a Standing Assignment, not
  a building) harvests from a bounded Forest tile, a one-time harvest that
  does not regenerate within a run. Both produce the same fungible, pooled
  **Wood** — usable interchangeably for fabrication or for burning at
  Fuel-based Generator — but *how* a given unit was produced is what
  matters for Stewardship: only Clear-Cutting's output counts toward
  `ExtractionRestraint`
  (see [SEED Factions](06_planets_and_scoring.md#seed-factions) in Win/Lose Conditions), tracked as a running total at
  production time, not by tracing which specific unit later gets consumed.
- **Lumber** — the refined, usable form of Wood, cut at the Sawmill (see
  Fabrication) — Wood itself is never a direct construction/fabrication
  input once Lumber exists, the same "raw deposit → refined form" shape
  Iron Ore/Copper Ore already established. Now one of the two universal
  base materials every structure's construction cost draws on (alongside
  Concrete), replacing the old Matter resource.
- **Leather** — the refined, usable form of Pelts, tanned at the Textile
  Workshop — a second, independent use for Pelts alongside Fabric (Pelts
  remains a valid direct alternate input to Fabric on its own; tanning is
  only required for the specifically Leather-based goods: Leather Boots,
  Leather Backpack, Temperature-Resistant Gear, Wooden Plow).
- **Fossil Fuel** exists solely as Fuel-based Generator's upgrade-tier input
  (see [Fuel](04_buildings_and_economy.md#fuel)), from a hidden deposit (see [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery)) — always
  non-sustainable, no Timber-Grove-style renewable source exists for it.
- **Fertilizer** — produced passively by livestock buildings (Dairy Pasture,
  Poultry Coop, Sheep Pasture — not Trapping, which harvests wild animals
  rather than raising livestock, and isn't a building at all) just by
  existing on the farm, regardless of
  staffing or whether they're actively producing Milk/Eggs/Wool that season.
  Consumed automatically, once per *season* (not per production cycle), by
  plant-crop buildings to offset the Alien Soil penalty (see [Farm/Production](04_buildings_and_economy.md#farmproduction)).
- **Mining deposits come in two types**: a **high-yield, bounded** site (finite
  total quantity, depletes with use) and a **lower-yield, effectively infinite**
  site (doesn't meaningfully deplete within a run's timescale). Both incur the same
  per-unit Stewardship cost when mined (see [SEED Factions](06_planets_and_scoring.md#seed-factions) in Win/Lose Conditions) —
  the disruption Stewardship objects to is the mining process/infrastructure itself,
  not depletion, so extraction volume is penalized at the same rate regardless of
  deposit type.
- **Seasonings (Herbs and Spices)** — found only incidentally, never through
  dedicated gathering: **Herbs** have a small chance to turn up during
  Clear-Cutting, Basic/Deep Survey, or any Exploration Task; **Spices**
  have a small chance to turn up during Mining (Mine/Quarry/Rare Metal
  Extractor) or any Exploration Task (exact probabilities TBD, deferred to
  balancing). Each planet type has its own roster of roughly 2–3 distinct
  Herbs and 2–3 distinct Spices — genuinely separate, individually-named
  items, not one fungible pooled resource — so a given run only ever
  realistically encounters a handful of the full cross-planet catalog,
  tied to that planet's identity and that run's discovery luck. Each
  Seasoning corresponds to exactly one Gourmet recipe (see Food/Meal
  Conversion's Kitchen) and participates in nothing else, which is what
  keeps the catalog's actual per-run footprint small despite the total
  roster being wide.

### Naming Convention
- Basic resources: simple names (Energy)
- Advanced/rare items: technical compound names (e.g. "Flux-modulated Drone Battery")
- Planet-side materials: can use less familiar names (e.g. "Iridite") since they are
  rarer and encountered later in play

---

## Building Schema

Every building in the catalog (see [Building Categories](04_buildings_and_economy.md#building-categories) in [Resources](04_buildings_and_economy.md#resources)) is defined by
the following properties. Working through the catalog category-by-category (see
`DESIGN_TODO.md`) fills in concrete buildings against this shared schema.

**Universal properties** (every building has these):
- **Name** — per the naming-convention design principle (tier-appropriate
  familiarity/exoticism)
- **Category** — one of the 8 Building Categories
- **Grid slot count** — all buildings sit on a single unified grid (see Core
  Loop & Grid's The Grid). **Slot count equals the number of simultaneous
  worker assignments a building supports** — most
  buildings need 1 worker and so occupy 1 slot (the common case, matching the
  single-cell redesign); a building needing multiple parallel workers (e.g. an
  Upgraded Kitchen with 2 recipe stations) occupies correspondingly more slots.
  Multi-slot footprints are **fixed, non-rotatable shapes** — a much simpler
  echo of the old polyomino system, with no rotation and no orientation-dependent
  effects. An upgrade that expands a building's footprint is only
  offered/confirmable if the required adjacent cell(s) are free — the same
  placement-validity check used for new construction (see [Construction](03_core_loop_and_grid.md#construction), above,
  for how a construction robot can relocate a blocking building to resolve
  this).
- **Input** — a multiset of resources/items consumed, per cycle (continuous-rate)
  or per instant-conversion (see [Ration Press](04_buildings_and_economy.md#ration-press)); may be empty. Applies uniformly
  to every building — no taxonomy of "which category gets this property" is
  needed, since an empty multiset already covers buildings that don't consume
  anything.
- **Output** — a multiset of resources/items produced, on the same timing as
  Input; may be empty, and an output need not be a trackable inventory item at
  all (e.g. data reports, a buff/boost effect for a drone-control structure).
  `production_time` (continuous-rate cooldown, per the Production Model in
  Platform & Core Loop Redesign) applies whenever Output is non-empty and
  production isn't instant. **Alternative: instant conversion** (see Ration
  Press) — the player selects Input directly during planning and the
  conversion resolves immediately, with no `production_time`, no staffing, and
  no rate limit; ordinary planning reversibility still applies (undoable like
  any other planning action until Next Season is confirmed).
- **Staffing** — Unstaffed (zero-effort) or Staffed (requires a worker; if
  staffed, which worker types qualify — Any/Settler-only/specific drone
  category). Entirely independent of Input/Output — staffing says nothing
  about whether a building consumes or produces anything (Solar Array:
  unstaffed, has Output, no Input; Weather Shield: unstaffed, no Input/Output
  at all, just Energy upkeep and Area of effect; Kitchen: staffed, has both).
- **Indoor or Outdoor** — for staffed buildings, whether a worker there is
  physically sheltered. Reuses the **Outdoor/Fieldwork** grouping already
  defined in Settlers & Exploration's Injuries (every Farm/Production
  building, all mining, Clear-Cutting, Trapping, Basic/Deep Survey — plus
  Exploration Tasks, which aren't buildings but follow the same rule) as
  Outdoor; everything else staffed (Kitchen, all Fabrication buildings,
  Research Lab, Medical Bay, Scanner Station, Water buildings) is Indoor.
  A **powered** Indoor building shields its worker (settler or drone) from
  both Atmospheric Hazard and Temperature Extremity for free. An
  **un-powered** Indoor building (shed during an Energy shortfall, see
  [Resources](04_buildings_and_economy.md#resources)) still shelters its worker from **Atmospheric Hazard**,
  but **not from temperature** — for Temperature Extremity it is treated as
  Outdoor, including the extreme-event death roll. (Principle note: a
  temperature death by this path is only ever reachable in a season the
  Temperature Extremity schedule had already telegraphed — see Planets &
  Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events) — so it traces to an
  Energy-budget decision the player made against a known-inbound event, not
  an ambush.) This is a separate,
  free-by-default protection channel alongside Weather/Row Shield, which
  remains how Outdoor sites/crops/workers get protected (funded shield
  coverage protects both the structure/crops *and* any outdoor worker on a
  shielded tile). If a building is destroyed mid-Mid-Sim, its worker is
  freed and returns to the roster immediately, losing whatever Indoor
  protection they had at that instant.
- **Construction cost** — resources required to build. **Lumber and Concrete
  are the two universal base materials every structure draws on** (replacing
  the old Matter resource), with the exact ratio varying per building — some
  lean more Lumber, some more Concrete; additional planet-side/advanced
  materials (Iron, Copper, High-Tech Components, etc.) layer on top for
  more demanding designs, per Technology & Progression. Exact per-building
  Lumber:Concrete ratios TBD, deferred to a follow-up balancing pass (see
  `DESIGN_TODO.md`). Consumed when a construction robot begins the build.
- **`TechAchievement` value** — static, design-authored score on a 0–4 scale
  (see the [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) below for the full rubric and
  per-entry values) — feeds Development Bloc (see [SEED Factions](06_planets_and_scoring.md#seed-factions)
  in Win/Lose Conditions)
- **Repeatable** — whether multiple copies can be built (most can; whether any
  building should be capped at one instance is an open question)
- **Upgrade path** — none, or a defined sequence of tiers, each tier really being
  its own bundle of these same properties, unlocked via a construction-robot
  upgrade action rather than new construction. **Every upgrade bundles a
  free relocation**: the same one robot-action rebuilds the (possibly
  larger) building either on its current cell(s) or on any other valid,
  empty slot(s), placed through the same UI as new construction — so a
  footprint-expanding upgrade is never blocked by a lack of adjacent free
  cells and never costs a second action to clear space. Upgrade-in-place is
  just choosing the current location. **Deposit/feature-gated buildings**
  (Mine, Quarry, etc.) are forced to stay on their deposit.

**A building's Input/Output is usually one fixed pairing, but some buildings
define more than one — "recipes."** Recipes are always chosen explicitly by
the player during planning, never selected automatically in reaction to
stock levels (which was the earlier-flagged risky "automatic alternative
output" idea, and stays rejected). No further taxonomy of recipe shapes is
needed: whether recipes differ in output item (Robotics Assembly), input
item (Diplomatic Gear), or output rate for the same input/output types
(Fuel-based Generator), they're all just alternative Input/Output pairings —
the schema doesn't need a name for each shape.

**Production queue.** Rather than one active recipe per season, every
production building carries an ordered **queue** of steps, each a
`(recipe, limit)` pair where `limit` is a completed-cycle count or
**unlimited**. It is a normal reversible planning-phase choice — edited like
any other planning action, reset fresh each season (all steps present,
cycle-counts zeroed, limits restored). The player uses it to sequence a
season's production without needing to intervene mid-season ("make 3
Biological Lab Materials, then research countermeasures the rest of the
season"; "make 3 Bread, then 1 Gourmet dish"). A single-recipe building has
no ordering to set but can still take a bare `limit` ("make only 5 Concrete,
then idle").

- **Advancement.** The active step ends by either **hitting its limit** —
  removed from the queue for the rest of the season — or being **skipped**
  because its inputs aren't available at the moment it is selected. Control
  then passes to the **next list position, circularly**: past the last
  remaining step, back to the first.
- **Skipped ≠ removed.** A skipped step stays in the queue, retains its
  cycle-count (a skip never resets progress toward a limit), and is
  re-attempted on later passes.
- **Whole-queue skip → dormant.** If advancement goes all the way around and
  every remaining step is skipped, the building goes **dormant** instead of
  spinning — its worker held idle at the site (see [Assignment](03_core_loop_and_grid.md#assignment), and the
  parallel un-powered-building rule under [Resources](04_buildings_and_economy.md#resources)). A dormant queue is
  re-checked every quarter-season and restarts from the top of the list the
  moment any step has inputs.
- Net effect: planned limits are always respected, and production otherwise
  continues through any missing-input situation rather than stalling on it.
- Skip is distinct from **pause**: inputs-out *skips* (advance the queue);
  an un-powered or Water-denied building *pauses* (the current step and the
  whole queue state freeze until it resumes). A step hitting its limit, a
  step being skipped, and a queue going dormant each emit a simulation-log
  line with cause.

**Input consumption and any success roll both happen at cycle start.**
Inputs for a cycle leave inventory when that cycle begins (not on
completion); for a recipe with a non-guaranteed output (see e.g. Food/Meal
Conversion's parasite cook-out), the success/failure roll is made then too,
so the outcome is settled up front rather than at the end. "Inputs ran out
on cycle 3 of 5" therefore means cycle 3 never starts and the step is
skipped with a cycle-count of 2. Fuel-based Generator's planning-phase
fuel-limit control is just a `limit` on its own queue step — no separate
mechanism.

**Conditional properties** (apply depending on category/function):
- **Production cap** — max per-cycle output requiring multiple workers'/drones'
  effort to reach (effort-stacking, per Worker Assignment). Only meaningful for
  **staffed** sites, since it's inherently about worker effort reaching a
  ceiling — unstaffed buildings just produce a flat per-tier rate.
- **Area of effect** — coverage radius/shape for Protection buildings
  specifically.
- **Energy upkeep** — passive per-season Energy cost, usually 0; nonzero
  primarily via the Protection/temperature-coupling mechanic (see Exoplanet
  Types) — always explicitly displayed when nonzero, never hidden.
- **Preparedness contribution** — which Safeguard hazard axis (Weather or
  Bio-hazard) this building counts toward for `MatchedPreparedness(hazard)`, and
  how much.
- **Data-gathering contribution** — which hazard sub-factor (or
  `EcologicalData`) this building passively generates reports for each active
  season.
- **Storage contribution** — capacity added to a dedicated storage mechanic
  (e.g. Food Storage's stockpile capacity — see [Storage](04_buildings_and_economy.md#storage)). General working
  inventory is uncapped (see [Inventory](04_buildings_and_economy.md#inventory)) and has no storage-contribution
  property; this only applies to buildings implementing a deliberate,
  limited-capacity commitment mechanic.
- **Recovery capacity** — the number of settlers who can actively recover
  from an injury or infection at once (Medical Bay only so far: 1 base / 2
  upgraded — see [Medical Bay](04_buildings_and_economy.md#medical-bay) and Settlers & Exploration's [Injuries](05_settlers_and_exploration.md#injuries)). Distinct
  from the worker slot — recovering settlers aren't workers.

---

## TechAchievement Catalog

Every building tier, fabricated item, and drone state below carries a
static, design-authored `TechAchievement` value on a 0–4 scale, based on how
demanding its own prerequisites/inputs are:

- **0 — Base tier.** Buildable from run start with only the two universal
  construction materials (Lumber/Concrete — see [Building Schema](04_buildings_and_economy.md#building-schema); these
  replaced the old Matter resource and occupy its old role here) plus single
  common raw materials (Stone, Wood, basic farm output). No deposit
  discovery, no building prerequisite, no upgrade needed.
- **1 — Processed, or hard-gated by a required deposit.** Needs a refined
  resource (Silicon, Fabric, Leather, smelted Iron/Copper) as an input, or
  the building itself cannot exist without a discovered deposit (Mine,
  Quarry, Rare Metal Extractor, Geothermal Generator, Fuel-based Generator's
  Fossil Fuel tier).
- **2 — Advanced-input or first upgrade tier.** Needs High-Tech Components,
  or is itself an "Upgraded" building tier (or the fresh-fabrication result
  of one), or is a passive bonus automatically triggered by a deposit on an
  otherwise freely-buildable structure (Deep Well).
- **3 — Compound-advanced or gate-locked.** Needs multiple advanced inputs
  together (a rare metal plus High-Tech Components, or two Tier-2 items at
  once), or is gated behind a Confidence threshold rather than materials
  (Medical Bay's Biological Countermeasures tier), or requires a
  further-Upgraded building tier beyond the first.
- **4 — Rarest tier.** The catalog's actual ceiling items.

**Counting rule** (see Win/Lose Conditions' [SEED Factions](06_planets_and_scoring.md#seed-factions) for the full
Development Bloc formula): each distinct catalog entry below contributes
its tier value **once**, the first time it's ever reached during a run — not
once per unit produced, not once per copy built. Producing 10 Iron and
later consuming all of it still contributes Iron's tier (1); building two
fully-upgraded Scanner Stations still contributes 4, not 8. A building's
successive tiers, and a drone's successive Basic/Advanced/Hardened states,
are each their own distinct entry.

**Basic Resource Production**

| Entry | Tier |
|---|---|
| Settlement Base (base) | 0 |
| Settlement Base II (upgraded) | 2 |
| Solar Array (base) | 0 |
| Solar Array (upgraded) | 2 |
| Geothermal Generator | 1 |
| Geothermal Generator (upgraded) | 2 |
| Fuel-based Generator (Wood) | 0 |
| Fuel-based Generator (Fossil Fuel tier) | 1 |

**Farm/Production**

| Entry | Tier |
|---|---|
| Grain Field / Fruit Orchard / Dairy Pasture / Poultry Coop / Sheep Pasture / Fiber Field / Timber Grove (base, each) | 0 |
| Same seven, upgraded tier (each) | 2 |
| Trapping | 0 |
| Hybridization (per-planet signature discovery) | 3 |
| Hybridization (meteorite-fragment, planet-independent) | 4 |

**Deposit Discovery**

| Entry | Tier |
|---|---|
| Mine | 1 |
| Quarry | 1 |
| Rare Metal Extractor | 1 |

**Water**

| Entry | Tier |
|---|---|
| Water Processing Plant (base) | 0 |
| Water Processing Plant (Reclamation) | 2 |
| Water Condenser / Ice Melter / Cistern (each) | 0 |
| Well (base) | 0 |
| Deep Well | 2 |

**Scanner Station / Research Lab**

| Entry | Tier |
|---|---|
| Scanner Station (base) | 3 |
| Scanner Station (upgrade tier 2, unstaffed) | 3 |
| Scanner Station (upgrade tier 3, all-modes) | 4 |
| Research Lab | 2 |

**Food/Meal Conversion**

| Entry | Tier |
|---|---|
| Kitchen (base) | 0 |
| Kitchen (upgraded, combo recipes) | 2 |
| Gourmet tier (per settler-invented recipe) | 2 |
| Local Delicacy | 3 |
| Ration Press | 0 |

*Gourmet tier and Local Delicacy are gated by settler mastery and alliance
state rather than materials, so they don't derive from the rubric's own
input-cost logic the way everything else here does — their placement is a
deliberate placeholder pending balancing, same as the numeric TBDs
elsewhere in this catalog.*

**Fabrication — buildings**

| Entry | Tier |
|---|---|
| Robotics Assembly (base) | 1 |
| Robotics Assembly (upgraded) | 2 |
| Stone Processing I | 0 |
| Stone Processing II | 2 |
| Smelter | 0 |
| Textile Workshop | 0 |
| Tinkerer's Workshop | 2 |
| Sawmill | 0 |
| Carpenter's Shop | 2 |

**Fabrication — items**

| Entry | Tier |
|---|---|
| Concrete / Lumber (each) | 0 |
| Iron / Copper (smelted, each) | 1 |
| Silicon | 2 |
| Glass | 2 |
| Biological Lab Materials | 2 |
| Fabric | 1 |
| Leather | 1 |
| Leather Boots | 2 |
| Leather Backpack | 1 |
| Fine Furniture | 2 |
| Ornamental/Decorative Items | 2 |
| Wooden Plow | 2 |
| High-Tech Components | 2 |
| High-Resolution Screens | 2 |
| Portable High-Powered Scanning Equipment | 3 |
| Temperature-Resistant Gear | 3 |
| Diplomatic Gear | 3 |
| Armed Expedition Kit | 3 |
| Overwhelming Force Package | 4 |

**Drones** (see [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly) for the Basic/Advance/Harden
fabrication-vs-upgrade structure — each state below is its own distinct
catalog entry)

| Entry | Tier |
|---|---|
| Construction Robot | 1 |
| All-Purpose Drone, Basic | 1 |
| All-Purpose Drone, Advanced | 2 |
| All-Purpose Drone, Basic + Hardened | 2 |
| All-Purpose Drone, Advanced + Hardened | 3 |
| Specialized Drone, Basic | 2 |
| Specialized Drone, Advanced | 3 |
| Specialized Drone, Basic + Hardened | 3 |
| Specialized Drone, Advanced + Hardened | 4 |

**Protection**

| Entry | Tier |
|---|---|
| Weather Shield (base) | 1 |
| Weather Shield (upgraded) | 2 |
| Row Shield | 1 |
| Medical Bay (base) | 2 |
| Medical Bay (Biological Countermeasures) | 3 |
| PPE | 2 |
| Emergency Medical Kit | 1 |

**Storage**

| Entry | Tier |
|---|---|
| Food Storage (base) | 0 |
| Food Storage (upgraded) | 2 |

**Habitation**

| Entry | Tier |
|---|---|
| Crew Quarters | 1 |
| Luxury Living Quarters | 3 |

*(The Settlement Base's Habitation role carries no separate
`TechAchievement` entry — the building is scored under Basic Resource
Production, above, as the starting Solar Array it also is.)*

---

## Basic Resource Production

Every run begins with one **[Settlement Base](04_buildings_and_economy.md#settlement-base)** — the run's first
Solar Array, a variant that also houses the crew's quarters — alongside the
other starting buildings (Water Processing Plant, Sawmill, Stone Processing
— see [Water](04_buildings_and_economy.md#water) and [Fabrication](04_buildings_and_economy.md#fabrication)). How these four land on the grid is
Core Loop & Grid's [Starting Settlement Placement](03_core_loop_and_grid.md#starting-settlement-placement). Plain Solar
Arrays can be built and upgraded thereafter (more copies), each consuming a
grid slot, preserving the grid's limited-slots opportunity cost.

### Solar Array
- Category: Basic Resource Production | Staffing:
  Unstaffed
- Input: none | Output: Energy per season (rate varies by planet type)
- Production cap: N/A (unstaffed)
- Construction cost: modest Energy + Lumber/Concrete (exact numbers TBD,
  deferred to a balancing pass)
- `TechAchievement`: 0 (base) / 2 (upgraded) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) |
  Repeatable: yes | Upgrade path: yes — higher tiers
  produce more Energy; a late tier is a natural place to pay off the Crash
  Research Era's controlled-fusion lore (e.g. eventually becoming a Fusion
  Generator — `TechAchievement` TBD once that tier is actually designed)
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

### Settlement Base

The one starting Solar Array, a special variant that **also houses the
crew's quarters**. Apart from the quarters, it behaves exactly like a
[Solar Array](04_buildings_and_economy.md#solar-array): same planet-type Energy rate, unstaffed, one grid
slot, robot-relocatable.

- Category: Basic Resource Production (the quarters function also places it
  in [Habitation](04_buildings_and_economy.md#habitation)) | Staffing: Unstaffed
- Input: none | Output: Energy per season (as Solar Array) + baseline
  crew quarters (see [Habitation](04_buildings_and_economy.md#habitation) — the crew get neither the "Poor
  Sleep" debuff nor a "Good/Great Sleep" buff while a Settlement Base or
  any dedicated quarters stands)
- Grid slot count: 1 (the quarters are spartan and add no footprint)
- Construction cost: N/A at run start (it arrives with the expedition);
  not independently buildable
- `TechAchievement`: 0 (base) / 2 (**Settlement Base II**, upgraded) — see
  [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)
- Repeatable: **no** — exactly one per run; further Solar Arrays are plain
- Upgrade path: yes — upgrading raises the Energy tier the same way a Solar
  Array upgrade does, and the result stays a distinct **Settlement Base
  II** (it keeps the quarters and stays separate from an upgraded plain
  Solar Array)
- **If destroyed** (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)):
  the run does **not** end. Its Energy output is lost and it stops
  providing quarters — if it was the only source of quarters, the whole
  crew takes the "Poor Sleep" debuff (see [Habitation](04_buildings_and_economy.md#habitation)). It is a
  one-off: once destroyed it cannot be rebuilt, and the player recovers by
  building a plain Solar Array for the Energy and a [Crew Quarters](04_buildings_and_economy.md#crew-quarters)
  for the sleep.
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

### Geothermal Generator
*(Volcanic's Alternative Energy building — see `DESIGN_TODO.md`)*
- Category: Basic Resource Production | Staffing: **Unstaffed** — no more
  active than Solar Array; a geothermal plant is heat driving a turbine, not
  ongoing labor like tending a field or hauling water. The real tradeoff
  against Solar Array isn't a labor cost, it's **scarcity**: Solar Array is
  repeatable anywhere on any planet, uncapped, while this building only
  exists where a Thermal Vent does — rare, Volcanic-exclusive, and gated
  behind the same exploration-survey investment as any other deposit (see
  [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery)).
- Built directly on a discovered Thermal Vent deposit slot (any depth tier),
  same placement pattern as Mine/Quarry/Well.
- Input: none | Output: Energy per season, at a rate meaningfully above
  Solar Array's Volcanic-tier rate (exact numbers
  TBD, deferred to a balancing pass) — this is what actually lets a Volcanic
  run offset Weather Shield's temperature-driven Energy cost (see Planets &
  Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)), the original motivation for this
  building.
- Production cap: N/A (unstaffed)
- Construction cost: Lumber/Concrete (ratio TBD) + Iron
- `TechAchievement`: 1 (base) / 2 (upgraded) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) |
  Repeatable: yes (naturally capped by how many
  Thermal Vents exist on the site, not by player choice — same pattern as
  Mine/Quarry) | Upgrade path: yes — higher tiers produce more Energy
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

*(A third [Basic Resource Production](04_buildings_and_economy.md#basic-resource-production) building, [Fuel-based Generator](04_buildings_and_economy.md#fuel-based-generator), lives
under [Fuel](04_buildings_and_economy.md#fuel) below rather than here, since it's most legible alongside Forest
tiles and Clear-Cutting — its category is still Basic Resource Production.)*

---

## Farm/Production

Numbers below are a **first-pass illustrative draft**, not balanced — following
"numbers stay small," exact values are meant to be tuned empirically via
playtesting later, not over-engineered now. All buildings in this section:
Repeatable: yes, Upgrade path: yes (higher tiers reduce duration and/or raise
the effort-stacking production cap), `TechAchievement` 0 at base tier / 2
upgraded (see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)). **Water**: the four animal-based
buildings ([Dairy Pasture](04_buildings_and_economy.md#dairy-pasture), [Poultry Coop](04_buildings_and_economy.md#poultry-coop), [Sheep Pasture](04_buildings_and_economy.md#sheep-pasture)) draw a flat
amount per cycle (exact amount and insufficient-Water behavior still TBD —
see `DESIGN_TODO.md`'s Water resource open threads); the four plant-crop
buildings instead draw Water only during specific transitions of their own
persistent per-site state (see [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model), below) —
never a flat per-cycle amount. Every building in this section stays a
**single 1-tile footprint** with a correspondingly fixed **1-worker cap**
(per Core Loop & Grid's Assignment "one worker, one slot" default) —
upgrades here only ever reduce duration, never raise the effort-stacking
cap, unlike the general per-building upgrade note above.

### Plant-Crop Production Model

The four plant-crop buildings — [Grain Field](04_buildings_and_economy.md#grain-field), [Fruit Orchard](04_buildings_and_economy.md#fruit-orchard), [Fiber Field](04_buildings_and_economy.md#fiber-field),
[Timber Grove](04_buildings_and_economy.md#timber-grove) — don't run the single continuous-rate cycle every other
production site in this design uses (per Core Loop & Grid's Production
Model). Instead, each tracks a **persistent per-site state** that advances
through a named sequence of timed transitions, and — deliberately — **each
building's sequence is its own shape**, not a shared template with
different numbers, so the four don't read as color-tinted versions of one
building: Grain Field and Fiber Field replant from scratch every harvest
(an annual-crop shape); Fruit Orchard establishes once and then fruits
repeatedly forever after (a tree-crop shape); Timber Grove establishes once
and then harvests a self-renewing batch on a fixed interval decoupled from
any single tree's maturity (a managed-woodlot shape). All four: **Staffing:
Staffed** — a worker/drone is needed to progress every short, active
transition (below), though not the passive/biological-wait ones. Per-building
detail is below; what's shared across all four:

- **Cross-season carryover follows one rule.** A transition is either a
  **short, worker-active** step (a settler or drone physically plowing,
  planting, or harvesting) or a **long, passive/biological-wait** step (the
  crop growing or ripening on its own). If Mid-Sim ends mid-transition: a
  worker-active transition **restarts from zero** next season (assuming a
  worker is still assigned) — no partial credit for a half-finished plow or
  harvest; a passive/biological-wait transition **pauses and resumes with
  its progress held** — a crop 20s into a 30s growth doesn't forget those
  20s just because a season boundary fell in the middle.
- **Water is drawn during every passive/biological-wait transition, and
  only those** — see Water reservation & shortfall, below.
- **Alien Soil** applies to the same set of transitions: the four plant-crop
  buildings carry a standing growth-rate penalty on every passive/
  biological-wait transition (illustrative -30%, TBD) — Earth crops aren't
  naturally suited to a foreign planet's soil. Removed for any season
  Fertilizer is available (see [Resources](04_buildings_and_economy.md#resources)) — consumed automatically, no
  manual action needed, same low-friction spirit as Water's automatic
  draw. Permanently removed, with no further Fertilizer need at all, once a
  plant type has been hybridized (see [Hybridization](04_buildings_and_economy.md#hybridization), below).
- **Worker effects on the short, active transitions** follow the general
  Effort-stacking model (see Core Loop & Grid's [Assignment](03_core_loop_and_grid.md#assignment)), same as
  ordinary production. **Every transition away from a building's
  `unprepared` state is additionally, drastically sped up** by a **Wooden
  Plow** (a passive settlement-wide stock check, not consumed — see
  [Fabrication](04_buildings_and_economy.md#fabrication)) for a settler or an All-Purpose Drone, **or inherently, with
  no Plow needed, for a Farming-Specialized Drone** (its body is built for
  the task directly — this stacks on top of its Effort multiplier, it
  doesn't substitute for it; see [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)).
- Each transition is its own segment of the production progress overlay
  (see Core Loop & Grid's Season Structure) — exact color/icon mapping per
  building is an open Art Design item (see `DESIGN_TODO.md`).

**Water reservation & shortfall.** Water, like Energy, is tracked as a live **Income rate** (see [Water](04_buildings_and_economy.md#water) below),
not an accumulated stock — there is no shared balance to draw a lump sum
from. When a plant-crop building's passive/biological-wait transition is
ready to start, it requests a consumption-rate reservation sized for its
crop, entering one **settlement-wide pool** shared across every
currently-requesting transition (and, once designed, the animal-based
buildings' draw — see `DESIGN_TODO.md`'s Water resource open threads).

- **Resolution mirrors Energy's random un-powering** (see [Resources](04_buildings_and_economy.md#resources)),
  applied to Water instead: when total requested reservations exceed
  available Water Income, the shortfall is resolved by **randomly**
  selecting enough requests to deny until the total fits back under
  Income — recomputed to a fixed point on every event that changes the
  picture (a request starting/ending, Water Income changing). Deliberately
  random, not by a queue position or build order, so which specific site
  goes dry is never something a player can optimize — the same "keep total
  supply ahead of total demand, not the service order" intent as before,
  now delivered by the same mechanism Energy uses rather than a separate
  one.
- **A denied transition pauses** — holds its progress, no loss — and
  re-enters the pool at the next recompute. Once granted, a reservation
  holds for the transition's whole duration and releases back to available
  capacity the instant it ends.
- A manual **"turn Water off at this site"** toggle exists, on the same
  footing as Energy's active/inactive toggle: an available mitigation, not
  something else in the design is built to expect routine use of.
- **Legibility.** A denied site surfaces in the simulation log with cause,
  the same as an Energy un-powering.

### Grain Field

States: `unprepared → plowed → growing → harvestable → unprepared → …` —
returns to `unprepared` and replants every cycle.

| Transition | Base duration | Progresses without a worker? | Draws Water? | At season boundary |
|---|---|---|---|---|
| `unprepared → plowed` | 2s | No (Effort-driven; Wooden Plow / Farming-Specialized Drone bonus applies) | No | Restarts |
| `plowed → growing` | 1s | No (Effort-driven) | No | Restarts |
| `growing → harvestable` | 3s | Yes (Alien Soil/Hybridization-driven) | Yes | Pauses, progress held |
| `harvestable → unprepared` | 1s | No (Effort-driven) | No | Restarts |

**1 Grain is added to inventory at the completion of `harvestable →
unprepared`.** Full cycle at base rates: 7s (vs. the prior flat 3s
`production_time` — this redesign trades a fast flat cycle for a slower,
distinct, multi-step one). Production cap: 1 (fixed, single tile).
Construction cost: Lumber/Concrete (ratio TBD).

### Fruit Orchard

States: one-time establishment `unprepared → planted → mature`, then a
**repeating loop, once mature, that never returns to `planted` or
`unprepared`**: `mature → fruiting → mature → …` — the tree is planted once
and fruits indefinitely after that.

| Transition | Base duration | Progresses without a worker? | Draws Water? | At season boundary |
|---|---|---|---|---|
| `unprepared → planted` | 1s | No (Effort-driven; Wooden Plow / Farming-Specialized Drone bonus applies) | No | Restarts |
| `planted → mature` | 30s | Yes | Yes | Pauses, progress held |
| `mature → fruiting` | `k` s, `k` ∈ {3, 4, 5} rerolled fresh every cycle | Yes | Yes | Pauses, progress held |
| `fruiting → mature` | 1s | No (Effort-driven) | No | Restarts |

**1 Fruit is added to inventory at the completion of `fruiting →
mature`.** One-time establishment: 31s. Steady state after that: 4–6s per
Fruit, depending on the `k` roll. Production cap: 1 (fixed, single tile).
Construction cost: Lumber/Concrete (ratio TBD).

### Dairy Pasture
- Staffing: Staffed | Input: Water | Output: 1 Milk per cycle,
  `production_time` 5s | Production cap: 1 (fixed, single tile) | Construction cost: Lumber/Concrete (ratio TBD)

### Poultry Coop
- Staffing: Staffed | Input: Water | Output: 1 Egg per cycle,
  `production_time` 3s | Production cap: 1 (fixed, single tile) | Construction cost: Lumber/Concrete (ratio TBD)

### Sheep Pasture
- Staffing: Staffed | Input: Water | Output: 1 Wool per cycle,
  `production_time` 5s | Production cap: 1 (fixed, single tile) | Construction cost: Lumber/Concrete (ratio TBD)

### Fiber Field

Same shape as [Grain Field](04_buildings_and_economy.md#grain-field): states `unprepared → plowed → growing →
harvestable → unprepared → …`, replanting every cycle.

| Transition | Base duration | Progresses without a worker? | Draws Water? | At season boundary |
|---|---|---|---|---|
| `unprepared → plowed` | 2s | No (Effort-driven; Wooden Plow / Farming-Specialized Drone bonus applies) | No | Restarts |
| `plowed → growing` | 1s | No (Effort-driven) | No | Restarts |
| `growing → harvestable` | 4s | Yes (Alien Soil/Hybridization-driven) | Yes | Pauses, progress held |
| `harvestable → unprepared` | 1s | No (Effort-driven) | No | Restarts |

**1 Fiber/Cotton is added to inventory at the completion of `harvestable →
unprepared`.** Full cycle at base rates: 8s (vs. the prior flat 3s
`production_time`). Production cap: 1 (fixed, single tile). Construction
cost: Lumber/Concrete (ratio TBD).

### Timber Grove

States: one-time establishment `unprepared → growing → cycle-harvestable`,
then a **self-loop** — `cycle-harvestable → cycle-harvestable → …` — that
never returns to `growing` or `unprepared`: a managed woodlot, harvested on
a fixed interval decoupled from any single tree's maturity.

| Transition | Base duration | Progresses without a worker? | Draws Water? | At season boundary |
|---|---|---|---|---|
| `unprepared → growing` | 1s | No (Effort-driven; Wooden Plow / Farming-Specialized Drone bonus applies) | No | Restarts |
| `growing → cycle-harvestable` | 15s | Yes | Yes | Pauses, progress held |
| `cycle-harvestable → cycle-harvestable` (self-loop) | 5s | Yes, **to progress** — see completion gate below | Yes | Pauses/holds, including a held-at-100% state |

**Completion gate — unique to this self-loop.** Every other passive
transition above only ever *progresses* without a worker. This one *also*
produces the building's output at completion, so it needs a rule the others
don't: its timer can reach 100% with no worker assigned (the batch keeps
maturing on its own), but the loop only actually **completes** — adding
**1 Wood** to inventory and restarting the 5s timer — the next time a
worker is present. A Timber Grove held at 100%-pending-worker carries that
exact state across a season boundary, same as any other in-progress passive
transition. One-time establishment: 16s. Steady state after that: 5s per
Wood, while staffed. Production cap: 1 (fixed, single tile). Construction
cost: Lumber/Concrete (ratio TBD).

### Trapping

Not a building — traps set on a tile for the season are just that, no
persistent structure involved. **Trapping** is a Standing Assignment (see
[Settlers](05_settlers_and_exploration.md#settlers) & Exploration), production-speed-based like a building rather than
a single lump-sum result: assign a settler to one tile, and they yield
**Pelt** through repeating production cycles across the season's Mid-Sim
window (rate TBD) — eligible for Storied's production-speed bonus the same
way a Production building assignment is. Fully repeatable indefinitely on
the same tile — unlike Clear-Cutting, wildlife is a renewable resource, not
a bounded one-time harvest, as long as the local habitat persists.

Yield scales two ways:
- **Planet-type biological richness** — reusing the same `TrueRisk(Bio-hazard)`
  correlation already established for Fossil Fuel frequency, rather than a
  new per-planet dial: Verdant (richest biosphere) yields the most, Volcanic/
  Frozen (suppressed biological complexity) the least, Arid/Desert in
  between.
- **Whether the tile currently has Forest present** (see [Fuel](04_buildings_and_economy.md#fuel)) — unforested
  or already-clear-cut land is less habitable for prey animals, so a
  forested tile yields more than a bare one. This creates a direct,
  legible tension with Clear-Cutting: harvesting a Forest tile's Wood
  permanently reduces that same tile's future trapping potential too, since
  clear-cutting removes the habitat.

No Rations, no risk — same as any Standing Assignment. Pelt stays one
resource everywhere (see [Resources](04_buildings_and_economy.md#resources)), consistent with not exploding the
catalog per planet type, though its flavor name/appearance could vary
cosmetically by planet with zero mechanical effect, the same pattern
already used for Kitchen's combo-meal flavor-name pools.

### Hybridization

An exploration discovery (Site Reveal outcome — see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration)
unlocks the ability to research **one specific plant-crop building's**
hybridization at a Research Lab (see Utilities) — a single discovery targets
a single building type (e.g. a Verdant find might unlock Grain Field's
hybridization specifically, not all four plant buildings at once). Completing
that research at the Lab **permanently changes every instance of that
building type, existing and future, for the rest of the run** — no
per-instance Construction Robot upgrade needed, since crop buildings replant
every cycle anyway; there's no physical structure to retrofit, just a
different seed to plant next time.

Every hybridized building gets two distinct benefits:
- **Universal**: permanent immunity to the Alien Soil penalty (above) — no
  Fertilizer ever needed again for that building type. Not really a bonus
  stacked on top so much as a direct consequence of being adapted to local
  soil in the first place.
- **Planet-specific signature benefit** — tied to whatever defines that
  planet's strategic identity, so it's never arbitrary flavor:
  - **Arid/Desert** — reduced (or zero) Water requirement (native flora
    already solved local scarcity).
  - **Ice / Volcanic** — immune to Temperature Extremity's slowed/stopped
    production consequence (see Planets & Scoring's In-Simulation Hazard
    Events) — produces exactly as if fully shielded, no Weather/Row Shield
    funding needed for this specific building.
  - **Verdant** — higher yield (production cap and/or faster
    `production_time`) — an adapted species out-competing for abundant
    resources.

Exact building↔discovery pairings (which specific find unlocks which
specific building) are content-authoring-pass detail, same as the rest of
Exploration Tasks' unwritten flavor content.

---

## Deposit Discovery

Ore, Stone, rare-metal, and **aquifer** (see [Water](04_buildings_and_economy.md#water)) deposits are hidden by
default — most are underground, and the player must actively discover them
before they can be mined/tapped. **All deposit locations across the grid are
determined at run start** (world generation), independent of when the player
actually discovers them — discovery only reveals what's already there, it
never generates new deposits. Aquifers are binary (present/not-present) and
single-tile, exactly like the other deposit types — no varying depths.

**Thermal Vents** (see [Geothermal Generator](04_buildings_and_economy.md#geothermal-generator), under Basic Resource
Production) are a fifth deposit type, binary and single-tile like aquifers,
but with a new kind of restriction the other four don't have: they're
**Volcanic-exclusive** — guaranteed present (at least one) on Volcanic at
world generation, absent entirely on every other planet type, rather than
merely varying in frequency across planets the way Ore/Stone/rare-metal/
aquifer do. Skews toward Mid-depth/Deep tiers, same rarity flavor as
rare-metal deposits.

**Fossil Fuel** (see [Fuel-based Generator](04_buildings_and_economy.md#fuel-based-generator), under [Fuel](04_buildings_and_economy.md#fuel)) is a sixth deposit
type, hidden and skewing toward Mid-depth/Deep tiers like rare-metal and
Thermal Vents — but unlike Thermal Vents' strict Volcanic-exclusivity, its
frequency simply varies by planet type, reusing an existing correlation
rather than adding a new one: expedition-feasible planets all have *some*
biological history capable of laying down fossil deposits, so frequency
scales with each planet type's existing `TrueRisk(Bio-hazard)` value (see
Hazard Priors) as a proxy for historical biological richness — Verdant
(richest biosphere) has the most, Volcanic/Frozen (suppressed biological
complexity) have the least, Arid/Desert sits in between.

**Overlap.** A tile can hold more than one deposit/feature type at once,
which is exactly what makes relocating a deposit-gated building sometimes
worth it (see Core Loop & Grid's [Construction](03_core_loop_and_grid.md#construction)). The rules:
- **Ore, Stone, and rare-metal are mutually exclusive with each other** — a
  tile has at most one of these three "what kind of rock is here"
  characterizations.
- **Aquifer, Thermal Vent, and Fossil Fuel can each independently coexist
  with each other and with the tile's one mineral type (if any)** — they're
  physically distinct resources (water, heat, hydrocarbons), not competing
  for the same "rock type" slot. (Aquifer + Thermal Vent is just a hot
  spring.) Planet-type gating still does most of the work limiting how
  often these actually stack — Thermal Vent stays Volcanic-exclusive,
  Fossil Fuel frequency still scales with `TrueRisk(Bio-hazard)` — so
  Thermal Vent + Fossil Fuel on the same tile would be rare in practice
  even without an explicit rule against it.
- **Forest can coexist with any hidden deposit/feature**, since a visible
  surface feature and something buried underneath aren't in conflict — but
  **Forest is mutually exclusive with Surface-tier deposits specifically**,
  since a tile can't simultaneously present as a visible forest and a
  visible ore outcrop at world-gen; only one visible characterization per
  tile.
- **Discovery resolves per (tile, depth) pair, not per tile alone and not
  per type.** Revealing a tile's Mid-depth status doesn't also reveal its
  Deep status (those need their own separate Deep Survey) — but revealing
  either one reveals every *type* present at that depth on that tile
  together, with no separate per-type reveal roll.

This is what actually delivers the "force a real choice" goal: a tile with
both Ore and an Aquifer forces a Mine-vs-Well decision, since only one
building fits the slot — the other resource sits inaccessible unless the
player later relocates the built structure elsewhere. A Forest tile with a
hidden deposit underneath doesn't force that same choice, since
Clear-Cutting isn't a building and doesn't consume the tile — harvesting
the Wood doesn't cost later access to whatever's underneath.

**Three depth tiers:**
- **Surface** — visible from run start, immediately buildable with no discovery
  needed. **Guarantee**: every run has at least one Stone, Iron, or Copper
  deposit at Surface tier, so the player always has an immediate mining option.
- **Mid-depth** — hidden; found via Basic Deposit Survey (or Deep Survey,
  on tiles it also covers).
- **Deep** — hidden; found only via Deep Survey or a Scanner Station's Deposit
  Scanning mode. Skews toward rare-metal deposits specifically, not just more
  Iron/Copper/Stone.

**Basic Deposit Survey** (Standing Assignment — see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration)
— available from Season 1, every season, not pool-limited. Requires modest
basic tools (small resource cost, TBD). At assignment time, the player
selects a **rectangular region of tiles** (size TBD, a balancing number) to
survey — not the whole farm. On success, within that rectangle: guarantees
1 undiscovered Mid-depth deposit revealed (if any exist in the rectangle),
then independently a 0.6 chance **per remaining** undiscovered Mid-depth
deposit in the rectangle. As a side effect, it also **flags every tile in
the rectangle that has a Deep-tier feature present** — not what it is, just
that something's there — marking those tiles **deep-survey-eligible**.
Repeatable, on a new (or overlapping) rectangle each time, which is how a
player gradually covers the farm across multiple seasons.

**Deep Survey** (Standing Assignment) — requires **Portable High-Powered
Scanning Equipment** (reusing the existing Tinkerer's Workshop item rather
than inventing a new one) to perform at all, regardless of whether any
tiles are currently deep-survey-eligible. Unlike Basic Survey, there's no
rectangle to choose: it automatically targets **every tile flagged
deep-survey-eligible so far**, across however many prior Basic Surveys
contributed to that set — which also means it's simply meaningless (nothing
to target) until at least one tile has been flagged, and meaningful the
moment one has, with no separate unlock gate to track. On success, across
that flagged set: guarantees 1 undiscovered Mid-depth deposit revealed (if
any remain there) **and** 1 undiscovered Deep deposit revealed (if any
exist there) — two independent guarantees — then independently a 0.9 chance
per remaining undiscovered Mid-depth deposit and a 0.5 chance per remaining
undiscovered Deep deposit, both scoped to the flagged set. **Repeatable** —
a single attempt likely won't reveal everything at the 0.5 Deep-tier rate,
so doing it again has real value; being a Standing Assignment, it's simply
available again next season with no reroll or pool mechanics involved.

**Scanner Station's Deposit Scanning mode is entirely unaffected by any of
this** — no rectangle selection, no eligibility flagging, it keeps its
existing any-depth-tier, anywhere-on-the-grid probabilistic reveal (see
[Scanner Station](04_buildings_and_economy.md#scanner-station)). The rectangle/flagging pattern is specific to
settler-performed surveys, not building-based scanning.

### Mine
- Built directly on an Iron/Copper Ore deposit slot (any depth tier, once
  discovered) | Staffing: Staffed | Input: none | Output: 1 unit of Iron Ore
  and/or Copper Ore per cycle, drawn independently per unit from the
  deposit's percentage mix, `production_time` 4s | Production cap: 1 (base) |
  Construction cost: Lumber/Concrete (ratio TBD) + 1 Stone

### Quarry
- Built directly on a Stone deposit slot (any depth tier, once discovered) |
  Staffing: Staffed | Input: none | Output: 1 Stone per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: a
  **small amount of Lumber only** — deliberately cheap, since this is the
  one building that has to be reachable before Stone (and therefore
  Concrete) exists anywhere in the settlement's economy; see Fabrication's
  Sawmill/Stone Processing for the full bootstrapping chain this closes.

### Rare Metal Extractor
- Built directly on a rare-metal deposit slot (any depth tier, once
  discovered) | Staffing: Staffed | Input: none | Output: 1 rare metal per
  cycle, `production_time` 8s (slower, reflecting rarity) | Production cap: 1
  (base) | Construction cost: Lumber/Concrete (ratio TBD) + 2 Stone

---

## Fuel

A deliberately *not clean* third Energy option, alongside Solar Array and
Geothermal Generator (see [Basic Resource Production](04_buildings_and_economy.md#basic-resource-production)) — cheap and immediately
available from run start, no unlock needed, but genuinely resource-limited
and, unlike either of those two, carries a real ongoing Stewardship cost
(see Win/Lose Conditions' [SEED Factions](06_planets_and_scoring.md#seed-factions), `EmissionsRestraint`) for as long
as it's used.

**Forest tiles** are a visible-from-start terrain feature (not a hidden
Deposit Discovery type — a forest is visually obvious, no survey needed),
with count and density varying by planet type and site, shown at Farm Site
Selection (see Core Loop & Grid) alongside Surface deposits and Average
Temperature as a known feature. Each Forest tile holds a bounded quantity of
**Wood** — the same "high-yield, bounded, depletes with use" shape already
established for some Ore/Stone deposits (see [Resources](04_buildings_and_economy.md#resources)) — that does not
regenerate within a run once harvested. This is the *same* Wood Timber
Grove produces on an ongoing, renewable basis (see [Farm/Production](04_buildings_and_economy.md#farmproduction) and
[Resources](04_buildings_and_economy.md#resources)) — one resource, two sources with different sustainability
profiles, not two separate items.

### Clear-Cutting
Not a building — a **Standing Assignment** (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration). No
grid slot, no construction cost, no staffing in the sticky sense.
- Production-speed-based, like a building, rather than a single lump-sum
  result: the player selects any number of individual Forest tiles for one
  assignment (drag-click marks every eligible tile within a rectangle and
  can only mark, never unmark; single-tile click toggles mark/unmark on one
  tile at a time), and the assigned settler works through them during
  Mid-Sim. How many get fully cleared by season end depends on the
  settler's speed (rate TBD) — eligible for Storied's production-speed
  bonus the same way a Production building assignment is. Each cleared
  tile yields **Wood** — a portion of that tile's bounded total, not the
  whole thing at once — and any tiles not finished by season end carry
  over if reassigned next season, continuing to draw the same tiles down
  until each is exhausted, at which point it's bare and no longer
  assignable — same end state as any depleted bounded deposit.
- Balancing target, not a hard rule: a season or two of assignments should
  bank enough Wood to run a base-tier Fuel-based Generator for a season or
  two before the next round of Clear-Cutting is needed.
- Every unit harvested this way counts toward `ExtractionRestraint` (see
  [SEED Factions](06_planets_and_scoring.md#seed-factions) in Win/Lose Conditions), unlike Timber Grove's output,
  which never does — the distinction lives at the point of production, not
  on the pooled Wood itself, which is fully fungible once in inventory.

### Fuel-based Generator
- Category: Basic Resource Production | Staffing: **Unstaffed**
- The catalog's one **Conditional** Energy Income source (see [Resources](04_buildings_and_economy.md#resources)'
  Energy Income/Consumption Rates) — contributes **zero** Income while
  inactive or out of fuel, unlike Solar Array and Geothermal Generator's
  constant Reliable contribution.
- **Planning-phase control**: the active/inactive toggle every building has,
  plus a **fuel limit** — the maximum Wood/Fossil Fuel it's allowed to
  consume that season, which is just a cycle `limit` on its production-queue
  step (see [Building Schema](04_buildings_and_economy.md#building-schema)'s "Production queue"), not a separate mechanism.
  During Mid-Sim, if active, it burns for a duration determined by that
  limit (or by however much fuel is actually available, whichever binds
  first) against its burn efficiency — it doesn't necessarily run the whole
  season. While actively burning, it
  contributes an **additional** Energy income rate on top of the constant-rate
  producers; once its fuel limit or supply is exhausted, that contribution
  drops to zero for the remainder of the season. Draws from the same pooled
  Wood used for fabrication (Carpenter's Shop, etc.) — burning it here is a
  real opportunity cost against those other uses, not a dedicated stockpile.
- Base tier burns **Wood** only, from either source — but see
  `EmissionsRestraint` below: burning is penalized regardless of whether
  the Wood came from sustainable Timber Grove output or non-sustainable
  Clear-Cutting output, since Emissions is about the act of burning, not
  the sustainability of the source (that's `ExtractionRestraint`'s job,
  already charged at the point of harvest for Clear-Cutting's share).
- Upgrade tier additionally unlocks burning **Fossil Fuel** (see Deposit
  Discovery) once discovered — same multi-recipe pattern used elsewhere in
  the catalog (player selects the active fuel type as a normal, reversible,
  sticky planning choice; see [Building Schema](04_buildings_and_economy.md#building-schema)). Fossil Fuel gives a
  meaningfully higher Energy return per unit than Wood, which is the entire
  point of the upgrade — but see `EmissionsRestraint` below for the
  corresponding cost.
- Construction cost: cheap, common materials only (Lumber/Concrete/Iron, no
  High-Tech Components) — deliberately no barrier to entry, in contrast to
  Geothermal Generator's deposit-gating. Upgrade cost: TBD.
- **No further upgrade path beyond the Fossil Fuel tier.** Solar Array
  scales toward a late-game Fusion Generator payoff and Geothermal is capped
  by Vent scarcity but stays clean; this building's ceiling is "burn a
  better fuel," never "become clean" — the mechanical shape of "easier and
  faster, but not sustainable," without needing to editorialize about it in
  the text.
- `TechAchievement`: 0 (base) / 1 (Fossil Fuel tier) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) |
  Repeatable: yes | Available from run start, no unlock needed — same
  footing as Solar Array, since it needs no exotic materials.

---

## Water

*(Category: Utilities — see [Building Categories](04_buildings_and_economy.md#building-categories) in [Resources](04_buildings_and_economy.md#resources))*

**Water is tracked as a live Income rate (Water/s), not an accumulated
stock** — the same shape as Energy (see Resources' Energy
Income/Consumption Rates). No inventory presence, nothing carried between
moments or across the season boundary, nothing to have "banked." Water
Condenser/Ice Melter/Cistern/Well's "Output: Water per cycle" figures
(below) are exactly this rate's contributing sources, the same way Solar
Array and Geothermal Generator contribute to Energy's Income.

**Settler consumption is deliberately *not* rate-tracked or
amount-measured at all — a single binary check, not a headcount-vs-quantity
comparison like nutrition's.** Resolved once per season at Post-Sim: **the
check fails, and every settler dies, only if the settlement had no
functioning Water collection building at any point in the season** — none
built, or the only one(s) destroyed and not replaced, or none with its
[Water Processing Plant](04_buildings_and_economy.md#water-processing-plant) prerequisite intact and a worker assigned.
It is a check on *infrastructure existence*, not on rate or power state: a
collection building that is merely **un-powered** by an Energy shortfall
still produces a minimal fail-safe trickle (see [Resources](04_buildings_and_economy.md#resources)' random
un-powering rule) — enough that settlers are never at risk from an Energy
shortfall, effectively nothing for production draws. So an Energy shortfall
can never trigger this; only losing the collection infrastructure outright
can. There is no partial or proportional
consequence, and settler need never competes with production's own Water
reservations (see Farm/Production's Water reservation & shortfall) for
capacity. (Since
there's no longer a settler-need figure to calibrate against, collection
rates and the plant-crop buildings' passive-transition draw amounts have no
shared numeric anchor between them anymore — each stays independently TBD, deferred to
balancing like every other first-pass number in this design, same as
before.) This is a deliberate departure from nutrition's Tier-1 model, not
a mirror of it —
Water's stakes are binary (functioning infrastructure or total collapse),
never gradated by exact quantity.

**No dedicated water-storage buildings** — superseded by the rate model
above; there was never an amount to store in the first place now.

**Water transport is deliberately unmodeled** — no pipes, irrigation, or
distribution system to design. Collection buildings and consumption sites
don't need spatial adjacency; the player can imagine whatever transportation
mechanism they like, with no design commitment either way — consistent with
Energy also never needing an explained distribution system. (The plant-crop
buildings' Water reservation pool, see Farm/Production's [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model),
is a **resource-allocation** mechanic — deciding which reservations get
served when Income is scarce — not a spatial/transport one; it doesn't
reopen this decision.)

**All collection buildings require a [Water Processing Plant](04_buildings_and_economy.md#water-processing-plant) to function at
all** — see below. No separate "Raw Water" intermediate resource; the Plant's
mere existence is a prerequisite gate, not a conversion step.

Water Condenser, Ice Melter, and Cistern each: `TechAchievement` 0 (see
[TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)) — Lumber/Concrete only, no deposit gate. Well: `TechAchievement` 0
base / 2 once it automatically becomes a Deep Well (below).

### Water Processing Plant
- A **starting building**, present from run start like Solar Array, Sawmill,
  and Stone Processing I — not something the player constructs. (Once a demolish-building
  mechanic exists — not yet designed — rebuilding a demolished Processing
  Plant via normal construction should become possible; flagged as a forward
  dependency, not resolved now.)
- Base tier is mechanically almost inert — no production conversion,
  Preparedness contribution, or data-gathering of its own. Its only function
  is being the required prerequisite that lets collection buildings actually
  produce Water. Still occupies a real grid slot.
- Upgrade tier unlocks **Reclamation** — a settlement-wide reduction
  (illustrative -20%, TBD, deferred to balancing) applied to net Water
  consumption-rate demand, folded directly into this building rather than
  being a separate structure or item (structurally similar to Vaccine
  Production's one-time-unlock shape, but gated by a tech/resource
  prerequisite rather than a data-confidence threshold). **Resolved gate**:
  the upgrade's construction cost includes **High-Tech Components**
  alongside the usual Lumber/Concrete — the same advanced-tech gate
  material already used elsewhere (e.g. Scanner Station's construction
  cost), reused rather than inventing a new resource, and a fitting
  "water-recycling tech" theme. **Note**: since settler Water shortfall is
  now a binary "any production at all" check rather than a
  headcount-vs-quantity comparison (see Water above), Reclamation's
  consumption-rate reduction has no bearing on that check at all — its
  real, felt benefit is entirely on the production side, easing pressure on
  the plant-crop Water reservation pool (see Farm/Production's [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model))
  — fewer denials, less time spent paused. A quality-of-life upgrade for
  farming throughput, not a settler-safety one.
- `TechAchievement`: 0 (base) / 2 (Reclamation tier) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)

### Water Condenser
- Staffing: Staffed | Input: none | Output: Water per cycle (rate TBD) |
  Draws water from air/humidity. Best on Volcanic; Verdant has humidity too
  but easier direct liquid-water access (Cistern) makes condensing
  non-optimal there; Ice and Arid/Desert are too low-humidity to be
  effective.
- Construction cost: Lumber/Concrete (ratio TBD).

### Ice Melter
- Staffing: Staffed | Input: none | Output: Water per cycle (rate TBD) |
  Melts surface ice/snow. Exclusive to Frozen planets — the direct
  counterpart to Water Condenser's Volcanic specialization.
- Construction cost: Lumber/Concrete (ratio TBD).

### Cistern
- Staffing: Staffed | Input: none | Output: Water per cycle (rate TBD) |
  Passive rainfall collection. Best on planets with regular rainfall
  (Verdant and similar) — the "finding water is easy here" mechanism for
  hospitable planets.
- Construction cost: Lumber/Concrete (ratio TBD).

### Well
- Staffing: Staffed | Input: none | Output: Water per cycle, **relatively
  low rate** | Buildable on any tile.
- Built on a tile with a **detected aquifer** (see [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery)),
  automatically becomes a **Deep Well** — same building, higher production
  rate, no separate build choice or upgrade action. The "deepening" is a
  passive consequence of the tile's property, not a player decision beyond
  choosing where to build.
- Construction cost: Lumber/Concrete (ratio TBD). All four Water
  collection buildings deliberately stay in this same low-barrier
  register — Water is essential enough that gating collection behind
  demanding materials would just create an early-run bottleneck, not a
  meaningful choice.

---

## Scanner Station

*(consolidates the previously-separate "Weather Monitoring Station" and
"Deposit Scanner" concepts into one building, per the same consolidation logic
already applied to Robotics Assembly)*

- Category: Utilities (see [Building Categories](04_buildings_and_economy.md#building-categories) in [Resources](04_buildings_and_economy.md#resources))
- Construction cost: Stone + Iron + Copper + High-Tech Components +
  High-Resolution Screens — a real gate, requiring Tinkerer's Workshop to
  have already produced both before Scanner Station is reachable
- Base tier: Staffed. Uses the multi-recipe pattern (player selects one active
  mode, no resource inputs beyond staffing itself — per the Building Schema's
  note that Input may be empty and Output may not be a trackable resource
  item):
  - **Weather Sensing** — generates Storm Severity/Frequency and Temperature
    Extremity reports simultaneously each active season (see [Exoplanet Types](06_planets_and_scoring.md#exoplanet-types)'
    Data-Gathering Mechanism)
  - **Deposit Scanning** — a chance **each active season** to reveal one
    random undiscovered deposit of **any depth tier**, always capable of
    detecting Deep deposits. Unlike the Basic/Deep Surveys above, **no
    guaranteed reveal** — purely probabilistic, and at **slightly lower**
    probabilities than the surveys (illustrative starting point: 0.4 for
    Mid-depth, 0.3 for Deep — TBD, deferred to balancing)
- **Upgrade tier 2**: becomes **unstaffed** (zero-effort) — still one active
  mode at a time.
- **Upgrade tier 3**: performs **all modes simultaneously** — no need to
  select, both Weather Sensing and Deposit Scanning run every active season.
  Since this tier is already unstaffed, simultaneous operation doesn't need
  Kitchen-style multiple grid slots/workers — it's a property of automation at
  this tier, not of staffing capacity, a distinct mechanism from Kitchen's
  worker-count-driven parallelism.
- `TechAchievement`: 3 (base and upgrade tier 2) / 4 (upgrade tier 3,
  all-modes) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) | Repeatable: yes
  (multiple Scanner Stations can exist, though diminishing value once deposits
  are discovered) | Upgrade path: yes, as described above
- **Upgrades may also reduce the Rations cost of manually rerolling the
  Exploration Tasks pool** (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration) — exact discount
  per tier TBD, but the connection is real: better local sensing makes a
  fresh sweep of the region cheaper.
- **One upgrade tier also permanently adds +1 to the Exploration Tasks
  pool size** (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration) — which tier TBD. A Research
  Lab project ("Expanded Reconnaissance Doctrine," see [Research Lab](04_buildings_and_economy.md#research-lab)) is
  the second, independent source of +1, for a maximum pool size of 5.

---

## Research Lab

Deliberately named and scoped generically, not after its first use case —
this is meant to host other Basic-Science-flavored research later without
needing a new building type each time (see `DESIGN_TODO.md`). Its own
progression stays **resource-gated, not research-gated**, consistent with
Technology & Progression: it doesn't introduce an abstract research-points
currency, it's a bespoke, per-discovery unlock tied to specific exploration
finds, same spirit as everything else in the catalog.

- Category: Utilities (see [Building Categories](04_buildings_and_economy.md#building-categories) in [Resources](04_buildings_and_economy.md#resources)) | Staffing: Staffed
- Input: none (beyond staffing) | Output: none in the trackable-resource
  sense — completing a research project is a permanent rule-change to a
  target building type, not an item (per the Building Schema's note that
  Output may not be a trackable resource item at all).
- Works one research project at a time; building multiple Labs allows
  parallel projects. If more than one unlocked-but-unresearched project is
  pending, the player selects which to work on — same multi-recipe
  selection pattern used elsewhere (sticky, reversible). `production_time`
  per project: TBD, some number of seasons.
- **First use case: Hybridization** (see [Farm/Production](04_buildings_and_economy.md#farmproduction)) — exploration
  discoveries unlock specific per-building hybridization projects here.
- **Second use case: "Expanded Reconnaissance Doctrine"** — a research
  project permanently adding +1 to the Exploration Tasks pool size (see
  [Settlers](05_settlers_and_exploration.md#settlers) & Exploration), always available to research (not
  discovery-gated like Hybridization projects are).
- Construction cost: Lumber/Concrete (ratio TBD) + High-Tech Components.
- `TechAchievement`: 2 — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)

---

## Food/Meal Conversion

### Kitchen
- Category: Food/Meal Conversion | Staffing: Staffed
- **Deviates from the standard multi-recipe pattern**: instead of one active
  recipe with effort stacking toward a shared cap, Kitchen has **N simultaneous
  recipe slots**, each independently staffed by one worker who selects which
  recipe *that slot* runs from the full available list — letting one Kitchen
  produce several different meals in parallel. Grid footprint scales with slot
  count (see [Building Schema](04_buildings_and_economy.md#building-schema)): **base Kitchen = 1 slot (1 worker, 1 grid
  space)**, **Upgraded Kitchen = 2 slots (2 workers, 2 grid spaces, fixed
  non-rotatable shape)**.
- Base-tier recipes — single-ingredient meals, chosen so the group together
  covers all four PFCV axes (see [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)):
  - Bread ← Grain (Carbs-heavy)
  - Fruit dish ← Fruit (Vitamins-heavy)
  - Dairy dish ← Milk (Protein/Fat/Vitamins)
  - Egg dish ← Eggs (Protein/Fat-heavy — carries the group's main Fat
    contribution, per design)
- Upgraded-tier recipes — a small **fixed set of combo meal types**, each with a
  **fixed ingredient list**, yielding better-balanced PFCV profiles than any
  single-ingredient meal:
  - **Sandwich** ← Grain + Eggs
  - **Pasta Dish** ← Grain + Milk
  - **Fruit Pastry** ← Grain + Fruit
  - **Custard Dish** ← Milk + Eggs + Fruit (the one three-ingredient "premium"
    combo, naturally the most PFCV-balanced of the four)
  - Each combo type has a **pool of purely cosmetic flavor-name variants**,
    randomly selected on production with zero mechanical effect (e.g. Sandwich →
    *Club / Egg Salad / Breakfast Sandwich / Croque Madame*; Pasta Dish →
    *Alfredo / Mac & Cheese / Carbonara / Baked Ziti*; Fruit Pastry → *Fruit Pie
    / Turnover / Strudel / Cobbler*; Custard Dish → *Custard / Flan / Quiche /
    Crème Brûlée*). Flavor-name variety doesn't need to correspond to actually
    matching ingredients — a named dish referencing an ingredient the player
    doesn't literally have is fine, relying on the player's suspension of
    disbelief.
- **Gourmet tier** — a **settler-specific** unlock, distinct in kind from
  every recipe above: once a settler has maxed their Kitchen [Experience](05_settlers_and_exploration.md#experience)
  (3 stacks — see Settlers & Exploration) *and* at least one Seasoning
  (see Resources) currently sits in the farm's general inventory, each
  season they work Kitchen carries an independent chance (illustrative
  75%, one roll per distinct Seasoning currently available) of a "moment
  of brilliance" — inventing that Seasoning's corresponding Gourmet dish.
  A settler can invent more than one Gourmet recipe over a run, one per
  distinct Seasoning they successfully roll against. Once invented, the
  recipe belongs to that settler specifically: only they can cook it, and
  only while they're the one currently assigned to Kitchen — unlike every
  other recipe in this design, it isn't a settlement-wide unlock. Gourmet
  dishes feed `TechAchievement` the same way Luxury Goods do, on top of
  their ordinary nutritional value.
- **Local Delicacy** — a second, separate new recipe, unlocked once a
  Peaceful Contact alliance exists with an alien civilization (see
  Settlers & Exploration's Escalation Chains) rather than through
  Experience/Seasonings. Name, flavor, and exact input cost are tied to
  the specific planet type and civilization class contacted. The alliance
  existing unlocks the *recipe*; actually cooking it requires the
  ingredient itself, sourced as a civilization/planet-specific income
  option within a **Trade Agreement** (see Settlers & Exploration's
  Escalation Chains) — the resolution to this recipe's previously-open
  sourcing question.
- Construction cost: Lumber/Concrete (ratio TBD).
- `TechAchievement`: 0 (base tier) / 2 (upgraded tier) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog); Gourmet tier 2 per
  invented recipe, Local Delicacy 3 (both non-material-gated, see the
  Catalog) | Repeatable: yes |
  Upgrade path: yes, gates the combo recipes and second recipe slot above

> **Open question:** meal expiration — deliberately deferred until meal
> consumption mechanics (per Food & Nutrition) are revisited in more depth. The
> idea of meals expiring is appealing (it would make a season's length feel more
> real) but needs a consumption-mechanic redesign to make it fun rather than
> just punishing.

### Ration Press

Turns fresh food into **Rations** (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)) —
densely packed, flavorless, **flat sustenance** with no per-axis nutrient
profile of its own. Its processing is aggressive enough that the input is
not left intact — which is why every Ration is interchangeable regardless
of what went in, and why anything that passes through it comes out
thoroughly sanitized (a mildly reassuring property on a frontier).

- Staffing: Unstaffed — the conversion is meant to feel automatic, not
  labor-intensive — but **cycle-based** now, not instant: it runs its
  selected recipe each cycle during Mid-Sim, consuming inputs at cycle
  start (see [Building Schema](04_buildings_and_economy.md#building-schema)), and carries a production queue with cycle
  `limits` like any other production building.
- **Input selection.** The player picks which food types the press is
  allowed to consume; the default is "everything," with an opt-out
  **blacklist** as the common case (protect Fruit for meals, say). A
  whitelist mode is available for finer control.
- **Two recipes:**
  - **Packaged Rations** — output: portable Ration units, usable
    immediately (including for exploration tasks planned the same season).
  - **Stockpile Fill** — output: bulk Ration-content routed into the
    settlement's Food Storage (see [Storage](04_buildings_and_economy.md#storage)) toward its capacity, not into
    general inventory. Same content as a packaged Ration, just unpackaged
    and in bulk.
- **Lossy either way** — a Ration (packaged or stockpiled) is worth
  meaningfully less sustenance than eating the input fresh would have been;
  Rations earn their place through portability and shelf stability, not
  efficiency. Exact conversion ratio TBD, deferred to balancing.
- Construction cost: TBD, same as other basic-tier buildings
- `TechAchievement`: 0 | Repeatable: yes | Upgrade path: none currently
  proposed

---

## Fabrication

Designed by working backward from what fabrication actually needs to consume,
which in turn confirmed uses for every raw material already listed in Resources
(Iron, Copper, Stone, Silicon, Wool, Fiber/Cotton, Wood, Pelts, rare metals) and
introduced several new intermediate/luxury resources: **Fabric**, **Concrete**,
**High-Tech Components**, **High-Resolution Screens**, **Portable High-Powered
Scanning Equipment**, **Leather Boots**, **Temperature-Resistant Gear**,
**Diplomatic Gear**, **Fine Furniture**, and **Ornamental/Decorative Items**.

[Robotics Assembly](04_buildings_and_economy.md#robotics-assembly) and Diplomatic Gear below are both examples of the
multi-recipe pattern already established in Building Schema — no separate
addition needed here.

### Robotics Assembly
*(consolidated — a separate Construction Bay and per-category specialized-drone
buildings were considered and rejected: committing a worker and resources to a
rarely-needed unit like a construction robot at a wholly separate structure felt
like too many commitments for something that basic, and drones are multi-use,
sticking around once built rather than needing constant replacement — so one
consolidated building with selectable recipes fits better)*
- Category: Fabrication | Staffing: Staffed
  (Settler or all-purpose drone)
- **Every drone starts as a Basic unit, fabricated fresh.** Reaching
  Advanced, or Hardened, is always a separate **upgrade-in-place** action
  performed on an already-built drone afterward — never its own from-scratch
  recipe. An upgrade-in-place action takes the existing drone as an assigned
  *resource* to the task (it's tied up, unavailable for its normal
  assignment, for the task's duration) while a *different* worker performs
  the upgrade and supplies the materials; the same drone comes out the other
  side changed, its identity and current battery charge carried through
  rather than being consumed and replaced by a fresh unit. **Advance** and
  **Harden** are independent axes — either can be applied first, and Harden
  works on a drone at either tier of either line.
- Selectable recipes (fresh fabrication):
  - Construction Robot ← Iron + Copper (base tier)
  - All-Purpose Drone (Basic) ← Iron + Copper (base tier)
  - Specialized Drone (Basic) (one recipe per Experience group — see
    [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's
    [Experience](05_settlers_and_exploration.md#experience) for the full
    list) ← Iron + Copper + a category-flavored input (**base tier — no
    Upgraded Robotics Assembly needed**, so a settlement can field its first
    specialized drone about as early as its first All-Purpose one) — still
    requires **at least one existing production structure of the matching
    group already built** — no point fabricating a Farming-specialized drone
    before any farm plot exists. Never available for Research Lab, since
    Research is settler-only regardless of drone tier.
- Selectable recipes (upgrade-in-place, on an existing drone):
  - **Advance** All-Purpose Drone (Basic → Advanced) ← Silicon + High-Tech
    Components (**requires Upgraded Robotics Assembly**) — the Basic build
    already paid for the Iron/Copper frame, so this only covers what
    Advanced tier actually adds.
  - **Advance** Specialized Drone (Basic → Advanced) ← High-Tech Components
    (**requires Upgraded Robotics Assembly**) — likewise only the increment
    beyond what Basic Specialized already paid for.
  - **Harden** (temperature-resistant battery) ← High-Tech Components —
    applies to a drone at either tier of either line.
- Construction cost: Lumber/Concrete (ratio TBD) + Iron + Copper — a robotics
  workshop needs its own metal framework, not just wood/masonry.
- `TechAchievement` (the building itself): 1 (base) / 2 (upgraded) — see the
  [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)'s Drones table for each individual
  drone state's own value | Repeatable: yes |
  Upgrade path: yes, gates the Advanced/Specialized recipes above

**Drones are persistent, assignable units** — settler-lite roster entries,
not consumable items once built. Every drone is assigned to exactly one
site at a time, the same as a settler (no multi-cell service footprint).

**Effort** (see Core Loop & Grid's [Assignment](03_core_loop_and_grid.md#assignment) for the general mechanic — a
per-worker multiplier on a task's base production rate, where 1.0 matches
an unmodified settler):

| Drone type | Effort |
|---|---|
| All-Purpose (Basic) | 0.5 |
| All-Purpose (Advanced) | 1.0 |
| Specialized (Basic) | 1.5 |
| Specialized (Advanced) | 2.0 |

Hardening changes none of the above — it's a battery-only upgrade (see below),
so a Hardened drone has the same Effort and task eligibility as its
unhardened counterpart at the same Basic/Advanced tier.

**Task eligibility:**
- **All-Purpose (Basic)** — basic production, Farming, Mining, Clear-Cutting,
  and assembly-style tasks at most production buildings. **Not** eligible
  for High-Tech Components, Research, Scanning, Surveys, Exploration, or
  Trapping.
- **All-Purpose (Advanced)** — everything Basic can do, plus High-Tech
  Components, Surveys, Scanning, Trapping, and Medical Bay's Vaccine/PPE
  production. **Only** barred from Exploration and Research (Research
  Lab's research work, and Medical Bay's medical research specifically) —
  those stay settler-only regardless of drone tier.
- **Specialized** — restricted to exactly one Experience group (see
  [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Experience](05_settlers_and_exploration.md#experience)), at a much higher Effort than even
  Advanced All-Purpose, but never Exploration or Research under any
  circumstances, same as the other two tiers.

**Battery**: every drone has an internal battery — a tracked value with a
per-drone maximum (better on higher tiers). It **resets to full for free at
the start of every season**, no cross-season tracking. Performing an
assigned task drains it over the course of Mid-Sim; if it hits zero, the
drone **briefly recharges** (~3 seconds of Mid-Sim time, roughly a fifth of
a season, possibly varying by drone type) — fully automatic, no player
decision. Recharging is a temporary **elevated Energy consumption** need,
the same category of thing as Weather/Row Shield's event-driven cost (see
Resources' Energy Income/Consumption Rates), so it competes for coverage
the same way: if there isn't enough available Income when the drone needs
to recharge, it's one of the consumers the random-shedding mechanism can
select, and recharging simply doesn't progress until Income next covers it
(no separate buffer/threshold needed — the "don't recompute except on a
real change" rule already prevents rapid flapping). While recharging or
waiting to, the drone contributes zero Effort. Higher-tier drones have big
enough batteries that they may never need to recharge in a normal season.
No battery replacement is ever needed; this is permanent hardware, just
periodically drained and refilled. Draining is faster the further
temperature strays from the 72°F comfort target (see Planets & Scoring's
[In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)), **except for hardened drones** (see the
Hardening upgrade recipe above), which don't suffer this penalty.

**Destruction**: any worker, settler or drone, is freed and returns to the
roster when their building is destroyed. If this happens mid-Mid-Sim, they
also immediately lose whatever Indoor protection they had (see Building
Schema) and become exposed to any hazard active at that moment.

### Stone Processing I
*(a starting building, present from run start like Solar Array and Water
Processing Plant — not something the player constructs; see Sawmill below
for the matching Lumber-side building and the bootstrapping problem this
pair of starting buildings resolves)*
- Category: Fabrication | Staffing: Staffed
- Selectable recipes:
  - Concrete ← Stone
- Concrete is one of the two universal base construction materials (see
  Resources) — this is why Stone Processing has to be standing from turn
  one rather than something the player builds.
- Upgrades to **Stone Processing II**, which additionally unlocks:
  - Silicon ← Stone
  - **Glass ← Stone** — a refined material used by High-Tech Components
    (cameras/screens), PPE, and specialized hazard-resistant gear (see
    Medical Bay and Fabrication below). Broader uses for Glass are an open
    thread — see `DESIGN_TODO.md`.
- Upgrade cost: TBD.
- `TechAchievement`: 0 (Stone Processing I) / 2 (Stone Processing II) — see
  [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)

### Smelter
- Category: Fabrication | Staffing: Staffed
- New (surfaced while designing Settlers & Exploration's Aptitude
  buckets): refines **Iron Ore** and **Copper Ore** into usable Iron and
  Copper, the same role Stone Processing plays for Stone — Mine's Ore
  output previously had nowhere to go but directly into Fabrication
  recipes unrefined; this adds a real processing step, matching the
  mined-then-processed shape Stone Processing already established.
- Selectable recipes:
  - Iron ← Iron Ore
  - Copper ← Copper Ore
- Exact ratios TBD, deferred to balancing like other numeric values in
  this design.
- Construction cost: Lumber/Concrete (ratio TBD) + Stone — same register
  as Stone Processing, another modest processing-plant structure.
- `TechAchievement`: 0 — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)

### Textile Workshop
- Category: Fabrication | Staffing: Staffed
- Construction cost: Lumber/Concrete (ratio TBD).
- `TechAchievement` (the building itself): 0 — see the [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)'s
  Fabrication — items table for Fabric/Leather/Leather Boots/Leather
  Backpack's own values
- Selectable recipes:
  - Fabric ← Wool, or Fiber/Cotton, or Pelts (any one of the three, player
    selects which this cycle consumes) — Pelts' direct role here is
    independent of tanning, below; a player can go straight from Pelts to
    Fabric without ever producing Leather.
  - **Leather** ← Pelts (tanning) — the refined, usable form of Pelts for
    Leather-specific goods (see Resources). Everything below that used to
    consume Pelts directly now consumes Leather instead.
  - Leather Boots ← Leather + Fiber (**requires Upgraded Textile Workshop**) —
    a Luxury Good; feeds `TechAchievement` and can serve as a
    prerequisite/supply cost for specific manned exploration tasks,
    generalizing the earlier food-cost-for-expeditions idea to manufactured
    goods
  - **Leather Backpack** (renamed from Large Backpack) ← Leather — an
    exploration-task consumable (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Exploration Tasks](05_settlers_and_exploration.md#exploration-tasks) [Task Catalog](05_settlers_and_exploration.md#task-catalog)):
    brought along on a Resource windfall task, it guarantees the top of
    that task's value range. Consumed on use, same precedent PPE already
    established for exploration-task consumables.

### Tinkerer's Workshop
- Category: Fabrication | Staffing: Staffed
  — Settler, Advanced All-Purpose Drone, or a Tinkerer's-Workshop-Specialized
  Drone (see [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)) — not Basic All-Purpose, since High-Tech
  Components requires Advanced-tier eligibility
- Construction cost: Lumber/Concrete (ratio TBD) + Iron + Copper + Silicon
  — the most materially demanding of the Fabrication buildings' own
  construction costs, matching the sophistication of what it produces.
- `TechAchievement` (the building itself): 2 — see the [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)'s
  Fabrication — items table for each recipe's own value
- Selectable recipes (base tier):
  - High-Tech Components ← Copper + Silicon + Iron + Glass — used as a
    construction-cost input for Protection-tier shield structures and other
    advanced buildings, creating a real multi-tier fabrication chain
    (Iron/Copper/Silicon/Glass → High-Tech Components → advanced buildings)
    without reintroducing merge-space complexity, since each step is still
    automatic single-recipe production. (Silicon and Glass both come from
    Stone Processing II, so it is squarely the mid-game keystone — a
    deliberate single chokepoint, see `DESIGN_TODO.md`.)
  - High-Resolution Screens ← Silicon + Copper — a Luxury Good; no functional
    use yet beyond `TechAchievement`/faction-reward value, left open
  - Portable High-Powered Scanning Equipment ← Silicon + Copper + a rare metal
    + High-Tech Components —
    an exploration task initiation cost, likely gating access to higher-tier/
    more-frequent Safeguard or Stewardship data-gathering missions (weather
    balloon, atmospheric probe, bio-survey, sentience-detection)
- Selectable recipes (**requires further-Upgraded Tinkerer's Workshop**):
  - Temperature-Resistant Gear ← (Fabric **or** Leather, player selects
    which) + a rare metal + High-Tech Components + Glass — **one
    universal item covering both hot and cold** (no separate variants),
    distinct from `MatchedPreparedness` (which is about the settlement's
    structures, not what an individual carries). Exploration-task settlers
    still explicitly elect to bring it (consumed); farm-based settlers are
    covered by a **passive stock check** — any Gear sitting in general
    inventory covers everyone on the farm against Temperature Extremity, not
    consumed, not per-settler-allocated — the same pattern PPE already
    established for Atmospheric Hazard (see [Protection](04_buildings_and_economy.md#protection)'s [Medical Bay](04_buildings_and_economy.md#medical-bay)). Any
    passive-stock-check item like this one should show a visible "in use"
    indicator during season simulation when it's actively covering someone —
    a UI/Art Design note, not a mechanic.
  - Diplomatic Gear ← (Silicon + Copper) **or** (Fabric), player selects which
    input path — a prerequisite for the **Peaceful Contact** and
    **Bluff/Coercive Exploitation** approaches at First Contact (see
    [Exploration Tasks](05_settlers_and_exploration.md#exploration-tasks)' [Escalation Chains](05_settlers_and_exploration.md#escalation-chains))
  - **Armed Expedition Kit** ← Iron + a rare metal — one of two
    prerequisites (alongside Overwhelming Force Package, below) for the
    **Military Exploitation** approach at First Contact (see Exploration
    Tasks' [Escalation Chains](05_settlers_and_exploration.md#escalation-chains)); deliberately named to read as practical
    expedition equipment rather than a weapons system, matching the game's
    cozy-pioneering tone
  - **Overwhelming Force Package** (new) ← High-Tech Components + a rare
    metal — the other Military Exploitation prerequisite; represents a
    genuine technological edge, not just more Armed Expedition Kits,
    consistent with the design intent that a few settlers should
    essentially never be able to force anything from an entire
    civilization without one. Exact recipe a first-pass placeholder — see
    `DESIGN_TODO.md`

### Sawmill
*(a starting building, present from run start like Solar Array and Stone
Processing I — not something the player constructs)*
- Category: Fabrication | Staffing: Staffed
- Selectable recipes:
  - Lumber ← Wood
- Lumber is one of the two universal base construction materials (see
  Resources), and Wood is freely available from turn one via Clear-Cutting
  (a Standing Assignment, no building required) — together with Stone
  Processing I, this is what makes the settlement's starting economy
  self-bootstrapping with no separate starting-materials stockpile needed.
- Upgrades to **Carpenter's Shop**, which additionally unlocks:
  - Fine Furniture ← Lumber — a Luxury Good, pure flavor/`TechAchievement`
    reward, no functional use
  - Ornamental/Decorative Items ← Lumber + Stone/Concrete — same tier as Fine
    Furniture
  - **Wooden Plow** ← 2 Lumber + 1 Leather — a passive-stock-check item
    (same pattern as PPE/Temperature-Resistant Gear: not consumed, its
    effect is simply active whenever at least one sits in general
    inventory), **drastically** cutting the duration of every plant-crop
    building's transition *away from* its `unprepared` state, settlement-wide
    (see Farm/Production's [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model)) —
    illustrative **at least -50%**, exact value TBD, deferred to balancing
    like other numeric values in this design. A **Farming-Specialized
    Drone** doesn't need a Wooden Plow at all — its body is built for the
    task directly, so it gets this same cut inherently, **stacked on top of**
    its Effort multiplier rather than substituting for it. A settler or an
    **All-Purpose Drone** still needs the item present, same as anyone else
- Upgrade cost: TBD.
- `TechAchievement`: 0 (Sawmill) / 2 (Carpenter's Shop, and each of Fine
  Furniture/Ornamental/Decorative Items/Wooden Plow) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)

---

## Protection

Backs `MatchedPreparedness(Weather)` and `MatchedPreparedness(Bio-hazard)` for
the Safeguard Coalition (see Win/Lose Conditions' [SEED Factions](06_planets_and_scoring.md#seed-factions)). Also
resolves the "Medical/Vaccine production" gap: Bio-hazard preparedness lives
here too, not as a separate category — Protection is about protecting the
settlement from a planetary danger generally, whether physical (weather) or
biological.

Each building's **Preparedness contribution** is expressed on the same rough
0–1 scale as `TrueRisk` (see [Exoplanet Types](06_planets_and_scoring.md#exoplanet-types)' Hazard Priors), so that a
reasonable number of buildings can plausibly reach or exceed a planet's true
risk level and hit `MatchedPreparedness`'s cap of 1. Exact numbers TBD,
deferred to a balancing pass — following "numbers stay small," these are
first-pass illustrative values.

**Multi-slot footprints aren't only about worker capacity.** The Building
Schema's rule that grid-slot count equals worker-assignment capacity (see
[Kitchen](04_buildings_and_economy.md#kitchen)) has its first exception here: [Row Shield](04_buildings_and_economy.md#row-shield) below occupies 2 slots for
a wholly different reason — its physical size determines the *shape* of
coverage it projects, independent of staffing (it's unstaffed). A building's
slot count can reflect either worker capacity or physical structure needs,
whichever applies.

### Weather Shield
- Staffing: Unstaffed (a physical force field doesn't
  need an operator to simply keep running once built)
- **Area of effect**: a Manhattan-distance radius (illustrative: 2, matching
  the original design's "weather bubble" precedent) covering nearby cells of
  **any building type** (not just Farm/Production — see Core Loop & Grid's
  The Grid (Unified) for why coverage was widened when the two grids
  merged) — upgradeable to a larger radius
- **Energy upkeep**: variable and event-driven, not a flat per-season
  number — see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events) for the full
  mechanism. Summary: cost scales with the severity of whatever Temperature
  Extremity event is currently active (idle-but-armed cost normally, more
  during a mild event, more during an extreme one); paying it in full during
  an active event is what keeps covered cells at zero effect. Always
  explicitly displayed, never hidden.
- **Preparedness contribution**: Weather axis, flat amount scaling with tier
  (illustrative: 0.3 base, 0.6 upgraded)
- Construction cost: Concrete + Iron (base tier); upgraded tier additionally
  requires **High-Tech Components** (from Tinkerer's Workshop), consistent
  with shield technology needing sophisticated components
- `TechAchievement`: 1 (base) / 2 (upgraded) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) | Repeatable: yes (multiple
  can be built for wider coverage) | Upgrade path: yes — larger radius, more
  Preparedness credit
- No data-gating on its Preparedness contribution — a physical shield works
  regardless of whether the settlement has measured how bad the weather
  actually is. This is an intentional asymmetry with [Medical Bay](04_buildings_and_economy.md#medical-bay) below, not
  an inconsistency: physical protection doesn't require understanding a
  threat to block it, but a medical countermeasure specifically requires
  characterizing the threat to exist at all.

### Row Shield
*(an alternate Weather Shield structure, not an upgrade of it — a genuinely
different coverage shape for a different grid layout, per the design
principle that a planet/strategy shouldn't reduce to one correct approach)*
- Staffing: Unstaffed
- **Footprint**: 2 vertically-adjacent tiles, a fixed non-rotatable shape
  (see the multi-slot note above — this is about physical structure size,
  not worker capacity)
- **Area of effect**: both full horizontal rows the building occupies,
  extending in both directions (left and right) across the entire grid
  width — a linear shape, contrasted with Weather Shield's circular radius.
  Suits a horizontally-spread layout; Weather Shield suits a compact cluster.
- **No upgrade path** — extending coverage to additional rows isn't worth
  building into this structure specifically, since the player can simply
  build a second Row Shield for more rows (at some cost to placement
  granularity, not considered worth designing around)
- **Energy upkeep**: same variable, event-driven mechanic as Weather Shield
  (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events))
- **Preparedness contribution**: Weather axis, same shape as Weather Shield's
  base tier
- Construction cost: strictly between Weather Shield's base cost and
  (Weather Shield base + Advanced upgrade) combined — exact numbers TBD
- `TechAchievement`: 1 — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) | Repeatable: yes

### Medical Bay
- Staffing: Staffed, **1 worker** — Settler, Advanced All-Purpose Drone, or
  a Medical-Bay-Specialized Drone (see [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)) for the Biological
  Lab Materials / PPE / Emergency Medical Kit recipes; **countermeasure
  research stays settler-only**, the same rule as Research Lab. The one
  worker chooses among these via the production queue (see [Building Schema](04_buildings_and_economy.md#building-schema)) —
  a deliberate bottleneck on a high-hazard run (the answer is a second
  Medical Bay).
- **Base tier**: provides baseline `Preparedness(Bio-hazard)` credit
  (general medical readiness — illustrative: 0.2) — available immediately,
  no data prerequisite. Also hosts the recurring PPE and Emergency Medical
  Kit recipes and the **Biological Lab Materials** recipe (below).
- **Recovery capacity** (a conditional Building Schema property): the number
  of settlers who can be actively recovering from an injury or a
  parasite/disease infection at once — **1 at the base tier, 2 upgraded**.
  Recovering settlers are not this building's worker and can't be assigned
  to other work while recovering (see Settlers & Exploration's [Injuries](05_settlers_and_exploration.md#injuries));
  demand beyond capacity queues, still infected. When infected settlers
  outnumber slots, the deadliest infections take the slots first (not
  surfaced to the player). A held-but-recovering settler's assigned site
  produces nothing — the Site Panel shows "worker recovering."
- **Biological Countermeasures tier** (upgrade) — a **functional gate**:
  only buildable once `Confidence(Bio-hazard)` (from Safeguard's
  Beta-distribution data-gathering, see Exoplanet Types) crosses a threshold
  (illustrative: 0.5, TBD) — you can't develop targeted countermeasures
  without first characterizing the planet's biology at all. Provides an
  elevated `Preparedness(Bio-hazard)` credit while it exists (illustrative:
  0.7). Beyond the tier gate, individual countermeasures are researched
  **one threat at a time** (this is the resolution to the axis-vs-pathogen
  granularity question):
  - **Countermeasure research** is a recurring recipe: a settler on this
    recipe completes a cycle (consuming **Biological Lab Materials**) that
    resolves **one bio-threat, chosen at random**, from the list of
    *encountered or confirmed* threats not yet countered — a settler or
    animal case, an expert-witnessed infected food/animal, or an
    exploration/survey report; never a threat that merely exists on the
    planet unseen. Each completed research **permanently removes** that
    threat from the list. Needing a researcher assigned every season is the
    signal of an unusually high-hazard run.
  - **Against a disease (Pathogen Threat):** the result is a **vaccine** —
    a permanent settlement-wide fact. From then on no settler is infected
    by that disease, and any active case's recovery always succeeds. Not
    tied to the building's continued existence (a destroyed-and-rebuilt
    Medical Bay restores its Preparedness/recipes, not the vaccine — there's
    nothing to restore). Unlocking a vaccine also triggers a **new
    exploration escalation** to the region the disease was found in, now
    safe (see Exploration Tasks' [Escalation Chains](05_settlers_and_exploration.md#escalation-chains)).
  - **Against a parasite (Toxic/Parasitic Organism Threat):** the result is
    an **anti-parasitic**. Settlers gain **no immunity** — they can still
    contract it — but recovery from then on always succeeds and is faster.
    Husbandry animals gain **permanent auto-immunity**: every currently
    infected husbandry population of that parasite is cleared on research
    completion and can never re-contract it (diegetically, ongoing
    small-scale treatment of the herd as it grows — mechanically, a
    settlement-wide fact).
  - See Settlers & Exploration's [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition) (infected food) and
    Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events) (the quarter-season
    epidemiology tick, spread, death rolls) for the rest.
- **Energy upkeep**: ordinary flat per-season baseline, same rule as every
  other building — Medical Bay isn't one of the two AOE shield structures.
- **Biological Lab Materials recipe**: Grain + Glass → Biological Lab
  Materials — the advanced-input for countermeasure research (replacing
  High-Tech Components in that role; PPE and Emergency Medical Kit keep
  their own recipes). Meant to be quick per cycle — an input-cost gate more
  than a time gate.
- **PPE recipe** (Personal Protective Equipment): **Fabric + Glass → PPE**,
  a recurring recipe available from the base tier, no `Confidence`-gating.
  Addresses **Atmospheric Hazard** (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)
  for the full mechanism: passive stock check for farm-based settlers;
  explicitly elected and consumed for exploration-task settlers; exposure
  without it inflicts the halving status effect).
- **Emergency Medical Kit recipe**: a low-tier recurring recipe, **no
  High-Tech Components** (recipe otherwise TBD — Fabric plus a basic
  input). An **optional item on any exploration task**, consumed when
  taken: if that task's outcome would have inflicted a **minor injury or a
  parasite/disease infection**, the kit prevents it (it does nothing
  against a permanent injury or death). One kit covers that task's whole
  "came back hurt" outcome.
- Construction cost: Fabric + Lumber/Concrete (ratio TBD) + High-Tech
  Components (base tier); the Biological Countermeasures tier requires
  **Biological Lab Materials** instead of additional High-Tech Components.
  The upgraded tier occupies a **2-slot footprint** (any two-tile
  rectangle) — the upgrade bundles a free relocation, per [Building Schema](04_buildings_and_economy.md#building-schema).
- `TechAchievement`: 2 (base) / 3 (Biological Countermeasures tier) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog);
  PPE 2, Emergency Medical Kit 1 |
  Repeatable: yes | Upgrade path: yes, as described above

---

## Habitation

The crew need somewhere to sleep. **Sleep quality** is a settlement-wide
settler status (a `status_effect` entry — see Settlers & Exploration's
[Settler State](05_settlers_and_exploration.md#settlers)), determined by the best quarters the settlement
currently provides, on a **best-available-wins** basis — the tiers do not
stack:

| Best quarters standing | Status | Effect |
|---|---|---|
| no quarters building stands at all | **Poor Sleep** | on-site Effort ×0.75 |
| Settlement Base only (powered or not) | *(neutral — no status)* | baseline |
| Crew Quarters, **powered** | **Good Sleep** | on-site Effort ×1.10 |
| Luxury Living Quarters, **powered** | **Great Sleep** | on-site Effort ×1.15 |

The **bonus** tiers require the building to be powered. An **un-powered**
Crew Quarters or Luxury Living Quarters (shed during an Energy shortfall —
see [Resources](04_buildings_and_economy.md#resources)) is still a valid place to sleep, so it falls back to the
neutral baseline, never to Poor Sleep. Poor Sleep applies only when **no**
quarters building — Settlement Base or dedicated — stands at all.

- The modifier applies to **settlers only** (drones do not sleep) and to
  **on-site work only** — production-building assignments *and* Standing
  Assignments (both performed at or near the settlement, where the settler
  sleeps in their quarters). Exploration Tasks are unaffected — the settler
  is away from the settlement for the season.
- It is a straight multiplier on the worker's Effort contribution; its
  exact position relative to Aptitude/Experience/other modifiers folds
  into the open modifier-combination question (see Worker Assignment audit
  `3-SF1` in `DESIGN_TODO.md`).
- One qualifying building covers the **whole crew** — there is no
  per-settler capacity. The status flips the moment the settlement's best
  standing quarters changes (a Crew Quarters built, the Settlement Base
  destroyed, etc.), resolved at the same point as other `status_effect`
  changes.

### Crew Quarters
- Category: Habitation | Staffing: Unstaffed
- Input: none | Output: **Good Sleep** for the whole crew (see table
  above)
- Grid slot count: 1
- Construction cost: modest Lumber/Concrete (ratio TBD, deferred to
  balancing)
- `TechAchievement`: 1 — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)
- Repeatable: **no** — a second one does nothing (the effect is
  settlement-wide and non-stacking)
- Upgrade path: yes → **Luxury Living Quarters**
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

### Luxury Living Quarters
The upgrade tier of [Crew Quarters](04_buildings_and_economy.md#crew-quarters).
- Category: Habitation | Staffing: Unstaffed
- Input: none | Output: **Great Sleep** for the whole crew, plus the
  luxury-item slots below
- Grid slot count: 1
- **Luxury-item slots** — one slot per settler (five, at the crew size of
  5). A luxury item is *held/assigned* into a slot from general inventory,
  a normal reversible planning-phase action in **any** planning phase (not
  only the one where it was first assigned) — it is not consumed. Each
  **distinct** luxury item in a slot grants one settlement-wide boost;
  duplicates of the same item add nothing. The luxury-item roster and the
  boost each one grants are **not yet designed** — see `DESIGN_TODO.md`,
  "Luxury-item catalog & Habitation boosts".
- Construction cost: Crew Quarters' cost plus refined goods (exact set
  TBD, deferred to balancing)
- `TechAchievement`: 3 — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog)
- Repeatable: no | Upgrade path: none (top tier)
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

---

## Storage

General working inventory needs no dedicated Storage buildings at all — it's
fully uncapped (see [Inventory](04_buildings_and_economy.md#inventory) below). The one deliberate exception is **Food
Storage**, which exists specifically to give the Sustenance Bloc's
`NutritionStockpile` term a real, felt tradeoff rather than a passive byproduct
of surplus production.

### Food Storage

A long-term reserve of **bulk Ration-content** — the same flat, sanitized
sustenance a Ration is, just unpackaged and in bulk. Its only input is the
**Stockpile Fill** recipe of a [Ration Press](04_buildings_and_economy.md#ration-press); raw crops, meat, and Meals
cannot be put here directly, so nothing entering long-term storage has
skipped the Ration Press's sanitizing processing.

- **Held bulk feeds `NutritionStockpile`** (see Planets & Scoring's [SEED Factions](06_planets_and_scoring.md#seed-factions))
  — a single flat quantity now, not a four-axis sum; measured as a
  **run-end snapshot**, so anything drawn back out before the run ends
  simply isn't scored. General inventory contributes nothing, so a real
  Sustenance score still requires committing production into storage via
  the press.
- **Reversible, with friction.** Assigning a worker makes Food Storage run
  an **extraction** recipe: bulk held content → packaged Rations, at a
  deliberately poor rate and pace — it exists for the season a settlement
  would otherwise lose settlers because normal food income and Ration
  production fell short, not as a routine tap. (It should never feel good
  to watch the crew die because you were hoarding a reserve to look
  impressive back on Earth.) With no worker assigned, the building just
  holds and scores.
- **Storage contribution**: a real, limited capacity (in sustenance units),
  **deliberately scaled so the unupgraded building cannot reach a maximum
  `NutritionStockpile` score even completely full** — forcing upgrades (or
  multiple Food Storage buildings) as a genuine ongoing investment, not a
  one-time build-and-forget structure. Exact capacity numbers TBD, deferred
  to a balancing pass.
- Staffing: Staffed (Settler or drone) — only when extracting; holding and
  scoring need no worker.
- Construction cost: Lumber/Concrete (ratio TBD) | `TechAchievement`: 0 (base) /
  2 (upgraded tiers) — see [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) | Repeatable: yes | Upgrade path: yes, raises
  capacity

---

## Inventory

- All crafted items and pieces removed from the grid go to a **general
  inventory** — a single shared pool, not tied to any specific building; the
  inventory also serves as the off-grid holding area (workspace) during
  planning
- **Fully uncapped** — no capacity limit, no storage-contribution buildings
  needed to hold ordinary working resources (raw materials, manufactured
  goods, food not yet committed to [Food Storage](04_buildings_and_economy.md#food-storage) — see [Storage](04_buildings_and_economy.md#storage) below). This
  supersedes the old capacity-limited model entirely: there is no prioritization
  list, no overflow state, and no overflow-breakdown mechanic —
  nothing ever needs to be discarded or converted for lack of space. Reflects
  the general design goal of keeping ordinary resource-holding low-effort and
  low-interaction; the one deliberate exception is Food Storage, a dedicated
  building that requires real investment (see [Storage](04_buildings_and_economy.md#storage) below).
- The inventory is a **list**, not a spatial arrangement — the player never has
  to pack items into storage physically
