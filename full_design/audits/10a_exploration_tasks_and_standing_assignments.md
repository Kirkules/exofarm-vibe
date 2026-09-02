# Audit — System 10a: Exploration Tasks & Standing Assignments

Pure design review against `full_design/`; no implementation exists. Citations
are `file` → "Section" (no anchor links: this file sits in `audits/` and the
repo link-checker only scans `full_design/*.md`).

**Split rationale.** System 10 was audited as two files. **10a** (this file)
covers the routine every-season exploration loop: the pool, refresh/reroll/lock,
assignment, risk spectrum, the four positive outcome categories, the task
catalog and per-planet exclusives, and the four Standing Assignments. **10b**
(`10b_escalation_chains_alien_contact_trade.md`) covers the multi-step narrative
arc a minority of runs trigger: escalation chains, the sentience-contact chain,
First Contact, alien civilization classes, `ContactRestraint`, alliance
deepening, Trade Agreements, and elevated legend value. The two link
mechanically (10b tasks appear in 10a's pool and use its risk spectrum and
assignment rules) but their design gaps are almost disjoint — 10a's are about
pool economy and catalog completeness, 10b's about an under-specified branching
system.

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Exploration tasks feel like side quests — event-like, not a routine every-season mechanic | `05` "Overview" |
| Always available every season; pool of up to 3 presented during planning | `05` "Overview" |
| Pool refresh — auto at season start + manual reroll; locked and in-progress tasks exempt from every trigger | `05` "Overview" |
| Locking — free, applies only to unaccepted tasks | `05` "Overview" |
| Manual reroll costs a flat Rations amount (TBD); framed as re-sweeping the region; deliberately not Energy; Scanner Station upgrades may reduce it | `05` "Overview" |
| Pool size 3 default, max 5 — Scanner Station upgrade +1 and Research Lab "Expanded Reconnaissance Doctrine" +1; tier mapping TBD | `05` "Overview"; `04` "Scanner Station", "Research Lab" |
| Seasons-to-complete = Ration cost, by construction (a Ration ≡ "1 settler, 1 season") | `05` "Overview", "Assignment" |
| Multi-season task occupies its pool slot as in-progress for its whole duration | `05` "Overview" |
| Number/quality of available tasks varies by planet type and meta-progression | `05` "Overview" |
| One of the three Assignment target kinds — settler-only, one-shot, drawn from the pool | `05` "Assignment"; `03` "Assignment" |
| Multiple tasks run simultaneously if enough settlers + Rations | `05` "Assignment" |
| Assigned settler removed from pooled nutrition headcount for the season; sustenance becomes the task's Ration cost, consumed at season-simulation-start with any other required consumable | `05` "Assignment", "Consumption — Pooled, Not Per-Settler" |
| Cost most tasks — 1 Ration base + optional or mandatory consumable item (optional → guarantees top of range / bonus reward; mandatory → hard prerequisite) | `05` "Assignment", "Task Catalog" |
| Drones barred from Exploration entirely, all tiers | `05` "Assignment"; `04` "Robotics Assembly" |
| Player may never send anyone; Frontier Legends specifically rewards choosing to risk settlers | `05` "Assignment"; `06` "SEED Factions" |
| Four positive outcome categories — Resource windfall / Site reveal (Hybridization-opportunity variant included) / Legend outcome (Achievement vs. Wonder) / Farm-wide Upgrade | `05` "Outcomes" |
| Most tasks yield only a windfall; the other three are rarer, Legend and Farm-wide Upgrade rarest | `05` "Outcomes" |
| Strategy-dimension framing — Profile-shifting / Reinforcing / Neutral; risk tier and reward rarity are independent axes | `05` "Outcomes and the Strategy Dimensions" |
| Every planet type has ≥1 exclusive exploration possibility (Reinforcing + Profile-shifting per planet, table) | `05` "Outcomes and the Strategy Dimensions" |
| Task catalog — windfall + generic Site Reveal; Legend outcomes + Weather Anomaly; Farm-wide Upgrades; planet exclusives; Meteorite Fragment; Unknown Radio Signal (weighted branching + Emergency Medical Kit interaction) | `05` "Task Catalog" |
| Site Reveal tasks — 100% success if attempted; no optional item, nothing to boost | `05` "Task Catalog" |
| Risk Spectrum — No-risk / Low-risk / High-risk, defined by worst possible outcome | `05` "Risk Spectrum" |
| Risk tier gates injury/death severity (Low → SP injury or nothing; High → nothing / SP / permanent / death) | `05` "Injuries", "Risk Spectrum" |
| Negative outcomes trigger only on task failure, for tasks with a real success/failure split | `05` "Injuries" |
| Guaranteed-success-with-independent-risk shape (Site Reveals, Hybridization, most planet exclusives) — base 100% success, only reducible by negative Exploration Aptitude; risk tier applies as a separate independent roll; the two never interact; injury/death here earns a Frontier Legends bonus (larger for injury than death) | `05` "Risk Spectrum", "Aptitude" |
| Planet type affects the proportion of Low/High-risk tasks | `05` "Risk Spectrum"; `06` "Exoplanet Types" |
| Standing Assignments — the other Assignment target kind; drawn fresh each season, not pool-limited; safe (no risk, no Rations); worker-eligibility varies per assignment | `05` "Standing Assignments"; `03` "Assignment" |
| Four members — Basic Deposit Survey, Deep Survey, Clear-Cutting, Trapping | `05` "Standing Assignments" |
| Basic Survey — player-chosen rectangle; one-shot; flags Deep-eligible tiles; Settlers + Advanced All-Purpose Drones | `05` "Standing Assignments"; `04` "Deposit Discovery" |
| Deep Survey — requires Portable High-Powered Scanning Equipment; auto-targets all flagged tiles; one-shot; Settlers + Advanced All-Purpose Drones | `05` "Standing Assignments"; `04` "Deposit Discovery" |
| Clear-Cutting — production-speed-based; mark Forest tiles (drag-rect marks, single-tile toggles); worked through Mid-Sim; unfinished carry over; Wood bounded/depletes; Settlers + any All-Purpose Drone incl. Basic | `05` "Standing Assignments"; `04` "Fuel" |
| Trapping — production-speed-based; one tile; Pelt via repeating cycles; boosted by Forest presence + planet biological richness; renewable/repeatable; Settlers + Advanced All-Purpose Drones | `05` "Standing Assignments"; `04` "Farm/Production" |
| Clear-Cutting / Trapping eligible for Storied's production-speed bonus | `05` "Standing Assignments", "Storied" |
| Standing Assignments do not participate in the Reinforcing/Profile-shifting/Neutral framing | `05` "Standing Assignments" |

**Boundary notes (ambiguous / shared ownership).**
- Escalation chains, First Contact, alien classes, alliance deepening, Trade
  Agreements, elevated legend value → audited in **10b**.
- Deposit Discovery survey *mechanics* (reveal probabilities, depth tiers,
  deep-eligible flagging) are System 7; 10a covers Basic/Deep Survey only as
  Standing Assignment *targets* (assignment, eligibility, resolution shape).
- Hybridization opportunity as a Site Reveal variant — exploration *delivery* is
  here; the Research Lab project and hybridization effects are Systems 7 / 4.
- Injury/death taxonomy and Aptitude/Storied modifiers are System 9; referenced
  at the risk-spectrum seam.
- Ration cost and pooled-nutrition-headcount exclusion are System 8; referenced
  at the assignment seam.
- Pool-size unlocks (Scanner Station tier, Research Lab doctrine) are Systems 7 /
  12; the +1 sources and max of 5 are noted here.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. No pool-population algorithm.** `05` "Overview" says task
  number/quality "varies by planet type and meta-progression unlocks"; the
  catalog carries Rarity (Common/Uncommon/Rare) and "Season gate" columns — but
  no stated rule combines per-planet eligibility + season gate + rarity weights
  + unlock state into the 3 (max 5) filled slots. Blocks building the pool.
  *Possible direction: a weighted draw without replacement from the
  season-gate-eligible, planet-eligible, unlocked subset, weights = rarity, with
  guaranteed-escalation slots (10b) inserted before the draw.*
- **G-S2. Multi-season / multi-Ration payment timing.** "consumed at
  season-simulation-start" (singular) vs. "seasons to complete equals its Ration
  cost." For a 2-Ration task (e.g. Ancient Irrigation Technique), unclear
  whether 2 Rations are paid upfront at season-1 sim-start or 1/season across
  the 2 seasons. `05` "Overview", "Assignment", "Task Catalog".
- **G-S3. Reroll vs. partially-locked/in-progress pools.** When 2 of 3 slots are
  locked or in-progress, does reroll replace only the 1 free slot, and does the
  flat Ration cost still apply in full? Is there a cap on how many slots can be
  locked (a 3-lock pool can never refresh)? `05` "Overview".
- **G-S4. Accepted-task UI location.** An in-progress task "occupies its pool
  slot"; a task accepted this planning phase — does it stay in a pool slot or
  move to a separate active-expeditions area? The refresh rule implies the
  former; the UI model isn't stated. `05` "Overview", "Assignment".
- **G-S5. Injury timing on a multi-season High-risk task.** The settler is
  force-locked to the task each season until it resolves (`05` "Settler State").
  Does the injury roll happen only at resolution, or can it fire mid-task and
  then affect the still-running task? `05` "Settler State", "Injuries", "Risk
  Spectrum".
- **G-S6. Farm-wide Upgrade recurrence.** The category has 3 catalog entries and
  is "rare"; unclear whether those 3 are the whole per-run set and whether the
  same Farm-wide Upgrade task can appear/resolve twice in one run (its effect is
  a permanent settlement-wide passive — non-stacking?). `05` "Outcomes", "Task
  Catalog".

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** Reroll flat Ration cost; per-Scanner-tier reroll discount; which
  Scanner tier grants +1 pool size. `05` "Overview"; `04` "Scanner Station".
- **G-N2.** All per-task success chances, value ranges, rarity weights,
  season-gate values. `05` "Task Catalog".
- **G-N3.** Clear-Cutting / Trapping per-settler speed rates; Trapping
  yield-scaling numbers. `05` "Standing Assignments"; `04` "Fuel",
  "Farm/Production"; also `DESIGN_TODO.md` "Remaining numeric TBDs".
- **G-N4.** Basic Survey rectangle size. `04` "Deposit Discovery".
- **G-N5.** Storied `legend_value` threshold (gates the Standing-Assignment
  speed bonus). `05` "Storied"; `DESIGN_TODO.md`.

### Cross-check with `DESIGN_TODO.md`

Already flagged, touching 10a: the Frontier Legends "hard sites" catalog;
Trapping/Clear-Cutting speed rates; Storied threshold. **Not** flagged: the
pool-population algorithm (G-S1), reroll-cost-vs-slots-refreshed (G-S3), the
multi-Ration payment timing (G-S2), the guaranteed-slot-vs-full-pool case
(shared with 10b). Recommend adding.

---

## 3. Internal consistency

- **IC1. "Event-like, not routine" vs. an always-on 3-slot panel.** `05`
  "Overview" frames tasks as side quests, "not a routine every-season mechanic,"
  then specifies a permanent pool of up to 3 presented "at all times during
  planning" that refreshes every season, with Frontier Legends rewarding
  engagement. Not a mechanical contradiction, but the stated feel and the stated
  availability pull opposite ways; reconcile the wording.
- **IC2. "Site Reveals get no optional item."** `05` "Task Catalog" states Site
  Reveals "get no optional item; there's no quantity to boost" — but the
  planet-exclusives table lists Site-Reveal exclusives with "Mandatory: Portable
  High-Powered Scanning Equipment" / "Mandatory: Temperature-Resistant Gear." No
  literal contradiction (mandatory ≠ optional-boost), but the flat phrasing
  misreads as "Site Reveals take no items." Tighten.
- **IC3. Negative-Aptitude effect on "guaranteed" Site Reveals.** `05` "Risk
  Spectrum" says these carry "a base 100% success rate — only reducible by
  negative Exploration Aptitude … otherwise as good as guaranteed." `05`
  "Aptitude" gives concrete reductions (`p_new = 0.75 × p` at −2; −1 to
  resource-outcome maximums at −3). "As good as guaranteed" and an explicit
  0.75 multiplier are two different descriptions of the same case; reconcile.

---

## 4. Cross-system consistency

- **CS1 (→ G-S1). Pool population spans three systems with no combining rule.**
  Planet type (System 12) sets the eligible set; Scanner/Research unlocks
  (System 7) raise pool size; season gate + rarity live in the catalog. Nothing
  ties them together. `05` "Overview", "Task Catalog"; `06` "Exoplanet Types".
- **CS2. Two feeding moments, only one in the Season Structure list.** Explorer
  Ration cost is deducted at season-simulation-start (`05` "Assignment"); at-home
  pooled nutrition resolves at Post-Sim (`05` "Consumption"; `03` "Season
  Structure"). Intended, but `03`'s resolution-moment list names only the
  Post-Sim nutrition step — the sim-start explorer deduction should appear
  there too.
- **CS3. Standing Assignments split across two resolution models.** Basic/Deep
  Survey are one-shot ("returns with a result") and map to `03` "Season
  Structure" Post-Sim sub-step (2) "Deposit Discovery survey resolution."
  Clear-Cutting and Trapping are production-speed-based Mid-Sim accumulation.
  `03` names only the Survey case; where Clear-Cutting/Trapping output lands
  isn't stated. `05` "Standing Assignments"; `03` "Season Structure".
- **CS4. Drone eligibility lists must stay in sync.** `05` "Standing
  Assignments" (Advanced All-Purpose for Survey/Trapping; any All-Purpose incl.
  Basic for Clear-Cutting) and `04` "Robotics Assembly" task-eligibility table
  must agree; today they do, but they are two independently-maintained lists.
- **CS5. Frontier Legends injury/death bonus is only in `05`.** `05` "Risk
  Spectrum" defines a Frontier Legends bonus (large for injury, moderate for
  death, injury > death) for injury/death on guaranteed-success-with-risk tasks.
  `06` "SEED Factions" Frontier Legends describes only static per-site
  legend-values and the sentience-chain inverse-probability scaling — this bonus
  source is absent there.
- **CS6. "One-time `Confidence(Weather)` burst"** from Weather Anomaly
  Investigation / Aurora Readings (`05` "Task Catalog") is undefined in
  evidence-count terms — how many pseudo-reports, and does it move `a`/`b` or
  `ν` only? A directionless burst needs the `EcologicalData`-style `ν`-only
  treatment, not stated. Seam with System 11. `06` "Data-Gathering Mechanism".
- **CS7. Aptitude Exploration bucket ↔ outcome shapes (System 9).** `05`
  "Aptitude" says its effect "Applies to every exploration outcome, including
  the previously-'guaranteed' ones." Both systems must agree a "guaranteed"
  Site Reveal is really "base 100%, scalable down by Exploration Aptitude only."
  Tight coupling to note.

---

## 5. Story & world consistency

- **Reinforcing.** Exploration-as-side-quest with real settler risk fits `02`
  "SEED's Culture, and the Player's Role" (prestigious, competitive settlers, a
  scrappy mission-first arm) and Frontier Legends' framing after Captain Kiran
  (`02` "The Kiran Incident"; `06` "SEED Factions"). Standing Assignments being
  safe on-farm work, distinct from genuine off-site expeditions, is a clean
  fiction match.
- **Minor stretch (no change required).** A reliably-populated 3-task pool every
  season on an unexplored world reads slightly gamey. `05` already hangs a
  lantern on it ("tasking local sensors/drones with a fresh sweep"); noting it
  so it stays a conscious call.
- **Missed reinforcement (→ NTH4).** The exploration reroll's "settlers eat
  while drones re-sweep the region" hook is stated fully for Farm Site
  Selection's reroll but only glancingly for the exploration reroll — a chance
  to reinforce the "everything the expedition does costs sustenance" theme.
- No lore conflicts in the core loop.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Planning phase is reversible / randomization gated behind an explicit
  commitment* — accepting a task and assigning settlers/tools/food is reversible
  plan-composition; the reroll is the explicit irreversible commitment that
  gates the redraw, exactly the pattern `01` prescribes. Outcome rolls resolve
  in simulation, not planning.
- *Difficulty from breadth of tradeoffs* — send-or-not, which task, which
  optional item, reroll now vs. save Rations to launch — all resource
  tradeoffs, no execution skill.
- *Forgiving of individual mistakes* — never exploring is viable; a failed
  No-risk task just costs a Ration.

**Risks / violations:**
- **P1 (→ SF1). Luck must be distinguishable from certainty.** The
  guaranteed-success + independent-risk dual roll (`05` "Risk Spectrum") means a
  settler can discover the vein and still die to the environment, or fail the
  discovery (negative Aptitude) and also die. `01` "failure should always be
  legible" requires the player be told *which*; the result messaging isn't
  specified.
- **P2 (→ NTH3). Minimal UI interaction.** Pool + lock toggles + reroll +
  per-task optional-item pickers + multi-task assignment + a next-planning
  confirmation dialog is a lot of surface. Each is a real decision, but
  optional-item pickers should be surfaced only for tasks whose item the
  settlement actually holds, per "surface relevant choices ahead of irrelevant."
- **P3. A passable plan should always be quick to reach.** Exploration is fully
  skippable (floor is fine), but the engaged path recurs every season — confirm
  in playtest it stays optional-feeling and doesn't become a mandatory chore for
  a Frontier-Legends-chasing player.
- **P4 (→ NTH5). Colour is never the sole channel.** Risk tier (No/Low/High) in
  the pool UI must carry a non-colour cue. Art pass deferred; recorded here.

---

## 7. Player legibility

- Risk tier per task — the three-tier scheme is simple and learnable; legible
  once the visual language is set (P4).
- Optional vs. mandatory item — the catalog distinguishes them; the UI must make
  "you *may* bring X for top of range" vs. "*requires* X" unmistakable.
- Reroll cost vs. launch cost draw the same Ration pool — the Ration count must
  be visible when deciding to reroll (implied by "tooltips throughout," not
  specified).
- Result reveal — the dedicated confirmation UI at next-planning start is a
  clear single moment, not silent. Good.
- The guaranteed-vs-risk dual roll (P1) is the main legibility hazard.
- Standing Assignments — Clear-Cutting's carry-over and Trapping's continuous
  yield need a Mid-Sim progress indication (production-overlay analog); only
  production *buildings* have one specified.

---

## 8. Fun / scope risk

- **Pool + reroll + lock economy is well-scoped** — a recurring optional
  decision with a finite-resource cost. Keep.
- **Catalog breadth** (~30 entries + per-planet exclusives + one-off branches)
  is content-authoring load, not rule complexity — fine, but the
  pool-population algorithm (G-S1) must exist or the catalog can't be surfaced
  coherently.
- **Farm-wide Upgrade outcomes** are high-impact, rare, permanent — verify one
  roll can't trivialize a strategy dimension (e.g. "Farm-wide Water reduction"
  on Arid). Balance-pass watch item.
- **Standing Assignments overlap production buildings** for Clear-Cutting/
  Trapping (both speed-based, both Storied-eligible) — deliberate, but this
  means they compete for the same worker pool and Storied bonus; they aren't
  free parallel capacity.
- **Narrowing risk.** Frontier Legends' `StandoutSettlerRecord` (max across
  settlers) rewards funneling every risky task to one "designated hero." `05`
  "Risk Spectrum" partly counteracts this (injury bonus > death bonus keeps the
  hero alive). Flag for the balance pass to check whether hero-funneling
  dominates.

---

## 9. Findings summary

### Blockers

- **B1.** No pool-population/draw algorithm — filling the 3 (max 5) slots from
  the per-planet eligible set given Rarity, Season gate, and meta-progression
  unlocks is unspecified. (§2 G-S1, §4 CS1 — `05` "Overview" / "Task Catalog";
  `06` "Exoplanet Types")
- **B2.** Multi-season / multi-Ration payment timing undefined — 2 Rations
  upfront at sim-start vs. 1/season across the duration; "consumed at
  season-simulation-start" contradicts "seasons to complete = Ration cost." (§2
  G-S2 — `05` "Overview" / "Assignment" / "Task Catalog")
- **B3.** Reroll's interaction with partially-locked/in-progress pools undefined
  — which slots refresh, whether the flat cost scales with slots refreshed,
  whether locks can starve the pool of refreshes (no lock cap). (§2 G-S3 — `05`
  "Overview")

### Should-fix

- **SF1.** Specify guaranteed-success-vs-independent-risk result messaging — the
  player must be told separately whether the discovery succeeded and whether the
  environment harmed the settler. (§6 P1, §7 — `05` "Risk Spectrum"; `01`
  failure-legibility)
- **SF2.** State where an accepted/in-progress task lives relative to the 3 pool
  slots, and how a guaranteed-escalation slot (10b) is placed when the pool is
  full. (§2 G-S4 — `05` "Overview" / "Escalation Chains")
- **SF3.** Add the explorer Ration deduction (sim-start) to `03` "Season
  Structure"'s resolution-moment list — it currently names only Post-Sim pooled
  nutrition. (§4 CS2 — `05` "Assignment" / "Consumption"; `03` "Season
  Structure")
- **SF4.** Name where Clear-Cutting / Trapping output lands in the Season
  Structure model (Mid-Sim accumulation) vs. Basic/Deep Survey's Post-Sim
  one-shot. (§4 CS3 — `05` "Standing Assignments"; `03` "Season Structure")
- **SF5.** Add the injury/death-on-guaranteed-success-with-risk Frontier Legends
  bonus (large for injury, moderate for death) to `06`'s Frontier Legends
  description — it lives only in `05` "Risk Spectrum" today. (§4 CS5 — `05` "Risk
  Spectrum"; `06` "SEED Factions")
- **SF6.** Define the "one-time `Confidence(Weather)` burst" from Weather
  Anomaly Investigation / Aurora Readings in evidence-count terms (how many
  pseudo-reports; `ν`-only vs. `a`/`b`). (§4 CS6 — `05` "Task Catalog"; `06`
  "Data-Gathering Mechanism")
- **SF7.** Reconcile the two descriptions of how negative Exploration Aptitude
  reduces a "guaranteed" Site Reveal — "as good as guaranteed" vs. explicit
  `p_new = 0.75 × p` / −1 outcome-max. (§3 IC3 — `05` "Risk Spectrum" /
  "Aptitude")
- **SF8.** Tighten `05` "Task Catalog"'s "Site Reveals get no optional item" —
  the planet-exclusives table lists Site-Reveal exclusives with mandatory items.
  (§3 IC2 — `05` "Task Catalog")
- **SF9.** Specify whether an injury roll on a multi-season High-risk task can
  occur mid-task or only at resolution. (§2 G-S5 — `05` "Settler State" /
  "Injuries" / "Risk Spectrum")
- **SF10.** Add a Mid-Sim progress indication for Clear-Cutting (tiles cleared /
  carried over) and Trapping (accumulating Pelt). (§7 — `05` "Standing
  Assignments"; `03` "Season Structure")

### Nice-to-have

- **NTH1.** Reconcile the "event-like, not routine" framing with the always-on
  3-slot every-season panel. (§3 IC1)
- **NTH2.** Clarify whether a Farm-wide Upgrade task can recur within a run, and
  the non-stacking of its permanent effect. (§2 G-S6)
- **NTH3.** Show optional-item pickers only for tasks whose item the settlement
  currently holds. (§6 P2)
- **NTH4.** Give the exploration reroll the same "settlers eat while drones
  re-sweep" framing already used for Farm Site Selection's reroll. (§5)
- **NTH5.** Record the non-colour channel requirement for risk-tier display in
  the pool UI. (§6 P4)

### Defer (numeric / content-pass)

- **D1.** Reroll flat Ration cost; per-Scanner-tier reroll discount; which
  Scanner tier grants +1 pool size. `05` "Overview"; `04` "Scanner Station".
- **D2.** All per-task success chances, value ranges, rarity weights,
  season-gate values. `05` "Task Catalog".
- **D3.** Clear-Cutting / Trapping per-settler speed rates; Trapping
  yield-scaling numbers. `05` "Standing Assignments"; `04` "Fuel" /
  "Farm/Production"; `DESIGN_TODO.md`.
- **D4.** Basic Survey rectangle size. `04` "Deposit Discovery".
- **D5.** Catalog of named "hard sites" with legend-values. `DESIGN_TODO.md`.
- **D6.** Exact building↔Hybridization-discovery pairings. `04`
  "Farm/Production".
