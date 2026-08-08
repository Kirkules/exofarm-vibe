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

### Building Categories
1. **Basic Resource Production** — Energy and Matter generation; zero-effort/unstaffed.
2. **Farm/Production** — crops, animal products, and mining, staffed sites (see
   Baseline Farm/Mined Resources below).
3. **Food/Meal Conversion** — turns raw farm output into meals with nutrient profiles
   (see Food & Nutrition).
4. **Robotics/Fabrication** — staffed site producing drones and additional
   construction robots (see Platform & Core Loop Redesign's Construction and Worker
   Assignment sections).
5. **Protection** — force-field/weather-protection structures; the AOE system that
   survived alongside drone footprints. Carries a passive Energy upkeep cost scaling
   with how extreme the planet's ambient temperature is (near-zero on temperate
   planets, significant on very hot or very cold ones) — always explicitly listed
   when it has an impact, never a hidden drain (see Planet Types below).
6. **Storage** — contributes inventory capacity, carried over from the original
   design.
7. **Exploration Support** — buildings tied to expedition supplies or the
   filament-scanning lore, if warranted as distinct from the Exploration Tasks
   system itself (not yet designed).

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
- **Iron** and **Copper** — refined from distinct Iron Ore and Copper Ore deposits
  (differentiated at the source, not from a generic "Ore"). A single site can have
  multiple ore kinds mixed in some percentage distribution (e.g. 70% Iron / 30%
  Copper); each unit mined is an independent random draw from that distribution —
  fine since this randomness resolves during simulation, not planning, per the
  reversibility principle. Iron: structural strength (robot bodies). Copper:
  electronics components.
- **Stone** — raw material for basic construction, distinct from **Silicon**, which
  is refined/extracted from the same Stone resource for electronics fabrication.
- **Rare metals** — findable on any planet, but with probability strongly biased by
  planet type. Needed for high-tech applications, including energy-shielding
  devices. Governed by a standing planet-design principle (see Planet Types below):
  a planet's dominant hazard and the materials that counter it are positively
  correlated, but only as a correlation, not a guarantee — a temperate planet can
  still yield them, just less often.
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
- **Staffing** — Unstaffed (zero-effort) or Staffed (requires a worker; if
  staffed, which worker types qualify — Any/Settler-only/specific drone category)
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

**Conditional properties** (apply depending on category/function):
- **Production conversion** — input(s)+quantities → output(s)+quantities, plus
  `production_time` (continuous-rate cooldown, per the Production Model in
  Platform & Core Loop Redesign). Applies to Basic Resource Production,
  Farm/Production, Food/Meal Conversion, Robotics/Fabrication. Inputs may be
  empty beyond passive Energy upkeep and/or staffing itself, and outputs may not
  be a trackable resource item at all (e.g. data reports for a Weather Monitoring
  Station, or a buff/boost effect for a drone-control structure). **Alternative:
  instant conversion** (see Ration Press) — the player selects inputs directly
  during planning and the conversion resolves immediately, with no
  `production_time`, no staffing, and no rate limit; ordinary planning
  reversibility still applies (undoable like any other planning action until
  Next Season is confirmed).
- **Production cap** — max per-cycle output requiring multiple workers'/drones'
  effort to reach (effort-stacking, per Worker Assignment). Only meaningful for
  **staffed** sites, since it's inherently about worker effort reaching a
  ceiling — unstaffed buildings just produce a flat per-tier rate.
- **Area of effect** — coverage radius/shape for Protection buildings
  specifically. **Not the same as worker/drone service footprint** — that belongs
  to the *worker*, not the building (see Worker Assignment); both are spatial
  coverage systems but attach to different entities.
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
- Production conversion: no resource input → Energy output per season (rate
  varies by planet type)
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
- Production conversion: no resource input → Matter output per season (rate
  varies by planet type)
- Production cap: N/A (unstaffed)
- Construction cost: modest Energy/Matter (TBD)
- `TechAchievement`: 0 | Repeatable: yes | Upgrade path: yes — higher tiers
  produce more Matter
- Area of effect / Energy upkeep / Preparedness / Data-gathering / Storage: N/A

---

## Farm/Production

Numbers below are a **first-pass illustrative draft**, not balanced — following
"numbers stay small," exact values are meant to be tuned empirically via
playtesting later, not over-engineered now. All buildings in this section:
Repeatable: yes, Upgrade path: yes (higher tiers reduce `production_time`
and/or raise the effort-stacking production cap), `TechAchievement` 0 at base
tier. **All require the same flat amount of Water per cycle** (see Water below —
exact amount TBD, calibrated against the settler baseline of 1 Water/season).

### Grain Field
- Staffing: Staffed | Production: Water → 1 Grain per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 2 Matter

### Fruit Orchard
- Staffing: Staffed | Production: Water → 1 Fruit per cycle,
  `production_time` 4s | Production cap: 1 (base) | Construction cost: 2 Matter

### Dairy Pasture
- Staffing: Staffed | Production: Water → 1 Milk per cycle,
  `production_time` 5s | Production cap: 1 (base) | Construction cost: 3 Matter

### Poultry Coop
- Staffing: Staffed | Production: Water → 1 Egg per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 2 Matter

### Sheep Pasture
- Staffing: Staffed | Production: Water → 1 Wool per cycle,
  `production_time` 5s | Production cap: 1 (base) | Construction cost: 3 Matter

### Fiber Field
- Staffing: Staffed | Production: Water → 1 Fiber/Cotton per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 2 Matter

### Timber Grove
- Staffing: Staffed | Production: Water → 1 Wood per cycle,
  `production_time` 4s | Production cap: 1 (base) | Construction cost: 2 Matter

### Trapper's Den
- Staffing: Staffed | Production: Water → 1 Pelt per cycle,
  `production_time` 6s (slower, reflecting rarity) | Production cap: 1 (base) |
  Construction cost: 3 Matter

---

## Deposit Discovery

Ore, Stone, rare-metal, and **aquifer** (see Water) deposits are hidden by
default — most are underground, and the player must actively discover them
before they can be mined/tapped. **All deposit locations across the grid are
determined at run start** (world generation), independent of when the player
actually discovers them — discovery only reveals what's already there, it
never generates new deposits. Aquifers are binary (present/not-present) and
single-tile, exactly like the other deposit types — no varying depths.

**Three depth tiers:**
- **Surface** — visible from run start, immediately buildable with no discovery
  needed. **Guarantee**: every run has at least one Stone, Iron, or Copper
  deposit at Surface tier, so the player always has an immediate mining option.
- **Mid-depth** — hidden; found via Basic Deposit Survey or Deep Survey.
- **Deep** — hidden; found only via Deep Survey or a Scanner Station's Deposit
  Scanning mode. Skews toward rare-metal deposits specifically, not just more
  Iron/Copper/Stone.

**Basic Deposit Survey** (exploration task) — commonly available early.
Requires modest basic tools (small resource cost, TBD). On success: guarantees
1 undiscovered Mid-depth deposit revealed (if any exist), then independently a
0.6 chance **per remaining** undiscovered Mid-depth deposit. A discrete Site
Reveal outcome, same category already established under Exploration Tasks.
Guarantees a follow-up escalation to Deep Survey (per Escalation Chains).

**Deep Survey** (exploration task) — requires **Portable High-Powered Scanning
Equipment** (reusing the existing Tinkerer's Workshop item rather than
inventing a new one). On success: guarantees 1 undiscovered Mid-depth deposit
revealed (if any remain) **and** 1 undiscovered Deep deposit revealed (if any
exist) — two independent guarantees — then independently a 0.9 chance per
remaining undiscovered Mid-depth deposit and a 0.5 chance per remaining
undiscovered Deep deposit. **Repeatable** — a single attempt likely won't
reveal everything at the 0.5 Deep-tier rate, so doing it again has real value.
Once unlocked via the Basic Survey escalation, it becomes a normal recurring
exploration-pool candidate — if discarded via reroll, it resurfaces in later
opportunities without needing to redo the escalation chain.

### Mine
- Built directly on an Iron/Copper Ore deposit slot (any depth tier, once
  discovered) | Staffing: Staffed | Production: no input → 1 unit of Iron
  and/or Copper per cycle, drawn independently per unit from the deposit's
  percentage mix, `production_time` 4s | Production cap: 1 (base) |
  Construction cost: 3 Matter + 1 Stone

### Quarry
- Built directly on a Stone deposit slot (any depth tier, once discovered) |
  Staffing: Staffed | Production: no input → 1 Stone per cycle,
  `production_time` 3s | Production cap: 1 (base) | Construction cost: 3 Matter

### Rare Metal Extractor
- Built directly on a rare-metal deposit slot (any depth tier, once
  discovered) | Staffing: Staffed | Production: no input → 1 rare metal per
  cycle, `production_time` 8s (slower, reflecting rarity) | Production cap: 1
  (base) | Construction cost: 4 Matter + 2 Stone

---

## Water

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
- Staffing: Staffed | Production: no input → Water per cycle (rate TBD) |
  Draws water from air/humidity. Best on Volcanic; Verdant has humidity too
  but easier direct liquid-water access (Cistern) makes condensing
  non-optimal there; Ice and Arid/Desert are too low-humidity to be
  effective.

### Ice Melter
- Staffing: Staffed | Production: no input → Water per cycle (rate TBD) |
  Melts surface ice/snow. Exclusive to Frozen planets — the direct
  counterpart to Water Condenser's Volcanic specialization.

### Cistern
- Staffing: Staffed | Production: no input → Water per cycle (rate TBD) |
  Passive rainfall collection. Best on planets with regular rainfall
  (Verdant and similar) — the "finding water is easy here" mechanism for
  hospitable planets.

### Well
- Staffing: Staffed | Production: no input → Water per cycle, **relatively
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

- Construction cost: Stone + Iron + Copper
- **Category doesn't cleanly fit any of the 7 established Building Categories**
  (data-gathering/sensing isn't quite Basic Resource Production, Farm/Production,
  or Exploration Support as currently scoped) — flagged in `DESIGN_TODO.md` as
  a categorization gap to resolve later, not blocking design work now.
- Base tier: Staffed. Uses the multi-recipe pattern (player selects one active
  mode, no resource inputs beyond staffing itself — per the Building Schema's
  note that production conversion inputs may be empty and outputs may not be a
  trackable resource item):
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

## Robotics/Fabrication

Designed by working backward from what fabrication actually needs to consume,
which in turn confirmed uses for every raw material already listed in Resources
(Iron, Copper, Stone, Silicon, Wool, Fiber/Cotton, Wood, Pelts, rare metals) and
introduced several new intermediate/luxury resources: **Fabric**, **Concrete**,
**High-Tech Components**, **High-Resolution Screens**, **Portable High-Powered
Scanning Equipment**, **Leather Boots**, **Temperature-Resistant Gear**,
**Diplomatic Gear**, **Fine Furniture**, and **Ornamental/Decorative Items**.

**Schema addition — multi-recipe buildings.** A building can have more than one
possible production conversion ("recipe"). The player **selects which single
recipe is active**, as a normal, reversible planning-phase choice — this is
distinct from (and doesn't reintroduce) the earlier-flagged risky "automatic
alternative output based on ingredient availability" idea, since selection here
is always explicit and player-driven, never automatic/reactive to stock levels.
This applies in two forms:
- **Multiple distinct outputs from one building** (e.g. Robotics Assembly's
  Construction Robot vs. Drone recipes) — the player picks which output this
  building currently produces.
- **Multiple alternative input sets converging on the same output** (e.g.
  Diplomatic Gear, buildable via either an electronics path or a textile path) —
  the player picks which input combination this cycle consumes.

### Robotics Assembly
*(consolidated — a separate Construction Bay and per-category specialized-drone
buildings were considered and rejected: committing a worker and resources to a
rarely-needed unit like a construction robot at a wholly separate structure felt
like too many commitments for something that basic, and drones are multi-use,
sticking around once built rather than needing constant replacement — so one
consolidated building with selectable recipes fits better)*
- Category: Robotics/Fabrication | Staffing: Staffed
  (Settler or all-purpose drone)
- Selectable recipes:
  - Construction Robot ← Iron + Copper (base tier)
  - All-Purpose Drone (Basic) ← Iron + Copper (base tier)
  - All-Purpose Drone (Advanced) ← Iron + Copper + Silicon (**requires Upgraded
    Robotics Assembly**)
  - Specialized Drone (one recipe per job category — Grain/Fruit/Food,
    Lumber/Cotton, animal products, etc.) ← Iron + Copper + a category-flavored
    input (**requires Upgraded Robotics Assembly AND at least one existing
    production structure of the matching job category already built** — no
    point fabricating a Grain/Fruit harvester drone before any such farm plot
    exists)
- `TechAchievement`: 0 (base tier) / higher (upgraded tier) | Repeatable: yes |
  Upgrade path: yes, gates the Advanced/Specialized recipes above

### Stone Processing
- Category: Robotics/Fabrication | Staffing: Staffed
- Selectable recipes:
  - Concrete ← Stone
  - Silicon ← Stone

### Textile Workshop
- Category: Robotics/Fabrication | Staffing: Staffed
- Selectable recipes:
  - Fabric ← Wool, or Fiber/Cotton, or Pelts (any one of the three, player
    selects which this cycle consumes)
  - Leather Boots ← Pelts + Fiber (**requires Upgraded Textile Workshop**) — a
    Luxury Good; feeds `TechAchievement` and can serve as a prerequisite/supply
    cost for specific manned exploration tasks, generalizing the earlier
    food-cost-for-expeditions idea to manufactured goods

### Tinkerer's Workshop
- Category: Robotics/Fabrication | Staffing: Staffed
  — Settler or a specialized research/data-capable drone tier (a new drone
  specialization distinct from harvester-type production drones, not yet fully
  designed — flagged for Worker Assignment later)
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
  - Temperature-Resistant Gear ← Fabric/Leather + a rare metal — a prerequisite
    or risk-reducer for exploration tasks on hazardous-temperature planets
    (Volcanic, Frozen), distinct from `MatchedPreparedness` (which is about the
    settlement's structures, not what an individual expedition carries)
  - Diplomatic Gear ← (Silicon + Copper) **or** (Fabric), player selects which
    input path — a prerequisite for the **Peaceful Contact** branch of the
    sentience-contact chain (see Exploration Tasks' Escalation Chains)

### Carpenter's Shop
- Category: Robotics/Fabrication | Staffing: Staffed
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
  the original design's "weather bubble" precedent) covering nearby
  Farm/Production cells — upgradeable to a larger radius
- **Energy upkeep**: scales with the planet's ambient temperature extremity,
  per the temperature-coupling mechanic (see Exoplanet Types) — always
  explicitly displayed, never hidden
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
- **Energy upkeep**: same temperature-coupling mechanic as Weather Shield
- **Preparedness contribution**: Weather axis, same shape as Weather Shield's
  base tier
- Construction cost: strictly between Weather Shield's base cost and
  (Weather Shield base + Advanced upgrade) combined — exact numbers TBD
- `TechAchievement`: 0 | Repeatable: yes

### Medical Bay
- Staffing: Staffed
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
