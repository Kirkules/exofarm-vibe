# Story & World

## Run Structure (Roguelike)

- Each run is a **fresh start** on a new exoplanet.
- Runs last a maximum of **15 seasons** (working value; may vary by planet type and will
  be tuned after playtesting).
- **A run ends when the communication trace finishes collapsing** and Earth
  loses contact — not when the expedition ends. The settlement carries on;
  the player, orchestrating from Earth, simply can't see or reach it any
  more. No in-fiction figure is ever put on how long a trace lasts.
- A run ends early on **critical failure**: total farm destruction, settler starvation,
  or similar catastrophic events.
- A successful run ends with a **score** representing quality of life, resource richness,
  safety, settler happiness, and other factors — functioning as a "viability report" for
  humanity's potential colonization of that planet.

---

## Meta-Progression & Earth Hub

The Earth hub is the persistent home base between runs. It represents humanity's
growing body of knowledge from all completed expeditions.

### Meta-Progression

**Meta-progression** is any cross-run change to the game outside of run history
— a permanent shift to what a future run starts with, contains, or can reach.
It runs on one mechanism: **Favor** earned with the five SEED factions, spent
on **Initiatives** in those factions' trees.

**Within a run, nothing about it changes.** Settlers arrive with
**blueprints for all known designs**, and what limits them is access to the
required **planet-side materials**, not knowledge — there is no in-run tech
tree, and an Initiative unlocked between runs applies from the next run's
start, never partway through one.

#### Favor

**Favor is political power a faction is willing to spend on your behalf.**
You earn it by raising a faction's standing — an expedition is the whole
world's focus, so aligning one with a faction's ideology is what puts that
faction's politics in the ascendant. Having done so, it will expend some of
that power for you, in proportion to what you've accrued.

**Every completed run pays out to all five factions at once**, each against
its own score (see Planets & Scoring's [SEED Factions](06_planets_and_scoring.md#seed-factions)) — the player
never nominates one. A run's payout with a faction is what its score clears
above a **bar that rises with the Favor already earned from it** (curve: see
`data/misc_balancing_values.csv`'s "Favor" rows).

That diminishing return does two things, and the second is the interesting
one. It makes **neglected factions the cheap ones**, so the meta-game keeps
asking for constituencies you've been ignoring. And it means pulling another
Initiative out of a faction you've already courted requires scoring *higher
with that same faction than you ever have* — which usually means importing
capability from other factions' trees. Breadth is pushed from both ends.

**Favor never decays and never resets.** It accumulates for the life of the
save.

#### Initiatives

Each faction has a tree of **Initiatives** — see `data/faction_initiatives.csv`
and `data/faction_initiative_prerequisites.csv`. An Initiative **spends** that
faction's Favor, permanently. Some additionally require a level of **total
Favor ever earned** with a *second* faction — spent or not — so a
cross-faction Initiative asks whether that faction knows you, not whether
you've kept a balance on hand.

**Initiatives are not all upgrades, by design** — each is one of three kinds:
- **Capability** — content or a way to play that didn't exist before.
  *Illustrative*: Sustenance Bloc moving public opinion far enough that
  insect-derived food is acceptable, opening tiny-animal husbandry.
- **Capacity** — more of a dial the game already has. *Illustrative*:
  Development Bloc funding wormhole-stabilization research, raising the
  Specialization mass budget (see Core Loop & Grid's [Specialization](03_core_loop_and_grid.md#specialization)).
- **Access** — reaching planets or options previously out of range.

A tree made only of Capacity would raise the floor without widening the
game; the three-way split is there to be authored against.

#### Modes

Two cross-run modes. **Favor and Initiatives work identically in both** —
the countdown changes how many runs you get, not how progression works.

- **Story mode** — a countdown measured in **runs remaining** until Ren
  arrives. Scripted cutscenes and **curated planets** (hand-authored
  candidates appearing in the catalog at set points) carry the story.
  **A curated planet never has to be "beaten" for the story to move past
  it** — it's an opportunity, not a gate, so a run that goes badly costs the
  player that opportunity and nothing else.
- **Atemporal mode** — no countdown; runs continue indefinitely. The
  doomsday looms permanently without ever arriving.

Because unlocking is finite in Story mode and eventually exhaustive in
Atemporal, **the order Initiatives are taken in is a real commitment under
the countdown** and merely a preference without it. One mechanism, two
pressures.

**The final run.** When Story mode's countdown reaches zero there is one
last expedition, and it is played differently: **there are no
Transmissions.** The player is no longer directing from Earth, because
Earth is gone — the viewpoint is the expedition's own, the first and only
time the game is played from the settlement's side rather than from the
orchestrator's.

### Earth Hub Contents

The hub landing routes to five screens; it is otherwise independent of a run's
first season and initial settlement state:
- **Exoplanet catalog** — the available candidate planets with their known
  conditions and features; used to choose the next run (or opt into random
  selection), and to reroll the candidate pool. "Start run" launches from here
  once a candidate is chosen.
- **Run history** — summary of past runs: planet visited, score, key outcomes.
- **Initiatives** — the five factions' trees, each Favor balance, and the
  bar each faction's next payout has to clear.
- **Settings** — game-wide settings.
- **Discovered-element codex** — reference detail on game elements the player
  has encountered: how they work, their stats, and so on.

*Backstory and lore moved to [Background Story & Gameplay-Story Integration](02_story_and_world.md#background-story--gameplay-story-integration) below.*

**Phase 5+ addition:** A hub mini-game for scanning/searching for exoplanets with
specific property combinations. More favorable target = harder mini-game, sometimes
impossible.

---

## Background Story & Gameplay-Story Integration

### Backstory

**Ren, the Incoming Star.** Generations before the Crash Research Era, ordinary
astronomical survey work flagged a hypervelocity star on a trajectory that will
eventually bring it catastrophically close to the Sun — a collision, or a near-miss
violent enough to devastate the solar system regardless, with the exact outcome still
narrowing after centuries of continued observation. It is centuries out, but nothing
about it is stoppable: no technology, foreseeable or otherwise, can move a star or
shield a solar system from one. Nobody caused it and nobody can prevent it, which gives
it a very different emotional register from Earth's own climate trouble (see below) —
there is no argument to have about it, no policy that could have averted it, nothing to
regret. It simply is, and it is coming. The game deliberately keeps no explicit account
of how many in-fiction years elapse across a player's own history of runs — Ren's
centuries-long runway means the hub's situation stays effectively the same, imminent
but distant, no matter how long a player keeps playing.

SEED was founded generations before FTL was achieved, directly in response to Ren's
discovery — an aspirational organization built on the belief that emigration would
eventually become possible, long before it actually was. Some of its current leadership
were once anti-industrial climate activists who opposed the reckless research boom that
would later become the Crash Research Era, for reasons that had nothing to do with
Ren; when that same era unexpectedly produced FTL, they recognized the tool SEED had
been waiting for all along and redirected their energy from protest into building the
way out.

The star's original designation was dryly technical — an instrument or survey acronym,
the kind of self-amused in-joke astronomers have always given their equipment, that
happened to spell **WREN**. "The Wren" is what stuck in public use almost immediately,
and across the centuries since, worn down by constant multilingual repetition the way
"influenza" wore down to "the flu," it settled into a single name spoken by everyone
alive: **Ren**. Unlike the deliberately dry, functional-only catalog designations SEED
still uses for candidate exoplanets (see [Filaments and Exoplanet Discovery](02_story_and_world.md#backstory), below),
Ren's name never stayed neutral — it is the single most spoken, most personally
significant word in human language.

Much of that weight traces to an old, unrelated folk tale: across a wide swath of
European tradition, the wren becomes "king of all birds" not through size or strength,
but by hiding, unnoticed, on the eagle's back during a contest for who can fly highest,
and popping up at the last possible moment to claim the win. Whether the astronomers
who wrote the backronym had that story in mind or stumbled into it by accident, it's
the story humanity settled on once the name did: not size or strength, but the small
and the clever, prevailing over the vast, at the last possible moment. Religious and
quasi-religious movements have grown up around Ren in the generations since, with no
single dominant interpretation. One significant thread, an offshoot within Hindu
tradition, holds Ren to be an incarnation of Shiva — destruction as the necessary
clearing-away that makes new, untainted creation possible, with SEED's expeditions cast
as a literal act of that renewal. It is one voice among several, not an official SEED
position, and not something the game treats as settled fact any more than any other
in-fiction belief.

**The Crash Research Era.** Within living memory — recent enough that people alive
today remember at least its final years — humanity underwent a short, extraordinarily
compressed period of technological breakthrough. Four fields advanced concurrently and
fed into each other: high-efficiency energy production (a controlled-fusion
breakthrough), artificial intelligence (which accelerated research across the other
three fields), force-field/shielding technology (developed to protect orbiting ship
factories from debris and sublight spacecraft from destruction by low-density
interstellar particles at high speed), and finally, faster-than-light travel itself.

The era's industrial buildout made an already-serious problem worse: irreversible
climate change had been a real, worsening crisis for generations before the era even
began, not something the era invented from nothing. Reckless, competition-driven
progress accelerated the damage further, and by the time FTL was achieved, few
scientists thought full reversal was realistic any longer. Earth remains habitable, and
mitigation efforts continue, but this is a real, ongoing, self-inflicted cost the era
made worse — and Earth's politics still argue about it (see [Seed-Ships](02_story_and_world.md#backstory), below). It
isn't why SEED exists, though; that reason predates the era entirely (see [Ren, the
Incoming Star](02_story_and_world.md#backstory), above).

Shielding technology, no longer needed to protect FTL-capable ships (which bypass the
normal-space hazards of sublight travel entirely), found a second life in agriculture:
the weather protection domes used on exoplanet settlements today are directly descended
from this era's ship-shielding breakthroughs.

AI remains an active tool rather than a relic of that era — it continues to accelerate
Earth's design pipeline (why a newly-discovered resource can become a usable catalog
design within a workable timeframe) and, in the field, drives the autonomous drones
settlers rely on.

**Faster-Than-Light Travel.** FTL travel is wormhole-based, not a literal violation of
light-speed within normal space. A wormhole connects two specific regions of space
(each roughly the scale of an asteroid belt's radius) and permits mass to pass between
them.

Passing a sufficient amount of mass through a wormhole destabilizes and collapses it.
The exact threshold is a function of stabilization technology — better stabilization
(a meta-progression axis to note for later; see [Technology & Progression](03_core_loop_and_grid.md#technology--progression)) raises how
much mass can pass through before collapse, which is why a run's starting expedition
footprint is small: it's constrained by the mass threshold current stabilization tech
allows, not merely by cost.

There is no hard mass cap in principle — any threshold can theoretically be created —
but the energy required to create and stabilize a wormhole scales drastically (worse
than exponentially) with the mass it needs to carry. Transporting a colonization-scale
population and its life-support infrastructure would require energy beyond anything
producible (more than a star outputs), so wormhole mass-transit at that scale isn't a
matter of "not invented yet" — it's foreclosed for any foreseeable technology. This is
why large-scale human migration and wormhole-based scouting remain two permanently
distinct systems (see "[Seed-Ships](02_story_and_world.md#backstory)" below), rather than something future meta-progression
could ever unify.

Once a wormhole collapses, re-establishing a *direct* connection between that same
specific pair of regions again is dangerous or impossible — as far as anyone knows,
permanently. This lockout is specific to that exact pair: a new wormhole is entirely
unaffected as long as it isn't the same two regions (Earth can freely open a fresh link
to a different destination, or a third region can link to either side of an
already-collapsed pair). See [The Kiran Incident](02_story_and_world.md#backstory), below, for how this was first
discovered.

Communication signals (information/energy, effectively massless) don't count
meaningfully against the mass threshold, and a collapsed wormhole leaves behind a
lingering trace that permits ongoing FTL communication between the same two regions.
This is why a settlement can maintain contact with Earth after the physical route
that brought them there is spent.

**The trace is not permanent — the lockout is.** Without a mass-wormhole
alongside it to hold it open, a trace carries only electromagnetism and
destabilizes on its own; it simply takes far longer to finish collapsing
than the transit wormhole did. When it does, contact ends for good, and the
lockout rule guarantees nothing can ever be opened along that path again.
That combination is the cruel one: an expedition can never be returned to,
and eventually can't even be spoken to. **How long a trace lasts is never
quantified in-fiction** — it is known to be finite and roughly predictable,
never to the season.

Together, these rules make SEED's expansion inherently outward-facing: reinforcing or
returning to an already-reached planet via its original direct route is never possible
again, so the institutional strategy is always to keep reaching toward fresh
destinations — a physical fact underlying "there is always another planet to explore."

**Filaments and Exoplanet Discovery.** Wormhole creation requires the presence of a
star near each endpoint. Before any transit-capable wormhole is attempted, a cheaper
proto-connection called a *filament* can be stabilized toward a candidate star
system — this is the actual mechanism behind exoplanet discovery, allowing remote
detection of a system's contents (planets, composition, and other properties) from
Sol, well beyond what ordinary telescopy alone could resolve.

Maintaining a stabilized filament costs energy on an ongoing basis, so only a limited
number can be kept active at once. This is why only a handful of candidate expeditions
are ever available to choose from at a time in the Earth hub's exoplanet catalog, and
why an unclaimed candidate has a shelf life — if a filament isn't committed to an
actual expedition within some window, it's dropped to free capacity for a new
candidate elsewhere (nothing is lost at this stage; no expedition has happened yet).
This cost has no direct effect on the player's own in-run resource economy — its only
gameplay effect is to gate the number of currently-available planet choices and put a
soft time limit on rerolling them, keeping this mechanic simple rather than adding a
second resource-management layer.

When SEED commits to an actual crewed expedition, the filament is upgraded into a full
transit-capable wormhole (subject to the mass threshold described above) — the
connection that eventually collapses once the expedition passes through. The collapse
doesn't destroy the filament; it re-stabilizes it, already "paid for" by
the process of having gone through it once. This re-stabilized filament is the same
structure that carries the ongoing FTL communication trace described above — one
object across its whole lifecycle: a pre-expedition scanning tool, briefly upgraded
into a one-time transit wormhole, then returned to service as a
communication-only channel until it finishes collapsing.

This gives the Phase 5+ hub scanning minigame a concrete in-fiction basis: it
dramatizes choosing which limited filament slots are worth the energy to search, with
more favorable or distant targets presumably costing more to detect or being harder to
lock onto.

**The Kiran Incident.** The very first filament ever upgraded into a full
transit-capable wormhole was not, strictly speaking, planned to end well.
The *Halcyon Survey* — a mid-size crewed science vessel outfitted with the
era's full suite of measurement instruments — was commissioned to observe
and record the landmark first transit, captained by Naveen Kiran. As the
wormhole opened, the ship was drawn in by a gravitational pull stronger
than anticipated; smaller, higher-thrust escape pods could break away in
time, but the science vessel itself could not. Kiran ordered her crew to
evacuate and remained aboard alone, taking last measurements as the ship
continued toward the threshold. She lost her own window to escape, and the
*Halcyon Survey* — with her aboard — was pulled through as the wormhole
collapsed behind it.

From Sol's side, this looked like a straightforward, catastrophic loss:
ship and captain gone, wormhole collapsed. Then, days later, ordinary FTL
communications arrived from the direction of the collapsed wormhole's ring
structure. This is how humanity first discovered that a collapsed wormhole
leaves behind a lingering, communication-capable trace — the filament,
re-stabilized in its post-transit form.

Sol's engineers spent months trying to re-open a direct transit connection
to reach her, and failed — this is how humanity first learned that a
collapsed pair can never be directly reconnected: the very filament now
carrying her voice back was precisely what stood in the way of forming a
new transit wormhole along that same path. Once Kiran accepted she wasn't
coming home, she turned the connection into a research asset instead of a
lifeline, spending her remaining time helping Sol characterize the system
she was stranded in — and eventually crash-landed the *Halcyon Survey*, its
scientific payload substantially salvaged, on the system's single verdant
world.

She survived there for several years, sending back an extraordinary volume
of data: atmospheric and weather readings, biological samples, and hours of
footage — herself climbing mountains and descending into cave systems,
small native creatures studied up close, larger ones observed from a
cautious distance. She died of an infection contracted on the planet, still
transmitting to the end. Her system remains permanently unreachable, per
the same lockout rule her death first proved — no expedition has ever
followed her, or ever will.

Naveen Kiran is, by any reasonable account, the first human being to ever
set foot on another world. See [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)' [SEED Factions](06_planets_and_scoring.md#seed-factions) for how
her name lives on.

**Seed-Ships.** Following a successful expedition, if a planet's viability is high
enough, SEED may eventually dispatch a "seed-ship" toward it — not a wormhole transit
(a colonization-scale population and its life-support systems represent far more mass
than wormhole transit could ever practically carry; see above), but a slow, sublight
generation ship: crews travel via long-term cryogenic stasis, or as a living,
generations-spanning colony aboard the ship itself, arriving decades or centuries
later. This is the actual mechanism by which large numbers of people eventually leave a
dying Earth.

This is also why expeditions continue even after a first viable planet is found: a
seed-ship's voyage is an irreversible, once-in-a-lifetime commitment, and not everyone
requires the same strength of guarantee before accepting it. SEED continues scouting a
portfolio of candidate planets at varying confidence levels, over time matched to the
risk tolerance of those willing to go — some are satisfied with a merely
conceivably-suitable destination, others hold out for stronger evidence.

This gives the end-of-run **viability report** its concrete in-fiction meaning: it is
literally an estimate of the likelihood that a full-scale, long-term human civilization
could be successfully established on that planet. An ExoFarm expedition is simultaneously
a test case (can humans farm and live here at all?) and direct preparatory groundwork
for a future seed-ship, should one ultimately be sent. Whether a seed-ship is actually
dispatched, and what becomes of it, happens off-screen from the player's perspective —
the game's job is producing the report, not depicting the multi-generational voyage
that may follow it. A run that ends in critical failure isn't necessarily a wasted
data point either — it's simply a lower-confidence (or near-zero, in the case of total
colony loss) result, which factors into who, if anyone, would accept that destination.

Back on Earth, this is also the central axis of day-to-day politics: for most people,
life continues much as it always has — the economy still exists to keep people fed and
housed, and to fund both SEED and a scattering of private startups attempting similar
efforts. What dominates public debate is who gets a seat on the seed-ships bound for
successful destinations, and — a separate, still-unresolved argument — whether
continuing to invest in climate mitigation is worth it, given Earth has centuries of
habitability left regardless of how Ren eventually resolves. Full reversal is all but
impossible with any foreseeable technology, but opinion is divided between those who
think mitigation still matters for however long Earth remains home, and those who'd
rather redirect those resources toward seed-ship capacity instead. The game doesn't
take a side in this any more than it resolves what Ren actually means.

**Planet Naming.** At filament-scan discovery, a candidate planet receives only a
systematic catalog designation — functional, not evocative (a star-system ID plus
planet letter, in the spirit of real exoplanet naming). This is the only name a planet
has throughout an ExoFarm expedition and for the whole of a typical run; the game does
not give the player an opportunity to rename it. A planet only receives a real,
evocative name once an actual seed-ship is dispatched to it, and even then the name
isn't chosen by SEED or by the player-AI — it's chosen by the community aboard the
seed-ship itself, the people who will actually live there, naming their own future
home. In practice this makes a "real" name a rare, delayed, off-screen reward: most
planets the player ever plays through remain known only by their catalog designation
for the entire run.

**SEED's Culture, and the Player's Role.** SEED itself is largely a bureaucratic
body — an intergovernmental coalition (see above) with the funding committees,
treaties, and process-heavy machinery that implies. But the expedition-dispatching arm
operates with a much scrappier, mission-first culture, insulated somewhat from the
larger bureaucracy above it. Becoming a settler is one of the most prestigious
achievements a person can pursue on Earth — comparable to becoming an astronaut today,
if not more so — and settlers are drawn from a highly selective, competitive pool, not
desperate volunteers with no better option.

The player takes on the role of an AI orchestration intelligence — a distinct entity
from the autonomous drone-intelligences also used in the field (which are individual,
on-board systems in their own right, not extensions of the player). The player-AI is
based on/around Earth and directs an expedition remotely, communicating with the
settlement via the same FTL trace left by the settlement's original wormhole
transit. This is why the game's viewpoint is abstract and detached rather than
first-person, and why entire seasons can play out at a glance: the player is not
physically present, and operates at the level of planning and direction, not direct
control. During the simulation phase, the settlement's own settlers and
drone-intelligences carry out the plan autonomously — the player-AI has no more ability
to directly puppet a drone mid-season than to personally lay a brick.

Settlers are aware they are directed by an AI; this is not hidden. The player-AI takes
on a humanoid-robot avatar and is otherwise treated much like a highly capable human
colleague in-fiction — not alien, unsettling, or sterile. The player names their own AI
character as part of the game's introduction/tutorialization. This human-AI dynamic
exists but is intentionally kept low-key rather than a major thematic focus, absent a
compelling reason to foreground it later.

The player-AI's formal class designation is **Herald** — chosen for its double
meaning: a Herald both reports findings back to Earth (the AI's actual function) and,
in-fiction, an ExoFarm expedition itself heralds whether a future seed-ship should
follow. "Herald" functions as a title prefixed to the player-chosen name (e.g. "Herald
John"), giving the custom-named AI character a natural full title from the moment the
player picks a name during tutorialization.

How many expeditions SEED runs concurrently at any given time is left deliberately
soft/unresolved in the fiction — the player only ever experiences their own single
ongoing expedition at a time.

The player-AI is **persistent across runs** — the same character, under the name the
player gave it, carries a career across every expedition the player ever undertakes.
This gives the Earth hub a personal throughline distinct from SEED-the-institution
persisting: each run is a fresh planet, but not a fresh protagonist. A colony that
survives to a run's end is simply preserved as a record in the hub's run history —
what becomes of those settlers afterward (including whether/when a seed-ship
eventually reaches them) is not something the game depicts. A possible future
mechanic, not yet committed to: a past colony later receiving a seed-ship could grant
SEED some resource/financial windfall the player is able to allocate toward
meta-progression, alongside the planet finally receiving its real name (see "Planet
Naming" below) — flagged here for the Backend/meta-progression content pass rather
than resolved now.

**Life on Other Worlds.** Non-sentient native flora exists on many hospitable
planets, independently evolved rather than seeded by humanity — the basis of the
Local Agriculture path's crop hybridization. Non-sentient fauna can exist too, on the
planets where conditions support it, offering a native analog to animal-based
agriculture alongside (or instead of) Earth-imported livestock.

Genuine sentient life is an exceedingly rare wildcard rather than a standing feature
of the setting — the overwhelming majority of planets have no intelligence to
encounter at all. On the rare planet or exceptional exploration outcome where it
exists, it's treated as an extraordinary, awe-inducing exception, not a gameplay
pillar to design around. Humanity (and SEED, culturally) has always wondered and
speculated about the possibility, the way people always have — a background fact
about how people think, not an active operational expectation for most expeditions.

The game is not about terraforming — it is about finding a planet already suitable
enough for human life. Each run's viability report score is a direct contribution to
that search.

> Organizing body: **SEED** — Survival and Emigration Expedition Dispatch.

### Gameplay-Story Integration

**Transmissions (in-run).** A "Transmissions" record, accessible via a mail-evoking
icon in the HUD, collects messages received over the FTL communication trace across
the whole run (persistent, unlike the per-season simulation log). Reviewing it is
mostly optional, consistent with the minimal-UI-interaction principle. Each
entry leads with a **category glyph** (per the shared status-cue vocabulary
— see Production & Technical's [Art Design](07_production_and_technical.md#art-design)), since a run's worth of
accumulated transmissions is otherwise too much to re-parse each season to
find the one that matters. Content is
mixed: Earth/SEED political and world-state flavor, exploration task outcomes and
Mission Report content framed in the Herald's own voice (a report the player-character
is filing, not neutral narrator text), and — importantly — diegetically-framed game
hints and advance warnings of planet-side hazards (e.g. incoming weather). This last
point resolves the still-open "no purely ambient, untriggered randomness should end a
run" design principle for any future weather/disaster mechanic: a transmission
telegraphs the hazard in advance, turning what would otherwise be an ambush into a
legible, prepare-or-don't risk. **Now concretely realized** — see Planets & Scoring's
[In-Simulation Hazard Events](06_planets_and_scoring.md#in-simulation-hazard-events) for the full mechanism (the one-time SEED summary
transmission, and per-season telegraphing that scales with `Confidence(hazard)`).

**Settler story presence.** Kept deliberately minimal for now: a short personnel-file
style blurb when a settler first appears (consistent with the prestigious/competitive
selection process established in Background Story), and a single acknowledgment line
in the log/report on death. No ongoing dialogue or barks during simulation.

**Narrative-Only Flavor.** A running list of settler-related content that is
pure fiction with zero mechanical effect, kept separate from anything in
Settlers & Exploration's Settler State so it's never mistaken for a system
that needs balancing:
- The personnel-file blurb and death-acknowledgment line above.
- **Relationships** — settlers may form an exclusive-pair romantic
  relationship with each other, arbitrarily/randomly from the player's
  perspective, surfaced via a Transmission noting two settlers have paired
  up. No gameplay effect.

**SEED Bulletin (hub, between runs).** A hub panel — not a voiced character — showing
a periodic state-of-affairs summary: Earth-politics flavor (seed-ship seat allocation
debate, whether continued climate mitigation is still worth it given Ren's deadline),
possible meta-progression direction hints, and seed-ship development news. This is the natural home for the flagged
"a past colony receives a seed-ship" mechanic to surface, including the planet's
community-chosen name (see "[Planet Naming](02_story_and_world.md#backstory)" above) and any associated resource
windfall, once that mechanic is built.

**Per-planet "why this planet" hook.** A "known conditions" flavor blurb generated per
planet *type* (not unique lore per individual planet instance) when it appears as a
filament-scan candidate. A meta-progression unlock could allow deeper scanning through
an already-stabilized filament for more detail before committing to an expedition.

**Production scope.** Text-only, illustrated with pixel art; no voice acting. (Note:
the pixel-art commitment itself is flagged for revisiting during the full Art Design
pass, not settled permanently here.)

### Story-World Brainstorm Tracker

World-building explored for its own coherence first, with gameplay implications
surfacing later rather than driving the exploration (per design-process preference).

**The Earth side**
- A. ~~Mechanism of FTL travel, and its relationship to Earth's climate trouble~~ —
  **resolved**, see "[The Crash Research Era](02_story_and_world.md#backstory)" and "[Faster-Than-Light Travel](02_story_and_world.md#backstory)" above: FTL
  is a byproduct of the same reckless research boom that worsened — not caused — an
  already-existing, independent climate crisis.
- B. ~~State of Earth society right now~~ — **resolved**, see "[Seed-Ships](02_story_and_world.md#backstory)" above:
  SEED is an ISS-partnership-style multilateral coalition (not a unified world
  government), the dominant program operating from Earth because an effort at this
  scale is too hard for a smaller/unilateral actor. Day-to-day life on Earth continues
  much as before; politics centers on seed-ship seat allocation and disagreement over
  whether continuing to invest in climate mitigation is worth it, given Ren's deadline
  applies regardless of how that argument resolves. A hinted rival program based
  elsewhere in the solar system (not Earth) is intentionally parked as a future hook,
  not developed further for now.
- C. ~~Communication lag with Earth during a run~~ — **resolved**, see
  "[Faster-Than-Light Travel](02_story_and_world.md#backstory)" above (ongoing FTL comms via the collapsed-wormhole
  trace, lasting until the trace itself finishes collapsing).
- K. ~~Why finding a new world is existentially urgent~~ — **resolved**, see "[Ren, the
  Incoming Star](02_story_and_world.md#backstory)" above: a hypervelocity star, discovered generations before the Crash
  Research Era, on an unmitigable collision-or-near-miss course with the Sun, centuries
  out. Deliberately decoupled from Earth's climate trouble, which stays real and
  present but secondary — SEED's founding and the expeditions' urgency were never
  about escaping a self-inflicted crisis.

**SEED as an institution**
- D. ~~SEED's internal culture and structure~~ — **resolved**, see "[SEED's Culture,
  and the Player's Role](02_story_and_world.md#backstory)" above: bureaucratic institutional shell, scrappy
  mission-first culture in the dispatching arm; concurrent expedition count left
  deliberately soft/unresolved. This is also where the player-AI orchestrator reveal
  lives — the player's role, the humanoid avatar, and why the game's viewpoint is
  detached/season-scale rather than first-person.
- E. ~~What "success" leads to~~ — **resolved**, see "[Seed-Ships](02_story_and_world.md#backstory)" above: a high
  viability report is what a future seed-ship's destination gets chosen from; the
  actual voyage/outcome happens off-screen from the player's perspective.
- F. **What "failure" means in-fiction** — **substantially addressed**, see
  "[Seed-Ships](02_story_and_world.md#backstory)" above: a critical-failure run isn't a wasted data point, just a
  lower-confidence (or near-zero, for total colony loss) result that factors into who
  would accept that destination. Still open: how SEED's internal culture *feels*
  about a loss at the human/institutional level, separate from the data-point framing
  (note: per the "forgiving of individual mistakes" design principle, run outcomes are
  forgiven at the run-to-run level regardless — this remaining piece is about
  in-fiction institutional culture, not a mechanical question).

**The planets and life on them**
- G. ~~Origin of native flora/fauna, and whether sentient life ever appears~~ —
  **resolved**, see "[Life on Other Worlds](02_story_and_world.md#backstory)" above: non-sentient flora/fauna are
  common; genuine sentient life is an exceedingly rare wildcard, not a standing
  gameplay pillar.
- H. ~~How planets get selected/discovered~~ — **resolved**, see "Filaments and
  Exoplanet Discovery" above: energy-limited filament stabilization is both the
  discovery mechanism and the in-fiction basis for the Phase 5+ scanning minigame.

**The settlers themselves**
- I. **Who becomes a settler, and why** — **substantially addressed**, see "[SEED's
  Culture, and the Player's Role](02_story_and_world.md#backstory)" above: settler selection is prestigious and highly
  competitive (astronaut-or-better status), reinforcing "pioneering optimism, not
  desperate survival." Still open: any individual settler backstory/motivation
  detail beyond this general framing.
- J. ~~What settlers know going in~~ — **resolved**: settlers are informed,
  competitive volunteers, not naive or coerced (per I, and Earth's open political
  debate over the climate/seed-ship situation). No single dominant emotional
  tenor (duty, wonder, personal reinvention, etc.) is defined at the story level —
  motivations are left to vary per settler, consistent with the real per-settler
  mechanical differentiation Settlers & Exploration's Settler State now provides
  (Injuries, Aptitude, Experience, `legend_value`).
