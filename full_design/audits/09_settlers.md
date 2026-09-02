# Audit — System 9: Settlers

Design audit. Pure design review against `full_design/`; no implementation
exists. Citations are `file` → "Section" (no anchor links: this file sits in
`audits/` and the repo link-checker only scans `full_design/*.md`).

Scope: Settler State; Crew Selection; Aptitude; Experience; Storied; the
Injuries taxonomy; death / roster removal; the narrative-only-flavor boundary.
Injury *causes* (exploration risk rolls, Atmospheric Hazard, Temperature
Extremity) and the *Assignment* mechanic itself are adjacent systems (10, 11, 3)
and in scope here only at the seam.

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| 3–4 named human settlers at run start; must be fed each season; starvation = critical failure | `05` "Settlers" |
| `current_assignment` — Production building / Standing Assignment / Exploration Task / idle; lives on the settler | `05` "Settler State" |
| Sticky/locked is a property of the *target*: Production = remembered default, freely changeable; incomplete multi-season Exploration = forced + locked; completed Exploration = settler unassigned; Standing Assignment = one-shot, no stickiness | `05` "Settler State" |
| `status_effect` — a *list* of concurrent entries: Injury, Atmospheric Hazard, Temperature Extremity (slowed), Storied | `05` "Settler State" |
| `legend_value` — a *list* of completed sites/achievements (not a scalar); summed by Frontier Legends; feeds personnel-file / end-of-run display | `05` "Settler State"; `06` "SEED Factions" |
| `experience` — per-task-group stack count 0–3, earned | `05` "Settler State", "Experience" |
| `aptitude` — per-bucket level −3..+3, innate, fixed at Crew Selection | `05` "Settler State", "Aptitude" |
| `gourmet_recipes` — list of personally-invented Gourmet dishes; only this settler cooks them, only while assigned to Kitchen | `05` "Settler State" (mechanic in `04` "Kitchen" — System 8) |
| Crew Selection — one-time pre-run screen, before Farm Site Selection; each candidate crew = full settler set with independently-rolled Aptitude; selecting locks Aptitude across all 6 buckets for the run | `03` "Crew Selection" |
| Archetypes, per-settler independent: Average 70% / Jack-of-several-trades 20% / Savant 10%, each with bucket-value + total constraints | `03` "Crew Selection" |
| Per-settler (not per-crew) balance rationale | `03` "Crew Selection" |
| Crew reroll — free, uncapped, no cost | `03` "Crew Selection" |
| Crew Selection presentation — plain-language per-bucket readouts, never raw levels/formulas | `03` "Crew Selection" |
| Aptitude — 6 buckets, each nesting whole Experience groups (never split); first five buckets ±15%/level speed (additive to ±45%, additive with Experience); Exploration bucket a per-level effect ladder with mirrored negatives | `05` "Aptitude" |
| Exploration Aptitude stacks *additively not sequentially* with Storied (`p_new = p + 0.50(1-p)` if both; flat ±1 adds normally) | `05` "Aptitude" |
| Experience — earned, stacking, permanent, per task group; +15%/stack to 3 (+45%); applies only to non-exploration assignable tasks | `05` "Experience" |
| Experience groups — Farming (7 bldgs), Mining (3), Kitchen / Trapping / Clear-Cutting (each), Surveys (Basic+Deep shared), each Fabrication building separately, each Research/Utilities building separately | `05` "Experience" |
| Experience gain — one stack/group/season if *any* work performed that season; injury-shortened season counts; zero-work season doesn't | `05` "Experience" |
| Kitchen max Experience stack — prerequisite for Gourmet "moment of brilliance" | `05` "Experience"; `04` "Kitchen" |
| Storied — positive `status_effect` once `legend_value` sum crosses a threshold (TBD); permanent | `05` "Storied" |
| Storied effects — +15% speed (Production buildings + Trapping/Clear-Cutting); +1 exploration numeric-range upper bound; `p_new = p + 0.25(1-p)`; `r_new = 0.75 r_old` | `05` "Storied" |
| Injuries taxonomy — shared (claimed) across exploration / Atmospheric Hazard / Temperature Extremity | `05` "Injuries" |
| Semi-Permanent — no standalone debuff; quarter-season heal each; serial without Medical Bay, parallel with; barred from Low/High-risk exploration, eligible No-risk (small success penalty on probabilistic ones); on-site work delayed until recovered (recovery occupies first portion of Mid-Sim) | `05` "Injuries" |
| Permanent (4 types) — Loss of leg (bars Outdoor/Fieldwork), Loss of arm (50% speed except non-manual + reduces any probabilistic exploration success), Brain damage (bars non-manual set; bars Low/High-risk exploration), Severe burns (75% speed on Manual Labor) | `05` "Injuries" |
| Task groupings — Outdoor/Fieldwork; Manual Labor (superset); non-manual residual (Research Lab, Medical Bay, Scanner Station, Tinkerer's Workshop) | `05` "Injuries" |
| Risk tier gates severity — Low-risk failure → SP or nothing; High-risk failure → {nothing / SP / permanent / death} | `05` "Injuries", "Risk Spectrum" |
| Negative outcomes only on task *failure* for real success/fail tasks; guaranteed-success tasks instead carry a separate independent risk roll | `05` "Injuries", "Risk Spectrum" |
| Death — permanent roster removal, same mechanic as starvation-death; starvation "who dies" drawn uniformly at random, excluding settlers on Exploration Tasks | `05` "Risk Spectrum", "Injuries", "Food & Nutrition" |
| Injury/death on guaranteed-success tasks earns a Frontier Legends bonus — large for injury, moderate for death | `05` "Risk Spectrum" |
| Narrative-only (zero mechanical effect) — personnel-file blurb on first appearance; single death-acknowledgment line; no ongoing barks; exclusive-pair Relationships via Transmission | `02` "Settler story presence", "Narrative-Only Flavor" |
| Settlers know they are AI-directed; prestigious/competitive selection (astronaut-or-better) | `02` "SEED's Culture, and the Player's Role" |

**Boundary notes (ambiguous ownership).**
- **`current_assignment` + sticky/locked** — the state *field* is here; the assign gesture and Worker Roster are System 3.
- **Injury *causes*** — exploration risk rolls (System 10), Atmospheric Hazard / Temperature Extremity (System 11). Only the taxonomy and effects are here.
- **Death by starvation** — trigger and "who dies" lottery are System 8; the roster-removal mechanic is here.
- **`gourmet_recipes`** — state field here; the Gourmet unlock + Seasonings are Systems 8 / 7.
- **Crew Selection** — text lives in `03`, is functionally part of System 12's run-start flow; this system owns the Aptitude profiles it produces.
- **`legend_value`** — per-settler state here; the Frontier Legends `HardSiteAchievement` / `StandoutSettlerRecord` formulas are Scoring (`06`).

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. Injury-acquisition distribution is undefined.** `05` "Injuries" says High-risk failure "can produce any of {nothing / SP / permanent / death}" and to "roll a negative-outcome type" — but gives no weights per risk tier, no rule for *which* of the 4 permanent types is selected (uniform? task-flavored?), and no rule on whether one failed roll can inflict more than one injury. Blocks every injury outcome. *Possible direction: a per-risk-tier weighted table over {nothing / SP / permanent / death}, a uniform (or task-flavored) pick among the 4 permanent types, one injury per failed roll.*
- **G-S2. Multiple concurrent permanent injuries have no stacking rule.** Arm-loss (50% speed) + severe-burns (75% speed) is reachable (neither bars re-sending on a High-risk task); so is arm-loss + brain-damage. Do the multipliers compound (→ 37.5%)? Do eligibility bars intersect to a possible "no eligible assignment at all" state (leg-loss + brain-damage leaves only Kitchen / Robotics Assembly / Stone Processing / Carpenter's Shop; is even that guaranteed)? Unspecified. *Possible direction: speed multipliers compound multiplicatively; eligibility bars intersect; explicitly permit the "no eligible assignment" end state (settler still eats, contributes nothing).*

### Should-clarify (does not block this system alone, but two systems depend on it)

- **G-C1. The "shared taxonomy" claim is only half-realised.** `05` "Injuries" and "Risk Spectrum" both assert the SP/permanent taxonomy is "shared across every source of harm (exploration, Atmospheric Hazard, Temperature Extremity)." But `06` "In-Simulation Hazard Events" has Temperature Extremity inflict a slowing `status_effect` (mild) or a death roll (extreme), and Atmospheric Hazard inflict a fixed-duration halving `status_effect` — *neither ever produces an SP or permanent injury*. So in practice the SP/permanent ladder is exploration-only; hazards share only *death*. Resolve: can hazards maim, or only slow/kill? (→ §4 CS1; the Hazards audit should raise this from its side too.)

### Structural — smaller

- **G-S3. SP on-site recovery vs. the continuous-rate production model.** "recovery period occupies the first portion of that season's Mid-Sim window" is fine for one SP injury; with 3+ serial SP injuries (no Medical Bay) the settler works only the final quarter, and the interaction with the plant-crop three-phase cycle and with Effort-stacking toward a production cap (does the *site* stall, or just this worker's Effort?) is unstated. *Possible direction: model as the worker contributing 0 Effort for the first k quarter-seasons, normal Effort after — everything downstream already handles a variable-Effort worker.*
- **G-S4. The "idle" `current_assignment` value has no defined behaviour.** Enumerated in `05` "Settler State"; nothing says an idle settler still eats (System 8 implies yes), accrues nothing, and carries no penalty. *Possible direction: idle settler eats normally, accrues nothing, no penalty — a legitimate plan.*
- **G-S5. Storied and permanent injuries are `status_effect` list entries alongside clearable ones** (Atmospheric Hazard, Temperature Extremity slowed) with no rule distinguishing non-expiring from transient entries, or preventing a gained Storied from being "cleared." *Possible direction: mark Storied and permanent injuries non-expiring; only Atmospheric/Temperature entries have clear conditions.*

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** Storied's `legend_value` threshold. `05` "Storied".
- **G-N2.** SP-injury No-risk success-chance penalty magnitude. `05` "Injuries".
- **G-N3.** Low/High-risk negative-outcome distribution weights. `05` "Injuries".
- **G-N4.** Crew size (3 vs. 4), and whether it varies by planet type / meta-progression. `05` "Settlers"; `03` "Crew Selection".
- **G-N5.** Jack-of-several-trades / Savant per-bucket value-generation distributions; whether "centered on −1" is a generator target or descriptive. `03` "Crew Selection".
- **G-N6.** Frontier Legends per-site legend-values; injury-vs-death bonus magnitudes. `06` "SEED Factions"; `05` "Risk Spectrum".

### Cross-check with `DESIGN_TODO.md`

`DESIGN_TODO.md` flags (under "Remaining numeric TBDs from the Settler State / Injuries / Storied design pass"): Storied's `legend_value` threshold; Temperature Extremity extreme-exposure death probability; Trapping / Clear-Cutting per-settler speed rates. It does **not** flag G-S1 (injury-acquisition distribution), G-S2 (concurrent permanent-injury stacking), G-C1 (hazard-injury question), or G-S4/G-S5. Recommend adding these.

---

## 3. Internal consistency

- **IC1. A permanent arm loss bars *fewer* exploration tasks than a temporary SP sprain.** Arm loss "bars nothing" (only cuts speed and probabilistic success); SP injury bars Low- and High-risk exploration outright. So an arm-lost settler can still be sent on a High-risk task; an SP-injured one cannot. Internally consistent, but counter-intuitive — likely intended (SP = "let them heal first"; permanent = "this is their new normal"), and worth being a conscious call rather than an accident. (→ NTH1.)
- **IC2. The plain-language string "up to 1 more item from Exploration" is prescribed by both Storied (+1 upper bound) and Exploration Aptitude +3 (+1 to resource-outcome maximums).** When both are active the flat bonuses "add normally" (→ +2), but the tooltip convention still shows "up to 1 more," understating the effect exactly where two sources stack. (→ SF9.)
- **IC3. Storied's speed bonus enumerates assignment types** ("Production-building assignments, and on Trapping/Clear-Cutting") and silently omits Surveys — correct today (Surveys are one-shot reveals with no speed axis), but an enumeration that will desync if a speed-based Standing Assignment is ever added. (→ NTH; same maintenance-coupling shape as CS4.)
- **IC4. Savant "every other bucket unconstrained" vs. "total always summing to exactly −3."** With one bucket forced to +3 and one to −3, the remaining four must sum to exactly −3 — so the last is determined by the other three. "Unconstrained" is loose wording; the generator has 3 free buckets, not 4. Cosmetic. (→ NTH2.)
- **IC5. Jack-of-several-trades "3 buckets at +2" cannot reach the stated total.** 3×(+2) = +6; the remaining 3 buckets (values in {−1, −2}) sum at best to −6, giving a total of exactly 0 — never "centered on −1" or below. The "2–3 buckets at +2" and "total between −2 and 0, centered on −1" constraints are jointly satisfiable only at the 2-bucket end. (→ NTH; content-pass clarification.)

---

## 4. Cross-system consistency

- **CS1 (→ G-C1). Injury causes across `05` and `06` disagree on what they inflict.** `05` "Injuries" claims a taxonomy shared by exploration + Atmospheric Hazard + Temperature Extremity; `06` "In-Simulation Hazard Events" has those hazards inflict only status effects and (extreme Temp) a death roll. Either `05`'s intro overstates the sharing, or `06`'s hazard sections are missing SP/permanent injury outcomes.
- **CS2. `status_effect` is a list here, but the Worker Roster shows a single "hazard-affected" icon** "matching the worker's active `status_effect`" (`03` "Worker Roster (UI)"). Which entry wins when a settler is both Atmospheric-Hazard-affected and Temperature-slowed is unspecified. (Seam with System 3.) (→ SF5.)
- **CS3. The starvation lottery can delete the standout settler.** `05` "Food & Nutrition" — "who dies is drawn uniformly at random … excluding any settler currently on an Exploration Task." That can remove the settler carrying the largest `legend_value` sum, which drives `StandoutSettlerRecord` (`06` "Frontier Legends"). Whether a dead settler's accumulated `legend_value` still counts toward the end-of-run `HardSiteAchievement` / `StandoutSettlerRecord` totals is implied ("death is honored") but never stated. (→ SF4.)
- **CS4. Experience groups and Aptitude buckets hard-code the current building catalogue** (Grain Field … Tinkerer's Workshop). Any building added / renamed / recategorised in System 7 silently desyncs both lists. Maintenance coupling; same shape as the pilot's CS4.
- **CS5. Crew Selection locks Aptitude before Farm Site Selection reveals the site.** The player picks Mining / Surveys / Exploration Aptitude before seeing terrain and Surface deposits (`03` "Farm Site Selection"). Intended — planet *type* is fixed earlier at filament-scan — but confirm the player has enough planet-type information at Crew Selection for the Aptitude tradeoff to be a real decision. (Seam with System 12.)
- **CS6. Three sources all modify "production speed" and the Site Panel must sum them.** This system defines Aptitude(bucket) + Experience(group) + Storied(+15% flat) as additive; `03` "Site Panel (UI)" shows "one combined number" with the breakdown in a tooltip. Consistent — but the combined value can reach +105% (+45 +45 +15), which the "+X% Farming speed" plain-language readout then has to display. (→ §6 P1.)

---

## 5. Story & world consistency

- **Reinforcing.** Per-settler Aptitude + the prestige/competitive-selection framing (`02` "SEED's Culture") fit — a hand-picked expert crew genuinely differs person to person, and `02` brainstorm item J ("motivations left to vary per settler") is echoed by the archetype spread. Storied ↔ Frontier Legends ↔ the Kiran ethos (`02` "The Kiran Incident"; `06` "Frontier Legends") is a clean mechanic/story tie.
- **Tension — Savant vs. the selection fiction.** `02` establishes settlers are "not desperate volunteers" but a "highly selective, competitive pool." A Savant with a guaranteed net −3 skill profile and a −3 bucket is a deliberately lopsided recruit; a prestige program fielding someone net-negative across their profile is a mild stretch. Framable ("a specialist accepted for one extraordinary strength"), currently unaddressed. (→ NTH3.)
- **Tension — the free, uncapped Crew reroll** reads oddly against selection being "comparable to becoming an astronaut." Mechanically fine (pre-run, nothing to spend); a one-line frame (SEED shortlisting candidate teams) would cover it. (→ NTH3.)
- **Missed reinforcement — permanent injuries have no narrative surface.** `02` "Settler story presence" deliberately caps death at one acknowledgment line and bars ongoing barks — but limb loss / brain damage get *nothing*, not even a personnel-file note. A single personnel-file line on permanent injury matches the existing blurb/death-line treatment without reopening "no ongoing dialogue." (→ NTH4.)
- **Relationships flavor** (`02` "Narrative-Only Flavor") is correctly walled off — no mechanical hook leaks into Settler State. Confirmed clean.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Difficulty from breadth of tradeoffs* — Crew Selection's per-settler archetype balance and the 6-bucket allocation are a pure strategy puzzle, zero execution skill.
- *Forgiving of individual mistakes* — Experience and Storied are permanent, never decay; a bad season doesn't erase settler investment, and the roguelike reset covers a lost crew.
- *Randomization gated behind an explicit commitment* — Crew Selection RNG is a distinct pre-run step; the reroll is explicit and irreversible-in-effect (the old crew can't be recovered), and selecting a crew is the commitment — matches `01`'s randomization rule.
- *Numbers stay small* — Aptitude −3..+3, Experience 0–3, 3–4 settlers, 6 buckets. Legible.

**Risks / violations:**
- **P1. Numbers stay small — stacked speed modifiers.** Aptitude (±45%) + Experience (+45%) + Storied (+15%) → up to +105% on one assignment (CS6). Each source is small, but the *combined* Site Panel readout is exactly the kind of number `01` says to watch. Flag for the balance pass.
- **P2. Failure legibility — permanent-injury effects.** When a settler returns brain-damaged (barring most assignments), the player must see on the settler *which* assignments are now barred/slowed and *that it was an accepted risk* — not discover it by trying to assign them and failing. `05` gives the direction; the per-injury effect needs surfacing. (→ SF6.)
- **P3. "Luck must be distinguishable from certainty."** On guaranteed-success-with-independent-risk tasks, a settler can complete the discovery and still be hurt by the separate roll. `05` "Risk Spectrum" says the rolls "never interact" but doesn't require the outcome UI to report them separately, so "got the vein, broke a leg" could read as "the task failed." (→ SF7; shared with System 10.)
- **P4. Plain-language tooltip loses information when sources stack** (IC2). (→ SF9.)
- Not engaged: units-unspecified; colour-not-sole-channel (Aptitude readouts are text; status-effect icons are System 3); normalize-before-combining (Frontier Legends self-normalizes); touch/mouse parity; dexterity-timing.

---

## 7. Player legibility

- **Aptitude** — legible via the plain-language per-bucket readout, provided every non-zero bucket is shown (not just positives), at Crew Selection and on the settler.
- **Experience gain rule** — "one stack per season of any work in the group" is not self-evident; needs a one-line surface on the settler screen alongside current stacks-per-group.
- **Storied onset** — crossing an invisible `legend_value` threshold mid-run, after which a settler is permanently better. Needs an explicit "X is now Storied" moment (Transmission or log line) or the player won't know why the numbers moved. Not currently specified. (→ SF8.)
- **Permanent-injury effects** — must be shown on the settler (P2 / SF6).
- **SP-injury recovery delay** — the roster needs a "recovering until ~¼ season" cue so a low partial-season yield isn't mysterious.
- **Why a specific settler died in a starvation lottery** — must read as random, not "the game targeted my best one." (Shared with System 8.)
- **Crew Selection** — the screen should state explicitly that Aptitude is locked for the whole run and cannot be trained (only Experience can). Currently only implied by "innate rather than earned." (→ NTH5.)

---

## 8. Fun / scope risk

- **Injuries is the complexity centre.** SP vs. permanent, 4 bespoke permanent types, two task groupings + a non-manual residual, serial-vs-parallel healing, risk-tier severity gating, failure-only triggering, plus the separate independent-risk roll for guaranteed tasks — a large surface for something that fires rarely (High-risk failures). *Cut-or-simplify candidates:* (a) collapse the 4 permanent types to 2 — a "mobility" impairment (bars/limits fieldwork) and a "cognition/dexterity" impairment (bars/limits skilled work) — keeping the strategic texture at roughly half the rules; (b) drop serial-vs-parallel SP healing, make Medical Bay a flat SP-heal-time reduction — the distinction only bites in the uncommon multi-SP case. Worth an explicit decision.
- **Aptitude (6 buckets) + Experience (~15 groups) is a two-tier taxonomy the player must hold in their head** to assign well. The buckets-nest-whole-groups rule keeps it learnable, but this is the system most at risk of straining "a passable plan should always be quick to reach" in the late game, when a returning player is tracking Experience across many settlers and groups. Note for playtest.
- **Storied is low-overhead and well-judged** — one threshold, a few flat modifiers, self-limiting because Legend outcomes are rare. Keep.
- **Crew Selection archetypes** — clean, high-value, low-complexity decision. Keep.
- **Narrowing risk — Savant grinding.** A player who learns Savant crews are strictly better (one huge strength, dump the −3 where it's never assigned) could reroll for all-Savant. The design tries to prevent this (per-settler balance, −3 total, ~0.1% for a full-Savant trio); whether the −3 total stings enough is a balance-pass question, and presentation should not encourage the grind.

---

## 9. Findings summary

### Blockers

- **B1.** Injury-acquisition distribution undefined — no {nothing / SP / permanent / death} weights per risk tier, no rule for which of the 4 permanent types is picked, no rule on one-failure-multiple-injuries. (§2 G-S1 — `05` "Injuries")
- **B2.** Multiple concurrent permanent injuries have no stacking rule — do speed cuts compound, do eligibility bars intersect to a possible "no eligible assignment" state. (§2 G-S2 — `05` "Injuries")

### Should-fix

- **SF1.** Resolve whether Atmospheric Hazard / Temperature Extremity can inflict SP or permanent injuries or only status effects + death — `05` claims a shared taxonomy that `06`'s hazard sections don't deliver. (§2 G-C1, §4 CS1 — `05` "Injuries" / "Risk Spectrum" vs `06` "In-Simulation Hazard Events")
- **SF2.** Specify SP on-site recovery as a variable-Effort model (0 Effort for the first k quarter-seasons, normal after) so it composes with the continuous-rate production model, the plant-crop phase cycle, and Effort-stacking. (§2 G-S3 — `05` "Injuries" vs `03` "Production Model")
- **SF3.** Define the "idle" `current_assignment` state — eats normally, accrues nothing, no penalty; a legitimate plan. (§2 G-S4 — `05` "Settler State")
- **SF4.** State whether a dead settler's accumulated `legend_value` persists into the end-of-run Frontier Legends `HardSiteAchievement` / `StandoutSettlerRecord` totals. (§4 CS3 — `05` "Food & Nutrition" vs `06` "Frontier Legends")
- **SF5.** Specify which `status_effect` list entry the Worker Roster's single "hazard-affected" icon shows when a settler carries more than one. (§4 CS2 — `05` "Settler State" vs `03` "Worker Roster (UI)")
- **SF6.** Require permanent-injury effects (which assignments barred / slowed) to be surfaced on the settler, not inferred from failed assignment attempts. (§6 P2, §7 — `05` "Injuries"; `01` failure-legibility)
- **SF7.** Require the exploration outcome UI to report the success roll and the independent risk roll separately, so "completed the discovery but got hurt" doesn't read as "failed." (§6 P3 — `05` "Risk Spectrum"; `01` "luck must be distinguishable from certainty")
- **SF8.** Add an explicit "X is now Storied" surface (Transmission or log line) at threshold crossing. (§7 — `05` "Storied")
- **SF9.** Fix the plain-language tooltip understatement when Storied's +1 and Exploration Aptitude's +1 stack to +2 ("up to 1 more item from Exploration" is then wrong). (§3 IC2, §6 P4 — `05` "Storied" / "Aptitude")
- **SF10.** Mark Storied and permanent injuries as non-expiring `status_effect` entries, distinct from clearable Atmospheric/Temperature entries. (§2 G-S5 — `05` "Settler State")
- **SF11.** Add G-S1, G-S2, and the hazard-injury question (SF1) to `DESIGN_TODO.md`'s Settler/Injuries TBD list. (§2 cross-check — `DESIGN_TODO.md`)

### Nice-to-have

- **NTH1.** Make the "permanent arm loss bars fewer exploration tasks than a temporary SP sprain" asymmetry a conscious, noted call. (§3 IC1)
- **NTH2.** Tighten "every other bucket unconstrained" in the Savant archetype — the sum-to-−3 rule leaves 3 free buckets, not 4. (§3 IC4 — `03` "Crew Selection")
- **NTH3.** Give the Savant archetype and the uncapped Crew reroll a one-line fiction frame consistent with the prestige/competitive-selection lore. (§5)
- **NTH4.** Add a one-line personnel-file note on permanent injury, matching the existing blurb/death-line treatment. (§5)
- **NTH5.** State explicitly at Crew Selection that Aptitude is locked for the run and cannot be trained (only Experience can). (§7)
- **NTH6.** Watch the stacked speed-modifier readout (Aptitude + Experience + Storied, up to ~+105%) against "numbers stay small" in the balance pass. (§4 CS6, §6 P1)
- **NTH7.** Reconcile the Jack-of-several-trades "3 buckets at +2" case, which cannot reach the stated "centered on −1" total. (§3 IC5 — `03` "Crew Selection")
- **NTH8.** Storied's enumerated speed-bonus assignment list will desync if a speed-based Standing Assignment is added. (§3 IC3)
- **NTH9.** Experience groups / Aptitude buckets hard-code the building catalogue; adding or recategorising a building in System 7 silently desyncs both. (§4 CS4)
- **NTH10.** Confirm the player has enough planet-type information at Crew Selection (before Farm Site Selection) for the Aptitude tradeoff to be a real decision. (§4 CS5)

### Defer (numeric / content-pass)

- **D1.** Storied's `legend_value` threshold. `05` "Storied".
- **D2.** SP-injury No-risk success-chance penalty magnitude. `05` "Injuries".
- **D3.** Low/High-risk negative-outcome distribution weights. `05` "Injuries".
- **D4.** Crew size (3 vs. 4) and whether it varies by planet type / meta-progression. `05` "Settlers"; `03` "Crew Selection".
- **D5.** Jack / Savant per-bucket value-generation distributions. `03` "Crew Selection".
- **D6.** Frontier Legends per-site legend-values; injury-vs-death bonus magnitudes. `06` "SEED Factions" / "Risk Spectrum".
