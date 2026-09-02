# Audit — System 12: Meta-Progression, Earth Hub & Run-Start Flow

Design audit. Pure design review against `full_design/`; no implementation
exists. Citations are `file` → "Section" (no anchor links: this file sits in
`audits/` and the repo link-checker only scans `full_design/*.md`).

This system is the one the design most openly acknowledges is unbuilt:
`DESIGN_TODO.md`'s "Run-start flow" item calls the hub a "4-bullet sketch
with no real UI/flow design underneath it." The audit's job here is to pin
down exactly what is missing and split it from what is merely deferred.

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Earth hub = persistent home base between runs; represents SEED's growing body of knowledge | `02` "Meta-Progression & Earth Hub" |
| Design Catalog — settlers arrive with blueprints for *all* known designs; only planet-side materials gate use within a run | `02` "Design Catalog"; `03` "Technology & Progression" (Within a Run) |
| Meta-progression axis — gathering enough of a *previously-unseen* resource type → Earth develops new designs using it → permanent catalog unlock | `02` "Design Catalog"; `03` "Technology & Progression" (Across Runs) |
| Earth Hub Contents — Design browser / Exoplanet catalog / Run history / Start run | `02` "Earth Hub Contents" |
| SEED Bulletin — periodic between-runs state-of-affairs panel (Earth politics, meta-progression hints, seed-ship news); not a voiced character | `02` "SEED Bulletin" |
| Exoplanet catalog — filament-scan candidates, limited slots, per-planet-*type* "known conditions" blurb, unclaimed-candidate shelf life, "opt into random" | `02` "Earth Hub Contents", "Filaments and Exoplanet Discovery", "Per-planet why-this-planet hook" |
| Phase 5+ hub scanning minigame — pick filament slots; more favorable target = harder, sometimes impossible; sanctioned exception to difficulty-from-tradeoffs | `02` "Meta-Progression & Earth Hub" (Phase 5+), "Filaments and Exoplanet Discovery"; `01` "Difficulty comes from breadth of tradeoffs" |
| Wormhole/filament lore constraints — mass threshold (stabilization tech) → small starting footprint; one-way outward expansion; permanent FTL comms trace | `02` "Faster-Than-Light Travel", "Filaments and Exoplanet Discovery" |
| Persistent player-AI "Herald" — named by the player at introduction/tutorialization; same character carries a career across all runs | `02` "SEED's Culture, and the Player's Role" |
| Run-start sequence — hub landing → Crew Selection → expedition commitment (filament-scan planet-type choice) → Farm Site Selection → starting loadout → run-start SEED summary transmission → Season 1 planning | assembled from `02` / `03` / `06`; **not stated as a sequence anywhere** |
| Crew Selection — one-time pre-run screen; per-crew set of Aptitude-rolled settlers; free uncapped reroll; **precedes Farm Site Selection**; order vs. filament-scan TBD | `03` "Crew Selection" |
| Farm Site Selection — one-time pre-run screen; generates & locks the grid instance (terrain, fixed slots, deposit seeding); **after** planet-type commitment; 3 candidates, 1-Ration reroll | `03` "Farm Site Selection" |
| Starting loadout — 3–4 settlers, starting Rations stock, ≥1 Solar Array + Water Processing Plant + Sawmill + Stone Processing I; counts "tied to wormhole mass-threshold stabilization tech" | `03` "Crew Selection"; `04` "Basic Resource Production", "Water Processing Plant", "Sawmill", "Stone Processing I"; `05` "Rations (Basic Sustenance)" |
| Run-start SEED summary transmission — one-time, near-zero-confidence; surfaces the planet-*type* Bayesian priors, framed as SEED institutional knowledge | `06` "In-Simulation Hazard Events" (telegraphing, near-zero confidence) |
| Run History — planet visited, score, key outcomes; currently unbounded; a surviving colony is preserved as a record | `02` "Earth Hub Contents", "SEED's Culture…"; `07` "Backend & Data Persistence" (open questions) |
| Settings screen(s) — not designed anywhere; principle-mandated contents scattered (°F/°C toggle, dexterity/gesture-timing scale, volume, larger-font tier, drag-offset toggle) | `01` "Units are unspecified", "Dexterity-timing thresholds", "Text legibility"; `07` "Autoloads" |
| Save/load & persistence — `SaveData` Resource `.res` to `user://`; save after every meaningful planning action + on app pause; local-only single slot | `07` "Backend & Data Persistence" |
| Flagged-not-committed — a past colony later receiving a seed-ship grants a windfall the player allocates toward meta-progression + the planet's real name | `02` "SEED's Culture, and the Player's Role" |

**Boundary notes (ambiguous ownership).**
- **Starting loadout** — this system owns *what* the run starts with; Systems 1 (grid placement of starting buildings), 5 (Energy baseline), 6 (Water — Water Processing Plant), 8 (starting Rations stock) consume it. No doc assigns the definition.
- **Farm Site Selection output** — terrain + deposit seeding is consumed by Systems 1 and 7; per-site Average Temperature by System 11. This system produces; they consume.
- **Run-start SEED summary transmission** — mechanically defined in System 11 (`06`); its *placement in the run-start sequence* is this system's.
- **Score / viability report** — a cross-cutting concern; this system only displays it (Run History).

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. The run-start flow between "Start run" and Season 1 planning is undesigned.** No spec for the hub landing (what the player first sees/does), the screen sequence and transitions, where each already-designed step sits (Crew Selection, filament-scan/planet commitment, Farm Site Selection, starting-loadout grant, starting-building placement, the run-start SEED summary transmission), or the reversibility/commitment boundary. This is `DESIGN_TODO.md`'s "Run-start flow" item; confirm its scope and add the commitment-boundary question (below, G-S2 / §6 P2). *Possible direction: author it as an explicit linear screen sequence with one named "run begins — no further re-rolls" commit point, everything before it freely re-rollable.*
- **G-S2. Crew Selection ↔ filament-scan ordering is explicitly TBD** (`03` "Crew Selection"). Determines whether the player picks a crew blind to the planet or informed by its type — a real strategy lever (mining-apt crew for Volcanic, etc.).
- **G-S3. The meta-progression unlock trigger is undefined.** No definition of "enough" of a resource, no definition of "previously-unseen" (which implies a persistent cross-run ledger of every resource type ever gathered), no statement of which new design(s) a given material unlocks (an authored material→design mapping is implied but unspecified), and no statement of whether the unlock is surfaced to the player. The primary meta-progression loop cannot be built or deliberately pursued without this. *Possible direction: a per-resource-type cumulative-gathered threshold checked at run end against a persistent ledger, with an authored material→design table.*
- **G-S4. The "stabilization tech" meta-progression axis is named but entirely undesigned.** `02` "Faster-Than-Light Travel" and `04` "Basic Resource Production" both defer it and tie the starting expedition footprint (settler count, starting buildings, Rations, Solar Array count) to it. How it improves across runs, whether the player influences it, and its per-tier effect are all open. *Possible direction: decide it is real and additive-only (a second axis unlocked by a milestone), or cut it and fix the starting loadout as a flat number.*
- **G-S5. Pre-Phase-5 exoplanet selection is unspecified** — candidate count, how candidates are generated, whether the filament shelf-life / soft reroll-limit from the lore is mechanically active before the Phase 5+ minigame exists, and whether "opt into random" differs mechanically from choosing.
- **G-S6. Settings screen(s) undesigned** — no consolidated spec, and no statement of in-run vs. hub access, though the principles scatter a required contents list.
- **G-S7. First-run tutorialization is undesigned** — `02` places the one-time Herald-naming step "as part of the game's introduction/tutorialization"; nothing about a first-run experience exists anywhere.
- **G-S8. Run History's role and presentation are undefined** — pure display, or does it "seed the next run's approach" (`01` replayability open question)? Also `06`'s open question of whether the five sub-metrics combine into a cross-run-comparable figure is really a Run History question.

### Numeric / content-pass (catalogued only)

- **G-N1.** Exoplanet-catalog candidate slot count; filament shelf-life window; reroll soft-limit timing. `02`.
- **G-N2.** Starting-loadout quantities (settler count 3–4, starting Rations, Solar Array count, exact building set) — tied to G-S4 but the base numbers are independently TBD. `03` / `04` / `05`.
- **G-N3.** Run History retention limit / pagination. `07` "Backend & Data Persistence" (open question).
- **G-N4.** Per-planet-type "known conditions" blurb content. `02`.
- **G-N5.** Meta-progression material→design unlock authoring table (once G-S3's model is chosen). `02` / `03`.

### Cross-check with `DESIGN_TODO.md`

The "Run-start flow" item covers G-S1 and names Settings (G-S6) and Run History
presentation (G-S8). It does **not** flag G-S2 (Crew/filament ordering — though
`03` flags it inline), G-S3 (unlock trigger undefined), G-S4 (stabilization-tech
axis), G-S5 (pre-Phase-5 planet selection), or G-S7 (tutorialization). Recommend
extending the item.

---

## 3. Internal consistency

- **IC1. SEED Bulletin absent from the "Earth Hub Contents" list.** `02` "Earth Hub Contents" enumerates four items; SEED Bulletin is described as "A hub panel" later in the same file but never added to the list. (→ SF8.)
- **IC2. "The very first decision of a run" vs. TBD ordering.** `03` "Crew Selection" justifies its free uncapped reroll as being "the very first decision of a run, before there's anything in inventory to spend" — which only holds if Crew Selection precedes both the planet commitment and the starting-Rations grant. The same section then leaves ordering vs. filament-scan "TBD". The rationale and the open question are in tension. (→ SF1 / SF2.)
- **IC3. "No explicit account of elapsed years" vs. a chronological Run History.** `02` deliberately keeps no in-fiction elapsed-time account across runs; Run History lists "past runs". Not a contradiction (sequence ≠ dates), but Run History presentation must avoid implying a timeline. (→ SF7.)

---

## 4. Cross-system consistency

- **CS1 (→ B3). Starting-loadout seam.** This system produces the starting settlers / buildings / Rations / Solar Arrays; Systems 1 (grid placement — `full_design/audits/01_grid_placement_and_construction.md` B3), 5 (Energy baseline), 6 (Water) consume them. No doc defines the loadout or how starting buildings land on the grid (player-placed vs. auto-placed, later relocatable). Blocks those systems' baselines and the `DisruptionFootprint` "start of Season 1" snapshot (`06` "SEED Factions").
- **CS2. Farm Site Selection hand-off.** Terrain + deposit seeding → Systems 1 and 7; per-site Average Temperature → System 11; Surface-tier deposit / Forest positions → System 7. Consistent producer→consumer; no conflict, noted so the hand-off is explicit.
- **CS3. Starting Rations ordering constraint.** Farm Site Selection reroll costs 1 Ration (`03`), so the starting Rations stock must be granted *before* Farm Site Selection — which constrains where "starting-loadout grant" sits in the sequence (G-S1).
- **CS4. Run-start SEED summary transmission placement.** Owned here, defined in `06`. Must land after planet-type commitment (it quotes planet-*type* priors) and before or at Season 1 planning. (Already in the "Run-start flow" item.)
- **CS5 (→ SF6). Save/load + interruptibility.** `07` "Backend & Data Persistence" defines save-after-every-planning-action and save-on-app-pause, but around an Android lifecycle (`NOTIFICATION_APPLICATION_PAUSED`, "critical on Android") that the `03` PC-first pivot supersedes. `01`'s open "interruptibility" principle question wants this formalized as an explicit guarantee.
- **CS6. Catalog-size discipline.** Meta-progression grows the Design Catalog across runs; the Design browser / build menu must apply `01`'s "surface relevant/available choices ahead of irrelevant" at a scale that keeps growing. No per-run system appears to assume a *bounded* catalog, but this should be a conscious constraint. (→ NTH5.)

---

## 5. Story & world consistency

- **Strongly reinforcing — record as a deliberate strength.** The hub is among the most story-integrated systems in the design: the persistent Herald identity gives it a protagonist throughline distinct from SEED-the-institution (`02` "SEED's Culture…"); Ren's centuries-long runway explicitly licenses the hub not tracking elapsed time; the filament/mass-threshold lore motivates the small starting footprint; the SEED Bulletin and the run-start SEED summary transmission both have concrete in-fiction bases. No lore conflict in the core system.
- **Minor stretch (no change required).** "Opt into random selection" of the next planet sits slightly awkwardly against the fiction that filaments are deliberately, expensively tasked toward chosen candidates — random contradicts the deliberateness the lore builds up. Acceptable, noted. (Overlaps SF4 / NTH2.)
- **Missed reinforcement (→ NTH1).** The hub's per-planet-*type* "known conditions" blurb and the run-start SEED summary transmission are two surfacings of the same planet-type prior information at two moments. Saying so explicitly — the blurb you read choosing the planet *is* the prior the transmission later quantifies — would tie them together for the player.

---

## 6. Design-principle adherence

**Adherent — worth recording:**
- *Forgiving of individual mistakes* — meta-progression is stated as additive-only ("never subtracts"), and a surviving colony is preserved as a record; a bad run is forgiven at the run-to-run level.
- *Difficulty from breadth of tradeoffs* — the Phase 5+ scanning minigame is the one explicitly sanctioned exception (`01`); pre-Phase-5 planet choice is a pure strategic pick with no execution component.

**Risks / violations:**
- **P1 (→ B2). Failure / progression legibility.** The meta-progression unlock trigger is not surfaced (G-S3) — if the player is never told the "gather enough of a new resource type" rule, or which resources on the current planet would trigger an unlock, meta-progression is opaque and cannot be deliberately pursued, cutting against `01` "failure should always be legible" (here: *progression* should be legible) and the replayability open question's "meta-progression expanding the strategy space".
- **P2 (→ SF2). Randomization gating.** `01` "Planning phase is reversible" requires a random draw be gated behind an explicit irreversible commitment. Crew Selection and Farm Site Selection each involve re-rollable random draws and each "lock in … for the entire run" at some point; the run-start flow does not state where that irreversible commit is or that everything before it is freely reversible.
- **P3 (→ SF5). Interruptibility (open principle question).** `01` explicitly flags this as unresolved and points at the save-trigger behaviour; the hub↔run boundary and the persistence design are where it must be formalized.
- **P4 (→ NTH3). Describe the current design, not its history.** `07`'s Backend section is written around an Android app lifecycle the `03` pivot superseded; `02`'s hub section is an admitted sketch. Transitional-doc cleanup, same category the pilot flagged for `03`.
- **P5. Numbers stay small** — Run History is "currently unbounded" (`07`); an ever-growing list is a mild instance of the "a number/collection that grows unhelpfully large is a diagnostic signal" framing. Low stakes. (→ D3.)
- **P6.** Settings must host the °F/°C toggle, the global dexterity/gesture-timing scale, and an optional larger-font tier that three separate principles mandate — and Settings is undesigned (G-S6 / SF5-Settings).
- Not engaged / n/a: units-unspecified (beyond the Settings toggle), naming convention, normalize-before-combining, colour-not-sole-channel (no grid overlays here), difficulty-from-tradeoffs beyond the sanctioned minigame.

---

## 7. Player legibility

- **Which unlocks exist / how to get them** — the Design browser shows current unlocks; whether it teases locked-but-discoverable designs is unspecified (→ NTH4), and the unlock *trigger* is unsurfaced (P1 / B2). Net: meta-progression is currently opaque to the player.
- **What each candidate planet offers** — the per-planet-type "known conditions" blurb covers this at type granularity; adequate once authored (G-N4).
- **What to expect turn one** — the run-start SEED summary transmission is explicitly designed for this; good.
- **Naming the Herald** — a one-time action with no designed context to host it (G-S7).
- **Run-start sequence** — legible once designed; nothing structurally hostile to legibility.

---

## 8. Fun / scope risk

- **The hub is currently almost decision-free** — pick a planet, (Phase 5+) play a minigame, start; meta-progression is automatic. Defensible as minimalist scope, but it makes the between-runs experience thin. Worth an explicit decision: is that intended, or should the hub carry a real recurring choice (the flagged seed-ship-windfall allocation is the obvious candidate)?
- **Two meta-progression axes, one undesigned.** "Resource discovery → new designs" is the stated primary; "stabilization tech → larger starting footprint" (G-S4) is a whole second axis mentioned only in passing. Decide if it is real or cut it — don't let it drift as a half-referenced dependency of the starting loadout.
- **"Opt into random" is a dead option** as written — no incentive delta vs. choosing. Give it a reason to exist or cut it. (Overlaps SF4.)
- **Tutorialization is unbudgeted scope** — first-run experience + Herald naming + teaching the core loop is a real chunk of work not acknowledged in the roadmap.
- **Run History unbounded** — low stakes; decide pruning/pagination rather than let it grow untracked.

---

## 9. Findings summary

### Blockers

- **B1.** The run-start flow (hub landing → Crew Selection → planet commitment → Farm Site Selection → starting loadout → SEED summary transmission → Season 1 planning) is undesigned — sequence, transitions, and where each already-designed step sits. (§2 G-S1, §3 IC2 — `DESIGN_TODO.md` "Run-start flow"; `02` "Earth Hub Contents"; `03` "Crew Selection" / "Farm Site Selection")
- **B2.** Meta-progression unlock trigger undefined — the "enough of a previously-unseen resource type" threshold, the cross-run ledger it implies, the authored material→design mapping, and whether the unlock is surfaced to the player; without it the primary meta loop is unbuildable and opaque. (§2 G-S3, §6 P1, §7 — `02` "Design Catalog"; `03` "Technology & Progression" Across Runs)
- **B3.** Starting-loadout ownership seam — this system produces the starting settlers/buildings/Rations/Solar Arrays but no doc defines the loadout or how starting buildings land on the grid; blocks Systems 1/5/6 baselines and the `DisruptionFootprint` Season-1 snapshot. (§4 CS1 — `04` "Basic Resource Production"; `03` "Farm Site Selection"; `full_design/audits/01_grid_placement_and_construction.md` B3)

### Should-fix

- **SF1.** Decide Crew Selection ↔ filament-scan ordering (explicitly TBD) — blind vs. planet-informed crew pick. (§2 G-S2 — `03` "Crew Selection")
- **SF2.** Define the run-start reversibility/commitment boundary — which pre-run choices are freely re-rollable and the single point past which the run is committed, per the randomization-gating principle. (§2 G-S1, §6 P2 — `01` "Planning phase is reversible"; `03` "Crew Selection" / "Farm Site Selection")
- **SF3.** Decide whether the "stabilization tech" meta-progression axis is real (design how it improves + its per-tier effect on the starting loadout) or cut it and fix the starting loadout as a flat number. (§2 G-S4 — `02` "Faster-Than-Light Travel"; `04` "Basic Resource Production")
- **SF4.** Specify pre-Phase-5 exoplanet selection — candidate count, generation, whether the filament shelf-life/reroll-limit lore is mechanically active yet, and whether "opt into random" differs mechanically from choosing. (§2 G-S5, §8 — `02` "Earth Hub Contents" / "Filaments and Exoplanet Discovery")
- **SF5.** Consolidate a Settings screen spec (°F/°C toggle, global dexterity/gesture-timing scale, volume, optional larger-font tier, drag-offset toggle; in-run vs. hub access). (§2 G-S6, §6 P6 — `01` "Units are unspecified" / "Dexterity-timing thresholds" / "Text legibility"; `07` "Autoloads")
- **SF6.** Resolve the interruptibility open principle question here — an explicit "safely pausable any time, no meaningful progress loss" guarantee formalizing save-on-every-action; and re-base `07`'s persistence section off its Android-lifecycle assumptions post PC-first pivot. (§4 CS5, §6 P3/P4 — `01` Design Principles open block; `07` "Backend & Data Persistence")
- **SF7.** Define Run History's role and presentation — pure record vs. seeding the next run (`01` replayability open question), whether runs get a cross-run-comparable score figure (`06` open question), and avoiding any implied timeline (IC3). (§2 G-S8, §3 IC3 — `02` "SEED's Culture…"; `06` "Win / Lose Conditions"; `07` "Backend" run-history open question)
- **SF8.** Add SEED Bulletin to the "Earth Hub Contents" enumeration in `02`. (§3 IC1 — `02` "Earth Hub Contents" vs "SEED Bulletin")
- **SF9.** Decide where the one-time Herald-naming step lives — it presumes a first-run intro/tutorial that isn't designed; full tutorialization is a separate later effort but the naming step needs a home. (§2 G-S7 — `02` "SEED's Culture, and the Player's Role")

### Nice-to-have

- **NTH1.** Explicitly link the hub's per-planet-type "known conditions" blurb and the run-start SEED summary transmission (same prior info, two moments). (§5)
- **NTH2.** Give "opt into random" planet selection a reason to exist or cut it. (§5, §8; overlaps SF4)
- **NTH3.** Fold `07`'s Backend section and `02`'s hub sketch out of transitional/Android framing once the flow settles, per "describe the current design, not its history". (§6 P4)
- **NTH4.** Decide whether the Design browser teases locked-but-discoverable designs so the player can see what meta-progression offers. (§7)
- **NTH5.** Keep the Design browser / build menu applying "surface relevant choices first" as the catalog grows across runs. (§4 CS6)

### Defer (numeric / content-pass)

- **D1.** Exoplanet-catalog candidate slot count; filament shelf-life window; reroll soft-limit timing. `02`.
- **D2.** Starting-loadout quantities (settler count, starting Rations, Solar Array count, building set). `03` / `04` / `05`.
- **D3.** Run History retention limit / pagination. `07` "Backend & Data Persistence".
- **D4.** Per-planet-type "known conditions" blurb content authoring. `02`.
- **D5.** Meta-progression material→design unlock authoring table (once B2's model is chosen). `02` / `03`.
- **D6.** Monetization decision — gates the backend/persistence/accounts design. `07` "Monetization".
- **D7.** Phase 5+ scanning minigame mechanical spec; deeper-filament-scanning unlock. `02`.
- **D8.** The flagged-not-committed "past colony receives a seed-ship" windfall + real-name mechanic. `02` "SEED's Culture, and the Player's Role".
