# Design To-Do — Faction-Driven System Gaps

Tracks remaining content/system design work in `full_design/`, organized around
what each SEED Faction's scoring formula still needs to become concrete and
buildable. All five faction formulas are done (see Win/Lose Conditions); this
tracks what's needed *underneath* them.

## Per-Faction Status

- [x] **Development Bloc** — formula done
  - [ ] Rarity weights per resource (not yet assigned)
  - [ ] Real buildings/items catalog carrying `TechAchievement` values — a
    first-pass table was drafted and partly discussed, then paused to do
    the fabrication-chain revisit below first; needs re-running once that
    settles, since it added several items (Lumber, Leather, Wooden Plow)
    and changed several recipes (Temperature-Resistant Gear,
    Scanner Station, Medical Bay, the drone tiers) since the draft table
    was made.
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
- [ ] **Production building UI** — not yet designed at all; how a player
  actually sees/interacts with a staffed site's assignment, Effort,
  Experience/Aptitude readouts, and (for drones) battery state during
  play.
- [ ] Remaining numeric TBDs from the Settler State / Injuries / Storied
  design pass: Storied's `legend_value` threshold; the Temperature
  Extremity settler death-probability on extreme exposure; Trapping's and
  Clear-Cutting's per-settler speed rates.

## Core Loop / Structural Gaps

- [ ] **Season simulation** — in progress. **Resolved so far**: fixed
  real-time window length (seasons correspond to fixed real-world time
  in-fiction; playback speed stays a pure time-multiplier); two resolution
  contexts, Outside-Sim (merges pre-clock, post-clock, and
  start-of-next-planning into one mechanically-equivalent instantaneous
  bucket) and Mid-Sim (the only place real time passes — continuous
  production plus any discrete event with a genuine reason to occupy a
  specific interval, e.g. hazard events); the "ambient Mid-Sim visual for an
  Outside-Sim-resolved activity" pattern (see Art Design); the
  **log/event-feed system** (see Core Loop & Grid's Season Structure) — a
  single togglable log (no forced overlay), per-resource-type aggregated
  production lines that live-update/re-timestamp, individual lines for
  noteworthy events, Transmissions kept fully separate. **Still open**: how
  multiple buildings' continuous production cycles interleave *visually*
  beyond the log itself; the internal sub-step ordering within Outside-Sim.

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
