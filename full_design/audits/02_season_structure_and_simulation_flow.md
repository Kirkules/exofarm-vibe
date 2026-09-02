# Audit — System 2: Season Structure & Simulation Flow

Design audit against `full_design/`; no implementation exists. Citations are
`file` → "Section" (no anchor links: this file sits in `audits/` and the repo
link-checker only scans `full_design/*.md`). §9 is the authoritative findings
index; §2–8 carry the reasoning.

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Two-phase season loop (Planning ⇄ Simulation); "results feed into the next planning phase" | `03` "Season Structure" |
| "Proceed to Next Season" confirmation = the reversibility boundary | `03` "Planning Phase"; `01` "Planning phase is reversible" |
| **Planning Lock-in** — instantaneous freeze right before the Mid-Sim clock; no consequence computed, nothing revealed | `03` "Season Structure" |
| Planning Lock-in hosts — Food Storage deposits committed; food-for-consumption selection fixed; construction/upgrade/relocate queued (robot consumed at queue time) | `03` "Season Structure" |
| **Mid-Sim** — the only window where real time passes; 30s @ 1×; continuous production ticks; discrete events with a genuine reason to occupy an interval (hazard events); ambient (decoupled) visual depictions of Post-Sim-resolved activities | `03` "Season Structure"; `07` "Art Design" |
| Fixed real-time window — 30s @ 1×; `production_time` values and event occurrence rates calibrated against it; playback speed is a pure time-multiplier | `03` "Season Structure" |
| **Post-Sim** — instantaneous discrete resolution, no clock; merges "right after clock ends" with "top of next planning phase"; never precedes a season's Mid-Sim | `03` "Season Structure" |
| Post-Sim sub-step order — (1) Scanner report (2) Deposit Discovery (3) pooled nutrition (3.5) Trade Agreement (4) construction completions (5) Exploration Task confirmation UI [next planning phase] (6) Vaccine unlock check [last, unconditional]; steps 1/2/4 mutually order-free | `03` "Season Structure" |
| Nutrition consumption deferred to Post-Sim so mid-season production is consumable that same season | `03` "Season Structure" |
| Playback-speed slider — 0×–5×, snap 0.1; 0× = outright pause (no separate pause control); 5× → 30s compresses to 6s; no separate skip affordance | `03` "Season Structure" |
| Playback default — sticky-carried per season, 1× until first adjusted; adjusting the in-season slider *is* what updates the default; not a Settings preference | `03` "Season Structure" |
| Playback legibility targeted at 1× only; no minimum wall-clock floor at higher speeds; legibility-for-time tradeoff in the player's hands; log available afterward | `03` "Season Structure" |
| Log / event-feed — no forced overlay; single log opened via button/icon; openable *during* sim, live-updating; also reviewed after | `03` "Season Structure" |
| Routine production aggregated — one live-updating line per resource *type* (not per building), incrementing and re-timestamping to the most recent contributing tick | `03` "Season Structure" |
| Noteworthy events — individual timestamped lines interspersed (hazard occurrences, settler deaths, vaccine unlocks, Deposit Discovery reveals, exploration escalations unlocking, "and similar") | `03` "Season Structure" |
| Transmissions — persistent cross-season narrative channel (mail-evoking HUD icon; Herald's-voice reports, Earth/SEED flavor, advance hazard warnings); kept fully separate from the per-season mechanical log | `03` "Season Structure"; `02` "Gameplay-Story Integration" |
| Production progress overlay — per-tick semi-transparent sprite, opaque bottom-up fill, thin white boundary line; driven by the continuous-rate progress value; primary at-a-glance channel, deliberately redundant with the log | `03` "Season Structure"; `07` "Art Design" |
| Farm-specific overlay variant — fill resets per phase; brown/green/gold; + per-phase icon badge | `03` "Season Structure" |
| Assigned-worker Mid-Sim depiction — static sprite parked at/near the site; no locomotion; idle frame OK; ownership/presence cue only | `03` "Season Structure" |
| Ambient Mid-Sim visuals for Post-Sim-resolved activities — decoupled from resolution (Scanner radio-wave pulse; survey settler "searching") | `03` "Season Structure"; `07` "Art Design" |

**Boundary notes (ambiguous ownership).**
- **Post-Sim sub-step order** references resolutions owned by Systems 6/7/8/10/11 (Scanner, Deposit Discovery, nutrition, Trade Agreement, construction, Exploration, Vaccine). This system owns the *timing skeleton and ordering*; each resolution's internals belong to its own system.
- **Season 1's front edge** — no Post-Sim precedes it; what seeds the first planning phase is `DESIGN_TODO.md` "Run-start flow" / System 12. This system owns whether Season 1 has a normal Planning Lock-in and what plays Post-Sim's seeding role (B1).
- **Hazard event windows** live in Mid-Sim but the event model is System 11; this system owns "Mid-Sim is where discrete timed events run."
- **Production overlay / farm variant / worker depiction** are also claimed by System 4 and Art Design; this system owns them as the Mid-Sim visual layer, the fill math is System 4.

---

## 2. Completeness gaps

### Structural

- **G-S1. Season 1's entry state is unspecified.** Post-Sim "never occurs before a season's Mid-Sim has actually run" (`03` "Season Structure"), so the first planning phase has no Post-Sim before it. What seeds it — starting grid/inventory, the one-time run-start SEED summary transmission (`06` "In-Simulation Hazard Events"), whether Season 1 has a normal Planning Lock-in with the same freeze semantics — is only partially covered by `DESIGN_TODO.md` "Run-start flow" and not reconciled with the loop skeleton. *Possible direction: a "Run Start" pseudo-moment that plays Post-Sim's seeding role, after which Season 1 runs as any other season.*
- **G-S2. No sub-step applies this season's production output to inventory.** The Post-Sim order (`03` "Season Structure") goes straight to consumers — (3) nutrition, (3.5) Trade Agreement expense — and construction cost is spent at Planning Lock-in, but nothing in the order credits the season's accumulated production. `03` says production "accumulates through Mid-Sim"; the moment it becomes a readable inventory balance for the Post-Sim consumers is undefined. *Possible direction: an explicit "production tallied to inventory" step (continuous during Mid-Sim, or Post-Sim step 0).*
- **G-S3. Mid-Sim's process list is under-specified.** `03` "Season Structure" names only "continuous production ticks" and "discrete event[s]" (hazards). It omits the Energy/Water live-rate recomputation + random consumer-shedding (`04` "Resources" — triggered by Conditional-source windows, hazard windows, build/destroy/toggle events, all Mid-Sim) and the plant-crop Water-draw FIFO queue's per-tick reservation attempts (`04` "Farm/Production"). *Possible direction: enumerate the full Mid-Sim process set.*
- **G-S4. What freezes at Planning Lock-in is given as a partial list of three items** (`03` "Season Structure"), read as exhaustive. Unaddressed: worker assignments, multi-recipe selections (`03` "Site Panel"), every building's active/inactive toggle and Fuel-based Generator's fuel-limit setting (`04` "Resources"), shield placement, exploration-task assignments + elected consumables (`05` "Assignment"). *Possible direction: state the general rule ("every reversible planning choice freezes at Lock-in") with playback speed as the one named exception.*

### Numeric (deferred to balancing)

- **G-N1.** 30s Mid-Sim window at 1× — working value. `03` "Season Structure".
- **G-N2.** Playback ceiling (5×) and 0.1 snap granularity. `03` "Season Structure".
- **G-N3.** Interleave order when an aggregated production line and an event line share a timestamp. `03` "Season Structure".
- **G-N4.** Calibration constants tying `production_time` and event occurrence rates to the fixed window. `03` "Season Structure".

### Cross-check with `DESIGN_TODO.md`

The "Season simulation" item lists the resolved pieces and explicitly hedges it is "not a claim that every possible gap has been surfaced." G-S1 is partially inside "Run-start flow". G-S2, G-S3, G-S4 are not flagged anywhere — recommend adding G-S2 and G-S3 (both structural).

---

## 3. Internal consistency

- **IC1. "Instantaneous" Post-Sim hosts an interactive dialog.** `03` "Season Structure" calls Post-Sim "instantaneous, discrete resolution with no clock running," yet sub-step (5) is the Exploration Task confirmation UI "(start of next planning phase)" — a UI the player operates over wall-clock time, and (6) runs after it. Reword to "no simulation clock runs." (→ SF1 / NTH3.)
- **IC2. Fractional sub-step "(3.5)".** Trade Agreement resolution is wedged in as "(3.5)" (`03` "Season Structure") — a visible artifact of the list being amended after it was written. Renumber 1–7. (→ NTH1.)
- **IC3. Post-Sim step (4) internal order.** Step (4) "construction/upgrade/relocate completions" is one sub-step with unspecified internal order, but `03` "Construction" needs a relocation to complete before a dependent build/upgrade in the same season (the two-robot "clear a blocker, then upgrade into the freed space" case). Same finding as Audit 1 SF1, owned here. (→ SF2.)
- **IC4. Process narration throughout "Season Structure".** "renamed from the old single 'Outside-Sim'", "(was 15s in the prior implementation…)", "Supersedes the prior implementation's standalone Skip button", "Replaces the old live-log-overlay/outcome-log split", "(This tier already meant destruction under the hood…)" — all disallowed by `01` "Design docs describe the current design, not its history." Known transitional state. (→ NTH2.)

---

## 4. Cross-system consistency

- **CS1 (→ SF3). Post-Sim straddles the season boundary.** Sub-step (5) is a next-planning-phase UI; (6) Vaccine check runs "after every Confidence-feeding source … including exploration-driven ones" — i.e. after (5), after a player interaction and a wall-clock gap. Post-Sim is therefore not one atomic instant. *Possible direction: split into "Post-Sim (immediate, 1–4)" and "next-planning-phase preamble (5–6)".*
- **CS2 (→ SF4). Hazard-warning lead time has no mechanism in the loop.** `06` "In-Simulation Hazard Events" promises warnings "a season or two ahead" (high confidence) or "right before the affected season's planning phase" (low); the triggering hidden draw is described as a Mid-Sim occurrence. Nothing says when a *future* season's draw is rolled so a warning can precede it. *Possible direction: roll season N's hazard draw at the end of season N−k's Post-Sim, store it, surface as a Transmission, execute in N's Mid-Sim.*
- **CS3 (→ SF5). "Mid-Sim log lines" conflates occurrence with resolution.** `03` "Season Structure" lists "hazard occurrences, settler deaths, vaccine unlocks, Deposit Discovery reveals, exploration escalations unlocking" as Mid-Sim timestamped lines. Only hazard occurrences and hazard-caused deaths happen in Mid-Sim; starvation deaths (Post-Sim step 3), vaccine unlocks (step 6), Deposit Discovery reveals (step 2), and exploration escalations (step 5, next planning phase) all resolve at Post-Sim. *Possible direction: Post-Sim resolutions append to the same log with a Post-Sim timestamp / in a resolution section, not as Mid-Sim entries.*
- **CS4. Final-outcome irreversibility is implied, never stated.** `01` "Planning phase is reversible" resets each planning phase; the loop needs to say the *previous* season's Post-Sim outcomes (deaths, destroyed buildings, consumed/produced resources, completed construction) are final and only the new planning choices are reversible. (→ SF6.)
- **CS5. Playback speed is deliberately outside Planning Lock-in.** `03` "Season Structure" has the per-season speed set/changed *during* Mid-Sim (sticky-carried, in-season slider updates the default). Consistent with it not being a gameplay input, but it is the one planning-adjacent value not frozen at Lock-in and should be named as the exception under G-S4.
- **CS6. Scanner Station ambient pulse — clean example, no conflict.** `07` "Art Design" 's radio-wave pulse "throughout the window" is explicitly ambient; the report resolves at Post-Sim (1). Consistent; noted as the model case for the decoupling rule.

---

## 5. Story & world consistency

- **Reinforcing.** The passive, watch-it-play-out Simulation Phase directly expresses `02` "SEED's Culture, and the Player's Role": the Herald "operates at the level of planning and direction, not direct control," and "the settlement's own settlers and drone-intelligences carry out the plan autonomously." The fixed real-time season window ("a season corresponds to a fixed length of real time in the story-world") reinforces the Herald receiving compressed telemetry over the FTL trace rather than living the season. Strong fit.
- **Transmissions vs. log split is lore-consistent.** `02` frames Transmissions as "a report the player-character is filing, not neutral narrator text"; the mechanical log has no such voice. Keeping them separate (`03`) matches the fiction.
- **Missed reinforcement (→ NTH4).** The "no minimum wall-clock floor" fast-playback tradeoff — rushing a season, missing the visuals — has no in-fiction voice. It could be framed as the Herald choosing to skim incoming telemetry rather than review it in full.
- **No unit conflict.** `01` "Units are unspecified" explicitly exempts "simulation playback timestamps in seconds"; showing "30s" / "2.3×" is consistent.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *UI interaction is minimal* — simulation requires no interaction; the log is opt-in (no forced overlay); sticky playback speed means most seasons need zero speed input.
- *Planning phase is reversible* — Planning Lock-in is a single, clean, well-defined commit boundary.
- *No purely ambient, untriggered randomness should end a run* — hazard events are telegraphed via Transmissions and reuse the scored hidden draw rather than a fresh ambient roll; the loop's role (Mid-Sim hosts the event) is consistent.
- *Colour is never the sole channel* — the farm-variant overlay pairs phase colour with an icon badge.

**Risks / violations:**
- **P1 (→ SF7). Colour is never the sole channel — the log.** `03` "Season Structure" doesn't say how gain / loss / death / noteworthy lines are differentiated. If it is text colour alone, it violates `01`.
- **P2 (→ SF8). Failure should always be legible — fast playback.** At 5× a player can miss a death, a destruction, and a hazard entirely, relying on the log. Acceptable only if the log is complete *and* meets "luck must be distinguishable from certainty" retrospectively (a destroyed-building line must say whether preparedness was near-zero (guaranteed) vs. an unlucky extreme-storm side-roll). Not currently specified.
- **P3. Numbers stay small / units unspecified** — playback multiplier display ("2.3×") and second-based timestamps are fine; noted as checked.
- **P4. Design docs describe the current design, not its history** — pervasive in "Season Structure" (IC4). (→ NTH2.)
- **Dexterity-timing / accessibility** — a 0×–5× slider at 0.1 snap is 50 stops on a small target; `01` "dexterity-timing thresholds" is about gesture *timing*, so not strictly engaged, but snap granularity and hit-target ergonomics belong in the UX pass. (→ D5.)

---

## 7. Player legibility

- **The three resolution moments are invisible infrastructure** — the player experiences "confirm → watch → see outcomes," which is intended. But the Post-Sim *order* has a player-visible consequence (survival reserves a contested resource before a Trade Agreement is paid) that the player can only infer; whether a log/Transmission line ever surfaces it is unaddressed. (→ SF, NTH7.)
- **Aggregated "+N Grain" lines** read totals well but hide which site underperformed (deliberate — that's the per-site overlay's job). The overlay-diagnoses / log-reads-totals division is stated in `03` but has no in-game signposting. (→ NTH5.)
- **Post-Sim outcomes have only ambient Mid-Sim visuals.** A survey settler "searching" is decorative; the reveal pops at Post-Sim. Risk that the player reads the ambient depiction as the resolution. (→ NTH6.)
- **"Nothing revealed at Planning Lock-in"** is good — projected outcomes aren't shown as if real, consistent with `01` reversibility.

---

## 8. Fun / scope risk

- **The Post-Sim sub-step order is precise machinery serving edge cases** (contested resources; construction dependencies). Appropriate rigour for a resolver, not over-design — but every future system that resolves at Post-Sim adds a step and a dependency question. Worth a standing checklist item ("where does it resolve, what does it depend on") for every later system. Keep.
- **Two "what's happening" channels (overlay + log)** serve different tempos (moment-to-moment vs. retrospective) — deliberate and good. Keep. Transmissions is a justified third channel; that is the ceiling — resist a fourth.
- **Playback slider (50 stops)** is more than anyone needs; the design's own rationale is "continuous-feeling." A coarser snap (0.25/0.5) would lose nothing. (→ D2.)

---

## 9. Findings summary

### Blockers

- **B1.** Season 1's entry state is unspecified — no Post-Sim precedes the first planning phase, and what seeds it (starting grid/inventory, run-start SEED summary transmission, whether Season 1 has a normal Planning Lock-in) is only partly in `DESIGN_TODO.md` "Run-start flow" and unreconciled with the loop skeleton. (§2 G-S1 — `03` "Season Structure"; `06` "In-Simulation Hazard Events"; `DESIGN_TODO.md` "Run-start flow")
- **B2.** No Post-Sim sub-step applies the season's accumulated production to inventory, yet (3) nutrition, (3.5) Trade Agreement expense, and construction-cost accounting all read inventory — the moment production output becomes available is undefined. (§2 G-S2 — `03` "Season Structure")
- **B3.** Mid-Sim's process list names only continuous production and discrete hazard events; it omits Energy/Water live-rate recomputation + random shedding and the plant-crop Water-draw FIFO queue, all per-tick Mid-Sim processes defined in `04`. (§2 G-S3 — `03` "Season Structure" vs `04` "Resources" / "Farm/Production")

### Should-fix

- **SF1.** Reword Post-Sim "instantaneous" → "no simulation clock runs," since it hosts an interactive dialog and step (6) follows it. (§3 IC1 — `03` "Season Structure")
- **SF2.** Specify intra-step-(4) ordering of construction completions (relocations before dependent builds/upgrades). Same as Audit 1 SF1, owned here. (§3 IC3 — `03` "Season Structure" vs "Construction")
- **SF3.** Split Post-Sim into "immediate (steps 1–4)" and "next-planning-phase preamble (steps 5–6)," which are separated by a player interaction and the season boundary. (§4 CS1 — `03` "Season Structure")
- **SF4.** Reconcile hazard-warning lead time ("a season or two ahead") with when the triggering hidden draw is rolled — the loop has no forecast/look-ahead mechanism. (§4 CS2 — `03` "Season Structure" vs `06` "In-Simulation Hazard Events")
- **SF5.** Fix the Mid-Sim log-line list: vaccine unlocks, Deposit Discovery reveals, and exploration escalations resolve at Post-Sim, not Mid-Sim — separate "occurs in Mid-Sim" from "revealed at Post-Sim." (§4 CS3 — `03` "Season Structure")
- **SF6.** State that the previous season's Post-Sim outcomes are final and not reversible in the next planning phase — only new planning choices are. (§4 CS4 — `03` "Season Structure" vs `01` "Planning phase is reversible")
- **SF7.** Specify a redundant non-colour cue for log line types (gain / loss / death / noteworthy), per `01` "colour is never the sole channel". (§6 P1 — `03` "Season Structure")
- **SF8.** Require event log lines to carry enough detail for `01`'s "luck must be distinguishable from certainty" retrospectively (e.g. building-destroyed: near-zero preparedness vs. unlucky extreme-storm side-roll), since fast playback makes the log the only record. (§6 P2 — `03` "Season Structure"; `01` "Failure should always be legible")

### Nice-to-have

- **NTH1.** Renumber the Post-Sim sub-steps 1–7 (drop the "3.5"). (§3 IC2)
- **NTH2.** Fold the process narration out of "Season Structure" once the redesign settles, per `01` "describe the current design, not its history". (§3 IC4, §6 P4)
- **NTH3.** State explicitly whether Post-Sim counts as "simulation" (passive) — it hosts the Exploration and Trade Agreement dialogs. (§3 IC1, §2 — `03` "Simulation Phase" / "Season Structure")
- **NTH4.** Give the "no minimum wall-clock floor" fast-playback tradeoff an in-fiction frame (the Herald skimming incoming telemetry). (§5)
- **NTH5.** Signpost the overlay-diagnoses-per-site / log-reads-totals division so players learn it. (§7)
- **NTH6.** Note the risk that a decoupled ambient Mid-Sim visual (survey settler "searching") reads as resolution rather than decoration; consider a rule distinguishing mechanically-real from decorative Mid-Sim visuals. (§7 — `07` "Art Design")
- **NTH7.** Consider whether the player can learn the Post-Sim resolution order's visible consequence (survival reserves a contested resource before trade) through a log/Transmission line. (§7)

### Defer (numeric / UX-pass)

- **D1.** 30s Mid-Sim window at 1× — tune in playtest. `03` "Season Structure".
- **D2.** Playback ceiling (5×) and 0.1 snap — consider a coarser snap. `03` "Season Structure".
- **D3.** Log interleave order when a production line and an event line share a timestamp. `03` "Season Structure".
- **D4.** Calibration constants tying `production_time` and event rates to the 30s window. `03` "Season Structure".
- **D5.** Playback-slider hit-target / snap ergonomics — Art/UX pass. `03` "Season Structure"; `01` accessibility principles.
