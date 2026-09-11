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

**Occurrence — a fixed per-run schedule, not a per-season draw.** This
applies to every **non-reactive** hazard — one that manifests at a time of
its own rather than in response to a player action. Storm and Temperature
Extremity are the two such hazards here. Bio-hazard's sub-factors —
**Pathogen Threat** (diseases) and **Toxic/Parasitic Organism Threat**
(parasites) — are **not exploration-gated**: which disease and parasite
*types* a run has is fixed at planet generation, and they reach the
settlement through several routes (see Bio-hazard, below). Whether
Atmospheric Hazard stays a continuous check or joins the scheduled model is
still open (see `DESIGN_TODO.md` `11-B5`).

At **run generation** the game rolls, once and for the rest of the run:
which seasons carry a Storm and/or a Temperature Extremity event, and each
scheduled event's **severity band (mild or extreme)** — the same coarse
band described below, pre-rolled here rather than at event time, weighted by
that hazard's `TrueRisk` (a worse-off planet gets more scheduled events and
skews them more extreme). This schedule is **deterministic once rolled** —
never re-drawn. The only part still rolled at simulation time is *when
within* a scheduled season the event occupies the Mid-Sim window: it hits
one or more **random intervals** of that season, not the whole of it.

**Telegraphing — a lead-time window that narrows with `Confidence(hazard)`.**
At the start of every season's planning, the game reads the fixed schedule
and, through the **Transmissions** channel (see Story & World's
[Gameplay-Story Integration](02_story_and_world.md#gameplay-story-integration)), reports the next inbound scheduled hazard
season and roughly how many seasons away it is. Accumulated data-`Confidence`
for that hazard sharpens both the lead-time window and the severity readout,
not whether the event happens:
- **Near-zero confidence** (run start, before any surveying): possibly no
  advance notice at all. The one-time **SEED summary transmission** at run
  start still surfaces the planet-type's *prior* values directly
  (narrativized, but showing the actual Bayesian prior numbers or a close
  translation) — framed in-fiction as SEED's institutional knowledge about
  planet-type archetypes from prior missions, not this specific planet —
  so every run has a baseline sense of what to expect from turn one even
  with zero investment.
- **Low confidence**: a wide window ("severe weather incoming, some time in
  the next 1–5 seasons" — numbers illustrative), severity vague ("elevated
  risk").
- **Moderate confidence**: a narrower window ("2–4 seasons out").
- **High confidence** (a raised tier, not the maximum): the exact lead time
  ("3 seasons out") and a specific severity ("a severe storm").
- Regardless of confidence, when a scheduled season is the **current** one,
  that season's planning opens with a firm, certain notice.
- The **orbital probe** (see Core Loop & Grid's [Specialization](03_core_loop_and_grid.md#specialization)) shifts
  the warning **one tier better** than the player's current data-`Confidence`
  alone would give (capped at the exact-lead-time tier).

All delivered via the existing **Transmissions** mechanic, which was already
specifically designed for this purpose — this section is that mechanic's
concrete realization, not a new system layered on top of it. (How a survey
now accrues `Confidence` against a fixed schedule rather than a per-season
coin-flip, and how that feeds the Safeguard score, is being reconciled in
the Hazards & Data-Gathering design pass — see `DESIGN_TODO.md` `11-B1` /
`11-B2`.)

**Event severity — a coarse band, shared by Storm and Temperature
Extremity.** Each scheduled event carries one of two severity bands,
**mild** or **extreme** — pre-rolled with the schedule at run generation
(above), weighted by that hazard's `TrueRisk` (a worse-off planet skews
toward more extreme events, not just more frequent ones — reusing a value
already tracked rather than adding a new dial). This is what gives "a strong
enough storm" or "the real temperature passing a threshold" concrete
meaning below, instead of consequence being driven purely by the
settlement's static Preparedness coverage as before.

**Concurrency.** Storm and Temperature Extremity are the only two hazard
sub-factors that manifest as a **scheduled discrete Mid-Sim event** —
Atmospheric Hazard (also Weather) is a continuous passive-stock/PPE check
with no start/duration event, and Bio-hazard (Pathogen Threat / diseases,
Toxic/Parasitic Organism Threat / parasites) is a **settlement-facing
standing risk** resolved on the quarter-season epidemiology tick (below),
not a scheduled event. Each scheduled season carries **at most one Storm
and at most one Temperature Extremity**
event; there's no scenario where the same hazard type fires twice in one
season. That leaves a ceiling of at most two discrete events in a season —
one Storm, one Temperature Extremity — each independently scheduled and
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
  Weather Shield or Row Shield covering the site draws its flat baseline
  always, plus an **elevated** draw for the event's duration, banded by
  severity (more for a mild event, more still for an extreme one — per
  Buildings & Economy's Resources' Energy Income/Consumption Rates). If the
  settlement's total Income rate covers total Consumption including that
  elevated draw — i.e. the shield is **not one of the buildings left
  un-powered by a shortfall**, see Resources — the shield **fully maintains
  the comfort target** — zero effect on covered production, regardless of
  how extreme the event got outside. If there's no shield covering the
  site, or the shield couldn't be powered:
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
- When a storm event is scheduled at **extreme** severity, every *other*
  unprotected building on the grid (any category, not just the
  directly-targeted Farm/Production site — "unprotected" reuses the same
  Weather/Row Shield coverage check) independently rolls a small chance of
  the same fate. Chance value TBD, deferred to balancing like other numeric
  values in this design.
- **Settler and drone casualties.** At an affected site with no shield
  coverage, a Storm can also **kill an unprotected outdoor settler** and
  **destroy an unprotected outdoor worker drone** — the same roster-removal
  / unit-loss mechanics used elsewhere. Outdoor workers on a shielded tile
  are covered by that shield the same way crops and buildings are; Indoor
  workers in a powered building are sheltered.
- **Never a direct run-ender.** Storm losses — buildings, crops, settlers,
  drones — are severe but do not by themselves end a run. A run ends only
  when every settler is dead (to which Storm casualties can contribute) or
  the season limit is reached (see [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)). The
  pre-rolled schedule and its `Confidence`-scaled telegraph are the
  intended counterplay: advance knowledge of a stormy season is what lets a
  player fund shield coverage, pull outdoor workers indoors, or brace for
  the loss.

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

*Bio-hazard* — diseases (**Pathogen Threat**) and parasites
(**Toxic/Parasitic Organism Threat**), a settlement-facing standing risk
rather than a scheduled event. Which disease and parasite **types** a run
has is fixed at planet generation (count and roster weighted by
`TrueRisk(Bio-hazard)`). Their per-settler and infected-food mechanics live
in Settlers & Exploration's [Infections](05_settlers_and_exploration.md#infections) and [Infected Food](05_settlers_and_exploration.md#infected-food); what belongs
here is the settlement-level machinery:

- **The quarter-season epidemiology tick.** Four times a season, one pass
  handles all bio-infection resolution: (1) for each disease with at least
  one infected settler present in the settlement and **no vaccine**, every
  uninfected settler in the settlement rolls a spread chance; (2) every
  infected settler — recovering, queued, or working — rolls for **death**
  (probability per type) unless a **countermeasure** (vaccine for a
  disease, anti-parasitic for a parasite) exists for that infection at that
  tick; (3) Medical Bay recovery progresses for the settlers occupying its
  Recovery-capacity slots (see Buildings & Economy's [Medical Bay](04_buildings_and_economy.md#medical-bay)).
- **Contraction routes**, all applying their infection at **Post-Sim** (the
  settler works the affected season normally, then carries it):
  - **Exploration** — a task's outcome roll (an Emergency Medical Kit taken
    on the task blocks a would-be minor injury or infection).
  - **Carrier wild populations** — a carrier grazer at a crop site infects
    the settler working it; a carrier predator at a husbandry site infects
    the settler there and any surviving targeted animals. Fencing or an
    Energy shield that keeps the population out of the site blocks this —
    see [Wild Animal Populations](06_planets_and_scoring.md#wild-animal-populations), below, for the full mechanic.
  - **Infected husbandry animals** — tending an infected husbandry
    population.
  - **Infected food** — see Settlers & Exploration's [Infected Food](05_settlers_and_exploration.md#infected-food).
- **Countermeasures** are researched at a Medical Bay (see [Medical Bay](04_buildings_and_economy.md#medical-bay)):
  a vaccine ends a disease permanently and settlement-wide; an
  anti-parasitic guarantees settler recovery (no immunity) and grants
  husbandry animals permanent auto-immunity.

### Wild Animal Populations

A third kind of threat, distinct from the scheduled Storm/Temperature
Extremity events and the standing Bio-hazard risk above: wild animals near
the settlement are tracked as **populations**, not discrete events, and —
through carrier variants — are a delivery vector for the diseases and
parasites described in Bio-hazard, above.

**Tracking & size.** The settlement tracks nearby wild populations of
gameplay-relevant size (diegetically there's more wildlife around than
this tracks — just what's close and plentiful enough to matter). Each
tracked population has: a **kind** — **grazer/scavenger** (raids standing
crops) or **predator** (preys on husbandry animals, and can kill
settlers); a **size class** — tiny, small, medium, large, huge, or titan
(insect- to largest-dinosaur-scaled), fixed per population, governing
which fence tiers and shields stop it (see Buildings & Economy's
[Fencing](04_buildings_and_economy.md#fencing)); a **size tier** — low / moderate / high / overrunning — how big it
currently is, rising or falling each season (see Growth & Decay, below);
for a grazer, a **diet** drawn from {Grain, Fruit, Vegetation} (Vegetation
covers both Timber Grove and Fiber Field); for a predator, a **prey list**
of husbandry archetypes; and a **carrier flag** per bio-threat type —
binary, not a fraction, rolled once at introduction. **Reach is ambient** —
a population can reach any settlement tile not protected by fencing or an
active Energy shield; there is no spatial position beyond "near enough to
reach the settlement," and no travel time. (An off-grid visual, with
decorative nearby topography, exists purely for legibility — see UI,
below.)

**Grazers/scavengers.** A reachable grazer population affects **every
completed cycle** of every plant-crop building matching its diet, at the
**pre-harvest growth step** (Grain/Fiber Field's `growing→harvestable`;
Fruit Orchard's `mature→fruiting`; Timber Grove's
`cycle-harvestable→cycle-harvestable` self-loop — see Buildings &
Economy's [Plant-Crop Production Model](04_buildings_and_economy.md#plant-crop-production-model)), computed at that step's
completion:

| Tier | Effect on that cycle's harvest |
|---|---|
| low | −1 to the harvest range's **minimum** |
| moderate | −1 to the **rolled** harvest amount |
| high | −2 to the rolled amount |
| overrunning | harvest → 0 |

(clamped ≥ 0). **Titan** grazers act **one tier higher** for this effect
only (a titan-sized high population behaves as overrunning) — their
growth-target tier is unaffected. **Every plant-crop yield is a range
`[min, max]`, rolled uniformly** — a value that was a flat `v` is `[v,
v]`; whether building upgrades widen the range is TBD, deferred to
balancing. If a fence protecting a matching site is breached mid-season,
that site is exposed to grazing for the rest of Mid-Sim immediately, not
just from the following season.

**Predators.** A reachable predator population, for each prey archetype
with a **reachable domesticated site**, rolls once per site (at Post-Sim,
after carrier infections and before population growth — see below) for a
**chance — scaling with tier — to destroy that site** (the husbandry
building reverts to a built-but-empty state; see Buildings & Economy's
forthcoming Animal Husbandry). **Titan** predators succeed automatically
against any reachable site. A predator only ever "affects" domesticated
animal sites of its prey archetypes — never crop sites, and never a
settler directly *except* the one working a site it's actively preying
on: if present, and the predator is **large, huge, or titan**, there is
also a chance it kills that settler (medium and smaller predators never
kill settlers). Predators are drawn **only by prey**, never by settlers
alone; it's meant to be common for a predator population to exist nearby
without ever touching the settlement in a given season, if it has no
reachable prey.

**Carrier infection.** If a carrier population affects a site with a
present, infectable worker or animal, that infection is applied **at
Post-Sim**, resolved **before** site destruction and population growth
(so destruction doesn't need to track which sites were exposed in order
to also infect them): a carrier **grazer** at a crop site infects the
settler working it; a carrier **predator** at a husbandry site infects the
settler there and any domesticated prey animals that survive that
season's destruction roll. A researched countermeasure (vaccine or
anti-parasitic — see Buildings & Economy's [Medical Bay](04_buildings_and_economy.md#medical-bay)) for that specific
type blocks the infection entirely — see Settlers & Exploration's
[Infections](05_settlers_and_exploration.md#infections) for what happens after. **Domesticating an infected wild
grazer population inherits its infection into the new herd** — the only
other wild route parasites reach husbandry stock, alongside an existing
herd being targeted by a carrier predator.

**Growth & decay.** Resolved at **Post-Sim**, after harvest/production
resolution, in this order: **carrier infections → site destruction →
population growth.** Each population's **target tier** is set by an
effective site count, then it moves **at most one tier** toward that
target:

| Effective site count | Target tier |
|---|---|
| 0 (or negative) | none — dropped from tracking |
| 1 | low |
| 2 | moderate |
| 3 | high |
| 4+ | overrunning |

A **grazer's** site count = the number of reachable matching plant-crop
sites that completed a growth step this season (whether or not the
resulting harvest was actually reduced to 0 — the food was there either
way). A **predator's** site count = (reachable domesticated prey sites
this season) + (the size-**stage** of every wild population of one of its
prey archetypes, low=1 … overrunning=4, summed) — a predator preys on
**all** its sources, wild and domestic, simultaneously. Each predator's
tier, in turn, **subtracts** that same amount from **each of its prey
archetypes' own wild-population** site count (clamped at 0) — predators
suppress the wild prey they hunt, though they have no effect on
domesticated stock's own numbers (husbandry growth/production isn't
modeled this way at all — see `DESIGN_TODO.md`).

**A fully-mitigated population (site count driven to 0, by fencing,
shielding, or predator suppression) always disappears within 4 seasons**
— one tier per season from overrunning down through none. A population
that keeps receiving a constant nonzero count settles at that tier
indefinitely (an equilibrium, not decay). A **dropped** population that
later regains matching exposure returns only via a **fresh introduction
roll** (a new carrier status rolled too, independent of before).

**Seeding.** Planet generation may place initial populations
(Crew-Selection-style archetype/reroll balancing, a wider range of
outcomes) — always including the possibility of none — up to a **high**
tier (never overrunning), with count and size-class roster weighted by
`TrueRisk(Bio-hazard)` (the same "biological richness" correlation already
governing Trapping yield and Fossil Fuel frequency). Each season
thereafter carries a chance of a **new** population appearing, generally
**falling** as more populations already exist, and **starting small and
scaling up over the run's seasons** — early seasons are kept from
compounding multiple new threats at once. A newly-introduced prey
population has a chance to arrive together with an accompanying predator,
**one tier smaller**, that hunts it. Which farm-site *archetypes* bias
this further is a separate open item — see `DESIGN_TODO.md`.

**Reachability & wall destruction.** Whether a population of a given size
class can reach a tile is computed **per size**, never by a single
tier-agnostic "fenced or not": a tile is **passable** to that size if it's
unfenced, or fenced with a tier that doesn't block it (see [Fencing](04_buildings_and_economy.md#fencing)) —
a size untroubled by a fence tier walks through tiles of that tier exactly
as if unfenced, and never targets them for destruction. An active
**Energy shield's** coverage is different in kind: it is **excluded
entirely** from the passable graph for every size, evaluated **live, at
the moment of each check**, from the shield's current power state (see
[Resources](04_buildings_and_economy.md#resources)) — never a barrier to attempt destroying, since nothing can
destroy it, and reverting instantly to whatever fence (if any) sits under
it the moment it drops.

For a population that wants to reach a site, the game finds the
**shortest path, through tiles passable to its size, connecting the site
to the edge of the grid**. Every tile that path crosses which *is* a
barrier for that size is a real obstacle, attacked **nearest-to-the-site
first**, resolved on the quarter-season hazard ticks per the destruction
rule below. This is computed purely from the current grid layout, never
from what a barrier's enclosed area happens to contain — a barrier
guarding nothing of direct interest is still a genuine target if a wanted
site lies behind a further, separate barrier beyond it. Two full,
separate, non-touching barriers of a tier that blocks the same size are
fought **one at a time, outermost first** — the inner one is never even
reachable, and so never targeted, until the outer falls; deliberate double
investment in protection buys a longer siege, never a simultaneous double
fight.

Destruction, checked on the quarter-season ticks, for **huge** and
**titan** only (no smaller size ever attempts it — they're simply excluded
if blocked):

| Attacker | vs. Wood | vs. Concrete |
|---|---|---|
| Huge | guaranteed | 25% per tick |
| Titan | guaranteed | guaranteed |

Once a barrier tile is destroyed, that site is exposed to **every**
population (not only the one that broke it) immediately, for the rest of
Mid-Sim.

**UI.** Wild populations get a dedicated readout in the assessment panel —
current size tier and a **predicted trajectory** (planning-responsive: a
queued fence removes those sites from the projection; optimistic, doesn't
account for breakage) — the same "prediction, not a guarantee" role used
elsewhere (see [Resources](04_buildings_and_economy.md#resources)). A **carrier's status is visible under the same
gates as infected food/animals** (see Settlers & Exploration's [Infected Food](05_settlers_and_exploration.md#infected-food))
— a population can be *confirmed* present without its carrier status
being *visible*. Transmissions report committed changes (a tier rising, a
new population, a destroyed site); off-grid visual representations of
nearby populations, with decorative surrounding topography, are clickable
and open the same panel.

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
  `NutritionStockpile` is a flattening function (`sqrt`, tunable) of the flat
  sustenance held in Food Storage (see [Storage](04_buildings_and_economy.md#storage)) at a **run-end snapshot** —
  bulk Ration-content routed there via a Ration Press, nothing else counts,
  and anything extracted back out before run end isn't scored;
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
    **Baseline**: the site's pristine state, captured when the grid
    instance is locked in Farm Site Selection — *before* the starting
    settlement is placed (see Core Loop & Grid's [Starting Settlement Placement](03_core_loop_and_grid.md#starting-settlement-placement)).
    **Base disruption**: any fixed/environmental slot whose state has
    changed from that baseline (built over, harvested, extracted from,
    etc.) counts as disrupted — applies uniformly across every
    fixed/environmental type (deposits, Forest tiles, all of it);
    untouched slots don't count. The starting settlement's own placement
    is the first change measured this way; on top of any slot it happens
    to cover, **founding the settlement adds a small flat amount** — there
    is no zero-impact way to settle an alien world — kept deliberately
    minor relative to a run's ongoing extraction. **Further
    disruption**: among disrupted slots, ones whose underlying feature
    required active discovery (a Mid-depth or Deep tier survey reveal)
    before being acted on contribute more than a base-disrupted slot does —
    surfacing something genuinely hidden is worse than using something
    already visible from Season 1 (Surface-tier deposits, Forest tiles,
    which were never hidden and so never get this extra weight). Exact
    weighting TBD, deferred to balancing like other numeric values in this
    design. **Fencing extends this beyond fixed/environmental slots**: a
    built fence tile (see Buildings & Economy's [Fencing](04_buildings_and_economy.md#fencing)) counts as disrupted
    the same as a changed fixed/environmental slot, whatever the tile
    underneath; a **planned-but-not-yet-built** fence tile counts for
    **half** that.
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

There is exactly one critical-failure trigger: **every settler is dead.**
No other single event — not total farm destruction, not the loss of a
building, not a hazard — ends a run on its own. The paths to colony-wide
death are:
- **Starvation** — the nutrition Tier-1 consequence compounding across
  seasons (see Settlers & Exploration's Food & Nutrition).
- **No Water infrastructure** — the settlement has no functioning Water
  collection building for a season (see Buildings & Economy's [Water](04_buildings_and_economy.md#water)); a
  binary check, not reachable from a mere Energy shortfall.
- **Hazard casualties** — Storm and Temperature Extremity can kill
  settlers (see [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events) above); enough of them in a
  run whittles the crew to zero. Each such death is telegraphed by the
  hazard schedule, never an ambush.

Everything else — a wiped-out farm, a destroyed Settlement Base, a bad
season — is a setback to recover from or a lower score, not an early end.

### Gradual Decline
- Poor seasons compound: fewer resources, understaffed sites, harder recovery
- A run can be effectively lost through slow decline without a single critical event
