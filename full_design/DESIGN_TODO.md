# Design To-Do

The open-work queue for `full_design/`. Every entry here is work still to be
done; resolved work is removed rather than archived, and what changed and why
lives in git history.

Items carrying a citation tag (`5-B3`, `11-SF14`, …) came from the per-system
design audit whose full reports live in `full_design/audits/` (indexed by
`audits/00_system_inventory.md`). `7a`/`7b` and `10a`/`10b` are split reports.
Tags are kept so an item can still be traced back to its report's full
rationale.

---

## Run Structure & Meta-Progression

- [ ] **Author the Initiative trees** — the structure is settled (see Story &
  World's [Meta-Progression](02_story_and_world.md#meta-progression)); the content is not. Five trees in
  `data/faction_initiatives.csv`, currently holding three Initiatives.
  Needed per Initiative: name, Type, effect, where its mechanic is defined,
  prerequisites, and any cross-faction Favor gate. Every tree wants
  **Capability** entries, not only Capacity — a tree of Capacity raises the
  floor without widening the game. Absorbs `12-B2` and `12-SF3` (cross-run
  variation on the starting loadout is an Initiative effect like any other).
  Fodder, not yet placed in a tree:
  - Frontier Legends' recruitment ramp guaranteeing every future crew one
    legendary-tier "hero" settler.
  - A technology humans do not (and in-fiction never would) invent on their
    own, reached through trade with an advanced alien species.
  - Widening or cheapening the Specialization pool — affording an advanced
    worker, or two directions at once — alongside the mass-budget raise
    Wormhole Stabilization already covers.
- [ ] **Settle the Favor payout formula** — a rising bar with flat yield above
  it is the agreed shape, and `data/misc_balancing_values.csv`'s "Favor" rows
  hold its three constants at TBD. The final formula waits on Initiative
  costs, which wait on the trees being authored.
- [ ] **The unlocked content behind the three seeded Initiatives** — Protein
  Reform's tiny-animal husbandry does not exist in `04` at all; Thin-Film
  Photovoltaics needs a Solar Array variant and its construction costs.
- [ ] **Author the final run** — Story mode's last expedition, played from
  the expedition's own side with no Transmissions (see Story & World's
  [Modes](02_story_and_world.md#modes)). The exposition for it is unwritten, and can be written after
  the rest of the game is built. Two mechanical consequences need answers
  first: hazard telegraphs and the run-start SEED summary both travel by
  Transmissions, so the final run has neither — which removes the counterplay
  that makes scheduled hazards legible (see Planets & Scoring's
  [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)) and sits against the design principle that no
  untelegraphed event should end a run. And with no Earth to report to,
  whether the final run is scored at all — and what its faction scores would
  mean — is undecided.
- [ ] **Author the curated planets and scripted cutscenes** for Story mode.
- [ ] **Author the final run's ending** — it has no run-length clock (see
  Story & World's [Modes](02_story_and_world.md#modes)), so a story beat has to end it: the settlement
  stable enough and enough settlers remaining, resolving into exposition
  about the colony holding and children born on the planet. Needs the
  concrete trigger — the working idea is a behind-the-scenes check that the
  player *would* have scored well enough on an ordinary run, plus a settler
  headcount — and the exposition itself, which can be written after the rest
  of the game is built.
- [ ] **Confirm the capped-score rule covers every failure path.** A failed
  run now scores normally but capped at the faction's Favor bar (see Planets
  & Scoring's [Critical Failure (Early End)](06_planets_and_scoring.md#critical-failure-early-end)), which pays no Favor and still
  records a score. Written against colony-wide death and a missing Beacon;
  wants a pass over any other failure path to confirm nothing needs
  different treatment.
- [ ] **Deep Space Beacon's remaining values** — construction-cost
  quantities at the intended mid tier, Energy draw while broadcasting, and
  quantities (`data/building_construction_costs.csv`). The survey's base
  chance is set at 0.5; what remains is whether its tail needs bounding —
  an unboosted explorer still fails four straight attempts 6% of the time,
  against a hard run requirement.
- [ ] **Author a fifth planet archetype as the worked Access Initiative.**
  Planet types are now picked like classes and extended by Access
  Initiatives (see Story & World's [Choosing a Planet](02_story_and_world.md#choosing-a-planet)), but `Access` still
  has no entry in `data/faction_initiatives.csv` and no fifth type exists.
  Needs the archetype itself — identity, strategy-dimension pressure, hazard
  priors, resource profile — plus which faction's tree it belongs to.
- [ ] **What a rerolled candidate actually varies.** Rerolling within an
  archetype re-rolls "the specifics" — deposits, hazard priors, terrain —
  but the generation ranges are undefined, and `06`'s per-planet pressure
  distribution and terrain layout are open threads feeding the same
  question. Determines whether two Frozen worlds feel meaningfully
  different or interchangeable.
- [ ] **Where the seed-ship decision sits relative to the final run.** Story
  mode's closing beat has the player choose which successful-run planet gets
  humanity's last seed-ship (see Story & World's [Run History](02_story_and_world.md#run-history)), but the
  final run is played with Earth already destroyed — so who dispatches the
  ship, and whether the choice comes before that run, after it as an
  epilogue, or in flashback, is unwritten. Part of the final run's
  exposition pass.
- [ ] **Settings screen(s) (`12-SF5`)** — not designed anywhere. Wanted: one
  consolidated spec covering °F/°C, a global dexterity/gesture-timing scale,
  volume, an optional larger-font tier, drag-offset, and whether settings
  are reachable in-run as well as from the hub.
- [ ] **Interruptibility, and `07`'s persistence assumptions (`12-SF6`)** —
  resolve the open interruptibility principle here, and re-base Production &
  Technical's [Backend & Data Persistence](07_production_and_technical.md#backend--data-persistence) off its Android-lifecycle
  assumptions (it still cites `NOTIFICATION_APPLICATION_PAUSED` as critical
  on Android, from the deleted mobile design).
- [ ] **Where the one-time Herald-naming step lives (`12-SF9`)** — presumes
  an undesigned first-run intro/tutorial. Story & World establishes "Herald"
  as a title prefixed to a player-chosen name, but nothing says where the
  player supplies that name.
- [ ] **Add SEED Bulletin to the "Earth Hub Contents" enumeration
  (`12-SF8`)** — Story & World describes the SEED Bulletin as a hub panel,
  but [Earth Hub Contents](02_story_and_world.md#earth-hub-contents) still lists five destinations without it.
- [ ] **The Roadmap's completed-work checklist describes deleted code.**
  `08_roadmap.md`'s Phase 0-2 items are ticked off — polyomino shapes and
  rotation, Energy + Matter with seasonal regeneration and storage
  overflow, the broadcast-range power network, greenhouse piece
  definitions, the double-tap building toggle — all from the pre-redesign
  prototype that no longer exists (see `CLAUDE.md`). As written, the
  roadmap claims a foundation the project doesn't have, and several ticked
  items describe mechanics the current design has since replaced. Needs a
  rebuild against the current design rather than line-edits.

---

## Grid, Placement & Construction

- [ ] **Whether shields run through the construction-robot economy at all
  (`1-B1`)** — Core Loop & Grid's [Small Set of Impactful Actions (Current Draft)](03_core_loop_and_grid.md#small-set-of-impactful-actions-current-draft)
  still lists "place/reposition a force-field or weather-protection
  structure" (#3) as its own action alongside "queue a building construction
  or upgrade" (#1). Determines the action economy and whether the player can
  react to a per-season hazard forecast.
- [ ] **Building on an undiscovered deposit tile, and its silent
  `DisruptionFootprint` (`1-SF2`)** — needs a general building-on-a-feature
  rule. Referenced as open from Core Loop & Grid's
  [Starting Settlement Placement](03_core_loop_and_grid.md#starting-settlement-placement), which defers the covering-a-visible-feature
  case to it.
- [ ] **Add an "except via exploration Site Reveal" carve-out (`1-SF3`)** —
  Core Loop & Grid's [The Grid (Unified)](03_core_loop_and_grid.md#the-grid-unified) says fixed/environmental slots are
  "set at run start; cannot be moved or removed", while a Site Reveal
  outcome (see Settlers & Exploration's [Outcomes](05_settlers_and_exploration.md#outcomes)) transforms a grid feature
  into a new accessible site.
- [ ] **Explicit cause messaging for blocked/greyed grid actions
  (`1-SF5`)** — the Site Panel's disabled worker slot is the only case
  currently specified; there's no general rule that a refused placement,
  upgrade, or assignment says *why*.
- [ ] **Transition-season behaviour of an upgrading/relocating building
  (`1-SF7`)** — what the building does during the season its
  upgrade/relocation is resolving, and whether its worker is retained.
- [ ] **Add a "deposit overlap audit" item.** Core Loop & Grid's
  [Construction](03_core_loop_and_grid.md#construction) and Buildings & Economy's [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery) both cite a
  deposit-overlap audit — whether a single tile can hold more than one type
  of extractable resource, and what that means for the buildings that sit on
  it — that was never written. (audit `7b`)

---

## Season Structure & Simulation

- [ ] **State that prior Post-Sim outcomes are final (`2-SF6`)** — nothing
  says a resolved season outcome can't be unwound by the next planning
  phase's reversibility.
- [ ] **Event log lines must carry luck-vs-certainty detail (`2-SF8`)** —
  for retrospective legibility, a log line should distinguish "this was
  always going to happen given your plan" from "this was an unlucky roll".
  Energy's un-powering lines already do; nothing else does — the hazard
  post-event log is now specified this way (see Planets & Scoring's
  [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)) and is the pattern to generalize from.
- [ ] **Per-building production-progress overlay color/icon mapping.** The
  farm-specific overlay variant (see Core Loop & Grid's
  [Season Structure](03_core_loop_and_grid.md#season-structure) and Buildings & Economy's
  [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model)) resets and recolors per transition with a
  redundant icon badge, but the exact color/icon mapping still needs
  authoring **per building**, since each of the four plant-crop buildings
  now has its own distinct state count and shape rather than one shared
  three-phase brown/green/gold mapping. An Art Design item.
- [ ] **Planning-phase undo/redo** — add a planning-wide undo/redo action
  covering every reversible planning choice (placement, assignment, queue
  edits, food-for-consumption, construction queuing): redo available after
  an undo only while nothing new has changed, undo reachable back to the
  start of the planning phase.
- [ ] **Every game element needs a hover tooltip.** Tooltips are specified
  ad hoc today — the Site Panel gives each of its elements one, food items
  have a nutrient-profile tooltip, the Energy bar has a caveat tooltip —
  but there's no blanket rule, so new surfaces keep having to decide
  individually. Wanted: hover detail on *every* element carrying state a
  player might question, grid tiles included (deposit/aquifer type, depth,
  what's still unrevealed — the detail deliberately kept out of the binary
  grid glyph). Needs a consistent content convention (plain language, no
  formulas, per the existing Site Panel precedent) and a decision on
  touch-equivalent access.

---

## Production Model & Buildings

- [ ] **Fertilizer's per-season consumption quantity (`4-SF2`, `7a-A-S3`)**
  — settlement-wide boolean vs. rationed, and how much is actually consumed
  (a settlement-wide unit, or per plant-crop building). Buildings & Economy
  says Alien Soil's penalty is "removed for any season Fertilizer is
  available … consumed automatically", which leaves the amount unstated.
  Sets whether Fertilizer is a real cost or a trivial side-effect.
- [ ] **Hazard slowed/stopped behaviour for a plant-crop building
  mid-transition (`4-SF3`)** — Planets & Scoring defines slowed/stopped for
  production generally, but not for a building partway through a specific
  state transition, and not whether a stopped passive/biological-wait
  transition holds or releases its Water reservation.
- [ ] **Quantify "slowed" as a rate multiplier (`4-SF4`)** — one shared
  value used by both Storm and Temperature Extremity; no value exists
  anywhere in the data sheets.
- [ ] **What the Site Panel's combined rate means for a multi-transition
  plant-crop building (`4-SF10`)** — and the expected-yield legibility risk
  of showing one number for a building whose transitions differ in kind.
- [ ] **Ration Press's timing model contradicts itself between sections.**
  Buildings & Economy's [Building Schema](04_buildings_and_economy.md#building-schema) (Output property) cites Ration
  Press as *the* example of "instant conversion" (`production_time`-free,
  no staffing, no rate limit, player selects Input directly during
  planning). [Ration Press](04_buildings_and_economy.md#ration-press)'s own section instead describes it as
  **cycle-based**: it runs its selected recipe each cycle during Mid-Sim,
  consumes inputs at cycle start, and carries an ordinary production queue
  with cycle limits. These can't both be true as written — and whether
  Ration Press should be re-pointed-to as the instant-conversion example is
  a separate question from whether the Building Schema's Output property
  still needs an instant-conversion alternative at all.
- [ ] **Multi-item production by skilled workers** — a high-Experience or
  high-Aptitude worker at certain sites should be able to produce
  **multiple item types at once** in a single production step, rather than
  the production queue's normal one-recipe-at-a-time sequencing. Motivation:
  as a run's commitments compound, the worker count needed to keep every
  early-tier recipe staffed separately grows fast; letting a skilled worker
  combine several low-tier outputs into one step is meant to blunt that
  growth without removing the underlying complexity. Needs careful
  integration with the production queue (see Buildings & Economy's
  [Building Schema](04_buildings_and_economy.md#building-schema) "Production queue") — this is a different kind of step
  (parallel outputs) than the queue's sequencing (ordered outputs) and the
  two need to compose cleanly. Which sites/tiers/skill thresholds qualify
  is entirely open.
- [ ] **Rebuilding a demolished starting building.** Once a
  demolish-building mechanic exists (not yet designed), rebuilding a
  demolished Water Processing Plant (see Buildings & Economy's
  [Water Processing Plant](04_buildings_and_economy.md#water-processing-plant)) via normal construction should become
  possible. A forward dependency, not resolved now.
- [ ] **Luxury-item catalog & Habitation boosts** — Luxury Living Quarters
  (see Buildings & Economy's [Habitation](04_buildings_and_economy.md#habitation)) gives one luxury-item slot per
  settler; each *distinct* luxury item held in a slot grants one
  settlement-wide boost. Undesigned: which luxury items exist, where they
  come from (fabrication? Trade Agreements? alliance rewards?), what each
  one boosts, and how strong the boosts are.
- [ ] **Fusion Generator — Solar Array's eventual late tier.** A late Solar
  Array tier is a natural place to pay off the Crash Research Era's
  controlled-fusion lore (see Buildings & Economy's
  [Solar Array](04_buildings_and_economy.md#solar-array)), e.g. eventually becoming a
  distinct Fusion Generator. `TechAchievement` and every other property TBD
  once this tier is actually designed — currently just a lore hook, not a
  design.
- [ ] **Hydroelectric Generator + River feature** — surfaced as a side note
  during the Energy Pool redesign, not yet designed. Would need a new
  **River** grid feature first — checked, and confirmed this was only ever
  mentioned conceptually during the original Water design pass, never
  actually formalized as a feature anywhere. A genuinely new piece of scope.

---

## Energy & Water

- [ ] **Per-building Green/Yellow/Red prediction needs an apportionment rule
  (`5-B2`)** — Buildings & Economy's [Resources](04_buildings_and_economy.md#resources) and Core Loop & Grid's
  [Site Panel (UI)](03_core_loop_and_grid.md#site-panel-ui) both phrase the indicator as whether Income covers a
  building's "share", but no rule says how total Income is apportioned into
  a per-building share.
- [ ] **Fuel-based Generator post-season "burned X of Y" readout
  (`5-SF8`)** — the fuel limit itself is now an ordinary production-queue
  step `limit` (sticky and reversible like any planning choice), but nothing
  reports back how much of it was actually consumed.
- [ ] **Animal-building Water draw (`6-B1`).** The three animal-based
  buildings (Dairy Pasture, Poultry Coop, Sheep Pasture — see Buildings &
  Economy's [Farm/Production](04_buildings_and_economy.md#farmproduction)) draw a flat amount per cycle, but a "flat
  per-cycle" amount has no defined way to draw from a stockless rate, and
  nothing specifies what happens when available Water Income can't cover it
  — unlike the plant-crop buildings' reservation pool. Goal remains getting
  *all* water usage across the catalog into a fully designed state.
- [ ] **Warning/confirmation gate for a season that will trigger the
  zero-Water wipe (`6-SF1`)** — the check is now infrastructure-existence
  only (see Buildings & Economy's [Water](04_buildings_and_economy.md#water)), but the player still gets no
  explicit confirm before committing a season with no functioning
  collection building.
- [ ] **Confirm the Deep Well auto-upgrade and a Water-denied transition
  emit log/Transmission lines (`6-SF8`)** — both are silent state changes
  today.

---

## Economy, Fabrication & Deposits

- [ ] **Fabrication chain revisit — still open pieces:**
  - Per-building **Lumber:Concrete construction-cost ratios** across the
    whole catalog — the rule (and Quarry's specific small-Lumber-only cost)
    is established, but the actual ratio for every other building is still
    unassigned in `data/building_construction_costs.csv`. Bootstrap-critical
    rows need pricing before the general balancing pass.
  - Sawmill→Carpenter's Shop and Stone Processing I→II **upgrade costs** —
    TBD.
- [ ] **Rare resources and their high-tech uses are unspecified.** "A rare
  metal" is currently one undifferentiated input, and the design has no
  roster of what rare raw resources exist, how they differ, or what they're
  for. Intended shape: **several** distinct rare resources, each feeding
  specialized, not-every-run high-tech content rather than the critical
  path — sci-fi payoffs a run may or may not reach. Ideas floated:
  PPE-style personal shielding suits for settlers, small-radius
  time-dilation bubbles. Needs the roster itself, which planets favour
  which, and the uses each unlocks — deliberately *not* gating anything the
  ordinary tech spine needs. (Portable High-Powered Scanning Equipment was
  moved off rare metals to Iron + Copper for exactly this reason — see
  Buildings & Economy's [Tinkerer's Workshop](04_buildings_and_economy.md#tinkerers-workshop).)
- [ ] **Glass — broader uses** — Glass is currently input only to High-Tech
  Components, Temperature-Resistant Gear, PPE, and Biological Lab Materials.
  Worth 1–2 more homes so it isn't a one-purpose material — candidates:
  further hazard-resistant gear, a Luxury Good, Scanner Station optics.
- [ ] **Seasoning drop cadence for continuous sources (`7a-A-S4`)** — Herbs
  drop during Clear-Cutting/Surveys and Spices during Mining, but nothing
  says whether the chance is rolled per production cycle or once per season.
- [ ] **Multi-recipe items get one `TechAchievement` tier that can exceed
  their cheapest recipe's cost (`7a-A-IC1`)** — an item reachable by more
  than one recipe scores the same regardless of which path produced it.
- [ ] **Sawmill is unplaced in the skill taxonomies
  (`7a-A-IC4`/`A-CS1`/`A-CS2`)** — Settlers & Exploration's [Experience](05_settlers_and_exploration.md#experience)
  groups, [Aptitude](05_settlers_and_exploration.md#aptitude) buckets, and the Manual-Labor grouping under
  [Injuries](05_settlers_and_exploration.md#injuries) now place Smelter, Textile Workshop, Stone Processing and the
  rest, but Sawmill — a *starting* staffed building — appears in none of
  them.
- [ ] **The Silicon chokepoint (`7a-A-CS4`, `7a-A-P1`)** — the entire
  advanced catalog is single-threaded through Silicon → the Stone Processing
  II upgrade. Buildings & Economy's [Tinkerer's Workshop](04_buildings_and_economy.md#tinkerers-workshop) now names this as a
  deliberate single chokepoint, but it still has no in-game legibility
  signal — nothing tells a player mid-run that this one upgrade is what's
  gating everything ahead of them.
- [ ] **"On success" for a Survey is undefined (`7b-B-S2`)** — Buildings &
  Economy's [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery) phrases both surveys' results as "on success",
  but Standing Assignments are specified as safe with no risk spectrum, so
  it's unclear whether there is a success/failure roll at all or whether
  this just means "on completion".
- [ ] **Basic Deposit Survey's required "basic tools" are unspecified
  (`7b-B-S3`)** — still TBD in `data/misc_balancing_values.csv`. A
  fabricated prerequisite would break its Season-1 availability.
- [ ] **Deep Survey with no flagged tiles needs a UI guard (`7b-B-IC3`)** —
  it can be fabricated-for and assigned with zero effect when nothing is
  deep-survey-eligible; the doc acknowledges the case but specifies no
  guard.
- [ ] **Iron Ore vs. Copper Ore need one consistent representation
  (`7b-B-S4`/`B-IC1`)** — Buildings & Economy's [Basic Resources](04_buildings_and_economy.md#basic-resources) describes
  them as "mined from distinct deposits" *and* as a single site with a
  "70% Iron / 30% Copper" mixed distribution, while [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery)
  treats "Ore" as one of six deposit types.
- [ ] **The Stewardship `DisruptionFootprint` penalty for discovering and
  mining a discovery-gated (especially Deep) deposit is invisible when the
  player commits (`7b-B-CS3`)** — the cost accrues on grid-slot state
  change, after the decision has already been made.

---

## Food & Nutrition

- [ ] **Tier-1 bulk-shortfall test undefined in units (`8-B1`)** — "can't
  cover the settler headcount at all" vs. the summed worked example
  (3/3/5/5 against 4/4/4/4) admit different death outcomes.
- [ ] **How many settlers die on a Tier-1 shortfall (`8-B2`)** —
  proportional to the gap, or feed-as-many-as-possible? *Who* dies is now
  settled (drawn uniformly at random from the at-home headcount); the count
  is not.
- [ ] **Gourmet dishes and Local Delicacy have no defined ingredient list,
  nutrient profile, or `production_time` (`8-B3`)**, and whether a Seasoning
  is consumed by the invention roll, by cooking, or neither is unstated —
  Buildings & Economy's [Kitchen](04_buildings_and_economy.md#kitchen) only requires one to *sit in inventory*.
- [ ] **Specify the food-for-consumption default UI surface (`8-SF1`)** —
  the auto-queued-defaults transparency bar, shown at the very start of
  planning, so the sticky default is visible rather than implicit.
- [ ] **Reconcile Tier-1's "Rations plus any meals" with raw crops and
  animal products also feeding settlers (`8-SF2`)** — Settlers &
  Exploration states both.
- [ ] **Define "food type" for the sticky-diet default (`8-SF6`)** — item id
  vs. category, and how Kitchen combo flavor-name variants are treated.
- [ ] **Visible Rations count and runway (`8-SF8`)** — the stock is finite
  and non-replenishable, and it funds both exploration and the reroll cost,
  but nothing surfaces how many seasons it covers.
- [ ] **Surface a signal that a settler is Gourmet-*eligible* (`8-SF10`)** —
  maxed Kitchen Experience plus a Seasoning in inventory is an invisible
  precondition today.

---

## Settlers & Injuries

- [ ] **Does a dead settler's `legend_value` persist into the Frontier
  Legends totals (`9-SF4`)?** Both faction metrics aggregate per-settler
  sums; nothing says whether removal from the roster removes the
  contribution.
- [ ] **Which `status_effect` the roster's single "hazard-affected" icon
  shows when a settler carries more than one (`9-SF5`)** — the
  `status_effect` list is explicitly concurrent, the icon is singular.
- [ ] **Permanent-injury effects must be surfaced on the settler (`9-SF6`)**
  — not left to be inferred from failed attempts or a slower site.
- [ ] **Explicit "X is now Storied" surface at threshold crossing
  (`9-SF8`)** — the threshold check exists; the moment isn't announced.
- [ ] **Plain-language tooltip understates stacked exploration bonuses
  (`9-SF9`)** — Storied's flat +1 and Exploration Aptitude's flat +1 add
  normally to +2, but the tooltip convention still reads "up to 1 more item
  from Exploration".
- [ ] **Remaining numeric TBDs from the Settler State / Injuries / Storied
  design pass**: Storied's `legend_value` threshold (flagged explicitly open
  in `data/misc_balancing_values.csv`); Trapping's and Clear-Cutting's
  per-settler speed rates.
- [ ] **Catalog of named "hard sites" with legend-values** — Frontier
  Legends' formula is done, but the authored roster of notably difficult
  sites it scores against doesn't exist yet.
- [ ] **Rarity weights per resource** — Development Bloc's `ResourceIncome`
  and `ResourceStockpile` are both rarity-weighted; the weights aren't
  assigned.

---

## Exploration Tasks & Standing Assignments

- [ ] **Author catalog entries for the escalation chain's named tasks.**
  `data/exploration_task_escalations.csv` refers to tasks that have no row in
  `data/exploration_task_catalog.csv`, which is why `check_data.py` reports
  them as soft-reference mismatches rather than resolving them. As triggers:
  "Unknown Radio Signal (rescue succeeded)", "Unknown Radio Signal (rescue
  failed, 'too late')", "Medical Bay vaccine unlock (per-pathogen)", and
  "Native-fruit-stockpile find (Verdant, worked example)". As unlocks:
  the three elevated Sentience Detection tiers, "First Contact (direct
  entry)", "Region-reveal exploration task", and "Habitat-seeking task ->
  animal alliance". `data/exploration_task_injury_weights.csv` separately
  names the three First Contact resolutions (Peaceful / Bluff-Coercive /
  Military Exploitation). Each needs a real catalog row with its Rarity,
  Risk, Season gate, Ration cost, `Availability`, and — since most of these
  will be Leads — a deliberate `Lead expiry`, which is currently unset for
  nearly everything that will become one.
- [ ] **`sentience_contact_chain.csv`'s item names carry their requirement
  inline** — "Diplomatic Gear (Mandatory)" and "Armed Expedition Kit +
  Overwhelming Force Package (Mandatory)" don't resolve against
  `items.csv`. The second also names two items in one cell. Wants splitting
  into real item references with the requirement in its own column, the way
  `exploration_task_input_items.csv` already does it.
- [ ] **No pool-population/draw algorithm (`10a-B1`)** — filling the 3 (max
  5) slots from the per-planet eligible set, given Rarity, the Season gate,
  and meta-progression unlocks, is unspecified.
- [ ] **Full-pool escalation placement (`10a-SF2`)** — an accepted
  multi-season task now holds its own pool slot, but nothing says where a
  guaranteed escalation goes when every slot is already held (see also
  `10b-SF9`).
- [ ] **Define the "one-time `Confidence(Weather)` burst" in evidence-count
  terms (`10a-SF6`)** — `data/exploration_task_confidence_bursts.csv` lists
  which tasks grant one but carries no count.
- [ ] **Mid-Sim progress indication for Clear-Cutting / Trapping
  (`10a-SF10`)** — both are production-speed-based and run across the
  window, but neither is a building with a progress overlay.
- [ ] **Clear-Cutting / Trapping tile richness — undesigned.** Both are
  production-speed-based Standing Assignments (see Settlers & Exploration's
  [Standing Assignments](05_settlers_and_exploration.md#standing-assignments)), but the per-tile quantity each one works against
  doesn't exist yet. Needed: a per-tile **richness** value that, for a
  Forest tile, sets how many Clear-Cutting cycles it yields before the tile
  is depleted, and for a Trapping tile sets the per-cycle Pelt output rate.
  The two differ in kind: Clear-Cutting **draws its tile down** toward
  depletion, Trapping **doesn't deplete** its tile at all — so richness is a
  consumable stock in the first case and a standing rate multiplier in the
  second. Also open: how richness is set at world generation, whether it
  varies by planet type, and whether it's visible to the player before
  assigning a worker.

---

## Alien Contact & Trade

- [ ] **Peaceful Contact's base alliance reward has no shape (`10b-B1`,
  `10b-SF1`).** First Contact's Peaceful approach succeeds and grants…
  something. Only "specific rewards TBD" is written. This is structural, not
  numeric: several designed things hang off whatever shape it takes — the
  deepening-alliance arc (whose per-tier rewards are meant to extend it),
  Trade Agreement availability, Local Delicacy ingredient sourcing, and
  the zero-staffing passive-benefit reward tier the fruit-animal alliance
  already set a precedent for. Needed: what a *base* alliance grants
  before any deepening, and whether that's a standing passive benefit, a
  one-time payout, an unlock, or some mix. Also open: the deepening arc's
  tier count and cadence (`10b-B2`), which sets arc length and how many
  guaranteed-escalation pool slots it generates.
- [ ] **No rule enforcing "at most one alien civilization per run"
  (`10b-B3`)** — `ContactRestraint` assumes it (scored as a single discrete
  tier, "since a run has at most one encounter"), but five separate triggers
  plus Universal Ubiquity plus the Unknown Radio Signal path can each reach
  Sentience Detection.
- [ ] **Trade Agreement candidate generation is unspecified (`10b-B4`)** —
  the confirmation dialog offers three fixed expense/income pairings; how
  those three are drawn has no algorithm. Income-side resources are
  restricted to raw/harvested materials plus Lumber/Concrete/refined metals;
  the expense side is unrestricted.
- [ ] **How an unresolved sentience chain is handled at run end, and which
  `ContactRestraint` tier applies mid-arc (`10b-SF3`).**
- [ ] **Quantify the chain's "significantly elevated `EcologicalData`
  weight" in evidence-count terms (`10b-SF4`).**
- [ ] **First Contact approach UI info content before commit (`10b-SF5`)** —
  cost, risk tier, directional odds, and the `ContactRestraint` consequence
  of each of the three approaches.
- [ ] **Guaranteed-escalation-slot vs. pool-size-3 pressure (`10b-SF9`)** —
  an alliance arc generating a guaranteed slot every step can dominate a
  three-slot pool.
- [ ] **Alien civilization classes — remaining numeric TBDs**, deferred to
  balancing (see Settlers & Exploration's [Escalation Chains](05_settlers_and_exploration.md#escalation-chains)):
  - Exact `ContactRestraint` tier values
  - Exact Bluff success-probability curve vs. Technology Level
  - Exact Military success-probability curve vs. Technology Level + Unity
  - Exact resource pairs/quantities offered per Trade Agreement
  - Bluff's on-success payout amount (relative to an undeepened alliance's
    baseline)
  - Military Exploitation's success rewards
  - Overwhelming Force Package's exact recipe (a first-pass placeholder is
    written into Buildings & Economy's [Fabrication](04_buildings_and_economy.md#fabrication))
  - Exact legend-value-scaling formula shape (inverse of success
    probability, magnitude TBD)

---

## Hazards, Protection & Data-Gathering

- [ ] **Author the recurring data-gathering exploration tasks (`11-SF9`)** —
  its own focused pass. `data/data_gathering_sources.csv` and Planets &
  Scoring's [Data-Gathering Mechanism (Beta Distribution, Hidden From the Player)](06_planets_and_scoring.md#data-gathering-mechanism-beta-distribution-hidden-from-the-player) name a weather balloon,
  atmospheric sampling, a bio-survey, and a dedicated probe as data sources
  — and for Atmospheric Hazard and Toxic/Parasitic Organism Threat they are
  the **only** source (Pathogen Threat now also has the Medical Bay's
  passive contribution). None exist in `data/exploration_task_catalog.csv`.
  Until they're authored, `Confidence` for those sub-factors can never rise,
  which in turn gates Medical Bay's Biological Countermeasures tier and
  leaves the Safeguard score's `Data` term near its floor. Needed per task:
  rarity, risk tier, season gate, Ration cost, required item (if any),
  repeatability, and how much evidence one completion contributes.
- [ ] **Balance the hazard values now sitting at TBD** —
  `data/misc_balancing_values.csv`'s "Hazard event duration",
  "Atmospheric Hazard", "Medical Bay" passive-evidence, and "Weather Shield"
  Energy-draw rows. Shapes are settled; only the numbers are missing.

---

## Animal System

The husbandry pipeline, parasites/diseases/countermeasures, wild animal
populations, Fencing, the tiny/small-animal counters, and the Medical Bay
materials are all written into the design docs. What remains:

- [ ] **The Earth-livestock → native-fauna pivot itself is not yet
  written.** Earth livestock is **dropped** — an expedition mass-constrained
  enough to ration seed stock realistically can't bring herds. Removing
  Dairy Pasture / Poultry Coop / Sheep Pasture, rehoming Milk/Eggs/Wool onto
  husbandry-animal analogs and Kitchen recipes, and authoring the archetype
  rosters below. Animal husbandry becomes discovery-gated and
  planet-dependent, which is the point — it makes runs diverge while crops +
  Trapping + Rations stay a reliable learnable core on every planet type.
  Settlers & Exploration's [Experience](05_settlers_and_exploration.md#experience) groups already flag the three current
  animal buildings as slated to move to the Husbandry group once this lands.
  - **Husbandry roster**: Grazer/herd (meat + milk-analog + droppings →
    Fertilizer + hide → Leather); Fiber beast (wool-analog → Fabric;
    insulating fiber → Temperature-Resistant Gear); Burrower (suppresses
    Alien Soil for plant-crop buildings while active — an alternative to
    Fertilizer/Hybridization); Pollinator hive (amplifies plant yield
    settlement-wide; honey-analog).
- [ ] **Archetype value-consistency rule.** Outcome values are **constant
  across all instances of an archetype** (a Fiber beast is 1 Wool/cycle,
  always). Variety = naming + small % differences on *secondary* attributes
  (grows 10% slower; lumbering, 20% easier to capture). Planet-gen picks
  each type's roster, Seasoning-style. Referenced by name from Buildings &
  Economy's [Animal Husbandry](04_buildings_and_economy.md#animal-husbandry).
- [ ] **Pet / companion path.** Rare. Found via a rare exploration outcome,
  **bonds permanently to the finding settler** (acquisition = luck × that
  settler's Exploration Aptitude). One pet per settler; no run cap,
  probabilities tuned for 0–2 per run. Provides an *effect*, not a good — a
  mix of passive/settlement-wide and bonded-settler-activity-specific; pets
  follow their settler on exploration (a settlement-wide passive effect
  lapses while the pet is away). Bonded settler dies → pet lost (released),
  and befriending adds `legend_value` (Frontier Legends). Pets are immune to
  parasites/diseases and generally act like a buff on their settler. Pets
  can gate **non-systematized content** (e.g. a water-source exploration
  task that only ever appears if a water-diviner pet exists).
  - **Pet roster**: Water-diviner (unlocks a unique water-source exploration
    task, flags aquifer tiles); Sentinel flyer (telegraphs a scheduled
    Storm/Temp event earlier than weather `Confidence` would); Draft animal
    (multiplies the bonded settler's Effort on hard-labor Outdoor tasks);
    Chem-scavenger (dual-mode: in-settlement, a pure-variance random-loot
    forage cycle — Seasonings, a small catch → 1 Pelt; on exploration, a
    serendipitous-discovery bonus).
- [ ] **Guards, traps (the general kind — not the tiny/small-specific Traps
  already designed), and hunt/remove-population exploration tasks** — real
  but undesigned active counters to wild animal populations, mentioned in
  discussion and never specified.
- [ ] **Farm-site archetypes biasing wild-population generation** —
  Planets & Scoring's [Wild Animal Populations](06_planets_and_scoring.md#wild-animal-populations) defers this to its own item
  by name.
- [ ] **Titan Domestication's unique output.** A husbanded Titan (see
  Buildings & Economy's [Animal Husbandry](04_buildings_and_economy.md#animal-husbandry) Production Cycle) may
  eventually get a unique output of its own, beyond the normal
  size-scaled version of its archetype's ordinary output. A content hook,
  not yet a mechanic to design.
- [ ] **Hybridization numeric details still TBD** — exact Water-reduction
  amount (Arid), yield-boost amount (Verdant), Research Lab
  `production_time` per project, and the generic "broad yield improvement"
  magnitude for the planet-independent (meteorite-fragment-unlocked)
  hybridization path.
