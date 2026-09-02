# Audit — System 5: Energy

Design audit #5. Pure design review against `full_design/`; no implementation
exists. Citations are `file` → "Section" (bare numbered prefix; no anchor links,
since this file sits in `audits/` and the repo link-checker only scans
`full_design/*.md`).

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Energy is two continuously-tracked live rates — total Income, total Consumption (Energy/s); **no stockpile ever**, nothing carried between moments or across the season boundary | `04` "Energy Income/Consumption Rates" |
| Energy never an inventory item; its own dedicated UI bar; orthogonal to Storage's uncapped-inventory rules | `04` "Basic Resources", "Energy Income/Consumption Rates" |
| "Keeping the lights on" = a live Income-vs-Consumption comparison, never a depleting reserve | `04` "Energy Income/Consumption Rates" |
| **Reliable** Income — Solar Array, Geothermal Generator; constant for the whole season, no failure mode | `04` "Energy Income/Consumption Rates", "Solar Array", "Geothermal Generator" |
| **Conditional** Income — Fuel-based Generator only; contributes while actively burning, drops to zero the instant its fuel limit / supply is exhausted or a hazard disrupts it | `04` "Energy Income/Consumption Rates", "Fuel-based Generator" |
| Solar Array — unstaffed, Energy out, rate varies by planet type; repeatable + upgrade path (late tier → Fusion Generator lore); one present at run start (count tied to wormhole mass-threshold tech) | `04` "Solar Array", "Basic Resource Production" |
| Geothermal Generator — unstaffed, built on a discovered Thermal Vent (Volcanic-exclusive), rate above Solar's Volcanic-tier rate; the intended offset for Weather Shield's temperature cost | `04` "Geothermal Generator" |
| Fuel-based Generator — unstaffed; planning-phase active/inactive + a fuel limit (max Wood/Fossil Fuel for the season); burns for a duration set by that limit or available fuel; base burns Wood, upgrade adds Fossil Fuel (multi-recipe, sticky); no upgrade beyond Fossil Fuel | `04` "Fuel-based Generator", "Fuel" |
| Consumption = every building's flat per-season baseline + temporarily **elevated** sources (Weather/Row Shield event cost, drone battery recharge) layered on while active | `04` "Energy Income/Consumption Rates" |
| Baseline Energy upkeep — every building draws a flat per-season rate just for existing; fixed at placement, never re-examined; **only** Weather Shield / Row Shield deviate (idle-armed rate that elevates during a Temperature Extremity event) | `04` "Baseline Energy upkeep" |
| Temperature / Protection / Energy coupling — enclosed or protected structures (A) carry a passive Energy upkeep (D) scaling with how extreme the planet's ambient temperature is; near-zero on temperate planets; "always explicitly listed when it has an impact" | `06` "The Four Strategy Dimensions"; `04` "Building Schema" (Energy-upkeep conditional property) |
| Shortfall handling — when Consumption exceeds available Income at any Mid-Sim moment, enough currently-active consumers are shed **at random** (never by build order or player priority) until Consumption fits under Income | `04` "Energy Income/Consumption Rates" |
| Recompute cadence — only on real change events (a Conditional source's window starting/ending, a hazard event starting/ending, a building built/destroyed/toggled), not every tick | `04` "Energy Income/Consumption Rates" |
| Active/inactive toggle — **every** building has one (generalized from Fuel-based Generator's control) | `04` "Energy Income/Consumption Rates" |
| Planning-phase Income bar — 0 → season's optimistic max Income (assumes every Conditional source runs its full window); two indicator lines (planned Income, planned Consumption); tooltip states it is best-case, not a guarantee | `04` "Energy Income/Consumption Rates" |
| Per-building power prediction — **Green** (Reliable alone covers its share) / **Yellow** (covered only with Conditional) / **Red** (not covered even optimistically); a planning-phase prediction, not a live status; shape-coded, not colour-alone | `04` "Energy Income/Consumption Rates" per-building prediction; `03` "Site Panel (UI)" |
| Drone battery recharge — a temporary elevated Consumption; competes in the same random-shedding pool; recharge simply doesn't progress until Income covers it | `04` "Robotics Assembly" (Battery) |
| Fuel-based Generator Energy output feeds Stewardship's `EmissionsRestraint` (Fossil Fuel at a higher per-unit rate than Wood) | `06` "SEED Factions" (`EmissionsRestraint`) |
| Cut from the prior design — the entire power grid: broadcast range, networks, shared pools, batteries, the double-tap toggle | `03` "What Got Cut", "Platform & Core Loop Redesign" |

**Boundary notes (ambiguous ownership).**
- **Weather/Row Shield event-driven cost** — the rate mechanic (idle-armed → mild → extreme banding) is Energy; the coverage math and the slow/stop/destroy consequence are Hazards (System 11). Findings E-S4 / E-CS1 sit on that seam.
- **Drone battery recharge as elevated Consumption** — the recharge *need* is Resource Economy / drones (System 7); its Energy-competition behaviour is here.
- **Temperature-coupling upkeep** — the *rate* is Energy; *which* structures carry it and how it scales is a Building Schema / Planet Types fact (E-S1).
- **`EmissionsRestraint`** — Energy production method feeds it; the scoring term itself is Scoring / System 11.
- **Twin resource:** Water (System 6) is explicitly "the same shape as Energy" as a live rate — but resolves scarcity by opposite means (see E-CS5).

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **E-S1. The temperature/protection/energy coupling is intent, not spec — and three passages disagree.** `06` "The Four Strategy Dimensions" says "enclosed or protected structures (A) carry a passive Energy upkeep cost (D) that scales with how extreme the planet's ambient temperature is." `04` "Baseline Energy upkeep" says **only** Weather Shield / Row Shield deviate from a flat, placement-fixed baseline and "no individual building's own baseline rate ever needs re-examining once built." `04` "Building Schema" (Energy-upkeep conditional property) says upkeep is "nonzero primarily via the Protection/temperature-coupling mechanic." `04` "Building Schema" (Indoor or Outdoor) says an Indoor building shields its worker from Temperature Extremity "for free." Unresolved: which buildings carry it (all Indoor? greenhouses? only the two shields?), whether it is a flat rate set at placement from the site's Average Temperature or an event-driven rate keyed to active Temperature Extremity events, and the scaling function. Strategy dimension D's "real teeth" (`06`) depend entirely on this. *Possible direction: make the coupling a flat per-season rate on every Indoor/enclosed building, set at placement from the site's Average Temperature (known at Farm Site Selection), distinct from the two shields' separate event-driven cost.*
- **E-S2. "Consumer" and "active" are undefined for the shedding mechanism.** Does an unstaffed producer with a baseline draw (Solar Array itself) count as a sheddable consumer? Does a building mid-production-cycle that is shed pause and resume, or lose cycle progress? Does a shed staffed building release its worker? (`04` "Energy Income/Consumption Rates")
- **E-S3. The recompute-trigger list is stated as exhaustive but is not.** `04` lists a Conditional source's window, a hazard event, and a building built/destroyed/toggled. It omits a drone starting/finishing battery recharge (an elevated-Consumption change acknowledged in `04` "Robotics Assembly") and the consumption drop caused by a shed building itself — which changes the total and could un-shed others, raising an ordering/termination question the design does not address. (`04` "Energy Income/Consumption Rates"; `04` "Robotics Assembly")
- **E-S4. Whether an armed shield is eligible for random shedding during the very event it counters is unspecified.** `06` "In-Simulation Hazard Events" makes the shield maintain the comfort target only "if the shield isn't one of the consumers randomly shed during a shortfall" — so a shield can be shed mid-Temperature-Extremity-event, producing the slow/stop + settler exposure it exists to prevent. Also unspecified: whether the shield's elevated cost is added to Consumption *before* the shedding pass (letting it be shed to relieve the cost it just created). (`06` "In-Simulation Hazard Events"; `04` "Energy Income/Consumption Rates")
- **E-S5. The per-building active/inactive toggle has no defined interaction.** The redesign cut the double-tap-to-toggle-power gesture (`03` "Platform & Core Loop Redesign" supersede note, "What Got Cut"), and the Energy redesign reintroduces a toggle on every building with no replacement gesture/UI specified. (`04` "Energy Income/Consumption Rates"; `03` "What Got Cut")

### Numeric (deferred to balancing — catalogued only)

- **E-N1.** All per-building baseline Energy consumption rates. `04` "Baseline Energy upkeep".
- **E-N2.** Solar Array / Geothermal / Fuel-based Generator output rates per planet type; Fossil Fuel vs. Wood Energy-per-unit and burn efficiency. `04` "Basic Resource Production", "Fuel".
- **E-N3.** Weather/Row Shield idle-armed rate and its mild/extreme elevation bands. `04` "Baseline Energy upkeep"; `06` "In-Simulation Hazard Events".
- **E-N4.** Temperature-coupling upkeep scaling function and magnitude (after E-S1). `06` "The Four Strategy Dimensions".
- **E-N5.** Per-planet-type base Energy regeneration / Solar rate — already flagged open. `06` "Initial Planet Types" open questions.

### Cross-check with `DESIGN_TODO.md`

"Energy Pool per-building powered state" is marked resolved and captures the rate-model redesign (live Income/Consumption, Reliable/Conditional, random shedding, the optimistic bar, Green/Yellow/Red) accurately. It does **not** flag E-S1 (temperature-coupling underspecification), E-S2 / E-S3 / E-S4 (shedding-mechanism gaps), E-S5 (toggle interaction), or E-CS4 (per-building "share" undefined). "Hydroelectric Generator + River feature" is correctly parked as deferred new scope. Recommend adding E-S1, E-S4, E-S5, E-CS4.

---

## 3. Internal consistency

- **E-IC1. Solar Array's construction cost lists "Energy."** `04` "Solar Array" — "Construction cost: modest Energy + Lumber/Concrete." Energy has "no stockpile at all … nothing is ever 'spent' from a reserve" (`04` "Energy Income/Consumption Rates"), and `04` "Building Schema" makes Lumber+Concrete the universal construction materials that replaced Matter. A build cost payable in Energy is impossible under the rate model — a leftover from the pre-redesign economy. (→ SF3)
- **E-IC2. "Never re-examined once built" vs. temperature-coupled upkeep.** `04` "Baseline Energy upkeep"'s claim that no building's baseline rate ever needs re-examining is directly contradicted by `06`'s temperature-scaled enclosed-structure upkeep and by `04` "Building Schema"'s own Energy-upkeep conditional property. Same root as E-S1. (→ B1)
- **E-IC3. Rate unit granularity.** `04` "Energy Income/Consumption Rates" uses "Energy/s"; `01` "Units are unspecified" gives "Energy per season" as the model rate a player needs. Two time bases for one quantity. (→ NTH1)
- **E-IC4. "no … on/off toggling" (cut) vs. "the active/inactive toggle every building has" (reintroduced).** Not a mechanical contradiction — the power grid is gone and the toggle now serves rate management — but the `03` "What Got Cut" line reads as false out of context. (→ NTH2)

---

## 4. Cross-system consistency

- **E-CS1. Shedding a Water collection building (System 6).** If shed buildings stop producing and a staffed Water collection building is shed during an Energy shortfall, Water Income can hit zero → `04` "Water"'s "zero Water Income anywhere this season → every settler dies." Whether Water buildings are shed-eligible or protected is unspecified, and it is the difference between an Energy shortfall being a slowed-production inconvenience and a total-colony-loss event. (`04` "Energy Income/Consumption Rates" × `04` "Water") (→ B3)
- **E-CS2. Green/Yellow/Red needs a per-building Consumption *share*.** "Reliable Income alone already covers its share" implies apportioning total Income across consumers, but no apportionment rule is given (equal split? by draw size? a priority order the design elsewhere refuses to have). Without one, "its share" is undefined and the Site Panel indicator cannot be computed. (`04` per-building prediction; `03` "Site Panel (UI)") (→ B2)
- **E-CS3. Continuous-rate production (System 4) vs. "recompute only on real change."** Production accumulates every tick; Energy coverage is recomputed only on discrete events. The claim that nothing drifts between events must be confirmed against every elevated-Consumption source, especially drone recharge cycles that start/stop mid-window (see E-S3). (`04` "Energy Income/Consumption Rates" × `03` "Production Model") (→ SF1)
- **E-CS4. Shed building and its worker (System 3).** Unspecified whether a shed staffed building releases its worker to the roster for the rest of the window or holds them idle — feeds the Worker Roster's Mid-Sim per-worker state (working / idle). (`04` "Energy Income/Consumption Rates" × `03` "Worker Roster (UI)") (→ SF7)
- **E-CS5. Opposite scarcity philosophies for twinned resources.** Water resolves contention by strict deterministic FIFO ("the intended player skill is keeping total supply ahead of total demand, not gaming service order"); Energy resolves it by deliberate randomness (so "which specific building goes dark is never something a player can optimize"). Same stated goal, opposite mechanism, on two resources the design calls "the same shape." Worth a conscious confirmation. (`04` "Energy Income/Consumption Rates" vs `04` "Farm/Production" water-draw queue) (→ NTH3)
- **E-CS6. Scoring feeds.** Energy production method feeds Stewardship's `EmissionsRestraint`; Energy itself is not scored and is not a `ResourceStockpile` / `ResourceIncome` entry (it has no stockpile). Confirm no faction formula references an Energy quantity. (`06` "SEED Factions") (→ D6)

---

## 5. Story & world consistency

- **Positive / reinforcing.** The Solar / Geothermal / Fuel triad maps cleanly onto real energy sources at the game's cozy-pioneering altitude. Fuel-based Generator's `EmissionsRestraint` penalty is explicitly "the mechanic's direct playable echo of … Ren, the Incoming Star" (`06` "SEED Factions") — Stewardship rewarding a new planet's climate stewardship on its own terms. Solar Array's late-tier Fusion Generator pays off `02` "The Crash Research Era"'s controlled-fusion breakthrough. No lore conflict in the core system.
- **Minor stretch (no change required).** A colony-wide Energy rate with genuinely zero storage — not even a buffer — is a mild fiction stretch (real settlements carry batteries; `03` "What Got Cut" removed them for gameplay reasons). Acceptable at this altitude, noted so it is a conscious call.
- **Missed reinforcement (→ NTH4).** There is no in-fiction hook for why Energy cannot be stored at all. A one-line frame — expedition-grade equipment runs live off the microgrid; storage mass was not in the wormhole budget — would tie the no-stockpile rule to the story the way `02`'s mass-threshold logic ties the small starting footprint to it.

---

## 6. Design-principle adherence

**Adherent — worth recording as deliberate strengths:**
- *Difficulty from breadth of tradeoffs, not execution precision* — Energy budgeting is a strategy puzzle (Income diversity, Conditional-source risk, shield timing); random shedding deliberately deletes the outage-triage optimization axis.
- *Planning phase is reversible; randomization gated behind commitment* — toggles and fuel limits are reversible planning actions; the only randomness (shedding) lives in Mid-Sim, not planning.
- *Failure legibility (intent)* — "always explicitly displayed when it has an impact, never a hidden drain" is stated repeatedly for the shield and temperature costs; the Income bar's "best case, not a guarantee" tooltip directly serves Conditional-source shortfall legibility.
- *Numbers stay small* — Energy has its own unit, no physical-unit label; rates only, no accumulating balance to grow large.

**Risks / violations:**
- **P1 (→ B2). Colour is never the sole channel + failure legibility.** Green/Yellow/Red is called shape-coded (good), but the Income bar's two indicator lines (planned Income, planned Consumption) have no specified non-colour distinction. (`01` "Color is never the sole channel of information")
- **P2 (→ SF5). Failure should always be legible / luck distinguishable from certainty.** A building going dark from random shedding needs a simulation-log line with cause, or it reads as an unexplained production gap; nothing currently designates it a "noteworthy event" for System 2's feed. The player must be able to tell "shed by chance during a shortfall" from "deterministic consequence I could have prevented." (`01` "Failure should always be legible")
- **P3 (→ SF10). Never a hidden drain — but where is it shown?** The temperature-coupling upkeep is promised to be "always explicitly listed when it has an impact," but no surface is named (Site Panel status section? Energy bar tooltip?). (`06` "The Four Strategy Dimensions"; `03` "Site Panel (UI)")
- **P4 (→ B4 / scope). A passable plan should always be quick to reach.** On a high-D planet (Frozen/Ice), the per-building active/inactive toggle plus fuel-limit tuning plus reading Green/Yellow/Red per building is real recurring planning surface. Sticky defaults help a steady-state build; the tight-Energy early game is where "any passable plan" could get slow — worth watching in playtest.
- **P5 (→ NTH2). Docs describe the current design, not its history.** `04` "Basic Resources" — "Matter no longer exists as a resource. It's been removed entirely" — is history narration in a numbered doc.
- Not engaged / n/a: units-unspecified (Energy is its own unit — compliant), naming convention, normalize-before-combining (Energy is not summed into any score), dexterity-timing scale / touch-mouse parity / text-legibility (input & art deferred — but see E-S5 for the missing toggle gesture).

---

## 7. Player legibility

- **Income vs. Consumption bar, two indicator lines** — a good at-a-glance planning read, once the two lines are non-colour-distinguishable (P1).
- **Green/Yellow/Red per building** — good and shape-coded, but uncomputable until the per-building "share" apportionment is defined (E-CS2 / B2).
- **A building going dark mid-simulation** — needs a cause-carrying log line (P2 / SF5).
- **"Best case, not a guarantee" bar tooltip** — directly serves legibility for Conditional-source shortfalls. Good.
- **Temperature-coupling upkeep** — promised visible "when it has an impact," but no location specified (P3 / SF10).
- **Fuel limit** — the player sets a per-season number per Fuel-based Generator; needs a clear readout of "burned X of Y this season" afterward (not specified).

---

## 8. Fun / scope risk

- **The per-building active/inactive toggle risks reintroducing the very outage-triage the random shedding was designed to remove.** Random shedding kills *reactive* triage; but on a tight-Energy planet the optimal move becomes *proactive* triage — toggle off low-value buildings before simulation so the high-value ones are safe from the random pick. That is arguably the same optimization the design says it does not want. This is the system's central scope risk; worth an explicit decision (e.g. the toggle is coarse and off-by-default-heavy, or its purpose is reframed).
- **Strategy dimension D has teeth only if E-S1 resolves into a substantial mechanic.** If the temperature-coupling upkeep stays vague, D collapses to "build enough Solar Arrays" and the A↔D coupling on extreme-temperature planets never materializes.
- **Green/Yellow/Red prediction is genuinely good** — it converts an opaque runtime outcome into a planning-phase readout with low rule weight. Keep.
- **Conditional (Fuel-based Generator) as the one risk-bearing Income source is a clean design** — one building carries the "plan might fall short" tension; everything else is Reliable. Keep.
- **Fuel limit as a per-season numeric** — minor extra surface; fine if it is sticky-carried (see E-S6 / SF8).

---

## 9. Findings summary

### Blockers

- **B1.** The temperature/protection/energy coupling is described as intent, not built spec, and `06` "The Four Strategy Dimensions", `04` "Baseline Energy upkeep", `04` "Building Schema" (Energy-upkeep property), and `04` "Building Schema" (Indoor "for free") give four non-agreeing accounts of which buildings carry it and whether it is flat-at-placement or event-driven. Strategy dimension D depends on it. (§2 E-S1, §3 E-IC2)
- **B2.** The Green/Yellow/Red per-building power prediction requires apportioning total Income into a per-building "share," and no apportionment rule exists — so the Site Panel indicator cannot be computed. (§4 E-CS2 — `04` "Energy Income/Consumption Rates" per-building prediction; `03` "Site Panel (UI)")
- **B3.** "Consumer" and "active" are undefined for the random-shedding mechanism, and it is unspecified whether staffed Water collection buildings are shed-eligible — if they are, an Energy shortfall can zero Water Income and trigger `04` "Water"'s all-settlers-die check, turning a minor shortfall into a run-ending event. (§2 E-S2, §4 E-CS1 — `04` "Energy Income/Consumption Rates" × `04` "Water")
- **B4.** Unresolved whether an armed Weather/Row Shield is eligible for random shedding during the Temperature Extremity event it is meant to counter, and whether its elevated cost is added before or after the shedding pass — the `06` "In-Simulation Hazard Events" consequence chain is not buildable without this. (§2 E-S4 — `06` "In-Simulation Hazard Events"; `04` "Energy Income/Consumption Rates")

### Should-fix

- **SF1.** The `04` recompute-trigger list is stated as exhaustive but omits drone recharge start/stop and the consumption drop from a shed building itself (which raises an un-shed / termination-ordering question). Make it cover every elevated-Consumption source's onset/end and define the shedding pass's termination. (§2 E-S3, §4 E-CS3 — `04` "Energy Income/Consumption Rates"; `04` "Robotics Assembly")
- **SF2.** Decide and state whether a shed staffed building releases its worker to the roster or holds it idle for the rest of the window (feeds the Worker Roster Mid-Sim state). (§4 E-CS4 — `04` "Energy Income/Consumption Rates" × `03` "Worker Roster (UI)")
- **SF3.** Remove "Energy" from Solar Array's construction cost — Lumber/Concrete are the universal construction materials and Energy has no stockpile to spend. (§3 E-IC1 — `04` "Solar Array" vs "Energy Income/Consumption Rates" / "Building Schema")
- **SF4.** Define the interaction for the per-building active/inactive toggle — the double-tap-to-toggle-power gesture it inherited was cut in the redesign. (§2 E-S5 — `04` "Energy Income/Consumption Rates"; `03` "What Got Cut")
- **SF5.** Require random-shedding events to surface in the simulation log with cause ("Energy shortfall — [building] offline"); confirm they count as "noteworthy events" for System 2's feed, so luck is distinguishable from a preventable certainty. (§6 P2 — `01` "Failure should always be legible")
- **SF6.** Give the Income bar's two indicator lines (planned Income, planned Consumption) a non-colour distinction — label, style, or position. (§6 P1 — `01` "Color is never the sole channel of information")
- **SF7.** State where the temperature-coupling upkeep is surfaced to the player ("always explicitly listed when it has an impact" names no surface). (§6 P3 — `06` "The Four Strategy Dimensions"; `03` "Site Panel (UI)")
- **SF8.** State whether the Fuel-based Generator fuel-limit value is sticky-carried and reversible like other planning defaults; add a post-season "burned X of Y" readout. (§2 — `04` "Fuel-based Generator")

### Nice-to-have

- **NTH1.** Unify the Energy rate time base for display — `01` "Units are unspecified" says "Energy per season," `04` says "Energy/s." (§3 E-IC3)
- **NTH2.** Fold the `03` "What Got Cut" "no … on/off toggling" line so it does not read as false against the reintroduced per-building toggle; likewise the `04` "Matter no longer exists … removed entirely" history line, per `01` "describe the current design, not its history." (§3 E-IC4, §6 P5)
- **NTH3.** Confirm that Water's strict-FIFO and Energy's deliberate-randomness are an intentional pair of opposite mechanisms for the same "not gameable" goal on two resources the design calls "the same shape." (§4 E-CS5)
- **NTH4.** Give the no-stockpile rule an in-fiction hook (microgrid runs live; storage mass was not in the wormhole budget), matching how other systems tie to lore. (§5)

### Defer (numeric / content-pass)

- **D1.** All per-building baseline Energy consumption rates. `04` "Baseline Energy upkeep".
- **D2.** Generator output rates per planet type; Fossil Fuel vs. Wood Energy-per-unit and burn efficiency. `04` "Basic Resource Production", "Fuel".
- **D3.** Weather/Row Shield idle-armed rate and its mild/extreme bands. `04` "Baseline Energy upkeep"; `06` "In-Simulation Hazard Events".
- **D4.** Temperature-coupling upkeep scaling function and magnitude (after B1). `06` "The Four Strategy Dimensions".
- **D5.** Per-planet-type base Energy regeneration / Solar rate. `06` "Initial Planet Types" open questions.
- **D6.** Confirm no faction formula references an Energy quantity. `06` "SEED Factions".
