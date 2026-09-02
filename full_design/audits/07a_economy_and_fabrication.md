# Audit — System 7a: Economy & Fabrication

Split from System 7 (Resource Economy, Fabrication & Deposits). **7a** covers the
Building Schema, the `TechAchievement` catalog, the raw/refined resource set and
its generic-category discipline, the refined-goods fabrication chains, the
Lumber+Concrete construction-cost model, the starting-building bootstrap,
Fertilizer, Seasonings, luxury goods, and the Robotics Assembly drone taxonomy.
Deposit Discovery, the depth-tier/overlap model, the two Surveys, Scanner-Station
scanning, and the mining buildings are in `07b_deposits_and_surveys.md`.

**Split rationale:** the two halves fail differently — 7a is recipe chains,
catalog schema, and tech-tier ordering; 7b is spatial discovery, RNG, and the
survey action economy — and they touch largely disjoint design-doc sections. The
only tight seam (mining output feeding refining) is noted in both.

Pure design review against `full_design/`; no implementation exists. Citations
are `file` → "Section" (no anchor links: the repo link-checker only scans
`full_design/*.md`).

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| 7 Building Categories (Basic Resource Production, Farm/Production, Food/Meal Conversion, Fabrication, Protection, Storage, Utilities) | `04` "Building Categories" |
| Building Schema — universal props: Name, Category, Grid slot count (= worker capacity), Input, Output + `production_time`, Staffing, Indoor/Outdoor, Construction cost, `TechAchievement`, Repeatable, Upgrade path | `04` "Building Schema" |
| Building Schema — conditional props: Production cap, Area of effect, Energy upkeep, Preparedness contribution, Data-gathering contribution, Storage contribution | `04` "Building Schema" |
| Recipes — a building may define >1 Input/Output pairing; player picks one, sticky + reversible; no recipe-shape sub-taxonomy | `04` "Building Schema" |
| Instant-conversion alternative to `production_time` (Ration Press shape — no staffing, no timer, no rate limit, reversible) | `04` "Building Schema" |
| Generic resource categories — many sources → one tracked category, to stop catalog explosion | `04` "Baseline Farm/Mined Resources" |
| Baseline crops/animal/material raws: Grain, Fruit, Milk, Eggs, Wool, Fiber/Cotton, Wood, Pelts | `04` "Baseline Farm/Mined Resources" |
| Mined raws: Iron Ore, Copper Ore (per-site %-mix, per-unit draw in sim), Stone, rare metals, Fossil Fuel | `04` "Baseline Farm/Mined Resources" |
| Refined forms: Iron/Copper (Smelter), Concrete/Silicon (Stone Processing I/II), Lumber (Sawmill), Leather (Textile Workshop) | `04` "Baseline Farm/Mined Resources", "Fabrication" |
| Lumber + Concrete = the two universal construction-cost materials; per-building ratio TBD; advanced materials layer on top | `04` "Building Schema", "Resources" |
| Wood — one pooled resource, two sources (Timber Grove renewable; Clear-Cutting bounded); sustainability tracked at production point for `ExtractionRestraint` | `04` "Baseline Farm/Mined Resources", "Fuel" |
| Starting buildings incl. Sawmill + Stone Processing I; "self-bootstrap from turn one" claim (Clear-Cutting + the two starting Fabrication buildings, no starting-materials stockpile) | `04` "Resources" |
| Smelter — Iron ← Iron Ore / Copper ← Copper Ore (selectable) | `04` "Smelter" |
| Stone Processing I (starting) → Stone Processing II (upgrade; adds Silicon ← Stone) | `04` "Stone Processing I" |
| Sawmill (starting) → Carpenter's Shop (upgrade; adds Fine Furniture / Ornamental / Wooden Plow) | `04` "Sawmill" |
| Textile Workshop — Fabric ← Wool/Fiber/Pelts (selectable); Leather ← Pelts; Leather Boots (upgrade); Leather Backpack | `04` "Textile Workshop" |
| Tinkerer's Workshop — HTC, High-Resolution Screens, Portable Scanning Equipment (base); Temp-Resistant Gear, Diplomatic Gear, Armed Expedition Kit, Overwhelming Force Package (further upgrade) | `04` "Tinkerer's Workshop" |
| Fertilizer — passive from livestock buildings regardless of staffing; auto-consumed once/season by plant crops to null Alien Soil | `04` "Baseline Farm/Mined Resources", "Farm/Production" |
| Seasonings — Herbs (Clear-Cutting/Surveys/Exploration) & Spices (Mining/Exploration), incidental only; 2–3 each per planet type; 1 Gourmet recipe each, else inert | `04` "Baseline Farm/Mined Resources" |
| Luxury goods — Fine Furniture, Ornamental/Decorative Items, High-Resolution Screens; `TechAchievement` / "faction-reward value", no functional use | `04` "Fabrication" (Sawmill, Tinkerer's Workshop) |
| `TechAchievement` — static 0–4 per catalog entry; the rubric; count-once-per-run rule; the full per-entry catalog | `04` "TechAchievement Catalog" |
| Robotics Assembly — consolidated; fresh fab = Basic only; Advance & Harden = independent upgrade-in-place axes (drone tied up as a resource, different worker performs, identity + battery carried through) | `04` "Robotics Assembly" |
| Drone fresh recipes: Construction Robot, All-Purpose Basic (both ← Iron+Copper); Specialized Basic (one per Experience group, ← Iron+Copper+category input, base tier, needs ≥1 matching production structure, never Research Lab) | `04` "Robotics Assembly" |
| Drone upgrade recipes: Advance All-Purpose ← Silicon+HTC; Advance Specialized ← HTC (both need Upgraded RA); Harden ← HTC (any tier/line) | `04` "Robotics Assembly" |
| Drone Effort: AP-Basic 0.5, AP-Adv 1.0, Spec-Basic 1.5, Spec-Adv 2.0; Harden changes none | `04` "Robotics Assembly" |
| Drone task-eligibility tiers (AP-Basic / AP-Advanced / Specialized); Exploration & Research always settler-only | `04` "Robotics Assembly" |
| Drone battery — per-drone max, free full reset each season-start, drains over Mid-Sim, auto ~3s recharge as elevated Energy consumption, temp-accelerated drain (hardened exempt), zero Effort while recharging | `04` "Robotics Assembly" |
| Worker freed to roster when its building is destroyed (mid-Mid-Sim loses Indoor protection) | `04` "Robotics Assembly", "Building Schema" |
| Feeds Development Bloc (`ResourceStockpile`, `ResourceIncome`, `TechAchievement`) and Stewardship (`ExtractionRestraint`, `EmissionsRestraint`) | `06` "SEED Factions" |

**Boundary notes.**
- Mining buildings (Mine/Quarry/Rare Metal Extractor) produce the raw Ore/Stone/rare-metal 7a refines; audited in **7b**. The refining seam (Smelter / Stone Processing consuming their output) is here.
- Ration Press instant-conversion is inventoried here as a Schema shape; its food-economy behaviour is System 8's.
- Drone *assignment / Effort-stacking* is System 3's; the drone *catalog* (recipes, tiers, battery) is here.
- Fuel-based Generator burning Wood is System 5's; Wood as a fabrication input is here.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **A-S1. The "self-bootstraps from turn one" claim is unverified and hinges on the deferred Lumber:Concrete ratios.** `04` "Resources" asserts no starting-materials stockpile is needed because Clear-Cutting + Sawmill + Stone Processing I self-bootstrap. But turn one there is no Stone (no Quarry) and therefore no Concrete; the first buildable structure (Quarry) is priced "small Lumber only" specifically to be reachable pre-Concrete (`04` "Quarry"). Whether the *next* structures that close the loop (Timber Grove, Smelter, a second Quarry) are also Lumber-only/-heavy is exactly the per-building ratio `DESIGN_TODO.md` "Fabrication chain revisit" defers. Until those ratios exist for the bootstrap set, the opening is not demonstrably playable — a structural precondition wearing a numeric-TBD label. *Possible direction: pin the ratio for the ~5 buildings on the critical bootstrap path now, separately from the full-catalog balancing pass.*
- **A-S2. Turn-one Wood supply is not guaranteed.** Clear-Cutting needs a Forest tile; Timber Grove must be built (needs Lumber → needs Wood). `04` "Fuel" says Forest-tile count "varies by planet type and site" with no floor; `04` "Deposit Discovery" guarantees only a Surface Stone/Iron/Copper deposit — no Wood equivalent. A site with zero Forest tiles has no turn-one Wood → no Lumber → no construction of any kind. *Possible direction: guarantee ≥1 Forest tile (or a small starting Lumber quantity) at Farm Site Selection.*
- **A-S3. Fertilizer consumption quantity is undefined.** `04` "Baseline Farm/Mined Resources" — plant crops consume Fertilizer "once per season"; `04` "Farm/Production" — Alien Soil is "Removed for any season Fertilizer is available". Not stated: one unit settlement-wide vs. one per plant-crop building. Determines whether Fertilizer is a trivial side-effect of owning one livestock building or a real per-field cost. *Possible direction: 1 Fertilizer per plant-crop building per season.*
- **A-S4. Seasoning drop cadence is undefined for continuous sources.** `04` "Baseline Farm/Mined Resources" — Spices "turn up during Mining". Per production cycle or per season? Per-cycle makes Spices routine on any mining-heavy run. *Possible direction: one roll per season per qualifying assignment, not per cycle.*
- **A-S5. Drone upgrade-in-place duration and siting is unspecified.** `04` "Robotics Assembly" — an Advance/Harden action ties up the target drone "for the task's duration" while "a different worker performs the upgrade". Duration (presumably one season), resolution moment (presumably Post-Sim), and whether it consumes a Robotics Assembly staffing slot / grid presence are all unstated. *Possible direction: one season, resolves at Post-Sim, consumes one RA staffing slot.*

### Numeric (deferred to balancing — catalogued only)

- **A-N1.** Per-building Lumber:Concrete ratios catalog-wide (minus Quarry's stated Lumber-only). `04` "Building Schema"; `DESIGN_TODO.md`. *(But see A-S1 — the bootstrap subset is not purely numeric.)*
- **A-N2.** Sawmill→Carpenter's Shop and Stone Processing I→II upgrade costs. `04` "Sawmill" / "Stone Processing I".
- **A-N3.** Smelter Ore→metal ratios; `production_time` values not already stated. `04` "Smelter".
- **A-N4.** Development Bloc per-resource rarity weights (score uncomputable without them). `06` "SEED Factions"; `DESIGN_TODO.md` "Development Bloc".
- **A-N5.** Fertilizer production rate per livestock building; Herb/Spice drop probabilities. `04` "Baseline Farm/Mined Resources".
- **A-N6.** Drone per-tier battery capacities; recharge-duration variation by type; temperature-drain curve. `04` "Robotics Assembly".
- **A-N7.** "Category-flavored input" for each Specialized Drone recipe (content-authoring). `04` "Robotics Assembly".
- **A-N8.** Per-planet Herb/Spice rosters and their one-to-one Gourmet recipes (content-authoring; cross-ref System 8). `04` "Baseline Farm/Mined Resources".

### Cross-check with `DESIGN_TODO.md`

Already flagged: the Lumber:Concrete ratios, the two upgrade costs, Development Bloc rarity weights. **Not** flagged: A-S2 (turn-one Wood guarantee), A-S3 (Fertilizer quantity), A-S4 (Seasoning cadence), A-S5 (drone upgrade-in-place resolution), and that the bootstrap-path ratios (A-S1) are a structural precondition, not a balancing nicety. Recommend adding.

---

## 3. Internal consistency

- **A-IC1. One `TechAchievement` value per entry, but multi-recipe items have recipes of very different input cost.** `04` "TechAchievement Catalog" rates Diplomatic Gear 3 ("multiple advanced inputs together"), yet `04` "Tinkerer's Workshop" gives it a **Fabric-only** recipe path alongside the Silicon+Copper one. Producing it via the cheap path still "reaches" the tier-3 entry and credits Development Bloc the full 3. (Temperature-Resistant Gear avoids this — both its paths carry rare metal + HTC.) *Possible direction: rate a multi-recipe item at its cheapest recipe's tier, or split it into two catalog entries.*
- **A-IC2. Tier-0 rubric says "no building prerequisite" but several tier-0 entries have one.** `04` "TechAchievement Catalog" tier 0 = "no building prerequisite, no upgrade needed", yet Water Condenser/Ice Melter/Cistern/Well (tier 0) require the Water Processing Plant to function (`04` "Water"). Harmless (WPP is a starting building) but the wording is contradicted. *Possible direction: "no non-starting building prerequisite".*
- **A-IC3. "Generic categories stop the catalog exploding" vs. individually-named per-planet Seasonings.** `04` "Baseline Farm/Mined Resources" applies the generic-category rule strictly to crops, ore, Pelts — then explicitly exempts Seasonings, up to ~6 named items per planet type plus a matching Gourmet recipe each. The doc's own argument (the *per-run* footprint stays small) is what the principle protects, so this is a defensible carve-out — but it should be named as a deliberate exception in the principle's text, not just in the Seasonings bullet.
- **A-IC4. "All Fabrication buildings are Indoor" vs. the Manual-Labor / non-manual injury split.** `04` "Building Schema" lists "all Fabrication buildings" as Indoor. `05` "Injuries" puts "Robotics Assembly, Stone Processing, Carpenter's Shop" in Manual Labor and "Tinkerer's Workshop" in non-manual — leaving **Smelter, Textile Workshop, Sawmill** in neither. A settler with a Permanent injury has undefined eligibility/speed at those three. (Cross-ref System 9.)

---

## 4. Cross-system consistency

- **A-CS1. Sawmill has no Experience group and no Aptitude bucket.** `05` "Experience" lists "each Fabrication building separately — Robotics Assembly, Stone Processing, Smelter, Textile Workshop, Carpenter's Shop, Tinkerer's Workshop"; `05` "Aptitude" names "Carpenter's Shop". **Sawmill** — a *starting* staffed building worked from turn one — appears in neither. A settler milling Lumber in Season 1 gains no Experience and no Aptitude modifier applies. *Possible direction: state that a base building and its upgrade share one Experience group / Aptitude bucket, named for the line.*
- **A-CS2. "Stone Processing" in the Experience/Aptitude lists is tier-ambiguous** (I vs. II) — same base/upgrade identity question as A-CS1. `05` "Experience" / "Aptitude".
- **A-CS3. Rare-metal acquisition is softly circular.** Portable High-Powered Scanning Equipment needs "a rare metal" as an input (`04` "Tinkerer's Workshop"); the systematic way to find rare metal is Deep Survey, which *requires* Portable High-Powered Scanning Equipment (`04` "Deposit Discovery"). The break routes (a lucky Mid-depth rare-metal deposit, Scanner Station scanning, exploration windfalls — `05` "Task Catalog") exist but are never called out as the intended bootstrap for the rare-metal tier. (Cross-ref 7b B-CS1, System 10.)
- **A-CS4. The mid-game tech spine is single-threaded through Silicon.** Silicon ← Stone Processing II (an upgrade). HTC needs Silicon. Tinkerer's Workshop needs Silicon to *build*. Portable Scanning Equipment, Temperature-Resistant Gear, Diplomatic Gear, Overwhelming Force Package, Scanner Station, Medical Bay, Research Lab, Reclamation, Advanced drones — all route through HTC → Silicon → the Stone Processing II upgrade. One construction-robot upgrade action hard-gates roughly the entire advanced catalog; the design does not acknowledge this dependency. (Cross-ref Systems 1, 11, 12.)
- **A-CS5. Luxury goods' "faction-reward value" is asserted but only `TechAchievement` is wired.** `04` "Fabrication" — High-Resolution Screens has "no functional use yet beyond `TechAchievement`/faction-reward value, left open". No SEED formula in `06` "SEED Factions" has a luxury-goods term; Development Bloc's `ResourceStockpile` list excludes them. The only concrete pathway is `TechAchievement` (produce once → tier points).
- **A-CS6. Robotics Assembly staffing tier is ambiguous.** `04` "Robotics Assembly" staffing = "Settler or all-purpose drone" (unqualified), but AP-Basic drones are barred from several task classes and allowed "assembly-style tasks at most production buildings" — unclear whether fabricating a drone at RA is such a task. (Cross-ref System 3.)

---

## 5. Story & world consistency

- **Positive / reinforcing.** The Lumber+Concrete + refined-metals economy squares with `02` "The Crash Research Era" (industrial buildout, AI-driven drones) and the mass-threshold-limited scout footprint (`02` "Faster-Than-Light Travel") — a team with a Sawmill and a Smelter, not a colony with a foundry. The Matter removal (`04` "Resources") is a story improvement: a generic filler had no in-fiction referent; Lumber/Concrete do.
- **A-ST1 (no change — conscious call).** Fossil Fuel on a scout world is a light stretch that `04` "Deposit Discovery" leans into deliberately via the `TrueRisk(Bio-hazard)`-as-historical-biomass rationale.
- **A-ST2 (missed reinforcement).** The drone Basic→Advance→Harden ladder has no in-fiction voice; `02` establishes AI/drone and shielding tech as Crash Research Era pillars, and Hardening is literally shielding-lineage — a one-line frame would tie it in.
- **A-ST3 (missed reinforcement).** Luxury goods with "no functional use" are a missed hook; `02` "SEED Bulletin" / seed-ship politics could make Fine Furniture / Ornamental Items diegetic viability-report evidence instead of inert tier-point fodder. (→ §8.)

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Numbers stay small* — generic categories, per-cycle outputs of 1, Effort 0.5–2.0, `TechAchievement` 0–4. `04` "Baseline Farm/Mined Resources", "Robotics Assembly".
- *Planning reversible / randomization gated* — the Iron/Copper mix draw "resolves during simulation, not planning, per the reversibility principle"; recipe selection is "a normal, reversible planning-phase choice". `04` "Baseline Farm/Mined Resources", "Building Schema".
- *Normalize before combining unrelated values* — Development Bloc normalizes its three terms before summing. `06` "SEED Factions".
- *Naming convention* — tier-scaled exoticism is explicit. `04` "Naming Convention".

**Risks / violations:**
- **A-P1 (→ SF). Failure legibility.** The bootstrap deadlock (A-S2) and the Silicon chokepoint (A-CS4) have no in-game signal; a run with no Forest tile, or a player who hasn't realised every advanced building needs Stone Processing II first, hits a wall silently. `01` "Failure should always be legible".
- **A-P2 (→ NTH). Numbers stay small.** `TechAchievement` count-once + multi-recipe asymmetry (A-IC1) lets a tier-3 score be banked off a tier-1 input path — a mild "optimise the one number" incentive `01` warns against.
- **A-P3. Passable-plan-quick.** The single-threaded Silicon dependency (A-CS4) makes the passable late-game plan and the only late-game plan increasingly coincide — tension with `01` "A passable plan should always be quick to reach" (which also wants a passable/optimal gap). Watch in playtest.
- Not engaged: units-unspecified, colour-not-sole-channel (no 7a-specific overlays — see 7b / System 1), dexterity-timing, text-legibility.

---

## 7. Player legibility

- **Recipe chains** — legible if the Site Panel recipe indicator/selector (`03` "Site Panel (UI)") shows input→output plainly; the multi-step chain is learn-once and transfers.
- **`TechAchievement`** — the player rightly "doesn't need to know the exact formula" (`06` "SEED Factions"), but *which* actions bank a tier point (first production of an item, first upgrade) needs some signal, or the Development Bloc score moves for invisible reasons. Not specified.
- **Bootstrap path** — currently a puzzle to reverse-engineer (which starting buildings, what Clear-Cutting is for, why Quarry is cheap). `01` "inferable through play" allows this only if discoverability is signalled (e.g. a run-start line). Not specified. (Cross-ref System 12.)
- **Fertilizer** — "consumed automatically, no manual action needed" (`04` "Farm/Production") is good, but the player must see *that* it happened and how much remains, or Alien Soil silently returns when livestock output lapses.
- **Drone battery / recharge** — `03` "Worker Roster (UI)" gives a battery bar; recharge as an Energy spike needs to appear in the log (`03` "Season Structure") or an unexplained brownout reads as a bug.

---

## 8. Fun / scope risk

- **The luxury-goods loop is thin.** Fine Furniture, Ornamental/Decorative Items, High-Resolution Screens: "no functional use", produced once for tier points (A-CS5) — three recipes, three menu entries, three catalog lines serving only a number. *Cut-or-simplify: give them a real sink (diegetic viability/morale contribution per A-ST3) or fold them into one generic "Luxury Good" category — the same discipline the raw resource set already uses.*
- **The Silicon chokepoint (A-CS4)** risks a samey mid-game — every run's advanced phase opens "upgrade Stone Processing, build Tinkerer's Workshop". High strategic value in the *early* economy, narrowing in the *mid*. Decide explicitly: intended pacing gate, or should a second route to HTC-tier capability exist?
- **Drone Basic/Advance/Harden as independent axes** — genuinely good: two orthogonal decisions per drone, low rule weight, clean opportunity cost vs. fresh fabrication. Keep.
- **Generic-category discipline for raws** — high value, keep. The Seasoning carve-out (A-IC3) is defensible (per-run footprint stays small), but ~24 Seasonings + 24 Gourmet recipes across four planets is a real authoring commitment, not a drift — flag it as a conscious content-scope decision.
- **Starting economy (bootstrap + staffing squeeze)** — the turn-one puzzle of Clear-Cutting → Sawmill → Quarry → Stone Processing while staffing two starting buildings with 3–4 settlers is a strong, legible opening tradeoff. Keep; just make it survivable (A-S2) and legible (A-P1).

---

## 9. Findings summary

### Blockers

- **A-S1.** "Self-bootstraps from turn one" is unverified; the bootstrap-path Lumber:Concrete ratios are a structural precondition mislabelled as a balancing TBD. (§2 — `04` "Resources" / "Quarry"; `DESIGN_TODO.md` "Fabrication chain revisit")
- **A-S2.** No guaranteed turn-one Wood source — a site with zero Forest tiles has no Lumber and cannot build anything. (§2 — `04` "Fuel" / "Deposit Discovery"; cross-ref System 1 Farm Site Selection, 7b B-S1)
- **A-S3.** Fertilizer per-season consumption quantity undefined (settlement-wide unit vs. per-plant-crop-building) — sets whether Fertilizer is a real cost or a trivial side-effect. (§2 — `04` "Baseline Farm/Mined Resources" / "Farm/Production")

### Should-fix

- **A-S4.** Seasoning drop cadence undefined for continuous sources (per cycle vs. per season during Mining). (§2 — `04` "Baseline Farm/Mined Resources")
- **A-S5.** Drone upgrade-in-place (Advance/Harden) has no stated duration, resolution moment, or Robotics Assembly slot cost. (§2 — `04` "Robotics Assembly")
- **A-IC1.** Multi-recipe items get one `TechAchievement` tier that can exceed their cheapest recipe's cost (Diplomatic Gear rated 3, but a Fabric-only path exists). (§3 — `04` "TechAchievement Catalog" / "Tinkerer's Workshop")
- **A-IC4 / A-CS1 / A-CS2.** Sawmill, Smelter, and Textile Workshop are unplaced in the Experience-group, Aptitude-bucket, and Manual-Labor/non-manual taxonomies; Sawmill is a *starting* staffed building. State that a base building and its upgrade share one line-identity across all three. (§3–§4 — `05` "Experience" / "Aptitude" / "Injuries"; cross-ref Systems 3, 9)
- **A-CS3.** Rare-metal acquisition is softly circular (Portable Scanning Equipment needs a rare metal; systematic rare-metal discovery needs Portable Scanning Equipment); the intended bootstrap (exploration / Scanner Station) is never stated. (§4 — `04` "Tinkerer's Workshop" / "Deposit Discovery"; cross-ref 7b B-CS1, System 10)
- **A-CS4.** The entire advanced catalog is single-threaded through Silicon → the Stone Processing II upgrade; this hard dependency is unacknowledged. (§4 — `04` "Stone Processing I" / "Tinkerer's Workshop")
- **A-CS5.** Luxury goods' "faction-reward value" is asserted but unwired — only `TechAchievement` credits them; no SEED formula has a luxury term. (§4 — `04` "Fabrication"; `06` "SEED Factions")
- **A-P1.** The bootstrap deadlock and the Silicon chokepoint have no in-game legibility signal. (§6 — `01` "Failure should always be legible"; cross-ref System 12 run-start)

### Nice-to-have

- **A-IC2.** Tier-0 `TechAchievement` rubric says "no building prerequisite" but tier-0 Water-collection buildings need the (starting) Water Processing Plant; soften to "no non-starting prerequisite". (§3 — `04` "TechAchievement Catalog")
- **A-IC3.** Name the Seasonings carve-out as a deliberate exception in the generic-category principle's own text. (§3 — `04` "Baseline Farm/Mined Resources")
- **A-CS6.** Clarify whether an AP-Basic drone can staff Robotics Assembly. (§4 — `04` "Robotics Assembly"; cross-ref System 3)
- **A-ST2.** Give the drone Advance/Harden ladder an in-fiction frame (shielding-tech lineage). (§5 — `02` "The Crash Research Era")
- **A-ST3 / §8.** Give luxury goods a real sink (diegetic viability/morale contribution) or fold them into one generic "Luxury Good" category. (§5, §8 — `04` "Fabrication")
- **A-P2.** `TechAchievement` count-once + multi-recipe asymmetry is a mild single-number-optimisation incentive. (§6 — `01` "Numbers stay small")
- Consider whether the mid-game Silicon spine should have a second route. (§8)

### Defer (numeric / content-pass)

- **A-N1.** Per-building Lumber:Concrete ratios (catalog-wide, minus the bootstrap subset per A-S1). `04` "Building Schema".
- **A-N2.** Sawmill→Carpenter's Shop, Stone Processing I→II upgrade costs. `04` "Sawmill" / "Stone Processing I".
- **A-N3.** Smelter ratios; remaining `production_time` values. `04` "Smelter".
- **A-N4.** Development Bloc per-resource rarity weights. `06` "SEED Factions".
- **A-N5.** Fertilizer production rate; Herb/Spice drop probabilities. `04` "Baseline Farm/Mined Resources".
- **A-N6.** Drone battery capacities, recharge durations, temperature-drain curve. `04` "Robotics Assembly".
- **A-N7.** Per-Specialized-Drone "category-flavored input". `04` "Robotics Assembly".
- **A-N8.** Per-planet Herb/Spice rosters + their Gourmet recipes. `04` "Baseline Farm/Mined Resources" (cross-ref System 8).
