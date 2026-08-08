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
- Available during the **planning phase** on every **third season**, starting with
  season 3 (seasons 3, 6, 9, 12, 15 in a standard 15-season run) — working value,
  subject to change after playtesting
- A **small pool** of tasks is presented each opportunity: up to **3 at a time**
- Number and quality of available tasks varies by planet type and meta-progression unlocks

> **Open question:** no actual task content exists yet (specific task names, flavor
> text, full outcome tables) beyond the framework below — a large content-authoring
> pass, best done once the per-planet strategy-pressure distribution (see Exoplanet
> Types) is finalized.

### Assignment
- During planning, the player assigns a **settler** to an exploration task
- Assigning a settler **removes them from all farm duties** that season
- Multiple tasks can run simultaneously if the colony has enough settlers and
  **Rations** to send (see Food & Nutrition) — settlers must take food with them to
  survive while not on the farm; consumed from inventory per task
- Placement of assignments is **fully reversible** during planning
- **Some tasks are unmanned** (e.g. a weather balloon or camera drone), requiring no
  settler assignment at all — mostly data-collecting missions, making up some
  fraction of available tasks. This means a player could plausibly complete an
  entire run without ever sending a settler out; the Frontier Legends SEED faction
  (see Win/Lose Conditions) specifically rewards choosing *not* to rely purely on
  the safer unmanned option.

### Outcomes
Two categories of positive result:
- **Resource windfall** — settler returns with rare resources or items; no persistent
  grid change
- **Site reveal** — a feature on the farm grid is transformed into a new accessible
  site; e.g. a mountain region becomes an exposed ore deposit, a cave system, or a
  volcanic vent; the revealed site persists for the rest of the run

Many tasks yield only a windfall; site reveals are less common.

### Outcomes and the Strategy Dimensions
Every exploration outcome falls into one of three flavors relative to the four
strategy dimensions (A/B/C/D — see Exoplanet Types):
- **Profile-shifting** — unlocks or reveals something that opens up a dimension the
  current planet doesn't naturally favor (e.g. a rare mineral vein on an
  otherwise metal-poor Verdant planet, shifting toward A/D). This is exploration's
  *primary* purpose — the main route by which a run's strategic profile can move
  away from its planet's default. Skews toward the high-risk tier, but isn't
  exclusive to it — available at low/mid-risk sometimes too.
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
exploration option** that wasn't available before, guaranteeing it a slot in the
*next* exploration opportunity's pool (though it can still be discarded like any
other candidate via normal reroll/rescan). This lets a single discovery grow into a
multi-step arc rather than resolving in one roll. Example: a neutral find of native
fruit stockpiles on a Verdant planet reveals the option to seek out the habitat of
the animal that gathers and preserves that fruit; succeeding at *that* task can lead
to an alliance with those animals — a passive, ongoing food source requiring **no
staffing at all**, a qualitatively different reward tier from ordinary production,
similar in spirit to how baseline Energy/Matter production is already zero-effort.

**Sentience-contact chain** (worked example, since it's the point where every SEED
faction's priorities can visibly pull against each other in a single decision — see
SEED Factions in Win/Lose Conditions):
1. **Sentience detection** (an exploration task; see Stewardship Caucus's
   `EcologicalData`) turns up signs of organized intelligence. This is rare, per
   Life on Other Worlds' stance that sentient life is an exceedingly rare wildcard,
   not a standing feature.
2. **Observe from a distance** — the guaranteed escalation. Low-risk, gathers
   further `EcologicalData` confidence, and reveals enough about the civilization
   to present the player with a genuine branching choice next. Contributes a
   **significantly elevated weight** to the `EcologicalData` counter relative to an
   ordinary biodiversity report (a heavier increment, not a new score term),
   reflecting how much more this faction values careful, patient investigation of
   a sentient civilization specifically.
3. **A genuine branching choice**, gated as an explicit, distinct commitment per the
   reversibility principle (not an ordinary reversible planning tweak):
   - **Peaceful contact** — low-risk, diplomacy-flavored. Also contributes a
     significantly elevated `EcologicalData` weight, same as Observe. Can unlock
     its own further escalation into an ongoing alliance/trade relationship — the
     same zero-staffing passive-benefit reward tier as the fruit-animal-alliance
     example above.
   - **Aggressive/exploitative contact** (e.g. attempting to claim resources from
     their territory) — high-risk, can result in severe retaliation up to total
     loss. This is the concrete realization of the "aliens obliterating an
     aggressive explorer" example from the difficulty-principle discussion — a
     severe outcome from an explicit, knowingly-initiated high-risk choice, which
     the design principles explicitly allow even when it ends a run.

**Elevated legend value.** Every task in this chain — the initial detection,
Observe from a distance, and either contact branch — carries an elevated,
design-authored legend-value (see Frontier Legends in Win/Lose Conditions)
relative to ordinary exploration tasks, **regardless of whether the encounter was
peaceful or aggressive**. First contact with intelligent life is one of the
rarest, most story-worthy events the game can produce, and Frontier Legends
rewards that inherently — independent of which faction's priorities the outcome
otherwise served.

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
- Tasks range from **low-risk** to **high-risk**
- Low- and mid-risk tasks have **no negative outcomes** — results range from nothing
  to a good find
- High-risk tasks can result in **settler injury or death** but are the **exclusive
  source of the rarest and most desirable outcomes**
- Planet type affects the proportion of high-risk tasks available (e.g. a volatile
  volcanic planet generates more high-risk opportunities)

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
  gameplay.
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
