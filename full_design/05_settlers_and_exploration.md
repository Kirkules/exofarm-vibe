# Settlers & Exploration

## Settlers

**At a glance:**
- **Settler State** — `current_assignment`, `status_effect` list, `legend_value`
  list, `experience` (per-group stack), `aptitude` (per-bucket level),
  `gourmet_recipes`.
- **Injuries** — Semi-permanent (heals automatically) vs. Permanent (four
  types, each a different assignment restriction); severity gated by risk
  tier.
- **Infections** — parasite/disease `status_effect` entries; contraction,
  recovery via Medical Bay, quarter-season death-roll tick, countermeasures.
- **Storied** — permanent buff once `legend_value` crosses a threshold:
  production speed, exploration outcome max, success chance, bad-outcome
  reduction.
- **Experience** — per-task-group stacking buff, earned through play,
  non-exploration only.
- **Aptitude** — per-bucket innate level (−3 to +3), fixed at Crew
  Selection; Exploration bucket has its own effect shape.
- **Drones** — count as fixed Aptitude/Experience equivalents for
  non-speed gates only.

- A small group of **human settlers** (5 at run start; see `data/misc_balancing_values.csv`'s "Crew Selection" row)
- Named individuals, with real per-settler state (see [Settler State](05_settlers_and_exploration.md#settler-state), below) —
  no longer "no individual gameplay mechanics" now that Frontier Legends,
  injuries, and Atmospheric/Temperature hazards all need it. Settlers may form
  an exclusive-pair romantic relationship, arbitrarily/randomly, surfaced to
  the player via a Transmission — **pure narrative flavor with no mechanical
  effect** (see Story & World's Narrative-Only Flavor).
- Settlers must be **fed** each season; starvation is a critical failure condition (see
  [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition))

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
  - **Idle** — a settler with no active assignment, whether unassigned by
    the player or freed when their site was destroyed. They wait at
    **Crew Quarters** (or the Settlement Base's quarters), which is where
    idle settlers are shown and what shelters them; a settler recovering
    from an injury or infection waits at the **Medical Bay** instead, and
    returns to quarters once recovered. Idle is a legitimate plan: they
    eat normally and accrue nothing, with no penalty beyond the lost work.
- `status_effect` — a list of concurrently-possible entries (not a single
  field): Injury (see below), **Infection** (one entry per parasite or
  disease type carried — see [Infections](05_settlers_and_exploration.md#infections) below), Atmospheric Hazard,
  Temperature Extremity (slowed), Storied, and Sleep quality (Poor / Good /
  Great — a settlement-wide Effort modifier on on-site work, set by the
  best crew quarters standing; see Buildings & Economy's [Habitation](04_buildings_and_economy.md#habitation)).
- `legend_value` — a list of completed sites/achievements, not just a
  scalar; the Frontier Legends formula (see [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)) sums it,
  and the list itself feeds personnel-file/end-of-run report display.
- `experience` — a per-task-group stack count (0–3), earned through play
  (see [Experience](05_settlers_and_exploration.md#experience), below).
- `aptitude` — a per-bucket level (−3 to +3), innate and fixed at Crew
  Selection, never changing over a run (see [Aptitude](05_settlers_and_exploration.md#aptitude), below).
- `gourmet_recipes` — a list of Gourmet dishes this specific settler has
  personally invented (see Buildings & Economy's Kitchen) — only they can
  cook these, and only while assigned to Kitchen; empty for most settlers,
  since it requires maxed Kitchen `experience` plus a Seasoning roll.

### Injuries

Designed independently of *where* a settler gets hurt (exploration,
Atmospheric Hazard, Temperature Extremity, a failed Buildings & Economy's
[Husbandry](04_buildings_and_economy.md#animal-husbandry) Capture attempt) — this taxonomy is shared by all of them,
referenced rather than repeated wherever injury/death is mentioned
elsewhere in this design. Two categories:

- **Semi-permanent (SP)** — four types: broken bones, sprains, moderate
  burns, concussions. Tracked individually, but **differentiated only in
  flavor** for now: the four behave identically, and the type is carried
  so future design can differentiate them without a data migration. No
  standalone debuff number of its own — its entire
  mechanical expression *is* the eligibility and delay rules below;
  inventing an additional debuff on top would be functionally irrelevant,
  since it would disappear the moment it could matter. Heals automatically:
  each SP injury takes a **quarter-season** to heal. Without a Medical Bay,
  multiple SP injuries heal **serially** (one quarter-season each, in
  sequence); with a Medical Bay, they heal **simultaneously** — same
  quarter-season per injury, but in parallel, so Medical Bay's entire value
  is collapsing N×(quarter-season) down to one quarter-season when a
  settler has more than one SP injury at once. (With exactly one SP injury,
  Medical Bay makes no difference.) Since a settler never holds two of the
  same type (see Acquisition, below), four is the ceiling — at worst one
  full season of serial healing.
  - **Exploration eligibility**: ineligible for Low-risk or High-risk
    exploration tasks; eligible for No-risk tasks, with a success-chance
    penalty (see `data/settler_modifiers.csv`'s "Injury - SP, No-risk
    exploration" row) — applying only to No-risk tasks that already have a
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
  - **Loss of an arm** — bars nothing, but cuts work speed (see
    `data/settler_modifiers.csv`'s "Injury - Loss of Arm" row) on every
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
  - **Severe burns** — bars nothing, cuts work speed (see
    `data/settler_modifiers.csv`'s "Injury - Severe Burns" row) on Manual
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
  High-risk tasks — exactly one outcome per roll; see
  `data/injury_outcome_weights.csv` for the per-tier weights and
  `data/exploration_task_injury_weights.csv` for per-task values. This does **not** apply to the separate
  guaranteed-success-with-independent-risk shape (Site Reveals,
  Hybridization opportunities, most Planet exclusives — see Risk
  Spectrum) — those tasks have no failure state to gate on, and keep
  their existing independent roll unchanged.

**Acquisition.** Once a roll lands on "SP injury" or "permanent injury",
the specific type is drawn **uniformly at random from the types that
settler doesn't already carry** — a settler never holds two of the same
type, in either category. A duplicate would be mechanically inert, which
would quietly turn the harshest outcome into the mildest one.

- **A settler already carrying all four types of that category simply
  keeps them** — the injury fizzles, changing nothing. This is the one
  case where a rolled injury has no effect, and it's preferred over
  re-rolling into the other category (which would let SP saturation
  manufacture permanent injuries) or escalating to death.
- Concurrent permanent injuries **stack multiplicatively** on work speed
  (see `data/settler_modifiers.csv`), and their assignment bars simply
  intersect.
- Hazards inflict injuries on the same taxonomy, with their own weights —
  see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events) and
  `data/hazard_casualty_weights.csv`.

### Infections

**Parasites and diseases** are the concrete form of the two Bio-hazard
sub-factors — parasites are *Toxic/Parasitic Organism Threat*, diseases are
*Pathogen Threat* (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)
for the settlement-facing side and the quarter-season epidemiology tick).
Which parasite and disease **types** exist on a run is fixed at planet
generation. A settler carries one `status_effect` **Infection** entry per
type. Mechanically an infection behaves like a minor injury with an
outsized tail risk.

**Contraction.** A settler can be infected by:
- an **exploration task** whose outcome roll includes it (resolved only at
  task completion — no mid-task affliction; an Emergency Medical Kit taken
  on the task prevents a would-be minor injury or infection);
- **working an affected site** — a carrier wild population (grazers at a
  crop site, predators at a husbandry site) infecting the present worker,
  or tending a parasite-infected husbandry population (see Buildings &
  Economy's forthcoming Animal Husbandry, and `DESIGN_TODO.md`);
- **eating infected food** — if infected animal-derived food is used in the
  seasonal nutrition pool, **every non-exploring settler** is infected (see
  [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition) below);
- for **diseases only**, catching it from another infected settler (see
  spread, below).

All of these **begin at Post-Sim** — a settler working an affected site
produces normally that season, then carries the infection into the next.
**Drones can't be infected.** Any number of infections stack, alongside any
number of injuries.

**Recovery** happens at a Medical Bay, gated by its **Recovery capacity**
(1 base / 2 upgraded — see Buildings & Economy's [Medical Bay](04_buildings_and_economy.md#medical-bay)). A settler
needing recovery **cannot work** (a held assigned site produces nothing)
and cannot be sent on an exploration task. Beyond capacity, settlers queue —
still infected, not recovering. A worker who spends a whole season in the
Medical Bay isn't infected by exposure at their nominal assigned site; only
if they recover mid-season and return to it.

**The tail risk.** At each quarter-season **epidemiology tick**, every
infected settler — recovering, queued, or working — rolls for **death**
(probability per type), unless a countermeasure exists for that infection
at that tick:
- **With the countermeasure** (a researched vaccine for a disease, or
  anti-parasitic for a parasite — see Medical Bay): no death roll, and
  recovery always succeeds.
- **Without it:** a recovery cycle may fail (still infected) and the death
  roll is live. A settler who recovers from an un-countermeasured infection
  **gains `legend_value`** for beating the odds.

**Disease vs. parasite:**
- A **disease** is communicable settler-to-settler: at each epidemiology
  tick, if any infected settler is in the settlement and no vaccine for
  that disease exists, every uninfected settler in the settlement rolls a
  chance to catch it. A **vaccine confers permanent immunity**.
- A **parasite** never spreads settler-to-settler, and an **anti-parasitic
  confers no immunity** — a cured settler can contract it again — it only
  guarantees and speeds recovery.

### Storied

A positive `status_effect`: once a settler's `legend_value` sum crosses a
threshold (see `data/misc_balancing_values.csv`'s "Storied" row), they
permanently gain four flat modifiers (exact values in
`data/settler_modifiers.csv`'s "Storied" rows):
- A production-speed boost on Production-building assignments, and on
  Trapping/Clear-Cutting now that both are production-speed-based (see
  [Standing Assignments](05_settlers_and_exploration.md#standing-assignments), below).
- A flat increase to the upper bound of any exploration-task outcome with a
  numeric quantity range, regardless of which outcome category it's filed
  under.
- A relative success-chance boost on any probabilistic exploration outcome.
- A relative reduction to bad-outcome probability on any risky task — a
  distinct, simpler formula from the success-chance boost above, applied
  to the negative-outcome rolls described in Injuries.

Diegetically: an experienced, renowned settler is just genuinely better at
their job — low mechanical overhead (one threshold check, a handful of flat
modifiers), self-limiting rather than unbalancing, since Legend outcomes are
already rare by design. Tooltip stays plain-language, same as [Experience](05_settlers_and_exploration.md#experience)
and [Aptitude](05_settlers_and_exploration.md#aptitude) below — "reduced injury chance," "improved chance of
success," "up to 1 more item from Exploration," never the underlying
formula.

### Experience

A stacking permanent buff, per settler, per **task group** — earned
through play, unlike [Aptitude](05_settlers_and_exploration.md#aptitude) below. Applies only to non-exploration
assignable tasks (Production buildings and Standing Assignments);
Exploration Tasks never build or benefit from Experience.

**Groups** (fixed, not player-adjustable) — a settler tracks one stack
count per group, and that count's bonus applies uniformly across every
task within it, not just wherever it was earned:
- **Farming** — the four plant-crop buildings (Grain Field, Fruit Orchard,
  Fiber Field, Timber Grove) plus the Hydroponic Farm. *(The current
  Dairy/Poultry/Sheep buildings are slated to move to the Husbandry group
  below once the native-fauna pivot actually removes them — see
  `DESIGN_TODO.md`.)*
- **Husbandry** — native-animal work: a [Husbandry Site](04_buildings_and_economy.md#animal-husbandry)'s
  Capture attempts and its ongoing feed/tend cycle. Kept separate from
  Farming: learning to grow crops shouldn't teach a settler to handle
  animals or spot a parasite in a herd.
- **Mining** — Mine, Quarry, Rare Metal Extractor.
- **Kitchen**, **Trapping**, and **Clear-Cutting** — each its own group.
- **Surveys** — Basic Deposit Survey and Deep Survey, shared with each
  other only.
- **Each Fabrication building separately** — Robotics Assembly, Stone
  Processing, Smelter (see Buildings & Economy's [Fabrication](04_buildings_and_economy.md#fabrication)), Textile
  Workshop, Carpenter's Shop, Tinkerer's Workshop.
- **Each Research/Utilities building separately** — Research Lab, Medical
  Bay, Scanner Station.

**Gaining stacks**: a settler assigned to a task in a group gains one
stack for that group per season, provided they actually perform *any*
work in that group during the season — a season shortened by an
injury-recovery delay still counts, as long as some work happens
afterward; a season where somehow no work happens at all (e.g. a
mid-season death) does not. Stacks are **permanent** — no decay from time
away or reassignment.

**Effect**: a production-speed boost per stack, capped at 3 stacks (see
`data/settler_modifiers.csv`'s "Experience per-stack" row). Tooltip shows
a plain-language readout ("+30% Farming speed"), never the underlying
formula.

**Kitchen's max stack does something no other group's does**: it's the
prerequisite for a settler's Gourmet-recipe "moment of brilliance" (see
Buildings & Economy's Kitchen and `gourmet_recipes` above) — a qualitative
payoff layered on top of the ordinary speed bonus, not a replacement for
it.

### Aptitude

A per-settler, per-bucket profile — analogous to Experience in shape (same
production-speed effect per level, see `data/settler_modifiers.csv`'s
"Aptitude per-level" row, same three-level range), but
**innate rather than earned**: fixed once at Crew Selection (see Core Loop
& Grid's [Crew Selection](03_core_loop_and_grid.md#crew-selection) for the archetype/reroll system that generates
these), never changing over the course of a run. Levels run **−3 to +3**,
zero meaning no aptitude either way.

**Buckets** — coarser than Experience's groups, and never crossing an
Experience group's boundary (each Experience group belongs to exactly one
bucket):
- Farming, Clear-Cutting *(plant & land work)*
- Trapping, Husbandry *(animal work — split from the plant bucket so a
  clear-cutter can't innately diagnose a herd)*
- Mining, Stone Processing, Smelter
- Textile Workshop, Carpenter's Shop, Kitchen
- Robotics Assembly, Tinkerer's Workshop, Medical Bay, Research Lab
- Scanner Station, Surveys
- **Exploration** — Aptitude-only; no corresponding Experience group
  exists for it.

**Effect, the first five buckets**: a production-speed effect per level,
same additive stacking shape as Experience (see
`data/settler_modifiers.csv`'s "Aptitude per-level" row), applied
uniformly across every task in the bucket — stacks additively with
whatever Experience a settler has separately earned at the specific
building they're working (Experience and Aptitude are independent numbers
that both contribute to the same speed total). Tooltip: plain-language
("+30% Mining speed"), no formula.

**Effect, the Exploration bucket** — a different shape from the other
five: each level unlocks an *additional* effect rather than repeating the
same one, and the negative direction mirrors each formula rather than
just inverting a sign. See `data/aptitude_exploration_effect_table.csv`
for the full per-level breakdown.

Applies to every exploration outcome, including the previously-"guaranteed"
ones (Site Reveals, Hybridization opportunities, most Planet exclusives —
see [Risk Spectrum](05_settlers_and_exploration.md#risk-spectrum)) — those are now framed as having a base 100% success
rate that this can scale down, same as any other probabilistic outcome.
Their separate independent risk roll for injury/death (see [Risk Spectrum](05_settlers_and_exploration.md#risk-spectrum))
stays completely unaffected by this success/fail outcome either way — the
two systems don't interact.

Stacks with **Storied** additively, not sequentially: the two sources'
relative percentages sum before being applied once (`p_new = p +
0.50(1-p)` if both are active, not `p` run through the formula twice) —
this avoids the compounding oddity of applying the same relative formula
in sequence. The flat +1/−1 outcome-maximum effect just adds normally with
Storied's own +1. Tooltip stays plain-language here too — "reduced injury
chance," "improved chance of success," "up to 1 more item from
Exploration" (or the negative-direction equivalents), never the formulas.

### Drones, Experience, and Aptitude

A general rule for how any drone relates to this system, resolving it
everywhere Experience or Aptitude gate something **other than** production
speed — a probability (Buildings & Economy's [Husbandry](04_buildings_and_economy.md#animal-husbandry) Capture roll), or a
threshold check (the "max Kitchen/Medical Experience or Aptitude" food/
animal-infection-visibility gates — see [Infected Food](05_settlers_and_exploration.md#infected-food)):

- A **Basic** drone (of any kind) counts as a settler with **0 Aptitude**
  in the relevant bucket and **0 Experience stacks** in the relevant
  group — and **never accrues Experience**, no matter how many seasons it
  works.
- An **Advanced** drone counts as **+1 Aptitude and +1 Experience** in the
  relevant bucket/group — fixed at that value forever, never climbing
  further with more seasons worked.
- This is **only** for these non-time-scaling effects. It changes nothing
  about production **speed**: a drone's contribution there is still its
  own flat Effort value (see Buildings & Economy's [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)),
  entirely separate from — and not summed with — the Experience/Aptitude
  speed formulas above.

---

## Exploration Tasks

**At a glance:**
- **Pool** — up to 3–5 tasks, always available; refreshes each season or
  on paid reroll; lock/in-progress exempt from refresh.
- **Assignment** — settler-only, one-shot, 1+ Ration plus optional/
  mandatory item per task.
- **Outcomes** — Resource windfall, Site reveal, Legend, Farm-wide
  Upgrade; full catalog in `data/exploration_task_catalog.csv` and its
  detail tables.
- **Strategy Dimensions** — every outcome is Profile-shifting, Reinforcing,
  or Neutral; each planet has a Reinforcing and a Profile-shifting
  exclusive (`data/strategy_dimension_exclusives.csv`).
- **Escalation Chains** — an outcome can guarantee a follow-up task next
  refresh; sentience-contact chain and Trade Agreements are the worked
  examples.
- **Risk Spectrum** — No/Low/High-risk, gates injury/death severity;
  guaranteed-success tasks still carry an independent risk roll.

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
- **Manual reroll costs Rations** — a flat amount (see
  `data/misc_balancing_values.csv`'s "Exploration Tasks" rows) — framed as
  tasking local sensors/drones with a fresh sweep of the surrounding
  region, the same principle already used at the hub level for
  filament-scanning. Deliberately **not** an Energy cost (see Buildings &
  Economy's Resources' Energy Income/Consumption Rates, which has no
  spendable balance to draw from at all now) — Rations is the pointed
  choice instead, since it's already the same resource that funds actually
  *launching* a risk-bearing Exploration Task (below). This creates a real,
  felt tension: rerolling for a better task option spends the same
  stockpile that would otherwise let the player commit to a task sooner,
  rather than being a free, consequence-free do-over. Scanner Station
  upgrades may reduce this cost.
- **Pool size**: see `data/misc_balancing_values.csv`'s "Exploration Tasks"
  rows. Scanner Station upgrades and a Research Lab project ("Expanded
  Reconnaissance Doctrine") each permanently add +1 toward the max.
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
  **Rations** to send (see [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)). Unlike at-home settlers (who
  can be fed by any food type — Meals, raw crops, or Rations), an exploring
  settler's cost is a **strict Rations requirement** — no substituting fresh
  food, since it has to travel with them. Mechanically, the moment a
  settler is assigned to a task, they're removed from the settlement's
  pooled nutrition headcount for that season (see [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)'s
  Consumption), and their sustenance instead becomes that task's Ration
  cost. A multi-season task's **full** Ration cost, and any item it
  requires, is consumed at Planning Lock-in for the task's **first** season
  — the settler carries the whole trip's supplies out with them, rather
  than drawing a Ration per season from a settlement that might run dry
  mid-task and strand them.
- **Cost, most tasks**: 1 Ration base (see Seasons to complete, above),
  plus an optional or mandatory consumable item depending on the specific
  task — an optional item typically guarantees the top of an outcome's
  value range or unlocks a bonus reward component; a mandatory item is a
  hard prerequisite the task can't be attempted without at all (Deep Survey's
  Portable High-Powered Scanning Equipment requirement is the existing
  precedent for this). Full task-by-task costs are in the catalog below.
- **Every exploration task requires a settler** — drones are barred from
  Exploration entirely, regardless of tier (see Buildings & Economy's
  [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly)), so there's no unmanned route through this pool. A
  player can still choose never to send anyone out at all, simply by never
  accepting a task; the Frontier Legends SEED faction (see [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions))
  specifically rewards choosing to risk real settlers rather
  than avoiding exploration altogether.

### Outcomes
Four categories of positive result:
- **Resource windfall** — settler returns with rare resources or items; no persistent
  grid change
- **Site reveal** — a feature on the farm grid is transformed into a new accessible
  site; e.g. a mountain region becomes an exposed ore deposit, a cave system, or a
  volcanic vent; the revealed site persists for the rest of the run.
  **Hybridization opportunities** (see Buildings & Economy's [Farm/Production](04_buildings_and_economy.md#farmproduction))
  are a Site Reveal variant — what's unlocked is a Research Lab project
  rather than a grid feature.
- **Legend outcome** — rare, little or no material reward, but a large
  one-time Frontier Legends legend-value injection (see [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)),
  usually tied to a genuinely story-worthy moment. Always
  **Neutral** within the Strategy Dimensions framing below, since its value
  lives entirely in the separate Frontier Legends axis, not any of the four
  strategy dimensions. Two
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
  Medical Bay's vaccines/anti-parasitics — a second, exploration-specific
  pathway to that same reward shape, not a replacement for the existing
  tech/resource-gated one.

Many tasks yield only a windfall; the other three are less common, with
Legend and Farm-wide Upgrade outcomes rarer still.

### Task Catalog

Full per-task fields — Rarity, Risk, Season gate, Base cost, required/
optional item, and outcome — are in `data/exploration_task_catalog.csv`
and its detail tables (`data/exploration_task_input_items.csv`,
`data/exploration_task_item_rewards.csv`, `data/exploration_task_site_reveals.csv`,
`data/exploration_task_legend_outcomes.csv`, `data/exploration_task_confidence_bursts.csv`,
`data/exploration_task_farmwide_upgrades.csv`). Every task's "seasons to
complete" equals its Ration cost (see [Assignment](05_settlers_and_exploration.md#assignment), above).
**Leather Backpack** (a Leather-derived Textile Workshop item, see
Buildings & Economy's [Fabrication](04_buildings_and_economy.md#fabrication)) and **Portable High-Powered Scanning
Equipment** (Tinkerer's Workshop) are both consumed on use, same
precedent PPE already established for exploration-task consumables.

Site Reveal tasks are 100% success if attempted — one settler finding one
specific thing, not a probabilistic area survey the way Basic/Deep Survey
already are — so they get no optional item; there's no quantity to boost.

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
an independent risk roll (see [Risk Spectrum](05_settlers_and_exploration.md#risk-spectrum), above) — the find itself
never fails, but the dangerous environment can still injure or kill the
settler, which also earns them a Frontier Legends bonus when it happens.

**Meteorite Fragment** and **Unknown Radio Signal** are both
planet-independent, not tied to any single planet type's identity.
Unknown Radio Signal is another alternate entry point into the
sentience-contact chain (see [Escalation Chains](05_settlers_and_exploration.md#escalation-chains), below); its branching
resolution — the signal's resolved cause, and, within the genuine-distress-
signal branch, whether an Emergency Medical Kit was brought — is in
`data/exploration_task_unknown_radio_signal.csv`. Legend value tracks the
clout of a discovery, not how poignant the moment was, so "found them too
late" earns the same legend value as a clean rescue, not less and not a
sympathy bonus either. The sentience-contact chain's own numbers are in
[Escalation Chains](05_settlers_and_exploration.md#escalation-chains), below.

### Outcomes and the Strategy Dimensions
Every exploration outcome falls into one of three flavors relative to the four
strategy dimensions (Protection/Enclosure, Biosphere Integration,
Synthesis/Self-Sufficiency, Energy Management — see [Exoplanet Types](06_planets_and_scoring.md#exoplanet-types)):
- **Profile-shifting** — unlocks or reveals something that opens up a dimension the
  current planet doesn't naturally favor (e.g. a rare mineral vein on an
  otherwise metal-poor Verdant planet, shifting toward Protection/Enclosure
  and Energy Management). This is exploration's
  *primary* purpose — the main route by which a run's strategic profile can move
  away from its planet's default. **Not inherently tied to risk tier** — a
  Profile-shifting outcome can be No-risk just as easily as High-risk; risk
  and reward rarity are independent axes except where a specific task is
  deliberately designed otherwise (see [Risk Spectrum](05_settlers_and_exploration.md#risk-spectrum), below).
- **Reinforcing** — deepens a dimension the planet already favors (e.g. an
  exceptionally potent shielding-material vein on Volcanic, deepening
  Protection/Enclosure).
- **Neutral** — generic value with no strategic lean at all (a stockpile of
  ordinary materials, a plain resource windfall).

**Every planet type has at least one exclusive exploration possibility** unavailable
on any other planet, opening a path to special technology or another unique
payoff — see `data/strategy_dimension_exclusives.csv` for each planet's
Reinforcing and Profile-shifting exclusive.

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
similar in spirit to how baseline Energy production is already zero-effort.

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

See `data/alien_civilization_classes.csv` for the current curated roster.

**Biological Compatibility is deliberately not a mechanical property** —
it's pure per-class flavor text explaining why contact carries the injury
risk it already carries via the Risk Spectrum, not a new consequence
layer. Keeps the system from growing a sixth axis for a distinction that
doesn't need to change any numbers.

**Sentience-contact chain** (worked example, since it's the point where every SEED
faction's priorities can visibly pull against each other in a single decision — see
[SEED Factions](06_planets_and_scoring.md#seed-factions) in Win / Lose Conditions):

Full per-step fields — Season gate, Base cost, Item, Success chance, and
Outcome, for Sentience Detection's three trigger variants and Observe from
a distance — are in `data/sentience_contact_chain.csv`.

**3. First Contact** surfaces in the pool as a **single guaranteed
escalation slot**, not three separate entries — its own UI lets the player
switch between three approaches before committing a settler, each pulling
its own cost and item. Full fields for all three approaches (3a Peaceful
Contact, 3b Bluff/Coercive Exploitation, 3c Military Exploitation) are
also in `data/sentience_contact_chain.csv`. 3b's success scales inversely
with Technology Level alone — an advanced civilization has more
information about what's actually possible, not more information about
the settlers' specific claims, so it's harder to fool regardless of
Openness or Unity. 3c's success scales against both Technology Level and
Unity together, more steeply than 3b, and carries the largest death
chance in the catalog — this is the concrete realization of the "aliens
obliterating an aggressive explorer" example from the difficulty-principle
discussion, a severe outcome from an explicit, knowingly-initiated
high-risk choice the design principles explicitly allow even when it ends
a run.

Step 1 gives every alien-civilization-implying trigger a real, concrete
target rather than inventing a separate chain per trigger — this is
literally what "starting the sentience-contact chain" means whenever one of
those five is discovered.

**Direct entry to First Contact.** A successful rescue during Unknown Radio
Signal (see [Task Catalog](05_settlers_and_exploration.md#task-catalog)) skips straight to First Contact, bypassing
Sentience Detection and Observe from a distance entirely — a direct rescue
already constitutes first contact. All three approaches are still
available at that point; a rescue doesn't force the player into Peaceful
Contact specifically.

**Deepening an alliance.** Peaceful Contact's alliance isn't a one-time
payout — it deepens through follow-up exploration tasks, each requiring
Diplomatic Gear, using the same guaranteed-escalation-slot shape as
everything else in this section, and **only reachable once the base
alliance already exists** (First Contact via Peaceful Contact must have
already succeeded — deepening is never a standalone entry point). Exact
tier count and per-tier rewards otherwise TBD, same as Peaceful Contact's
base rewards — **establishing a Trade Agreement (below) is one form a
deepening reward can take, not the only one.**

**Trade Agreements** are the concrete resolution of "how does the player
actually trade with an ally" (previously an open question — see
`DESIGN_TODO.md`). Structurally:
- A deepening task that resolves into a trade opportunity surfaces its
  offer in the task's own **confirmation dialog** — the same dialog every
  Exploration Task already gets at the start of the next planning phase
  (see Core Loop & Grid's Season Structure), not a new UI surface. The
  dialog presents **three candidate agreements**, each a fixed pairing of
  one expense resource (paid by the settlement) and one income resource
  (received from the ally), with per-season quantities — illustrative/TBD
  like other first-pass numbers. The player picks exactly **one; no
  reroll**, consistent with "deliberately not something a player can
  optimize" restraint already used elsewhere in this design (e.g. Energy
  and Water's shared random-shortfall model).
- **One-season delay before the first exchange.** Accepting an agreement
  doesn't trade anything immediately — the first exchange resolves at the
  end of the *next* season to follow (i.e., the season the player is about
  to plan when the dialog appears), giving a full planning phase to
  prepare the expense resource rather than an immediate, unpreparable
  deduction.
- **Ongoing resolution**: every season thereafter, resolved during
  Post-Sim (placed right after pooled nutrition consumption and before
  construction completions in the established sub-step order — see Core
  Loop & Grid's Season Structure — so survival needs get first claim on
  any resource an agreement also happens to use, Rations most notably).
  If the settlement has the required expense quantity, it's deducted and
  the income quantity is added. **If it doesn't, the agreement ends
  permanently**, with a dialog informing the player — no grace period, no
  partial fulfillment.
- **Up to a cap of Trade Agreements can be active at once** (see
  `data/misc_balancing_values.csv`'s "Escalation Chains" row). A terminated
  agreement frees its slot — a future deepening task can offer a new
  agreement to fill it — rather than being a lifetime cap ever.
- **Allowed income-resource types** (what an ally could plausibly produce
  without sharing the settlement's own tech tree): raw/harvested materials
  (Wood, Stone, ore types, Pelt, raw uncooked food ingredients), plus
  **Lumber, Concrete, and refined-metal outputs** (Iron, Copper, and
  similar — a light processing step, included on request). **Excluded**:
  anything requiring deeper settler fabrication/culinary process to
  exist — cooked Meals, Luxury Goods (Fine Furniture, Ornamental/
  Decorative Items), textile-processed goods (Fabric, Leather), deep
  manufacturing (High-Tech Components and similar), and Rations.
  Expense-side resources have no equivalent restriction (any inventory
  resource is a valid expense).
- **Energy and Water are never tradeable, income or expense**, full stop —
  both are rate-tracked with no stockpile (see Buildings & Economy's
  Resources' Energy Income/Consumption Rates and Water), so there's
  nothing for a per-season lump exchange to add to or deduct from.
- **Local Delicacy's ingredient** (see Buildings & Economy's Food/Meal
  Conversion) is a natural fit as a civilization/planet-specific income
  option within this system — the alliance existing unlocks the *recipe*,
  but actually being able to cook it would require having negotiated a
  Trade Agreement that brings the ingredient in, rather than it arriving
  automatically. Proposed here as the resolution to that recipe's
  previously-open sourcing question; flag if you'd rather keep it
  decoupled from Trade Agreements entirely.

**Elevated legend value.** Every task in this chain — the initial
detection, Observe from a distance, and First Contact regardless of which
approach is chosen — carries an elevated, design-authored legend-value
(see Frontier Legends in [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)) relative to ordinary
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
general injury/death Legends bonus described in [Risk Spectrum](05_settlers_and_exploration.md#risk-spectrum), below, if
Bluff or Military Exploitation goes badly.

**Vaccine-unlock region reveal** (third worked example): a bio-survey
exploration task discovering a dangerous pathogen (see Buildings & Economy's
[Protection](04_buildings_and_economy.md#protection), [Medical Bay](04_buildings_and_economy.md#medical-bay)) is tied to the specific region where it was found.
Once enough `Confidence(Bio-hazard)` accumulates and Medical Bay's Vaccine
Production tier unlocks for that pathogen, the settlement is assumed fully
vaccinated — and that unlock guarantees a new escalation: an exploration task
to explore the specific region the pathogen came from, previously too
dangerous to approach, now safe. A clean example of a *building* unlock
(rather than an exploration outcome) triggering an escalation.

### Risk Spectrum
Every task has exactly one of three risk profiles, defined by its worst
possible outcome — not by reward rarity, which is a separate, independent
axis (see [Outcomes and the Strategy Dimensions](05_settlers_and_exploration.md#outcomes-and-the-strategy-dimensions), above):
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
the failure-gated negative-outcome pool described in Injuries: they carry
a base **100% success rate** — only reducible by negative Exploration
Aptitude (see [Settlers](05_settlers_and_exploration.md#settlers)' [Aptitude](05_settlers_and_exploration.md#aptitude)), otherwise as good as guaranteed — but
the risk tier still applies as a fully separate **independent roll**
alongside it — the settler *will almost always* discover the vein, but the
dangerous environment they found it in (an active volcanic zone, a deep
cave) can still injure or kill them regardless of whether the discovery
itself succeeded. The two rolls never interact — a negative-Aptitude
settler failing the discovery doesn't change their odds on the danger
roll, and vice versa. This roll fires on *every* attempt rather than only
after a failure, so it carries its own far gentler weights (see
`data/injury_outcome_weights.csv`'s "Independent risk roll" rows).

Because the two rolls are independent, the results dialog (see Core Loop &
Grid's Season Structure, Post-Sim step 5) **reports them on separate
lines** — what the task found, and what happened to the settler — rather
than merging them into one verdict. A settler hurt on a task whose find was
never in doubt must not read as a failed task. When that happens, the settler earns a **Frontier
Legends bonus** (see `data/misc_balancing_values.csv`'s "Risk Spectrum"
rows) for every task of this shape, not just Profile-shifting-flavored
ones: a settler who's hurt or lost expanding the settlement's strategic
options has done something legend-worthy regardless of which specific
dimension it moved. Injury's bonus is larger than death's — the settler
who survives becomes a living legend who keeps contributing to the
colony's story; death is honored, but doesn't keep generating one.

For the specific tasks already designed as Low- or High-risk, the
original design intent still holds — risk-bearing tasks tend to guard
better rewards — but this is true of *those tasks specifically*, not a
universal rule; plenty of No-risk tasks (Meteorite Fragment, the
Wonder-flavor Legend outcomes, most Farm-wide Upgrades) are just as rare or
valuable. Planet type affects the proportion of Low/High-risk tasks
available (e.g. a volatile volcanic planet generates more of them).

---

## Standing Assignments

**At a glance:**
- **Basic Deposit Survey / Deep Survey** — rectangle-based deposit
  discovery; Settlers + Advanced All-Purpose Drones.
- **Clear-Cutting** — production-speed-based Forest-tile Wood harvest;
  Settlers + any All-Purpose Drone.
- **Trapping** — production-speed-based Pelt yield, renewable; Settlers +
  Advanced All-Purpose Drones.
- Safe (no risk, no Rations), drawn fresh each season, not pool-limited.

The other of the three Assignment target kinds (see Core Loop & Grid's
[Assignment](03_core_loop_and_grid.md#assignment)) — drawn fresh each season rather than pool-limited, and
**safe** (no risk spectrum, no Rations — the work stays on or near the
farm, unlike a genuine off-site expedition). Worker-type eligibility
varies per assignment, unlike Exploration Tasks (settler-only, full stop)
— see Buildings & Economy's [Robotics Assembly](04_buildings_and_economy.md#robotics-assembly) for the full drone
taxonomy. Four members:

- **Basic Deposit Survey** and **Deep Survey** (see Buildings & Economy's
  [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery)) — Basic Survey covers a player-chosen rectangle of
  tiles and flags which of them are worth a Deep Survey; Deep Survey then
  automatically targets every tile flagged that way so far, no rectangle
  choice needed. Both repeatable, one-shot per assignment (the worker is
  gone for the season and returns with a result) — the same resolution
  shape Exploration Tasks use. Open to Settlers and Advanced All-Purpose
  Drones (not Basic).
- **Clear-Cutting** (see Buildings & Economy's [Fuel](04_buildings_and_economy.md#fuel)) — production-speed-based,
  like a building: the player selects any number of individual Forest tiles
  (drag-click marks every eligible tile within a rectangle and can only
  mark, never unmark; single-tile click toggles mark/unmark on one tile at
  a time), and the assigned worker works through them during Mid-Sim — how
  many get fully cleared by season end depends on their speed, with any
  unfinished tiles carrying over if reassigned next season. Each tile's
  Wood is bounded and depletes with use. Open to Settlers and any
  All-Purpose Drone, Basic included.
- **Trapping** (see Buildings & Economy's [Farm/Production](04_buildings_and_economy.md#farmproduction)) — also
  production-speed-based: targets one tile, yielding Pelt through repeating
  production cycles across the season's Mid-Sim window rather than a
  single lump-sum result, boosted by Forest presence and the planet's
  biological richness. Unlike Clear-Cutting, renewable and repeatable
  indefinitely on the same tile. Open to Settlers and Advanced All-Purpose
  Drones (not Basic).

Trapping and Clear-Cutting's speed-based shape makes them eligible for
Storied's production-speed bonus (see [Settlers](05_settlers_and_exploration.md#settlers)) the same way a Production
building assignment is.

Since these aren't drawn from the Exploration Tasks pool, they don't
participate in that system's Reinforcing/Profile-shifting/Neutral outcome
framing (see [Outcomes and the Strategy Dimensions](05_settlers_and_exploration.md#outcomes-and-the-strategy-dimensions), above) — they're
guaranteed, mundane, on-farm work, not strategic-profile-shifting content.

---

## Food & Nutrition

**At a glance:**
- **Nutrient Axes** — Protein/Fat/Carbs/Vitamins per food item.
- **Rations** — fixed non-replenishable starting stock; producible at
  Ration Press (lossy); no nutrient profile, flat sustenance.
- **Consumption** — pooled at settlement level, not per-settler; excludes
  exploring settlers; sticky default food selection; Tier 1 (bulk
  shortfall → deaths) vs. Tier 2 (axis imbalance → score-only).
- **Infected Food** — two forms (`normal`/`parasite-infected`), visually
  identical until a countermeasure or max Kitchen/Medical Experience/
  Aptitude reveals it.
- **Food Security score** — `normalize(NutritionStockpile) +
  normalize(NutritionIncome)`, end-of-run.

### Nutrient Axes
Every food item, including Rations, has a **Protein / Fat / Carbs / Vitamins**
profile — category names, not real-world units, consistent with the units/naming
principles (e.g. Bread: 1/1/5/0; an Apple: 0/0/1/1; Milk: 1/1/0/2; Rations: 1/1/1/1
per unit, matching "1 unit = 1 season's complete nutrition for 1 settler"). Visible
in any food item's info tooltip.

### Rations (Basic Sustenance)
- Every settlement starts with a **fixed, non-replenishable quantity** of
  pre-packaged Rations (see `data/misc_balancing_values.csv`'s "Rations"
  row) — densely packed, unappetizing, meant only to sustain life.
- **No automatic replenishment** — once the starting stock (plus anything the
  player has manually produced, see below) is gone, there is no free fallback
  left. This creates natural, legible pressure to establish real Kitchen/Farm
  food production early.
- **Can be manually produced** at a **Ration Press** (see Buildings &
  Economy's [Food/Meal Conversion](04_buildings_and_economy.md#foodmeal-conversion)) — an unstaffed, cycle-based building that
  turns player-selected fresh food into Rations, at a **lossy** rate (a
  Ration is worth meaningfully less sustenance than eating the input
  fresh). Rations carry **no per-axis nutrient profile** — they are flat
  sustenance — so they cover the Tier-1 bulk check but do nothing for
  Tier-2 axis balance. Valuable specifically for portability (required for
  certain exploration tasks — see [Assignment](05_settlers_and_exploration.md#assignment) above), not a strictly better
  choice than fresh consumption. The press has two output modes: packaged
  Rations, or a bulk **Stockpile Fill** feeding Food Storage (see Buildings
  & Economy's [Storage](04_buildings_and_economy.md#storage)) — and a **Food Storage building, when staffed, can
  run the reverse**, extracting bulk stock back into packaged Rations at a
  deliberately poor rate, a last-resort valve for a season the settlement
  would otherwise lose settlers.
- If total available nutrition (Rations plus any meals) can't cover the
  settler headcount at all, the shortfall causes **settler deaths** — a
  confirmation dialog gates confirming a season with deaths planned from
  this shortfall. **Who dies is drawn
  uniformly at random** ("drawing lots") from everyone needing to be fed at
  the settlement that season, excluding any settler currently on an
  Exploration Task — their Rations were already committed at assignment
  time, separate from this pooled at-home check.

### Meals
- Produced at ordinary staffed single-conversion production sites (see [Platform](03_core_loop_and_grid.md#platform) &
  Core Loop Redesign's [Production Model](03_core_loop_and_grid.md#production-model)) — no merge-space crafting.
- Defined by a recipe (single input→output conversion) and a nutrient-axis
  profile. **No secondary effects.**
- Meal items do not expire.

### Consumption — Pooled, Not Per-Settler
- Nutrition need and availability are tracked **at the settlement level, not per
  individual settler** — e.g. 4 settlers need a pooled 4/4/4/4 per season; 1 Bread +
  1 Apple + 2 Milk (1/1/5/0 + 0/0/1/1 + 2×[1/1/0/2] = 3/3/5/5) is evaluated against
  that pooled need as a whole, with no bookkeeping over which settler "ate" what.
  Keeps small-number play simple and avoids the nutrition system dominating
  gameplay. **The pooled headcount only counts settlers actually present at
  the settlement that season** — a settler assigned to an Exploration Task
  (see [Exploration Tasks](05_settlers_and_exploration.md#exploration-tasks)' Assignment) is excluded from it for the season(s)
  they're away, since their sustenance is covered separately by that task's
  strict Ration cost instead. A settler who **died earlier in the season**
  (a hazard event, an injury) isn't counted either — the check runs at
  Post-Sim against whoever is alive when it runs, and nothing was set aside
  for them beforehand, so the settlement simply eats less and the surplus
  stays in inventory. A deliberate, lightweight departure from realism that
  suits the cozy register better than tracking partial-season meals.
- **Food-for-consumption is assigned during planning** (not fully automatic), but
  defaults intelligently each season in this priority order:
  1. If the food types consumed **last season** are available and sufficient on
     their own, default to using those again.
  2. If those types are available but insufficient, use them fully and cover the
     remainder with Rations.
  3. If none of last season's types are available, default to Rations entirely.
  4. If Rations have run out entirely (the finite starting stock, plus
     anything manually produced at a Ration Press, is exhausted), this
     fallback simply provides nothing.
- The player can always override this default during planning; a stable diet simply
  continues itself with no action required — a sticky-default cousin to worker
  staffing.
- **Two-tier consequence model:**
  - **Tier 1 — bulk shortfall (existential):** total available nutrition can't cover
    the settler headcount at all → settler deaths, as described above.
  - **Tier 2 — axis imbalance (soft):** bulk need is covered, but one or more axes
    falls short of pooled need → **no in-run consequence** — tracked only for the
    end-of-run Food Security score below. A short axis is marked with a
    glyph beside its always-present label (per the shared status-cue
    vocabulary — see Production & Technical's [Art Design](07_production_and_technical.md#art-design)), never a tint
    alone.
- **No penalty for excess** in any axis — surplus simply accumulates in the shared
  inventory stockpile, feeding the score below.

**Planning-phase prediction readout.** The actual Tier-1/Tier-2 check still
resolves once, at Post-Sim (see Core Loop & Grid's [Season Structure](03_core_loop_and_grid.md#season-structure)) — but
the player isn't left guessing whether their plan covers a dire need until
it's too late to act. Through the Planning Phase, a readout projects the
likely season-end nutrition outcome from currently-stocked food plus this
season's staffed production, the same **"optimistic estimate, not a
guarantee"** role the Energy Income/Consumption bar already plays (see
Buildings & Economy's [Resources](04_buildings_and_economy.md#resources)) — reusing that established pattern rather
than inventing a second one. In the common case, given how severe Tier-1's
consequence is, this simply reads "on track" before the player has to think
about it at all; it only becomes an active decision point on a genuinely
tight plan, which is exactly when it should. This adds no new mechanic to
nutrition itself — no per-tick consumption, no new tracked quantities —
it's a projection layered on the existing once-a-season check.

### Infected Food

Every **animal-derived food item** (meat, organs, and any product of a
parasite-infected husbandry population) exists in two forms — `normal` and
**`parasite-infected(type)`** — that are **visually identical by default**.
A Meal cooked from an infected ingredient is itself infected; **Rations are
never infected** (the Ration Press's processing sanitizes its input — see
Buildings & Economy's [Ration Press](04_buildings_and_economy.md#ration-press)), and neither is anything in Food
Storage.

**Visibility.** The player can tell infected from normal only when one of:
(a) the countermeasure for that parasite has been researched, (b) a
non-exploring settler has **max Kitchen or Medical Experience**, or (c) a
non-exploring settler has **max Kitchen or Medical Aptitude**. This is
distinct from a threat being merely *confirmed* (on the countermeasure
research list): a parasite can be known to exist while its infected items
stay invisible.

- **While visible**, infected food splits into its **own inventory entry**
  (e.g. "3 Meat" and "2 Meat (infected — Taenia analog)"), is **excluded
  by default** from the food-for-consumption selection, and can only be
  eaten by **explicit manual assignment** — the desperation choice
  (infected food or starvation) stays available, just never automatic.
- **While invisible**, infected food is indistinguishable and gets pulled
  into the seasonal pool like any other — and if it does, **every
  non-exploring settler is infected at Post-Sim** (the planning-phase
  nutrition prediction can't warn of this — it counts invisible infected
  food as normal).
- **The reveal beat.** The moment a countermeasure finishes *or* a settler
  first crosses the Experience threshold to identify infection, every
  infected item already in inventory splits out at once; both moments come
  with a **Transmission** that names how the settlement learned (lab
  analysis / a specific settler's expertise).

### End-of-Run Food Security Score
`FoodSecurity = normalize(NutritionStockpile) + normalize(NutritionIncome)`

`NutritionStockpile` is a flattening function (`sqrt`, tunable later via
playtesting) of a **single flat sustenance quantity** — the bulk
Ration-content held in Food Storage. It is **not** a per-axis sum:
long-term storage holds homogenized, sanitized Ration-content with no
nutrient-axis profile (see Buildings & Economy's [Ration Press](04_buildings_and_economy.md#ration-press) / [Storage](04_buildings_and_economy.md#storage)),
so per-axis balance lives entirely in the *in-run* Tier-2 check where it
belongs. Because `sqrt` flattens at high values, the marginal value of
further stacking shrinks — the reserve is worth building, with
diminishing returns.
**The counted amount is what sits in Food Storage at a run-end snapshot**
— routed there via a Ration Press's Stockpile Fill, nothing else; food in
general inventory doesn't count, and anything extracted back out (a
last-resort crisis move — see [Storage](04_buildings_and_economy.md#storage)) simply stops being scored.

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
