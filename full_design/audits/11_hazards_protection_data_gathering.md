# Audit — System 11: Hazards, Protection & Data-Gathering

Pure design review against `full_design/`; no implementation exists. Citations
are `file` → "Section" (no anchor links: this file sits in `audits/` and the
repo link-checker only scans `full_design/*.md`).

**Single file, not split.** A split into `11a` (events/data-gathering) and
`11b` (protection buildings) was considered and rejected: the energy-funded
Temperature-Extremity model, `MatchedPreparedness`, the Vaccine-Production
gate, and the mid-Mid-Sim building-destruction chains each span both halves,
and the system's through-line is one argument — hidden values → telegraphing →
consequence → protection.

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Hazard Priors — `TrueRisk(Weather)` = arithmetic mean of Storm Severity/Frequency, Temperature Extremity, Atmospheric Hazard; `TrueRisk(Bio-hazard)` = mean of Pathogen Threat, Toxic/Parasitic Organism Threat; each a probability the danger is insurmountable; per-planet-type table | `06` "Hazard Priors" |
| Hidden Beta(a,b) per sub-factor (5 sub-factors, 10 counters); prior mean matches the table, small `a₀+b₀`; each report ±1 to `a` or `b` | `06` "Data-Gathering Mechanism" |
| `MatchedRisk(hazard) = a/(a+b)` (Beta posterior mean) | `06` "Data-Gathering Mechanism" |
| `Confidence(hazard) = ν/(ν+k)`, `ν = a+b`; deliberately evidence-count-based, not variance-based; `Data(hazard)` **is** `Confidence(hazard)` | `06` "Data-Gathering Mechanism" |
| Per-sub-factor data sources / success-failure definitions / player-facing report strings; reports as short log entries | `06` "Data-Gathering Mechanism" table |
| Same mechanism reused in simplified (count-only) form for Stewardship's `EcologicalData` | `06` "Data-Gathering Mechanism"; `06` "SEED Factions" |
| In-sim hazard event trigger = the same hidden Bernoulli draw that generates a report ("a storm report and a storm actually happening are the same event") | `06` "In-Simulation Hazard Events" — Trigger |
| Only Storm and Temperature Extremity manifest as discrete Mid-Sim events; Atmospheric Hazard is a continuous check; Bio-hazard resolves only via exploration encounters | `06` "In-Simulation Hazard Events" — Concurrency |
| Each of Storm / Temperature Extremity fires ≤1×/season, tied to that season's single evidence report; ceiling of 2 discrete events/season; overlapping windows stack consequences independently; no double-destroy | `06` "In-Simulation Hazard Events" — Concurrency |
| Severity band (mild / extreme) rolled per triggered event, weighted by `TrueRisk`; shared framing for Storm and Temperature Extremity | `06` "In-Simulation Hazard Events" — Event severity |
| Telegraphing scales continuously with `Confidence`: near-zero → one-time run-start SEED summary of planet-type priors, no per-season warning; low-moderate → vague short-lead warnings; high → precise longer-lead warnings; all via Transmissions | `06` "In-Simulation Hazard Events" — Telegraphing; `02` "Gameplay-Story Integration" |
| Per-site Average Temperature sampled at world-gen from a `TrueRisk(Temp)`-parameterised distribution; shown at Farm Site Selection; universal 72°F comfort target (settings-toggle °F/°C) | `06` "In-Simulation Hazard Events" — Temperature Extremity; `01` "Units are unspecified" |
| Temperature Extremity production consequence: Energy-funded shield coverage (banded upkeep) → fully maintains comfort; else mild → slowed / extreme → stopped, for the event's duration, always temporary, never destroys | `06` "In-Simulation Hazard Events" — Temperature Extremity |
| Temperature Extremity settler consequence (one shared severity roll): mild → dynamic slowing `status_effect` (present only while at an unprotected site AND in-sim temp outside 72°F); extreme → death-probability roll (chance TBD) | `06` "In-Simulation Hazard Events" — Temperature Extremity |
| Temperature-Resistant Gear: passive stock check covering all farm-based settlers (not crops) against Temperature Extremity | `06` "In-Simulation Hazard Events"; `04` "Tinkerer's Workshop" |
| Storm consequence tiers: adequately covered → no effect; under-covered → paused; severely under-covered (`MatchedPreparedness` near zero) → affected outdoor Farm/Production site destroyed (grid slot emptied, robot rebuild needed) | `06` "In-Simulation Hazard Events" — Storm |
| Extreme-severity Storm: every *other* unprotected building (any category) independently rolls a small destruction chance (TBD) | `06` "In-Simulation Hazard Events" — Storm |
| Atmospheric Hazard: settler-level only; farm settlers covered by passive PPE stock check; exploration settlers must elect to send PPE (consumed); exposure without PPE → halving `status_effect` (0.5 effort) that also locks out exploration assignment | `06` "In-Simulation Hazard Events" — Atmospheric Hazard; `04` "Medical Bay" — PPE recipe |
| Indoor buildings shield their worker from Atmospheric Hazard and Temperature Extremity **for free while powered**; unpowered Indoor = treated as Outdoor; destroyed mid-Mid-Sim → worker freed, protection lost instantly | `04` "Building Schema" — Indoor or Outdoor |
| Weather Shield — unstaffed; Manhattan-radius AOE (illustrative 2) over any building type; variable event-driven Energy upkeep (idle-armed → mild → extreme banded); Weather-axis Preparedness contribution scaling with tier; upgrade = larger radius + more Preparedness; **no data-gating** on Preparedness | `04` "Weather Shield"; `04` "Baseline Energy upkeep" |
| Row Shield — unstaffed; fixed 2-tile non-rotatable footprint for coverage *shape*; full-row linear AOE; no upgrade path; same event-driven upkeep; Weather-axis Preparedness = Weather Shield base shape | `04` "Row Shield" |
| Medical Bay — staffed; base tier baseline `Preparedness(Bio-hazard)` (illustrative 0.2); ordinary flat Energy baseline (not the shield exception); recurring PPE and Emergency Medical Kit recipes (no `Confidence`-gating) | `04` "Medical Bay" |
| Vaccine Production tier — gated by a `Confidence(Bio-hazard)` threshold (illustrative 0.5); higher Preparedness (illustrative 0.7); a permanent one-time settlement-wide fact surviving Medical Bay destruction; triggers a new exploration escalation (region reveal) | `04` "Medical Bay" — Vaccine Production tier; `05` "Escalation Chains" |
| `MatchedPreparedness(hazard) = min(Preparedness / TrueRisk, 1)`; Preparedness contributions on a 0–1 scale | `06` "SEED Factions" — Safeguard; `04` "Protection" |
| `Score(hazard) = Data(hazard) + MatchedRisk(hazard) × MatchedPreparedness(hazard)`; total Safeguard = an undecided combination of `Score(Weather)` and `Score(Bio-hazard)` | `06` "SEED Factions" — Safeguard Coalition |
| Building Schema conditional properties this system uses: Area of effect, Energy upkeep, Preparedness contribution, Data-gathering contribution | `04` "Building Schema" — Conditional properties |

**Boundary notes (ambiguous ownership).**
- **Bio-hazard** has no in-sim event; its gameplay is the Vaccine-Production
  `Confidence` gate + a vaccine-unlock escalation task — both mostly live in
  Exploration (System 10) and Scoring. This audit treats Bio-hazard as *data
  plumbing + a building gate*, not a co-equal hazard axis (see §8 F2).
- **Energy-funded Temperature Extremity** — the banded shield upkeep and the
  random-shedding interaction belong to System 5 (Energy); this audit covers
  only the hazard-side coupling.
- **Storm site destruction** hands slot-state / `DisruptionFootprint` to
  System 1, mid-sim worker return to System 3, exposure to System 9.
- **The run-start SEED summary** sits inside System 12's run-start sequence
  (already flagged in `DESIGN_TODO.md` "Run-start flow").
- **PPE / Temperature-Resistant Gear / Emergency Medical Kit** as fabricated
  items belong to System 7; this audit covers only their protective function.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. The per-season hazard draw's dependence on a data source is contradictory.** `06` "In-Simulation Hazard Events" — Trigger says the report and the event "are the same draw, not two separate rolls"; the report source is a *staffed* Scanner Station in Weather Sensing mode ("one reading/season active") or an exploration task. But the Telegraphing section's near-zero-confidence bullet says "Events at this stage happen with no specific advance notice" — i.e. before any surveying. Read literally, no data source ⇒ no report ⇒ no draw ⇒ no event, which contradicts that. *Possible direction: state that the Bernoulli draw fires unconditionally every season at `P = TrueRisk(sub-factor)` and determines whether the event occurs; a data source present that season converts that same draw into a visible report and a `±1` counter update; absent one, the event still occurs, unshown and uncounted.*
- **G-S2. Sub-factor → hazard-axis aggregation is undefined for `Data` and `MatchedRisk`.** `06` "Hazard Priors" defines `TrueRisk(Weather)` as the arithmetic mean of its three sub-factors, but `Score(Weather)` needs `Data(Weather)` and `MatchedRisk(Weather)` and no rule says how the per-sub-factor `Confidence` / `a,b` combine to the axis level. (`06` "Data-Gathering Mechanism" is entirely per-sub-factor; `06` "SEED Factions" is entirely per-axis.)
- **G-S3. Storm's targeted-site consequence ignores the severity band.** `06` "In-Simulation Hazard Events" — Storm gives only coverage-tier outcomes (no effect / paused / destroyed); "Event severity" introduces mild/extreme as *shared* with Temperature Extremity and central to its consequence. As written a *mild* storm destroys an unshielded outdoor farm exactly as an *extreme* one does. *Possible direction: gate the destroyed tier on extreme severity; mild severely-under-covered → paused or damaged.*
- **G-S4. The `adequately covered` vs. `under-covered` Storm boundary is undefined.** Only `severely under-covered = MatchedPreparedness near zero → destroyed` is pinned; nothing says what `MatchedPreparedness` value separates "no effect" from "paused", nor whether the boundary is a fixed constant or planet-relative. This is the core consequence of the more destructive event.
- **G-S5. Vaccine-Production gate granularity is ambiguous.** `04` "Medical Bay" says both `Confidence(Bio-hazard)` (axis level) and "pathogen-specific… targeted to the pathogen a specific bio-survey exploration task discovered" (per-pathogen). Whether the gate is axis-level / sub-factor-level (`Confidence(Pathogen Threat)`) / per-discovered-pathogen, and how many distinct pathogens a run can have, is unspecified.
- **G-S6. Atmospheric Hazard's exposure trigger is undefined.** `06` "In-Simulation Hazard Events" — Concurrency calls it "a continuous passive-stock/PPE check with no start/duration event", yet the Atmospheric Hazard subsection says the `status_effect` "triggers on exposure" and persists "roughly 3 seconds of Mid-Sim time afterward" — implying a discrete exposure moment with no stated cause, frequency, or `TrueRisk` weighting.
- **G-S7. Event timing and duration within the 30s Mid-Sim window is unmodelled.** Consequences are repeatedly scoped "for the event's duration"; nothing says when in the window an event starts or how long it runs, or whether duration varies with severity. Mid-Sim cannot be run without this.
- **G-S8. "Medical/Research facility" as a passive per-season Pathogen data source is unspecified.** The `06` "Data-Gathering Mechanism" table lists it alongside the bio-survey exploration task, but neither `04` "Medical Bay" nor `04` "Research Lab" defines a passive report (rate, staffing requirement, whether it needs a discovered pathogen first).

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** `k` confidence constant — one global value or per-sub-factor. `06` "Data-Gathering Mechanism".
- **G-N2.** Severity-band weighting `P(extreme | event) = f(TrueRisk)`. `06` "Event severity".
- **G-N3.** Temperature Extremity extreme-exposure settler death probability (also `DESIGN_TODO.md`). `06` "Temperature Extremity".
- **G-N4.** Extreme-Storm per-building collateral destruction chance. `06` "Storm".
- **G-N5.** Vaccine `Confidence` threshold (illustrative 0.5); Preparedness contributions (0.2 / 0.3 / 0.6 / 0.7 illustrative); Weather Shield AOE radius (illustrative 2). `04` "Protection"; `06` "SEED Factions".
- **G-N6.** `Score(Weather)` + `Score(Bio-hazard)` combination (sum / average / weighted) undecided (also `DESIGN_TODO.md`). `06` "SEED Factions".
- **G-N7.** Atmospheric Hazard `status_effect` duration ("roughly 3 seconds"). `06` "In-Simulation Hazard Events".

### Cross-check with `DESIGN_TODO.md`

Currently flags, touching this system: the Temperature Extremity death-probability
TBD (= G-N3), the `Score(Weather)`+`Score(Bio-hazard)` combination (= G-N6),
"Livestock vaccines" (out of scope — a back-burner idea), and "Run-start flow"
(covers CS5). It does **not** flag G-S1 (unconditional draw), G-S2 (axis
aggregation), G-S3/G-S4 (Storm severity & thresholds), G-S6 (Atmospheric
trigger), or G-S7 (event timing). Recommend adding those.

---

## 3. Internal consistency

- **IC1. Two descriptions of `MatchedRisk`.** `06` "SEED Factions" — Safeguard: "computed directly from Bayes' theorem using a prior based on planet type updated by `Data(hazard)`". `06` "Data-Gathering Mechanism": `a/(a+b)`, updated by individual success/failure reports, with `Data` = `Confidence` (a *separate* quantity). The Safeguard phrasing reads as a superseded formulation and conflates `Data` with the update mechanism.
- **IC2. Shield energy behaviour during a Storm is unstated.** `04` "Baseline Energy upkeep" and `04` "Weather Shield" tie the elevated shield upkeep to "an active *Temperature Extremity* event". Storm consequences run on coverage tiers, not Energy funding — so during a Storm the shield's Energy draw is presumably just its idle-armed baseline, but this is never said.
- **IC3. The concurrency "destroyed twice" edge case cannot occur as written.** `06` "In-Simulation Hazard Events" — Concurrency describes one hazard's destruction check no-opping because the other already emptied the slot. But only Storm destroys, and ≤1 Storm fires per season, so there is never a second destroyer.
- **IC4. Report channel unresolved.** `06` "Data-Gathering Mechanism": reports "fit the Transmissions record *or* simulation log". The two channels differ in persistence and the design elsewhere keeps them strictly separate (`03` "Season Structure" — log/event-feed; Transmissions "stays fully separate").
- **IC5. Atmospheric Hazard effect — `status_effect` vs. Injury, and duration wording.** `06` main text: "persists for roughly 3 seconds… halves… effectiveness". `06` PPE cross-summary and `04` "Medical Bay": "fixed duration". `05` "Settler State" lists Atmospheric Hazard as a `status_effect` entry but `05` "Injuries" (the shared harm taxonomy) doesn't mention it. Confirm classification and align the duration wording.

---

## 4. Cross-system consistency

- **CS1. Telegraph lead time < construction lead time.** `06` low-to-moderate-confidence warnings appear "right before the affected season's planning phase", but a Weather Shield / Medical Bay built in response costs a construction-robot action and is operational only the *following* season (`03` "Construction"). Same-season warnings are not actionable for any construction-based response. (Mirrors the pilot's B1.)
- **CS2. Random Energy shedding → settler-death pathway.** An Indoor building randomly shed during an extreme Temperature Extremity event becomes "treated as Outdoor" (`04` "Building Schema" — Indoor/Outdoor), exposing its worker to the extreme-event death roll. The shed selection is deliberately non-player-controllable (`04` "Resources" — random shedding), so this is a settler death from ambient randomness stacked on a hidden event. Tension with §6 P1.
- **CS3. Weather Shield over-credits the Weather axis / Atmospheric preparedness is unscored.** Weather Shield's Preparedness contribution is "Weather axis" (`04` "Weather Shield"), i.e. it feeds `MatchedPreparedness(Weather)` for all three sub-factors — but Atmospheric Hazard is mitigated only by PPE, which is an item with no Building-Schema Preparedness contribution. So the score credits "Weather preparedness" while a third of the axis has no scoring representation.
- **CS4. Data-gathering exploration tasks are referenced but not clearly authored.** `06` "Data-Gathering Mechanism" makes bio-survey / atmospheric sampling / weather balloon / dedicated probe the sole data source for Atmospheric Hazard and both Bio sub-factors, but `05` "Task Catalog" does not list them as named recurring tasks (only Weather Anomaly Investigation / Aurora Readings give `Confidence(Weather)` bursts).
- **CS5. Run-start SEED summary placement** is an open cross-dependency with System 12 (`DESIGN_TODO.md` "Run-start flow" already flags "where the one-time SEED summary transmission actually lands").
- **CS6. Mid-Mid-Sim building destruction has no reconciled sequence.** Storm destruction frees the worker and the slot (System 1 slot-state + `DisruptionFootprint`; System 3 worker returns to the roster mid-sim) and, for an Indoor building, strips the worker's protection at that instant (System 9 exposure). Each system states its own rule; none states the ordering for a single mid-sim destruction event.
- **CS7. The intended in-season response to a same-season warning is unstated.** Non-construction responses *are* available — building active/inactive toggle, reassigning workers off outdoor sites, deploying already-stocked PPE / Temperature-Resistant Gear — but the design never says what a low-confidence warning is *for*, given CS1 rules out builds.
- **CS8. Coverage is computed against hidden `TrueRisk`.** `MatchedPreparedness = min(Preparedness/TrueRisk, 1)` and the Storm tiers ("sufficient `Preparedness` relative to the hazard") both use the hidden true value, so "am I adequately shielded" is only ever a player estimate via `MatchedRisk`. The preparedness UI must present coverage as a prediction-with-confidence — the pattern `03` "Site Panel (UI)" already commits to for power — but no design text says so.

---

## 5. Story & world consistency

- **Positive / reinforcing.** The telegraphing mechanism is the explicit realization of `02` "Gameplay-Story Integration"'s pre-committed design — Transmissions carrying "diegetically-framed game hints and advance warnings of planet-side hazards (e.g. incoming weather)" and resolving the "no purely ambient, untriggered randomness should end a run" principle. Clean fit; the run-start SEED summary as "SEED's institutional knowledge about planet-type archetypes from prior missions" matches the worldbuilding (planet *types* are known, specific planets are not).
- **ST2. Raw prior numbers vs. hidden-math goal.** `06` says the run-start summary surfaces "the actual Bayesian prior numbers or a close translation". Showing a bare `0.53` tensions with both the Data-Gathering "hidden from the player / never involves… visible math" goal and `01` "Units are unspecified". Prefer the "close translation" path explicitly.
- **ST3. Missed reinforcement.** A hazard-caused settler death should route through `02` "Settler story presence"'s existing "single acknowledgment line in the log/report on death", not a bare mechanical line. Confirm the shared death path is reused (the design already says Temperature Extremity death uses "the same roster-removal mechanic used everywhere else").
- No lore conflict in the core mechanics.

---

## 6. Design-principle adherence

**Adherent — record as deliberate strengths:**
- *Numbers stay small / minimal machinery* — ten integer counters, no distribution objects, `Confidence` on evidence count not variance (with a stated legibility rationale), one hidden draw reused for report + event, continuous `Confidence`-scaled telegraphing instead of a building-gated tier ladder.
- *Difficulty from breadth of tradeoffs* — the A↔D coupling via energy-funded shield upkeep, and Weather Shield vs. Row Shield as genuinely different coverage shapes rather than a strict upgrade.

**Risks / violations:**
- **P1 (→ SF11). "No purely ambient, untriggered randomness should end a run" / "forgiving of individual mistakes."** Extreme-Storm site destruction (→ possible total farm destruction, a critical-failure condition per `06` "Win / Lose Conditions") and extreme-Temperature-Extremity settler death both fire from hidden draws; at near-zero `Confidence` the only telegraph is the generic planet-type summary. Defensible only if that summary genuinely makes "don't run unshielded outdoor sites on a high-prior planet" inferable — which needs to be an explicit design claim, and possibly a `Confidence` floor or early-season grace on the destructive/lethal tiers.
- **P2 (→ SF12). "Failure should always be legible" / "luck must be distinguishable from certainty."** Targeted-site Storm destruction is deterministic given coverage state; collateral destruction and the Temp-Extremity death roll are genuine rolls. The post-event log must say which, and must surface the coverage state that made a destruction a certainty.
- **P3 (→ NTH6). "Colour is never the sole channel."** The preparedness / shield-coverage readouts this system relies on need a shape/icon channel; the `03` Site Panel power indicator commits to this, the Weather/Bio preparedness readouts do not.
- **P4 (→ SF13). "Normalize before combining unrelated values."** `Score(hazard) = Data + MatchedRisk × MatchedPreparedness`. The design argues both terms are [0,1] so no normalization is needed — but `Data` (`ν/(ν+k)`, saturating toward 1) and `MatchedRisk × MatchedPreparedness` (two probabilities multiplied, biased small) have very different practical ranges, so the unweighted sum lets `Data` dominate. Needs an explicit weighting decision.
- **P5 (→ NTH7). "Design docs describe the current design, not its history."** IC1's stale `MatchedRisk` bullet, and "same shape as before" / "already meant destruction under the hood; it's stated explicitly now" in the Storm section, are change-log narration.

---

## 7. Player legibility

- **L1 (→ CS8, P2).** Every consequence-determining value is hidden (`TrueRisk`, the event draw, the severity weighting). The player's only instruments are the `Confidence`-scaled telegraphs and the inspectable Planetary Assessment panel — which shows `MatchedRisk`, not `TrueRisk`. The panel must present preparedness/coverage as an estimate-with-confidence; unspecified.
- **L2 (→ SF15).** "Protected" means three different things for a shield: binary in-AOE coverage (collateral-storm immunity, Temperature-Extremity comfort-funding eligibility), Preparedness *magnitude* vs. `TrueRisk` (Storm targeted-site tier), and static score credit. These need distinct UI language.
- **L3 (→ NTH8).** The Temperature-Extremity mild `status_effect` is "fully dynamic" — flickering in and out with the fluctuating in-sim temperature. Legible signal or Mid-Sim noise is untested.
- Next-season resolution of a Vaccine unlock, and the deterministic "you were unprepared" storm outcome, are otherwise learn-once-transfers.

---

## 8. Fun / scope risk

- **F1.** Largest single system by hidden-state surface — a Bayesian layer, `TrueRisk`, severity weighting, and the event draw are all invisible; legibility rests entirely on the telegraphing + assessment panel carrying that load (L1).
- **F2.** Bio-hazard has zero in-sim event presence. Its gameplay is a `Confidence`-gated vaccine unlock plus an escalation task, both of which live in Exploration/Scoring. Consider scoping this system's Bio-hazard content down to "data plumbing feeding Scoring/Exploration" rather than a co-equal hazard axis — it would roughly halve the nominal surface here.
- **F3.** Weather Shield carries three distinct mechanics (static Preparedness credit, Storm coverage-tier magnitude, energy-funded real-time Temperature-Extremity comfort). Combined with random Energy shedding (CS2) this is a high complexity-to-legibility ratio on one building.
- **F4 (→ NTH9).** "Severity band shared by Storm and Temperature Extremity" over-promises unification — central to Temperature Extremity's consequence, marginal to Storm's (G-S3).
- **F5.** Narrowing risk: if the `adequately/under` Storm threshold (G-S4) lands such that Preparedness *magnitude* rarely matters, the dominant line collapses to "one cheap in-AOE shield for binary collateral coverage + one Temperature-Resistant Gear, eat the Safeguard score hit." Flag for the balance pass to check actively.

---

## 9. Findings summary

### Blockers

- **B1.** The per-season hazard draw's dependence on a data source is contradictory — "the report and the event are the same draw" vs. events firing at near-zero confidence before any surveying; must state the draw fires unconditionally at `P = TrueRisk` and a data source only converts it to a visible/counted report. (§2 G-S1 — `06` "In-Simulation Hazard Events" — Trigger vs. Telegraphing)
- **B2.** Sub-factor → hazard-axis aggregation for `Data` and `MatchedRisk` is undefined — `Score(Weather)` / `Score(Bio-hazard)` need axis-level values but the mechanism is entirely per-sub-factor and only `TrueRisk` has a stated aggregation. (§2 G-S2 — `06` "Data-Gathering Mechanism" vs "SEED Factions")
- **B3.** The `adequately covered` vs. `under-covered` Storm boundary is undefined — only `severely under-covered → destroyed` is pinned; the no-effect/paused threshold and its basis are unspecified. (§2 G-S4 — `06` "In-Simulation Hazard Events" — Storm)
- **B4.** Vaccine-Production gate granularity is ambiguous — axis-level `Confidence(Bio-hazard)` vs. per-discovered-pathogen; number of distinct pathogens per run undefined. (§2 G-S5 — `04` "Medical Bay" — Vaccine Production tier; `06` "Data-Gathering Mechanism")
- **B5.** Atmospheric Hazard's exposure trigger is undefined — called a "continuous… check with no… event" yet the status effect "triggers on exposure" with a post-exposure duration; no cause, frequency, or weighting given. (§2 G-S6 — `06` "In-Simulation Hazard Events" — Atmospheric Hazard)
- **B6.** Event timing and duration within the 30s Mid-Sim window is unmodelled — consequences are scoped "for the event's duration" with no rule for start time or length. (§2 G-S7 — `06` "In-Simulation Hazard Events"; `03` "Season Structure" — Mid-Sim)

### Should-fix

- **SF1.** Storm's targeted-site consequence ignores the severity band — a mild storm destroys an unshielded farm as readily as an extreme one; gate the destroyed tier on extreme severity. (§2 G-S3 — `06` "In-Simulation Hazard Events" — Storm vs. Event severity)
- **SF2.** "Medical/Research facility" as a passive per-season Pathogen data source is listed in the Data-Gathering table but unspecified in the `04` "Medical Bay" / "Research Lab" sections (rate, staffing, prerequisite). (§2 G-S8)
- **SF3.** Reconcile the two `MatchedRisk` descriptions — the `06` "SEED Factions" Bayes-theorem phrasing reads as superseded by the Beta-counter model and conflates `Data` with the update. (§3 IC1 / §6 P5 — `06` "SEED Factions" vs "Data-Gathering Mechanism")
- **SF4.** State the shield's Energy behaviour during a Storm (idle-armed baseline only?) — the event-driven upkeep is defined only against Temperature Extremity. (§3 IC2 — `04` "Weather Shield" / "Baseline Energy upkeep"; `06` "Storm")
- **SF5.** Resolve which channel hazard reports use — Transmissions vs. the per-season simulation log — given the design keeps the two strictly separate. (§3 IC4 — `06` "Data-Gathering Mechanism"; `03` "Season Structure")
- **SF6.** Telegraph lead time must be ≥ construction lead time for warnings to be actionable, or shields must be exempt from next-season construction delay, or the design must state that prophylactic pre-building from priors is the intended response. (§4 CS1 — `06` "Telegraphing"; `03` "Construction")
- **SF7.** Address the random-shed → Indoor-worker-exposure → extreme-event death-roll chain — a settler death from non-player-controllable randomness stacked on a hidden event. (§4 CS2 / §6 P1 — `04` "Building Schema" — Indoor/Outdoor; `04` "Resources" — random shedding; `06` "Temperature Extremity")
- **SF8.** Atmospheric Hazard preparedness has no scoring representation while Weather Shield's Preparedness credit spans the whole Weather axis — decide whether PPE stock feeds `MatchedPreparedness(Weather)` or Weather Shield's contribution is sub-factor-scoped. (§4 CS3 — `04` "Weather Shield"; `06` "SEED Factions"; `06` "Data-Gathering Mechanism")
- **SF9.** Author the recurring data-gathering exploration tasks (bio-survey, atmospheric sampling, weather balloon, dedicated probe) that this system names as the sole data source for 3 of 5 sub-factors. (§4 CS4 — `06` "Data-Gathering Mechanism"; `05` "Task Catalog")
- **SF10.** Specify that the preparedness / shield-coverage UI presents coverage as a prediction-with-confidence (computed vs. hidden `TrueRisk`, estimable only via `MatchedRisk`), mirroring the Site Panel power indicator. (§4 CS8 / §7 L1 — `06` "SEED Factions" — MatchedPreparedness; `03` "Site Panel (UI)")
- **SF11.** Make explicit that the run-start SEED summary is the sole "failure legibility" instrument for the entire pre-`Confidence` period, and decide whether the destructive/lethal event tiers get a `Confidence` floor or early-season grace. (§6 P1 — `01` "Forgiving of individual mistakes"; `06` "In-Simulation Hazard Events")
- **SF12.** The post-event log must distinguish deterministic-given-coverage destruction from an unlucky collateral/death roll, and surface the coverage state that made a destruction certain. (§6 P2 — `01` "Failure should always be legible"; `06` "Storm"; `03` "Season Structure" — log)
- **SF13.** Decide term weighting in `Score(hazard) = Data + MatchedRisk × MatchedPreparedness` — `Data` saturates toward 1 while the product term is biased small, so the unweighted sum lets data-gathering dominate. (§6 P4 — `01` "Normalize before combining unrelated values"; `06` "SEED Factions")
- **SF14.** Reconcile mid-Mid-Sim building destruction into one ordered sequence across slot-state/`DisruptionFootprint` (System 1), mid-sim worker return (System 3), and protection loss/exposure (System 9). (§4 CS6 — `06` "Storm"; `04` "Building Schema" — Indoor/Outdoor; `03` "Construction")
- **SF15.** Give "protected" distinct UI language for its three shield meanings — binary AOE coverage, Preparedness magnitude vs. `TrueRisk`, and static score credit. (§7 L2 — `06` "In-Simulation Hazard Events"; `04` "Protection")
- **SF16.** Confirm hazard-caused settler death routes through the existing death-acknowledgment line rather than a bare mechanical entry. (§5 ST3 — `06` "Temperature Extremity"; `02` "Settler story presence")

### Nice-to-have

- **NTH1.** Trim the concurrency "destroyed twice" edge case — it cannot occur, since only Storm destroys and ≤1 Storm fires per season. (§3 IC3)
- **NTH2.** Confirm the Atmospheric Hazard effect is a `status_effect` entry (not an Injury) and align the "roughly 3 seconds" vs. "fixed duration" wording across the three places it appears. (§3 IC5)
- **NTH3.** Cross-link the run-start SEED summary's sequencing to `DESIGN_TODO.md` "Run-start flow" (System 12). (§4 CS5)
- **NTH4.** State the intended in-season response to a low-confidence same-season warning (toggles, worker reassignment, deploying stocked gear). (§4 CS7)
- **NTH5.** Prefer the "close translation" over raw Bayesian prior numbers in the run-start SEED summary, per the hidden-math goal and "units are unspecified". (§5 ST2)
- **NTH6.** Record the colour-not-sole-channel requirement for the preparedness / shield-coverage indicators. (§6 P3)
- **NTH7.** Fold change-log narration ("same shape as before", "already meant destruction under the hood") out of the Storm / Safeguard subsections. (§6 P5)
- **NTH8.** Watch the dynamic Temperature-Extremity mild `status_effect` for Mid-Sim flicker/noise in playtest. (§7 L3)
- **NTH9.** Reconcile the "shared severity band" framing with its asymmetric use once SF1 is resolved. (§8 F4)

### Defer (numeric / content-pass)

- **D1.** `k` confidence constant — global vs. per-sub-factor. (§2 G-N1)
- **D2.** Severity-band weighting `P(extreme | event) = f(TrueRisk)`. (§2 G-N2)
- **D3.** Temperature-Extremity extreme-exposure death probability (also `DESIGN_TODO.md`). (§2 G-N3)
- **D4.** Extreme-Storm collateral per-building destruction chance. (§2 G-N4)
- **D5.** Vaccine `Confidence` threshold; Preparedness contribution magnitudes; Weather Shield AOE radius. (§2 G-N5)
- **D6.** `Score(Weather)` + `Score(Bio-hazard)` combination (also `DESIGN_TODO.md`). (§2 G-N6)
- **D7.** Atmospheric Hazard `status_effect` duration. (§2 G-N7)
- **D8.** Balance-pass checks: whether Storm Preparedness *magnitude* ever matters (§8 F5); whether Bio-hazard's scope should shrink to data-plumbing (§8 F2).
