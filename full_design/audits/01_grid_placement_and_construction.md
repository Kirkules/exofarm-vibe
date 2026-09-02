# Audit — System 1: Grid, Placement & Construction

Pilot design audit. Pure design review against `full_design/`; no
implementation exists. Citations are `file` → "Section" (no anchor links:
this file sits in `audits/` and the repo link-checker only scans
`full_design/*.md`).

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Single unified grid, one instance per run; holds every building, crop, animal pen, mining site | `03` "The Grid (Unified)" |
| Uniform single-cell placement; no polyominoes, no rotation | `03` "The Grid (Unified)", "What Got Cut" |
| Grid dimensions — working target 10×8 (80 cells), landscape | `03` "The Grid (Unified)" |
| Coordinate system — (row, col), 1-indexed, (1,1) top-left, row↓ col→ | `07` "Grid Coordinate System" |
| "Any building on any cell", subject to building-specific placement rules | `03` "The Grid (Unified)" |
| Single total grid size = the infrastructure-vs-farmland scarcity lever | `03` "The Grid (Unified)" |
| Fixed/environmental slots — impassable terrain, deposits, Forest tiles; set at run start; not player-moveable/removable | `03` "Fixed/environmental slots" |
| Grid instance (terrain shape + full deposit seeding) generated & locked at Farm Site Selection; 3 candidates, 1-Ration reroll | `03` "Farm Site Selection" |
| Multi-slot buildings — fixed non-rotatable footprints; slot count = simultaneous worker-assignment capacity | `04` "Building Schema" |
| Known multi-slot cases — Upgraded Kitchen (2 slots); Row Shield (2 vertically-adjacent tiles; physical-size, not worker-capacity) | `04` "Kitchen", "Row Shield" |
| Moveable pieces picked up / placed / returned to inventory in planning; inventory = off-grid holding area | `03` "Planning Phase"; `04` "Inventory" |
| Construction robots — start with 1; more built at Robotics Assembly (staffed production) | `03` "Construction" |
| Robot action set (one per robot per season) — build one new building (any type) / upgrade one building / relocate one built building | `03` "Construction" |
| All three robot actions resolve the following season | `03` "Construction", "Season Structure" |
| Automatic robot assignment; queue consumes a robot from the pool; cancel returns it; no manual pick; no persistent busy-state | `03` "Construction" |
| N-actions-per-season cap, N = robots owned (rate limit on infra *growth*, vs. slot-count cap on infra *total*) | `03` "Construction" |
| Placement-validity check (free cells + non-rotatable shape fit) — shared by new construction and footprint-expanding upgrades | `03` "Construction"; `04` "Building Schema" |
| Footprint-expanding upgrade only offered/confirmable if the required adjacent cell(s) are free | `03` "Construction"; `04` "Building Schema" |
| Relocation reuses the building; does not re-charge construction cost; costs one robot-action | `03` "Construction" |
| Deposit/feature-gated buildings (Mine, Quarry, Rare Metal Extractor, Geothermal Generator) relocate only to a discovered, unbuilt, matching-type deposit tile; Well excluded | `03` "Construction" |
| Vacated deposit tile reverts to empty-but-discovered, buildable | `03` "Construction" |
| Construction cost — Lumber+Concrete universal base + advanced materials; "consumed when a construction robot begins the build" | `04` "Building Schema" |
| Queued build/upgrade/relocate freeze at Planning Lock-in; robot consumed at queue time; completion at Post-Sim sub-step (4) | `03` "Season Structure" |
| Grid state feeds Stewardship's `DisruptionFootprint` (fixed/environmental slot state vs. start of Season 1) | `06` "SEED Factions" |
| Cut from prior design — power grid entirely; general neighbor-effect synergies (except shield AOE); manual merge-space crafting | `03` "What Got Cut" |

**Boundary notes (ambiguous ownership).**
- **Shield AOE placement** — "Small Set of Impactful Actions" #3 ("Place/reposition a force-field or weather-protection structure") straddles this system and Protection/Hazards. The placement gesture is grid; the coverage math is Hazards. Finding B1 sits on this seam.
- **Deposit-gating** — the rule is authored per-building / in Deposit Discovery but enforced as a grid placement check. Shared with System 7.
- **slot-count = worker-capacity** — the number is a Building-Schema / Worker-Assignment fact; the spatial footprint is grid. Tightly coupled (see C4).
- **Farm Site Selection** generates the grid instance but belongs to System 12 (Meta / Run-Start); this system only consumes its output.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. Multi-slot footprint *shapes* and the footprint-expansion direction rule are absent.** `04` "Building Schema" gives only slot *counts* and "fixed, non-rotatable". Upgraded Kitchen's 2-slot shape is unspecified; no rule says which adjacent cell(s) a 1→2 upgrade consumes, or whether a blocked preferred direction fails the upgrade outright (it must, if non-rotatable) or falls back to another free neighbour. This gates placement validity for every multi-slot building and the whole upgrade/relocate-to-clear-space interaction. *Possible direction: define a per-building authored footprint (anchor cell + offset list) plus a single rule that a footprint-expanding upgrade consumes a fixed authored offset set, and is blocked (offer a relocate) if any of those cells is unavailable.*
- **G-S2. Initial grid state is undefined.** No spec for where the starting buildings (Solar Array, Water Processing Plant, Sawmill, Stone Processing I — `04` "Basic Resource Production", "Sawmill", "Stone Processing I", "Water Processing Plant") sit at run start, whether the player places them or they are auto-placed, and whether they may later be relocated (Water Processing Plant's note implies starting buildings can't be demolished; relocation is silent). This also pins `DisruptionFootprint`'s "start of Season 1" baseline. `DESIGN_TODO.md` "Run-start flow" flags "starting-building / starting-Rations setup" but not its grid consequences. *Possible direction: auto-place starting buildings on ordinary (non-fixed) cells as part of Farm Site Selection output; treat them as relocatable like any built building; snapshot the grid immediately after placement as the DisruptionFootprint baseline.*
- **G-S3. Transition-season behaviour of an upgrading / relocating building is unstated.** Does it produce that season, at which tier and which location? Does a relocated staffed building keep its assigned worker (sticky assignment is "a property of the target", and relocation "reuses the building", which argues yes — but it isn't said)? *Possible direction: upgrading building runs at its old tier during the transition season; relocating building is offline that season; worker stays assigned across a relocation.*
- **G-S4. Building on an *undiscovered* deposit tile is unspecified** — allowed or not, does it block later discovery, and does it incur `DisruptionFootprint`. (Also §4 / §7.)

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** Final grid dimensions (10×8 is a working target). `03` "The Grid (Unified)".
- **G-N2.** Count / proportion / generation method of fixed-environmental slots per site and per planet type; terrain-layout generation. `03`; `06` "Initial Planet Types" open questions; `DESIGN_TODO.md` Farm Site Selection.
- **G-N3.** Per-building multi-slot footprint authoring across the catalog (only Kitchen and Row Shield exist today). `04` "Building Schema".
- **G-N4.** Whether any building is capped at one instance ("Repeatable" open question). `04` "Building Schema".
- **G-N5.** `DisruptionFootprint` base-vs-discovery-gated weighting. `06` "SEED Factions".

### Cross-check with `DESIGN_TODO.md`

`DESIGN_TODO.md` currently flags, touching this system: "Run-start flow" (covers G-S2 partially), "deposit overlap audit" (feeds G-S4), and per-building Lumber:Concrete ratios (a System 7 numeric, not grid). It does **not** currently flag G-S1 (footprint shapes), G-S3 (transition-season behaviour), or the shield/robot-economy question (B1). Recommend adding those.

---

## 3. Internal consistency

- **IC1. "Cannot be moved or removed" vs. Site Reveal.** `03` "Fixed/environmental slots" states fixed/environmental cells are "Set at run start; cannot be moved or removed." `05` "Outcomes" Site reveal transforms exactly these ("a mountain region becomes an exposed ore deposit, a cave system, or a volcanic vent"). The absolute phrasing needs an explicit "except via exploration Site Reveal" carve-out. (→ SF3.)
- **IC2. "Any building can go on any cell"** (`03` "The Grid (Unified)") is contradicted two sentences later by fixed/environmental cells being non-placeable and by deposit-gating. Not a mechanical contradiction once "subject only to building-specific placement rules" is read, but the flat clause is quotable out of context and should be softened. (→ NTH1.)
- **IC3. Action #3 vs. action #1.** "Small Set of Impactful Actions" lists placing/repositioning a shield (#3) as a distinct action from "Queue a building construction or upgrade" (#1), while shields are ordinary catalogue buildings with Construction cost / TechAchievement / Upgrade path. Either #3 is a redundant restatement of #1+relocate, or shields are exempt from the robot economy — the doc implies the latter without saying so. (→ B1.)
- **IC4. Process narration in a "current design only" doc.** `03`'s "The Grid (Unified)" opens with a historical parenthetical, carries a "Why unified, not split" rationale subsection, a "What Got Cut" section, and an "(In Progress)" banner — all disallowed by `01`'s "Design docs describe the current design, not its history." Known transitional state; noted for eventual cleanup. (→ NTH2.)

---

## 4. Cross-system consistency

- **CS1 (→ B1). Protection buildings & the construction-robot economy.** If shields cost a robot-action and resolve next season, the player frequently cannot respond to a per-season hazard forecast (`06` "In-Simulation Hazard Events" telegraphing; `02` Transmissions) in time — which reads as a deliberate design pressure or an oversight depending on intent. If shields are instead freely placed in planning, they break the Building-Schema invariant and the N-cap. Must be resolved before the action economy is buildable.
- **CS2 (→ SF1). Post-Sim ordering of multiple construction completions.** `03` "Season Structure" sub-step (4) is "construction/upgrade/relocate completions" with inter-step order to steps 1/2 called "arbitrary"; intra-step-4 order is unspecified. But `03` "Construction" explicitly contemplates *relocate a blocker + upgrade into the freed cells in one season with two robots* — which requires the relocation to resolve before the dependent upgrade's footprint check. Same hazard for "relocate A off tile T, build B on T" in one season. Needs an intra-step-4 order (relocations → upgrades → new builds, or dependency-topological).
- **CS3 (→ SF2 / G-S4). Undiscovered-deposit placement & Stewardship.** `06` `DisruptionFootprint` counts "any fixed/environmental slot whose state has changed from … the start of Season 1 (built over, harvested, extracted from, etc.)". Building on an undiscovered deposit would silently disrupt a slot the player cannot see — colliding with `01` "failure should always be legible" and leaving unclear whether the buried deposit is then permanently unreachable.
- **CS4. slot-count = worker-capacity is a hard coupling to System 3.** Any later change to multi-slot footprints changes worker capacity and vice versa; conversely, simplifying multi-slot buildings away (see §8) would require relaxing the "2 parallel workers ⇒ 2 slots" invariant in `04` "Building Schema". Flagged as a constraint on future edits to either system.
- **CS5. `DisruptionFootprint` baseline depends on G-S2.** The score cannot be computed until the initial grid state is pinned, and "state has changed … (built over, harvested, extracted from, etc.)" needs a per-fixed-type definition of "changed" — the "etc." is doing real work (does surveying a tile without building count? does a Forest tile partially clear-cut count?).
- **CS6 (→ SF5). Deposit-gated relocate availability depends on System 7 progress.** Relocating a Mine needs a *second* discovered, unbuilt Ore deposit to exist; until Deposit Discovery reveals one the relocate option is unavailable, and the player needs to be told why.

---

## 5. Story & world consistency

- **Positive / reinforcing.** Autonomous construction robots are directly supported by `02` "The Crash Research Era" (AI "drives the autonomous drones settlers rely on"); the abstract, remote, plan-only grid view is exactly the `02` "SEED's Culture, and the Player's Role" framing of the player as an orbital/Earth-side AI "Herald" who "operates at the level of planning and direction, not direct control." No lore conflict in the core system.
- **Minor stretch (no change required).** Relocating a fully-built structure (greenhouse, cafeteria) to a new tile in one season on a single robot-action is a mild fiction stretch; acceptable at the game's altitude, noted so it's a conscious call rather than an oversight.
- **Missed reinforcement (→ NTH3).** The finite grid and the infrastructure-vs-farmland squeeze have no in-fiction voice. A one-line frame — the grid as the survey-plot perimeter SEED authorized for the expedition — would tie the central spatial tradeoff to the story the way most other systems here are tied to a faction or lore beat.

---

## 6. Design-principle adherence

**Adherent — worth recording as deliberate strengths:**
- *Difficulty from breadth of tradeoffs, not execution precision* — `01` names grid placement as "the model instance of this"; single grid size makes infra and farmland compete for one pool; polyomino/rotation removal deletes the execution-precision axis entirely.
- *Forgiving of individual mistakes* — "not leaving room to grow" is a real misstep but relocation "without ever permanently locking the upgrade out".
- *Planning phase is reversible* — queuing a robot action is undoable, robot returns to the pool on cancel.
- *Randomization must be gated behind an explicit commitment* — the grid instance's RNG (terrain + deposit seeding) is locked at Farm Site Selection, a distinct pre-run commitment; deposit-*discovery* RNG resolves in simulation, not planning. Placement itself carries no in-planning draw.

**Risks / violations:**
- **P1 (→ SF4). Colour is never the sole channel.** Grid overlays — placement validity, fixed/environmental tiles, deposit tiles, shield AOE, powered-state — will all be colour-coded, and no redundant shape/icon/texture cue is specified for any of them. Art pass is deferred, but the requirement belongs on record against this system now.
- **P2 (→ SF5). Failure should always be legible.** A footprint-expanding upgrade blocked for lack of an adjacent free cell, and a deposit-gated relocate greyed out for lack of a second matching deposit, need explicit "which cell / what's missing" messaging. Plus the invisible `DisruptionFootprint` hit from building on an unseen deposit (CS3).
- **P3. A passable plan should always be quick to reach.** The relocate-to-make-room-then-upgrade sequence is multi-step and cross-season. It is opt-in (the player chose to upgrade) and represents "a genuine decision", so it fits the principle's carve-out — but it is the one place in this system where required effort grows with ambition; worth watching in playtest.
- **P4 (→ NTH2). Design docs describe the current design, not its history** — see IC4.
- Not engaged / n/a: numbers-stay-small (80 cells, small N, slot counts 1–2 — fine), units-unspecified, naming convention, normalize-before-combining, dexterity-timing scale and touch/mouse parity (input/Art pass deferred; PC-mouse is now the primary path so there is no touch-first-without-mouse hazard).

---

## 7. Player legibility

- **Grid scarcity** — self-evident; the player watches the grid fill. Good.
- **Fixed/environmental tiles & discovered deposit tiles** — legible only once the visual language is specified (P1). Undiscovered deposits are invisible by design, which is fine *except* for the silent-disruption case (CS3).
- **Footprint-expanding upgrade blocked** — cause is not currently surfaced (P2 / SF5).
- **Deposit-gated relocate unavailable** — cause is not currently surfaced (P2 / SF5 / CS6).
- **Relocation cost** (one robot-season, no material refund/recharge) — needs to be shown before commit; implied by "tooltips throughout" but not specified.
- **Next-season resolution delay** for build/upgrade/relocate — consistent with production resolving next season, so the player learns the rule once and it transfers. Good.
- **N-robot action budget** — the player needs an "actions used / available this season" readout; UI deferred, but the information requirement should be recorded.

---

## 8. Fun / scope risk

- **The multi-slot / footprint-expansion / relocate-to-clear-space cluster is the system's complexity centre.** It earns its keep only if footprint-expanding upgrades are common enough to matter. Today the sole named example is Upgraded Kitchen. If that stays the only one, this is a lot of rules (G-S1, the relocate interaction, IC3-adjacent placement checks) serving one building. *Cut-or-simplify candidates:* (a) commit to several footprint-expanding upgrades across the catalogue so the machinery pays off; or (b) drop footprint expansion — Upgraded Kitchen becomes a same-footprint tier — which then forces relaxing the "2 parallel workers ⇒ 2 slots" invariant (CS4). Worth an explicit decision rather than drift.
- **Relocation as a third robot-action competing with build/upgrade** — genuinely good: a clean opportunity-cost tradeoff, low rule weight. Keep.
- **Single-grid infra-vs-farmland tension** — high strategic value, minimal complexity. Keep; this is the system's core justification.
- **Narrowing risk** — a single fixed grid size could converge play toward one optimal density/build-order. That is a balance-pass question, not a structural one, but note it as something the balancing pass should actively check rather than assume.

---

## 9. Findings summary

### Blockers

- **B1.** Unresolved whether Protection structures (shields) run through the construction-robot economy at all — "Small Set of Impactful Actions" #3 treats shield placement/repositioning as its own action, parallel to #1, while shields are ordinary catalogue buildings with construction cost, TechAchievement, and an upgrade path. Determines the action economy and whether the player can react to per-season hazard forecasts. (§3 IC3, §4 CS1 — `03` "Small Set of Impactful Actions" / "Construction"; `04` "Building Schema" / "Weather Shield" / "Row Shield")
- **B2.** No multi-slot footprint *shape* model and no footprint-expansion direction rule — only slot counts exist, and even Upgraded Kitchen's shape is unspecified. Blocks placement validity for every multi-slot building and the entire upgrade / relocate-to-clear-space interaction. (§2 G-S1 — `04` "Building Schema"; `04` "Row Shield")
- **B3.** Initial grid state undefined — starting-building positions, whether the player or the game places them, whether they are later relocatable, and the resulting `DisruptionFootprint` "start of Season 1" baseline. (§2 G-S2, §4 CS5 — `DESIGN_TODO.md` "Run-start flow"; `04` "Water Processing Plant" / "Basic Resource Production"; `06` "SEED Factions")

### Should-fix

- **SF1.** Specify intra-Post-Sim ordering of multiple construction completions — the design's own two-robot "relocate a blocker then upgrade into the freed space in one season" example needs relocations to resolve before dependent upgrades/builds, but sub-step (4) declares order "arbitrary". (§4 CS2 — `03` "Season Structure" vs "Construction")
- **SF2.** Define whether a building may be placed on an *undiscovered* deposit tile, whether that blocks later discovery, and whether it incurs `DisruptionFootprint` for an unseen slot (the last would break failure-legibility). (§4 CS3, §2 G-S4 — `03` "Fixed/environmental slots"; `04` "Deposit Discovery"; `06` "SEED Factions")
- **SF3.** Add the "except via exploration Site Reveal" carve-out to `03` "Fixed/environmental slots" ("cannot be moved or removed"). (§3 IC1 — `03` "Fixed/environmental slots" vs `05` "Outcomes")
- **SF4.** Record the non-colour-channel requirement for every grid overlay (placement validity, fixed/environmental tiles, deposit tiles, shield AOE, powered-state) per `01` "colour is never the sole channel". (§6 P1 — `01` Design Principles)
- **SF5.** Require explicit cause messaging for blocked/greyed grid actions — footprint-expanding upgrade blocked for lack of an adjacent free cell; deposit-gated relocate unavailable for lack of a second discovered matching deposit. (§6 P2, §7 — `01` failure-legibility; `03` "Construction")
- **SF6.** Tighten construction-cost timing — `04` "consumed when a construction robot begins the build" vs `03` Planning Lock-in hosting the queue; confirm materials leave inventory at Planning Lock-in and are fully restored on cancel during the reversible phase. (§2 — `04` "Building Schema" vs `03` "Season Structure")
- **SF7.** State transition-season behaviour of an upgrading/relocating building — does it produce, at which tier/location, and does a relocated staffed building keep its worker. (§2 G-S3 — `03` "Construction")
- **SF8.** The N-actions-per-season cap is written as "build/upgrade actions"; confirm relocate counts against N. (§2 — `03` "Construction")

### Nice-to-have

- **NTH1.** Soften "Any building can go on any cell" so it is not quotable against the fixed/environmental and deposit-gating rules that immediately follow. (§3 IC2)
- **NTH2.** Fold `03`'s transitional framing (historical parenthetical, "Why unified, not split", "What Got Cut", "(In Progress)") out once the redesign settles, per `01` "describe the current design, not its history". (§3 IC4)
- **NTH3.** Give the finite grid an in-fiction hook (the SEED-authorised survey-plot perimeter) to tie the infra-vs-farmland tradeoff to story. (§5)
- **NTH4.** Define whether a relocation destination must be empty at queue time or at resolution time (two-robot swap edge case). (§4 CS2-adjacent)
- **NTH5.** Confirm grid dimensions are constant across planet types rather than a per-planet lever. (§2 G-N1)

### Defer (numeric / content-pass)

- **D1.** Final grid dimensions (10×8 working target). `03` "The Grid (Unified)".
- **D2.** Fixed-environmental slot count/proportion/generation per site and planet type; terrain-layout generation. `03`; `06` open questions; `DESIGN_TODO.md`.
- **D3.** Per-building multi-slot footprint authoring across the catalogue. `04` "Building Schema".
- **D4.** Whether any building is capped at one instance. `04` "Building Schema".
- **D5.** `DisruptionFootprint` base-vs-discovery-gated weighting. `06` "SEED Factions".
