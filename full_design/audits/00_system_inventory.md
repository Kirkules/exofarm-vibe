# System Inventory — Design Audit Backlog

Enumerates the game's mechanical systems as independently-auditable units, plus
the cross-cutting concerns each audit checks against. Regenerated from
`full_design/` (01–08) and `DESIGN_TODO.md`; grouping is a judgment call and can
be re-split or merged.

One audit report per system, at `full_design/audits/NN_<system>.md`. This is a
**pure design audit** — no implementation exists; `full_design/` is the sole
source of truth.

Status: audit **#1 done** (`01_grid_placement_and_construction.md`); **#2–12
batched**.

---

## Audit process

Each audit reads the design for one system and writes a report with these 9
sections. It reports findings; it does **not** edit the design docs.

1. **Scope & inventory** — every mechanic, rule, and entity the system owns,
   each with the design-doc section it's specified in. Fix the boundary; flag
   anything ambiguous about whether it belongs here or to an adjacent system.
2. **Completeness gaps** — undefined behaviour, open questions, TBDs between the
   text and a buildable spec. Split **Structural** (blocks implementation /
   forces a fresh design decision) vs. **Numeric** (deferred-to-balancing value,
   catalogued only). Cross-check `DESIGN_TODO.md`; confirm exhaustive or extend.
3. **Internal consistency** — contradictions within the system's own spec.
4. **Cross-system consistency** — where this system's rules meet another's:
   gaps, contradictions, unclear ownership, timing mismatches.
5. **Story & world consistency** — does every mechanic square with the fiction
   in `02_story_and_world.md` (and the story-load-bearing bits in `03`/`06`)?
   Flag mechanics that imply something the fiction rules out, contradict lore,
   or where mechanic and story could reinforce each other and currently don't.
6. **Design-principle adherence** — walk all 13 principles in
   `01_design_principles.md`; flag violations and risks.
7. **Player legibility** — can the player learn the system exists and enough of
   how it works through play? Is a bad outcome's cause inferable?
8. **Fun / scope risk** — does the complexity earn its keep? Anything pushing
   toward one-metric optimisation / narrowed playstyles? Cut-or-simplify
   candidates.
9. **Findings summary** — the single authoritative list. Every finding from
   §2–8 appears here once, one line each, under **Blockers / Should-fix /
   Nice-to-have / Defer**, with a pointer back to its section and the
   design-doc location. §2–8 carry the reasoning; §9 does not restate it.

**Adjustments (from the pilot):**
- **§9 is the index, not a re-run of §2–8.** Keep §2–8 terse and specific; §9 is
  one line per finding. (The pilot's §9 restated §2–8 verbatim — don't.)
- **Large systems may split.** #7, #10, #11 may write two files
  (`NNa_<...>.md` / `NNb_<...>.md`) if genuinely separable; state the split
  rationale in each. Otherwise one file.

**Constraints:** create only the report file(s); touch nothing else — not the
numbered design docs, not `DESIGN_TODO.md`, not this file. Cite a concrete
design-doc location for every finding. Plain `file` → "Section" citations, no
anchor links (the repo link-checker only scans `full_design/*.md`). Flag
findings, don't fix them; at most a one-line "possible direction" per structural
gap.

**Consolidation:** once all 12 are done, gather every §9 finding into
`DESIGN_TODO.md`.

---

## The 12 Systems

### 1. Grid, Placement & Construction  *(done)*
- **Scope:** the single unified grid (working target 10×8); uniform single-cell
  placement; fixed non-rotatable multi-slot footprints; fixed/environmental
  slots (impassable terrain, deposits, Forest tiles) set at run start; the one
  starting construction robot (+ more from Robotics Assembly); build / upgrade /
  relocate actions and their next-season resolution; automatic robot assignment;
  the N-actions-per-season cap; placement-validity checks (footprint-expanding
  upgrades, deposit-gated relocation).
- **Design sources:** 03 The Grid (Unified), What Got Cut, Construction, Small
  Set of Impactful Actions; 04 Building Schema.
- **Key entanglements:** Worker Assignment (slot count = worker capacity),
  Production Model, Deposit Discovery, Hazards (storm destruction frees slots),
  Meta / Run-Start (Farm Site Selection generates the grid instance).

### 2. Season Structure & Simulation Flow
- **Scope:** Planning Phase; Planning Lock-in; Mid-Sim (30s @ 1×, the only
  real-time window) and Post-Sim (instantaneous) and its fixed internal
  sub-step order; playback-speed slider (0×–5×, 0.1 steps, 0× = pause, sticky
  default); the single toggleable log / event-feed (aggregated per-resource
  production lines + individual noteworthy-event lines); Transmissions as a
  separate persistent channel; the assigned-worker Mid-Sim depiction.
- **Design sources:** 03 Season Structure; 02 Gameplay-Story Integration; 03
  Small Set of Impactful Actions; `DESIGN_TODO.md` "Season simulation".
- **Key entanglements:** every system that resolves an outcome (timing/ordering);
  Hazards (Mid-Sim events); Exploration (confirmation UI at next planning start).

### 3. Worker Assignment, Roster & Site Panel
- **Scope:** the Assignment mechanic (one worker ↔ one target); the three target
  kinds (Production building / Exploration Task / Standing Assignment) and their
  differing stickiness; settlers vs. drones as worker types; 1.0-Effort settler
  baseline; Effort-stacking toward a per-site production cap; Worker Roster UI
  (per-type A/B rows, hover-highlight, drag-to-assign, Mid-Sim per-worker
  expansion); Site Panel UI (recipe section, worker slot, rate summary, status
  section, per-element tooltips).
- **Design sources:** 03 Assignment, Worker Roster (UI), Site Panel (UI); 04
  Robotics Assembly (drone Effort / eligibility / battery); 05 Settler State
  (assignment stickiness), Standing Assignments (worker eligibility).
- **Key entanglements:** Production Model, Energy (Site Panel power indicator),
  Settlers (Aptitude / Experience / Storied modifiers), Resource Economy
  (drones).

### 4. Production Model
- **Scope:** continuous-rate production (`100% / production_time` per sec, rate
  modified not countdown-reset); one primary input→output per site; multi-recipe
  selection (sticky, reversible); the plant-crop three-phase
  Planting → Growing → Harvesting cycle (Effort-driven planting/harvesting,
  Water-gated idle growing); instant conversion (Ration Press); the production
  progress overlay (sprite-shaped fill) and its farm-specific phase-colored
  variant with icon badges.
- **Design sources:** 03 Production Model, Season Structure (overlay); 04
  Farm/Production (Production Cycle, Alien Soil, water-draw queue), Building
  Schema (recipes, production cap), Food/Meal Conversion (Ration Press).
- **Key entanglements:** Water (Growing-phase reservation queue), Energy,
  Fabrication chains, Fertilizer / Hybridization (Alien Soil), Worker
  Assignment.

### 5. Energy
- **Scope:** live Income / Consumption rates, no stockpile ever; Reliable (Solar
  Array, Geothermal) vs. Conditional (Fuel-based Generator) income; per-building
  flat baseline consumption + event-elevated consumption (shields, drone
  recharge); random consumer-shedding on shortfall, recomputed only on real
  change events; per-building active/inactive toggle; planning-phase optimistic
  Income bar; Green / Yellow / Red per-building power prediction (shape-coded);
  temperature-coupled upkeep on enclosed/protected structures.
- **Design sources:** 04 Resources (Energy Income/Consumption Rates), Basic
  Resource Production, Fuel; 06 Exoplanet Types (temperature coupling); 04
  Protection (shield upkeep).
- **Key entanglements:** Water (parallel rate model), Hazards (shield cost,
  Temperature Extremity), Resource Economy (drone battery recharge), Worker
  Assignment (Site Panel).

### 6. Water
- **Scope:** live Water Income rate (same shape as Energy), no stockpile;
  collection buildings (Condenser / Ice Melter / Cistern / Well→Deep Well) all
  gated behind the starting Water Processing Plant; Reclamation upgrade
  (consumption-rate reduction, HTC-gated); binary once-per-season settler-death
  check (zero Water Income anywhere → all settlers die; any nonzero → safe); the
  settlement-wide strict-FIFO plant-crop Growing-phase reservation queue;
  **undefined** insufficient-Water behaviour for the animal-based buildings.
- **Design sources:** 04 Water; 04 Farm/Production (water-draw queue);
  `DESIGN_TODO.md` (Water resource open threads).
- **Key entanglements:** Energy (rate-model twin), Production Model (queue),
  Settlers (death check), Planet Types (collection-building suitability).

### 7. Resource Economy, Fabrication & Deposits  *(may split)*
- **Scope:** the Building Schema (universal + conditional properties, recipes,
  upgrade tiers, `TechAchievement` rubric); baseline resource categories;
  refined chains (Smelter, Stone Processing I/II, Sawmill, Textile Workshop,
  Tinkerer's Workshop, Carpenter's Shop) and the Lumber+Concrete universal-cost
  model; Fertilizer; Seasonings; luxury goods; Robotics Assembly and the full
  drone taxonomy (Basic/Advanced × Hardened, All-Purpose vs. Specialized, Effort
  values, task eligibility, season-reset battery); mining buildings; Deposit
  Discovery (hidden deposits, 3 depth tiers, overlap rules, Thermal Vent /
  Fossil Fuel / aquifer); Basic & Deep Survey standing assignments; Scanner
  Station Deposit Scanning mode.
- **Design sources:** 04 Resources, Building Schema, TechAchievement Catalog,
  Basic Resource Production, Deposit Discovery, Fabrication; 05 Standing
  Assignments; 06 SEED Factions (Development Bloc, Stewardship
  Extraction/Emissions); `DESIGN_TODO.md` (Fabrication chain).
- **Key entanglements:** nearly everything downstream; Scoring.
- **Split option:** `07a` Economy & Fabrication / `07b` Deposits & Surveys.

### 8. Food & Nutrition
- **Scope:** the P/F/C/V nutrient axes; Rations (finite non-replenishable
  starting stock; Ration Press lossy `floor(min(P,F,C,V)/2)` instant
  conversion; strict Rations-only cost for exploring settlers); pooled
  (settlement-level) consumption with the 4-step food-for-consumption default
  ladder; two-tier consequence model (bulk shortfall → deaths by lot; axis
  imbalance → score-only); Kitchen (base / Upgraded combo + flavor-name pools /
  settler-specific Gourmet / alliance-gated Local Delicacy); Food Storage
  (commit-to-store, capacity-limited, feeds `NutritionStockpile`); the
  end-of-run Food Security score.
- **Design sources:** 05 Food & Nutrition; 04 Food/Meal Conversion, Storage; 06
  SEED Factions (Sustenance Bloc); 03 Season Structure (Post-Sim nutrition
  sub-step).
- **Key entanglements:** Settlers (headcount, deaths), Exploration (Ration
  cost), Scoring, Season Structure.

### 9. Settlers
- **Scope:** Settler State (`current_assignment`, `status_effect` list,
  `legend_value` list, `experience` stacks, `aptitude` levels,
  `gourmet_recipes`); Crew Selection (3 archetypes — Average /
  Jack-of-several-trades / Savant — per-settler balance, free uncapped reroll);
  Aptitude (−3..+3, innate, 6 buckets, special Exploration bucket ladder);
  Experience (0–3 stacks per task group, earned, permanent); Storied; Injuries
  (SP vs. 4 Permanent types; Outdoor/Fieldwork & Manual Labor groupings;
  risk-tier severity gating; Medical Bay parallel-heal); death = roster removal;
  the narrative-only-flavor boundary.
- **Design sources:** 05 Settlers, Settler State, Injuries, Storied, Experience,
  Aptitude; 03 Crew Selection; 02 Narrative-Only Flavor.
- **Key entanglements:** Worker Assignment, Exploration, Hazards (status
  effects, death), Scoring (Frontier Legends), Food & Nutrition.

### 10. Exploration, Standing Assignments & Escalation Chains  *(may split)*
- **Scope:** the always-available pool of ≤3 (max 5) tasks; refresh /
  Rations-cost reroll / free lock / in-progress exemption; seasons-to-complete =
  Ration cost; the Risk Spectrum (No/Low/High) and its severity gating; four
  positive outcome categories; Profile-shifting / Reinforcing / Neutral framing
  vs. strategy dimensions; the full task catalog + per-planet exclusives +
  Meteorite Fragment + Unknown Radio Signal branching; the sentience-contact
  chain (Sentience Detection → Observe → First Contact with 3 approaches), alien
  civilization classes, `ContactRestraint`; Trade Agreements; the four Standing
  Assignments (Basic/Deep Survey, Clear-Cutting, Trapping) and their
  worker-eligibility rules.
- **Design sources:** 05 Exploration Tasks, Escalation Chains, Risk Spectrum,
  Standing Assignments, Outcomes and the Strategy Dimensions; 03 Assignment; 06
  SEED Factions, Data-Gathering Mechanism; 04 Food/Meal Conversion (Local
  Delicacy), Protection (vaccine region reveal); `DESIGN_TODO.md` (alien
  classes, alien trade).
- **Key entanglements:** Settlers, Food (Rations), Hazards (Confidence bursts,
  bio-survey), Scoring (all five factions), Kitchen.
- **Split option:** `10a` Exploration Tasks & Standing Assignments / `10b`
  Escalation Chains, Alien Contact & Trade Agreements.

### 11. Hazards, Protection & Data-Gathering  *(may split)*
- **Scope:** Hazard Priors / `TrueRisk` (Weather & Bio-hazard, 5 sub-factors);
  the hidden Beta(a,b) data-gathering mechanism → `MatchedRisk` & `Confidence`;
  per-sub-factor data sources & report text; In-Simulation Hazard Events (Storm
  & Temperature Extremity only; mild/extreme bands; ≤1 each per season;
  independent stacking); `Confidence`-scaled telegraphing via Transmissions +
  the one-time run-start SEED summary; per-site Average Temperature (72°F
  target); consequence chains (production slowed/stopped/destroyed; settler
  status-effect / death); Atmospheric Hazard as a continuous PPE stock-check;
  Protection buildings (Weather Shield, Row Shield, Medical Bay base / Vaccine
  Production / PPE / Emergency Medical Kit); `MatchedPreparedness`.
- **Design sources:** 06 Hazard Priors, Data-Gathering Mechanism, In-Simulation
  Hazard Events, SEED Factions (Safeguard Coalition); 04 Protection; 02
  Gameplay-Story Integration.
- **Key entanglements:** Energy (shield cost), Season Structure (Mid-Sim
  events), Settlers, Scoring (Safeguard), Exploration (bio-survey, vaccine
  region reveal), Planet Types.
- **Split option:** `11a` Data-Gathering & Hazard Events / `11b` Protection
  buildings & Preparedness.

### 12. Meta-Progression, Earth Hub & Run-Start Flow
- **Scope:** the Design Catalog and its across-run growth (gather enough of a
  new resource type → Earth develops new designs → permanent unlock); Earth hub
  contents (Design browser, Exoplanet catalog, Run history, Start run, SEED
  Bulletin); the run-start sequence — hub landing → Crew Selection → expedition
  commitment / filament scan → Farm Site Selection → starting-building &
  starting-Rations setup → run-start SEED summary transmission → Season 1
  planning; Run History presentation; Settings screen(s); persistent player-AI
  ("Herald") identity across runs.
- **Design sources:** 02 Meta-Progression & Earth Hub, Background Story; 03 Crew
  Selection, Farm Site Selection, Technology & Progression (Across Runs); 06
  In-Simulation Hazard Events (run-start summary); 07 Backend & Data
  Persistence; `DESIGN_TODO.md` (Run-start flow — an explicit open gap).
- **Key entanglements:** Settlers (Crew Selection), Grid (Farm Site Selection
  seeds terrain / deposits), Hazards (run-start summary), Scoring (Run History).

---

## Cross-Cutting Concerns

Not audited as standalone systems — every per-system audit checks its subject
against each (mostly in §4–6):

- **Design Principles (all 13)** — `01_design_principles.md`. Numbers stay
  small; units unspecified; minimal UI interaction; planning reversibility
  (incl. randomization gating); passable-plan-quick; naming convention;
  colour-not-sole-channel; dexterity-timing single scale; touch/mouse parity;
  text-legibility ceiling; failure legibility; difficulty from breadth of
  tradeoffs; forgiving of mistakes / punishing of neglect; normalize before
  combining unrelated values; docs describe current design not its history.
- **SEED Faction scoring** — `06` Win / Lose Conditions. Does the system feed the
  formulas it's meant to (Sustenance / Safeguard / Stewardship / Development /
  Frontier Legends), with the right quantities, at the right time, normalized?
- **Planet Types & strategy dimensions (Protection/Enclosure, Biosphere
  Integration, Synthesis/Self-Sufficiency, Energy Management)** — `06` Exoplanet Types. Does
  the system express meaningfully different pressure across planet types without
  reducing any planet to one correct strategy?
- **Narrative / Transmissions integration** — `02` Gameplay-Story Integration.
  Does the system's player-facing communication route through the established
  channels (Transmissions, simulation log, tooltips) rather than inventing new
  surfaces?
