# Design To-Do — Faction-Driven System Gaps

Tracks remaining content/system design work in `full_design/`, organized around
what each SEED Faction's scoring formula still needs to become concrete and
buildable. All five faction formulas are done (see Win/Lose Conditions); this
tracks what's needed *underneath* them.

## Per-Faction Status

- [x] **Development Bloc** — formula done
  - [ ] Rarity weights per resource (not yet assigned)
  - [x] Real buildings/items catalog carrying `TechAchievement` values — see
    Buildings & Economy's [TechAchievement Catalog](04_buildings_and_economy.md#techachievement-catalog); the 0–4 rubric, the counting
    rule (each distinct entry counts once per run, not per unit/copy), and
    per-entry values are all written in. Exact numbers are a first pass,
    same as every other illustrative number in this design — revisit
    during balancing, not urgent to track here further.
- [x] **Frontier Legends** — formula done
  - [ ] Catalog of named "hard sites" with legend-values

## Open Items

- [ ] **Fabrication chain revisit — still open pieces**: this pass (see
  Buildings & Economy's Resources and Fabrication) replaced Matter with
  Lumber/Concrete as the universal construction-cost materials, split
  Carpenter's Shop into a starting Sawmill (Lumber only) + Carpenter's Shop
  upgrade, split Stone Processing into a starting Stone Processing I
  (Concrete only) + Stone Processing II upgrade (adds Silicon), introduced
  Leather (tanned from Pelts) alongside Fabric, added the Wooden Plow, and
  widened High-Tech Components into several more recipes and structures.
  Still to do:
  - Per-building **Lumber:Concrete construction-cost ratios** across the
    whole catalog — this pass established the rule (and Quarry's specific
    small-Lumber-only cost) but deferred assigning the actual ratio for
    every other building.
  - **Wooden Plow's gameplay mechanics** — only its fabrication recipe (2
    Lumber + 1 Leather) is defined so far; what it actually does for
    outdoor farming is explicitly deferred.
  - Sawmill→Carpenter's Shop and Stone Processing I→II **upgrade costs** —
    TBD.
- [ ] **Production building UI (planning phase)** — not yet designed at
  all; how the UI presents a production site's available choices during
  planning — which resources to produce, which recipe among alternatives,
  Effort/Experience/Aptitude readouts for the assigned worker(s), and
  similar. (Mid-Sim worker status display is a separate, now-resolved
  concern — see Core Loop & Grid's Worker Roster (UI) — this item is about
  the planning-phase choice-presentation problem specifically, not
  in-simulation status.)
- [ ] Remaining numeric TBDs from the Settler State / Injuries / Storied
  design pass: Storied's `legend_value` threshold; the Temperature
  Extremity settler death-probability on extreme exposure; Trapping's and
  Clear-Cutting's per-settler speed rates.

## Core Loop / Structural Gaps

- [ ] **Season simulation** — in progress. **Resolved so far**: fixed
  real-time window length (seasons correspond to fixed real-world time
  in-fiction; playback speed stays a pure time-multiplier); three resolution
  moments — **Planning Lock-in** (instantaneous, right before the Mid-Sim
  clock starts; reversible planning choices simply freeze into fixed
  inputs — Food Storage deposits, food-for-consumption selection,
  construction/upgrade/relocate queuing — no consequence computed, nothing
  revealed), **Mid-Sim** (the only place real time passes — continuous
  production plus any discrete event with a genuine reason to occupy a
  specific interval, e.g. hazard events), and **Post-Sim** (instantaneous,
  merges the moment right after the clock ends with the top of the next
  planning phase, since neither involves real time passing — renamed from
  the old single "Outside-Sim" now that the pre-clock moment has its own
  Planning Lock-in bucket; hosts actual season-outcome resolution: Vaccine
  unlock checks, pooled nutrition consumption resolution — deliberately here
  rather than Planning Lock-in, so mid-season production is consumable that
  same season — Scanner Station report resolution, Deposit Discovery
  resolution, construction/upgrade/relocate completion); the "ambient
  Mid-Sim visual for a Post-Sim-resolved activity" pattern (see Art Design);
  the **log/event-feed system** (see Core Loop & Grid's Season Structure) —
  a single togglable log (no forced overlay), per-resource-type aggregated
  production lines that live-update/re-timestamp, individual lines for
  noteworthy events, Transmissions kept fully separate; the **production
  progress overlay** (see Core Loop & Grid's Season Structure) — a per-tick
  semi-transparent bottom-up fill on each active production site's sprite,
  driven directly by the continuous-rate progress value, established as the
  primary at-a-glance channel (deliberately redundant with the log, which
  serves slower retrospective parsing instead); the **internal sub-step
  order within Post-Sim** (see Core Loop & Grid's Season Structure) —
  Scanner Station report resolution, then Deposit Discovery resolution,
  then pooled nutrition consumption, then construction/upgrade/relocate
  completions (relative order among these four is arbitrary — no
  dependencies), then the Exploration Task confirmation UI at next
  planning-phase start, then the Vaccine unlock threshold check
  unconditionally last (after every `Confidence`-feeding source for the
  season, including exploration-driven ones, has landed); the **assigned-worker
  Mid-Sim depiction** (see Core Loop & Grid's Season Structure) — a static,
  non-walking sprite parked at/near the assigned site, purely an
  ownership/presence cue; and the **Worker Roster's Mid-Sim expansion**
  (see Core Loop & Grid's Worker Roster (UI)) — one icon per actual worker
  during simulation (vs. one row per type during planning), each showing
  working/hazard-affected/idle state, with drones additionally always
  showing a battery-remaining bar; **Hazard Event concurrency** (see Planets
  & Scoring's In-Simulation Hazard Events) — only Storm and Temperature
  Extremity manifest as discrete Mid-Sim events at all (Atmospheric Hazard
  is a continuous check, Bio-hazard only resolves via exploration
  encounters), each capped at most once per season by its one-report/season
  evidence source, and when both occur with overlapping windows at the same
  site their consequences stack independently (no double-destroy — a
  second destruction check against an already-emptied slot is a no-op);
  **Playback Speed** (see Core Loop & Grid's Season Structure) — the
  Mid-Sim window is now **30 seconds at 1×** (was 15s in the prior
  implementation, widened so unhurried 1× playback has room to not feel
  rushed); speed is a **continuous-feeling slider from 0× to 5×, snapping
  to 0.1 increments**, rather than discrete preset buttons, with **0× as
  an outright pause** (no separate pause control, and this is also the
  resolution to mid-simulation pause/resume — 0× on the same slider *is*
  pause); Mid-Sim visual legibility (production overlay, hazard events,
  ambient depictions) deliberately **targets 1× only**, with no minimum
  wall-clock floor at higher speeds — a legibility-for-time tradeoff placed
  entirely in the player's hands, on the same "log covers what you missed"
  precedent as the production progress overlay above; the standalone "Skip
  simulation" button from the prior implementation is **removed** —
  cranking the slider to its 5× max (30s → 6s) is the only rush-to-next-
  season option; and the **default per-season speed is sticky-carried**
  (the same pattern as food-for-consumption and other planning defaults),
  starting at 1× until the player first adjusts it, rather than a separate
  Settings-menu preference. No further specifically-identified open
  sub-items remain for Season Simulation at this pass — left unchecked
  below since this reflects the currently-known gap list, not a claim that
  every possible gap has been surfaced.

## Newly Surfaced Ideas (recorded, not yet designed in detail)

- [ ] **Alien trade economy** — surfaced while designing the Local Delicacy
  food good (see Buildings & Economy's Food/Meal Conversion): once a
  Peaceful Contact alliance exists, how does the player actually *trade*
  with it? Does it get its own dedicated interface, or does it operate
  through repeatable/follow-up exploration tasks the same way everything
  else in the sentience-contact chain does? This is the same underlying
  gap as the already-tracked "Peaceful Contact's base alliance rewards"
  item below, just approached from the trade-goods side rather than the
  rewards side — worth resolving together, not twice.
- [ ] **Water resource open threads**: settler Water-shortfall consequence
  model (does it mirror nutrition's Tier-1 mechanic, or differ?);
  Reclamation's unlock gate (tech/resource prerequisite, not yet
  specified).

## Other Fabrication-Adjacent Gaps

- [ ] **Livestock vaccines** — back-burner idea, recorded not designed:
  protecting animal-production buildings (Dairy Pasture, Poultry Coop, Sheep
  Pasture) from Bio-hazard (and maybe Weather) via a produced vaccine *item*
  distinct from the human Vaccine Production unlock — would imply an actual
  recurring manufactured good rather than a one-time settlement-wide fact.
  Low-overhead, flavorful, not urgent.
- [ ] **Hydroelectric Generator + River feature** — surfaced as a side note
  during the Energy Pool redesign, not yet designed. Would need a new
  **River** grid feature first — checked, and confirmed this was only ever
  mentioned conceptually during the original Water design pass, never
  actually formalized as a feature anywhere. A genuinely new piece of scope,
  deliberately deferred rather than bundled into the Energy Pool rework.
- [ ] **Hybridization numeric details still TBD** — surfaced while building
  out the exploration content catalog. Exact Water-reduction amount (Arid),
  yield-boost amount (Verdant), Research Lab `production_time` per project,
  and the generic "broad yield improvement" magnitude for the
  planet-independent (meteorite-fragment-unlocked) hybridization path are
  all still unspecified — deferred to balancing like other numeric values
  in this design, but flagged here so they don't get lost.
- [x] **Alien civilization classes** — mostly resolved (see Settlers &
  Exploration's Escalation Chains): five axes (Technology Level, Openness,
  Economic Stability, Ubiquity, Unity) combine into four curated classes
  (Verdant Assembly, Hollow Kilns, Drift Caravans, Frostbound Remnant)
  rather than a full cross-product. First Contact surfaces as one pool slot
  with three switchable approaches — Peaceful Contact, Bluff/Coercive
  Exploitation, Military Exploitation — and Stewardship Caucus gained a new
  `ContactRestraint` formula term. **Still open, deferred to balancing:**
  - Exact `ContactRestraint` tier values
  - Exact Bluff success-probability curve vs. Technology Level
  - Exact Military success-probability curve vs. Technology Level + Unity
  - Peaceful Contact's base alliance rewards, and its per-tier deepening
    rewards
  - Bluff's on-success payout amount (relative to an undeepened alliance's
    baseline)
  - Military Exploitation's success rewards
  - Overwhelming Force Package's exact recipe (a first-pass placeholder is
    written into Buildings & Economy's Fabrication)
  - Exact legend-value-scaling formula shape (inverse of success
    probability, magnitude TBD)
