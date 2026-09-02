# Audit — System 4: Production Model

Design audit against `full_design/`; no implementation exists. Citations are
`file` → "Section" (no anchor links: the repo link-checker only scans
`full_design/*.md`).

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Continuous-rate production — progress at `100% / production_time` per second; a boost/penalty modifies the *rate*, no countdown, no timer resets, "no exploitable edge cases from boost timing" | `03` "Production Model" |
| One primary input→output conversion per site | `03` "Production Model"; `04` "Building Schema" |
| Input / Output as multisets per cycle; Output may be empty or a non-item (data report, buff); `production_time` applies when Output non-empty and not instant | `04` "Building Schema" |
| Multi-recipe buildings — player selects one active Input/Output pairing, sticky + reversible; recipes may differ in output item / input item / output rate; "no further taxonomy needed" | `04` "Building Schema" |
| Instant conversion (Ration Press) — input selected in planning, resolves immediately same-season, no `production_time` / staffing / rate limit; repeatable within a planning phase, no cap; reversible until Next Season | `04` "Building Schema", "Ration Press" |
| Staffing gates production — every site needs a worker to produce at all, except no-staffing sites and combo buildings; unstaffed (or unassigned) site → zero output that season | `03` "Assignment" |
| Unstaffed site → flat per-tier rate; staffed site → Effort stacks toward a per-cycle production cap | `03` "Assignment"; `04` "Building Schema" — "Conditional properties" |
| Plant-crop three-phase cycle (Grain Field, Fruit Orchard, Fiber Field, Timber Grove): Planting (Effort-driven, + Wooden Plow) → Growing (no worker, Alien Soil / Hybridization-governed, holds a flat Water rate reservation for its whole duration) → Harvesting (Effort-driven) | `03` "Production Model"; `04` "Farm/Production" — "Production Cycle" |
| Settlement-wide strict-FIFO Water-reservation queue for Growing phases — front-only service, no skip-ahead, ties broken by build/placement order, re-join back each cycle; sustained shortfall stalls the front entry and everyone behind it | `04` "Farm/Production" — "Water-draw queue" |
| Alien Soil — standing growth-rate penalty (illustrative −30%) on the 4 plant-crop buildings; auto-removed for any season Fertilizer is available; permanently removed once that plant type is hybridized | `04` "Farm/Production" — "Alien Soil" |
| Fertilizer — produced passively by the livestock buildings regardless of staffing/output; consumed automatically once per *season* by plant-crop buildings to offset Alien Soil | `04` "Resources" — "Fertilizer" |
| Animal buildings (Dairy Pasture, Poultry Coop, Sheep Pasture) — flat per-cycle Water input; **no defined insufficient-Water behaviour** | `04` "Farm/Production" |
| Combo / multi-purpose buildings — e.g. a Bakery growing its own wheat *and* baking it on one worker, wheat side slower than a dedicated field | `03` "Production Model", "Assignment" |
| Kitchen — deviates from the standard multi-recipe pattern: N simultaneous recipe slots, one worker each, each slot independently selects a recipe; footprint = slot count (base 1, Upgraded 2) | `04` "Food/Meal Conversion" — "Kitchen" |
| "Automatic higher-value alternative output when a secondary ingredient is in stock" — floated, **not resolved** (race-condition-prone) | `03` "Production Model" |
| Production progress overlay — semi-transparent sprite, opaque bottom-up fill + thin white boundary line, driven directly by the continuous-rate progress value; the primary at-a-glance channel; **legibility targeted at 1× only**, no wall-clock floor | `03` "Season Structure" — "Production progress overlay"; `07` "Art Design" |
| Farm overlay variant — fill resets to 0% per phase, colour brown / green / gold, plus a per-phase icon badge (seed / sprout / sheaf) | `03` "Season Structure" — "Farm-specific variant: phase-colored fill" |
| Assigned-worker Mid-Sim depiction — static sprite parked at the site, no locomotion | `03` "Season Structure" — "Assigned-worker Mid-Sim depiction" |
| `production_time` values and event rates calibrated against the fixed 30s-at-1× Mid-Sim window | `03` "Season Structure" — "Fixed real-time window" |

**Boundary notes (ambiguous ownership).**
- **Kitchen** — the N-parallel-slot *mechanism* (worker count = slot count, each slot a
  standalone single-recipe conversion) is a production-model pattern and is audited
  here; the *recipe content* and nutrient math are System 8. Gourmet recipes being
  settler-specific makes a slot's available recipe list depend on the assigned worker
  — a seam with System 3 (Site Panel selector) and System 9.
- **Effort-stacking, the per-cycle output cap, drone Effort values** — Building-Schema /
  Worker-Assignment (System 3) facts; taken as given here, but the unreconciled
  rate-vs-cap parameterization is flagged (CS4).
- **Alien Soil removal** depends on Fertilizer, produced by livestock buildings —
  owned here for the production effect, but Fertilizer-as-resource is System 7.
- **Hazard slow / stop / destroy consequences** are authored in System 11; their
  interaction with the three-phase cycle is flagged here (CS1).
- **Water Income rate, the queue's capacity side, animal-building shortfall** — System 6.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. Combo / multi-purpose buildings are a phantom feature.** Referenced twice
  (`03` "Production Model", "Assignment") as buildings that run *two* conversions on
  one worker, but: no catalog entry exists, no schema treatment (Building Schema says
  "one primary input→output conversion"; multi-recipe means "select *one* as the
  single active pairing" — a combo building is neither), and it's unstated whether the
  crop side runs the three-phase cycle or continuous-rate, how the single worker's
  Effort splits, and what the footprint is. *Possible direction: cut the references,
  or add one concrete combo building to the catalogue with an authored dual
  Input/Output and a stated Effort split.*
- **G-S2. The "automatic higher-value alternative output" idea is left unresolved in a
  current-design doc** (`03` "Production Model"), with its race condition unsolved and
  a cleaner alternative ("better recipe = separate building") already noted. Needs a
  formal in-or-out decision; if out, remove the paragraph. *Possible direction: cut it
  — the separate-building / separate-recipe pattern already covers the intent.*
- **G-S3. The three-phase plant-crop cycle's parameterization is underspecified.**
  Planting and Harvesting durations are "Effort-driven" (a function of the assigned
  worker, not fixed), Growing is soil/hybridization-governed — yet each plant-crop
  building carries a single combined `production_time` (Grain Field "3s", etc.). It is
  not stated what that number *is* now (Growing-only? total at 1.0 Effort?), which
  phase durations are authored vs. derived, or the Effort→duration function.
  `DESIGN_TODO.md` "Farm production cycle" flags the per-phase *split* as numeric, but
  the *mechanism* is structural. *Possible direction: author a base duration per phase;
  Planting/Harvesting base scaled by `1 / totalEffort`; Growing base scaled by Alien
  Soil / Hybridization; retire the single combined number.*
- **G-S4. Cross-season handling of an in-progress cycle is undefined — both models.**
  (a) A continuous-rate cycle 60% complete when Mid-Sim ends: does the progress carry
  to next season or reset? (b) A plant-crop building mid-Growing at the season
  boundary: does the phase and its held Water reservation persist — given Water is a
  per-season rate with "nothing carried across the season boundary" (`04` "Water"), a
  reservation *cannot* span seasons. *Possible direction: continuous progress carries;
  a Growing phase pauses at the boundary and re-enters the Water queue at the top of
  the next Mid-Sim.*
- **G-S5. Fertilizer → Alien Soil removal is all-or-nothing-settlement-wide vs.
  rationed-per-building undefined.** `04` "Alien Soil" reads "for any season Fertilizer
  is available" (a settlement boolean); `04` "Fertilizer" says "consumed automatically,
  once per season, by plant-crop buildings" (implying a per-building quantity leaves
  inventory). With 3 plant-crop buildings and 2 Fertilizer, are 2 covered and 1
  penalised, or all 3? *Possible direction: settlement-wide boolean — any ≥1 Fertilizer
  in inventory at season start clears Alien Soil for every plant-crop building that
  season; consume a fixed small amount.*
- **G-S6. Hazard consequences are defined only against the continuous-rate model.**
  `06` "In-Simulation Hazard Events" gives "slowed" / "stopped" / "paused" /
  "destroyed" with no statement of their effect on a plant-crop building mid-Planting
  or mid-Growing: does "stopped" freeze the Growing timer while *holding* its Water
  reservation (starving the queue behind it) or *release* it; does "slowed" scale the
  Effort-driven Planting duration. *Possible direction: "stopped" pauses the phase
  timer and releases the Water reservation; "slowed" applies a rate multiplier to
  whichever phase clock is running.*
- **G-S7. "Slowed" is never quantified.** `06` uses the word; the Production Model's
  governing variable is the `100% / production_time` rate. The mapping (slowed = rate ×
  k for the event duration) is absent. *Possible direction: define a single "slowed"
  multiplier (e.g. ×0.5) shared by both hazard types.*

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** Per-phase base durations for each of the 4 plant-crop buildings, and the
  Effort→duration function. `04` "Farm/Production" — "Production Cycle"; `DESIGN_TODO.md`.
- **G-N2.** Alien Soil penalty magnitude (−30% illustrative) and whether it acts as a
  rate or a duration modifier on Growing. `04` "Alien Soil".
- **G-N3.** Flat per-cycle Water for animal buildings; total Growing-phase Water need
  per crop. `04` "Farm/Production".
- **G-N4.** Fertilizer produced per livestock building per season; amount consumed per
  season. `04` "Resources" — "Fertilizer".
- **G-N5.** `production_time` values across the catalogue (all illustrative). `04`.
- **G-N6.** Wooden Plow Planting-reduction magnitude (−15% illustrative). `04`
  "Fabrication" — "Sawmill"/"Carpenter's Shop".

### Cross-check with `DESIGN_TODO.md`

Currently flagged, touching this system: "Farm production cycle" (covers G-S3's
numeric half and CS6), and the animal-building insufficient-Water gap (Water threads).
**Not** flagged: combo buildings (G-S1), the automatic-alternative-output resolution
(G-S2), cross-season in-progress-cycle handling (G-S4), the Fertilizer consumption
model (G-S5), hazard × three-phase interaction (G-S6/G-S7), the "four animal-based
buildings" miscount (IC1), the farm upgrade-rule contradiction (IC2). Recommend
adding.

---

## 3. Internal consistency

- **IC1. "Four animal-based buildings" — only three exist.** `03` "Season Structure"
  and `04` "Farm/Production" (Alien Soil parenthetical, water-draw-queue note) all say
  "the four animal-based buildings", but the catalogue lists exactly three (Dairy
  Pasture, Poultry Coop, Sheep Pasture); `04` "Fertilizer" confirms three livestock
  buildings. Either a fourth is intended and missing, or "four" is a repeated typo for
  "three". (→ SF5.)
- **IC2. Farm upgrade rule contradicts its own preamble.** `04` "Farm/Production"
  opens "All buildings in this section: … Upgrade path: yes (higher tiers reduce
  `production_time` and/or raise the effort-stacking production cap)", then the next
  paragraph: "upgrades here only ever reduce `production_time`, never raise the
  effort-stacking cap". (→ SF6.)
- **IC3. Kitchen is a fourth production pattern, despite "no further taxonomy
  needed".** `04` "Building Schema" asserts recipe shapes need no further taxonomy,
  but Kitchen's N-independent-parallel-slots model is neither single-recipe-effort-
  stack, nor pick-one-multi-recipe, nor instant conversion. (→ NTH1.)
- **IC4. The "no exploitable edge cases from boost timing" claim is unproven for the
  three-phase model.** `03` "Production Model" argues it for continuous-rate only. A
  settler's effective Effort changes mid-Mid-Sim during an injury-recovery delay (`05`
  "Injuries" — "recovery period occupies the first portion of that season's Mid-Sim
  window"), which shifts when a plant-crop Planting phase can even start. (→ NTH2.)

---

## 4. Cross-system consistency

- **CS1 (→ G-S6/G-S7). Hazards × three-phase cycle.** `06` "In-Simulation Hazard
  Events" authored its production consequences before the three-phase cycle existed;
  the Water-reservation-hold-or-release question under "stopped" directly feeds back
  into the queue (System 6) and can stall unrelated plant crops.
- **CS2 (→ SF7). Water-queue starvation is not legible.** Strict-FIFO by build/
  placement order (`04` "Water-draw queue") means a back-of-queue plant crop can
  produce nothing all season while the front one runs fine; the ordering key
  (placement order) is invisible, and there is no per-building "waiting for Water"
  indicator. Collides with `01` "failure should always be legible" and risks reading
  as an ambush against `01` "forgiving of individual mistakes".
- **CS3 (→ NTH3). Ration Press reversibility × exploration funding.** Ration Press
  output is available same-season for an exploration task's Ration cost (`04` "Ration
  Press"; `05` "Assignment"). Undoing the Ration Press batch after assigning that task
  leaves the cost unfunded — unstated whether the task auto-cancels or the undo is
  blocked.
- **CS4 (→ SF8). Effort ↔ `production_time` ↔ per-cycle output cap is unreconciled.**
  `03` "Production Model" is rate-based (progress per second); `03` "Assignment" is
  per-cycle-output-cap-based ("a single worker might only realize part of an advanced
  site's potential output"). Whether a second worker shortens the cycle, raises
  per-cycle output, or both, is unstated. Moot for farm buildings (cap 1) but governs
  every Fabrication / Utilities site.
- **CS5 (→ SF9). Unstated scoring hooks.** `06` "SEED Factions" needs a per-season
  units-produced-per-resource figure for `NutritionIncome` / `ResourceIncome`
  (5-season average), and needs each cycle completion of a penalised resource (mined
  ore/stone/rare metal, Clear-Cut Wood, Fuel-based Generator burn) to increment
  Stewardship `ExtractionRestraint` / `EmissionsRestraint`. Neither emission point is
  named in the Production Model.
- **CS6. Animal-building insufficient-Water behaviour undefined** — tracked in
  `DESIGN_TODO.md` Water threads, owned by System 6; noted here for completeness.
- **CS7 (→ NTH4). Kitchen recipe selector must filter by assigned worker** — Gourmet
  recipes are settler-specific (`04` "Kitchen"), so the Site Panel selector (`03`
  "Site Panel (UI)") can't be a pure per-building list.

---

## 5. Story & world consistency

- **Positive / reinforcing.** The three-phase Planting → Growing → Harvesting cycle
  has direct real-world grounding and needs no in-fiction justification. Continuous-
  rate "it just runs, no tending" fits the Herald's hands-off, plan-only role (`02`
  "SEED's Culture, and the Player's Role"). Alien Soil is a clean mechanical
  expression of the premise that Earth crops are being grown on a foreign world (`02`
  "Life on Other Worlds"; `03` "Agriculture Branching").
- **Minor stretch (no change required).** A "Ration Press" that runs unstaffed, in
  zero time, with uncapped throughput is a mild fiction stretch; acceptable at the
  game's altitude.
- **Missed reinforcement (→ NTH5).** The shift away from hand-tended farming to "it
  just runs" has no in-fiction voice — one line tying it to `02`'s
  AI-drives-autonomous-drones lore would ground *why* settlers no longer walk out to
  tend each field.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Difficulty from breadth of tradeoffs, not execution precision* — removing the
  tend-walk step deletes an execution/attention chore; the Water supply-vs-demand
  balance is the intended strategic tradeoff.
- *Planning phase is reversible* — recipe selection and Ration Press conversion are
  both explicitly reversible until Next Season.
- *A passable plan should always be quick to reach* — sticky recipe + idle,
  auto-served Growing phase means a stable farm needs zero per-season production
  actions.
- *Colour is never the sole channel* — the farm overlay pairs brown/green/gold with a
  per-phase icon badge; compliant as written.

**Risks / violations:**
- **P1 (→ SF10). Numbers stay small / legibility.** A season's yield is now an
  emergent product of `(30s ÷ production_time) × Effort × AlienSoil × phase-splits`
  rather than an authored per-season number; exact hand-calculation is no longer
  realistic. The Site Panel "one combined number" rate summary partly mitigates but is
  ill-defined for a three-phase cycle (which phase's rate?).
- **P2 (→ SF7). Failure should always be legible.** Water-queue starvation (CS2) and
  Alien-Soil-active-vs-removed have no dedicated indicator; both currently rely on the
  System 3 Site Panel rate summary listing them as modifiers.
- **P3 (→ NTH6). Docs describe the current design, not its history.** `03` "Production
  Model" ("was floated but is not resolved", "as in the original design") and `04`
  "Farm/Production" ("split of the prior single 3s `production_time`") carry
  process/history narration.
- **P4 (→ NTH7). Minimal UI interaction.** Ration Press "repeatable within a planning
  phase, no cap" with per-batch input selection could be a fiddly loop when converting
  a large stock; no bulk / target-quantity mode is specified.
- Not engaged: units-unspecified (seconds are exempt), naming, normalize-before-
  combining, dexterity-timing, touch/mouse parity, text-legibility.

---

## 7. Player legibility

- **Continuous-rate progress** — the overlay carries it at 1×. Good.
- **Plant-crop phase state** — the overlay (colour + badge) is the *only* channel and
  is explicitly not legible above 1×; the aggregated log carries resource-production
  ticks and "noteworthy events" but not phase transitions, so phase progress is
  unrecoverable after fast playback. Minor (→ NTH8).
- **Water-queue starvation** — not legible (→ CS2 / P2).
- **Alien Soil active vs. removed** — not independently legible; depends on the System
  3 rate summary listing it (→ P2).
- **Expected season yield** — hard to compute (→ P1).
- **Combo-building behaviour** — undefined, so unassessable (→ G-S1).
- **Next-season resolution for construction** and **instant same-season Ration Press
  output** — each consistent with a rule the player learns once and transfers. Good.

---

## 8. Fun / scope risk

- **The three-phase plant-crop apparatus is the system's complexity centre** — a
  separate overlay variant, the FIFO Water queue, a per-phase duration model, Effort
  on 2 of 3 phases, phase badges. Its concrete payoff is the burst-vs-flat Water-
  demand *shape* and farming flavour. If the Water queue or the phase overlay
  under-deliver in playtest, most of the apparatus yields little. *Cut-or-simplify
  candidate: collapse to a single continuous-rate cycle that holds a Water reservation
  for its duration, dropping Planting/Harvesting as distinct phases and folding Effort
  into the one rate.* Worth an explicit decision rather than drift.
- **"Automatic alternative output"** — a scope trap the design itself distrusts;
  recommend formally cutting (→ G-S2).
- **Combo buildings** — phantom feature; design one concretely or cut the mentions
  (→ G-S1).
- **Kitchen N-slot** — well-motivated (parallel meal variety); keep, but name it as a
  pattern in the schema (→ IC3).
- **Continuous-rate default** — strong, low rule-weight; keep. This is the system's
  core.

---

## 9. Findings summary

### Blockers

- **B1.** Combo / multi-purpose buildings are referenced as existing but have no
  catalogue entry, no schema, and contradict "one primary input→output conversion" —
  undefined worker-Effort split, crop-side cycle type, footprint. (§2 G-S1, §8 —
  `03` "Production Model" / "Assignment"; `04` "Building Schema")
- **B2.** Three-phase plant-crop cycle parameterization undefined — Planting/Harvesting
  durations are Effort-driven (not fixed), Growing is soil-driven, yet each building
  carries one combined `production_time` with no statement of what's authored vs.
  derived or the Effort→duration function. (§2 G-S3 — `04` "Farm/Production" —
  "Production Cycle"; `DESIGN_TODO.md` "Farm production cycle")
- **B3.** Cross-season handling of an in-progress cycle is undefined for both models —
  partial continuous-rate cycle at Mid-Sim end (carry or reset?), and a plant-crop
  building mid-Growing at the season boundary where its held Water reservation cannot
  span seasons (Water is a per-season rate). (§2 G-S4 — `03` "Season Structure"; `04`
  "Water", "Farm/Production" — "Water-draw queue")

### Should-fix

- **SF1.** Resolve the "automatic higher-value alternative output" idea — formally cut
  or scope it; if cut, remove the paragraph from a current-design doc. (§2 G-S2 —
  `03` "Production Model")
- **SF2.** Define Fertilizer → Alien Soil removal as settlement-wide-boolean vs.
  rationed-per-building, and the amount consumed per season. (§2 G-S5 — `04` "Alien
  Soil" vs `04` "Resources" — "Fertilizer")
- **SF3.** Define hazard "slowed"/"stopped" behaviour for a plant-crop building
  mid-Planting and mid-Growing — in particular whether a stopped Growing phase holds
  or releases its Water reservation. (§2 G-S6, §4 CS1 — `06` "In-Simulation Hazard
  Events"; `04` "Farm/Production" — "Production Cycle")
- **SF4.** Quantify "slowed" as a rate multiplier on `100% / production_time`, shared
  by both hazard types. (§2 G-S7 — `06` "In-Simulation Hazard Events" vs `03`
  "Production Model")
- **SF5.** Fix "the four animal-based buildings" — either add the missing fourth
  building or correct to "three" in all three occurrences. (§3 IC1 — `03` "Season
  Structure"; `04` "Farm/Production")
- **SF6.** Resolve the farm upgrade-rule contradiction — the section preamble allows
  raising the effort-stacking cap; the next paragraph forbids it. (§3 IC2 — `04`
  "Farm/Production")
- **SF7.** Add a per-building "waiting for Water" indicator (and surface the queue
  ordering) so plant-crop starvation is legible. (§4 CS2, §6 P2, §7 — `04`
  "Water-draw queue"; `01` "failure should always be legible")
- **SF8.** Reconcile whether a second worker shortens a cycle, raises per-cycle
  output, or both — the rate model (`03` "Production Model") and the per-cycle-output
  cap (`03` "Assignment") are not joined. (§4 CS4)
- **SF9.** Name the Production Model's scoring emission points — per-season
  units-produced-per-resource for `NutritionIncome` / `ResourceIncome`, and
  cycle-completion increments to Stewardship `ExtractionRestraint` /
  `EmissionsRestraint`. (§4 CS5 — `06` "SEED Factions")
- **SF10.** Define what the Site Panel "one combined number" production-rate summary
  means for a three-phase cycle, and record the expected-yield legibility risk from
  emergent per-season output. (§6 P1 — `03` "Site Panel (UI)"; `01` "numbers stay
  small")

### Nice-to-have

- **NTH1.** Acknowledge Kitchen's N-parallel-slot model as a named production pattern
  in `04` "Building Schema" rather than under "no further taxonomy needed". (§3 IC3)
- **NTH2.** Qualify or verify the "no exploitable edge cases from boost timing" claim
  for the three-phase cycle plus mid-Mid-Sim Effort changes (injury-recovery delay).
  (§3 IC4 — `03` "Production Model"; `05` "Injuries")
- **NTH3.** Define whether undoing a Ration Press batch auto-cancels an exploration
  task funded by it, or is blocked. (§4 CS3 — `04` "Ration Press"; `05` "Assignment")
- **NTH4.** Specify that the Site Panel recipe selector filters by assigned worker for
  Kitchen (Gourmet recipes). (§4 CS7 — `04` "Kitchen"; `03` "Site Panel (UI)")
- **NTH5.** Add an in-fiction hook for hands-off continuous production (drone-assisted
  farming, per `02`'s AI/drone lore). (§5)
- **NTH6.** Strip history/process narration from `03` "Production Model" and `04`
  "Farm/Production". (§6 P3 — `01` "Design docs describe the current design, not its
  history")
- **NTH7.** Give Ration Press a bulk / target-quantity conversion mode. (§6 P4 — `01`
  "UI interaction is minimal")
- **NTH8.** Accept, or add a log line for, plant-crop phase state being unrecoverable
  after >1× playback. (§7 — `03` "Season Structure" — log / event-feed)

### Defer (numeric / tracked elsewhere)

- **D1.** Per-phase base durations for the 4 plant-crop buildings + the Effort→duration
  function. `04` "Farm/Production" — "Production Cycle".
- **D2.** Alien Soil magnitude and whether it modifies rate or duration. `04` "Alien
  Soil".
- **D3.** Animal-building per-cycle Water; per-crop Growing-phase total Water. `04`
  "Farm/Production".
- **D4.** Fertilizer produced per livestock building / consumed per season. `04`
  "Resources" — "Fertilizer".
- **D5.** `production_time` values catalogue-wide. `04`.
- **D6.** Wooden Plow Planting-reduction magnitude. `04` "Fabrication".
- **D7.** Animal-building insufficient-Water behaviour — tracked in `DESIGN_TODO.md`
  Water threads, owned by System 6.
