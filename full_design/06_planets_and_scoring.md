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
  (Matter-conversion chains, hydroponics, drone-driven output) to compensate for a
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
> Energy/Matter base regeneration rates per planet are also still open.

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
  from SEED Factions below — i.e. `Data(hazard)` **is** `Confidence(hazard)`.
- **Implementation footprint**: just two running counters per sub-factor (ten total
  across all five). No distribution objects, no sampling.

**Per-sub-factor data sources, success/failure definitions, and player-facing text:**

| Sub-factor | Data source | Success | Failure | Player sees |
|---|---|---|---|---|
| Storm Severity/Frequency | Scanner Station's Weather Sensing mode (see Farm/Production; staffed at base tier, one reading/season active) or weather balloon (unmanned exploration task) | Storm event detected in the window | Calm conditions | *"Storm activity detected"* / *"Conditions calm."* |
| Temperature Extremity | Same Scanner Station Weather Sensing mode, or a dedicated probe | Window registered a temperature swing extreme enough to threaten human safety | Temperatures stayed within safe range | *"Extreme temperature swing recorded"* / *"Temperatures within safe range."* |
| Atmospheric Hazard | Atmospheric sampling (unmanned exploration task/probe) | Sample contained toxic/corrosive compounds above a safe threshold | Clean sample | *"Atmospheric sample: hazardous compounds detected"* / *"Atmospheric sample: clean."* |
| Pathogen Threat | Bio-survey exploration task (manned or unmanned) or Medical/Research facility | Sampled organism/environment tested positive for a dangerous pathogen | Clean sample | *"Pathogen detected in sample"* / *"No pathogens detected."* |
| Toxic/Parasitic Organism Threat | Exploration tasks encountering wildlife (inherently manned — direct contact risk, not remote sampling) | Encountered organism proved dangerous (venomous/toxic) | Organisms encountered were benign | *"Dangerous organism encountered"* / *"Wildlife encountered was benign."* |

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

---

## Win / Lose Conditions

### Success
- Survive the maximum number of seasons
- **Score** calculated from several separately visible/inspectable sub-metrics, not a
  single opaque summed number, per the "numbers stay small" principle's guidance
  against hiding information behind one figure
- Score = "viability report" — how good could life be here for a larger colony?
- The *fictional meaning* is defined (see "Seed-Ships" in Background Story &
  Gameplay-Story Integration) — it's an estimate of the likelihood that a full-scale,
  long-term human civilization could be established on that planet, used to decide
  whether/who a future seed-ship gets sent there.

### SEED Factions
The sub-metrics are backed in-fiction by political factions within SEED, each caring
about a different dimension of "success." They're in tension mostly through
resource scarcity, not necessarily ideology — their aims don't inherently conflict,
it's just impossible to satisfy everyone at once. This gives the "several
separately-visible sub-metrics" scoring principle real narrative weight instead of
being an arbitrary abstract dial, and mirrors the "breadth of tradeoffs" difficulty
principle at the political level.

- **Sustenance Bloc.** Feasibility, to them, doesn't mean "is it safe for humans" —
  it means "can it support a large population at all." Sustainability is the core
  value. Backs the **Food Security** sub-metric (see Food & Nutrition):
  `FoodSecurity = normalize(NutritionStockpile) + normalize(NutritionIncome)` —
  `NutritionStockpile` is `sum of sqrt(stockpiled amount)` across the four nutrient
  axes, counting only food actually committed to a Food Storage building (see
  Storage) — uncommitted food in general inventory contributes nothing;
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
    over time, exploration data-gathering missions — manned or unmanned, e.g. a
    weather balloon). 100%/1.0 means as confident as possible in the picture
    gathered.
  - `MatchedRisk(hazard)` — a Bayesian "sureness" that this hazard is actually
    significant on *this specific* planet, computed directly from Bayes' theorem
    using a **prior based on planet type** (e.g. Volcanic planets have a low prior
    for bio-hazard risk — not intuitively likely, even though a specific instance
    could still turn out high) updated by `Data(hazard)`. Being a probability, it's
    naturally normalized to [0,1].
  - `MatchedPreparedness(hazard)` — built preparedness (protection/energy
    infrastructure for Weather; medical facilities for Bio-hazards) normalized
    against the *true* risk level, capped at 1: `min(Preparedness / TrueRisk, 1)`.
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
      the full **sentience-contact chain** (see Exploration Tasks' Escalation
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
  - `DisruptionFootprint` — ratio of untouched vs. built-over native-terrain
    (fixed/environmental) slots in the Farm/Production grid; directly computable
    from grid state, no data-gathering needed to reveal it.
  - `ExtractionRestraint` — penalized by total volume extracted from mined
    deposits, at the same rate regardless of deposit type (see Resources: deposits
    come in a high-yield bounded type and a lower-yield effectively-infinite type).
    Extraction volume is a proxy for the disruptive footprint of the mining
    infrastructure/activity itself, not for depleting a finite resource.
  - These three are genuinely different *kinds* of quantities (a data-completeness
    percentage, a spatial ratio, and an extraction-volume-based penalty), so each
    is normalized to a comparable [0,1] scale before combining, per the "normalize
    before combining unrelated values" design principle:
    `Stewardship = normalize(EcologicalData) + normalize(DisruptionFootprint) +
    normalize(ExtractionRestraint)` (weights TBD)
  - A fourth axis — rewarding informed integration of native species over
    Earth-imported ones, gated by whether that species has actually been studied —
    was considered but dropped as too mechanically complex alongside these three.
- **Development Bloc.** Prioritizes resource access for advanced technology —
  rewards stockpiles of non-food resources (especially rare ones) and achieving
  more advanced technology tiers as evidence those resources are available. Likely
  ties to strategy dimension **C (Synthesis)** and the rare-metals/Ore economy. A
  "number go up = good" faction in spirit — rewards raw capacity even without a
  clear use for it, unlike Safeguard's requirement that preparedness be justified
  by data.

  **Mechanically defined**, across three independently-contributing axes:
  - `ResourceStockpile` — `sum of rarity-weighted sqrt(stockpiled amount)` across
    non-food resources (Iron, Copper, Stone, Silicon, Wool, Fiber/Cotton, Wood,
    Pelts, rare metals) — rarer resources weighted higher. Same diminishing-returns
    shape as Food Security.
  - `ResourceIncome` — `sum of rarity-weighted (linear average income rate over the
    run's last 5 seasons)` across the same resources. No `sqrt`-flattening, since
    it's a rate, not a stockpile — a separate signal from total stockpile, which
    could reflect one-time windfalls or short-lived high-yield mining rather than
    durable production capacity.
  - `TechAchievement` — sum of each built element's **static, design-authored
    achievement score** (assigned per catalog entry based on how demanding its
    prerequisites/input resources are — basic buildings score 0), not something
    computed adaptively from a run or environment.
  - These three are different *kinds* of quantities (a resource total, a rate, and
    a design-authored point count), so each is normalized before combining, per the
    "normalize before combining unrelated values" design principle:
    `Development = normalize(ResourceStockpile) + normalize(TechAchievement) +
    normalize(ResourceIncome)`
- **Frontier Legends.** Wants exciting stories — specific hard-to-complete
  exploration sites, a standout settler who's completed a lot of exploration tasks.
  Not just an institutional PR angle (though it is pragmatically that too, given
  SEED's need for continued public/political support) — the faction's own members
  want to see *themselves* as among the legends, not just chase good press. Gives
  the earlier-flagged "settler individuality could surface later, if it's fun"
  thread (from the Story session) a concrete reason to exist — the first place in
  the design individual-settler tracking becomes mechanically real.

  **Mechanically defined.** Each notably difficult/named exploration site has a
  static, design-authored "legend value," earned by completing it (mirrors
  `TechAchievement`'s pattern from Development Bloc). Every settler accumulates
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
  - Since some exploration tasks are unmanned (see Exploration Tasks), a player who
    never sends a settler out keeps `StandoutSettlerRecord` at zero — this faction
    specifically rewards choosing to risk real settlers rather than always
    defaulting to the safer unmanned option.

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
