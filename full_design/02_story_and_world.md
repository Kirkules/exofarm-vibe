# Story & World

## Run Structure (Roguelike)

- Each run is a **fresh start** on a new exoplanet.
- Runs last a maximum of **15 seasons** (working value; may vary by planet type and will
  be tuned after playtesting).
- A run ends early on **critical failure**: total farm destruction, settler starvation,
  or similar catastrophic events.
- A successful run ends with a **score** representing quality of life, resource richness,
  safety, settler happiness, and other factors — functioning as a "viability report" for
  humanity's potential colonization of that planet.

---

## Meta-Progression & Earth Hub

The Earth hub is the persistent home base between runs. It represents humanity's
growing body of knowledge from all completed expeditions.

### Design Catalog
- Earth already knows how to make everything — settlers arrive with **blueprints for all
  known designs**. What limits them is access to the required **planet-side materials**.
- As the game progresses across multiple runs, the catalog **grows**: discovering and
  gathering enough of a previously-unseen resource type during a run prompts Earth's
  designers to develop new designs using that material, unlocking them for future runs.
- This is the primary meta-progression mechanic: **resource discovery → new designs
  unlocked.**
- Story framing: Earth didn't have reason or opportunity to develop these designs before.
  The expedition's discovery creates the impetus.

### Earth Hub Contents
- **Design browser** — all known buildings/conversions, organized by category;
  reflects current meta-progression unlocks
- **Exoplanet catalog** — available planet types with their conditions and features;
  used to choose the next run (or opt into random selection)
- **Run history** — summary of past runs: planet visited, score, key outcomes
- **Start run** — launch into a new expedition

*Backstory and lore moved to [Background Story & Gameplay-Story Integration](02_story_and_world.md#background-story--gameplay-story-integration) below.*

**Phase 5+ addition:** A hub mini-game for scanning/searching for exoplanets with
specific property combinations. More favorable target = harder mini-game, sometimes
impossible.

---

## Background Story & Gameplay-Story Integration

### Backstory

**The Crash Research Era.** Within living memory — recent enough that people alive
today remember at least its final years — humanity underwent a short, extraordinarily
compressed period of technological breakthrough. Four fields advanced concurrently and
fed into each other: high-efficiency energy production (a controlled-fusion
breakthrough), artificial intelligence (which accelerated research across the other
three fields), force-field/shielding technology (developed to protect orbiting ship
factories from debris and sublight spacecraft from destruction by low-density
interstellar particles at high speed), and finally, faster-than-light travel itself.

The era's industrial buildout — not FTL travel itself — is what pushed Earth's climate
past the point of recovery on any timeframe that matters to living humanity. It was
reckless progress, driven by competition and urgency rather than care, and by the time
FTL was achieved, the damage was done: Earth would remain habitable for perhaps a few
more centuries, but rehabilitation was no longer viable. Finding an already-suitable
world became the only way forward.

SEED was founded *before* FTL was even achieved — an aspirational organization built on
the belief that emigration would eventually become possible, long before it was. Some
of its current leadership were once anti-industrial climate activists who opposed the
very research boom that caused the crisis; when FTL emerged as an unexpected byproduct
of that same reckless era, they redirected their energy from protest into building the
way out.

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
(a meta-progression axis to note for later; see Technology & Progression) raises how
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
distinct systems (see "Seed-Ships" below), rather than something future meta-progression
could ever unify.

Once a wormhole collapses, re-establishing a *direct* connection between that same
specific pair of regions again is dangerous or impossible — as far as anyone knows,
permanently. This lockout is specific to that exact pair: a new wormhole is entirely
unaffected as long as it isn't the same two regions (Earth can freely open a fresh link
to a different destination, or a third region can link to either side of an
already-collapsed pair).

Communication signals (information/energy, effectively massless) don't count
meaningfully against the mass threshold, and a collapsed wormhole leaves behind a
lingering trace that permits ongoing FTL communication between the same two regions —
lasting exactly as long as the lockout does (permanently, as far as anyone knows). This
is why a settlement can maintain contact with Earth throughout a run even though the
physical route that brought them there is spent: the same event that severs the
possibility of an easy return or reinforcement is what guarantees they're never truly
cut off from contact.

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
doesn't destroy the filament; it re-stabilizes it permanently, already "paid for" by
the process of having gone through it once. This re-stabilized filament is the same
structure that carries the ongoing FTL communication trace described above — one
object across its whole lifecycle: a pre-expedition scanning tool, briefly upgraded
into a one-time transit wormhole, then permanently returned to service as a
communication-only channel.

This gives the Phase 5+ hub scanning minigame a concrete in-fiction basis: it
dramatizes choosing which limited filament slots are worth the energy to search, with
more favorable or distant targets presumably costing more to detect or being harder to
lock onto.

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
successful destinations, and what (if anything) can still be done about Earth's own
decline — reversing the climate is all but impossible with any foreseeable technology,
but opinion is divided between those who accept that and those who still hope to
overcome it.

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
settlement via the same permanent FTL trace left by the settlement's original wormhole
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
mostly optional, consistent with the minimal-UI-interaction principle. Content is
mixed: Earth/SEED political and world-state flavor, exploration task outcomes and
Mission Report content framed in the Herald's own voice (a report the player-character
is filing, not neutral narrator text), and — importantly — diegetically-framed game
hints and advance warnings of planet-side hazards (e.g. incoming weather). This last
point resolves the still-open "no purely ambient, untriggered randomness should end a
run" design principle for any future weather/disaster mechanic: a transmission
telegraphs the hazard in advance, turning what would otherwise be an ambush into a
legible, prepare-or-don't risk.

**Settler story presence.** Kept deliberately minimal for now: a short personnel-file
style blurb when a settler first appears (consistent with the prestigious/competitive
selection process established in Background Story), and a single acknowledgment line
in the log/report on death. No ongoing dialogue or barks during simulation.

**SEED Bulletin (hub, between runs).** A hub panel — not a voiced character — showing
a periodic state-of-affairs summary: Earth-politics flavor (seed-ship seat allocation
debate, climate-reversal hope vs. acceptance), possible meta-progression direction
hints, and seed-ship development news. This is the natural home for the flagged
"a past colony receives a seed-ship" mechanic to surface, including the planet's
community-chosen name (see "Planet Naming" above) and any associated resource
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
- A. ~~Mechanism of FTL travel, and why it caused climate collapse~~ — **resolved**,
  see "The Crash Research Era" and "Faster-Than-Light Travel" above.
- B. ~~State of Earth society right now~~ — **resolved**, see "Seed-Ships" above:
  SEED is an ISS-partnership-style multilateral coalition (not a unified world
  government), the dominant program operating from Earth because an effort at this
  scale is too hard for a smaller/unilateral actor. Day-to-day life on Earth continues
  much as before; politics centers on seed-ship seat allocation and disagreement over
  whether reversing the climate is worth continuing to pursue. A hinted rival program
  based elsewhere in the solar system (not Earth) is intentionally parked as a future
  hook, not developed further for now.
- C. ~~Communication lag with Earth during a run~~ — **resolved**, see
  "Faster-Than-Light Travel" above (ongoing FTL comms via the collapsed-wormhole
  trace, effectively permanent).

**SEED as an institution**
- D. ~~SEED's internal culture and structure~~ — **resolved**, see "SEED's Culture,
  and the Player's Role" above: bureaucratic institutional shell, scrappy
  mission-first culture in the dispatching arm; concurrent expedition count left
  deliberately soft/unresolved. This is also where the player-AI orchestrator reveal
  lives — the player's role, the humanoid avatar, and why the game's viewpoint is
  detached/season-scale rather than first-person.
- E. ~~What "success" leads to~~ — **resolved**, see "Seed-Ships" above: a high
  viability report is what a future seed-ship's destination gets chosen from; the
  actual voyage/outcome happens off-screen from the player's perspective.
- F. **What "failure" means in-fiction** — **substantially addressed**, see
  "Seed-Ships" above: a critical-failure run isn't a wasted data point, just a
  lower-confidence (or near-zero, for total colony loss) result that factors into who
  would accept that destination. Still open: how SEED's internal culture *feels*
  about a loss at the human/institutional level, separate from the data-point framing
  (note: per the "forgiving of individual mistakes" design principle, run outcomes are
  forgiven at the run-to-run level regardless — this remaining piece is about
  in-fiction institutional culture, not a mechanical question).

**The planets and life on them**
- G. ~~Origin of native flora/fauna, and whether sentient life ever appears~~ —
  **resolved**, see "Life on Other Worlds" above: non-sentient flora/fauna are
  common; genuine sentient life is an exceedingly rare wildcard, not a standing
  gameplay pillar.
- H. ~~How planets get selected/discovered~~ — **resolved**, see "Filaments and
  Exoplanet Discovery" above: energy-limited filament stabilization is both the
  discovery mechanism and the in-fiction basis for the Phase 5+ scanning minigame.

**The settlers themselves**
- I. **Who becomes a settler, and why** — **substantially addressed**, see "SEED's
  Culture, and the Player's Role" above: settler selection is prestigious and highly
  competitive (astronaut-or-better status), reinforcing "pioneering optimism, not
  desperate survival." Still open: any individual settler backstory/motivation
  detail beyond this general framing.
- J. ~~What settlers know going in~~ — **resolved**: settlers are informed,
  competitive volunteers, not naive or coerced (per I, and Earth's open political
  debate over the climate/seed-ship situation). No single dominant emotional
  tenor (duty, wonder, personal reinvention, etc.) is defined at the story level —
  motivations are left to vary per settler, with potential to surface later as a way
  to differentiate individual settlers, if that turns out to be fun (consistent with
  the Settlers section's current "no individual gameplay mechanics" stance being a
  starting point, not a permanent constraint).
