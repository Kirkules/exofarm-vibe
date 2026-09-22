# Planets & Scoring

## Exoplanet Types

**At a glance:**
- **Four Strategy Dimensions** — Protection/Enclosure, Biosphere
  Integration, Synthesis/Self-Sufficiency, Energy Management; every planet
  has pressure on all four, weighted differently.
- **Initial Planet Types** — Volcanic, Verdant/Temperate, Arid/Desert,
  Frozen/Ice; each a distinct dimension-pressure profile.
- **Hazard Priors** — per-planet `TrueRisk(Weather)`/`TrueRisk(Bio-hazard)`,
  each the arithmetic mean of 2-3 sub-factors (`data/hazard_priors.csv`).
- **Data-Gathering Mechanism** — hidden Beta(a,b) per sub-factor;
  `MatchedRisk = a/(a+b)`, `Confidence = min(ν/m, 1)`; reused in simplified
  form by other factions' data-collection scoring.
- **In-Simulation Hazard Events** — Storm/Temperature Extremity: fixed
  per-run schedule, `Confidence`-scaled telegraph, Energy-funded shield
  coverage decides consequence. Bio-hazard: standing risk, quarter-season
  epidemiology tick.
- **Wild Animal Populations** — grazer/predator/pollinator kinds; size
  class + size tier; site-count-driven growth/decay; per-size
  fence/shield reachability; huge/titan wall destruction.

### Design Philosophy
Each planet type should function like a character class — it should be impossible to
apply the same general approach to every planet, without any planet reducing to a
single viable strategy or being strictly harder/easier than another. This is
achieved with a **distribution of pressure across four strategy dimensions**, not a
1:1 planet→dimension mapping: every planet type has some pressure on every
dimension, just weighted differently — a dominant pressure or two, moderate
pressure elsewhere, minimal pressure on whatever the planet makes easy. This directly
realizes the idea that variety should come from different planet scenarios
rather than reshuffled numbers (see Design Principles' open replayability
thread).

### The Four Strategy Dimensions
- **Protection/Enclosure.** Weather-protection shielding, indoor/enclosed tech
  (Advanced Greenhouse-tier investment).
- **Biosphere Integration.** The Local Agriculture path — hybridizing with
  native flora/fauna, open-air farming that works *with* the planet's ecosystem.
- **Synthesis/Self-Sufficiency.** Heavy fabrication/synthesized production
  (deep fabrication chains, hydroponics, drone-driven output) to compensate for a
  poor natural substrate.
- **Energy Management.** Energy production diversity and budgeting under
  scarcity. Given real teeth by the temperature-control mechanic below — without
  something to actually manage, this dimension would just be a label.

(See `data/strategy_dimensions.csv` for these four alongside what's exclusive
to each per planet.)

**Temperature/Protection/Energy coupling:** enclosed or protected structures
(Protection/Enclosure) carry a passive Energy upkeep cost (Energy Management)
that scales with how extreme the planet's ambient temperature is —
significant on both very hot and very cold planets (keeping interiors cool
vs. warm), near-zero on temperate ones. Always explicitly listed when it has
an impact, never a hidden drain. This is what naturally couples
Protection/Enclosure and Energy Management together on extreme-temperature
planets while leaving them mostly uncoupled elsewhere, without needing to
hand-author that coupling per planet.

### Initial Planet Types
Four to start, each with a qualitative identity below; the exact pressure
distribution per planet across the four strategy dimensions is still to be
worked out (open thread — see below).

- **Volcanic** — hostile atmosphere, extreme heat, harsh weather. Forces the Advanced
  Greenhouse path (Biosphere Integration is low). High Protection/Enclosure
  (constant protection needed) and, via the temperature coupling, high Energy
  Management. Rich in structural/electronics ore and (per the
  hazard↔resource correlation principle) shielding-relevant rare materials.
- **Verdant/Temperate** — hospitable atmosphere, mild hazards, rich native
  biosphere. Favors the Local Agriculture path (Biosphere Integration is
  high). Low Protection/Enclosure and low Energy Management (little climate
  control needed). Scarcer rare/advanced materials — tech progression here
  has to come from somewhere other than raw material abundance.
- **Arid/Desert** — poor farming substrate (water/organic scarcity) but abundant
  baseline Energy (strong sun). High Synthesis/Self-Sufficiency (heavy
  reliance on synthesis/hydroponics to compensate for the substrate); likely
  low Energy Management, since abundant Energy offsets what upkeep exists;
  low Biosphere Integration (little native biosphere to integrate with).
- **Frozen/Ice** — weak/distant sun, extreme cold. High Energy Management
  (Energy is the constrained resource) and high Protection/Enclosure
  (enclosure is mandatory, via the same temperature-coupling logic as
  Volcanic, just for cold instead of heat). Low Biosphere Integration.

> **Open questions:** the exact quantitative pressure distribution (dominant /
> moderate / minimal) per planet across all four dimensions is not yet defined —
> flagged to return to after Exploration is worked through. Terrain layout and
> Energy base regeneration rates per planet are also still open.

### Hazard Priors (Safeguard Coalition's TrueRisk Values)
Feeds the Safeguard Coalition's Bayesian `MatchedRisk` calculation (see [SEED Factions](06_planets_and_scoring.md#seed-factions)
in [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)). Each value is a **probability that the danger
proves insurmountable for humans**, not just a severity/presence rating. Granular
sub-factors exist to inform event-spawning design (storm frequency, etc.) even
though the actual scoring formula only uses the two top-level axes
(`TrueRisk(Weather)`, `TrueRisk(Bio-hazard)`), each the **arithmetic mean** of its
sub-factors.

**Weather** — Storm Severity/Frequency, Temperature Extremity, Atmospheric Hazard
(toxic/corrosive/thin atmosphere, distinct from temperature or storms).
**Bio-hazard** — Pathogen Threat (microbial and viral risk, merged into one
sub-factor since they behave identically for every current planet type) and
Toxic/Parasitic Organism Threat (contact-based danger from native life, distinct
from infection-based Pathogen Threat). Per-planet values for both axes: see
`data/hazard_priors.csv`.

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
- **`Confidence(sub-factor) = min(ν / m, 1)`**, where `ν = a+b` (total evidence,
  prior included) and `m` is that sub-factor's **max-needed data count** (see
  `data/data_gathering_targets.csv`) — linear progress toward a ceiling, full
  at `ν ≥ m`. **Deliberately based on `ν` (evidence count) rather than raw
  distribution variance** — variance conflates "how much data has been gathered"
  with "how far the mean sits from 0.5" (`Var = μ(1-μ)/(ν+1)`), meaning an obvious
  extreme hazard would appear falsely confident with very little data, for reasons
  the player can't perceive since the true value is hidden — a legibility problem.
  Basing it on `ν` alone means every report contributes predictably and
  equally, regardless of which way it leans or what the hidden true value is —
  and the linear-to-`m` shape means that contribution stays *visibly* even,
  rather than tapering asymptotically where the player can't tell whether more
  data is still worth gathering. `Confidence(sub-factor)` is exactly what the
  `Data(axis)` term in [SEED Factions](06_planets_and_scoring.md#seed-factions) below aggregates.
- **Implementation footprint**: just two running counters per sub-factor (ten total
  across all five). No distribution objects, no sampling.

**Per-sub-factor data sources, success/failure definitions, and player-facing
text:** see `data/data_gathering_sources.csv`.

Individual reports appear as short log entries (fits the Transmissions record or
simulation log, consistent with existing UI patterns). The derived
`Confidence`/`MatchedRisk` values surface separately as an inspectable summary stat
per hazard sub-factor (e.g. in a Planetary Assessment panel), updating quietly as
reports accumulate — never something the player calculates themselves.

**This same underlying mechanism is reused for other factions' data-collection
scoring**, not just Safeguard — Stewardship Caucus's `EcologicalData` (see [SEED Factions](06_planets_and_scoring.md#seed-factions)
in [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)) applies it in simplified form, needing only the
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
settlement through several routes (see Bio-hazard, below). Atmospheric
Hazard stays a **continuous check**, never a scheduled event — see its own
subsection below.

At **run generation** the game rolls, once and for the rest of the run:
which seasons carry a Storm and/or a Temperature Extremity event, and each
scheduled event's **severity band (mild or extreme)** — the same coarse
band described below, pre-rolled here rather than at event time, weighted by
that hazard's `TrueRisk` (a worse-off planet gets more scheduled events and
skews them more extreme). This schedule is **deterministic once rolled** —
never re-drawn. The only part still rolled at simulation time is *when
within* a scheduled season the event occupies the Mid-Sim window: it hits
one or more **random intervals** of that season, not the whole of it.

**Telegraphing — two messages, from two different places.** At the start of
every season's planning, the **Transmissions** channel (see Story & World's
[Gameplay-Story Integration](02_story_and_world.md#gameplay-story-integration)) carries a short exchange:

1. **The settlement reports the season it can see** — "this one's looking
   calm," or whatever is true. Instruments on the ground, no analysis: it
   covers the current season only and is always available.
2. **Earth answers with the forecast** — "based on the data you've sent, in
   *k* seasons there'll be a particularly stormy one." This is the
   `Confidence`-scaled lead time below, and it is an *analysis product*:
   SEED correlating this planet's readings against archetypes from prior
   missions. The settlement supplies the data; Earth supplies the foresight.

That split is what the final run removes — Earth's answer is cut, the
settlement's own report is not (see Story & World's [Modes](02_story_and_world.md#modes)). The current
season stays legible, so no event is ever an ambush; only the ability to
plan several seasons ahead is lost.

Earth's answer reports the next inbound scheduled hazard
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

All delivered via the existing **Transmissions** mechanic — this section is
that mechanic's concrete realization, not a new system layered on top of
it. **Transmissions carries everything predictive or reported** — telegraphs
and individual data reports alike — while the simulation log carries only
what actually happened during Mid-Sim.

**Scoring reads `TrueRisk`, never the realized schedule.** A run that
happened to draw few events doesn't score better for the same decisions;
`MatchedRisk` asks whether protection matched the planet's risk profile and
`Data` whether the player found that profile out.

**No extreme-band event is ever scheduled in the opening seasons** (count:
see `data/misc_balancing_values.csv`'s "Hazard schedule" row) — a
generation-time constraint rather than a `Confidence` floor, so a turn-one
settlement can't be handed a catastrophe it had no instrument to see
coming.

**Event severity — a coarse band, shared by Storm and Temperature
Extremity.** A band also sets **how long the event occupies the Mid-Sim
window** — mild events run one short interval, extreme events longer and
possibly two (durations in seconds of Mid-Sim: see
`data/misc_balancing_values.csv`'s "Hazard event duration" rows). Each
scheduled event carries one of two severity bands,
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

**Aftermath reporting.** The post-event log states each affected site's
coverage state at the moment the event hit, and distinguishes a
**deterministic** loss (unshielded, extreme severity) from an **unlucky
collateral roll** — the difference between "you left this open" and "this
one was chance," which is the whole of whether the player has something to
do differently next time. Any settler death a hazard causes routes through
the same **death-acknowledgment line** as a starvation death; every death is
acknowledged, whatever killed them.

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
  - **Extreme event** → a casualty roll (see
    `data/hazard_casualty_weights.csv`) resolving to nothing, an SP
    injury, a permanent injury, or death, on the shared taxonomy in
    Settlers & Exploration's [Injuries](05_settlers_and_exploration.md#injuries). Injury is the common result and death
    the rare one; death uses the same roster-removal mechanic as
    everywhere else.
  - Protection is shared with the production-side consequence: a funded
    Weather/Row Shield covers both crops and any settler working that
    site via one shared coverage check. Settlers additionally have a
    personal option production sites don't: Temperature-Resistant Gear
    (see Buildings & Economy's [Fabrication](04_buildings_and_economy.md#fabrication)), covering farm-based settlers
    via a passive stock check the same way PPE covers Atmospheric Hazard.

**Storm** — preparedness-coverage tiers, same shape as before, plus a new
top-severity consequence:
The tiers read off one **coverage ratio**: the site's funded `Preparedness`
over the event's severity-banded demand.
- **Shielded** (ratio ≥ 1) → no effect
- **Under-covered** (a funded shield, but ratio < 1) → production paused for
  the event's duration
- **Unshielded** (no funded shield at all) → production paused at mild
  severity; at **extreme** severity the affected outdoor Farm/Production
  site is **destroyed** — removed from the grid entirely, not merely paused
  — requiring an ordinary construction-robot build action to reconstruct
  from scratch on the now-empty slot, per Platform & Core Loop's
  Construction. So the worst outcome is reserved for the case the player
  simply didn't answer, and only when the planet swung hardest.
- When a storm event is scheduled at **extreme** severity, every *other*
  unprotected building on the grid (any category, not just the
  directly-targeted Farm/Production site — "unprotected" reuses the same
  Weather/Row Shield coverage check) independently rolls a small chance of
  the same fate. Chance value: see `data/misc_balancing_values.csv`'s
  "Storm" row.
- **Settler and drone casualties.** At an affected site with no shield
  coverage, an unprotected outdoor settler takes a **casualty roll** (see
  `data/hazard_casualty_weights.csv`, which bands by the event's severity)
  resolving to nothing, an SP injury, a permanent injury, or death, on the
  shared taxonomy in Settlers & Exploration's [Injuries](05_settlers_and_exploration.md#injuries) — injury is the
  common result, death the rare one. An unprotected outdoor worker drone is
  **destroyed** — the same unit-loss mechanic used elsewhere. Outdoor workers on a shielded tile
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
- **Exposure is checked on the quarter-season epidemiology tick** (below),
  reusing that cadence rather than introducing a second one: each tick,
  every outdoor settler with no PPE in stock rolls exposure at a probability
  scaled by `TrueRisk(Atmospheric Hazard)`. This is what makes it a
  continuous check rather than a scheduled event — there's no telegraph,
  only a standing condition the player either answers or doesn't.
- Exposure without PPE (either context) inflicts a **status effect** (see
  [Settlers](05_settlers_and_exploration.md#settlers) & Exploration's [Settler State](05_settlers_and_exploration.md#settler-state)): triggers on exposure, persists
  for roughly 3 seconds of Mid-Sim time afterward, halves the settler's
  effectiveness in all tasks (their worker-effort contributes 0.5 instead
  of 1, per Worker Assignment's Effort model), and locks them
  out of exploration-task assignment entirely while active. Exposure also
  carries a small **casualty roll** (see
  `data/hazard_casualty_weights.csv`) that can leave an SP or permanent
  injury on the shared taxonomy in Settlers & Exploration's [Injuries](05_settlers_and_exploration.md#injuries) —
  corrosive/toxic atmosphere doing lasting harm. Unlike the two scheduled
  events, it has no death outcome.

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
crops), **predator** (preys on husbandry animals, and can kill settlers),
or **pollinator** (see below — the one *beneficial* kind); a **size
class** — tiny, small, medium, large, huge, or titan
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

Per-tier effect on that cycle's harvest (clamped ≥ 0): see
`data/wild_animal_grazer_effect.csv`. **Titan** grazers act **one tier
higher** for this effect only (a titan-sized high population behaves as
overrunning) — their growth-target tier is unaffected. **Every plant-crop
yield is a range `[min, max]`, rolled uniformly** — a value that was a
flat `v` is `[v, v]`; whether building upgrades widen the range is TBD
(see `data/misc_balancing_values.csv`'s "Wild Animal Populations" row). If a fence protecting a matching site is breached mid-season,
that site is exposed to grazing for the rest of Mid-Sim immediately, not
just from the following season. Two things remove a site from a grazer's
diet entirely, rather than merely blocking reach: a **Hydroponic Farm**
(Indoor, never a target at all — see Buildings & Economy's [Hydroponic Farm](04_buildings_and_economy.md#hydroponic-farm)),
and a plant-crop building whose **Grazer immunity** hybridization has been
researched (see [Hybridization](04_buildings_and_economy.md#hybridization)) — its building type stops counting as
that population's food at all, settlement-wide, for the rest of the run.
Neither site type contributes to a grazer's growth site-count either,
for the same reason: it was never food to begin with.

**Predators.** A reachable predator population, for each prey archetype
with a **reachable domesticated site**, rolls once per site (at Post-Sim,
after carrier infections and before population growth — see below) for a
**chance — scaling with tier — to destroy that site** (the husbandry site
reverts to an idle, empty state; see Buildings & Economy's [Animal Husbandry](04_buildings_and_economy.md#animal-husbandry)).
**Titan** predators succeed automatically against any reachable site. A
predator only ever "affects" domesticated animal sites of its prey
archetypes — never crop sites, and never a settler directly *except* the
one working a site it's actively preying on: if present, and the predator
is **large, huge, or titan**, there is also a chance it kills that settler
(medium and smaller predators never kill settlers). Predators are drawn
**only by prey**, never by settlers alone; it's meant to be common for a
predator population to exist nearby without ever touching the settlement
in a given season, if it has no reachable prey.

**Pollinators.** The one beneficial kind: a wild pollinator population
applies the same ambient **crop-yield amplification** a domesticated
Pollinator hive does (see Buildings & Economy's [Animal Husbandry](04_buildings_and_economy.md#animal-husbandry)) to every
reachable matching plant-crop site, for as long as it exists at any
nonzero tier. It has no domesticated-site or diet/prey list at all — see
its distinct site-count rule under Growth & Decay, below.

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
target — see `data/wild_animal_growth_tiers.csv` for the site-count-to-tier
mapping.

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

A **pollinator's** site count is flat: always **1**, with no domestic-site
or wild-forage component at all — it has nothing to graze and nothing to
grow toward. Predator suppression still applies to it exactly like any
other prey archetype, clamped at 0. Left unpredated, a wild pollinator
population therefore settles at **low** and stays there indefinitely; any
predator that lists it as prey readily suppresses it toward **none**.
World generation may still seed one at any tier up to high like other
populations (see Seeding, below), but absent a matching predator it drifts
back down to low within a season or two under the standard
one-tier-per-season movement rule.

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
as if unfenced, and never targets them for destruction. **No fence tier
blocks tiny or small populations at all** — their only counter is a **Tiny
Trap** or **Small Trap** in general inventory (see Buildings & Economy's
Fabrication), auto-consumed at Planning Lock-in in any season where a
matching-size population would otherwise have reached a site; while
consumed, that size class simply cannot reach anything, settlement-wide,
for the season (feeding the same growth/decay model as fencing). An active
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
if blocked): see `data/wild_animal_wall_destruction.csv` for per-attacker
odds against each fence material.

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

**At a glance:**
- **Success** — survive to the season limit; score = a multi-sub-metric
  viability report, not one opaque number.
- **SEED Factions** — Sustenance, Safeguard, Stewardship, Development,
  Frontier Legends; each 0-100%, a normalized sum of that faction's own
  terms.
- **Critical Failure** — exactly one trigger: every settler dead
  (starvation, no Water infrastructure, or hazard casualties).
- **Gradual Decline** — a run can be lost slowly, with no single
  critical event.

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

**Each faction's score does double duty**: it's this run's viability
judgment, and it's what that faction pays out in **Favor** toward its
Initiative tree (see Story & World's [Meta-Progression](02_story_and_world.md#meta-progression)).

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
  rather than a secured reserve. **What counts as production**, for both
  terms: anything a **timed cycle produces during season simulation** —
  buildings and Standing Assignments alike — tallied as each cycle completes
  and recorded per season at Post-Sim. Exploration windfalls, Trade Agreement
  income, and the run-start loadout are **excluded**: they're luck, diplomacy
  and a gift respectively, not evidence this planet can sustain production.
  Consumption never reduces either term. For `NutritionIncome`, a cycle
  contributes its output's axes **minus any food it consumed**, so a Kitchen
  is credited for the nutritional improvement it makes rather than
  re-credited for the ingredients a farm already scored — raw ingredients and
  cooked meals both count, without the same food counting twice. Normalized before combining, per the
  "normalize before combining unrelated values" design principle.
- **Safeguard Coalition** *(name tentative)*. Prioritizes safety disjoint from raw
  sustenance — resilience against climate/weather, medical safety (including depth
  of biological research into the planet's pre-existing life), and information
  about planetary life, including whether sentient or organized life exists that
  might oppose human settlement.

  **Mechanically defined**, for two initial hazard axes — **Weather** and
  **Bio-hazards** (more could be added later):
  - `Data(axis)` — how complete the picture is on that axis, built up from
    its sub-factors and **normalized at every stage**, so each level is
    bounded to [0,1] before anything is combined (per the "normalize before
    combining unrelated values" design principle):
    - Each sub-factor has a **max-needed data count** `m` (see
      `data/data_gathering_targets.csv`) — the point past which more data
      stops adding understanding. Its normalized value is linear progress
      toward that ceiling: `Data_norm(sub-factor) = min(collected / m, 1)`.
      Collecting more than `m` earns nothing further, so dropping everything
      else to over-sample one sub-factor is never the scoring play.
      Diegetically `m` is the data volume at which human weather/biology
      modeling reaches useful predictive error on this planet; the player
      never needs that explanation, only the visible linear progress.
    - The axis value is its sub-factors' normalized values at **equal
      weight** — `1/3` each for Weather's three, `1/2` each for
      Bio-hazard's two — so `Data(axis)` is itself bounded to [0,1]. Equal
      weighting is what makes the final score legible as a call for
      *balanced* coverage: a player who knows what they focused on during
      the run can read the shortfall straight off the score.
    - Displayed to the player as a percentage (0–100%). Sources include
      passive structures accumulating readings over time and settler-crewed
      data-gathering missions (weather balloon, atmospheric sampling,
      bio-survey — see `data/data_gathering_sources.csv`).
  - `MatchedRisk(axis)` — a Bayesian "sureness" that this hazard is actually
    significant on *this specific* planet, computed from a **prior based on
    planet type** (e.g. Volcanic planets have a low prior for bio-hazard
    risk — not intuitively likely, even though a specific instance could
    still turn out high) updated by the reports collected. Tracked per
    sub-factor, then aggregated to the axis as the **mean of its
    sub-factors** — the same aggregation `TrueRisk(axis)` itself uses (see
    Hazard Priors), so the estimate and the quantity it estimates are built
    the same way. Being a probability, it's naturally bounded to [0,1].
  - `MatchedPreparedness(axis)` — built preparedness (Weather Shield and PPE
    for Weather; Medical Bay for Bio-hazards — see Buildings & Economy's
    [Protection](04_buildings_and_economy.md#protection) category) normalized against the *true* risk level, capped at
    1: `min(Preparedness / TrueRisk, 1)`. Read from **what stands at run
    end**, not averaged across the run: a settlement that survived long
    enough to identify a hazard and then answered it has done exactly what
    this faction values, so answering late still counts.
    - **Weather preparedness is the mean of its three sub-factors**, each
      counting the countermeasure that actually answers it: shields for
      **Storm**, shields or Temperature-Resistant Gear for **Temperature
      Extremity**, and PPE for **Atmospheric Hazard** — so the one
      countermeasure a sub-factor has always earns something, and no
      sub-factor can be answered by a countermeasure that doesn't apply to
      it.
    - **PPE counts both standing and spent.** Stock on hand at run end
      covers settlers the same way a shield covers buildings, and a
      **running tally of PPE consumed to counter an actual threat** across
      the run counts alongside it — the one deliberate exception to reading
      preparedness from what stands at run end, since consuming PPE against
      a real exposure is the clearest possible evidence of a matched
      response, and it would be perverse for using it to score worse than
      hoarding it. The sub-factor is still capped at 1 and is still one of
      three, so PPE alone can never carry more than a third of Weather
      preparedness however much of it gets spent.
    - **Preparedness counts what's actually addressed, not structures
      owned.** For Weather, a shield contributes for the
      otherwise-unprotected buildings it brings under cover; more shielding
      over already-covered buildings contributes nothing. For Bio-hazard,
      a Medical Bay contributes its **best countermeasure tier standing**
      (a second Medical Bay unlocks nothing the first didn't, since a
      countermeasure is a settlement-wide fact) plus **recovery capacity up
      to the current settler headcount** — capacity beyond the number of
      people who could need it addresses nobody. A consequence worth
      naming: losing a settler lowers that cap, so a shrinking crew reduces
      the credit for capacity built for a larger one. This is what stops
      last-season credit from degenerating into stacking redundant
      structures.
  - **The Safeguard score** is one weighted sum across both axes, every term
    already bounded to [0,1], with weights that sum to 1 (see
    `data/misc_balancing_values.csv`'s "Safeguard Coalition" rows):

    ```
    Safeguard = 0.3 × Data(Weather)
              + 0.3 × Data(Bio-hazard)
              + 0.2 × MatchedRisk(Weather)    × MatchedPreparedness(Weather)
              + 0.2 × MatchedRisk(Bio-hazard) × MatchedPreparedness(Bio-hazard)
    ```

    The two kinds of term answer different questions, which is why data
    deliberately outweighs the matched terms. **The data terms support a
    decision independent of how this particular expedition went** — humanity
    gets one experiment per exoplanet, so knowing the planet is worth
    something regardless of whether this crew thrived. **The matched terms
    treat the expedition as representative**, reading viability as the match
    between human capability and the planet, which is what makes finding a
    genuinely liveable world before time runs out worth anything. Pairing
    `MatchedPreparedness` with `MatchedRisk` is also what keeps preparedness
    from being credited as luck: it counts once there's enough sureness to
    read it as a deliberate, verified response to a known hazard.
  - This isn't only a scoring abstraction — some preparedness actions have a
    **functional data prerequisite** in-fiction, not just a scoring one (e.g. an
    effective vaccine can't be produced without first collecting enough bio-data to
    characterize the actual pathogen). A planet with a genuinely high, surprising
    hazard forces the data-gathering that unlocks dealing with it anyway, so
    information-gathering isn't an artificial side-quest bolted onto survival.
- **Stewardship Caucus** *(name undecided — alternative: Non-Intervention Bloc)*.
  Conservation-minded: opposes humans acting as a colonial force, wants to "do
  things right this time" — both to avoid repeating Earth's mistake and out of
  genuine concern for colonized life/planets. Likely pulls against the Development
  Bloc mechanically — probably rewards leaning into strategy dimension
  **Biosphere Integration** and penalizes aggressive extraction/strategy
  dimension **Synthesis/Self-Sufficiency** play.

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
    to cover, **founding the settlement adds a small flat amount** (see
    `data/misc_balancing_values.csv`'s "Stewardship (DisruptionFootprint)"
    rows) — there is no zero-impact way to settle an alien world.
    **Further disruption**: among disrupted slots, ones whose underlying
    feature required active discovery (a Mid-depth or Deep tier survey
    reveal) before being acted on contribute more than a base-disrupted
    slot does — surfacing something genuinely hidden is worse than using
    something already visible from Season 1 (Surface-tier deposits, Forest
    tiles, which were never hidden and so never get this extra weight).
    Exact weighting: see `data/misc_balancing_values.csv`'s "Stewardship
    (DisruptionFootprint)" rows. **Fencing extends this beyond
    fixed/environmental slots**: a built fence tile (see Buildings &
    Economy's [Fencing](04_buildings_and_economy.md#fencing)) counts as disrupted the same as a changed
    fixed/environmental slot, whatever the tile underneath; a
    **planned-but-not-yet-built** fence tile counts for less (see the same
    rows).
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
    regardless of whether the attempt itself succeeds. Exact tier values:
    see `data/misc_balancing_values.csv`'s "Stewardship (ContactRestraint)"
    row.
  - These five are genuinely different *kinds* of quantities (a
    data-completeness percentage, a spatial ratio, two differently-shaped
    extraction/emissions penalties, and a discrete per-run tier), so each
    is normalized to a comparable [0,1] scale before combining, per the
    "normalize before combining unrelated values" design principle:
    `Stewardship = normalize(EcologicalData) + normalize(DisruptionFootprint) +
    normalize(ExtractionRestraint) + normalize(EmissionsRestraint) +
    normalize(ContactRestraint)` (term weights: see
    `data/misc_balancing_values.csv`'s "Stewardship" row)
  - A fifth axis — rewarding informed integration of native species over
    Earth-imported ones, gated by whether that species has actually been studied —
    was considered but dropped as too mechanically complex alongside these four.
- **Development Bloc.** Prioritizes resource access for advanced technology —
  rewards stockpiles of non-food resources (especially rare ones) and achieving
  more advanced technology tiers as evidence those resources are available. Likely
  ties to strategy dimension **Synthesis/Self-Sufficiency** and the rare-metals/Ore economy. A
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

**No Deep Space Beacon is the one non-fatal way to fail.** A settlement that
reaches the end of the run without having raised one (see Buildings &
Economy's [Deep Space Beacon](04_buildings_and_economy.md#deep-space-beacon)) was never found by anyone who came
after, so its expedition amounts to the same thing as one that died —
scored as a failed run, not as a low-scoring successful one. It doesn't end
the run *early*, unlike colony-wide death; it's discovered at the end.

**A failed run is scored, not voided — it's capped.** Every faction's score
is computed exactly as it would be otherwise, then **capped at that
faction's current Favor payout bar** (see Story & World's [Favor](02_story_and_world.md#favor)). Two
things follow, and both are intended: the run **pays no Favor**, since
paying requires clearing a bar the score can no longer exceed; and the run
still produces a real score that goes into run history rather than a blank.
The only cost is a little **feedback precision** — a failed run that would
have scored above the bar reports the bar instead, so a capped score is
displayed as a floor ("at least this") rather than a measurement, and is
not comparable against uncapped runs.

### Gradual Decline
- Poor seasons compound: fewer resources, understaffed sites, harder recovery
- A run can be effectively lost through slow decline without a single critical event
