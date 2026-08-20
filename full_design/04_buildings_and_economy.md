# Buildings & Economy

## Resources

### Basic Resources
- **Energy** and **Matter** — pooled, colony-wide resources. Base production is
  **zero-effort/unstaffed** (see Building Categories below), unlike ordinary staffed
  production sites.
- **Water** — pooled, colony-wide resource, ambiguous units (e.g. "3 Water"),
  no complicated irrigation/transport system to model (see Water below).
  Unlike Energy/Matter, collection requires staffed buildings and a
  prerequisite structure (Water Processing Plant) — not zero-effort.

**Energy Pool.** Energy is not an inventory item — it never appears in the
general inventory list alongside Wood, Stone, food, etc.; it's tracked as
its own separate system (a dedicated meter/gauge in the UI), **orthogonal**
to Storage's uncapped-inventory rules entirely, not a second exception to
them. It behaves as a liquid pool with three parts:
- **Cap (ceiling)** — sum of every Energy-producing building's capacity
  contribution (Solar Array, Geothermal Generator, Fuel-based Generator —
  see Basic Resource Production and Fuel) minus the sum of every building's
  baseline Energy upkeep (below). Every Energy-producing building
  contributes to the cap simply by **existing**, regardless of whether it's
  currently actively producing — Fuel-based Generator's contribution comes
  from an assumed structural battery, the same reasoning that lets any
  Energy producer smooth out real-time mismatches between production and
  consumption. Upkeep permanently reduces the ceiling the moment a building
  is placed — a **build-time decision**, not a recurring withdrawal.
- **Income** — constant-rate accumulation into the pool during Mid-Sim,
  bounded by the cap. Solar Array and Geothermal Generator produce at a
  genuinely constant rate; Fuel-based Generator's contribution to *income*
  (distinct from its unconditional contribution to the *cap*, above) is
  conditional — see its entry under Fuel for how its active window works.
- **Draws** — discrete, reactive spending against the pool's **current
  balance** (not the cap), which persists across the season boundary rather
  than resetting each season. Weather Shield/Row Shield's event-driven
  funding (see Planets & Scoring's In-Simulation Hazard Events) is the
  original example this generalizes from; the exploration reroll cost (see
  Settlers & Exploration's Exploration Tasks) is a second draw type, spent
  during planning rather than mid-simulation.

The Energy meter reads as a **smooth, continuous fill**, never discrete
ticks — the same "continuous rate, not a discrete timer" principle already
established for the Production Model, applied to Energy's own UI
specifically.

**Baseline Energy upkeep.** Every building — staffed or not, and regardless
of category — draws a flat per-season Energy cost just for existing on the
grid (lights, climate-neutral operation, idle machinery draw), reducing the
pool's cap as described above, with exactly one exception: **Weather Shield
and Row Shield** (only these two — not the rest of Protection, so Medical
Bay follows the ordinary flat-baseline rule like any other staffed
building) instead carry a variable, event-driven cost drawn from the pool's
current balance during an active Temperature Extremity event, rather than a
fixed cap reduction. This is a deliberate simplicity choice: the baseline
cost is fixed the moment a building is placed, so budgeting for it is a
build-time decision, not something to re-check every season — juggling
Energy in response to short-lived threats (via the two shield buildings,
and now exploration reroll) is meant to be a real, occasional decision;
juggling it just to keep the lights on everywhere else is not. Exact
per-building values TBD, deferred to balancing like other numeric values in
this design.

### Building Categories
1. **Basic Resource Production** — Energy and Matter generation, always
   unstaffed — though not all zero-effort in practice: Geothermal Generator
   needs a discovered Thermal Vent, and Fuel-based Generator needs a real
   Wood/Fossil Fuel supply chain and carries an ongoing Stewardship cost
   (see Fuel).
2. **Farm/Production** — crops, animal products, and mining, staffed sites
   (see Baseline Farm/Mined Resources below).
3. **Food/Meal Conversion** — turns raw farm output into meals with nutrient profiles
   (see Food & Nutrition).
4. **Fabrication** — staffed sites producing drones, construction robots, and
   other fabricated goods (Concrete, Fabric, High-Tech Components, Fine
   Furniture, etc. — see Platform & Core Loop Redesign's Construction and
   Worker Assignment sections).
5. **Protection** — force-field/weather-protection structures and Medical
   Bay. Weather Shield/Row Shield specifically (not Medical Bay) carry a
   variable, event-driven Energy cost tied to Temperature Extremity events
   (see Planets & Scoring's In-Simulation Hazard Events) — always
   explicitly listed when it has an impact, never a hidden drain.
6. **Storage** — contributes inventory capacity, carried over from the original
   design.
7. **Utilities** — staffed settlement-support infrastructure that isn't
   itself farming, fabrication, storage, or protection: Water collection
   (see Water), Scanner Station (see Scanner Station), and Research Lab (see
   Research Lab). The thing these share isn't output type, it's role —
   keeping the place running rather than producing, protecting, or storing
   anything directly.

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
  Outcrop — see Settlers & Exploration's Task Catalog) also yield Ore, never
  refined metal.
- **Iron** and **Copper** — the refined, usable form of the Ore above, produced
  at the Smelter (see Fabrication). Iron: structural strength (robot bodies).
  Copper: electronics components. Higher-tier exploration tasks can skip the
  Ore stage and yield refined metal directly, as part of the reward for their
  added difficulty/rarity.
- **Stone** — raw material for basic construction, distinct from **Silicon**, which
  is refined/extracted from the same Stone resource for electronics fabrication.
- **Rare metals** — findable on any planet, but with probability strongly biased by
  planet type. Needed for high-tech applications, including energy-shielding
  devices. Governed by a standing planet-design principle (see Planet Types below):
  a planet's dominant hazard and the materials that counter it are positively
  correlated, but only as a correlation, not a guarantee — a temperate planet can
  still yield them, just less often.
- **Wood has two sources with different sustainability profiles, not two
  separate resources.** Timber Grove's ordinary output (see Farm/Production)
  is renewable/ongoing; Clear-Cutting (see Fuel — a Standing Assignment, not
  a building) harvests from a bounded Forest tile, a one-time harvest that
  does not regenerate within a run. Both produce the same fungible, pooled
  **Wood** — usable interchangeably for fabrication or for burning at
  Fuel-based Generator — but *how* a given unit was produced is what
  matters for Stewardship: only Clear-Cutting's output counts toward
  `ExtractionRestraint`
  (see SEED Factions in Win/Lose Conditions), tracked as a running total at
  production time, not by tracing which specific unit later gets consumed.
- **Fossil Fuel** exists solely as Fuel-based Generator's upgrade-tier input
  (see Fuel), from a hidden deposit (see Deposit Discovery) — always
  non-sustainable, no Timber-Grove-style renewable source exists for it.
- **Fertilizer** — produced passively by livestock buildings (Dairy Pasture,
  Poultry Coop, Sheep Pasture — not Trapping, which harvests wild animals
  rather than raising livestock, and isn't a building at all) just by
  existing on the farm, regardless of
  staffing or whether they're actively producing Milk/Eggs/Wool that season.
  Consumed automatically, once per *season* (not per production cycle), by
  plant-crop buildings to offset the Alien Soil penalty (see Farm/Production).
- **Mining deposits come in two types**: a **high-yield, bounded** site (finite
  total quantity, depletes with use) and a **lower-yield, effectively infinite**
  site (doesn't meaningfully deplete within a run's timescale). Both incur the same
  per-unit Stewardship cost when mined (see SEED Factions in Win/Lose Conditions) —
  the disruption Stewardship objects to is the mining process/infrastructure itself,
  not depletion, so extraction volume is penalized at the same rate regardless of
  deposit type.

### Naming Convention
- Basic resources: simple names (Energy, Matter)
- Advanced/rare items: technical compound names (e.g. "Flux-modulated Drone Battery")
- Planet-side materials: can use less familiar names (e.g. "Iridite") since they are
  rarer and encountered later in play

---

## Building Schema

Every building in the catalog (see Building Categories in Resources) is defined by
the following properties. Working through the catalog category-by-category (see
`DESIGN_TODO.md`) fills in concrete buildings against this shared schema.

**Universal properties** (every building has these):
- **Name** — per the naming-convention design principle (tier-appropriate
  familiarity/exoticism)
- **Category** — one of the 7 Building Categories
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
  placement-validity check used for new construction (see Construction, above,
  for how a construction robot can relocate a blocking building to resolve
  this).
- **Input** — a multiset of resources/items consumed, per cycle (continuous-rate)
  or per instant-conversion (see Ration Press); may be empty. Applies uniformly
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
  An Indoor building shields its worker (settler or drone) from Atmospheric
  Hazard and Temperature Extremity for free, but **only while powered** —
  an unpowered Indoor building is treated as Outdoor. This is a separate,
  free-by-default protection channel alongside Weather/Row Shield, which
  remains how Outdoor sites/crops/workers get protected (funded shield
  coverage protects both the structure/crops *and* any outdoor worker on a
  shielded tile). If a building is destroyed mid-Mid-Sim, its worker is
  freed and returns to the roster immediately, losing whatever Indoor
  protection they had at that instant.
- **Construction cost** — resources required to build (Energy/Matter for basic
  designs, additional planet-side materials for advanced ones, per Technology &
  Progression); consumed when a construction robot begins the build
- **`TechAchievement` value** — static, design-authored score (0 for basic
  buildings, higher for advanced ones) — feeds Development Bloc (see SEED Factions
  in Win/Lose Conditions)
- **Repeatable** — whether multiple copies can be built (most can; whether any
  building should be capped at one instance is an open question)
- **Upgrade path** — none, or a defined sequence of tiers, each tier really being
  its own bundle of these same properties, unlocked via a construction-robot
  upgrade action rather than new construction

**A building's Input/Output is usually one fixed pairing, but some buildings
define more than one — "recipes."** When a building has multiple recipes,
the player selects one as the single active pairing, as a normal, reversible
planning-phase choice — distinct from (and doesn't reintroduce) the
earlier-flagged risky "automatic alternative output based on ingredient
availability" idea, since selection here is always explicit and
player-driven, never automatic/reactive to stock levels. No further
taxonomy of recipe shapes is needed: whether recipes differ in output item
(Robotics Assembly), input item (Diplomatic Gear), or output rate for the
same input/output types (Fuel-based Generator), they're all just
alternative Input/Output pairings the player chooses between — the schema
doesn't need a name for each shape.

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
  (e.g. Food Storage's stockpile capacity — see Storage). General working
  inventory is uncapped (see Inventory) and has no storage-contribution
  property; this only applies to buildings implementing a deliberate,
  limited-capacity commitment mechanic.

---

## Basic Resource Production

Every run begins with one Solar Array and one Matter Extractor (exact starting
count tied to wormhole mass-threshold stabilization tech — a meta-progression axis
— see Background Story's Faster-Than-Light Travel section). Both can be built
again (more copies) and upgraded, each consuming a grid slot, preserving the
grid's limited-slots opportunity cost.

### Solar Array
- Category: Basic Resource Production | Staffing:
  Unstaffed
- Input: none | Output: Energy per season (rate varies by planet type)
- Production cap: N/A (unstaffed)
- Construction cost: modest Energy/Matter (exact numbers TBD, deferred to a
  balancing pass)
- `TechAchievement`: 0 | Repeatable: yes | Upgrade path: yes — higher tiers
  produce more Energy; a late tier is a natural place to pay off the Crash
  Research Era's controlled-fusion lore (e.g. eventually becoming a Fusion
  Generator)
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

### Matter Extractor
- Category: Basic Resource Production | Staffing:
  Unstaffed
- Input: none | Output: Matter per season (rate varies by planet type)
- Production cap: N/A (unstaffed)
- Construction cost: modest Energy/Matter (TBD)
- `TechAchievement`: 0 | Repeatable: yes | Upgrade path: yes — higher tiers
  produce more Matter
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
  Deposit Discovery).
- Built directly on a discovered Thermal Vent deposit slot (any depth tier),
  same placement pattern as Mine/Quarry/Well.
- Input: none | Output: Energy per season, at a rate meaningfully above
  Solar Array's Volcanic-tier rate (exact numbers
  TBD, deferred to a balancing pass) — this is what actually lets a Volcanic
  run offset Weather Shield's temperature-driven Energy cost (see Planets &
  Scoring's In-Simulation Hazard Events), the original motivation for this
  building.
- Production cap: N/A (unstaffed)
- Construction cost: modest Matter/Concrete/Iron (TBD)
- `TechAchievement`: 0 | Repeatable: yes (naturally capped by how many
  Thermal Vents exist on the site, not by player choice — same pattern as
  Mine/Quarry) | Upgrade path: yes — higher tiers produce more Energy
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

*(A third Basic Resource Production building, Fuel-based Generator, lives
under Fuel below rather than here, since it's most legible alongside Forest
tiles and Clear-Cutting — its category is still Basic Resource Production.)*

---

## Farm/Production

Numbers below are a **first-pass illustrative draft**, not balanced — following
"numbers stay small," exact values are meant to be tuned empirically via
playtesting later, not over-engineered now. All buildings in this section:
Repeatable: yes, Upgrade path: yes (higher tiers reduce `production_time`
and/or raise the effort-stacking production cap), `TechAchievement` 0 at base
tier. **All require the same flat amount of Water per cycle** (see Water below —
exact amount TBD, calibrated against the settler baseline of 1 Water/season).

**Alien Soil.** The four plant-crop buildings (Grain Field, Fruit Orchard,
Fiber Field, Timber Grove — not the four animal-based buildings below) carry
a standing growth-rate penalty (illustrative -30%, TBD): Earth crops aren't
naturally suited to a foreign planet's soil. Removed for any season Fertilizer
is available (see Resources) — consumed automatically, no manual action
needed, same low-friction spirit as Water's automatic draw. Permanently
removed, with no further Fertilizer need at all, once a plant type has been
hybridized (see Hybridization, below).

### Grain Field
- Staffing: Staffed | Input: Water | Output: 1 Grain per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 2 Matter

### Fruit Orchard
- Staffing: Staffed | Input: Water | Output: 1 Fruit per cycle,
  `production_time` 4s | Production cap: 1 (base) | Construction cost: 2 Matter

### Dairy Pasture
- Staffing: Staffed | Input: Water | Output: 1 Milk per cycle,
  `production_time` 5s | Production cap: 1 (base) | Construction cost: 3 Matter

### Poultry Coop
- Staffing: Staffed | Input: Water | Output: 1 Egg per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 2 Matter

### Sheep Pasture
- Staffing: Staffed | Input: Water | Output: 1 Wool per cycle,
  `production_time` 5s | Production cap: 1 (base) | Construction cost: 3 Matter

### Fiber Field
- Staffing: Staffed | Input: Water | Output: 1 Fiber/Cotton per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 2 Matter

### Timber Grove
- Staffing: Staffed | Input: Water | Output: 1 Wood per cycle,
  `production_time` 4s | Production cap: 1 (base) | Construction cost: 2 Matter

### Trapping

Not a building — traps set on a tile for the season are just that, no
persistent structure involved. **Trapping** is a Standing Assignment (see
Settlers & Exploration), production-speed-based like a building rather than
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
- **Whether the tile currently has Forest present** (see Fuel) — unforested
  or already-clear-cut land is less habitable for prey animals, so a
  forested tile yields more than a bare one. This creates a direct,
  legible tension with Clear-Cutting: harvesting a Forest tile's Wood
  permanently reduces that same tile's future trapping potential too, since
  clear-cutting removes the habitat.

No Rations, no risk — same as any Standing Assignment. Pelt stays one
resource everywhere (see Resources), consistent with not exploding the
catalog per planet type, though its flavor name/appearance could vary
cosmetically by planet with zero mechanical effect, the same pattern
already used for Kitchen's combo-meal flavor-name pools.

### Hybridization

An exploration discovery (Site Reveal outcome — see Settlers & Exploration)
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

Ore, Stone, rare-metal, and **aquifer** (see Water) deposits are hidden by
default — most are underground, and the player must actively discover them
before they can be mined/tapped. **All deposit locations across the grid are
determined at run start** (world generation), independent of when the player
actually discovers them — discovery only reveals what's already there, it
never generates new deposits. Aquifers are binary (present/not-present) and
single-tile, exactly like the other deposit types — no varying depths.

**Thermal Vents** (see Geothermal Generator, under Basic Resource
Production) are a fifth deposit type, binary and single-tile like aquifers,
but with a new kind of restriction the other four don't have: they're
**Volcanic-exclusive** — guaranteed present (at least one) on Volcanic at
world generation, absent entirely on every other planet type, rather than
merely varying in frequency across planets the way Ore/Stone/rare-metal/
aquifer do. Skews toward Mid-depth/Deep tiers, same rarity flavor as
rare-metal deposits.

**Fossil Fuel** (see Fuel-based Generator, under Fuel) is a sixth deposit
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
worth it (see Core Loop & Grid's Construction). The rules:
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

**Basic Deposit Survey** (Standing Assignment — see Settlers & Exploration)
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
Scanner Station). The rectangle/flagging pattern is specific to
settler-performed surveys, not building-based scanning.

### Mine
- Built directly on an Iron/Copper Ore deposit slot (any depth tier, once
  discovered) | Staffing: Staffed | Input: none | Output: 1 unit of Iron Ore
  and/or Copper Ore per cycle, drawn independently per unit from the
  deposit's percentage mix, `production_time` 4s | Production cap: 1 (base) |
  Construction cost: 3 Matter + 1 Stone

### Quarry
- Built directly on a Stone deposit slot (any depth tier, once discovered) |
  Staffing: Staffed | Input: none | Output: 1 Stone per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 3 Matter

### Rare Metal Extractor
- Built directly on a rare-metal deposit slot (any depth tier, once
  discovered) | Staffing: Staffed | Input: none | Output: 1 rare metal per
  cycle, `production_time` 8s (slower, reflecting rarity) | Production cap: 1
  (base) | Construction cost: 4 Matter + 2 Stone

---

## Fuel

A deliberately *not clean* third Energy option, alongside Solar Array and
Geothermal Generator (see Basic Resource Production) — cheap and immediately
available from run start, no unlock needed, but genuinely resource-limited
and, unlike either of those two, carries a real ongoing Stewardship cost
(see Win/Lose Conditions' SEED Factions, `EmissionsRestraint`) for as long
as it's used.

**Forest tiles** are a visible-from-start terrain feature (not a hidden
Deposit Discovery type — a forest is visually obvious, no survey needed),
with count and density varying by planet type and site, shown at Farm Site
Selection (see Core Loop & Grid) alongside Surface deposits and Average
Temperature as a known feature. Each Forest tile holds a bounded quantity of
**Wood** — the same "high-yield, bounded, depletes with use" shape already
established for some Ore/Stone deposits (see Resources) — that does not
regenerate within a run once harvested. This is the *same* Wood Timber
Grove produces on an ongoing, renewable basis (see Farm/Production and
Resources) — one resource, two sources with different sustainability
profiles, not two separate items.

### Clear-Cutting
Not a building — a **Standing Assignment** (see Settlers & Exploration). No
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
  SEED Factions in Win/Lose Conditions), unlike Timber Grove's output,
  which never does — the distinction lives at the point of production, not
  on the pooled Wood itself, which is fully fungible once in inventory.

### Fuel-based Generator
- Category: Basic Resource Production | Staffing: **Unstaffed**
- **Contributes to the Energy Pool's cap unconditionally, simply by
  existing** — same as Solar Array and Geothermal Generator (see Resources'
  Energy Pool) — on the assumption it comes with its own structural
  battery, the same reasoning that lets any Energy producer smooth out
  real-time mismatches between production and consumption. Its contribution
  to Energy *income*, though, is conditional on actually burning fuel (below).
- **Planning-phase control**: the player sets this building **active or
  inactive** for the season, plus a **fuel limit** — the maximum Wood/Fossil
  Fuel it's allowed to consume that season. During Mid-Sim, if active, it
  burns for a duration determined by that limit (or by however much fuel is
  actually available, whichever binds first) against its burn efficiency —
  it doesn't necessarily run the whole season. While actively burning, it
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
  sticky planning choice; see Building Schema). Fossil Fuel gives a
  meaningfully higher Energy return per unit than Wood, which is the entire
  point of the upgrade — but see `EmissionsRestraint` below for the
  corresponding cost.
- Construction cost: cheap, common materials only (Matter/Iron, no
  High-Tech Components) — deliberately no barrier to entry, in contrast to
  Geothermal Generator's deposit-gating. Upgrade cost: TBD.
- **No further upgrade path beyond the Fossil Fuel tier.** Solar Array
  scales toward a late-game Fusion Generator payoff and Geothermal is capped
  by Vent scarcity but stays clean; this building's ceiling is "burn a
  better fuel," never "become clean" — the mechanical shape of "easier and
  faster, but not sustainable," without needing to editorialize about it in
  the text.
- `TechAchievement`: 0 (base) / slightly higher (Fossil Fuel tier) |
  Repeatable: yes | Available from run start, no unlock needed — same
  footing as Solar Array/Matter Extractor, since it needs no exotic
  materials.

---

## Water

*(Category: Utilities — see Building Categories in Resources)*

Settlers need **1 Water per settler per season** (pooled, same consumption
model as nutrition) — this is the calibration anchor for all other Water
values (production rates, Farm/Production's per-cycle need) in this section.
No sub-axes, unlike nutrition's PFCV model — Water doesn't have an equivalent
of distinct dietary needs, so a single pooled quantity is sufficient.

> **Open question:** the consequence model for a settler Water shortfall
> (mirroring nutrition's Tier-1 bulk-shortfall → death mechanic, or something
> different?) is not yet decided — flagged in `DESIGN_TODO.md`.

**No dedicated water-storage buildings** — Water sits in the ordinary
uncapped general inventory like other resources (see Storage), not a
Food-Storage-style special commitment mechanic.

**Water transport is deliberately unmodeled** — no pipes, irrigation, or
distribution system to design. Collection buildings and consumption sites
don't need spatial adjacency; the player can imagine whatever transportation
mechanism they like, with no design commitment either way — consistent with
Energy/Matter also never needing an explained distribution system.

**All collection buildings require a Water Processing Plant to function at
all** — see below. No separate "Raw Water" intermediate resource; the Plant's
mere existence is a prerequisite gate, not a conversion step.

### Water Processing Plant
- A **starting building**, present from run start like Solar Array/Matter
  Extractor — not something the player constructs. (Once a demolish-building
  mechanic exists — not yet designed — rebuilding a demolished Processing
  Plant via normal construction should become possible; flagged as a forward
  dependency, not resolved now.)
- Base tier is mechanically almost inert — no production conversion,
  Preparedness contribution, or data-gathering of its own. Its only function
  is being the required prerequisite that lets collection buildings actually
  produce Water. Still occupies a real grid slot.
- Upgrade tier unlocks **Reclamation** — a settlement-wide reduction in net
  Water consumption, folded directly into this building rather than being a
  separate structure or item (structurally similar to Vaccine Production's
  one-time-unlock shape, but gated by a tech/resource prerequisite rather
  than a data-confidence threshold — exact gate TBD).
- `TechAchievement`: 0 (base) / higher (Reclamation tier)

### Water Condenser
- Staffing: Staffed | Input: none | Output: Water per cycle (rate TBD) |
  Draws water from air/humidity. Best on Volcanic; Verdant has humidity too
  but easier direct liquid-water access (Cistern) makes condensing
  non-optimal there; Ice and Arid/Desert are too low-humidity to be
  effective.

### Ice Melter
- Staffing: Staffed | Input: none | Output: Water per cycle (rate TBD) |
  Melts surface ice/snow. Exclusive to Frozen planets — the direct
  counterpart to Water Condenser's Volcanic specialization.

### Cistern
- Staffing: Staffed | Input: none | Output: Water per cycle (rate TBD) |
  Passive rainfall collection. Best on planets with regular rainfall
  (Verdant and similar) — the "finding water is easy here" mechanism for
  hospitable planets.

### Well
- Staffing: Staffed | Input: none | Output: Water per cycle, **relatively
  low rate** | Buildable on any tile.
- Built on a tile with a **detected aquifer** (see Deposit Discovery),
  automatically becomes a **Deep Well** — same building, higher production
  rate, no separate build choice or upgrade action. The "deepening" is a
  passive consequence of the tile's property, not a player decision beyond
  choosing where to build.

---

## Scanner Station

*(consolidates the previously-separate "Weather Monitoring Station" and
"Deposit Scanner" concepts into one building, per the same consolidation logic
already applied to Robotics Assembly)*

- Category: Utilities (see Building Categories in Resources)
- Construction cost: Stone + Iron + Copper
- Base tier: Staffed. Uses the multi-recipe pattern (player selects one active
  mode, no resource inputs beyond staffing itself — per the Building Schema's
  note that Input may be empty and Output may not be a trackable resource
  item):
  - **Weather Sensing** — generates Storm Severity/Frequency and Temperature
    Extremity reports simultaneously each active season (see Exoplanet Types'
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
- `TechAchievement`: 0 (base) / higher (each upgrade tier) | Repeatable: yes
  (multiple Scanner Stations can exist, though diminishing value once deposits
  are discovered) | Upgrade path: yes, as described above
- **Upgrades may also reduce the Energy cost of manually rerolling the
  Exploration Tasks pool** (see Settlers & Exploration) — exact discount
  per tier TBD, but the connection is real: better local sensing makes a
  fresh sweep of the region cheaper.
- **One upgrade tier also permanently adds +1 to the Exploration Tasks
  pool size** (see Settlers & Exploration) — which tier TBD. A Research
  Lab project ("Expanded Reconnaissance Doctrine," see Research Lab) is
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

- Category: Utilities (see Building Categories in Resources) | Staffing: Staffed
- Input: none (beyond staffing) | Output: none in the trackable-resource
  sense — completing a research project is a permanent rule-change to a
  target building type, not an item (per the Building Schema's note that
  Output may not be a trackable resource item at all).
- Works one research project at a time; building multiple Labs allows
  parallel projects. If more than one unlocked-but-unresearched project is
  pending, the player selects which to work on — same multi-recipe
  selection pattern used elsewhere (sticky, reversible). `production_time`
  per project: TBD, some number of seasons.
- **First use case: Hybridization** (see Farm/Production) — exploration
  discoveries unlock specific per-building hybridization projects here.
- **Second use case: "Expanded Reconnaissance Doctrine"** — a research
  project permanently adding +1 to the Exploration Tasks pool size (see
  Settlers & Exploration), always available to research (not
  discovery-gated like Hybridization projects are).
- Construction cost: TBD.

---

## Food/Meal Conversion

### Kitchen
- Category: Food/Meal Conversion | Staffing: Staffed
- **Deviates from the standard multi-recipe pattern**: instead of one active
  recipe with effort stacking toward a shared cap, Kitchen has **N simultaneous
  recipe slots**, each independently staffed by one worker who selects which
  recipe *that slot* runs from the full available list — letting one Kitchen
  produce several different meals in parallel. Grid footprint scales with slot
  count (see Building Schema): **base Kitchen = 1 slot (1 worker, 1 grid
  space)**, **Upgraded Kitchen = 2 slots (2 workers, 2 grid spaces, fixed
  non-rotatable shape)**.
- Base-tier recipes — single-ingredient meals, chosen so the group together
  covers all four PFCV axes (see Food & Nutrition):
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
- `TechAchievement`: 0 (base tier) / higher (upgraded tier) | Repeatable: yes |
  Upgrade path: yes, gates the combo recipes and second recipe slot above

> **Open question:** meal expiration — deliberately deferred until meal
> consumption mechanics (per Food & Nutrition) are revisited in more depth. The
> idea of meals expiring is appealing (it would make a season's length feel more
> real) but needs a consumption-mechanic redesign to make it fun rather than
> just punishing.

### Ration Press

Produces **Rations** — the replacement for the removed Nutrient Paste
mechanic (see Settlers & Exploration's Food & Nutrition). Rations are
conceptually analogous to Nutrient Paste: densely packed, unappetizing,
meant only to sustain life — but unlike Nutrient Paste, they're a genuine
player-produced item, not an automatic settlement-wide conversion rule.

- Staffing: Unstaffed — the conversion process is
  meant to feel automatic, not labor-intensive
- **Instant conversion** (see Building Schema): the player selects a set of
  input food items during planning; resolves immediately, with output
  available the **same season** — including for exploration tasks being
  planned that same season. Repeatable within a single planning phase, no
  cap, no cooldown. Ordinary reversibility applies: selecting inputs and
  converting is undoable like any other planning action until Next Season is
  confirmed.
- Formula: `Rations = floor(min(Protein, Fat, Carbs, Vitamins across
  selected inputs) / 2)` — a real, felt inefficiency: converting to Rations
  costs roughly half the input's nutrition value versus consuming it fresh,
  and any imbalance beyond the matched minimum across the four axes is
  discarded entirely. This makes Rations valuable specifically for
  portability (required for certain exploration tasks — see Exploration
  Tasks' Assignment), not a strictly better choice than fresh consumption.
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

Robotics Assembly and Diplomatic Gear below are both examples of the
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
- Selectable recipes:
  - Construction Robot ← Iron + Copper (base tier)
  - All-Purpose Drone (Basic) ← Iron + Copper (base tier)
  - All-Purpose Drone (Advanced) ← Iron + Copper + Silicon (**requires Upgraded
    Robotics Assembly**)
  - Specialized Drone (one recipe per Experience group — see Settlers &
    Exploration's Experience for the full list) ← Iron + Copper + a
    category-flavored input (**requires Upgraded Robotics Assembly AND at
    least one existing production structure of the matching group already
    built** — no point fabricating a Farming-specialized drone before any
    farm plot exists). Never available for Research Lab, since Research is
    settler-only regardless of drone tier.
  - **Hardening upgrade** (temperature-resistant battery) — takes an
    existing drone as an assigned *resource* to the task (it's tied up,
    unavailable for its normal assignment, for the task's duration) while a
    *different* worker performs the upgrade; the same drone comes out the
    other side hardened, its identity and current battery charge carried
    through rather than being consumed and replaced by a fresh unit.
- `TechAchievement`: 0 (base tier) / higher (upgraded tier) | Repeatable: yes |
  Upgrade path: yes, gates the Advanced/Specialized recipes above

**Drones are persistent, assignable units** — settler-lite roster entries,
not consumable items once built. Every drone is assigned to exactly one
site at a time, the same as a settler (no multi-cell service footprint).

**Effort** (see Core Loop & Grid's Assignment for the general mechanic — a
per-worker multiplier on a task's base production rate, where 1.0 matches
an unmodified settler):

| Drone type | Effort |
|---|---|
| All-Purpose (Basic) | 0.5 |
| All-Purpose (Advanced) | 1.0 |
| Specialized (Basic) | 1.5 |
| Specialized (Advanced) | 2.0 |

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
  Settlers & Exploration's Experience), at a much higher Effort than even
  Advanced All-Purpose, but never Exploration or Research under any
  circumstances, same as the other two tiers.

**Battery**: every drone has an internal battery — a tracked value with a
per-drone maximum (better on higher tiers). It **resets to full for free at
the start of every season**, no cross-season tracking. Performing an
assigned task drains it over the course of Mid-Sim; if it hits zero, the
drone **briefly recharges** (~3 seconds of Mid-Sim time, roughly a fifth of
a season, possibly varying by drone type), drawing a small amount from the
settlement's Energy Pool — fully automatic, no player decision, the same
"background check against reserved Energy" pattern already established for
Weather/Row Shield funding. While recharging, the drone contributes zero
Effort. Higher-tier drones have big enough batteries that they may never
need to recharge in a normal season. If the settlement doesn't have enough
Energy to complete a recharge, it pauses at whatever percentage it reached
and resumes once available Energy reaches **twice** the amount still
needed — a buffer against flickering on and immediately back off. No
battery replacement is ever needed; this is permanent hardware, just
periodically drained and refilled. Draining is faster the further
temperature strays from the 72°F comfort target (see Planets & Scoring's
In-Simulation Hazard Events), **except for hardened drones** (see the
Hardening upgrade recipe above), which don't suffer this penalty.

**Destruction**: any worker, settler or drone, is freed and returns to the
roster when their building is destroyed. If this happens mid-Mid-Sim, they
also immediately lose whatever Indoor protection they had (see Building
Schema) and become exposed to any hazard active at that moment.

### Stone Processing
- Category: Fabrication | Staffing: Staffed
- Selectable recipes:
  - Concrete ← Stone
  - Silicon ← Stone

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

### Textile Workshop
- Category: Fabrication | Staffing: Staffed
- Selectable recipes:
  - Fabric ← Wool, or Fiber/Cotton, or Pelts (any one of the three, player
    selects which this cycle consumes)
  - Leather Boots ← Pelts + Fiber (**requires Upgraded Textile Workshop**) — a
    Luxury Good; feeds `TechAchievement` and can serve as a prerequisite/supply
    cost for specific manned exploration tasks, generalizing the earlier
    food-cost-for-expeditions idea to manufactured goods
  - **Large Backpack** ← Pelts — an exploration-task consumable (see
    Settlers & Exploration's Exploration Tasks Task Catalog): brought along
    on a Resource windfall task, it guarantees the top of that task's value
    range. Consumed on use, same precedent PPE already established for
    exploration-task consumables.

### Tinkerer's Workshop
- Category: Fabrication | Staffing: Staffed
  — Settler, Advanced All-Purpose Drone, or a Tinkerer's-Workshop-Specialized
  Drone (see Robotics Assembly) — not Basic All-Purpose, since High-Tech
  Components requires Advanced-tier eligibility
- Selectable recipes (base tier):
  - High-Tech Components ← Copper + Silicon + Iron — used as a construction-cost
    input for Protection-tier shield structures and other advanced buildings,
    creating a real multi-tier fabrication chain (Iron/Copper/Silicon → High-Tech
    Components → advanced buildings) without reintroducing merge-space
    complexity, since each step is still automatic single-recipe production
  - High-Resolution Screens ← Silicon + Copper — a Luxury Good; no functional
    use yet beyond `TechAchievement`/faction-reward value, left open
  - Portable High-Powered Scanning Equipment ← Silicon + Copper + a rare metal —
    an exploration task initiation cost, likely gating access to higher-tier/
    more-frequent Safeguard or Stewardship data-gathering missions (weather
    balloon, atmospheric probe, bio-survey, sentience-detection)
- Selectable recipes (**requires further-Upgraded Tinkerer's Workshop**):
  - Temperature-Resistant Gear ← Fabric/Leather + a rare metal — **one
    universal item covering both hot and cold** (no separate variants),
    distinct from `MatchedPreparedness` (which is about the settlement's
    structures, not what an individual carries). Exploration-task settlers
    still explicitly elect to bring it (consumed); farm-based settlers are
    covered by a **passive stock check** — any Gear sitting in general
    inventory covers everyone on the farm against Temperature Extremity, not
    consumed, not per-settler-allocated — the same pattern PPE already
    established for Atmospheric Hazard (see Protection's Medical Bay). Any
    passive-stock-check item like this one should show a visible "in use"
    indicator during season simulation when it's actively covering someone —
    a UI/Art Design note, not a mechanic.
  - Diplomatic Gear ← (Silicon + Copper) **or** (Fabric), player selects which
    input path — a prerequisite for the **Peaceful Contact** and
    **Bluff/Coercive Exploitation** approaches at First Contact (see
    Exploration Tasks' Escalation Chains)
  - **Armed Expedition Kit** ← Iron + a rare metal — one of two
    prerequisites (alongside Overwhelming Force Package, below) for the
    **Military Exploitation** approach at First Contact (see Exploration
    Tasks' Escalation Chains); deliberately named to read as practical
    expedition equipment rather than a weapons system, matching the game's
    cozy-pioneering tone
  - **Overwhelming Force Package** (new) ← High-Tech Components + a rare
    metal — the other Military Exploitation prerequisite; represents a
    genuine technological edge, not just more Armed Expedition Kits,
    consistent with the design intent that a few settlers should
    essentially never be able to force anything from an entire
    civilization without one. Exact recipe a first-pass placeholder — see
    `DESIGN_TODO.md`

### Carpenter's Shop
- Category: Fabrication | Staffing: Staffed
  (Settler or all-purpose drone — simpler craft work, no research requirement)
- Selectable recipes:
  - Fine Furniture ← Lumber — a Luxury Good, pure flavor/`TechAchievement`
    reward, no functional use
  - Ornamental/Decorative Items ← Lumber + Stone/Concrete — same tier as Fine
    Furniture
- Left with room to grow — upgrade path can add functional recipes later
  without redesigning the building

---

## Protection

Backs `MatchedPreparedness(Weather)` and `MatchedPreparedness(Bio-hazard)` for
the Safeguard Coalition (see Win/Lose Conditions' SEED Factions). Also
resolves the "Medical/Vaccine production" gap: Bio-hazard preparedness lives
here too, not as a separate category — Protection is about protecting the
settlement from a planetary danger generally, whether physical (weather) or
biological.

Each building's **Preparedness contribution** is expressed on the same rough
0–1 scale as `TrueRisk` (see Exoplanet Types' Hazard Priors), so that a
reasonable number of buildings can plausibly reach or exceed a planet's true
risk level and hit `MatchedPreparedness`'s cap of 1. Exact numbers TBD,
deferred to a balancing pass — following "numbers stay small," these are
first-pass illustrative values.

**Multi-slot footprints aren't only about worker capacity.** The Building
Schema's rule that grid-slot count equals worker-assignment capacity (see
Kitchen) has its first exception here: Row Shield below occupies 2 slots for
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
  number — see Planets & Scoring's In-Simulation Hazard Events for the full
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
- `TechAchievement`: 0 (base) / higher (upgraded) | Repeatable: yes (multiple
  can be built for wider coverage) | Upgrade path: yes — larger radius, more
  Preparedness credit
- No data-gating on its Preparedness contribution — a physical shield works
  regardless of whether the settlement has measured how bad the weather
  actually is. This is an intentional asymmetry with Medical Bay below, not
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
  (see Planets & Scoring's In-Simulation Hazard Events)
- **Preparedness contribution**: Weather axis, same shape as Weather Shield's
  base tier
- Construction cost: strictly between Weather Shield's base cost and
  (Weather Shield base + Advanced upgrade) combined — exact numbers TBD
- `TechAchievement`: 0 | Repeatable: yes

### Medical Bay
- Staffing: Staffed — Settler, Advanced All-Purpose Drone, or a
  Medical-Bay-Specialized Drone (see Robotics Assembly) for PPE and Vaccine
  Production; medical research specifically stays settler-only, the same
  rule as Research Lab
- **Base tier**: provides baseline `Preparedness(Bio-hazard)` credit
  (general medical readiness — illustrative: 0.2) — available immediately,
  no data prerequisite.
- **Vaccine Production tier**: a **genuine functional gate**, not just a
  scoring nuance — only buildable once `Confidence(Bio-hazard)` (from
  Safeguard's Beta-distribution data-gathering mechanism, see Exoplanet
  Types) crosses a threshold (illustrative: 0.5, TBD). This directly
  realizes the earlier-established rule that an effective, pathogen-specific
  vaccine can't be produced without first characterizing the actual
  pathogen. Once unlocked, provides substantially higher Preparedness credit
  (illustrative: 0.7). This is deliberately **not** implemented as
  `Preparedness` itself continuously scaling with `Confidence` — that would
  double-apply the same gating the `Score(hazard)` formula's own
  `MatchedRisk × MatchedPreparedness` term already provides. Instead it's a
  discrete build-order gate: a tier either exists (available) or doesn't.
  **A static one-time unlock, not a recurring production/consumption
  item** — once unlocked, the settlement is assumed fully vaccinated against
  that specific pathogen (vaccines are always targeted to the pathogen a
  specific bio-survey exploration task discovered), and the building simply
  provides its Preparedness credit from then on with no ongoing cost.
  Unlocking a vaccine for a given pathogen also triggers a **new exploration
  escalation** — a task to explore the specific region where that pathogen
  was originally found, previously too dangerous, now safe (see Exploration
  Tasks' Escalation Chains for the worked example).
  **The unlock is a permanent settlement-wide fact, not tied to the Medical
  Bay's continued existence** — everyone is already vaccinated the moment it
  unlocks, so even if the building is later destroyed (see In-Simulation
  Hazard Events' Storm consequences), that fact doesn't un-happen. Rebuilding
  Medical Bay afterward restores its Preparedness/PPE functions, not the
  vaccine itself, since there's nothing to restore.
- **Energy upkeep**: ordinary flat per-season baseline, same rule as every
  other building (see Basic Resources above) — Medical Bay isn't one of the
  two AOE shield structures, so it doesn't get the variable event-driven cost.
- **PPE recipe** (Personal Protective Equipment — breathing masks, hazard
  suits, etc.): Fabric → PPE, an ordinary **recurring** staffed production
  recipe, available from the base tier with no `Confidence`-gating (PPE is
  generic protective gear, not pathogen-specific, unlike Vaccine
  Production). Addresses **Atmospheric Hazard** specifically — the one
  Weather sub-factor with no preparedness mitigation until now. Doesn't
  compete with Vaccine Production for a "slot," since Vaccine Production is
  a permanent tier unlock, not a recurring recipe.
  - **Fully resolved** — see Planets & Scoring's In-Simulation Hazard Events
    for the complete mechanism. Summary: farm-based settlers are protected by
    a passive stock check (any PPE in general inventory, not consumed);
    exploration-task settlers require explicitly electing to send PPE when
    initiating the task (consumed, a real optional cost distinct from
    mandatory prerequisites like Diplomatic Gear or Portable Scanning
    Equipment). Exposure without PPE in either context inflicts a status
    effect: fixed duration, halves the settler's effectiveness in all tasks,
    and locks them out of exploration-task assignment while active.
- **Emergency Medical Kit recipe** (new): Fabric + High-Tech Components →
  Emergency Medical Kit, an ordinary **recurring** staffed production
  recipe alongside PPE, no `Confidence`-gating (generic rescue/trauma
  gear, not pathogen-specific). Consumed on use; brought optionally on the
  Unknown Radio Signal exploration task (see Settlers & Exploration's Task
  Catalog) to guarantee a successful rescue if the signal turns out to be
  a genuine distress call.
- Construction cost: Fabric + basic materials (base tier); Vaccine
  Production tier additionally requires **High-Tech Components**
- `TechAchievement`: 0 (base) / higher (Vaccine Production tier) |
  Repeatable: yes | Upgrade path: yes, as described above

---

## Storage

General working inventory needs no dedicated Storage buildings at all — it's
fully uncapped (see Inventory below). The one deliberate exception is **Food
Storage**, which exists specifically to give the Sustenance Bloc's
`NutritionStockpile` term a real, felt tradeoff rather than a passive byproduct
of surplus production.

### Food Storage
- Staffing: Unstaffed (depositing food is a
  planning-phase action, not ongoing labor)
- Accepts food items (raw ingredients + prepared meals) deposited into it,
  reusing the existing "assign food" planning-action pattern rather than
  inventing new UI. Depositing is a normal **reversible planning action until
  the season is confirmed** — but once simulation runs, that food is genuinely
  committed: **removed from the general available/usable pool for the rest of
  the run** (no longer usable for consumption or anything else).
- Once stored, individual food identity is discarded — only the **sum of
  nutrient values** (across the four PFCV axes) is retained, feeding directly
  into `NutritionStockpile`.
- **Uncommitted food sitting in general inventory contributes nothing to
  `NutritionStockpile`** — only food actually deposited here counts. This
  makes Food Storage a hard requirement for any real Sustenance score, not an
  optional bonus. (`NutritionIncome`, the other half of the Food Security
  formula, is unaffected by this — it measures raw production rate regardless
  of what becomes of the output, since it represents productive *capacity*,
  not a secured reserve.)
- **Storage contribution**: a real, limited capacity (in nutrient-value units),
  **deliberately scaled so the unupgraded building cannot reach a maximum
  `NutritionStockpile` score even completely full** — forcing upgrades (or
  multiple Food Storage buildings) as a genuine ongoing investment, not a
  one-time build-and-forget structure. Exact capacity numbers TBD, deferred to
  a balancing pass.
- Construction cost: modest Matter (TBD) | `TechAchievement`: 0 (base) /
  higher (upgraded tiers) | Repeatable: yes | Upgrade path: yes, raises
  capacity

---

## Inventory

- All crafted items and pieces removed from the grid go to a **general
  inventory** — a single shared pool, not tied to any specific building; the
  inventory also serves as the off-grid holding area (workspace) during
  planning
- **Fully uncapped** — no capacity limit, no storage-contribution buildings
  needed to hold ordinary working resources (raw materials, manufactured
  goods, food not yet committed to Food Storage — see Storage below). This
  supersedes the old capacity-limited model entirely: there is no prioritization
  list, no overflow state, and no overflow-into-Matter breakdown mechanic —
  nothing ever needs to be discarded or converted for lack of space. Reflects
  the general design goal of keeping ordinary resource-holding low-effort and
  low-interaction; the one deliberate exception is Food Storage, a dedicated
  building that requires real investment (see Storage below).
- The inventory is a **list**, not a spatial arrangement — the player never has
  to pack items into storage physically
