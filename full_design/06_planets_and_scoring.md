# Planets & Scoring

## Exoplanet Types

### Design Philosophy
Each planet type should function like a character class — it should be impossible to
apply the same general approach to every planet, without any planet reducing to a
single viable strategy or being strictly harder/easier than another. This is
achieved with a **distribution of pressure across four strategy dimensions**, not a
1:1 planet→dimension mapping: every planet type has some pressure on every
dimension, just weighted differently — a dominant pressure or two, moderate
pressure elsewhere, minimal pressure on whatever the planet makes easy. This directly
realizes the "variety comes from different scenarios, not reshuffled numbers"
replayability idea flagged early in the design-principles work.

### The Four Strategy Dimensions
- **A — Protection/Enclosure.** Weather-protection shielding, indoor/enclosed tech
  (Advanced Greenhouse-tier investment).
- **B — Biosphere Integration.** The Local Agriculture path — hybridizing with
  native flora/fauna, open-air farming that works *with* the planet's ecosystem.
- **C — Synthesis/Self-Sufficiency.** Heavy fabrication/synthesized production
  (deep fabrication chains, hydroponics, drone-driven output) to compensate for a
  poor natural substrate.
- **D — Energy Management.** Energy production diversity and budgeting under
  scarcity. Given real teeth by the temperature-control mechanic below — without
  something to actually manage, this dimension would just be a label.

**Temperature/Protection/Energy coupling:** enclosed or protected structures (A)
carry a passive Energy upkeep cost (D) that scales with how extreme the planet's
ambient temperature is — significant on both very hot and very cold planets (keeping
interiors cool vs. warm), near-zero on temperate ones. Always explicitly listed when
it has an impact, never a hidden drain. This is what naturally couples A and D
together on extreme-temperature planets while leaving them mostly uncoupled
elsewhere, without needing to hand-author that coupling per planet.

### Initial Planet Types
Four to start, each with a qualitative identity below; the exact A/B/C/D pressure
distribution per planet is still to be worked out (open thread — see below).

- **Volcanic** — hostile atmosphere, extreme heat, harsh weather. Forces the Advanced
  Greenhouse path (B is low). High A (constant protection needed) and, via the
  temperature coupling, high D. Rich in structural/electronics ore and (per the
  hazard↔resource correlation principle) shielding-relevant rare materials.
- **Verdant/Temperate** — hospitable atmosphere, mild hazards, rich native
  biosphere. Favors the Local Agriculture path (B is high). Low A and low D (little
  climate control needed). Scarcer rare/advanced materials — tech progression here
  has to come from somewhere other than raw material abundance.
- **Arid/Desert** — poor farming substrate (water/organic scarcity) but abundant
  baseline Energy (strong sun). High C (heavy reliance on synthesis/hydroponics to
  compensate for the substrate); likely low D, since abundant Energy offsets what
  upkeep exists; low B (little native biosphere to integrate with).
- **Frozen/Ice** — weak/distant sun, extreme cold. High D (Energy is the
  constrained resource) and high A (enclosure is mandatory, via the same
  temperature-coupling logic as Volcanic, just for cold instead of heat). Low B.

> **Open questions:** the exact quantitative pressure distribution (dominant /
> moderate / minimal) per planet across all four dimensions is not yet defined —
> flagged to return to after Exploration is worked through. Terrain layout and
> Energy base regeneration rates per planet are also still open.

### Hazard Priors (Safeguard Coalition's TrueRisk Values)
Feeds the Safeguard Coalition's Bayesian `MatchedRisk` calculation (see SEED
Factions in Win/Lose Conditions). Each value is a **probability that the danger
proves insurmountable for humans**, not just a severity/presence rating. Granular
sub-factors exist to inform event-spawning design (storm frequency, etc.) even
though the actual scoring formula only uses the two top-level axes
(`TrueRisk(Weather)`, `TrueRisk(Bio-hazard)`), each the **arithmetic mean** of its
sub-factors.

**Weather** — Storm Severity/Frequency, Temperature Extremity, Atmospheric Hazard
(toxic/corrosive/thin atmosphere, distinct from temperature or storms):

| Planet | Storm | Temp | Atmo | **TrueRisk(Weather)** |
|--------|-------|------|------|------------------------|
| Volcanic | 0.5 | 0.6 | 0.5 | **0.53** |
| Verdant/Temperate | 0.1 | 0.05 | 0.05 | **0.07** |
| Arid/Desert | 0.3 | 0.4 | 0.15 | **0.28** |
| Frozen/Ice | 0.2 | 0.65 | 0.2 | **0.35** |

**Bio-hazard** — Pathogen Threat (microbial and viral risk merged into one
sub-factor — they ended up identical in reasoning and value for all four planets, so
tracking them separately added bookkeeping with no distinction; can be split again
later if a future planet type ever wants to differentiate them) and
Toxic/Parasitic Organism Threat (contact-based danger from native life, distinct
from infection-based Pathogen Threat):

| Planet | Pathogen | Toxic/Parasitic | **TrueRisk(Bio-hazard)** |
|--------|----------|------------------|----------------------------|
| Volcanic | 0.1 | 0.1 | **0.10** |
| Verdant/Temperate | 0.4 | 0.45 | **0.43** |
| Arid/Desert | 0.15 | 0.2 | **0.18** |
| Frozen/Ice | 0.1 | 0.05 | **0.08** |

Extreme physical environments (Volcanic, Frozen) suppress biological complexity and
thus bio-risk, while the mild/lush Verdant planet trades weather-safety for
bio-risk — an intentional inverse relationship, not a coincidence of the numbers.

### Data-Gathering Mechanism (Beta Distribution, Hidden From the Player)

**Design goal:** the player's experience of data-gathering should never involve
statistics, sampling, or visible math — just plain yes/no reports arriving over
time. All of the machinery below is a hidden backend computation that turns those
reports into `MatchedRisk` and `Confidence` values; the player never sees `a`, `b`,
or a distribution.

**Mechanism.** Each hazard sub-factor (five total: Storm, Temperature Extremity,
and Atmospheric Hazard under Weather; Pathogen Threat and Toxic/Parasitic Organism
Threat under Bio-hazard — same breakdown as the TrueRisk table above) is tracked as
a **Beta(a, b) distribution**, updated with simple counters — no real sampling or
statistics library needed at runtime:
- **Prior**: `a₀, b₀` chosen so the prior mean `a₀/(a₀+b₀)` matches that
  sub-factor's per-planet-type value from the table above, with `a₀+b₀` kept small
  (a weak, easily-overwhelmed starting guess) — e.g. `a₀=1, b₀=1` gives a mean of
  0.5 and is easily updated by a handful of reports.
- **Each report is a success or failure**, incrementing `a` or `b` by 1
  respectively — a "success" means the hazardous condition was observed in that
  report (e.g. a storm occurred), "failure" means it wasn't.
- **`MatchedRisk(hazard) = a / (a+b)`** — the Beta posterior mean, converging
  toward the true value as reports accumulate. This is what actually feeds the
  Safeguard `Score(hazard)` formula.
- **`Confidence(hazard) = ν / (ν+k)`**, where `ν = a+b` (total evidence, prior
  included) and `k` is a tunable constant (playtestable, same as other flattening
  constants in this design) controlling how many reports it takes to reach a given
  confidence level. **Deliberately based on `ν` (evidence count) rather than raw
  distribution variance** — variance conflates "how much data has been gathered"
  with "how far the mean sits from 0.5" (`Var = μ(1-μ)/(ν+1)`), meaning an obvious
  extreme hazard would appear falsely confident with very little data, for reasons
  the player can't perceive since the true value is hidden — a legibility problem.
  Basing Confidence on `ν` alone means every report contributes predictably and
  equally, regardless of which way it leans or what the hidden true value is.
  `Confidence(hazard)` is what actually feeds the `Data(hazard)` term in
  `Score(hazard) = Data(hazard) + MatchedRisk(hazard) × MatchedPreparedness(hazard)`
  from [SEED Factions](06_planets_and_scoring.md#seed-factions) below — i.e. `Data(hazard)` **is** `Confidence(hazard)`.
- **Implementation footprint**: just two running counters per sub-factor (ten total
  across all five). No distribution objects, no sampling.

**Per-sub-factor data sources, success/failure definitions, and player-facing text:**

| Sub-factor | Data source | Success | Failure | Player sees |
|---|---|---|---|---|
| Storm Severity/Frequency | Scanner Station's Weather Sensing mode (see [Farm/Production](04_buildings_and_economy.md#farmproduction); staffed at base tier, one reading/season active) or a weather balloon (exploration task) | Storm event detected in the window | Calm conditions | *"Storm activity detected"* / *"Conditions calm."* |
| Temperature Extremity | Same Scanner Station Weather Sensing mode, or a dedicated probe | Window registered a temperature swing extreme enough to threaten human safety | Temperatures stayed within safe range | *"Extreme temperature swing recorded"* / *"Temperatures within safe range."* |
| Atmospheric Hazard | Atmospheric sampling (exploration task) | Sample contained toxic/corrosive compounds above a safe threshold | Clean sample | *"Atmospheric sample: hazardous compounds detected"* / *"Atmospheric sample: clean."* |
| Pathogen Threat | Bio-survey exploration task or Medical/Research facility | Sampled organism/environment tested positive for a dangerous pathogen | Clean sample | *"Pathogen detected in sample"* / *"No pathogens detected."* |
| Toxic/Parasitic Organism Threat | Exploration tasks encountering wildlife | Encountered organism proved dangerous (venomous/toxic) | Organisms encountered were benign | *"Dangerous organism encountered"* / *"Wildlife encountered was benign."* |

Individual reports appear as short log entries (fits the Transmissions record or
simulation log, consistent with existing UI patterns). The derived
`Confidence`/`MatchedRisk` values surface separately as an inspectable summary stat
per hazard sub-factor (e.g. in a Planetary Assessment panel), updating quietly as
reports accumulate — never something the player calculates themselves.

**This same underlying mechanism is reused for other factions' data-collection
scoring**, not just Safeguard — Stewardship Caucus's `EcologicalData` (see SEED
Factions in Win/Lose Conditions) applies it in simplified form, needing only the
evidence-count term (no `MatchedRisk`-style mean), since some data-gathering
factions care about reaching a confident answer regardless of what that answer is.

### In-Simulation Hazard Events

Until now, Weather/Bio-hazard hazards were purely things the player *surveyed
and scored against* — this section makes them actually happen during
simulation, with real gameplay consequences, closing the gap flagged when
Medical Bay's PPE recipe was designed (see Buildings & Economy's [Protection](04_buildings_and_economy.md#protection)).

**Trigger — reuse the existing hidden draw, don't add a new one.** The
Data-gathering mechanism above already implicitly simulates "did this hazard
condition occur in this observation window" as a hidden Bernoulli draw (that's
literally what generates a report's success/failure). That same draw is what
triggers an in-simulation event — a storm *report* and a storm *actually
happening* are the same event, not two separate rolls.

**Telegraphing scales continuously with `Confidence(hazard)`** — reusing the
value already computed for scoring, not a separate building-gated tier system:
- **Near-zero confidence** (run start, before any surveying): no per-season
  warnings. Instead, a one-time **SEED summary transmission** at run start
  surfaces the planet-type's *prior* values directly (narrativized, but
  showing the actual Bayesian prior numbers or a close translation) — framed
  in-fiction as SEED's institutional knowledge about planet-type archetypes
  from prior missions, not this specific planet. Gives every run a baseline
  sense of what to expect from turn one, satisfying "failure should be
  legible" even with zero investment. Events at this stage happen with no
  specific advance notice.
- **Low-to-moderate confidence**: vague per-season warnings ("elevated risk
  of severe weather this season"), short lead time — appearing right before
  the affected season's planning phase.
- **High confidence**: precise, reliable warnings — which sub-factor, roughly
  how severe — with more lead time (illustrative: a season or two ahead).

All delivered via the existing **Transmissions** mechanic (see Story & World's
[Gameplay-Story Integration](02_story_and_world.md#gameplay-story-integration)), which was already specifically designed for this
purpose — this section is that mechanic's concrete realization, not a new
system layered on top of it.

**Event severity — a coarse band, shared by Storm and Temperature
Extremity.** Alongside the occurrence trigger above, a triggered event also
rolls one of two severity bands, **mild** or **extreme**, weighted by that
hazard's `TrueRisk` (a worse-off planet skews toward more extreme events, not
just more frequent ones — reusing a value already tracked rather than adding
a new dial). This is what gives "a strong enough storm" or "the real
temperature passing a threshold" concrete meaning below, instead of
consequence being driven purely by the settlement's static Preparedness
coverage as before.

**Concurrency.** Storm and Temperature Extremity are the only two hazard
sub-factors that manifest as a discrete Mid-Sim event at all — Atmospheric
Hazard (also Weather) is a continuous passive-stock/PPE check with no
start/duration event, and Bio-hazard's two sub-factors (Pathogen Threat,
Toxic/Parasitic Organism Threat) only ever resolve through individual
exploration-task encounters, never a settlement-wide event. Each of Storm
and Temperature Extremity triggers **at most once per season**, tied
one-to-one to that season's single evidence-gathering report for that
sub-factor (see Data-Gathering Mechanism's "one reading/season active");
there's no scenario where the same hazard type fires twice in one season.
That leaves a ceiling of at most two discrete events in a season — one
Storm, one Temperature Extremity — each independently rolled and
independently severity-banded. **When both occur and their windows overlap
at the same site, their consequences stack independently** — each hazard's
consequence chain (Energy-funded shield coverage, production
slowed/stopped/destroyed, settler status-effect/death) runs exactly as
specified in its own subsection below, with no special-cased interaction
between them. The one edge case this implies: if one hazard's consequence
already destroyed a Farm/Production site, the other hazard's destruction
check for that same site simply has nothing left to act on — the slot is
already empty, not destroyed twice.

**Temperature Extremity** — average temperature and consequence, in full:
- Every candidate farm site gets its own **Average Temperature**, sampled at
  world-gen from a distribution parameterized by the planet type's
  `TrueRisk(Temp)` (higher TrueRisk, wider/more extreme spread) — shown to
  the player at Farm Site Selection (see Core Loop & Grid) as a known site
  feature. This is a per-*site* draw, not a planet-type-level value: the
  distribution's shape stays fixed once the planet type is chosen, only
  where a specific candidate's sample lands within it varies — the same
  category of variance as deposit placement, not a new hazard-prior lever.
  All temperature is tracked against one universal human comfort target,
  **72°F** (see Design Principles' Units Unspecified for why real
  Fahrenheit/Celsius is used here rather than an abstracted scale, and why
  the display unit is a settings toggle).
- A Temperature Extremity event is a **temporary deviation** from the site's
  Average Temperature for the event's duration — same temporariness as a
  storm, never permanent on its own.
- **Consequence is decided by Energy funding, not a coverage tier**: a
  Weather Shield or Row Shield's Energy upkeep during an active event scales
  with that event's severity band (a small idle-but-armed cost normally,
  more during a mild event, more during an extreme one — banded, not
  continuous, per Buildings & Economy's Basic Resources). If the settlement
  had enough Energy in the pool to cover that cost, the shield **fully
  maintains the comfort target** — zero effect on covered production,
  regardless of how extreme the event got outside. If there's no shield
  covering the site, or the cost wasn't covered that season:
  - **Mild event** → production **slowed** for the event's duration.
  - **Extreme event** → production **stopped** entirely for the event's
    duration.
  - Always temporary — resumes automatically once the event ends. Unlike
    Storm below, Temperature Extremity never destroys anything on its own.
- **Settler-level consequence, driven by the same event-severity roll as
  the production consequence above** — every entity at an unprotected site
  shares one severity roll, not a separate roll per entity type. All
  temperature is tracked against one universal **72°F** target for every
  entity (settlers and crops alike) — no per-crop optimal-temperature
  variation; the only tolerance lever for crops is the existing
  Hybridization mechanic's Ice/Volcanic immunity (see Buildings &
  Economy's [Farm/Production](04_buildings_and_economy.md#farmproduction)), which stays unchanged. For an unprotected
  settler at the site:
  - **Mild event** → a `status_effect` entry (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's
    [Settler State](05_settlers_and_exploration.md#settler-state)) that slows the settler's work. Fully dynamic, not a
    fixed duration: present exactly when the settler is at an unprotected
    site *and* the current in-sim temperature — which fluctuates through
    Mid-Sim — is outside the 72°F comfort range, clearing the instant
    either condition stops holding.
  - **Extreme event** → a probability roll (chance TBD) on death, the same
    roster-removal mechanic used everywhere else a settler can die.
  - Protection is shared with the production-side consequence: a funded
    Weather/Row Shield covers both crops and any settler working that
    site via one shared coverage check. Settlers additionally have a
    personal option production sites don't: Temperature-Resistant Gear
    (see Buildings & Economy's [Fabrication](04_buildings_and_economy.md#fabrication)), covering farm-based settlers
    via a passive stock check the same way PPE covers Atmospheric Hazard.

**Storm** — preparedness-coverage tiers, same shape as before, plus a new
top-severity consequence:
- Adequately covered (Weather Shield/Row Shield with sufficient
  `Preparedness` relative to the hazard) → no effect
- Under-covered → production paused for the event's duration
- Severely under-covered (`MatchedPreparedness` near zero) → the affected
  outdoor Farm/Production site is **destroyed** — removed from the grid
  entirely, not merely paused — requiring an ordinary construction-robot
  build action to reconstruct from scratch on the now-empty slot, per
  Platform & Core Loop Redesign's Construction. (This tier already meant
  destruction under the hood; it's stated explicitly now that the
  distinction from "paused" actually matters.)
- **New**: when a storm event specifically rolls **extreme** severity, every
  *other* unprotected building on the grid (any category, not just the
  directly-targeted Farm/Production site — "unprotected" reuses the same
  Weather/Row Shield coverage check) independently rolls a small chance of
  the same fate. Chance value TBD, deferred to balancing like other numeric
  values in this design.

*Atmospheric Hazard* — a settler-level consequence, not a building-level one:
- Farm-based settlers: protection is a **passive stock check** — any PPE
  sitting in general inventory covers them; not consumed, not
  per-settler-allocated.
- Exploration-task settlers: protection requires **explicitly electing to
  send PPE** when initiating the task — this *is* consumed from inventory
  (see [Protection](04_buildings_and_economy.md#protection)'s [Medical Bay](04_buildings_and_economy.md#medical-bay) for PPE production), confirming it as a real
  optional exploration cost, not just a stock check.
- Exposure without PPE (either context) inflicts a **status effect** (see
  [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Settler State](05_settlers_and_exploration.md#settler-state)): triggers on exposure, persists
  for roughly 3 seconds of Mid-Sim time afterward, halves the settler's
  effectiveness in all tasks (their worker-effort contributes 0.5 instead
  of 1, per Worker Assignment's effort-stacking mechanic), and locks them
  out of exploration-task assignment entirely while active.

> **Resolved**: the per-settler tracking system this needed is now fully
> designed — see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Settler State](05_settlers_and_exploration.md#settler-state), [Injuries](05_settlers_and_exploration.md#injuries), and
> [Storied](05_settlers_and_exploration.md#storied) subsections.

---

## Win / Lose Conditions

### Success
- Survive the maximum number of seasons
- **Score** calculated from several separately visible/inspectable sub-metrics, not a
  single opaque summed number, per the "numbers stay small" principle's guidance
  against hiding information behind one figure
- Score = "viability report" — how good could life be here for a larger colony?
- The *fictional meaning* is defined (see "Seed-Ships" in Background Story &
  [Gameplay-Story Integration](02_story_and_world.md#gameplay-story-integration)) — it's an estimate of the likelihood that a full-scale,
  long-term human civilization could be established on that planet, used to decide
  whether/who a future seed-ship gets sent there.
- **Content scope**: the viability report explains each SEED Faction's score plus a
  broad-strokes summary across all five — it does not carry per-encounter narrative
  flourishes (e.g. no special write-up keyed to which alien civilization class was
  or wasn't encountered). Any story-worthy moments a run produced live in Frontier
  Legends' own scoring, not in bespoke report text.

### SEED Factions
The sub-metrics are backed in-fiction by political factions within SEED, each caring
about a different dimension of "success." They're in tension mostly through
resource scarcity, not necessarily ideology — their aims don't inherently conflict,
it's just impossible to satisfy everyone at once. This gives the "several
separately-visible sub-metrics" scoring principle real narrative weight instead of
being an arbitrary abstract dial, and mirrors the "breadth of tradeoffs" difficulty
principle at the political level.

**Score bounds and units, for all five factions.** Every faction's score is
displayed as a **percentage, 0–100%**, abstractly representing that faction's
estimated probability of recommending a seed-ship be sent to this planet.
Each faction's underlying formula is a sum of several `normalize()` terms
(each independently bounded to [0,1] before combining, per "normalize before
combining unrelated values"), so the raw sum's own maximum is just the
number of terms (or the sum of their weights, once weights are assigned
rather than TBD) — the displayed percentage is that raw sum divided by its
own maximum, then multiplied by 100. One conversion rule stated once here
rather than repeated per faction below.

- **Sustenance Bloc.** Feasibility, to them, doesn't mean "is it safe for humans" —
  it means "can it support a large population at all." Sustainability is the core
  value. Backs the **Food Security** sub-metric (see [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)):
  `FoodSecurity = normalize(NutritionStockpile) + normalize(NutritionIncome)` —
  `NutritionStockpile` is `sum of sqrt(stockpiled amount)` across the four nutrient
  axes, counting only food actually committed to a Food Storage building (see
  [Storage](04_buildings_and_economy.md#storage)) — uncommitted food in general inventory contributes nothing;
  `NutritionIncome` mirrors Development Bloc's `ResourceIncome` — a linear
  average production rate over the run's last 5 seasons, across the same four
  axes, unaffected by storage status since it measures productive capacity
  rather than a secured reserve. Normalized before combining, per the
  "normalize before combining unrelated values" design principle.
- **Safeguard Coalition** *(name tentative)*. Prioritizes safety disjoint from raw
  sustenance — resilience against climate/weather, medical safety (including depth
  of biological research into the planet's pre-existing life), and information
  about planetary life, including whether sentient or organized life exists that
  might oppose human settlement.

  **Mechanically defined**, for two initial hazard axes — **Weather** and
  **Bio-hazards** (more could be added later):
  - `Data(hazard)` — displayed to the player as a percentage (0–100%), but used in
    the formula below as a **0–1 fraction**, so it shares a scale with
    `MatchedRisk × MatchedPreparedness` (both naturally capped at 1) per the
    "normalize before combining unrelated values" design principle. How much of the
    possible data on that hazard has been collected — different efforts contribute
    different amounts (early weather-monitoring structures accumulating data points
    over time, settler-crewed exploration data-gathering missions, e.g. a
    weather balloon). 100%/1.0 means as confident as possible in the picture
    gathered.
  - `MatchedRisk(hazard)` — a Bayesian "sureness" that this hazard is actually
    significant on *this specific* planet, computed directly from Bayes' theorem
    using a **prior based on planet type** (e.g. Volcanic planets have a low prior
    for bio-hazard risk — not intuitively likely, even though a specific instance
    could still turn out high) updated by `Data(hazard)`. Being a probability, it's
    naturally normalized to [0,1].
  - `MatchedPreparedness(hazard)` — built preparedness (Weather Shield for
    Weather; Medical Bay for Bio-hazards — see Buildings & Economy's
    [Protection](04_buildings_and_economy.md#protection) category) normalized against the *true* risk level, capped at
    1: `min(Preparedness / TrueRisk, 1)`.
  - **`Score(hazard) = Data(hazard) + MatchedRisk(hazard) × MatchedPreparedness(hazard)`**
    — pure data-gathering has a real floor value on its own (SEED wants the
    information regardless of outcome); preparedness only earns its multiplier once
    there's enough sureness to credit it as intentional and verified, not lucky.
  - This isn't only a scoring abstraction — some preparedness actions have a
    **functional data prerequisite** in-fiction, not just a scoring one (e.g. an
    effective vaccine can't be produced without first collecting enough bio-data to
    characterize the actual pathogen). A planet with a genuinely high, surprising
    hazard forces the data-gathering that unlocks dealing with it anyway, so
    information-gathering isn't an artificial side-quest bolted onto survival.
  - Total Safeguard score = some combination of `Score(Weather)` and
    `Score(Bio-hazard)` — exact combination (sum, average, etc.) not yet decided.
    Both are the same kind of quantity (a Score(hazard) value on the same scale),
    so no additional cross-normalization is needed to combine them, unlike
    Stewardship's and Development's formulas below.
- **Stewardship Caucus** *(name undecided — alternative: Non-Intervention Bloc)*.
  Conservation-minded: opposes humans acting as a colonial force, wants to "do
  things right this time" — both to avoid repeating Earth's mistake and out of
  genuine concern for colonized life/planets. Likely pulls against the Development
  Bloc mechanically — probably rewards leaning into strategy dimension **B
  (Biosphere Integration)** and penalizes aggressive extraction/dimension **C**
  play.

  **Mechanically defined**, across three axes, weighted more heavily toward data
  than Safeguard — Stewardship's job is fundamentally assessment ("how hard would
  responsible settlement be here"), not achieving zero disruption in a single run:
  - `EcologicalData` — a combined survey metric merging sentient-life detection and
    general biodiversity/animal-life-prevalence research into **one shared
    counter**, since both stem from the same underlying biological research
    effort. Value comes from reaching a confident answer, not which answer it is —
    confirmed-absent sentience is just as valuable to this faction as
    confirmed-present — so unlike Safeguard's hazards, this needs **no
    `MatchedRisk`-style mean at all**, since there's no "risk direction" to
    estimate. Reuses the Beta-distribution data-gathering mechanism (see Exoplanet
    Types) in simplified form — just a single running count `ν` of qualifying
    reports (no `a`/`b` split needed, since nothing is being estimated toward a
    lean):
    ```
    EcologicalData = ν / (ν + k)
    ```
    Two report sources both feed the same shared counter:
    - **Sentience-detection** exploration task (investigating for structures,
      tools, signals, or other evidence of organized intelligence). Report:
      *"Signs of organized intelligence found"* / *"No signs of organized
      intelligence found."* Finding evidence of organized intelligence launches
      the full **sentience-contact chain** (see [Exploration Tasks](05_settlers_and_exploration.md#exploration-tasks)' Escalation
      Chains for the complete worked example — Observe from a distance, then a
      branching peaceful/aggressive contact choice), which contributes
      significantly elevated `EcologicalData` weight and elevated Frontier
      Legends legend-value at each step.
    - **Biodiversity survey** — the *same* bio-survey exploration action already
      established for Safeguard Coalition's Pathogen Threat data (see Exoplanet
      Types). One settler mission generates two independent reports for two
      different factions' scores at once — any result from that action adds to
      Stewardship's `EcologicalData` confidence, regardless of what it reveals
      about pathogens.
  - `DisruptionFootprint` — a weighted ratio of untouched vs. disrupted
    native-terrain (fixed/environmental) slots on the grid; directly
    computable from grid state, no data-gathering needed to reveal it.
    **Base disruption**: any fixed/environmental slot whose state has
    changed from what it was at the start of Season 1 (built over,
    harvested, extracted from, etc.) counts as disrupted — applies
    uniformly across every fixed/environmental type (deposits, Forest
    tiles, all of it); untouched slots don't count. **Further
    disruption**: among disrupted slots, ones whose underlying feature
    required active discovery (a Mid-depth or Deep tier survey reveal)
    before being acted on contribute more than a base-disrupted slot does —
    surfacing something genuinely hidden is worse than using something
    already visible from Season 1 (Surface-tier deposits, Forest tiles,
    which were never hidden and so never get this extra weight). Exact
    weighting TBD, deferred to balancing like other numeric values in this
    design.
  - `ExtractionRestraint` — penalized by cumulative volume of **non-sustainable**
    resources extracted: Iron Ore, Copper Ore, Stone, rare metals (both bounded and
    effectively-infinite deposit sub-types incur it at the same rate — neither
    mineral regenerates, "effectively infinite" only means the specific
    deposit is large relative to a run's timescale, not that the resource
    itself renews), Fossil Fuel, and Clear-Cutting's Wood output specifically
    (see Buildings & Economy's [Fuel](04_buildings_and_economy.md#fuel) — a Standing Assignment, not a
    building). **Does not apply** to ordinary Farm/Production output
    (Grain, Fruit, Milk, Eggs, Wool, Wood from Timber Grove, Fiber, Pelts —
    all renewable), Well/water-collection, or Geothermal Generator's
    heat-tapping — all ongoing and non-depleting. Tracked as a running
    cumulative total at the point of *harvest*, not by tracing which pooled,
    fungible unit later gets consumed — this is what lets Wood stay a single
    resource with two sources (see Buildings & Economy's [Fuel](04_buildings_and_economy.md#fuel)) rather than
    needing two separately-tracked items.
  - `EmissionsRestraint` — penalized by cumulative Energy produced via
    Fuel-based Generator over the run (see Buildings & Economy's [Fuel](04_buildings_and_economy.md#fuel)), a
    genuinely separate behavior from `ExtractionRestraint` (that one cares
    about the sustainability of the *source*; this one cares about the
    *act of burning* regardless of source — Wood from sustainable Timber
    Grove output is penalized here exactly the same as Wood from
    non-sustainable Clear-Cutting output, which already paid its own,
    separate `ExtractionRestraint` cost at the point of harvest) rather than a
    variant of `ExtractionRestraint`. Energy from Fossil Fuel is penalized
    at a higher per-unit rate than Energy from Wood — not linearly scaling
    with total output, just a modestly higher flat rate per unit —
    reflecting that fossil fuel is
    dirtier per unit of Energy even though it returns more Energy per unit of
    fuel. This is the mechanic's direct playable echo of Story & World's Ren,
    the Incoming Star: Stewardship rewards a new planet's climate stewardship
    on its own terms, independent of however Earth's own unresolved climate
    debate turns out.
  - `ContactRestraint` — how the player handled any alien civilization
    encountered this run (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Escalation Chains](05_settlers_and_exploration.md#escalation-chains)
    for the full sentience-contact chain and its civilization classes). A
    single discrete per-run value, not a cumulative sum like the other
    three axes, since a run has at most one such encounter: highest value
    for a successful alliance; a small reward for detecting a civilization
    and choosing to leave it uncontacted (or never detecting one at all —
    both represent zero disruption inflicted on a civilization, so they're
    treated the same); a small penalty for contact that never resolves
    into alliance, whether attempted-and-failed or simply never pursued
    past initial contact; a large penalty for choosing Bluff/Coercive or
    Military Exploitation at First Contact, applied for making that choice
    regardless of whether the attempt itself succeeds. Exact tier values
    TBD, deferred to balancing like other numeric values in this design.
  - These five are genuinely different *kinds* of quantities (a
    data-completeness percentage, a spatial ratio, two differently-shaped
    extraction/emissions penalties, and a discrete per-run tier), so each
    is normalized to a comparable [0,1] scale before combining, per the
    "normalize before combining unrelated values" design principle:
    `Stewardship = normalize(EcologicalData) + normalize(DisruptionFootprint) +
    normalize(ExtractionRestraint) + normalize(EmissionsRestraint) +
    normalize(ContactRestraint)` (weights TBD)
  - A fifth axis — rewarding informed integration of native species over
    Earth-imported ones, gated by whether that species has actually been studied —
    was considered but dropped as too mechanically complex alongside these four.
- **Development Bloc.** Prioritizes resource access for advanced technology —
  rewards stockpiles of non-food resources (especially rare ones) and achieving
  more advanced technology tiers as evidence those resources are available. Likely
  ties to strategy dimension **C (Synthesis)** and the rare-metals/Ore economy. A
  "number go up = good" faction in spirit — rewards raw capacity even without a
  clear use for it, unlike Safeguard's requirement that preparedness be justified
  by data.

  **Mechanically defined**, across three independently-contributing axes:
  - `ResourceStockpile` — `sum of rarity-weighted sqrt(stockpiled amount)` across
    non-food resources (Iron Ore, Copper Ore, Iron, Copper, Stone, Silicon,
    Wool, Fiber/Cotton, Wood, Pelts, rare metals) — rarer resources weighted
    higher. Same diminishing-returns shape as Food Security.
  - `ResourceIncome` — `sum of rarity-weighted (linear average income rate over the
    run's last 5 seasons)` across the same resources. No `sqrt`-flattening, since
    it's a rate, not a stockpile — a separate signal from total stockpile, which
    could reflect one-time windfalls or short-lived high-yield mining rather than
    durable production capacity.
  - `TechAchievement` — sum, across every distinct catalog entry (a building
    tier, a fabricated item type, a drone type/tier/hardened-state) **ever
    reached at least once during the run**, of that entry's **static,
    design-authored achievement score** on a 0–4 scale (see Buildings &
    Economy's [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog) for the full rubric and per-entry
    values), not something computed adaptively from a run or environment.
    Each distinct entry counts **once**, regardless of how many units were
    produced, how many copies were built, or what remains in stock at
    scoring time — producing 10 Iron and later consuming all of it still
    contributes Iron's tier value once; building two fully-upgraded Scanner
    Stations still contributes that tier's value once, not twice.
  - These three are different *kinds* of quantities (a resource total, a rate, and
    a design-authored point count), so each is normalized before combining, per the
    "normalize before combining unrelated values" design principle:
    `Development = normalize(ResourceStockpile) + normalize(TechAchievement) +
    normalize(ResourceIncome)`
- **Frontier Legends.** Named, informally but almost universally, after
  Captain Naveen Kiran (see Story & World's The Kiran Incident) — the first
  human being to ever set foot on another world, stranded there by
  accident, who spent her remaining years transmitting data back rather
  than treating her situation as merely a tragedy. Wants exciting stories
  in that same spirit — specific hard-to-complete exploration sites, a
  standout settler who's completed a lot of exploration tasks.
  Not just an institutional PR angle (though it is pragmatically that too, given
  SEED's need for continued public/political support) — the faction's own members
  want to see *themselves* as among the legends, not just chase good press. Draws
  on the per-settler `legend_value` tracked in Settlers & Exploration's Settler
  State.

  **Mechanically defined.** Each notably difficult/named exploration site has a
  static, design-authored "legend value," earned by completing it (mirrors
  `TechAchievement`'s pattern from Development Bloc) — with one exception: the
  sentience-contact chain's legend value scales inversely with the actual success
  probability of whichever roll produced the outcome, rather than being a flat
  static value (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Escalation Chains](05_settlers_and_exploration.md#escalation-chains)). Every settler accumulates
  their own personal sum of legend-values from sites *they* personally completed —
  both faction metrics are just different aggregations over that same one dataset:
  - `HardSiteAchievement` — **sum across settlers** of their individual sums.
    Rewards the colony having many legendary achievements overall, however
    distributed across settlers — "it's valuable to have multiple legends on a
    run."
  - `StandoutSettlerRecord` — **max across settlers** of their individual sums.
    Rewards one settler consistently impressing — a personal legend distinct from
    the colony's total achievement. Variety of task *types* doesn't matter, just
    accumulated legend-value.
  - Different aggregations of the same data still produce different natural
    scales, so both are normalized before combining, per the "normalize before
    combining unrelated values" design principle:
    `FrontierLegends = normalize(HardSiteAchievement) +
    normalize(StandoutSettlerRecord)`
  - Exploration is settler-only, full stop (see [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's
    [Exploration Tasks](05_settlers_and_exploration.md#exploration-tasks)) — but a player can still choose to never accept any
    exploration task at all, keeping `StandoutSettlerRecord` at zero. This
    faction specifically rewards choosing to risk real settlers rather than
    avoiding exploration altogether.

All five SEED Factions now have real formulas.

> **Open question:** whether/how the five sub-metrics combine into any single
> comparable figure across runs, if at all, is still open.

### Critical Failure (Early End)
- Total farm destruction (weather, disaster)
- Settler starvation

> **Open question:** "total farm destruction (weather, disaster)" has no implemented
> mechanic yet (no weather/disaster system exists in code). Is this still an intended
> failure condition, and if so what triggers it — random planet-type-weighted events,
> or a consequence of neglecting some other system? Colony-wide settler death (all
> settlers dead) is already implemented as the actual failure trigger per CLAUDE.md.

### Gradual Decline
- Poor seasons compound: fewer resources, understaffed sites, harder recovery
- A run can be effectively lost through slow decline without a single critical event
