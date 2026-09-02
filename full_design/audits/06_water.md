# Audit — System 6: Water

Pure design review against `full_design/`; no implementation exists. Citations
are `file` → "Section" (no anchor links: this file sits in `audits/` and the
repo link-checker only scans `full_design/*.md`). §2–8 carry the reasoning; §9
is the authoritative one-line index.

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Water tracked as a live Income rate (Water/s); no stockpile, no inventory presence, nothing carried across the season boundary | `04` "Water" |
| Collection buildings' "Output: Water per cycle" figures are contributing sources to that one rate | `04` "Water" |
| No water storage buildings; no transport/pipes/irrigation modelled; no spatial adjacency between collection and consumption | `04` "Water" |
| All collection buildings require the Water Processing Plant to function at all — mere-existence prerequisite gate, no "Raw Water" intermediate | `04` "Water", "Water Processing Plant" |
| Water Processing Plant is a starting building (not player-built); base tier mechanically inert; occupies a real grid slot | `04` "Water Processing Plant" |
| Reclamation upgrade — settlement-wide −X% to net Water consumption-rate demand; High-Tech-Components-gated; explicitly farming-throughput, not settler-safety | `04` "Water Processing Plant" |
| Water Condenser / Ice Melter / Cistern / Well — all Staffed, no input, Output: Water/cycle (rate TBD); all low-barrier construction cost (Lumber/Concrete only) | `04` "Water Condenser", "Ice Melter", "Cistern", "Well" |
| Per-planet suitability — Condenser best on Volcanic; Ice Melter Frozen-exclusive; Cistern best on Verdant; Well any tile, low rate | `04` "Water Condenser", "Ice Melter", "Cistern", "Well"; `06` "Initial Planet Types" |
| Well on a detected-aquifer tile auto-becomes Deep Well — same building, higher rate, no build choice or upgrade action | `04` "Well"; `04` "Deposit Discovery" (aquifer) |
| Settler consequence — a single binary check at Post-Sim: zero Water Income anywhere this season → every settler dies; any nonzero → safe; no partial/proportional in-between; settler need never competes with production reservations | `04` "Water" |
| Plant-crop Growing-phase Water = a consumption-rate reservation held for the whole phase, sized so rate × phase-duration = crop's total need | `04` "Farm/Production" ("Production Cycle") |
| Growing-phase water-draw queue — one settlement-wide strict-FIFO queue; front entry reserves against unreserved Income capacity each Mid-Sim tick; no skip-ahead; ties break by build/placement order; re-join the back each cycle; reservation released the instant Growing ends | `04` "Farm/Production" ("Water-draw queue (Growing phase only)") |
| Four animal-based buildings (Dairy Pasture, Poultry Coop, Sheep Pasture — plus the preamble's "all") use a flat per-cycle Water requirement, NOT the queue, with **no defined insufficient-Water behaviour** | `04` "Farm/Production" (preamble, blockquote after "Water-draw queue"); `DESIGN_TODO.md` "Water resource open threads" |
| `TechAchievement` — Condenser/Ice Melter/Cistern 0; Well 0 → 2 as Deep Well; Water Processing Plant 0 → 2 (Reclamation) | `04` "Water", "TechAchievement Catalog" |
| Water is never tradeable (income or expense) — no stockpile to exchange | `05` "Escalation Chains" (Trade Agreements); `04` "Resources" |
| Well / water-collection explicitly does NOT incur `ExtractionRestraint` (ongoing, non-depleting) | `06` "SEED Factions" (Stewardship) |

**Boundary notes (ambiguous ownership).**
- **Animal-building Water draw** — the mechanism (not just its failure mode) is a Production Model (System 4) concern as much as a Water one; findings B1 / G-S1 sit on that seam.
- **Aquifer → Deep Well** — aquifer detection is Deposit Discovery (System 7); this system only consumes the "tile has a detected aquifer" fact.
- **The binary settler-death check** — shares the roster-removal mechanic with Settlers (System 9) and the Post-Sim timing/"this season" definition with Season Structure (System 2).
- **Reclamation's HTC gate** — depends on Fabrication (System 7) reaching High-Tech Components.
- **Rate-model twinning** — Water is stated to have "the same shape as Energy" (System 5); the asymmetries are real (see IC2).

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. The animal-building Water mechanic is undefined end-to-end, not just its failure mode.** `04` "Farm/Production" gives the four animal buildings a "flat per-cycle Water requirement", but Water is a rate with no stockpile — there is no defined way a per-cycle amount draws from a rate. Reserve-a-rate-share for the cycle (like Growing)? Draw instantaneously at cycle completion (impossible against a stockless rate)? And then what on shortfall — pause, slow, skip the cycle, nothing? `DESIGN_TODO.md` frames only the insufficient case as open; the sufficient case is open too. *Possible direction: animal buildings reserve a rate share for their whole `production_time` cycle via the same queue, joining behind plant-crop Growing entries.*
- **G-S2. "Zero Water Income anywhere this season" has no defined temporal semantics.** Instantaneous at the Post-Sim moment? Ever-nonzero at any Mid-Sim tick? Time-integrated above zero? The reading determines whether a late-season Energy shed (see CS1), a hazard stopping a collection building, or a mid-season toggle triggers total colony loss. *Possible direction: "any collection building produced a nonzero rate for any part of Mid-Sim" — the most forgiving reading, and the one that keeps Energy's random shedding from being lethal.*
- **G-S3. No planning-phase Water readout is specified.** Energy has an explicit optimistic Income/Consumption bar with indicator lines; Water — despite "the same shape as Energy" — has no named UI. The player cannot see, before committing a season, whether the binary survival check will pass or whether the Growing queue will stall. *Possible direction: mirror Energy's bar — planned Water Income vs. summed reservation demand, with the same best-case caveat.*

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** Collection rates per building (Condenser / Ice Melter / Cistern / Well / Deep Well). `04` "Water".
- **G-N2.** Plant-crop per-crop total Water need and Growing-phase reservation size. `04` "Farm/Production".
- **G-N3.** Animal-building flat per-cycle Water amount. `04` "Farm/Production".
- **G-N4.** Reclamation reduction magnitude (illustrative −20%) and its upgrade cost (Lumber:Concrete ratio + HTC amount). `04` "Water Processing Plant".

### Cross-check with `DESIGN_TODO.md`

The "Water resource open threads" item is marked resolved with a "Still open" note covering **only** the animal-buildings insufficient-Water behaviour. It does not flag: the sufficient-case animal draw mechanism (G-S1 is broader), the "this season" semantics (G-S2), the missing planning readout (G-S3), the missing confirm gate (SF1), or the Energy-shedding interaction (CS1). Recommend the consolidation pass extend it.

---

## 3. Internal consistency

- **IC1. Farm Water calibration references an anchor the Water section deleted.** `04` "Farm/Production" preamble: non-plant buildings' Water is "calibrated against the settler baseline of 1 Water/season." `04` "Water": "there's no longer a settler-need figure to calibrate against … no shared numeric anchor." The Farm/Production preamble is stale. (→ SF2.)
- **IC2. "The same shape as Energy" overclaims.** Water differs from Energy on: staffed-not-zero-effort collection; a hard prerequisite building; no random-shedding mechanic; a binary settler consequence Energy has no analogue of; and (as yet) no planning-phase readout. Not a mechanical contradiction, but the flat claim invites readers to assume parity that isn't there. (→ NTH1.)
- **IC3. The blockquote under "Water-draw queue" understates the animal-building gap** — it reads as "the queue doesn't apply to them, and their shortfall behaviour is TBD," when in fact their entire draw model against a stockless rate is unspecified. (→ G-S1.)

---

## 4. Cross-system consistency

- **CS1 (→ B2). Energy random-shedding vs. the binary Water check.** `04` "Resources" sheds active consumers at random on an Energy shortfall, recomputed on change events. Water collection buildings are ordinary staffed buildings drawing baseline Energy, so they are in the shed pool. Under a strict "zero at the Post-Sim instant" reading of G-S2, a random shed of the colony's only collection building late in the season causes total colony loss with no player decision behind it — a direct hit on `01` "no purely ambient, untriggered randomness should be able to end a run" and "misfortune … should always trace back to a real decision point." The two systems must be reconciled explicitly.
- **CS2. Mandatory season-1 Water bootstrap.** Only the Water Processing Plant starts on the grid (`04` "Water Processing Plant"); no collection building does. Every run therefore *requires* building and staffing a collection building in season 1 or the colony dies at Post-Sim — a forced, non-skippable action sequence that also depends on the Lumber/Concrete bootstrap chain (System 7) being reachable turn one. Tension with `01` "a passable plan should always be quick to reach" and with the initial-grid-state gap already flagged in audit #1 (G-S2 there).
- **CS3. Animal-building draw shares the Production Model queue question (System 4).** Whatever G-S1 resolves to must be consistent with `03` "Production Model"'s continuous-rate model and `04` "Farm/Production"'s per-building `production_time` values.
- **CS4. A queue-blocked farm has no status surface.** `03` "Site Panel (UI)" leaves the status section "open for whatever future mechanics turn out to need a per-site status readout." "Blocked in the Water queue" is exactly that; without it, a stalled Growing phase is invisible (→ SF6, §7).
- **CS5. Aquifer use and Stewardship.** `06` `DisruptionFootprint` counts "any fixed/environmental slot whose state has changed." An aquifer is a hidden deposit; building a Well on it changes the slot and plausibly also draws the discovery-gated extra weight. Yet `ExtractionRestraint` explicitly excludes water. So aquifer tapping is Stewardship-penalised via Disruption but not Extraction — an unstated, possibly-unintended asymmetry. (→ SF7.)
- **CS6. Toggle parity.** The Energy redesign gives "every building" an active/inactive toggle. Applied to a colony's sole Water collection building, toggling it off is a one-click path to the binary wipe. Whether that is gated like confirming planned deaths is unstated. (→ SF5.)
- **CS7 (planet types, cross-cutting).** Per-planet Water answers are coherent and well-differentiated: Ice Melter (Frozen-exclusive), Condenser (Volcanic), Cistern (Verdant), Well+aquifer-hope (Arid) — and Arid's water scarcity is reinforced by its Hybridization signature (reduced Water need) and its exploration exclusive (hidden aquifer/oasis, "deepens C"). Worth recording as a deliberate strength.

---

## 5. Story & world consistency

- **Reinforcing.** Water-as-a-rate with no modelled transport fits the `02` "SEED's Culture, and the Player's Role" framing of the player as a remote, plan-level Herald — no lore conflict. Per-planet collection methods (melt ice on Frozen, condense humidity on Volcanic) are grounded, not arbitrary.
- **Tonal jump (→ NTH2).** "Zero Water production this season → every settler dies," with no ramp, sits hard against the stated tone (`00_index.md` Overview: "cozy … low-level survival tension … not desperate survival"). The design acknowledges the divergence from nutrition's tiering but gives it no in-fiction voice. A one-line frame — closed-loop life support has no graceful degradation, it either runs or it doesn't — would make the starkness read as an intentional world fact rather than an outlier.
- **Missed reinforcement.** The Water Processing Plant is "mechanically almost inert" set dressing. It could carry a small piece of the Crash-Research-Era shielding/recycling-tech lineage the way the weather domes do (`02` "The Crash Research Era"), tying the mandatory starting structure to the setting.

---

## 6. Design-principle adherence

**Adherent — record as deliberate strengths:**
- *Difficulty from breadth of tradeoffs, not execution* — the FIFO queue is explicitly built so gaming service order is an "emergent trick," not the designed-for skill (keep total Income ahead of total demand). Good.
- *UI interaction is minimal* — the queue is fully automatic; collection buildings are ordinary staffed sites; Reclamation is a one-time upgrade. Low routine interaction.
- *Planning phase is reversible / randomization gated* — Water infrastructure placement carries no in-planning draw; aquifer RNG resolves in survey during simulation, and Well→Deep Well is a passive consequence, not a planning-phase roll.

**Risks / violations:**
- **P1 (→ B2 / CS1). Forgiving of individual mistakes; no ambient randomness ends a run.** The binary wipe, combined with Energy's random shedding and the undefined "this season" semantics, can end a run from an ambient roll after the player built adequate infrastructure. The most serious finding in this audit.
- **P2 (→ B3 / SF1). Failure should always be legible.** No planning readout for the survival margin, and no stated confirmation gate for a season that will wipe the colony (starvation has one — `05` "Rations (Basic Sustenance)"). A first-time player can lose everything at season-1 Post-Sim with zero warning.
- **P3 (→ CS2). A passable plan should always be quick to reach.** The mandatory season-1 build-and-staff-a-collection-building sequence is small but non-skippable and instantly fatal if missed; coast-able only after it's standing and sticky-staffed.
- **P4. Colour is never the sole channel** — n/a yet (no Water overlays specified), but any future Income/demand readout inherits Energy's requirement for a non-colour cue. (→ NTH3.)
- Not engaged: numbers-stay-small (all rates TBD, small), units-unspecified (Water/s is a rate, fine), naming, normalize-before-combining (Water feeds no faction formula directly), dexterity-timing / touch-mouse parity (input/Art deferred).

---

## 7. Player legibility

- **Survival margin** — not surfaced pre-commit (P2 / B3). The single worst legibility gap in the system.
- **Growing queue stall** — a farm sitting in Growing with no visible reason; needs a named Site Panel status state (CS4 / SF6).
- **Deep Well auto-upgrade** — is the player told the Well deepened? Should be a log / Transmission line (SF8).
- **Reclamation's benefit** — "eases the water-draw queue" is invisible unless the player is already feeling stalls, making the upgrade hard to evaluate at purchase time.
- **Next-season / Post-Sim timing of the settler check** — consistent with other Post-Sim resolutions, so learned once and transfers. Good.

---

## 8. Fun / scope risk

- **The FIFO queue** — good "keep total ahead of total" pressure at near-zero interaction cost. Keep.
- **Binary settler wipe** — high-variance, low-nuance. Defensible as a hard floor *only* if it cannot fire from a single under-resourced or unlucky season (see B2). *Cut-or-change candidate:* a one-season zero-Water lapse could instead inflict a settler status effect / assignment lockout, with death reserved for a sustained lapse — mirroring the nutrition tiering the design deliberately diverged from. Worth an explicit decision, not drift. (→ NTH4.)
- **Reclamation** — tech-2 / HTC-gated for a benefit (easing a queue that may not be biting) that never touches survival. Thin. Re-scope (let it also widen the survival margin or the optimistic-bar headroom) or cut. (→ NTH5.)
- **Water Processing Plant base tier** — a grid-slot tax with no decision attached. Acceptable as bootstrapping, but note it adds nothing the player chooses.
- **Narrowing risk** — low; the per-planet collection-building split (CS7) gives real per-planet variety rather than one dominant answer.

---

## 9. Findings summary

### Blockers

- **B1.** Animal-building Water draw mechanism is undefined against the rate-not-stock model — not just the shortfall case; a "flat per-cycle" amount has no defined way to draw from a stockless rate. (§2 G-S1, §3 IC3, §4 CS3 — `04` "Farm/Production" preamble / "Water-draw queue" blockquote)
- **B2.** "Zero Water Income anywhere this season" has no temporal semantics (instant vs. ever-nonzero vs. integrated); under the strict reading, Energy's random consumer-shedding can cause total colony loss with no decision behind it. (§2 G-S2, §4 CS1, §6 P1 — `04` "Water" vs `04` "Resources" (Energy Income/Consumption Rates))
- **B3.** No planning-phase Water readout is specified — the player cannot see before committing whether the survival check passes or the Growing queue will stall. (§2 G-S3, §6 P2, §7 — `04` "Water"; contrast `04` "Resources" Energy bar)

### Should-fix

- **SF1.** Add a warning / confirmation gate for confirming a season that will trigger the zero-Water wipe, matching the existing starvation confirmation dialog. (§6 P2 — `04` "Water"; `05` "Rations (Basic Sustenance)")
- **SF2.** Resolve the stale anchor: `04` "Farm/Production" preamble calibrates farm Water "against the settler baseline of 1 Water/season," which `04` "Water" says no longer exists. (§3 IC1)
- **SF3.** Define the "build/placement order" queue tiebreak canonically, given planning-phase reversibility can reorder pieces. (§2, §4 — `04` "Farm/Production" "Water-draw queue")
- **SF4.** Specify that the queue advances per unit of sim-time, not wall-clock, so playback speed can't change queue outcomes. (§2 — `04` "Farm/Production" "Water-draw queue" ("each Mid-Sim tick"))
- **SF5.** State whether a collection building's active/inactive toggle can turn off the colony's only Water source, and whether that is gated like confirming planned deaths. (§4 CS6 — `04` "Resources" (universal toggle) vs `04` "Water")
- **SF6.** Make "blocked in the Water queue" a named Site Panel status state so a stalled Growing phase's cause is visible. (§4 CS4, §7 — `03` "Site Panel (UI)" status section)
- **SF7.** State whether tapping an aquifer (Well → Deep Well) incurs `DisruptionFootprint` and its discovery-gated extra weight, given `ExtractionRestraint` excludes water but the slot-state-changed rule does not. (§4 CS5 — `06` "SEED Factions")
- **SF8.** Confirm a Deep Well auto-upgrade and a stalled/failed Growing queue emit log / Transmission lines. (§7)

### Nice-to-have

- **NTH1.** Soften "the same shape as Energy" — enumerate the real asymmetries (staffed collection, prerequisite building, no shedding, binary consequence, no planning bar yet). (§3 IC2)
- **NTH2.** Give the binary Water collapse an in-fiction one-liner (closed-loop life support has no graceful degradation) so the tonal jump from "mild survival tension" reads as intentional. (§5)
- **NTH3.** Record the non-colour-channel requirement for any future Water Income/demand readout, matching Energy's. (§6 P4)
- **NTH4.** Decide explicitly whether one zero-Water season should be total death or a recoverable status effect, with death reserved for a sustained lapse. (§8)
- **NTH5.** Re-scope or cut Reclamation — tech-2 / HTC-gated for a benefit that never touches survival and is invisible unless the queue is already biting. (§8)

### Defer (numeric / content-pass)

- **D1.** Collection rates per building (Condenser / Ice Melter / Cistern / Well / Deep Well). `04` "Water".
- **D2.** Plant-crop per-crop total Water need and Growing-phase reservation size. `04` "Farm/Production".
- **D3.** Animal-building flat per-cycle Water amount. `04` "Farm/Production".
- **D4.** Reclamation reduction magnitude (−20% illustrative) and upgrade cost (Lumber:Concrete + HTC). `04` "Water Processing Plant".
