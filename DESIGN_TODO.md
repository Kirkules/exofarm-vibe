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
  - [ ] `Preparedness` buildings — nothing concrete yet backing
    `MatchedPreparedness(Weather)` or `MatchedPreparedness(Bio-hazard)` (only the
    data-gathering side has concrete sources so far)
- [x] **Stewardship Caucus** — formula done
  - [x] Mining buildings list — Mine, Quarry, Rare Metal Extractor designed
    (see Farm/Production); `DisruptionFootprint`/`ExtractionRestraint` still
    derive automatically from grid/mining state, no new scoring mechanism
    needed
- [x] **Development Bloc** — formula done
  - [ ] Rarity weights per resource (not yet assigned)
  - [ ] Real buildings/items catalog carrying `TechAchievement` values
- [x] **Frontier Legends** — formula done
  - [ ] Individual-settler tracking system (doesn't exist at all yet)
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
5. [ ] Protection — weather-shielding/enclosure structures (now has a likely
   consumer for High-Tech Components as a construction-cost input)
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

## Other Fabrication-Adjacent Gaps (found auditing while designing
Robotics/Fabrication)

- [ ] **Medical/Vaccine production** — Safeguard Coalition's bio-hazard
  `MatchedPreparedness` needs a building, and the earlier vaccine-production
  example ("an effective vaccine can't be produced without first collecting
  enough bio-data") implies a fabrication step never formally designed as a
  building.
- [x] **Weather Monitoring Station** — resolved by consolidating into **Scanner
  Station** (see Farm/Production), alongside a new Deposit Scanning mode.
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
