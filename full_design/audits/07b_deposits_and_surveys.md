# Audit — System 7b: Deposits & Surveys

Split from System 7 (Resource Economy, Fabrication & Deposits). **7b** covers
Deposit Discovery (world-gen placement, the three depth tiers, the overlap
model, Thermal Vent / Fossil Fuel / aquifer), Basic Deposit Survey, Deep Survey,
Scanner Station Deposit Scanning, and the three mining buildings (Mine, Quarry,
Rare Metal Extractor). The Building Schema, `TechAchievement` catalog, refined
chains, drones, Fertilizer, Seasonings, and luxury goods are in
`07a_economy_and_fabrication.md`.

**Split rationale:** 7b is about spatial discovery, RNG, and the survey action
economy; 7a is about recipe chains and tech-tier ordering. The one tight seam —
mining output feeding refining — is noted in both.

Pure design review against `full_design/`; no implementation exists. Citations
are `file` → "Section" (no anchor links: the repo link-checker only scans
`full_design/*.md`).

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| All deposits placed at world-gen; discovery *reveals*, never generates | `04` "Deposit Discovery" |
| Deposit types: Iron/Copper Ore, Stone, rare-metal, aquifer, Thermal Vent, Fossil Fuel | `04` "Deposit Discovery", "Baseline Farm/Mined Resources" |
| 3 depth tiers — Surface (visible + buildable from start; guarantee ≥1 Stone/Iron/Copper), Mid-depth (Basic Survey), Deep (Deep Survey / Scanner Station; skews rare-metal) | `04` "Deposit Discovery" |
| Overlap: Ore / Stone / rare-metal mutually exclusive; aquifer / Thermal Vent / Fossil Fuel coexist with each other + the one mineral; Forest coexists with hidden deposits, excludes Surface deposits | `04` "Deposit Discovery" |
| Discovery resolves per (tile, depth) pair — one depth reveal exposes every type at that depth together, no per-type roll | `04` "Deposit Discovery" |
| Thermal Vent — binary, single-tile, Volcanic-exclusive (guaranteed ≥1 on Volcanic), skews Mid/Deep | `04` "Deposit Discovery" |
| Fossil Fuel — hidden, skews Mid/Deep, frequency ∝ `TrueRisk(Bio-hazard)` | `04` "Deposit Discovery" |
| "Force a real choice" — one building per slot, so Ore + aquifer on one tile = a Mine-vs-Well decision | `04` "Deposit Discovery" |
| Basic Deposit Survey (Standing Assignment) — Season 1+, every season, modest tool cost TBD; player-chosen rectangle; guaranteed-1 + 0.6/remaining Mid reveal within rect; flags Deep-eligible tiles; repeatable | `04` "Deposit Discovery"; `05` "Standing Assignments" |
| Deep Survey (Standing Assignment) — requires Portable High-Powered Scanning Equipment; auto-targets every flagged tile so far; guaranteed-1-Mid + guaranteed-1-Deep + 0.9/remaining-Mid + 0.5/remaining-Deep; repeatable | `04` "Deposit Discovery"; `05` "Standing Assignments" |
| Scanner Station Deposit Scanning mode — unaffected by rectangle/flagging; any depth, anywhere; probabilistic (0.4 Mid / 0.3 Deep illustrative), no guarantee, one reveal per active season | `04` "Scanner Station", "Deposit Discovery" |
| Survey worker eligibility — Basic/Deep Survey open to Settlers + Advanced All-Purpose Drones (not Basic); one-shot, resolves at Post-Sim | `05` "Standing Assignments"; `03` "Season Structure" |
| Mine — on discovered Iron/Copper Ore tile; staffed; Output 1 Ore/cycle from the site's %-mix (per-unit draw in sim); `production_time` 4s; cap 1; cost Lumber/Concrete + 1 Stone | `04` "Mine" |
| Quarry — on discovered Stone tile; staffed; Output 1 Stone/cycle; `production_time` 3s; cap 1; cost small Lumber only | `04` "Quarry" |
| Rare Metal Extractor — on discovered rare-metal tile; staffed; Output 1 rare metal/cycle; `production_time` 8s; cap 1; cost Lumber/Concrete + 2 Stone | `04` "Rare Metal Extractor" |
| Mining deposits: high-yield/bounded vs. low-yield/effectively-infinite; same per-unit Stewardship cost either way | `04` "Baseline Farm/Mined Resources" |
| Deposit-gated buildings relocate only to a discovered, unbuilt, matching-type deposit; vacated tile reverts to empty-but-discovered | `03` "Construction" |
| Feeds Stewardship `DisruptionFootprint` (discovery-gated slots weighted higher) and `ExtractionRestraint` | `06` "SEED Factions" |

**Boundary notes.**
- Thermal Vent → Geothermal Generator (System 5); aquifer → Well/Deep Well (System 6); Fossil Fuel → Fuel-based Generator upgrade (System 5). 7b covers the *deposits*; the consuming buildings are those systems'.
- Forest tiles / Clear-Cutting are a *visible* terrain feature, not part of the hidden-deposit system — audited under System 5 (Fuel) and System 1 (grid terrain); noted here only for the Forest-vs-Surface-deposit exclusivity rule.
- Portable High-Powered Scanning Equipment (the Deep Survey gate) is fabricated at Tinkerer's Workshop — see 7a.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **B-S1. The Surface-deposit guarantee is too weak to guarantee a playable opening.** `04` "Deposit Discovery" guarantees "at least one Stone, Iron, or Copper deposit at Surface tier". But Quarry (the only building needing neither Stone nor Concrete) can only be built on a **Stone** deposit, and Mine needs "+ 1 Stone" to build (`04` "Mine"). If the single guaranteed Surface deposit is Iron or Copper Ore, there is no route to first Stone without a lucky exploration draw. Compounds 7a's A-S1/A-S2. *Possible direction: guarantee a Surface **Stone** deposit specifically, or drop the "+1 Stone" from Mine's cost, or seed a tiny starting Stone quantity.*
- **B-S2. "On success" for a Survey is undefined — is there a success/failure roll, and what drives it?** `04` "Deposit Discovery" repeatedly says "On success, within that rectangle: guarantees 1…", implying a prior success check, but `05` "Standing Assignments" calls these "safe … one-shot … returns with a result", no risk spectrum. If there is a success probability, its value and modifiers (Aptitude Surveys bucket? Experience? the tool?) are unspecified. *Possible direction: no success roll — "on success" → "on completion"; the only RNG is the per-deposit reveal chances.*
- **B-S3. Basic Deposit Survey's required "basic tools" are unspecified.** `04` "Deposit Discovery": "Requires modest basic tools (small resource cost, TBD)." If this is a fabricated item, Basic Survey is not actually available Season 1 (its own claim). *Possible direction: a small raw-material cost (e.g. Lumber) paid at assignment, no fabricated prerequisite.*
- **B-S4. Iron Ore vs. Copper Ore: distinct deposit types, or one "Ore" characterization with an internal mix?** `04` "Baseline Farm/Mined Resources" says they are "mined from distinct deposits (differentiated at the source)" *and* "A single site can have multiple ore kinds mixed in some percentage distribution (e.g. 70% Iron / 30% Copper)". `04` "Deposit Discovery"'s overlap rule treats "Ore" as one of three mutually-exclusive characterizations. Needs one consistent representation. *Possible direction: one "Ore" characterization carrying a per-tile (Iron%, Copper%) split; drop the "distinct deposits" language.*

### Numeric (deferred to balancing — catalogued only)

- **B-N1.** Grid-wide deposit counts / frequencies per type per planet type; bounded-vs-infinite deposit ratio. `04` "Deposit Discovery", "Baseline Farm/Mined Resources".
- **B-N2.** Basic Survey rectangle size; Basic Survey tool cost. `04` "Deposit Discovery".
- **B-N3.** Per-deposit reveal probabilities (Survey 0.6 / 0.9 / 0.5; Scanner 0.4 / 0.3) — all illustrative. `04` "Deposit Discovery", "Scanner Station".
- **B-N4.** `DisruptionFootprint` base-vs-discovery-gated weighting; per-fixed-type definition of "changed state" (the "etc." in "built over, harvested, extracted from, etc."). `06` "SEED Factions". *(Shared with audit #1 CS5.)*
- **B-N5.** Bounded-deposit total quantities; Mine/Quarry/RME `production_time` values beyond those stated. `04` "Mine" / "Quarry" / "Rare Metal Extractor".

### Cross-check with `DESIGN_TODO.md`

`03` "Construction" and `04` "Deposit Discovery" both cite "`DESIGN_TODO.md`'s deposit overlap audit" — **no such item exists in `DESIGN_TODO.md`**. Either a stale reference or a genuinely missing item. The overlap *rules* are written into `04`; what would justify the citation and remains open is B-S4, co-occurrence probabilities (B-N1), and verifying the "force a real Mine-vs-Well choice" goal holds for every two-extractable tile. Recommend adding the item.

---

## 3. Internal consistency

- **B-IC1.** (= B-S4) The "distinct deposits" vs. "70/30 mixed Ore" framing conflict. `04` "Baseline Farm/Mined Resources".
- **B-IC2.** (= B-S2) "On success" phrasing vs. `05`'s "safe, no risk" Standing-Assignment framing. `04` "Deposit Discovery" vs. `05` "Standing Assignments".
- **B-IC3. Deep Survey is "meaningless until at least one tile has been flagged" yet still "required to have Portable High-Powered Scanning Equipment … regardless of whether any tiles are currently deep-survey-eligible".** Not a contradiction, but together they let a player fabricate an expensive item and assign the Standing Assignment for zero effect — warrants an explicit UI guard (grey out until ≥1 flagged tile). `04` "Deposit Discovery".

---

## 4. Cross-system consistency

- **B-CS1. The discovery→rare-metal→advanced-tech chain is gated on Deep-tier reveals, which gate on Portable High-Powered Scanning Equipment, which needs a rare metal.** Deep tier "skews toward rare-metal"; Deep Survey needs the Equipment; the Equipment needs a rare metal (`04` "Tinkerer's Workshop"). Scanner Station Deposit Scanning is the only tool-free route to Deep deposits, and Scanner Station itself needs HTC + High-Resolution Screens (`04` "Scanner Station"). Same soft circularity as 7a's A-CS3, from the deposit side. (Cross-ref 7a, System 10.)
- **B-CS2. Survey resolution has no narrative surfacing.** `03` "Season Structure" resolves Deposit Discovery at Post-Sim sub-step (2) as a bare mechanical step; `02` "Gameplay-Story Integration" says exploration/survey outcomes land in the Transmissions record in the Herald's voice. The hook exists; the wiring for surveys specifically does not. (Cross-ref Systems 2, 12.)
- **B-CS3. `DisruptionFootprint`'s "further disruption" weight for discovery-gated slots makes Deep rare-metal mining the single worst Stewardship action** — deliberate, but the player has no visibility into that tradeoff at the point of deciding to Deep Survey / build a Rare Metal Extractor. (Cross-ref audit #1 CS3, System 11.)
- **B-CS4. Deep Survey auto-targets the entire accumulated flagged set with no cost scaling**, while Basic Survey is bounded to one rectangle. One settler-season sweeps arbitrarily many tiles at 0.5/Deep. Intended (the tool is the gate) or a scaling hole? (Cross-ref Systems 3, 10.)
- **B-CS5. Farm Site Selection reveals Surface deposit positions before site lock-in** (`03` "Farm Site Selection"), so B-S1's deadlock risk degrades — for an informed player — into a "reroll (1 Ration each) until a Surface Stone deposit appears" tax, spending the same stockpile that is the food buffer. Lands hardest on players who don't know to check. (Cross-ref Systems 1, 12.)

---

## 5. Story & world consistency

- **Positive / reinforcing.** Hidden deposits + prospecting surveys square with the scout-expedition premise and `06`'s hidden-backend data philosophy. Thermal Vent Volcanic-exclusivity and Fossil-Fuel-tracks-biosphere are strong, economical worldbuilding — one lore fact reused as a mechanical dial rather than a new one invented.
- **B-ST1 (missed reinforcement).** Survey and deposit-reveal results are exactly the "Herald's-voice report" content `02` "Gameplay-Story Integration" describes for the Transmissions record, but nothing routes them there (= B-CS2).
- No lore conflicts in this half.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Planning reversible / randomization gated* — survey RNG resolves at Post-Sim, after Planning Lock-in; the rectangle choice is a reversible planning action. `03` "Season Structure"; `01` "Planning phase is reversible".
- *Difficulty from breadth of tradeoffs* — where-to-prospect + which-survey-method is a real strategy choice with no execution-skill component. `01`.
- *Numbers stay small* — small probabilities, small deposit counts.

**Risks / violations:**
- **B-P1 (→ SF). Colour is never the sole channel.** "deep-survey-eligible" flagged tiles, discovered-vs-undiscovered deposit tiles, and per-depth reveal state all need a non-colour marker; none is specified. `01` "Color is never the sole channel".
- **B-P2 (→ SF). Failure legibility / forgiving of mistakes.** The B-S1 bootstrap deadlock (and its B-CS5 reroll-tax form) is invisible to a player who doesn't already know to inspect the Surface deposit type at Farm Site Selection. `01` "Failure should always be legible", "Forgiving of individual mistakes".
- **B-P3. Passable-plan-quick.** Re-selecting a Basic Survey rectangle every season encodes a real decision (where to look next), so it's within the carve-out — but a "repeat / advance last rectangle" default would keep the familiar-player floor low. `01` "A passable plan should always be quick to reach".

---

## 7. Player legibility

- Discovered deposits, flagged tiles, and per-depth reveal state all need the visual language B-P1 calls for; undiscovered deposits are invisible by design (fine).
- Which survey method to use, and why Deep Survey is inert with no flagged tiles (B-IC3), needs UI signalling.
- The Stewardship cost of discovering + extracting a discovery-gated deposit (B-CS3) is invisible at decision time.
- Survey outcomes should read in the log / Transmissions (B-CS2), or a reveal "just happens" with no trace.

---

## 8. Fun / scope risk

- **Three overlapping discovery mechanisms** (Basic Survey, Deep Survey, Scanner Station Deposit Scanning) plus exploration Site Reveals. Scanner Station is tier-3, expensive (HTC + Screens), probabilistic, and largely duplicates what the two free Standing-Assignment surveys do — its distinct value is unstaffed late-game automation (tier-2 upgrade). Worth asking whether it earns a whole building or should be a smaller add-on. *Cut-or-simplify candidate.*
- **Basic Survey's per-season rectangle** risks becoming rote "sweep the next strip" for a familiar player; a repeat-last-rectangle default (B-P3), or a coarser one-time "survey priority zone", would keep it a decision without the per-season gesture.
- **Deep Survey's unbounded sweep (B-CS4)** — either a deliberate reward for paying the tool cost, or a scaling hole. Decide.
- **Keep:** the where-to-prospect choice, the Basic-vs-Deep method tradeoff, and the one-building-per-slot "force a real choice" (Mine-vs-Well) — all high value, low rule weight.

---

## 9. Findings summary

### Blockers

- **B-S1.** The Surface-deposit guarantee ("Stone OR Iron OR Copper") doesn't guarantee first Stone, and Stone is required to build a Quarry (on a Stone tile) or a Mine (+1 Stone cost) — a site whose one Surface deposit is Ore can deadlock. (§2 — `04` "Deposit Discovery" / "Mine" / "Quarry"; cross-ref 7a A-S1/A-S2, System 1)
- **B-S4 / B-IC1.** Iron Ore vs. Copper Ore are described both as "distinct deposits" and as one site with a "70/30 mixed" split; the overlap model needs one consistent representation. (§2/§3 — `04` "Baseline Farm/Mined Resources" / "Deposit Discovery")

### Should-fix

- **B-S2.** "On success" for a Survey is undefined — a success/failure roll (with unspecified modifiers) or just "on completion"? Conflicts with `05`'s "safe, no risk" framing. (§2/§3 — `04` "Deposit Discovery" vs. `05` "Standing Assignments")
- **B-S3.** Basic Deposit Survey's required "basic tools" are unspecified; a fabricated prerequisite would break its stated Season-1 availability. (§2 — `04` "Deposit Discovery")
- **B-IC3.** Deep Survey can be fabricated-for and assigned with zero effect when no tile is flagged — needs a UI guard. (§3 — `04` "Deposit Discovery")
- **B-CS1.** Deep-tier discovery (→ rare metals → advanced tech) is softly circular through Portable High-Powered Scanning Equipment; the tool-free bootstrap routes (Scanner Station, exploration windfalls, a lucky Mid-depth rare metal) are never stated as intended. (§4 — `04` "Deposit Discovery" / "Tinkerer's Workshop"; cross-ref 7a A-CS3)
- **B-CS3.** The Stewardship `DisruptionFootprint` penalty for discovering + mining a discovery-gated (esp. Deep) deposit is invisible when the player commits to the survey / extractor. (§4 — `06` "SEED Factions"; cross-ref audit #1 CS3, System 11)
- **B-CS5.** B-S1's deadlock risk degrades, for informed players, into a Ration-spending site-reroll tax and lands hardest on players who don't know to check the Surface deposit type. (§4 — `03` "Farm Site Selection"; cross-ref Systems 1, 12)
- **B-P1.** No non-colour marker specified for discovered deposits, flagged deep-eligible tiles, or per-depth reveal state. (§6 — `01` "Color is never the sole channel")
- **B-P2.** The bootstrap-Stone deadlock has no in-game legibility signal. (§6 — `01` "Failure should always be legible" / "Forgiving of individual mistakes"; cross-ref System 12)
- **Missing TODO.** `03` "Construction" and `04` "Deposit Discovery" cite a "deposit overlap audit" item that does not exist in `DESIGN_TODO.md`; add it (covering B-S4, co-occurrence probabilities, Mine-vs-Well verification). (§2/§4 — `DESIGN_TODO.md`)

### Nice-to-have

- **B-CS2 / B-ST1.** Route survey and deposit-reveal outcomes into the Transmissions record / log in the Herald's voice. (§4/§5 — `02` "Gameplay-Story Integration"; cross-ref System 2)
- **B-CS4.** Decide whether Deep Survey's unbounded flagged-set sweep is an intended tool-cost reward or a scaling hole. (§4)
- **B-P3.** Add a repeat / advance-last-rectangle default for Basic Survey. (§6 — `01` "A passable plan should always be quick to reach")
- **§8.** Reconsider whether Scanner Station Deposit Scanning earns a whole tier-3 building given it largely duplicates the two free surveys. (§8)

### Defer (numeric / content-pass)

- **B-N1.** Deposit counts / frequencies per type per planet; bounded-vs-infinite ratio. `04` "Deposit Discovery".
- **B-N2.** Basic Survey rectangle size; tool cost. `04` "Deposit Discovery".
- **B-N3.** Per-deposit reveal probabilities (Survey 0.6/0.9/0.5; Scanner 0.4/0.3). `04` "Deposit Discovery" / "Scanner Station".
- **B-N4.** `DisruptionFootprint` weighting + per-fixed-type "changed state" definition. `06` "SEED Factions" *(shared with audit #1)*.
- **B-N5.** Bounded-deposit total quantities; remaining mining `production_time` values. `04` "Mine" / "Quarry" / "Rare Metal Extractor".
