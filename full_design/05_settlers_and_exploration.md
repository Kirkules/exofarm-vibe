# Settlers & Exploration

## Settlers

- A small group of **human settlers** (3–4 at run start)
- Named individuals, with real per-settler state (see Settler State, below) —
  no longer "no individual gameplay mechanics" now that Frontier Legends,
  injuries, and Atmospheric/Temperature hazards all need it. Settlers may form
  an exclusive-pair romantic relationship, arbitrarily/randomly, surfaced to
  the player via a Transmission — **pure narrative flavor with no mechanical
  effect** (see Story & World's Narrative-Only Flavor).
- Settlers must be **fed** each season; starvation is a critical failure condition (see
  Food & Nutrition)

### Settler State

Each settler carries:
- `current_assignment` — what they're doing this season: a Production
  building, Standing Assignment, Exploration Task, or idle. Lives on the
  settler, but *sticky*/*locked* behavior is a property of the assignment
  target, not something the settler itself knows:
  - **Production building** — remembers its last-assigned settler and
    defaults `current_assignment` to them at the start of each planning
    phase; just a default, freely changeable.
  - **Exploration Task, incomplete/multi-season** — remembers its assigned
    settler and *forces* `current_assignment` back to them every season
    until the task resolves; locked, cannot be reassigned during planning.
  - **Exploration Task, completed** — no longer occupies a pool slot,
    nothing to default from; the settler comes out unassigned.
  - **Standing Assignment** — stays one-shot, no stickiness, unaffected.
- `status_effect` — a list of concurrently-possible entries (not a single
  field): Injury (see below), Atmospheric Hazard, Temperature Extremity
  (slowed), and Storied.
- `legend_value` — a list of completed sites/achievements, not just a
  scalar; the Frontier Legends formula (see Win/Lose Conditions) sums it,
  and the list itself feeds personnel-file/end-of-run report display.

### Injuries

Designed independently of *where* a settler gets hurt (exploration,
Atmospheric Hazard, Temperature Extremity) — this taxonomy is shared by all
of them, referenced rather than repeated wherever injury/death is mentioned
elsewhere in this design. Two categories:

- **Semi-permanent (SP)** — broken bones, sprains, moderate burns,
  concussions. No standalone debuff number of its own — its entire
  mechanical expression *is* the eligibility and delay rules below;
  inventing an additional debuff on top would be functionally irrelevant,
  since it would disappear the moment it could matter. Heals automatically:
  each SP injury takes a **quarter-season** to heal. Without a Medical Bay,
  multiple SP injuries heal **serially** (one quarter-season each, in
  sequence); with a Medical Bay, they heal **simultaneously** — same
  quarter-season per injury, but in parallel, so Medical Bay's entire value
  is collapsing N×(quarter-season) down to one quarter-season when a
  settler has more than one SP injury at once. (With exactly one SP injury,
  Medical Bay makes no difference.)
  - **Exploration eligibility**: ineligible for Low-risk or High-risk
    exploration tasks; eligible for No-risk tasks, with a small penalty to
    success chance — applying only to No-risk tasks that already have a
    probabilistic success chance (Achievement-flavor), never to
    guaranteed-if-attempted ones.
  - **On-site assignment**: a settler assigned to a Production building or
    Standing Assignment has their actual work delayed until they've
    recovered — the recovery period occupies the first portion of that
    season's Mid-Sim window, with normal work resuming for the remainder.
- **Permanent** — loss of a limb or eye, brain damage, severe burns. Carries
  a real ongoing debuff, since it never resolves. Four types, each affecting
  a different aspect of assignment rather than sharing one number. Two
  reusable task groupings do most of the work here:
  - **Outdoor/Fieldwork**: every Exploration Task, all Farm/Production
    buildings, all mining (Mine, Quarry, Rare Metal Extractor),
    Clear-Cutting, Trapping, Basic Deposit Survey, Deep Survey.
  - **Manual Labor**: Outdoor/Fieldwork above, plus Kitchen, Robotics
    Assembly, Stone Processing, Carpenter's Shop. Everything **not** in
    this set (Research Lab, Medical Bay, Scanner Station, Tinkerer's
    Workshop) is "non-manual."

  With those two groupings:
  - **Loss of a leg** — bars Outdoor/Fieldwork entirely; everything
    non-Outdoor (Kitchen, Research Lab, all four Fabrication buildings,
    Medical Bay, Scanner Station, Water buildings) stays open.
  - **Loss of an arm** — bars nothing, but cuts work speed to 50% on every
    assignment except the non-manual set (Research Lab, Medical Bay,
    Scanner Station, Tinkerer's Workshop), and separately reduces success
    chance on *any* probabilistic exploration outcome regardless of risk
    tier — broader than SP injury's No-risk-only penalty.
  - **Brain damage** — bars the non-manual set entirely (only Manual Labor
    tasks stay eligible). Within exploration specifically, reuses risk
    tier as a complexity proxy rather than a separate taxonomy: Low-risk
    and High-risk tasks count as "too complicated" and are barred, No-risk
    tasks stay eligible — the same shape SP injury already uses for
    exploration.
  - **Severe burns** — bars nothing, cuts work speed to 75% on Manual
    Labor tasks specifically — narrower in scope than Arm Loss, but a
    smaller cut.
- **Risk tier gates severity directly**: Low-risk task failure can only
  produce SP injury or nothing — never permanent injury, never death.
  High-risk task failure can produce any of {nothing but no reward, SP
  injury, permanent injury, death}.
- **Negative outcomes only trigger on task failure**, for tasks with a real
  success/failure split (Achievement-flavor Legend outcomes, First
  Contact's Bluff/Military branches): on failure, roll a negative-outcome
  type from {nothing but no reward, SP injury} for Low-risk tasks, or
  {nothing but no reward, SP injury, permanent injury, death} for
  High-risk tasks. This does **not** apply to the separate
  guaranteed-success-with-independent-risk shape (Site Reveals,
  Hybridization opportunities, most Planet exclusives — see Risk
  Spectrum) — those tasks have no failure state to gate on, and keep
  their existing independent roll unchanged.

### Storied

A positive `status_effect`: once a settler's `legend_value` sum crosses a
threshold (TBD, deferred to balancing), they permanently gain:
- **+15% production speed** on Production-building assignments, and on
  Trapping/Clear-Cutting now that both are production-speed-based (see
  Standing Assignments, below).
- **+1 to the upper bound** of any exploration-task outcome with a numeric
  quantity range, regardless of which outcome category it's filed under.
- **A relative success-chance boost** on any probabilistic exploration
  outcome: `p_new = p + 0.25(1 - p)`.
- **A relative reduction to bad-outcome probability** on any risky task:
  `r_new = 0.75 × r_old` — a distinct, simpler formula from the
  success-chance boost above, applied to the negative-outcome rolls
  described in Injuries.

Diegetically: an experienced, renowned settler is just genuinely better at
their job — low mechanical overhead (one threshold check, a handful of flat
modifiers), self-limiting rather than unbalancing, since Legend outcomes are
already rare by design.

---

## Exploration Tasks

### Overview
- Feel like **side quests** — event-like, not a routine every-season mechanic
- **Always available, every season** — not gated to a periodic window, since
  the player never has to commit to anything in the pool anyway. A pool of
  up to **3 tasks** is presented at all times during planning.
- **Refresh**: the entire pool refreshes on two triggers — automatically at
  the start of each season, and manually via reroll (below) — except any
  task the player has explicitly **locked**, or any task **in progress**
  (assigned but not yet resolved, whether just assigned this planning
  session or still running from a prior one — see Seasons to complete,
  below). Locking is free and applies only to unaccepted tasks; both locked
  and in-progress slots are exempt from every refresh trigger until they're
  unlocked or resolve, the in-progress case simply being automatic rather
  than something the player has to toggle on.
- **Manual reroll costs Energy** — a flat amount (TBD), drawn from the
  Energy Pool's current balance (see Resources), not its cap — framed as
  tasking local sensors/drones with a fresh sweep of the surrounding
  region, the same principle already used at the hub level for
  filament-scanning. Scanner Station upgrades may reduce this cost.
- **Pool size**: 3 by default. Scanner Station upgrades and a Research Lab
  project ("Expanded Reconnaissance Doctrine") each permanently add +1,
  for a maximum of 5. Exact tier mapping TBD.
- **Seasons to complete**: every task has one. As the general rule, this
  equals its Ration cost (below) — a Ration is already defined as exactly
  "1 settler, 1 season," so a task's sustenance cost and its duration are
  the same number by construction, not two independently-set values. Any
  task that ever wants these to diverge would be a deliberate, flagged
  exception. A multi-season task occupies its pool slot as in-progress for
  its entire duration, per the refresh-exemption rule above.
- Number and quality of available tasks varies by planet type and meta-progression unlocks

### Assignment
Exploration Tasks are one of the three Assignment target kinds (see Core
Loop & Grid's Assignment) — settler-only, one-shot, drawn from the pool
above. What's specific to Exploration Tasks beyond the general Assignment
mechanics:
- Multiple tasks can run simultaneously if the colony has enough settlers and
  **Rations** to send (see Food & Nutrition). Unlike at-home settlers (who
  can be fed by any food type — Meals, raw crops, or Rations), an exploring
  settler's cost is a **strict Rations requirement** — no substituting fresh
  food, since it has to travel with them. Mechanically, the moment a
  settler is assigned to a task, they're removed from the settlement's
  pooled nutrition headcount for that season (see Food & Nutrition's
  Consumption), and their sustenance instead becomes that task's Ration
  cost, consumed at season-simulation-start alongside any other consumable
  the task requires (below).
- **Cost, most tasks**: 1 Ration base (see Seasons to complete, above),
  plus an optional or mandatory consumable item depending on the specific
  task — an optional item typically guarantees the top of an outcome's
  value range or unlocks a bonus reward component; a mandatory item is a
  hard prerequisite the task can't be attempted without at all (Deep Survey's
  Portable High-Powered Scanning Equipment requirement is the existing
  precedent for this). Full task-by-task costs are in the catalog below.
- **Some tasks are unmanned** (e.g. a weather balloon or camera drone), requiring no
  settler assignment at all — mostly data-collecting missions, making up some
  fraction of available tasks. This means a player could plausibly complete an
  entire run without ever sending a settler out; the Frontier Legends SEED faction
  (see Win/Lose Conditions) specifically rewards choosing *not* to rely purely on
  the safer unmanned option.

### Outcomes
Four categories of positive result:
- **Resource windfall** — settler returns with rare resources or items; no persistent
  grid change
- **Site reveal** — a feature on the farm grid is transformed into a new accessible
  site; e.g. a mountain region becomes an exposed ore deposit, a cave system, or a
  volcanic vent; the revealed site persists for the rest of the run.
  **Hybridization opportunities** (see Buildings & Economy's Farm/Production)
  are a Site Reveal variant — what's unlocked is a Research Lab project
  rather than a grid feature.
- **Legend outcome** — rare, little or no material reward, but a large
  one-time Frontier Legends legend-value injection (see Win/Lose
  Conditions), usually tied to a genuinely story-worthy moment. Always
  **Neutral** within the Strategy Dimensions framing below, since its value
  lives entirely in the separate Frontier Legends axis, not A/B/C/D. Two
  flavors: **Achievement** (the settler *attempts* something specific —
  reach the deepest cave, chart the ocean floor — with a real, non-guaranteed
  chance of success; Low-risk, since failure can injure but never kill) and
  **Wonder** (something beautiful or striking simply witnessed, guaranteed
  if attempted since there's no attempt to fail; No-risk). (Settler-specific
  personal-story-moment outcomes are a natural extension here but left
  undesigned for now, pending the not-yet-built per-settler tracking system
  — see `DESIGN_TODO.md`.)
- **Farm-wide Upgrade outcome** — rare, unlocks a permanent settlement-wide
  passive improvement not tied to one specific building, reusing the shape
  already established for Water Processing Plant's Reclamation tier and
  Medical Bay's Vaccine Production — a second, exploration-specific pathway
  to that same reward shape, not a replacement for the existing
  tech/resource-gated one.

Many tasks yield only a windfall; the other three are less common, with
Legend and Farm-wide Upgrade outcomes rarer still.

### Task Catalog

First-pass content, numbers illustrative and TBD-balanced like everything
else in this design. Every task's "seasons to complete" equals its Ration
cost (see Assignment, above). **Large Backpack** (new: a Pelt-derived
Textile Workshop item, see Buildings & Economy's Fabrication) and
**Portable High-Powered Scanning Equipment** (existing, Tinkerer's
Workshop) are both consumed on use, same precedent PPE already established
for exploration-task consumables.

**Resource windfall and generic Site Reveal:**

| Task | Rarity | Risk | Season gate | Base cost | Item | Outcome |
|---|---|---|---|---|---|---|
| Wild Orchard Grove (Food-cache flavor) | Common | No-risk | 1+ | 1 Ration | Optional: Large Backpack → top of range | 2–5 Fruit and/or Grain |
| Predator's Larder (Food-cache flavor) | Common | No-risk | 1+ | 1 Ration | Optional: Large Backpack → top of range | 2–5 Milk and/or Egg |
| Abandoned Settlement (Food-cache flavor) | Uncommon | No-risk | 3+ | 1 Ration | Optional: Large Backpack → top of range | 2–4 Rations (preserved food) + alien-civilization escalation chance (see Escalation Chains) |
| Exposed Mineral Outcrop (Non-food flavor) | Common | No-risk | 1+ | 1 Ration | Optional: Large Backpack → top of range | 3–6 Ore |
| Unusual Rock Formation (Non-food flavor) | Common | No-risk | 1+ | 1 Ration | Optional: Large Backpack → top of range | 3–6 Stone |
| Crashed Debris Field (Non-food flavor) | Uncommon | No-risk | 3+ | 1 Ration | Optional: Portable High-Powered Scanning Equipment → *also* yields High-Tech Components | 2–4 rare metal (always guaranteed) + 1–2 High-Tech Components if scanner brought + alien-civilization escalation chance |
| Unusual Crystalline Growth (Rare-resource flavor) | Uncommon | No-risk | 4+ | 1 Ration | Optional: Large Backpack → top of range | 1–3 rare metal |
| Generic Ore/Stone Site Reveal | Common | No-risk | 1+ | 1 Ration | — | Reveals one undiscovered Ore or Stone deposit |
| Generic Aquifer Site Reveal | Common | No-risk | 1+ | 1 Ration | — | Reveals one undiscovered aquifer |
| High Pelt-Population Tile Reveal | Uncommon | No-risk | 2+ | 1 Ration | — | Flags one tile with boosted Trapping yield |
| Glinting Vein (rare-metal Site Reveal) | Uncommon | No-risk | 4+ | 1 Ration | — | Reveals one undiscovered rare-metal deposit |

Site Reveal tasks are 100% success if attempted — one settler finding one
specific thing, not a probabilistic area survey the way Basic/Deep Survey
already are — so they get no optional item; there's no quantity to boost.

**Legend outcomes and Weather Anomaly Investigation:**

| Task | Rarity | Risk | Season gate | Base cost | Item | Outcome |
|---|---|---|---|---|---|---|
| Reach-the-deepest-X (Achievement) | Rare | Low-risk | 6+ | 1 Ration | Optional: planet-appropriate gear (e.g. Temperature-Resistant Gear) boosts success chance | Chance of success (illustrative 40–50% baseline, higher with gear) → Legend value; on failure, further chance of injury, otherwise nothing happens |
| Chart-the-Y (Achievement) | Rare | Low-risk | 6+ | 1 Ration | Optional: Portable High-Powered Scanning Equipment boosts success chance | Same structure as above |
| Bioluminescent Bloom (Wonder) | Uncommon | No-risk | 3+ | 1 Ration | — | Guaranteed Legend value if attempted |
| Aurora Readings (Wonder) | Uncommon | No-risk | 3+ | 1 Ration | — | Guaranteed Legend value + one-time `Confidence(Weather)` burst |
| Crystal Caves (Wonder) | Uncommon | No-risk | 3+ | 1 Ration | — | Guaranteed Legend value, flavor only (crystals are non-extractable) |
| Weather Anomaly Investigation | Uncommon | No-risk | 3+ | 1 Ration | — | Guaranteed one-time `Confidence(Weather)` burst |

**Farm-wide Upgrades:**

| Task | Rarity | Risk | Season gate | Base cost | Item | Outcome |
|---|---|---|---|---|---|---|
| Ancient Irrigation Technique | Rare | No-risk | 6+ | 2 Rations | Mandatory: Portable High-Powered Scanning Equipment | Farm-wide Water reduction + moderate alien-civilization escalation chance |
| Recovered Survey Data | Rare | No-risk | 6+ | 2 Rations | Mandatory: Portable High-Powered Scanning Equipment | Farm-wide Deposit Discovery odds boost + high alien-civilization escalation chance |
| Symbiotic Soil Microbiome | Rare | No-risk | 6+ | 2 Rations | — | Farm-wide Alien Soil severity reduction |

Ancient Irrigation Technique and Recovered Survey Data both mandate
Scanning Equipment since they're about extracting/documenting something
technical; Symbiotic Soil Microbiome reads more like fieldwork than
technical recovery, so it gets a longer Ration cost instead of a special
item — a more careful survey rather than a documentation task.

**Planet exclusives.** Rarity here tracks *what* the outcome is, not risk
tier — all four Hybridization-granting exclusives are Rare regardless of
risk, since Hybridization is inherently a significant, permanent unlock;
the two plain Site-Reveal/Windfall exclusives sit a notch below at
Uncommon. Every Low/High-risk entry here is a guaranteed-success task with
an independent risk roll (see Risk Spectrum, above) — the find itself
never fails, but the dangerous environment can still injure or kill the
settler, which also earns them a Frontier Legends bonus when it happens:

| Task | Rarity | Risk | Season gate | Base cost | Item | Outcome |
|---|---|---|---|---|---|---|
| Verdant Reinforcing | Rare | No-risk | 6+ | 1 Ration | — | Hybridization opportunity (native plants, deepens B) |
| Verdant Profile-shifting | Rare | High-risk | 6+ | 1 Ration | Mandatory: Portable High-Powered Scanning Equipment | Site Reveal: rare-metal/Ore deposit (guaranteed) |
| Volcanic Reinforcing | Rare | High-risk | 6+ | 1 Ration | Mandatory: Temperature-Resistant Gear | Site Reveal: rare-metal deposit, shielding-grade flavor (guaranteed) |
| Volcanic Profile-shifting | Rare | Low-risk | 6+ | 1 Ration | Mandatory: Temperature-Resistant Gear | Hybridization opportunity (lava-tube fungi) |
| Arid Reinforcing | Uncommon | Low-risk | 3+ | 1 Ration | — | Site Reveal: Aquifer (guaranteed) |
| Arid Profile-shifting | Rare | No-risk | 6+ | 2 Rations | — | Hybridization opportunity (dormant seed bank) + Moderate alien-civilization escalation chance (see Escalation Chains) |
| Ice Reinforcing | Uncommon | Low-risk | 3+ | 1 Ration | Optional: Large Backpack → top of range | 2–4 rare metal (insulation flavor) |
| Ice Profile-shifting | Rare | Low-risk | 6+ | 1 Ration | — | Hybridization opportunity (warmth-pocket flora) |

**Meteorite Fragment** — planet-independent, not tied to any single planet
type's identity:

| Task | Rarity | Risk | Season gate | Base cost | Item | Outcome |
|---|---|---|---|---|---|---|
| Meteorite Fragment | Rare | No-risk | 8+ | 2 Rations | Mandatory: Portable High-Powered Scanning Equipment | Hybridization opportunity, planet-independent: unlocks research eligibility for all four plant buildings at once (each still an independent Research Lab project); signature benefit is a generic "broad yield improvement," not planet-specific |

**Unknown Radio Signal** — planet-independent, another alternate entry point
into the sentience-contact chain (see Escalation Chains, below), but its
branching resolution doesn't fit the single-row format above:

| Task | Rarity | Risk | Season gate | Base cost | Item |
|---|---|---|---|---|---|
| Unknown Radio Signal | Rare | Low-risk | 6+ | 1 Ration | Optional: Emergency Medical Kit (new, see Buildings & Economy's Protection/Medical Bay) — consumed on use |

Attempting it resolves the signal's true source, illustrative weights
biased toward the mundane (consistent with genuine sentient contact being
an exceedingly rare wildcard everywhere else in this design):

| Resolved cause | Weight | Outcome |
|---|---|---|
| Rare ore vein (natural EM/mineral resonance misread as a signal) | ~40% | Site Reveal: rare-metal deposit — same shape as Glinting Vein |
| Reflected signal (terrain echoing back an altered copy of the settlement's own scans) | ~40% | Wonder-flavor Legend outcome, guaranteed — an eerie, ultimately-mundane phenomenon, same register as Crystal Caves |
| Genuine distress signal (a living, stranded alien) | ~20% | See below |

Within the distress-signal branch, whether the Emergency Medical Kit was
brought determines what happens next:

| Kit brought? | Result | Escalation |
|---|---|---|
| Yes | Guaranteed rescue | Immediate escalation straight to **First Contact** (see Escalation Chains) — skipping Sentience Detection and Observe from a distance entirely, since a direct rescue already *is* first contact |
| No | ~20% rescue anyway (same immediate step-3 escalation); otherwise (~80%) the settler finds the alien too late to save | On the "too late" result: escalates into **step 1** (Sentience Detection) at a new, higher-than-any-existing-trigger tier — direct confirmed contact is stronger evidence than any of the five indirect triggers already listed, even though the alien couldn't be saved |

Both outcomes carry the chain's usual elevated legend value (see
Escalation Chains' Elevated legend value note below) and nothing more —
Legend value tracks the clout of a discovery, not how poignant the moment
was, so "found them too late" earns the same legend value as a clean
rescue, not less and not a sympathy bonus either.

The sentience-contact chain's own numbers are in Escalation Chains, below.

### Outcomes and the Strategy Dimensions
Every exploration outcome falls into one of three flavors relative to the four
strategy dimensions (A/B/C/D — see Exoplanet Types):
- **Profile-shifting** — unlocks or reveals something that opens up a dimension the
  current planet doesn't naturally favor (e.g. a rare mineral vein on an
  otherwise metal-poor Verdant planet, shifting toward A/D). This is exploration's
  *primary* purpose — the main route by which a run's strategic profile can move
  away from its planet's default. **Not inherently tied to risk tier** — a
  Profile-shifting outcome can be No-risk just as easily as High-risk; risk
  and reward rarity are independent axes except where a specific task is
  deliberately designed otherwise (see Risk Spectrum, below).
- **Reinforcing** — deepens a dimension the planet already favors (e.g. an
  exceptionally potent shielding-material vein on Volcanic, deepening A).
- **Neutral** — generic value with no strategic lean at all (a stockpile of
  ordinary materials, a plain resource windfall).

**Every planet type has at least one exclusive exploration possibility** unavailable
on any other planet, opening a path to special technology or another unique payoff:

| Planet | Reinforcing exclusive | Profile-shifting exclusive |
|--------|----------------------|----------------------------|
| Verdant/Temperate | Efficiently-farmable, broad-nutritive-value native plants (deepens B) | A concentrated mineral vein in deep jungle/cave exploration, unusual for a normally metal-poor planet (shifts toward A/D) |
| Volcanic | An exceptionally potent shielding-material vein found only in active volcanic zones, unlocking a high-grade protection tier (deepens A) | Hardy fungi/lichen thriving in lava-tube caves despite surface hostility (shifts toward B) |
| Arid/Desert | A hidden aquifer/oasis, dramatically boosting synthesis/hydroponic efficiency (deepens C) | A dormant seed bank preserved by desert conditions, reviving ancient native flora (shifts toward B) |
| Frozen/Ice | Ice-core samples yielding an exotic cold-adapted insulation material (deepens A/D) | Subsurface geothermal vents beneath the ice (cryovolcanism), harboring warmth-pocket life or synthesis opportunities (shifts toward B or C) |

### Escalation Chains
Some outcomes — of any flavor, including neutral ones — unlock a **follow-up
exploration option** that wasn't available before, guaranteeing it a slot in
the pool at its very next refresh (though it can still be discarded like
any other candidate via reroll, or protected with a lock the moment it
appears). This lets a single discovery grow into a multi-step arc rather
than resolving in one roll. Example: a neutral find of native
fruit stockpiles on a Verdant planet reveals the option to seek out the habitat of
the animal that gathers and preserves that fruit; succeeding at *that* task can lead
to an alliance with those animals — a passive, ongoing food source requiring **no
staffing at all**, a qualitatively different reward tier from ordinary production,
similar in spirit to how baseline Energy/Matter production is already zero-effort.

**Alien civilization classes.** Once Sentience Detection succeeds, the
specific civilization encountered is rolled from a small set of curated
archetypes — kept small and simple deliberately, since alien contact is
meant to stay a rare, occasional thread rather than a fully-developed
system of its own. Each class is a fixed combination of five axes:
- **Technology Level** — Primitive / Comparable / Advanced
- **Openness** — Closed / Guarded / Open
- **Economic Stability** — Fragile / Stable
- **Ubiquity** — which planet type(s) this class is eligible to appear on
  at all: Exclusive (one type) / Common (2–3 types) / Universal (any type,
  rare everywhere). A fixed, design-time fact per planet type, like Hazard
  Priors — the *specific* class actually encountered is rolled, weighted
  among the classes eligible for the current planet, the moment Sentience
  Detection succeeds, so it's still a fresh surprise each run despite
  Ubiquity itself being a known quantity.
- **Unity** — how consolidated the civilization is *within* the one planet
  where it's found, ranging from scattered, unallied tribes up to a
  unified, planet-spanning society. Distinct from Ubiquity (which is about
  which planet *types* it can appear on at all) — this is about its
  presence on the one planet where it's actually found. Governs whether
  First Contact's confrontation approaches (see below) can ever avoid
  total failure.

| Class | Ubiquity | Technology | Openness | Economy | Unity |
|---|---|---|---|---|---|
| Verdant Assembly | Exclusive (Verdant) | Comparable | Open | Stable | High |
| Hollow Kilns | Exclusive (Volcanic) | Advanced | Guarded | Fragile | Moderate |
| Drift Caravans | Common (Arid, Ice) | Primitive | Open | Fragile | Low |
| Frostbound Remnant | Exclusive (Ice) | Advanced | Closed | Stable | High |

**Biological Compatibility is deliberately not a mechanical property** —
it's pure per-class flavor text explaining why contact carries the injury
risk it already carries via the Risk Spectrum, not a new consequence
layer. Keeps the system from growing a sixth axis for a distinction that
doesn't need to change any numbers.

**Sentience-contact chain** (worked example, since it's the point where every SEED
faction's priorities can visibly pull against each other in a single decision — see
SEED Factions in Win/Lose Conditions):

| Step | Season gate | Base cost | Item | Success chance | Outcome |
|---|---|---|---|---|---|
| **1. Sentience Detection**, reached cold from the base pool | 8+ | 1 Ration | — | Low (~10%) | Success: `EcologicalData` + guaranteed escalation to step 2 |
| **1. Sentience Detection**, reached via an alien-civilization-implying trigger (Abandoned Settlement, Crashed Debris Field, Ancient Irrigation Technique, Recovered Survey Data, Arid Profile-shifting — see Task Catalog) | N/A, guaranteed placement | 1 Ration | — | Moderate (~30%) for the first four triggers, High (~60%) for Recovered Survey Data specifically | Same as above |
| **1. Sentience Detection**, reached via Unknown Radio Signal (distress signal confirmed, but rescue failed — see Task Catalog) | N/A, guaranteed placement | 1 Ration | — | Very High (~85–90%) — direct confirmed contact, stronger evidence than any other trigger | Same as above |
| **2. Observe from a distance** | N/A, guaranteed escalation | 1 Ration | — | Guaranteed | Elevated `EcologicalData` weight (a heavier increment than an ordinary biodiversity report, not a new score term) + unlocks **First Contact** |

**3. First Contact** surfaces in the pool as a **single guaranteed
escalation slot**, not three separate entries — its own UI lets the player
switch between three approaches before committing a settler, each pulling
its own cost and item:

| Approach | Base cost | Item | Success chance | Outcome |
|---|---|---|---|---|
| **3a. Peaceful Contact** | 2 Rations | Mandatory: Diplomatic Gear | Guaranteed attempt, Low-risk | Elevated `EcologicalData` weight, same as Observe; can unlock its own further escalation into an ongoing, deepening alliance/trade relationship (see below) — same zero-staffing passive-benefit reward tier as the fruit-animal-alliance example above. **Specific rewards TBD** — see `DESIGN_TODO.md` |
| **3b. Bluff/Coercive Exploitation** | 2 Rations | Mandatory: Diplomatic Gear | Attemptable against any class. High-risk. Success scales **inversely with Technology Level alone** — an advanced civilization has more information about what's actually possible, not more information about the settlers' specific claims, so it's harder to fool regardless of Openness or Unity. Rarely succeeds, but more often than 3c | On success: a one-time payout slightly better than an undeepened alliance's baseline — no ongoing relationship, since nothing was actually built. **Exact odds/rewards TBD** — see `DESIGN_TODO.md` |
| **3c. Military Exploitation** | 1 Ration | Mandatory: Armed Expedition Kit **and** Overwhelming Force Package (new — see Buildings & Economy's Fabrication) | Attemptable against any class. High-risk, **the largest death chance in the catalog**. Success scales against **both Technology Level and Unity together**, more steeply than 3b — only a Primitive-tech, low-Unity class has any appreciable chance; everywhere else the chance is real but vanishingly small | This is the concrete realization of the "aliens obliterating an aggressive explorer" example from the difficulty-principle discussion — a severe outcome from an explicit, knowingly-initiated high-risk choice, which the design principles explicitly allow even when it ends a run. A few settlers should essentially never be able to force anything from an entire civilization without a real technological edge. **Exact odds/rewards TBD** — see `DESIGN_TODO.md` |

Step 1 gives every alien-civilization-implying trigger a real, concrete
target rather than inventing a separate chain per trigger — this is
literally what "starting the sentience-contact chain" means whenever one of
those five is discovered.

**Direct entry to First Contact.** A successful rescue during Unknown Radio
Signal (see Task Catalog) skips straight to First Contact, bypassing
Sentience Detection and Observe from a distance entirely — a direct rescue
already constitutes first contact. All three approaches are still
available at that point; a rescue doesn't force the player into Peaceful
Contact specifically.

**Deepening an alliance.** Peaceful Contact's alliance/trade relationship
isn't a one-time payout — it deepens through follow-up exploration tasks,
each requiring Diplomatic Gear, using the same guaranteed-escalation-slot
shape as everything else in this section. Exact tier count and per-tier
rewards TBD, same as Peaceful Contact's base rewards.

**Elevated legend value.** Every task in this chain — the initial
detection, Observe from a distance, and First Contact regardless of which
approach is chosen — carries an elevated, design-authored legend-value
(see Frontier Legends in Win/Lose Conditions) relative to ordinary
exploration tasks, independent of which faction's priorities the outcome
otherwise served. First contact with intelligent life is one of the
rarest, most story-worthy events the game can produce, and Frontier
Legends rewards that inherently. **Scales inversely with the actual
success probability of whichever roll produced the outcome** — a rare
success (a Low-tier Sentience Detection roll, or a successful Bluff/
Military attempt against a well-defended class) earns more legend value
than a near-certain one. This is a general rule keyed to the roll's actual
probability, not a lookup table keyed to civilization properties directly
— keeps the formula simple even as class-specific odds vary. (Peaceful
Contact's own guaranteed attempt has no probability to scale by, so it
keeps its flat elevated value.) This stacks with (is separate from) the
general injury/death Legends bonus described in Risk Spectrum, below, if
Bluff or Military Exploitation goes badly.

**Vaccine-unlock region reveal** (third worked example): a bio-survey
exploration task discovering a dangerous pathogen (see Buildings & Economy's
Protection, Medical Bay) is tied to the specific region where it was found.
Once enough `Confidence(Bio-hazard)` accumulates and Medical Bay's Vaccine
Production tier unlocks for that pathogen, the settlement is assumed fully
vaccinated — and that unlock guarantees a new escalation: an exploration task
to explore the specific region the pathogen came from, previously too
dangerous to approach, now safe. A clean example of a *building* unlock
(rather than an exploration outcome) triggering an escalation.

### Risk Spectrum
Every task has exactly one of three risk profiles, defined by its worst
possible outcome — not by reward rarity, which is a separate, independent
axis (see Outcomes and the Strategy Dimensions, above):
- **No-risk** — cannot lead to injury or death. Results range from nothing
  to a good find.
- **Low-risk** — can lead to injury, cannot lead to death.
- **High-risk** — can lead to injury or death.

Injury and death consequences, and the full taxonomy of injury types, are
specified once in Settlers' Injuries subsection (above) rather than here,
since they're shared across every source of harm (exploration, Atmospheric
Hazard, Temperature Extremity), not exploration-specific. Death is the
settler's permanent removal from the roster, the same mechanic
starvation-death already uses.

**Guaranteed-success tasks with a risk tag** (Site Reveals, Hybridization
opportunities — anything that isn't an Achievement-flavor Legend outcome)
handle risk differently from Achievement outcomes, and differently from
the failure-gated negative-outcome pool described in Injuries: the find
itself is never in doubt, but the risk tier still applies as an
**independent roll** alongside it — the settler *will* discover the vein,
but the dangerous environment they found it in (an active volcanic zone, a
deep cave) can still injure or kill them regardless of the task's own
success. There's no "failure" state to gate on here, so this keeps its own
independent roll rather than folding into the failure-triggered pool. When
that happens, the settler earns a **Frontier Legends bonus** — large for injury,
moderate for death — for every task of this shape, not just
Profile-shifting-flavored ones: a settler who's hurt or lost expanding the
settlement's strategic options has done something legend-worthy regardless
of which specific dimension it moved. (Injury's bonus is larger than
death's — the settler who survives becomes a living legend who keeps
contributing to the colony's story; death is honored, but doesn't keep
generating one.)

For the specific tasks already designed as Low- or High-risk, the
original design intent still holds — risk-bearing tasks tend to guard
better rewards — but this is true of *those tasks specifically*, not a
universal rule; plenty of No-risk tasks (Meteorite Fragment, the
Wonder-flavor Legend outcomes, most Farm-wide Upgrades) are just as rare or
valuable. Planet type affects the proportion of Low/High-risk tasks
available (e.g. a volatile volcanic planet generates more of them).

---

## Standing Assignments

The other of the three Assignment target kinds (see Core Loop & Grid's
Assignment) — settler-only, drawn fresh each season rather than
pool-limited, and **safe** (no risk spectrum, no Rations — the work stays
on or near the farm, unlike a genuine off-site expedition). Four members:

- **Basic Deposit Survey** and **Deep Survey** (see Buildings & Economy's
  Deposit Discovery) — Basic Survey covers a player-chosen rectangle of
  tiles and flags which of them are worth a Deep Survey; Deep Survey then
  automatically targets every tile flagged that way so far, no rectangle
  choice needed. Both repeatable, one-shot per assignment (the settler is
  gone for the season and returns with a result) — the same resolution
  shape Exploration Tasks use.
- **Clear-Cutting** (see Buildings & Economy's Fuel) — production-speed-based,
  like a building: the player selects any number of individual Forest tiles
  (drag-click marks every eligible tile within a rectangle and can only
  mark, never unmark; single-tile click toggles mark/unmark on one tile at
  a time), and the assigned settler works through them during Mid-Sim — how
  many get fully cleared by season end depends on their speed, with any
  unfinished tiles carrying over if reassigned next season. Each tile's
  Wood is bounded and depletes with use.
- **Trapping** (see Buildings & Economy's Farm/Production) — also
  production-speed-based: targets one tile, yielding Pelt through repeating
  production cycles across the season's Mid-Sim window rather than a
  single lump-sum result, boosted by Forest presence and the planet's
  biological richness. Unlike Clear-Cutting, renewable and repeatable
  indefinitely on the same tile.

Trapping and Clear-Cutting's speed-based shape makes them eligible for
Storied's production-speed bonus (see Settlers) the same way a Production
building assignment is.

Since these aren't drawn from the Exploration Tasks pool, they don't
participate in that system's Reinforcing/Profile-shifting/Neutral outcome
framing (see Outcomes and the Strategy Dimensions, above) — they're
guaranteed, mundane, on-farm work, not strategic-profile-shifting content.

---

## Food & Nutrition

### Nutrient Axes
Every food item, including Rations, has a **Protein / Fat / Carbs / Vitamins**
profile — category names, not real-world units, consistent with the units/naming
principles (e.g. Bread: 1/1/5/0; an Apple: 0/0/1/1; Milk: 1/1/0/2; Rations: 1/1/1/1
per unit, matching "1 unit = 1 season's complete nutrition for 1 settler"). Visible
in any food item's info tooltip.

### Rations (Basic Sustenance)
Replaces the old Nutrient Paste mechanic (an automatic, endlessly-regenerating
Matter-conversion safety net) entirely — no auto-conversion exists anymore, and
there is no building filling that old "Matter Manipulator" nutrition role.
- Every settlement starts with a **fixed, non-replenishable quantity** of
  pre-packaged Rations (exact starting quantity TBD, deferred to a balancing
  pass) — densely packed, unappetizing, meant only to sustain life.
  Conceptually analogous to the old Nutrient Paste in flavor, but a genuine
  finite starting stockpile, not an ongoing conversion the player can always
  fall back on.
- **No automatic replenishment** — once the starting stock (plus anything the
  player has manually produced, see below) is gone, there is no free fallback
  left. This is the point: it replaces an ongoing-but-costly safety net with a
  hard countdown, creating more natural, legible pressure to establish real
  Kitchen/Farm food production early, rather than a Matter tax that could
  always be paid indefinitely.
- **Can be manually replenished** at a **Ration Press** (see Buildings &
  Economy's Food/Meal Conversion) — an unstaffed, instant-conversion building
  that turns fresh food ingredients into more Rations at a lossy rate
  (`floor(min(P,F,C,V) / 2)`, with any axis imbalance beyond the matched
  minimum discarded). This is a genuine, felt inefficiency versus consuming
  fresh food directly — Rations are valuable specifically for portability
  (required for certain exploration tasks — see Assignment above), not as a
  strictly better choice than fresh consumption.
- If total available nutrition (Rations plus any meals) can't cover the
  settler headcount at all, the shortfall causes **settler deaths** (the
  original mechanic, unchanged) — a confirmation dialog gates confirming a
  season with deaths planned from this shortfall. **Who dies is drawn
  uniformly at random** ("drawing lots") from everyone needing to be fed at
  the settlement that season, excluding any settler currently on an
  Exploration Task — their Rations were already committed at assignment
  time, separate from this pooled at-home check.

### Meals
- Produced at ordinary staffed single-conversion production sites (see Platform &
  Core Loop Redesign's Production Model) — no merge-space crafting.
- Defined by a recipe (single input→output conversion) and a nutrient-axis profile.
  **No secondary effects** — the old Morale-related meal effects (modifier, floor) no
  longer apply, since Morale has been cut from the design entirely.
- Meal items do not expire.

### Consumption — Pooled, Not Per-Settler
- Nutrition need and availability are tracked **at the settlement level, not per
  individual settler** — e.g. 4 settlers need a pooled 4/4/4/4 per season; 1 Bread +
  1 Apple + 2 Milk (1/1/5/0 + 0/0/1/1 + 2×[1/1/0/2] = 3/3/5/5) is evaluated against
  that pooled need as a whole, with no bookkeeping over which settler "ate" what.
  Keeps small-number play simple and avoids the nutrition system dominating
  gameplay. **The pooled headcount only counts settlers actually present at
  the settlement that season** — a settler assigned to an Exploration Task
  (see Exploration Tasks' Assignment) is excluded from it for the season(s)
  they're away, since their sustenance is covered separately by that task's
  strict Ration cost instead.
- **Food-for-consumption is assigned during planning** (not fully automatic), but
  defaults intelligently each season in this priority order:
  1. If the food types consumed **last season** are available and sufficient on
     their own, default to using those again.
  2. If those types are available but insufficient, use them fully and cover the
     remainder with Rations.
  3. If none of last season's types are available, default to Rations entirely.
  4. If Rations have run out entirely (the finite starting stock, plus
     anything manually produced at a Ration Press, is exhausted), this
     fallback simply provides nothing — the natural, harsher consequence of
     removing the old auto-regenerating safety net.
- The player can always override this default during planning; a stable diet simply
  continues itself with no action required — a sticky-default cousin to worker
  staffing.
- **Two-tier consequence model:**
  - **Tier 1 — bulk shortfall (existential):** total available nutrition can't cover
    the settler headcount at all → settler deaths, as described above.
  - **Tier 2 — axis imbalance (soft):** bulk need is covered, but one or more axes
    falls short of pooled need → **no in-run consequence** — tracked only for the
    end-of-run Food Security score below.
- **No penalty for excess** in any axis — surplus simply accumulates in the shared
  inventory stockpile, feeding the score below.

### End-of-Run Food Security Score
`FoodSecurity = normalize(NutritionStockpile) + normalize(NutritionIncome)`

`NutritionStockpile` is `sum of sqrt(stockpiled amount)` across the four axes
(flattening function tunable later via playtesting, once it can be felt in actual
play) — deliberately not a hard bottleneck/minimum-of-the-four: a large stockpile in
one axis should still feel meaningful and impactful, not nullified by a weak axis
elsewhere. Because `sqrt` flattens at high values, the *marginal* value of further
stacking an already-large axis shrinks, so diversifying naturally becomes the more
efficient move at the margin once one axis is deep into diminishing returns —
without ever making a large single-axis investment feel wasted or capped.
**"Stockpiled amount" specifically means food committed to a Food Storage
building (see Storage)** — food merely sitting in general inventory doesn't
count. This makes deliberate storage a real, felt tradeoff (locking food away
from active use) rather than a passive byproduct of surplus production.

`NutritionIncome` mirrors Development Bloc's `ResourceIncome` — a linear average
production rate over the run's last 5 seasons, across the same four axes, a
separate signal from total stockpile (which could reflect one-time windfalls rather
than durable production capacity). The two terms are normalized before combining,
per the "normalize before combining unrelated values" design principle.

The player doesn't need to know the exact formula; the diminishing-returns feel
should be legible through play. This is one of several separately visible/inspectable
viability sub-metrics — visible at-a-glance during the run, inspectable in depth at
any time — not folded into one opaque summed score, per the "numbers stay small"
principle's guidance against hiding information behind a single number.
