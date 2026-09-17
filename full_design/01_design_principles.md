# Design Principles

## Design Principles

> Open question: difficulty philosophy is now covered (see ["failure should always be
> legible," "difficulty comes from breadth of tradeoffs," and "forgiving of
> individual mistakes, punishing of sustained neglect"](01_design_principles.md#design-principles) below). Still unexplored:
> **replayability** (candidates floated: variety from different planet scenarios
> rather than reshuffled numbers; meta-progression expanding the strategy space
> rather than just raising the floor; end-of-run reports that seed the next run's
> approach), **tone consistency for mechanical severity** (does a colony-ending
> failure get framed narratively as a valuable discovery for SEED rather than a
> punitive "game over"?), and **interruptibility** (an explicit guarantee that the
> game is safely pausable at any moment with no meaningful progress loss, formalizing
> what the save-trigger behavior in [Backend & Data Persistence](07_production_and_technical.md#backend--data-persistence) already does in
> practice).

- **Numbers stay small.** Describes how the finished game should feel to play — not a
  constraint to design against in advance. Quantities the player reads and reasons
  about should stay human-legible at a glance. Don't add caps, clamps, rescaling, or
  number-hiding logic pre-emptively because a number *might* grow large.

  Treat a number that grows unhelpfully large in play as a diagnostic signal, not just
  a cosmetic problem — similar to a code smell. Ask why it got big before deciding how
  to fix it. Sometimes the fix is a straightforward scale or cap on a value nobody was
  meant to track closely. Other times a big or opaque number reveals a deeper issue
  with the system producing it — e.g. an end-of-run score built by summing several
  unrelated outcome factors is not just an oversized number, it hides the information
  the player actually wants (how did each thing I did turn out?) and can quietly push
  players toward optimizing whichever single factor moves the total most, narrowing
  playstyles instead of rewarding a breadth of approaches. In that case, the fix isn't
  rescaling — it's reconsidering whether the system should produce one summed value
  at all.
- **Units are unspecified.** Applies to *real-world physical unit labels* (Watts,
  Joules, kilograms, meters, etc.) attached to in-fiction resource quantities — not to
  showing quantities themselves, not to abstract non-physical scales, and not to
  real-world meta/UI information that sits outside the fiction.

  The game never explains the underlying real-world mechanism behind Energy
  or other in-fiction resources in enough technical detail to justify a genuine
  physical unit — attaching one anyway would only add shallow flavor while creating a
  place for a player with real domain knowledge to notice an inconsistency (wrong
  order of magnitude, mismatched conversion) and get pulled out of immersion. A
  resource's own name already functions as its unit: "5 Energy" needs nothing more.

  This does not mean hiding quantities or rates — a rate like "Energy per season" is
  exactly the information a player needs for planning and should always be shown
  plainly as a number.

  Abstract, non-physical scales are exempt for a different reason: they aren't
  partially-explained real-world phenomena, they're intentionally abstract, so
  there's nothing to under-explain — no unit is expected or missing.

  Real-world meta/UI information that sits outside the game's fiction (e.g.
  simulation playback timestamps in seconds) is also exempt — it isn't a quantity
  being measured *in* the world, it's the actual clock the player uses to read the
  UI, and seconds are a unit every player already understands without any in-fiction
  justification needed.

  A third exemption covers real-world physical quantities so universally familiar
  that *hiding* the real unit would confuse rather than simplify — the opposite
  failure mode from the one this principle otherwise guards against. Time durations
  (production cycles measured in seconds) are the first example; **Temperature**
  (see Planets & Scoring's [In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events)) is the same case — showing
  "15 Temperature" instead of "15°" would force players to re-learn an arbitrary
  scale for a quantity they already understand instinctively in Fahrenheit or
  Celsius. Unlike Energy/Water, which have no real-world referent a typical
  player already holds, temperature and time are quantities everyone already has
  working intuition for — the exemption applies specifically because a made-up
  scale would be a net loss of clarity, not a gain in immersion. Fahrenheit vs.
  Celsius display is a player-facing settings toggle, the same way a real-world
  unit choice would be handled in any other application.
- **UI interaction is minimal.** Describes the entire path from a player forming an
  intent to that intent being satisfied — not just the final gesture that executes
  it. Minimize *structural* friction along that path: searching, redundant
  navigation, and extra taps that don't represent a real decision. It does not mean
  minimizing the number of genuine decisions themselves.

  Concretely, this principle favors:
  - **Surfacing relevant/available choices ahead of irrelevant/unavailable ones** in
    any list or menu, so the common case never requires scrolling or hunting (e.g.
    buildable buildings grouped above unaffordable ones; a newly-available meal
    surfaced near the top of an inventory list rather than requiring a search).
  - **Showing choices all at once rather than gating them behind extra navigation**
    (e.g. a grid of icons instead of tabs that cost a tap just to reveal a subset).
  - **Fusing select-and-act into one continuous gesture** where the two naturally
    belong together (e.g. tap-hold to pick a building, drag to place it, in one
    motion).
  - **Letting UI proactively get out of the way once its purpose is fulfilled**,
    rather than requiring an explicit dismiss (e.g. a building-selection panel that
    shrinks to reveal the grid the moment a choice is made).
  - **Automating an unambiguous, likely-intended default** on the player's behalf
    rather than requiring an explicit action to reach it — provided the automation
    remains overridable within the (already-reversible) planning phase (e.g.
    auto-assigning an unclaimed crafted meal to a settler with none).

  This principle does **not** argue against multi-step interactions that represent
  genuinely separate decisions, even split across different panels or different
  points in time (e.g. crafting a meal one season and assigning it to a settler the
  next — two real decisions, not one action artificially fragmented). It also does
  not argue against confirmation dialogs on irreversible or high-stakes outcomes —
  those deliver a decision the player hasn't yet made, not incidental overhead. And
  it does not require every piece of information to be visible with zero
  interaction — gating occasional/diagnostic depth behind an optional gesture is
  fine, as long as the headline information needed for routine planning remains
  visible by default.
- **Planning phase is reversible.** All decisions during planning can be undone until
  the player confirms "Proceed to Next Season." This exists so planning genuinely
  feels like planning: a space to freely test and adjust a prospective plan, where
  every piece of feedback the game shows during planning — calculated outcome deltas,
  projected production, or anything else — exists purely as an aid to help the player
  build their intended plan, not as an event with lasting consequence.

  **Player knowledge is out of scope.** The principle governs game state (grid
  layout, resource totals, assignments), not what the player has learned. A
  building's behavior learned by watching it run, outcomes previewed by the UI, or
  knowledge gained from a friend or outside resource are all one-way doors in the
  player's head, and that's fine — even good, since it makes planning feel
  discovery-driven. Undoing a placement reverts the game state; it was never
  expected to revert what the player now knows.

  **Auto-queued defaults are exempt from undo-history semantics, but carry a
  transparency bar instead.** A default the game applies without an explicit player
  action (e.g. auto-spending Rations on basic sustenance) doesn't need "undo" in the
  traditional sense — the player never took an action to undo, they simply haven't
  chosen to override the default yet. But introducing any such default requires it
  to be (a) the obviously-correct choice, both mechanically and in the game's
  fiction, and (b) transparently surfaced through inspectable, immediately-available
  UI feedback shown at the very start of planning, before the player does anything
  else.

  **Randomization must not be freely reversible, and must be gated behind an
  explicit, distinct commitment.** Weaving a random draw into an otherwise-reversible
  interaction (e.g. placing a building) silently breaks that interaction's
  reversibility, since undoing it can't restore the original roll. The fix isn't to
  forbid randomization during planning — it's to require any random draw be
  triggered only by a separate, explicit, irreversible choice, clearly distinct from
  the ordinary reversible planning interactions (placement, movement, assignment)
  around it. For example: a building with a randomized component requires a separate
  one-time commitment (unlocking that random outcome for whatever scope — a season,
  the rest of the run) before it can even be placed, so placing and moving the
  building itself stays fully reversible. Similarly, an exploration "reroll" that
  draws a new set of candidate sites for some resource cost is itself irreversible —
  but assigning settlers, tools, or food to a chosen expedition afterward remains
  ordinary, reversible plan-composition.
- **A passable plan should always be quick to reach.** The effort needed to
  construct a merely-adequate (not optimal) plan for a season should stay low
  throughout a run, and shouldn't meaningfully grow as systems and complexity
  accumulate — even in the late game. This describes a floor, not a ceiling: it says
  nothing about players who enjoy deep optimization and choose to spend much longer
  refining their plan. Treat a season that's become genuinely hard to find *any*
  passable plan for (not just hard to perfect) as a diagnostic signal that something
  in that season's design needs revisiting, similar to how an unhelpfully large
  number signals a system that needs a second look. A familiar player who's already
  reached their desired steady-state build should be able to coast through remaining
  seasons with near-zero action.

  This also subtly implies that the easiest-to-find passable plan should not, as a
  rule, coincide with the optimal one — there should generally be room for a more
  deliberate plan to outperform the passable baseline by at least some metric, or
  there'd be no reason for an engaged player to invest more effort. This principle
  doesn't prescribe which metric(s) define "better" (that's left to whatever
  scoring/outcome systems the design eventually specifies) — only that the gap
  between "quick and passable" and "deliberate and optimized" should generally
  exist.
- **Naming convention.** A name's primary job is to clearly and efficiently
  communicate the role, purpose, or relative tech-tier/rarity of the game element it
  labels — flavor (cozy futuristic sci-fi tone) is layered on top of that, not a
  substitute for it. This is the same underlying concern as "units are unspecified":
  labels should accurately communicate, not decorate.

  Basic, foundational things get simple, familiar names (Energy, Lumber, Concrete). Advanced,
  rare, or exotic things get progressively more technical or unfamiliar-sounding
  names (Flux-modulated Drone Battery), and the degree of unfamiliarity should scale
  consistently with actual tech-tier/rarity — a player should be able to roughly
  infer "this is more advanced/rarer" from how exotic a name sounds, so
  name-exoticism is a functional signal, not chosen freely per-item for flavor.
  Meals default toward familiar comfort-food names, but an advanced or alien meal
  should still earn a more exotic name once its ingredients or planetary origin
  justify it — reflecting purpose and origin, not trying to sound deliberately
  unintelligible for its own sake.

  **A name must never create a false implication about game-relevant behavior or
  properties that don't actually hold.** This rule only engages when a name carries
  decodable real-world semantic content a player would reasonably read meaning into
  (e.g. "Flux-modulated" implying some interaction with electrical/flux-based
  mechanics, if any exist; "Glacion" implying a cold planet). An arbitrary invented
  name with no real semantic payload (e.g. "Xorkad XI") makes no such promise and
  isn't constrained by this rule. If a meaningful name and an element's actual
  behavior would clash, either make the element behave consistently with what the
  name implies, or rename it.

  This applies to any named gameplay element with real game-relevant properties, not
  just directly manipulable items — planet names, for instance, should not imply a
  climate/hazard/resource profile that isn't true, when the chosen name carries that
  connotation. Purely flavor-only proper nouns with no gameplay role to communicate
  (e.g. the organization name "SEED") are exempt from the "communicate function"
  half of this principle, but still subject to "don't create false implications."

  **Identity and naming stay consistent across every context a player encounters an
  element.** The same name should always carry the same implications, so a player's
  past experience with an element transfers immediately and reliably wherever it
  reappears — regardless of how common or rare it happens to be in a specific run or
  on a specific planet. If an element's implications genuinely differ by context, it
  isn't the same element, and shouldn't share a name.
- **Color is never the sole channel of information.** The design already leans on
  color a lot (red/green resource deltas, staffed-vs-unstaffed site indicators,
  worker-footprint highlights). For colorblind players (red-green confusion is the
  most common form), every color-coded signal should be paired with a redundant
  non-color cue — shape, icon, position, or text — so nothing is lost if color can't
  be distinguished.
- **Dexterity-timing thresholds scale from one global setting.** All
  timing-sensitive gesture thresholds (double-tap window, tap-hold duration,
  drag-vs-tap distance, and any future equivalents) should derive from a single
  global accessibility setting exposed to the player (e.g. a "gesture timing" or
  "dexterity" scale in Settings), rather than each interaction defining and tuning
  its own fixed threshold independently. This keeps every touch interaction in the
  game consistently adjustable together, and keeps future features honest about
  reusing the same scale rather than inventing a new untunable threshold.
- **Every touch gesture needs a mouse equivalent.** Scoped specifically to
  touch-vs-mouse parity — not keyboard, voice, or other input modalities. Desktop
  mouse support (left-click=tap, right-click-while-dragging=rotate) already exists
  for core grid interactions; any new touch-first feature should ship with an
  equivalent mouse-driven path.
- **Text legibility has an honest ceiling.** The fixed low-res pixel-art aesthetic
  with integer scaling limits how much text-scaling flexibility is realistic.
  Rather than committing to a specific mechanism now, treat this as an area resolved
  primarily through playtesting and direct observation of legibility on target
  devices (Pixel 7a/10a) — pick a genuinely legible minimum font size, consider an
  optional larger font tier if authoring one proves feasible, but don't overpromise
  a level of scaling flexibility the art style can't structurally support.
- **Failure should always be legible.** When a run ends or takes a bad turn, the
  player should never be blocked from inferring what happened and why — but the game
  doesn't need to hold the player's hand by spelling everything out. The depth of
  explanation volunteered can vary by case:

  - **Exact probabilities aren't a general requirement.** Knowing the *direction* of
    an effect (e.g. better equipment improves an exploration task's odds) is enough
    by default. Showing a precise percentage is a legitimate enhancement where it
    adds value (e.g. a specific risk's exact chance, surfaced in a high-detail
    tooltip mode) — but it's a case-by-case content choice, not a blanket mandate.
  - **"Inferable through play" counts as legible.** A mechanism can be legitimately
    learned through experimentation rather than explained up front — but its
    *existence* as a discoverable capability must be signaled somehow (e.g. a
    Cafeteria building implies you can combine ingredients there, maybe reinforced
    by a brief tutorial line), even if the precise mechanical details (adjacency
    rules, ordering) are left for the player to figure out by doing.
  - **Luck must be distinguishable from certainty.** When an outcome stems from an
    accepted risk, the game must clearly communicate whether the negative result was
    a possible-but-unlucky roll (there was a real chance of success) versus a
    guaranteed outcome (there was no chance of success at all) — these two cases
    should never be conflated into the same generic "it went badly," since a player
    needs to know which one happened to correctly calibrate future risk-taking.
- **Difficulty comes from breadth of tradeoffs, not execution precision.** Challenge
  should come from balancing systems and resources against each other — a strategy
  puzzle — not from physical/motor execution skill (reaction time, aiming accuracy,
  timing precision).

  Grid placement is the model instance of this: since pieces snap to discrete cells,
  there is no physical aiming precision involved at all. The only difficulty that
  exists there is intellectual — wanting to fit more pieces than easily fit
  (space-scarcity/packing), or arranging many pieces to interact well together
  simultaneously (multi-piece synergy optimization). Both are exactly the kind of
  tradeoff-driven challenge this principle wants.

  Fine-motor gesture thresholds (double-tap timing, drag-vs-tap distance) are
  entirely the domain of the [accessibility principles](01_design_principles.md#design-principles) above (the global
  dexterity-timing scale) — this principle doesn't touch that territory at all, and
  there's no tension between the two.

  An isolated, non-core minigame (e.g. the Phase 5+ exoplanet-scanning minigame,
  where "harder" scales with how favorable the target is) is allowed to be an
  exception to this principle. But where there's a viable tradeoff-based alternative
  for expressing increased difficulty or progression-gated access — even one just
  *described* to the player as "difficulty" — that's preferred over reaching for
  execution-based challenge.
- **Forgiving of individual mistakes, punishing of sustained neglect.** "Forgiving"
  does not mean rubber-banding mechanics or guaranteeing every mistake is recoverable
  within the same run — it means the player can learn from a mistake, even if that
  lesson costs a run (or several) before it lands. This connects directly to
  "failure should always be legible": if the cause is clear, the way to avoid it next
  time should be clear too, even when the current run doesn't recover from it.

  A structural loss (e.g. a settler dying) is allowed to compound naturally into an
  ongoing disadvantage going forward — that's the honest continuation of a real
  loss, not a punitive mechanic layered on top, and it doesn't need to be softened.
  The actual mechanism delivering "forgiveness" is the roguelike structure itself:
  each run mostly resets, and meta-progression only ever adds new options, never
  subtracts — so a bad run is forgiven at the run-to-run level, not necessarily
  within the run it happened.

  The planning phase's job is to keep failures from being confusing or surprising in
  the first place — most within-run failures should trace back to a choice the
  player understood they were making, or a risk they knowingly accepted, not an
  ambush.

  **No purely ambient, untriggered randomness should be able to end a run.** A
  random event with no player action behind it (e.g. an out-of-nowhere weather
  disaster) has no buildup and nothing to learn from, so it has no place ending a
  run. A severe or even run-ending outcome from an explicit, high-risk choice the
  player knowingly initiated is different and remains allowed — e.g. an aggressive
  exploration option that can provoke total retaliation — provided the risk is
  inferable, either stated directly in the option's description or implicit in the
  nature of the action itself (initiating aggression against an unknown party
  obviously invites danger).

  **Misfortune is allowed to keep compounding a hole even after the player responds
  well**, as long as the cause stays legible — there's no guaranteed floor or
  recovery point the design owes the player. But the more extreme or rapid the
  compounding, the more it matters that the originating cause was avoidable in
  principle — a severe spiral should always trace back to a real decision point the
  player could have chosen differently at, not an exposure they had no way to avoid.
- **Normalize before combining unrelated values.** When a formula sums or otherwise
  combines components that represent genuinely different *kinds* of quantities —
  not just repeated instances of the same kind — each component must be normalized
  to a comparable scale first. Summing raw, differently-scaled values lets whichever
  happens to have the larger natural range dominate the result arbitrarily, for
  reasons that have nothing to do with actual relative importance.

  This does not apply to combining multiple instances of the *same* kind of
  quantity (e.g. summing `sqrt` of four different nutrient axes in the Food
  Security score — all four are the same kind of thing, already sharing a
  flattening treatment, so no additional cross-normalization is needed). It applies
  specifically when combining across categories — e.g. a raw resource stockpile
  total, a count of achievement points, and an average income rate are three
  different *kinds* of numbers with no inherent shared scale, so each must be
  normalized before being added into a single score (see [SEED Factions](06_planets_and_scoring.md#seed-factions)' Development
  Bloc in [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions) for a worked example).
- **Design docs describe the current design, not its history — or its
  speculative future.** Content in the numbered design files (Story & World
  through Roadmap) should read as if the described mechanic always existed
  this way and exists only as currently designed. Two symmetric directions
  this rules out:

  - **No backward-looking narration.** No "originally X, but this was changed
    to Y because..." asides, no rename footnotes ("Leather Backpack, renamed
    from Large Backpack"), no design-process narration ("designed by working
    backward from what fabrication needs to consume"). That kind of content
    doesn't help a reader understand the *current* system, and it goes stale
    the moment the design changes again, unlike a plain description of how
    something presently works.
  - **No forward-looking speculation.** A late-game payoff, lore hook, or
    not-yet-designed tier belongs in `DESIGN_TODO.md`'s Newly Surfaced Ideas,
    not folded into the spec for the thing that exists today (e.g. a
    building's eventual, undesigned upgrade tier).

  `DESIGN_TODO.md` is the deliberate exception on both ends — it exists
  specifically to track what changed, why, and what's still open, and should
  keep doing exactly that.

  This doesn't forbid rationale for a current design choice — a choice that
  would otherwise look wrong or invite a plausible rewrite gets to keep its
  "why." The bar: omitting the rationale must risk a genuinely **more
  natural** alternative resurfacing, not merely *an* alternative existing in
  the abstract. ("Random Energy-shedding instead of player-set priority"
  clears this bar, since player-set priority is the more natural first idea a
  reader would reach for. "This building was considered as several
  specialized buildings before being consolidated into one" does not — that a
  different structure is *possible* isn't enough to earn a footnote defending
  against it.)

- **State every fact exactly once, owned by whichever place is the natural
  authority on it — everywhere else references it.** This is the same
  discipline behind moving balancing values into `data/*.csv` (see
  `data/schema.csv`), applied to prose and content generally:

  - An item/resource's own entry states only its identity and source. A fact
    that's really about a *different* entity belongs at that entity's entry,
    not repeated here (Leather's entry doesn't need to explain Pelts' other
    uses).
  - A fact that already follows from an established pattern, a recipe's own
    notation, or something directly observable in the data doesn't need
    restating in prose (Lumber's universality is visible by inspecting
    `data/building_construction_costs.csv`; "`Leather` ← Pelts (tanning)"
    already implies Leather is pelts' usable refined form — no need to say so
    again).
  - **A bare pointer to a data sheet that carries no per-instance
    specificity belongs at the property's own definition, stated once — not
    repeated at every entry that has the property.** If a schema-level
    definition already says a property's values live in `data/foo.csv`
    (e.g. Building Schema's Universal properties list already says
    Construction cost's ratios are in `data/building_construction_costs.csv`),
    a per-building "Construction cost: see `data/building_construction_costs.csv`"
    with nothing else attached adds nothing beyond confirming that this
    building has the property every building has — the reader already knew
    that. Keep a per-instance pointer only when it's paired with something
    that actually varies per instance (a specific row/ID to look up, a
    notable exception, an additional-material callout) — the specificity is
    what earns the repetition, not the pointer itself.
  - Actual game content — specific values, names, or flavor text meant to
    appear in the finished game, not illustrative examples for the reader —
    belongs in a `data/*.csv` sheet with a reference from the doc, the same
    as a numeric balancing value (e.g. Kitchen's combo-meal flavor-name
    variants live in `data/kitchen_combo_flavor_names.csv`, not as an inline
    list).
  - An open question tracked in `DESIGN_TODO.md` gets referenced by name from
    the doc, never re-summarized inline — the inline summary and the tracked
    item drift out of sync the moment one changes without the other.
  - A cross-reference to another mechanic ("same placement pattern as
    Mine/Quarry/Well," "reusing the existing `TrueRisk(Bio-hazard)`
    correlation rather than a new per-planet dial") earns its place only when
    it stands in for an explanation that would otherwise have to be repeated.
    If it's merely noting a resemblance without saving any actual
    re-explanation, cut it.

  Riders on what counts as redundancy here:
  - **Redundancy within a single passage is worse than redundancy across
    sections**, since there's no cross-referencing excuse for it at all —
    e.g. restating "no separate build choice," then "no... upgrade action,"
    then "not a player decision beyond choosing where to build" for the same
    fact in one sentence. Tighten to state it once.
  - **Omission implies absence for a property every entry either has or
    doesn't — never state the absence explicitly.** A building's Upgrade
    path is either described (what the upgrade does) or simply not
    mentioned at all; "No upgrade path" / "Upgrade path: none" is never
    written out, since a reader who sees no upgrade described already knows
    there isn't one. Watch for this shape wherever a property is
    conventionally always addressed one way or the other — the convention
    of *always* stating a value, including "none," is itself worth
    reconsidering rather than assuming it must stay just because it's
    already how the rest of the document does it. An existing pattern
    earns its place in a restructuring pass on its own merits, not because
    it's already the pattern.
  - **A short "not applicable" marker in a structured, templated listing is
    not exempt from the rule above either — drop it.** A building entry
    ending with `Area of effect / Energy upkeep / Preparedness / ...: N/A`
    looks like it's confirming every conditional property was checked, but
    since applicable properties are already given their own bullet wherever
    they actually apply, the entries that lack one already tell a reader
    the property doesn't apply — the trailing marker adds nothing beyond
    what that omission already says, just condensed into one line. Not
    needed in design documents.
