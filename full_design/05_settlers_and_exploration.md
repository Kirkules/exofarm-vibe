# Settlers & Exploration

## Settlers

- A small group of **human settlers** (3–4 at run start)
- Named individuals, but **no individual gameplay mechanics** — no personal traits or
  individual favorites affecting gameplay
- Settlers may have **children** over the run (5–10 year timescale per run), who are
  additional mouths to feed
- Settlers must be **fed** each season; starvation is a critical failure condition (see
  Food & Nutrition)

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

**Sentience-contact chain** (worked example, since it's the point where every SEED
faction's priorities can visibly pull against each other in a single decision — see
SEED Factions in Win/Lose Conditions):

| Step | Season gate | Base cost | Item | Success chance | Outcome |
|---|---|---|---|---|---|
| **1. Sentience Detection**, reached cold from the base pool | 8+ | 1 Ration | — | Low (~10%) | Success: `EcologicalData` + guaranteed escalation to step 2 |
| **1. Sentience Detection**, reached via an alien-civilization-implying trigger (Abandoned Settlement, Crashed Debris Field, Ancient Irrigation Technique, Recovered Survey Data, Arid Profile-shifting — see Task Catalog) | N/A, guaranteed placement | 1 Ration | — | Moderate (~30%) for the first four triggers, High (~60%) for Recovered Survey Data specifically | Same as above |
| **2. Observe from a distance** | N/A, guaranteed escalation | 1 Ration | — | Guaranteed | Elevated `EcologicalData` weight (a heavier increment than an ordinary biodiversity report, not a new score term) + unlocks the branching choice at step 3 |
| **3a. Peaceful Contact** | N/A | 2 Rations | Mandatory: Diplomatic Gear | Guaranteed attempt, Low-risk | Elevated `EcologicalData` weight, same as Observe; can unlock its own further escalation into an ongoing alliance/trade relationship — same zero-staffing passive-benefit reward tier as the fruit-animal-alliance example above. **Specific rewards TBD** — see `DESIGN_TODO.md`'s Alien civilization classes item |
| **3b. Aggressive/Exploitative Contact** | N/A | 1 Ration | Mandatory: Armed Expedition Kit (see Buildings & Economy's Fabrication) | Guaranteed attempt, **High-risk with the largest death chance in the catalog** | This is the concrete realization of the "aliens obliterating an aggressive explorer" example from the difficulty-principle discussion — a severe outcome from an explicit, knowingly-initiated high-risk choice, which the design principles explicitly allow even when it ends a run. **Specific success rewards TBD** — see `DESIGN_TODO.md`'s Alien civilization classes item |

Step 1 gives every alien-civilization-implying trigger a real, concrete
target rather than inventing a separate chain per trigger — this is
literally what "starting the sentience-contact chain" means whenever one of
those five is discovered.

**Elevated legend value.** Every task in this chain — the initial
detection, Observe from a distance, and either contact branch — carries an
elevated, design-authored legend-value (see Frontier Legends in Win/Lose
Conditions) relative to ordinary exploration tasks, **regardless of whether
the encounter was peaceful or aggressive**. First contact with intelligent
life is one of the rarest, most story-worthy events the game can produce,
and Frontier Legends rewards that inherently — independent of which
faction's priorities the outcome otherwise served. This stacks with (is
separate from) the general injury/death Legends bonus described in Risk
Spectrum, below, if Aggressive/Exploitative Contact goes badly.

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

Both consequence types reuse existing mechanics rather than inventing new
ones:
- **Injury** — the settler gets the same status-effect debuff Atmospheric
  Hazard exposure already uses (fixed duration, halved effectiveness,
  locked out of exploration assignment while active).
- **Death** — the settler is permanently removed from the roster, the same
  mechanic starvation-death already uses.

Neither needs the not-yet-built per-settler tracking system — that system
is about tracking achievements/history, not whether a settler currently
exists, which the roster already handles today.

**Guaranteed-success tasks with a risk tag** (Site Reveals, Hybridization
opportunities — anything that isn't an Achievement-flavor Legend outcome)
handle risk differently from Achievement outcomes: the find itself is
never in doubt, but the risk tier still applies as an **independent roll**
alongside it — the settler *will* discover the vein, but the dangerous
environment they found it in (an active volcanic zone, a deep cave) can
still injure or kill them regardless of the task's own success. When that
happens, the settler earns a **Frontier Legends bonus** — large for injury,
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
Assignment) — settler-only and one-shot, same resolution as Exploration
Tasks (the settler is gone for the season and returns with a result), but
**always available every season** rather than pool-limited, and **safe**
(no risk spectrum, no Rations — the work stays on or near the farm, unlike
a genuine off-site expedition). Four members:

- **Basic Deposit Survey** and **Deep Survey** (see Buildings & Economy's
  Deposit Discovery) — Basic Survey covers a player-chosen rectangle of
  tiles and flags which of them are worth a Deep Survey; Deep Survey then
  automatically targets every tile flagged that way so far, no rectangle
  choice needed. Both repeatable.
- **Clear-Cutting** (see Buildings & Economy's Fuel) — harvests Wood from a
  discovered Forest tile; bounded, depletes with use.
- **Trapping** (see Buildings & Economy's Farm/Production) — harvests Pelt
  from any tile, yield boosted by Forest presence and by the planet's
  biological richness; unlike Clear-Cutting, renewable and repeatable
  indefinitely on the same tile.

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
  season with deaths planned from this shortfall.

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
