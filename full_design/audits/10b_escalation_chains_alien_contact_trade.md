# Audit — System 10b: Escalation Chains, Alien Contact & Trade Agreements

Pure design review against `full_design/`; no implementation exists. Citations
are `file` → "Section" (no anchor links: this file sits in `audits/` and the
repo link-checker only scans `full_design/*.md`).

**Split rationale.** See `10a_exploration_tasks_and_standing_assignments.md` §
"Split rationale". **10b** (this file) covers the multi-step narrative arc a
minority of runs trigger: escalation chains generally, the sentience-contact
chain, First Contact and its three approaches, alien civilization classes,
`ContactRestraint`, alliance deepening, Trade Agreements, and elevated legend
value. The core every-season exploration loop is in 10a.

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Escalation chains — some outcomes (any flavour, incl. neutral) unlock a follow-up option not previously available, guaranteed a pool slot at its next refresh (still discardable by reroll, protectable by lock) | `05` "Escalation Chains" |
| Worked example — neutral fruit-stockpile find on Verdant → seek the gathering animal → alliance → passive zero-staffing food source | `05` "Escalation Chains" |
| Alien civilization classes — rolled from a curated set on Sentience Detection success; five axes: Technology Level, Openness, Economic Stability, Ubiquity (design-time: which planet types it can appear on), Unity (consolidation on its one planet; governs whether confrontation approaches can avoid total failure) | `05` "Escalation Chains" |
| Four classes — Verdant Assembly, Hollow Kilns, Drift Caravans, Frostbound Remnant (full axis table) | `05` "Escalation Chains" |
| Biological Compatibility — deliberately non-mechanical; per-class flavour only, explaining existing contact injury risk | `05` "Escalation Chains" |
| Step 1 — Sentience Detection. Cold from base pool: 8+, 1 Ration, ~10%. Via alien-implying trigger (Abandoned Settlement, Crashed Debris Field, Ancient Irrigation Technique, Recovered Survey Data, Arid Profile-shifting): guaranteed placement, ~30% (first four) / ~60% (Recovered Survey Data). Via Unknown Radio Signal failed-rescue: ~85–90%. Success → `EcologicalData` + guaranteed escalation to step 2 | `05` "Escalation Chains", "Task Catalog" |
| Step 2 — Observe from a distance. Guaranteed escalation, 1 Ration, guaranteed success → elevated `EcologicalData` weight + unlocks First Contact | `05` "Escalation Chains" |
| Step 3 — First Contact. Single guaranteed escalation slot; own UI switches between three approaches before committing a settler, each with its own cost/item/odds/reward | `05` "Escalation Chains" |
| 3a Peaceful Contact — 2 Rations, mandatory Diplomatic Gear, guaranteed attempt / Low-risk → elevated `EcologicalData`; can unlock deepening alliance/trade; base rewards TBD | `05` "Escalation Chains" |
| 3b Bluff/Coercive Exploitation — 2 Rations, mandatory Diplomatic Gear, any class, High-risk; success scales inversely with Technology Level alone; rarely succeeds (> 3c); on success a one-time payout slightly better than an undeepened alliance baseline, no ongoing relationship; odds/rewards TBD | `05` "Escalation Chains" |
| 3c Military Exploitation — 1 Ration, mandatory Armed Expedition Kit + Overwhelming Force Package, any class, High-risk, largest death chance in the catalog; success scales against Technology Level and Unity together, more steeply than 3b; only Primitive-tech low-Unity has appreciable chance; odds/rewards TBD | `05` "Escalation Chains" |
| Step 1 gives every alien-implying trigger a concrete shared target ("starting the sentience-contact chain") | `05` "Escalation Chains" |
| Direct entry to First Contact — successful Unknown Radio Signal rescue skips steps 1–2; all three approaches still available | `05` "Task Catalog", "Escalation Chains" |
| Deepening an alliance — follow-up tasks, Diplomatic Gear each, guaranteed-escalation-slot shape; only reachable once base Peaceful Contact alliance exists; tier count + per-tier rewards TBD; a Trade Agreement is one possible deepening reward, not the only one | `05` "Escalation Chains" |
| Trade Agreements — a deepening task resolving into a trade opportunity surfaces its offer in the task's confirmation dialog; presents 3 candidate agreements (each a fixed expense resource paid by the settlement + income resource from the ally + per-season quantities); pick exactly one, no reroll | `05` "Escalation Chains"; `03` "Season Structure" |
| One-season delay before the first exchange | `05` "Escalation Chains" |
| Ongoing resolution — every season in Post-Sim, sub-step (3.5), right after pooled nutrition, before construction completions; expense present → deducted + income added; absent → agreement ends permanently, dialog-notified, no grace/partial | `05` "Escalation Chains"; `03` "Season Structure" |
| Up to 3 Trade Agreements active at once; a terminated agreement frees its slot (not a lifetime cap of three ever) | `05` "Escalation Chains" |
| Allowed income-resource types — raw/harvested materials + Lumber/Concrete/refined metals; excluded: cooked Meals, Luxury Goods, Fabric/Leather, deep-manufactured goods, Rations. Expense side unrestricted. Energy and Water never tradeable, either side | `05` "Escalation Chains" |
| Local Delicacy's ingredient — a civilization/planet-specific income option; the alliance unlocks the recipe, a Trade Agreement supplies the ingredient | `05` "Escalation Chains"; `04` "Food/Meal Conversion" |
| Elevated legend value — every chain task carries an elevated design-authored legend-value; scales inversely with the actual success probability of the roll that produced the outcome; Peaceful Contact's guaranteed attempt keeps a flat elevated value; stacks with (separate from) the general injury/death Legends bonus | `05` "Escalation Chains", "Risk Spectrum" |
| `ContactRestraint` (Stewardship term) — one discrete per-run value (not cumulative): highest for a successful alliance; small reward for detect-and-leave-uncontacted OR never detecting one; small penalty for contact that never resolves into alliance (attempted-failed or never-pursued); large penalty for choosing Bluff/Coercive or Military at First Contact, for the choice regardless of success; tier values TBD | `06` "SEED Factions" |
| `EcologicalData` (Stewardship term) — shared counter `ν / (ν + k)`, fed by sentience-detection reports + biodiversity survey; the sentience-contact chain contributes "significantly elevated" weight at each step | `06` "SEED Factions", "Data-Gathering Mechanism" |
| Vaccine-unlock region reveal — a building unlock (Medical Bay Vaccine Production) triggering an escalation task to explore the pathogen's origin region, now safe | `05` "Escalation Chains"; `04` "Medical Bay" |

**Boundary notes.**
- Pool mechanics, refresh/reroll/lock, risk spectrum, assignment, the base task
  catalog, and the four Standing Assignments are in **10a**.
- `EcologicalData` / `ContactRestraint` as Stewardship *scoring* live in the SEED
  Factions cross-cutting concern and System 11 (data-gathering mechanism);
  covered here only where the chain feeds them.
- Diplomatic Gear / Armed Expedition Kit / Overwhelming Force Package
  fabrication is System 7; referenced at the prerequisite seam.
- Local Delicacy recipe/consumption is System 8; referenced at the sourcing
  seam.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. Peaceful Contact base alliance reward has no defined shape.**
  "Specific rewards TBD" — but deepening rewards, Trade Agreement availability,
  Local Delicacy sourcing, and the zero-staffing passive-food reward tier all
  hang off it. There is no described reward *shape* beyond "elevated
  `EcologicalData`" and "can unlock deepening." `05` "Escalation Chains".
  *Possible direction: a base alliance grants one immediate zero-staffing
  passive benefit (small ongoing resource trickle or a standing discount),
  drawn from the ally class, with Trade Agreements as a deepening-only
  escalation on top.*
- **G-S2. Deepening tier count and cadence undefined.** "Exact tier count and
  per-tier rewards otherwise TBD." The tier *count* is structural — it sets the
  arc length and how many guaranteed-escalation pool slots the chain generates.
  `DESIGN_TODO.md` mis-tags this as "purely numeric." `05` "Escalation Chains".
- **G-S3. Bluff and Military success curves and rewards undefined.** "Scales
  inversely with Technology Level" / "against Technology Level and Unity
  together, more steeply" give direction and relative steepness but no
  functional form or anchor points; and the rewards depend on the still-
  undefined base alliance reward (G-S1), so they are doubly unpinned. `05`
  "Escalation Chains".
- **G-S4. No rule enforcing "at most one alien civilization per run."** `06`
  "SEED Factions" asserts "a run has at most one such encounter" for
  `ContactRestraint`, but five independent alien-implying triggers + Universal
  Ubiquity + the Unknown Radio Signal path can each reach Sentience Detection.
  The chain description never states a lock after the first success. `05`
  "Escalation Chains"; `06` "SEED Factions".
- **G-S5. Trade Agreement candidate generation is unspecified.** "Three
  candidate agreements, each a fixed pairing … per-season quantities —
  illustrative/TBD." How the 3 are drawn (from ally class? planet type? weighted
  how?) has no algorithm. `05` "Escalation Chains".
- **G-S6. Unresolved chain at run end.** The arc can be mid-step (detection done,
  First Contact not attempted) at season 15. Is a pending guaranteed-escalation
  slot just abandoned, and which `ContactRestraint` tier applies to a mid-arc or
  unfinishable-in-progress chain ("never pursued past initial contact")? `05`
  "Escalation Chains"; `06` "SEED Factions".
- **G-S7. First Contact approach-switch reversibility and reservation
  handling.** The approach UI "lets the player switch between three approaches
  before committing," each pulling different Rations + a different mandatory
  item. Whether the choice is reversible plan-composition (it should be, per
  `01`) and whether reserved items/Rations are released on switch or cancel
  isn't stated. `05` "Escalation Chains".
- **G-S8. "Significantly elevated `EcologicalData` weight"** is unquantified in a
  way that matters — the chain is the main non-survey `EcologicalData` source,
  and "elevated weight" against `ν / (ν + k)`'s one-at-a-time increments needs a
  defined multiplier. Seam with System 11. `05` "Escalation Chains"; `06` "SEED
  Factions".

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** `ContactRestraint` tier values. `06` "SEED Factions";
  `DESIGN_TODO.md`.
- **G-N2.** Bluff / Military exact odds curves and reward amounts; Bluff
  on-success payout magnitude. `05` "Escalation Chains"; `DESIGN_TODO.md`.
- **G-N3.** Overwhelming Force Package exact recipe (placeholder in `04`). `04`
  "Fabrication"; `DESIGN_TODO.md`.
- **G-N4.** Elevated-legend-value inverse-probability formula shape and
  magnitude. `05` "Escalation Chains"; `DESIGN_TODO.md`.
- **G-N5.** Sentience Detection per-trigger success percentages (all
  ~illustrative). `05` "Escalation Chains".
- **G-N6.** Trade Agreement per-candidate resource pairs and quantities;
  deepening per-tier reward values. `05` "Escalation Chains"; `DESIGN_TODO.md`.
- **G-N7.** `EcologicalData` `k` constant. `06` "Data-Gathering Mechanism".

### Cross-check with `DESIGN_TODO.md`

"Alien civilization classes" already lists most numeric TBDs but frames
base-alliance-reward and deepening-tier-count as "purely numeric" — G-S1 and
G-S2 argue both are structural. **Not** flagged at all: unresolved-chain-at-run-
end (G-S6), approach-switch reversibility (G-S7), Trade Agreement candidate
generation (G-S5), single-civilization enforcement (G-S4).

---

## 3. Internal consistency

- **IC1. "At most one such encounter"** (`06` "SEED Factions") vs. five
  independent alien-implying triggers + Universal Ubiquity + the Unknown Radio
  Signal path (`05`). Either add a post-first-success lock or change the scoring
  assumption. (→ G-S4.)
- **IC2. Rescue-then-Military.** A successful Unknown Radio Signal rescue jumps
  to First Contact with all approaches available; the player may then pick
  Military Exploitation against the alien they just rescued, incurring
  `ContactRestraint`'s large penalty "regardless of whether the attempt
  succeeds." Narratively incoherent, mechanically permitted. Likely fine as
  allowed-but-costly; flag so it's a conscious call. `05` "Task Catalog",
  "Escalation Chains"; `06` "SEED Factions".
- **IC3. Elevated legend value "scales inversely with … success probability"**
  but "Observe from a distance" is Guaranteed (p = 1). `05` handles Peaceful
  Contact's guaranteed attempt explicitly ("no probability to scale by … keeps
  its flat elevated value") but not Observe. State that Observe likewise keeps a
  flat value. `05` "Escalation Chains".
- **IC4. Trade Agreement sub-step numbering.** `05` "Escalation Chains" places
  it "right after pooled nutrition consumption, before construction
  completions"; `03` "Season Structure" numbers it "(3.5)." Consistent — verify
  both stay synced if the Post-Sim list is edited.

---

## 4. Cross-system consistency

- **CS1 (→ G-S1). Base alliance reward blocks four downstream things** —
  deepening rewards, Trade Agreement availability, Local Delicacy sourcing (`04`
  "Food/Meal Conversion"), and the zero-staffing passive-food reward tier. Part
  of System 8 and System 4 wait on this. `05` "Escalation Chains".
- **CS2 (→ SF6). Trade Agreement resolution ordering vs. survival priority.**
  `05`/`03` place resolution right after nutrition "so survival needs get first
  claim on any resource an agreement also happens to use (Rations, most
  notably)." Rations are excluded as *income* but the *expense* side is
  unrestricted — so an agreement can demand Rations per season. If Post-Sim
  nutrition just consumed the last Rations, the agreement then fails and ends
  permanently. State whether that's intended. `05` "Escalation Chains"; `03`
  "Season Structure".
- **CS3. `EcologicalData` feed shared with Safeguard's Pathogen Threat.** One
  bio-survey mission generates a Pathogen report (Safeguard) *and* an
  `EcologicalData` increment (Stewardship) (`06` "Data-Gathering Mechanism").
  Confirm the sentience chain steps feed `EcologicalData` *only* (no pathogen
  content) and that "elevated weight" is defined (G-S8).
- **CS4. `ContactRestraint` resolution timing.** Every other Stewardship term is
  cumulative-at-production-time or grid-state-computed; `ContactRestraint` is "a
  single discrete per-run value." Presumably finalised at run end from the final
  contact state — needs an explicit timing statement, and a defined tier for the
  mid-arc case (→ G-S6). `06` "SEED Factions".
- **CS5. First Contact items tie to deep System 7 fabrication.** 3a/3b need
  Diplomatic Gear (further-Upgraded Tinkerer's Workshop); 3c needs Armed
  Expedition Kit + Overwhelming Force Package (further-Upgraded Tinkerer's
  Workshop; OFP recipe is a placeholder). The aggressive approaches are gated
  behind a deep fabrication investment — a real cross-system dependency that
  should be acknowledged as intentional pacing. `05` "Escalation Chains"; `04`
  "Fabrication".
- **CS6 (→ SF5). Guaranteed-escalation slots vs. 10a's pool size 3.** A full
  sentience arc is detection → observe → first contact → deepening ×N → trade —
  potentially 5+ forced pool slots across a run, each displacing a normal
  candidate. A run deep in an alliance arc could have its exploration pool
  dominated by chain steps. Same fix needed as 10a SF2. `05` "Escalation
  Chains".
- **CS7. Vaccine-unlock region reveal** is a System-11 building unlock
  triggering a 10b-style escalation, but it is referenced only as a "worked
  example" with no catalog row. Confirm it uses the guaranteed-slot mechanism
  and author the task. `05` "Escalation Chains"; `04` "Medical Bay".

---

## 5. Story & world consistency

- **Strong fit.** The three First Contact approaches directly realise `01`'s and
  `02`'s difficulty-principle discussion of "aliens obliterating an aggressive
  explorer" as an explicit, knowingly-initiated high-risk choice — `05` calls
  this out. Military Exploitation gated behind Overwhelming Force Package, with
  near-zero success against anything but a Primitive low-Unity class, matches
  `02` "Life on Other Worlds" (sentient life is a rare wildcard, not a resource
  to strip-mine) and the intent that "a few settlers should essentially never be
  able to force anything from an entire civilization."
- `EcologicalData` rewarding confirmed-absent sentience equally with
  confirmed-present fits `02`'s framing that humanity "has always wondered and
  speculated" — the value is in *knowing*.
- **Deliberate restraint worth preserving (→ NTH3).** Biological Compatibility
  as flavour-only is a clean anti-scope-creep choice.
- **Missed / flattened (→ NTH2).** `ContactRestraint`'s "small reward for …
  never detecting one at all" scores a run that never finds aliens the same as
  one that finds them and respectfully withdraws — `02` frames genuine contact
  as "extraordinary, awe-inducing," and the scoring flattens that. Possibly
  intended (don't punish the common case); flag.
- No lore conflicts.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Forgiving of individual mistakes / no ambient run-ending randomness* —
  Military Exploitation's run-ending potential is an explicit, knowingly-
  initiated high-risk choice with a stated largest-death-chance: exactly the
  carve-out `01` allows.
- *Difficulty from breadth of tradeoffs* — First Contact is a genuine
  multi-axis decision (approach, Ration + fabrication cost, `ContactRestraint`
  vs. immediate payoff, settler risk).
- *Normalize before combining* — `ContactRestraint` is one `normalize()` term
  among five in the Stewardship sum.

**Risks / violations:**
- **P1. "Deliberately not something a player can optimize"** (Trade Agreement:
  pick one of 3, no reroll) mirrors the Water-queue / Energy-shedding restraint
  — good. But the 3 candidates being generated by an unspecified algorithm
  (G-S5) means the player can't understand the offer space, brushing `01`
  failure-legibility if a bad agreement later ends and better options were
  unforeseeable. `05` "Escalation Chains"; `01`.
- **P2 (→ SF2). Planning phase is reversible.** First Contact approach selection
  must be reversible plan-composition, with reserved Rations/items returned on
  switch or cancel (G-S7). `01`.
- **P3 (→ SF3). Failure legibility for Bluff/Military.** With odds "rarely
  succeeds" and no shown probability, the approach UI must give at least
  directional feedback (Technology Level / Unity make this harder), per `01`
  "knowing the direction of an effect is enough by default." The approach UI's
  information content isn't specified. `05` "Escalation Chains"; `01`.
- **P4. Numbers stay small.** The chain adds several hidden quantities
  (per-trigger success %, elevated legend-value multipliers, `EcologicalData`
  elevated weight, `ContactRestraint` tiers). Most are hidden backend (fine per
  the Beta-distribution precedent), but the count of new dials is worth
  watching. `01`.
- Not engaged: dexterity/timing, touch/mouse parity. Colour: the approach
  picker and trade dialog should still honour the non-colour-channel principle.

---

## 7. Player legibility

- The chain's *existence* is well-signalled — each step surfaces as a visible
  guaranteed pool slot with its own row, and the alien-implying triggers are
  named.
- The First Contact approach UI is the key legibility surface and is
  underspecified: per approach the player needs the Ration + item cost, the risk
  tier, a directional odds cue, and the `ContactRestraint` consequence — before
  committing. Only cost/item/risk-tier are currently implied.
- Trade Agreement — the 3-candidate dialog is a clear single decision moment
  (good), but "no reroll" + opaque candidate generation means the player can't
  tell a poor set from the ceiling; the "permanently ends if you miss a
  payment" consequence must be unmistakable at accept time.
- `ContactRestraint` being invisible until run end fits the inspectable-
  sub-metric model, but the large Bluff/Military penalty should be telegraphed
  *at the choice*, not discovered in the viability report.
- Elevated legend value scaling inversely with success probability is invisible
  math — acceptable per the Beta-distribution precedent, but a rare Bluff
  success feeling more legendary should at least read in the log / Transmissions.

---

## 8. Fun / scope risk

- **The sentience-contact chain is the design's biggest content-per-frequency
  bet** — a long multi-step arc most runs never see (Sentience Detection ~10%
  cold, gated 8+). Justified as "one of the rarest, most story-worthy events,"
  but the volume of open structural decisions (§2) makes it the least-buildable
  part of System 10. Recommend an explicit call on whether to fully spec it now
  or defer the whole chain past a first playable.
- **First Contact's three approaches** are a strong, legible decision with real
  story weight — keep. The aggressive branches earning a large
  `ContactRestraint` penalty "for the choice regardless of success" is a clean
  design stance.
- **Trade Agreements** add a persistent per-season obligation with a hard
  failure state — meaningful, but the 3-concurrent cap + per-season Post-Sim
  check + permanent termination is real ongoing bookkeeping for a feature only
  alliance runs reach. The "pick one, no reroll" restraint keeps the decision
  cost low; keep, but playtest that it doesn't become a fiddly tax.
- **Deepening tiers** (count TBD) are the main scope risk — an open-ended "it
  deepens through follow-up tasks" without a tier count could balloon. Pin the
  count low (2–3).
- **Narrowing risk.** `ContactRestraint` mildly incentivises *never engaging* —
  detect-and-leave scores nearly as well as a full alliance, with none of the
  Ration / fabrication cost, and alliance needs deep Tinkerer's Workshop
  investment. For most runs the "optimal" play may be to ignore the chain —
  fine for a rare-wildcard feature, but confirm it's intended that the elaborate
  content is usually correctly skipped.

---

## 9. Findings summary

### Blockers

- **B1.** Peaceful Contact base alliance reward has no defined *shape*, only
  "TBD" — deepening rewards, Trade Agreement availability, Local Delicacy
  sourcing, and the zero-staffing passive-food reward tier all depend on it.
  Structural, not numeric. (§2 G-S1, §4 CS1 — `05` "Escalation Chains"; `04`
  "Food/Meal Conversion")
- **B2.** Deepening-alliance tier *count* and cadence undefined — sets arc
  length and the number of guaranteed-escalation pool slots generated; mis-
  tagged "purely numeric" in `DESIGN_TODO.md`. (§2 G-S2 — `05` "Escalation
  Chains")
- **B3.** No rule enforcing "at most one alien civilization per run" despite
  `ContactRestraint` assuming it — five triggers + Universal Ubiquity + the
  Unknown Radio Signal path can each reach Sentience Detection. (§2 G-S4, §3 IC1
  — `05` "Escalation Chains"; `06` "SEED Factions")
- **B4.** Trade Agreement candidate generation unspecified — how the 3 fixed
  expense/income pairings are drawn has no algorithm. (§2 G-S5 — `05`
  "Escalation Chains")

### Should-fix

- **SF1.** Define what a *base* alliance grants before any deepening (the
  immediate Peaceful Contact payoff shape, distinct from B1's downstream
  chain). (§2 G-S1 — `05` "Escalation Chains")
- **SF2.** Specify First Contact approach-selection reversibility — reversible
  plan-composition per `01`, with reserved Rations/items released on switch or
  cancel. (§2 G-S7, §6 P2 — `05` "Escalation Chains"; `01` "Planning phase is
  reversible")
- **SF3.** State how an unresolved sentience chain is handled at run end —
  abandoned guaranteed slot, and which `ContactRestraint` tier applies to a
  mid-arc or unfinishable-in-progress chain. (§2 G-S6, §4 CS4 — `05` "Escalation
  Chains"; `06` "SEED Factions")
- **SF4.** Quantify the chain's "significantly elevated `EcologicalData` weight"
  in evidence-count terms, consistent with `ν / (ν + k)`. (§2 G-S8, §4 CS3 —
  `05` "Escalation Chains"; `06` "Data-Gathering Mechanism")
- **SF5.** Specify the First Contact approach UI's information content — per
  approach: Ration + item cost, risk tier, directional odds cue (Technology
  Level / Unity), and the `ContactRestraint` consequence — before committing.
  (§6 P3, §7 — `05` "Escalation Chains"; `01` failure-legibility)
- **SF6.** Note the edge case where a Trade Agreement's per-season *expense* is
  Rations and Post-Sim nutrition just consumed the last of them — the ordering
  protects survival but silently and permanently ends the agreement. State
  whether intended. (§4 CS2 — `05` "Escalation Chains"; `03` "Season Structure")
- **SF7.** Author the vaccine-unlock region-reveal escalation as a real catalog
  entry and confirm it uses the guaranteed-slot mechanism. (§4 CS7 — `05`
  "Escalation Chains"; `04` "Medical Bay")
- **SF8.** State that "Observe from a distance" keeps a flat elevated legend
  value (like Peaceful Contact), having no success probability to scale by. (§3
  IC3 — `05` "Escalation Chains")
- **SF9.** Address guaranteed-escalation-slot vs. pool-size-3 pressure — an
  alliance arc can dominate the exploration pool; same fix as 10a SF2. (§4 CS6 —
  `05` "Escalation Chains")
- **SF10.** Re-tag in `DESIGN_TODO.md`: base-alliance-reward shape and
  deepening-tier-count are structural, not "purely numeric." (§2 —
  `DESIGN_TODO.md` "Alien civilization classes")

### Nice-to-have

- **NTH1.** Note the rescue-then-Military-Exploitation narrative incoherence as
  an allowed-but-costly conscious call. (§3 IC2)
- **NTH2.** Reconsider whether "never detecting a civilization" should score
  identically to "detect and respectfully withdraw." (§5)
- **NTH3.** Keep Biological Compatibility flavour-only — recorded as a
  deliberate anti-scope-creep choice. (§5)
- **NTH4.** Keep the "(3.5) Trade Agreement resolution" sub-step number synced
  between `05` and `03` if the Post-Sim list is edited. (§3 IC4)
- **NTH5.** Ensure the approach picker and trade dialog honour the non-colour-
  channel principle. (§6)

### Defer (numeric / content-pass)

- **D1.** `ContactRestraint` tier values. `06` "SEED Factions";
  `DESIGN_TODO.md`.
- **D2.** Bluff / Military exact odds curves and reward amounts; Bluff
  on-success payout magnitude. `05` "Escalation Chains"; `DESIGN_TODO.md`.
- **D3.** Overwhelming Force Package exact recipe. `04` "Fabrication";
  `DESIGN_TODO.md`.
- **D4.** Elevated-legend-value inverse-probability formula shape and magnitude.
  `05` "Escalation Chains"; `DESIGN_TODO.md`.
- **D5.** Sentience Detection per-trigger success percentages. `05` "Escalation
  Chains".
- **D6.** Trade Agreement per-candidate resource pairs and quantities; deepening
  per-tier reward values. `05` "Escalation Chains"; `DESIGN_TODO.md`.
- **D7.** `EcologicalData` `k` constant. `06` "Data-Gathering Mechanism".
