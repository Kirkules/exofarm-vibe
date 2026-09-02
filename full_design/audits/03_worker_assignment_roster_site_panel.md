# Audit — System 3: Worker Assignment, Roster & Site Panel

Design audit against `full_design/`; no implementation exists. Citations are
`file` → "Section" (no anchor links: this file sits in `audits/` and the repo
link-checker only scans `full_design/*.md`).

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| Assignment = one worker ↔ one target; "pick a worker, pick a target, done"; reversible until Next Season | `03` "Assignment" |
| Three target kinds, difference is a property of the target not the mechanism | `03` "Assignment" |
| Production-building assignment — sticky by default; worker stays across seasons until explicitly reassigned; per-settler default remembered | `03` "Assignment"; `05` "Settler State" |
| Exploration-Task assignment — one-shot; settler gone for the season; locked to that settler every season while multi-season/incomplete; settler-only, no drone ever | `03` "Assignment"; `05` "Settler State", "Exploration Tasks" |
| Standing-Assignment assignment — one-shot, no stickiness; safe; per-assignment worker-type eligibility | `03` "Assignment"; `05` "Standing Assignments" |
| Every production site needs a worker to produce at all; unstaffed site = zero output that season | `03` "Assignment" |
| Exceptions: some sites are Unstaffed (zero-effort); some are multi-purpose combo buildings (one worker, two outputs, secondary side slower) | `03` "Assignment"; `04` "Building Schema" (Staffing) |
| Worker types for production: Settlers (universal subject to Injuries/Aptitude; 1 slot each; 1.0 Effort baseline) and Drones (built at Robotics Assembly; 1 site each; Effort by tier) | `03` "Assignment"; `04` "Robotics Assembly" |
| Effort stacks toward a per-site production cap (cap scales with tier/upgrades); one worker may realize only part of it; second worker to reach cap ⇒ spread-thin vs. concentrate | `03` "Assignment" |
| "One worker, one slot" is the settler default; explicitly left open whether a special worker type breaks it | `03` "Assignment" |
| Construction robots are workers in fiction but out of this system — single-purpose, auto-assigned, never production-staffing | `03` "Construction" |
| Drone battery — per-drone max by tier; resets full each season; drains over Mid-Sim; auto ~3s recharge at zero; recharge = elevated Energy Consumption competing in the random-shed pool; zero Effort while recharging/waiting; temp-accelerated drain except Hardened | `04` "Robotics Assembly" |
| Worker freed back to roster when its building is destroyed (loses Indoor protection if mid-Mid-Sim) | `04` "Robotics Assembly" (Destruction) |
| **Worker Roster (UI)** — left-edge avatar column over the vista; one row per worker type *present*; "A/B" = unassigned/total | `03` "Worker Roster (UI)" |
| Roster hover — outlines the avatar and every building/site serviced by that type | `03` "Worker Roster (UI)" |
| Roster is an assignment entry point — dragging a row with A > 0 starts the same assign flow as picking up a worker directly | `03` "Worker Roster (UI)" |
| Roster Mid-Sim expansion — one icon per actual worker; states: actively-working (animated) / hazard-affected (status_effect overlay icon) / not-working (idle, static); drones also carry a permanent battery bar; reverts to "A/B" next planning phase | `03` "Worker Roster (UI)" |
| **Site Panel (UI)** — right-edge, opens on selecting any built production site during Planning (staffed or not); fixed contents order | `03` "Site Panel (UI)" |
| Name/icon | `03` "Site Panel (UI)" |
| Recipe section — always present; plain indicator (single-recipe) or click-to-switch selector (multi-recipe), sticky & reversible | `03` "Site Panel (UI)"; `04` "Building Schema" (recipes) |
| Assigned-worker slot — always present; present-but-disabled (greyed, not absent) for unstaffable buildings; valid drop target *either* on the slot *or* on the building's grid tile | `03` "Site Panel (UI)" |
| Production-rate summary — one combined number folding base rate + Effort/Experience/Aptitude + other effects (Alien Soil, Fertilizer, Hybridization, …); breakdown in its tooltip | `03` "Site Panel (UI)"; `05` "Aptitude", "Experience", "Storied" |
| Status section — power-sufficiency indicator Green/Yellow/Red, shape-coded not colour-alone; a planning-phase *prediction*, not live status; other status content left open | `03` "Site Panel (UI)"; `04` "Resources" (Energy Income/Consumption Rates) |
| Per-element hover tooltips (separate small boxes) — plain-language ("+30% Farming speed"), never formulas; worker slot's tooltip carries the Effort/Experience/Aptitude readout | `03` "Site Panel (UI)"; `05` "Aptitude", "Experience" |
| Effort modifiers: Aptitude (±15%/level, innate) + Experience (+15%/stack, earned) stack additively; Storied +15% on production assignments | `05` "Aptitude", "Experience", "Storied" |

**Boundary notes (ambiguous ownership).**
- **slot-count = worker-capacity** — the count is a Building-Schema fact, the spatial footprint is Grid (System 1); assignment consumes it. Tightly coupled (CS1).
- **Drone taxonomy internals** (Effort table, eligibility, battery numbers, Advance/Harden) belong to System 7; audited here only where they hit assignment/roster/panel.
- **Plant-crop 3-phase cycle** (Growing needs no worker) belongs to System 4; audited here only at the "what does the Site Panel show" seam (CS2).
- **Construction-robot budget / N-actions cap** belongs to Systems 1–2; the open question here is only whether robots appear in the Worker Roster (CS5).
- **Standing-Assignment / Exploration mechanics** belong to System 10; audited here only for roster/Mid-Sim representation of those workers (B3, CS3).

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. Effort-stacking toward a per-site production cap has no concrete building instance.** `03` "Assignment" sells "requiring a second worker to reach the cap" as a core tradeoff, but `04` "Farm/Production" pins all seven farm buildings to "a fixed 1-worker cap" with "upgrades … never raise the effort-stacking cap", and `04` "Kitchen" makes the Upgraded tier *parallel independent stations* (each its own worker, own recipe), not stacking toward a shared cap. No building in the catalogue currently has a >1-worker shared cap. *Possible direction: name the categories/tiers that do have a multi-worker cap and state Farm/Production and Kitchen are deliberately outside it — or cut the mechanic (see §8).*
- **G-S2. Worker-to-building vs. worker-to-slot is unspecified for multi-slot buildings.** `03` "Site Panel (UI)" gives one "Assigned worker slot"; `04` "Building Schema" defines slot count as "the number of simultaneous worker assignments a building supports" and `04` "Kitchen" = "2 slots (2 workers)". Whether a worker is assigned to the *building* or to a *named slot within it* (Kitchen implies the latter — per-slot recipe choice) changes the Site Panel, the roster drag target, and the grid-tile drop target. *Possible direction: assignment targets a slot; the Site Panel renders one worker-slot row per building slot; the grid-tile drop fills the next free slot.*
- **G-S3. Roster representation of non-production-building workers is undefined.** The hover-highlight "outlines every building/site serviced" and the Mid-Sim per-worker expansion both assume a building target. An Exploration-Task settler is off-grid and "gone for the season"; Standing-Assignment workers act on tiles/rectangles. Whether an exploring settler shows a roster icon at all during Mid-Sim, and what a survey/trap/clear-cut worker's icon points at, is unstated. `03` "Assigned-worker Mid-Sim depiction" covers only production-site workers.
- **G-S4. Pre-assigning a worker to a queued (not-yet-built) building is undefined.** Construction resolves next season (`03` "Construction"); it isn't said whether a worker can be assigned now so the site is staffed on completion, or whether a fresh site is necessarily idle its first season.
- **G-S5. The unassign / send-to-idle gesture is unspecified.** `05` "Settler State" lists "idle" as a valid `current_assignment`; production assignment is sticky "until explicitly reassigned"; no gesture for pulling a worker *off* a site without placing them elsewhere is given.
- **G-S6. Which concrete worker a type-row roster drag assigns when A > 1.** `03` "Worker Roster (UI)" says the drag "begins the same assign-to-site flow as picking up a worker directly", but a type row is a count, not an individual — the selection rule (arbitrary? least-experienced? player-chosen?) is unstated, and matters because Experience/Aptitude are per-settler.

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** Per-site production-cap values by building/tier (if G-S1 keeps the mechanic). `03` "Assignment"; `04` "Building Schema".
- **G-N2.** Drone battery capacity, drain rate, and the "~3 seconds … possibly varying by drone type" recharge duration, per tier. `04` "Robotics Assembly".
- **G-N3.** Storied `legend_value` threshold. `05` "Storied" (already in `DESIGN_TODO.md`).
- **G-N4.** Temperature-deviation → battery-drain curve. `04` "Robotics Assembly".

### Cross-check with `DESIGN_TODO.md`

`DESIGN_TODO.md` marks "Production building UI" and "Energy Pool per-building powered state" resolved, and both match `03` faithfully; it notes "any status-section content beyond power is unaddressed". It does **not** flag G-S1 (effort-stacking has no instance) or G-S2 (worker-to-slot for multi-slot buildings). Recommend adding both.

---

## 3. Internal consistency

- **IC1. Single "Assigned worker slot" vs. multi-worker buildings.** `03` "Site Panel (UI)" (one slot, "always present") vs. `04` "Kitchen" (Upgraded = 2 workers). The panel must show N slots for an N-slot building. (→ G-S2 / B2.)
- **IC2. Effort-stacking described as central, realized nowhere.** `03` "Assignment" ("a second worker to reach the cap", "spread-thin-vs-concentrate tradeoff") vs. `04` "Farm/Production" (fixed 1-worker cap) and `04` "Kitchen" (parallel slots). (→ G-S1 / B1.)
- **IC3. Planning-phase roster can't show per-worker placement.** The per-worker expansion is Mid-Sim-only (`03` "Worker Roster (UI)"), but sticky defaults are per-settler (`05` "Settler State" — "remembers its last-assigned settler"), so during planning the roster shows only "A/B" and the player can't see *which* settler is defaulted where without opening each Site Panel.
- **IC4. Type-row drag vs. "pick a worker".** `03` "Assignment" ("pick a worker, pick a target") vs. `03` "Worker Roster (UI)" (drag a type row) — the row is a count; which individual it grabs is unresolved. (→ G-S6.)

---

## 4. Cross-system consistency

- **CS1. slot-count = worker-capacity binds this system to Grid (System 1) + Building Schema.** Grid audit finding B2 (no multi-slot footprint-shape model) directly blocks the multi-worker Site Panel here. Same seam; resolve together.
- **CS2. The Site Panel's "one combined number" needs a combination rule and a plant-crop answer.** `05` "Aptitude" says Aptitude + Experience "stack additively"; Storied adds +15%; the summary also folds Alien Soil (−30%), Fertilizer, Hybridization "and similar". Whether all are additive %-speed or some multiplicative is unstated, and for a plant-crop building the "rate" differs by phase (Planting/Harvesting Effort-driven, Growing not — `04` "Farm/Production") so it's unclear whether the panel shows one number or per-phase.
- **CS3. Mid-Sim depiction of Standing-Assignment and Exploration workers.** `03` "Assigned-worker Mid-Sim depiction" covers only "a worker stickily assigned to a production site". Survey/Trapping/Clear-Cutting workers (grid tiles) and exploring settlers (off-grid) have no specified on-screen or roster depiction. (→ G-S3; cross-refs Season Structure + Exploration audits.)
- **CS4. Drone recharge stalls aren't in the Site Panel prediction.** `04` "Robotics Assembly" — a drone can stall mid-sim for a recharge, and lose that contest under an Energy shortfall. The Site Panel's Green/Yellow/Red is per-building and can't express "this site's drone worker may stall". Legibility gap for drone-staffed sites.
- **CS5. Are construction robots a Worker Roster row?** `03` "Worker Roster (UI)" — "one row per worker type actually present". Construction robots are workers in the fiction, auto-assigned, single-purpose. Whether they get a row (showing remaining N actions) or a separate indicator is unstated; Grid audit §7 already flags that an "actions used/available" readout is needed somewhere.
- **CS6. Per-building worker eligibility must be enforced and explained at the worker slot.** `03` "Assignment" + `04` "Robotics Assembly": Research Lab and Medical-Bay *research* are settler-only; Tinkerer's Workshop needs Advanced-tier eligibility; Basic All-Purpose drones are barred from Surveys/Trapping/HTC; Specialized drones are locked to one Experience group and it's unstated whether a Surveys/Trapping/Clear-Cutting-Specialized drone qualifies for that Standing Assignment. The Site Panel worker slot and roster drop must reject ineligible workers and say why.

---

## 5. Story & world consistency

- **Reinforcing.** Drones as "settler-lite roster entries" and the roster as a command surface fit `02` "SEED's Culture, and the Player's Role" (the Herald "operates at the level of planning and direction, not direct control"); autonomous field drones are explicit `02` "The Crash Research Era" lore. Reading a manifest of worker types present, rather than walking the site, matches the detached-orbital viewpoint.
- **No lore conflict** in the core assignment/roster/panel mechanics.
- **Missed reinforcement (minor, contingent).** The "spread thin vs. concentrate" Effort tradeoff has no in-fiction voice — moot until G-S1 resolves whether it exists at all.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Minimal UI interaction* — roster drag fuses "notice an idle worker" + "assign"; two drop targets (slot or grid tile) for one action; sticky defaults mean a stable layout needs no per-season action. Named in `03`.
- *Planning phase is reversible* — assignment is "a normal, fully reversible planning-phase action".
- *A passable plan should always be quick to reach* — sticky defaults let a familiar player "coast … with near-zero action" (`01`).
- *Colour is never the sole channel* — the Site Panel power indicator is explicitly shape-coded, not colour-alone.
- *Difficulty from breadth of tradeoffs* — the staffing decision is intellectual (which worker, which site), no execution precision.

**Risks / violations:**
- **P1. Colour is never the sole channel** — the Mid-Sim roster "working vs. not working" distinction rests on *animated vs. static* alone ("no separate dedicated 'unpowered' icon, it's just the absence of the working animation"). Motion-vs-stillness is a weak channel and fails a reduced-motion setting. Needs a static shape/icon cue for the idle state.
- **P2. Failure should always be legible** — a worker dropped on a site that rejects them (CS6) needs an explicit "why not"; not specified.
- **P3. Failure should always be legible** — a drone-staffed site can stall mid-sim for a recharge with no planning-phase signal (CS4).
- **P4. Minimal UI interaction ("choices all at once, not gated behind navigation")** — seeing which specific settler is stickily defaulted where (relevant: Injuries/Aptitude bar some pairings) requires opening each Site Panel one at a time during planning (IC3).
- Not engaged: numbers-stay-small (Effort 0.5–2.0; see G-N1), units-unspecified, naming, dexterity-timing, text-legibility, touch/mouse parity (PC-mouse primary). *normalize-before-combining* only bites if CS2's modifiers turn out to be different *kinds* of quantity.

---

## 7. Player legibility

- **Worker deployment** — roster hover answers it at the type level (planning) and per-worker (Mid-Sim). Gap: which *specific* settler is on which site during planning (IC3 / P4).
- **Idle workers** — the "A/B" count plus roster-as-entry-point covers this well.
- **Why a site's output is what it is** — Site Panel rate summary + per-element tooltip breakdown; good, pending CS2's combination rule.
- **Why a worker can't be assigned somewhere** — not surfaced (CS6 / P2).
- **Drone recharge risk** — Mid-Sim battery bar exists; no planning-phase forecast (CS4 / P3).
- **Effort-stacking headroom** — if the mechanic survives G-S1, the player needs "1.4 / 2.0 Effort — add a worker for full output"; the summary shows only the resulting number.
- **Construction-robot budget** — no roster/indicator specified (CS5).

---

## 8. Fun / scope risk

- **Assignment core** (pick worker → target, sticky-by-default) is lean and high-value. Keep.
- **Effort-stacking toward a per-site cap is the scope risk.** Sold as central, currently instance-less (G-S1 / IC2). Either give it real homes — buildings with a genuine 2+ worker shared cap outside Kitchen's parallel model — which adds balancing surface, or drop it: "one worker per site, full stop" is simpler and the spread-vs-concentrate tension then lives in *which* sites get staffed at all. Decide explicitly rather than let it drift.
- **Drone battery + temperature-drain + recharge-competes-with-Energy-shedding** is a lot of hidden simulation for something the player can't steer ("fully automatic, no player decision"). Its real job is making higher-tier drones better. Watch in playtest whether it's legible enough to matter or is invisible friction.
- **Roster dual role** (status display + assignment surface + Mid-Sim expansion) is a big single-panel spec, but each piece maps to a real need. Reasonable.
- **Narrowing risk** — sticky defaults + "coast with near-zero action" is intended; the "deliberate plan beats passable" gap (`01`) then has to come from active reassignment paying off (targeting Experience accrual, matching Aptitude). Flag for the balancing pass to verify that upside exists.

---

## 9. Findings summary

### Blockers

- **B1.** Effort-stacking toward a per-site production cap has no concrete building instance (Farm/Production is 1-worker-capped; Kitchen's multi-slot tier is parallel stations) — decide whether it has real homes or is cut. (§2 G-S1, §3 IC2, §8 — `03` "Assignment" vs `04` "Farm/Production", "Kitchen")
- **B2.** Site Panel gives one "Assigned worker slot" but multi-slot buildings need multiple, and worker-to-building vs. worker-to-slot is unspecified. (§2 G-S2, §3 IC1 — `03` "Site Panel (UI)" vs `04` "Building Schema", "Kitchen")
- **B3.** Roster hover-highlight and Mid-Sim per-worker expansion assume building targets; representation of Exploration-Task (off-grid, "gone for the season") and Standing-Assignment (tile/rectangle) workers is undefined. (§2 G-S3, §4 CS3 — `03` "Worker Roster (UI)", "Assigned-worker Mid-Sim depiction" vs `05` "Standing Assignments", "Exploration Tasks")

### Should-fix

- **SF1.** Specify the modifier-combination rule for the Site Panel's "one combined number" (additive vs. multiplicative across Effort/Experience/Aptitude/Storied/Alien Soil/Fertilizer/Hybridization) and what a plant-crop building shows given its 3-phase cycle (one number or per-phase). (§4 CS2 — `03` "Site Panel (UI)"; `05` "Aptitude"; `04` "Farm/Production")
- **SF2.** Define per-building worker-eligibility enforcement at the worker slot and the "why rejected" messaging (drone→settler-only; Basic drone→Survey/Trapping/HTC; Research settler-only; whether a group-matched Specialized drone qualifies for that Standing Assignment). (§4 CS6, §6 P2 — `03` "Assignment"; `04` "Robotics Assembly"; `05` "Standing Assignments")
- **SF3.** Define whether a worker can be pre-assigned to a queued (not-yet-built) building, and whether a fresh site is idle its first season. (§2 G-S4 — `03` "Construction", "Assignment")
- **SF4.** Add a static (non-motion) cue for the Mid-Sim roster "idle / not working" state. (§6 P1 — `01` "colour is never the sole channel"; `03` "Worker Roster (UI)")
- **SF5.** Give drone-staffed sites a planning-phase signal that a battery recharge may stall output mid-sim. (§4 CS4, §6 P3 — `03` "Site Panel (UI)"; `04` "Robotics Assembly")
- **SF6.** Specify which concrete worker a type-row roster drag assigns when A > 1, and how the player targets a specific settler. (§2 G-S6, §3 IC4 — `03` "Worker Roster (UI)", "Assignment")
- **SF7.** Decide whether construction robots get a Worker Roster row (surfacing remaining N actions) or a separate budget indicator. (§4 CS5 — `03` "Construction", "Worker Roster (UI)")
- **SF8.** If Effort-stacking survives B1, the Site Panel must show the cap and current headroom ("1.4 / 2.0 Effort"), not just the resulting rate. (§7 — `03` "Site Panel (UI)", "Assignment")
- **SF9.** Define the unassign / send-to-idle gesture. (§2 G-S5 — `05` "Settler State"; `03` "Assignment")

### Nice-to-have

- **NTH1.** Let the player see which specific settler is stickily defaulted to which site during planning without opening each Site Panel. (§3 IC3, §6 P4 — `03` "Worker Roster (UI)", "Site Panel (UI)")
- **NTH2.** Give the spread-thin-vs-concentrate tradeoff an in-fiction line if B1 keeps it. (§5)
- **NTH3.** Clarify whether the illustrative self-growing-Bakery combo-building staffing exception is a planned catalogue entry or illustrative-only (it has no `04` instance and depends on the unresolved auto-alternative-output idea). (§2 — `03` "Assignment", "Production Model")

### Defer (numeric / content-pass)

- **D1.** Per-site production-cap values by building/tier (if B1 keeps the mechanic). `03` "Assignment"; `04` "Building Schema".
- **D2.** Drone battery capacity, drain rate, recharge duration per tier. `04` "Robotics Assembly".
- **D3.** Storied `legend_value` threshold (already in `DESIGN_TODO.md`). `05` "Storied".
- **D4.** Temperature-deviation → battery-drain curve. `04` "Robotics Assembly".
