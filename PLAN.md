# ExoFarm — Game Plan
**Title: ExoFarm**

## Overview

**Engine:** Godot v4.6.1
**Genre:** Single-player roguelike grid-based farm settlement builder
**Reference:** Backpack Brawl (grid/inventory UI inspiration)
**Tone:** Cozy with low-level survival tension. Easy to pick up and start a run. Forgiving
season-to-season, but critical failures are possible. The feeling is pioneering optimism,
not desperate survival.

---

## Premise

A small team of human settlers is sent to an exoplanet ahead of a potential larger
colonization effort. Their mission: determine whether humans could live and farm there.
The player manages their farm settlement across a finite number of seasons, ultimately
producing a "report" — a score representing how well humanity could thrive on that world.

The player's home base is Earth (or an Earth-adjacent hub), from which all runs are
launched. Each run is a different exoplanet. There is always another planet to explore;
the game never signals "you are done."

Faster-than-light travel (via wormhole or similar) is established technology in this
setting. The settlement maintains contact with Earth throughout each run.

---

## Design Principles

- **Numbers stay small.** Human-readable quantities at all times. A basic crop plot
  produces 1 unit per season. A starting team is 3–4 settlers. End-of-run production
  might reach ~100 of a resource per season at most. Numbers never explode into
  thousands or millions.
- **Units are unspecified.** Let the player infer real-world equivalents. Avoid labeling
  quantities with units wherever possible.
- **UI interaction is minimal.** Planning and decision-making dominate. UI friction is
  as low as possible.
- **Planning phase is reversible.** All decisions during planning can be undone until the
  player confirms "Proceed to Next Season."
- **Familiar players can complete planning in ~30 seconds.**
- **Naming convention:** Simple, familiar names for basic things (Energy, Matter).
  Technical or exotic names reserved for advanced/unusual items
  (e.g. "Flux-modulated Drone Battery"). Unfamiliar words signal high technology.

---

## Run Structure (Roguelike)

- Each run is a **fresh start** on a new exoplanet.
- Runs last a maximum of **15 seasons** (working value; may vary by planet type and will
  be tuned after playtesting).
- A run ends early on **critical failure**: total farm destruction, settler starvation,
  or similar catastrophic events.
- A successful run ends with a **score** representing quality of life, resource richness,
  safety, settler happiness, and other factors — functioning as a "viability report" for
  humanity's potential colonization of that planet.

---

## Meta-Progression & Earth Hub

The Earth hub is the persistent home base between runs. It represents humanity's
growing body of knowledge from all completed expeditions.

### Design Catalog
- Earth already knows how to make everything — settlers arrive with **blueprints for all
  known designs**. What limits them is access to the required **planet-side materials**.
- As the game progresses across multiple runs, the catalog **grows**: discovering and
  gathering enough of a previously-unseen resource type during a run prompts Earth's
  designers to develop new designs using that material, unlocking them for future runs.
- This is the primary meta-progression mechanic: **resource discovery → new designs
  unlocked.**
- Story framing: Earth didn't have reason or opportunity to develop these designs before.
  The expedition's discovery creates the impetus.

### Earth Hub Contents
- **Recipe browser** — all known merge-space recipes, organized by building type;
  reflects current meta-progression unlocks
- **Exoplanet catalog** — available planet types with their conditions and features;
  used to choose the next run (or opt into random selection)
- **Run history** — summary of past runs: planet visited, score, key outcomes
- **Start run** — launch into a new expedition

### Backstory
A second technological revolution on Earth produced faster-than-light (non-velocity-based)
travel — allowing humans to reach other star systems within a human lifetime at great
expense. This same event accelerated climate change on Earth to an irreversible degree,
leaving the planet with several hundred years before it becomes uninhabitable.

In response, **SEED** (Survival and Emigration Expedition Dispatch) was established to
find a suitable new home for humanity. ExoFarm's expeditions are its advance missions:
small settler teams sent to candidate exoplanets to determine whether humans could
farm and live there before any large-scale colonization effort is committed.

The game is not about terraforming — it is about finding a planet already suitable
enough for human life. Each run's viability report score is a direct contribution to
that search.

> Organizing body: **SEED** — Survival and Emigration Expedition Dispatch

**Phase 5+ addition:** A hub mini-game for scanning/searching for exoplanets with
specific property combinations. More favorable target = harder mini-game, sometimes
impossible.

---

## The Grid

The farm is laid out on a **grid of land plots**. Each cell holds one slot of content.

### Piece Categories

**Buildings**
- Fixed to their grid position by default (must be removed and re-placed to move;
  certain upgrades can make specific buildings moveable)
- No neighbor effects by virtue of being a building — any spatial effects are specific
  to that individual building's design
- Examples: solar rig, matter manipulator, weather protection station, drone station,
  storage facility

**Other placeable pieces** (crops, animal pens, modules, etc.)
- Moveable by default during planning phase
- May have neighbor effects specific to their type

### Fixed/Environmental Slots
- Impassable terrain (mountains, lakes)
- Permanent resource locations (e.g. metal ore, rare mineral deposits)
- Set at run start; cannot be moved or removed

### Multi-Slot Pieces (Polyominoes)
- Many placeable elements occupy **multiple grid slots** in irregular shapes
- Example: a 2×2 storage facility; a T-shaped weather station (1 center + 3 adjacent)
- Pieces can be **rotated** in 90° increments
- Orientation affects **direction of effects** and which neighbors a piece synergizes with
  or links to

### Neighbor Effects
- Elements affect nearby slots based on **Manhattan distance**
- Example: a weather bubble covers crop slots within distance 2
- **Visual overlays** show fields of effect during planning at all times (not just on
  hover)

---

## Season Structure

Each game round = one **season** on the planet.

### Planning Phase (~30 seconds for a familiar player)
- Player places, rotates, and rearranges elements on the grid
- All moves are **fully reversible** until "Proceed to Next Season" is confirmed
- **Moveable pieces** can be picked up (freeing their slots) and placed elsewhere or
  returned to the **inventory** (no separate workspace area — the inventory serves as
  the off-grid holding area)
- **Fixed pieces** (buildings) must be removed and re-placed; upgrades can make
  specific buildings moveable
- Rich visual feedback: effect overlays, synergy indicators, coverage areas
- Tooltips and contextual information throughout
- Player can **toggle buildings on/off** at any time during planning to manage power

### Simulation Phase (~15 seconds baseline)
- **Passive** — no player input required (may evolve later)
- Settler sprites (ColorRect) walk from Solar Rig to greenhouses and back in real time;
  speed = 2 grid-units/sec; each arrival = one tending operation; `tend_per_yield`
  tend operations = one crop yield
- Season progress bar (16px, above grid) with elapsed-time readout
- **Live log overlay** (between HUD and progress bar): last 6 entries shown as events occur,
  with timestamps in `(X.Xs)` format
- **Outcome log** button ("log") in HUD: full log accessible after simulation; cleared at
  start of each new simulation
- Playback speed: **1×, 2×, 3×, 5×** — **not yet implemented**
- Results feed into the next planning phase
- Building on/off toggle **not available** during simulation

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

---

## Resources

### Basic Resources (regenerate each season)
- **Energy** — produced by the solar rig; rate varies by planet (sun brightness/distance)
- **Matter** — produced by the matter manipulator; rate varies by planet; raw input
  collection is fully automatic (the extractor comes with a small drone that collects
  rocks/dirt)

### Planet-Side Materials & Other Non-Basic Resources
- All non-basic resources — planet-side materials, crop outputs, animal products, rare
  exploration finds, etc. — exist as **inventory items**, not as tracked resource
  counters
- Used as crafting ingredients in merge-space recipes, or placed into dedicated building
  slots (analogous to meals in the Cafeteria consumption area)
- Planet-side materials are specific to each exoplanet type; found in fixed terrain
  deposits; required for advanced designs; vary by planet
- Discovering a new material type in a run may unlock new catalog designs permanently

### Naming Convention
- Basic resources: simple names (Energy, Matter)
- Advanced/rare items: technical compound names (e.g. "Flux-modulated Drone Battery")
- Planet-side materials: can use less familiar names (e.g. "Iridite") since they are
  rarer and encountered later in play

---

## Starting Buildings

Every run begins with two fixed 1-slot buildings on the grid:

### Solar Rig
- Produces and stores **Energy** each season
- Production rate varies by planet type
- Functions as a power source with a Manhattan-distance broadcast range
- Upgradeable versions increase production rate

### Matter Manipulator
- Produces and stores **Matter** each season
- Production rate varies by planet type
- Raw input collection is automatic (built-in drone collects rocks/dirt)
- Also serves as the **initial fabrication structure** via its merge-space pop-up
- Automatically **breaks down overflow inventory items** into Matter at the start of
  season simulation; Matter recovered = proportional to item's inventory slot count
  (no player interaction required for breakdown)
- Upgradeable versions increase production rate

---

## Power System

### Overview
- **Only buildings** interact with the power system directly
- Non-building pieces (crops, etc.) are unaffected by power
- Elements like farming drones are extensions of their associated building and inherit
  its powered/unpowered state

### Power Sources
All power-providing buildings broadcast power within a **Manhattan-distance range**.
Any building within range is automatically powered — no explicit connection needed.
Power sources can also **relay** power: if two power sources' ranges overlap or chain,
they form a single **power network**.

Types of power sources:
- **Solar rig** (starting building) — passive; output varies by planet
- **Fuel-based power buildings** — higher output than solar; consume planet-side
  resources each season as fuel; unlocked via resource-gated tech progression
- **Batteries** — single-use; manufactured by consuming power (like a building drawing
  from the grid); used in two ways:
  - Dragged onto a non-grid-connected building to power it for one season
  - Dragged onto a power source building to supplement a grid's pool for one season
  - Both uses deplete the battery after one season
  - Placement (and removal) of batteries is fully reversible during planning

### Power Networks
- A power network = a connected component of power source buildings
- The network has a **shared pool** equal to the sum of all sources in it
- Any power-drawing building within range of **any node** in the network draws from
  the shared pool
- Visual representation: the combined range of a network appears as a single unified
  coverage area (not individual overlapping shapes)

### Power State
- Power is **binary per building**: fully powered or dormant (no partial power)
- An unpowered building is generally dormant (exceptions possible but none planned yet)
- If total power draw exceeds supply, some buildings go unpowered

### Player Control
- Players manage power shortfalls by **toggling buildings off** (reducing their draw
  to 0)
- Toggle is available any time **outside of season simulation**
- No automatic rationing — the player decides which buildings receive power

---

## Interaction Hierarchy (Fixed Buildings)

Fixed (non-moveable) buildings respond to three tap/touch gestures, in increasing
"weight" of interaction:

| Gesture | Threshold | Action |
|---------|-----------|--------|
| **Single tap** | Two distinct press+release events with only one tap registered | Tooltip / info pop-up (not yet implemented) |
| **Double tap** | Two taps on the same piece within 0.5 s | Toggle building on/off (power draw to 0 or normal) |
| **Tap-hold** | Press held for ≥ 0.5 s without release | Open building's merge/crafting UI (not yet implemented) |

Implementation notes:
- The 0.5 s double-tap window matches the 0.5 s hold-pickup threshold used by
  moveable pieces — consistent feel across interactions
- A slight delay before a "single tap" fires is acceptable at this stage; will be
  revisited if it feels sluggish in playtesting
- Drag beyond PICKUP_DRAG_THRESHOLD_SQ (16 px) during a tap DOWN cancels the tap
  (avoids accidental toggles when the player is panning or misses a piece)

---

## Inventory

- All crafted items and pieces removed from the grid go to a **general inventory** —
  a single shared pool, not tied to any specific building; the inventory also serves
  as the off-grid holding area (workspace) during planning
- **Inventory capacity** = sum of storage contributions from all buildings on the grid;
  each building contributes a flat number of slots
- Items have a **slot size** (matching their footprint in merge spaces); this is how
  much inventory space they consume
- The inventory is a **list**, not a spatial arrangement — the player never has to
  pack items into storage physically

### Inventory UI
- Displayed as a **compact list**, always visible alongside merge-space pop-ups
- Each item has a **"send to top" / "send to bottom"** button for prioritization
- Items are prioritized from the top of the list; the first N slots-worth of items are
  kept each season
- Items beyond capacity are **highlighted with a red background** indicating they will
  be sent to the Matter Manipulator at the start of season simulation
- Matter recovered from breakdown = proportional to the item's slot count (same for
  all items of the same size, regardless of type)

---

## Crafting & Merge Spaces

### Overview
- Combining/upgrading items happens via **building-specific merge space pop-ups**, not
  on the main farm grid (Option C)
- **Crafting resolves during season simulation**, not during planning — items set up in
  a merge space during planning are produced at the end of that season and available
  the following season; nothing crafted this season can be used this season
- Clicking a building opens its pop-up, which contains a small arrangement area (a
  mini-grid or similar) where items can be placed to form recipes
- A **persistent inventory/resource panel** is always visible on screen regardless of
  which pop-up is open, allowing drag-and-drop into any merge space at any time
- A building's pop-up is **always accessible during planning** regardless of power state
- Crafting **executes only if the building is powered** when the season is confirmed;
  an unpowered building with a complete recipe set up will not craft until powered

### Recipe Visibility
- Most recipes are **known upfront**, assuming they have been unlocked via
  meta-progression
- **Food recipes** (especially those involving non-Earth crops) can be **discovered
  within a run** by experimenting with combinations in a dining hall merge space
- Undiscovered recipes still receive visual feedback if valid ingredients are placed
  together (see below)

### Visual Confirmation
When items are placed in a merge space, the game shows:
- **Bright green beam overlay** between items that form a **complete recipe**
- **Bright yellow beam overlay** between items that form a **partial recipe** (valid
  sub-combination but missing ingredients)
- Multiplicity is handled correctly: if a recipe requires 2 wheat + 1 water and 3
  wheat + 2 water are present, one complete set is highlighted green and the remainder
  yellow (if they also form a partial match)
- Visual confirmation appears **regardless of whether the player has discovered the
  recipe** — serves as an organic discovery hint
- Beam overlays appear **regardless of building power state** — they are purely
  informational

### Example Buildings with Merge Spaces
- **Matter Manipulator / fabrication unit** — crafts components, batteries, and basic
  items from Energy and Matter
- **Robotics facility** — crafts robot parts and robots from fabricated components
- **Dining hall** — crafts settler favorite foods from available crop and animal outputs

---

## Settlers

- A small group of **human settlers** (3–4 at run start)
- Named individuals, but **no individual gameplay mechanics** — no personal traits or
  individual favorites affecting gameplay
- Settlers may have **children** over the run (5–10 year timescale per run), who are
  additional mouths to feed
- Settlers must be **fed** each season; starvation is a critical failure condition
- **Morale** is a colony-wide aggregate value from **0 to 10** (whole numbers only),
  recalculated fresh each season from inputs; starting value at run start is **10**
- Morale is influenced by:
  - Success or failure in recent seasons
  - Settler deaths during the run
  - Presence of young children (positive effect)
  - Meal items consumed at the Cafeteria (see Food & Nutrition)
  - Other factors TBD
- Morale contributes to end-of-run score; also directly affects probability of
  favorable outcomes on exploration tasks and other settler-assigned tasks (see below)

---

## Exploration Tasks

### Overview
- Feel like **side quests** — event-like, not a routine every-season mechanic
- Available during the **planning phase** on every **third season**, starting with
  season 3 (seasons 3, 6, 9, 12, 15 in a standard 15-season run) — working value,
  subject to change after playtesting
- A **small pool** of tasks is presented each opportunity: up to **3 at a time**
- Number and quality of available tasks varies by planet type and meta-progression unlocks

### Assignment
- During planning, the player assigns a **settler** to an exploration task
- Assigning a settler **removes them from all farm duties** that season
- Multiple tasks can run simultaneously if the colony has enough settlers and **food**
  to send (food is consumed from inventory per task)
- Placement of assignments is **fully reversible** during planning

### Outcomes
Two categories of positive result:
- **Resource windfall** — settler returns with rare resources or items; no persistent
  grid change
- **Site reveal** — a feature on the farm grid is transformed into a new accessible
  site; e.g. a mountain region becomes an exposed ore deposit, a cave system, or a
  volcanic vent; the revealed site persists for the rest of the run

Many tasks yield only a windfall; site reveals are less common.

### Risk Spectrum
- Tasks range from **low-risk** to **high-risk**
- Low- and mid-risk tasks have **no negative outcomes** — results range from nothing
  to a good find
- High-risk tasks can result in **settler injury or death** but are the **exclusive
  source of the rarest and most desirable outcomes**
- Planet type affects the proportion of high-risk tasks available (e.g. a volatile
  volcanic planet generates more high-risk opportunities)

### Morale Modifier
- Colony **Morale** directly affects the probability of favorable outcomes on all
  exploration tasks
- Feedback loop: risky exploration → possible settler death → Morale penalty →
  worse future exploration odds

---

## Morale

### Display
- Shown as a **bar** with a **face emoji** left-justified and the **value out of 10**
  right-justified (e.g. 😊 ████████░░ 8/10)
- Working default; may be revised if UI space allows something richer, or if Morale
  proves more central to gameplay than anticipated

### Projected Delta Display
- During planning, planned actions that affect Morale are reflected on the bar in
  real time:
  - Projected **increase**: a translucent green extension above the current level
  - Projected **decrease**: a translucent red section erasing from the current level
    downward
- These projections are fully tentative within planning and update as the player
  adjusts their plan

---

## Food & Nutrition

### Nutrient Paste (Basic Sustenance)
- The **Matter Manipulator** automatically provides basic nutrition: **1 Matter per
  settler per season** is converted into **Nutrient Paste**
- This conversion is **auto-queued as a planned action** at the start of each planning
  phase — the player sees the Matter cost reflected as a delta from the start of
  planning without needing to do anything
- Nutrient Paste conversion is **not mandatory**: the player may allow the Matter delta
  to go unmet (e.g. by spending Matter elsewhere), which results in settler deaths
- If Matter is insufficient to cover the full Nutrient Paste need, all available Matter
  is consumed and the shortfall translates to **settler deaths** (1 settler per missing
  unit of Nutrient Paste, after accounting for any meal items)
- The planned settler delta is displayed visually during planning (e.g. a small red
  **-1** or **-2** beneath the settler count)
- If the player confirms a season with settler deaths planned from nutrient shortfall,
  a **confirmation dialog** appears:
  > *"There are not enough nutrients available at the start of season for all settlers.
  > Some could die. Proceed anyway?"*
  > **[Proceed]** / **[Cancel]**

### Meal Items
- Meals are crafted in the **Cafeteria** building's merge space; crafting resolves
  during **season simulation** (like all merge-space recipes) — a meal crafted this
  season is available to consume next season
- Each meal has a **Nutrient Value** — the number of Nutrient Paste units it replaces
- Meals may also have **secondary effects**, two types defined so far:
  - **Morale modifier** — a flat ±N change to Morale for the season it is consumed
  - **Morale floor** — caps Morale loss during that season at a maximum of N
    (e.g. "loss capped at 1 regardless of events")
- Meal items **do not expire**
- A meal that replaces more Nutrient Paste than the remaining need is still fully
  consumed (excess nutrients are ignored)

### Example Meals
| Meal | Recipe | Nutrient Value | Secondary Effect |
|------|--------|---------------|-----------------|
| Bread | 3 wheat | 3 | None |
| Eggplant Parmesan | 1 milk, 1 eggplant, 1 tomato, 1 wheat | 4 | +1 Morale |
| Spaghetti & Meatballs | 1 noodles, 1 tomato, 1 beef | 5 | Morale loss capped at 1 |

### Cafeteria Building
- Contains a **merge space** (majority of the pop-up area) for crafting meal recipes
- Contains a smaller **dedicated consumption area** (labeled, ~3 slots) where meals
  from inventory (or directly from the merge space) are dragged to be consumed this
  season
- Consumption slots are **spaced slightly wider apart** than merge-space slots to
  visually signal they will not merge
- Placing a meal in the consumption area reduces the auto-queued Nutrient Paste delta
  by that meal's Nutrient Value; removing it reverses the change
- All assignments are fully reversible during planning

---

## Exoplanet Types

- Multiple planet types, each with distinct:
  - Environmental hazards (weather severity, temperature, radiation, etc.)
  - Terrain layouts and fixed resource locations
  - Native planet-side materials (affecting available tech paths)
  - Rare resource opportunities (affecting score ceiling)
  - Energy and Matter regeneration rates (solar intensity, raw material availability)
- Exact planet types TBD as content develops

---

## Win / Lose Conditions

### Success
- Survive the maximum number of seasons
- **Score** calculated from: production output, settler Morale, rare resources
  utilized, safety over time, and other factors
- Score = "viability report" — how good could life be here for a larger colony?

### Critical Failure (Early End)
- Total farm destruction (weather, disaster)
- Settler starvation
- [Other conditions TBD]

### Gradual Decline
- Poor seasons compound: fewer resources, lower Morale, harder recovery
- A run can be effectively lost through slow decline without a single critical event

---

## Development Standards

### Version Control
- **Git** for version control; private repository on **GitHub**
  (https://github.com/Kirkules/exofarm-vibe)
- **License:** GPL v3 — note: revisit before any commercial release

### Project Structure

#### Folder Layout
```
res://
├── scenes/
│   ├── game/       ← main run (grid, simulation, planning UI)
│   ├── hub/        ← Earth hub
│   └── menus/      ← main menu, settings
├── scripts/        ← pure logic scripts with no associated scene
├── resources/      ← Godot Resource files (piece definitions, planet types, recipes)
├── assets/
│   ├── sprites/
│   ├── fonts/
│   └── audio/
└── tests/          ← GUT test files
```

Scene scripts are co-located with their scene files. Pure logic scripts (no scene)
live in `scripts/`.

#### Autoloads (Singletons)
- **GameState** — current run data: season number, settler count, inventory, Morale,
  Energy, Matter, grid layout, and all other mutable run state; responsible for
  triggering saves
- **Catalog** — known designs and recipes reflecting current meta-progression state
- **EventBus** — global signal bus for decoupled communication between systems
- **Settings** — user preferences: volume levels, drag offset toggle (offsets dragged
  items from the touch point so a finger doesn't obscure them on mobile), and other
  TBD preferences

#### Data Definitions
- **Piece/building definitions, planet types, recipes:** defined as typed Godot
  Resource subclasses (`.tres`/`.res`); editable in the Godot editor without touching
  code
- **Pure logic** (grid calculations, rotation, outcome rolls, etc.): GDScript classes

#### Save Strategy
- **Game save state:** `SaveData` — a custom Resource subclass saved as a binary
  `.res` file via `ResourceSaver` to `user://`; fast to write; strongly typed;
  consistent with the project's Resource usage
- **Settings:** `ConfigFile` (`.cfg`) saved to `user://` — purpose-built for
  key-value preferences, simpler than a full Resource
- **Save triggers:**
  - After every meaningful planning action (piece placed/removed, building toggled,
    meal assigned, explorer assigned, etc.)
  - On app pause (`NOTIFICATION_APPLICATION_PAUSED`) — critical on Android, where
    the OS can kill background apps without warning
  - Saves are handled by `GameState` and must be fast enough to run synchronously
    without perceptible lag

### Grid Coordinate System
- Cells addressed as **(row, column)**, 1-indexed, with **(1, 1) at the top-left**
  corner of the grid
- Row increases downward; column increases rightward
- Example on an 8×6 grid: (1,1) = top-left, (1,8) = top-right, (6,8) = bottom-right

### Polyomino Shape Definition
- Each piece shape is defined as a **list of (row, col) offsets** from an **origin
  cell**, e.g. `[(0,0), (1,0), (2,0), (2,1)]` for an L-shape
- The **origin cell** is both the anchor for offset definitions and the **pivot point
  for rotation** during drag/placement — it tracks the player's touch point on the
  grid; the other cells rotate around it
- Rotation is applied mathematically: 90° clockwise transforms each offset
  `(r, c) → (c, -r)`, then offsets are renormalized so the minimum is back at `(0,0)`
- All 4 rotation states are computed from the base definition at runtime (not stored
  as separate variants)

### Language
- All game code written in **GDScript** — no C#

### Art Style & Resolution
- **Art style:** pixel art
- **Sprite size:** 32×32 pixels (working value)
- **Base game resolution:** 270×600 (9:20) portrait — working value, subject to change
  - Primary orientation: **portrait**; landscape not planned unless straightforward
  - Gives perfect 4× integer scaling on Pixel 7a (1080×2400 portrait); Pixel 10a
    expected to match (Google "a" series has used 1080×2400 since Pixel 6a)
  - On other aspect ratios: integer scaling produces black bars but never blurry
    pixels — crisp everywhere, bar size varies by device
  - Screen thirds layout: landscape view (top, ~150px) / farm grid (middle, 192px) /
    HUD + UI (bottom, ~258px)
  - 8×6 grid at 32×32px = 256×192px fits width (270px) with 14px margin; 9×6 would
    require tiles of ~29px or smaller
  - Most non-grid UI (merge spaces, crafting pop-ups, etc.) appears as overlays,
    keeping the persistent HUD minimal
  - Resolution and/or grid size can be adjusted later if gameplay needs require it
- **Text:** pixel fonts; multiple sizes (e.g. 8px, 16px) to allow modest text scaling
  within the pixel art aesthetic
- **Scaling:** Godot integer scaling (canvas_items); primary playtest targets are
  Android phones (Pixel 7a, Pixel 10a)

### UI Layout — Planning Phase

#### Screen Sections (Portrait, 270×600)

**Top (~150px) — Settlement View + Info Overlay**
- Background: a landscape-painting-style depiction of the settlement, as if viewed
  from a hillside looking at the farm and the planet beyond
- Not a 1:1 representation of the grid — reflects broad strokes (a weather bubble
  building → a translucent dome; crop drones → a single drone slowly crossing the
  scene; a storage facility → a building in the background)
- Updated once at the start of each planning phase to reflect post-simulation state
- Ambient animations run continuously within the season snapshot (drone moving,
  lights blinking, crops swaying, etc.)
- Persistent info overlaid with transparent-background text/elements:
  - Resource displays (Energy, Matter)
  - Morale bar (face emoji + value out of 10)
  - Settler count (with planned delta indicator)
  - Season number and other passive readouts
- Overlays are positioned to minimally obscure the landscape scene

**Middle (~192px) — Farm Grid**
- 8×6 grid at 32×32px (256×192px), centered horizontally with ~7px margins
- Primary planning interaction area: piece placement, rotation, building toggles,
  effect overlays, synergy indicators

**Bottom (~258px) — HUD & Controls**
- **Inventory:** persistently visible at top of this section; also serves as the
  off-grid holding area (workspace) — pieces picked up from the grid appear here as
  inventory items; expandable upward (overlaying the grid) to reveal more items at
  once; collapsible back to default
- **Next Season button:** wide (~50% screen width, ~135px), centered, at very bottom
  of screen; confirms planning and begins season simulation
- **Game navigation button:** small, tucked in a bottom corner; expands to reveal:
  - Settings (gear icon)
  - Quit to hub (back arrow)

#### Overlay / Popup Behavior
- **Merge space and interaction popups:** dim entire background; cover the top and
  middle sections plus most of the bottom section, leaving approximately a
  button-height strip (~32–40px) at the very bottom visible but dimmed; dismissed
  by tapping or clicking anywhere off the popup
- **Tooltips:** small popups providing detailed information; trigger varies by context;
  dismissed by tapping or clicking off them; do not cover large portions of the screen

### Asset Formats
- **Sprites & pixel art:** `.png` — editable in **Krita** (free/open-source); Godot
  imports `.png` natively
- **Audio SFX:** `.ogg` — editable/trimmed in **Audacity** (free/open-source)
- **Music:** `.ogg` — composed in **FL Studio** (proprietary but exports open formats)
  or other tools; format remains portable and editable in free tools

### Testing
- Unit tests written with the **GUT (Godot Unit Test)** plugin where sensible
- Tests are appropriate for pure logic (grid calculations, resource math, outcome rolls,
  morale recalculation, etc.) but not required for UI or rendering code

---

## Development Phases

### Phase 0 — Foundation
- [x] Project structure and scene organization
- [x] Core grid data model (cells, polyomino piece shapes, rotation logic)
- [x] Grid rendering with placeholder visuals (colored rectangles)
- [x] Piece placement, rotation, and removal input handling
- [x] Inventory data model and UI (collapsed/partial/full panel; drag-to-pick-up from
  inventory with 16px-drag or 0.5s-hold threshold; drop-to-inventory via sprite CoM
  detection; snap-back to original grid position on invalid drop; 32×32 piece icons)
- [x] Mouse/desktop input parity (left-click = tap, right-click-while-dragging = rotate)
- [x] Basic field-of-effect overlay system (shown while dragging; Manhattan distance radius
  per piece; toggleable per-piece via effect_range property)

### Phase 1 — Core Planning Loop
- [x] Initial set of placeable element types (GreenhouseDefinition class; Wheat/Tomato/Eggplant
  Greenhouses in build menu; 1×1 crop pieces, yield_per_season=1; separate
  PlaceableDefinition instances for Wheat/Tomato/Eggplant crop items as harvest output)
- [x] Resource system (Energy + Matter, seasonal regeneration; production computed from
  placed active buildings; HUD shows stored/capacity/+production; overflow warning on
  Next Season)
- [x] Power system: broadcast range, network formation, shared pool, binary power state
- [x] Building on/off toggle (double-tap on fixed building)
- [x] Neighbor effect calculation engine (NeighborSystem.compute(); effects not yet
  applied to simulation output)
- [x] Visual synergy and coverage indicators during planning (permanent effect-range
  overlay for placed pieces with effect_range > 0, dimmer shade than drag preview;
  power overlay refactored into shared _refresh_overlays() path)
- [x] Power range visual overlay during planning (placed buildings + hold preview)
- [x] "Proceed to Next Season" confirmation and lock-in (buildings lock in on Next Season;
  conditional dialog warns when Energy or Matter production would overflow storage)
- [x] Moveable vs. fixed piece distinction (all pieces moveable during planning; buildings
  lock to moveable=false on Next Season confirmation; upgrade hook deferred)
- [x] UNBUILT/BUILT building state: UNBUILT buildings (placed from build menu) flash and
  can be moved; if dropped off-grid they are discarded; transition to BUILT at season
  confirmation (stop flashing, lock moveable, enable toggle)
- [x] Build menu: shown below the grid when inventory is collapsed; lists buildable
  definitions; tapping begins the hold-to-place flow onto the grid as an UNBUILT building
- [x] HUD tooltips: press-and-hold Energy label shows per-building energy deltas; same
  for Matter label (includes stored amount); colored deltas (#88ee88 positive, #ee8888
  negative) used consistently throughout HUD

### Phase 2 — Season Simulation
- [ ] Season resolution logic (crop yield, resource consumption, weather events)
- [ ] Animated simulation playback with outcome log
- [ ] Playback speed controls (1×, 2×, 3×, 5×)
- [x] Settler food consumption and starvation check (Nutrient Paste auto-queue from
  powered Matter Manipulator; shortfall → settler death; confirmation dialog; per-settler
  fed/starving tracking; colony-lost condition when all settlers die)
- [ ] Morale calculation (fresh each season from inputs)
- [ ] Morale bar UI with projected delta display
- [x] Cafeteria building: merge space (KitchenGrid) + consumption area UI (SettlerFoodGrid
  per-settler meal assignment panel; meals draggable across slots; HUD reflects savings)
- [x] Meal item crafting data: RecipeDefinition populated ({2 Wheat}→Pasta,
  {2 Tomato}→Tomato Sauce, {1 Pasta+1 Tomato Sauce+1 Eggplant}→3 Pasta alla Norma);
  MealDefinition extends PlaceableDefinition with nutrient_value + morale_modifier
- [ ] Recipe execution during simulation (actually run recipes in KitchenGrid at sim time)
- [ ] Exploration task resolution (outcome roll, Morale modifier, windfall delivery,
  site reveal conversion)

### Phase 3 — Run Structure & Progression
- [ ] Exploration task pool generation (every 3rd season, count/quality by planet type)
- [ ] Settler assignment UI for exploration tasks during planning phase
- [ ] Run start: planet setup, fixed terrain, settler names, starting resources
- [ ] Planet-side material deposits and extraction
- [ ] Resource-gated design unlocking within a run
- [ ] Critical failure detection and early run end
- [ ] End-of-run score calculation and display
- [ ] Earth hub stub: run history, score log, catalog view

### Phase 4 — Meta-Progression & Content
- [ ] New design unlocking via novel resource discovery (cross-run)
- [ ] Multiple exoplanet types with distinct properties
- [ ] Full initial set of buildings, crops, and modules
- [ ] Cafeteria building content: meal recipes, crop and animal output items
- [ ] Earth hub fleshed out

### Phase 5 — Polish
- [ ] Sound effects and music
- [ ] Visual feedback (animations, particles, transitions)
- [ ] Art pass (replace placeholder graphics)
- [ ] Balancing and playtesting
- [ ] Main menu, settings, save/load

---

## Open Questions

- [x] Game title: **ExoFarm**
- [x] Run length: **15 seasons** (working value; exact number and whether it varies by
  planet to be tuned after playtesting)
- [x] Earth hub story: FTL tech caused irreversible climate change; SEED organizes
  advance settler missions to find a new home for humanity
- [x] Organizing body name: **SEED** — Survival and Emigration Expedition Dispatch
- [x] Morale (renamed from happiness): colony-wide aggregate 0–10, recalculates fresh
  each season; affects exploration outcomes and other settler tasks; displayed as bar
  with face emoji + number; projected delta shown during planning
- [x] Food: Nutrient Paste (auto from Matter Manipulator), Cafeteria for meal crafting;
  meals replace Nutrient Paste and may boost Morale or provide other effects
- [x] Resources beyond Energy and Matter: none at the basic level. All non-basic
  resources (planet-side materials, crop/animal outputs, rare finds, etc.) are
  inventory items — used as crafting ingredients in merge spaces or placed into
  building slots (analogous to meals in the Cafeteria consumption area)
- [x] Exoplanet selection: player chooses from available planet types at the hub, with
  an option to randomize. Late-game addition (Phase 5+): a hub mini-game for "scanning"
  for a planet with a specific combination of properties; difficulty scales with how
  favorable the target combination is; sometimes impossible.
- [x] Earth hub contents: recipe browser, exoplanet catalog, run history, start run
