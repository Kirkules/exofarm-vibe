# Audit — System 8: Food & Nutrition

Design audit #8. Pure design review against `full_design/`; no implementation
exists. Citations are `file` → "Section" (no anchor links: this file sits in
`audits/` and the repo link-checker only scans `full_design/*.md`).

---

## 1. Scope & inventory

| Mechanic / rule / entity | Specified in |
|---|---|
| P/F/C/V nutrient axes — category names not units; every food item incl. Rations carries a profile; visible in tooltip | `05` "Nutrient Axes" |
| Rations — fixed non-replenishable starting stock; no auto-replenishment; replaces the old Nutrient Paste safety net | `05` "Rations (Basic Sustenance)" |
| Ration Press — unstaffed instant conversion; `Rations = floor(min(P,F,C,V across selected inputs) / 2)`; imbalance beyond the matched minimum discarded; repeatable in a planning phase, no cap | `05` "Rations"; `04` "Ration Press" |
| Meals — produced at ordinary staffed single-conversion sites; recipe + nutrient profile; no secondary effects (morale cut); do not expire | `05` "Meals" |
| Pooled settlement-level consumption — not per-settler; e.g. 4 settlers → pooled 4/4/4/4; evaluated "as a whole" | `05` "Consumption — Pooled, Not Per-Settler" |
| Pooled headcount counts only settlers present that season; exploring settlers excluded (covered by their task's strict Ration cost) | `05` "Consumption — Pooled"; `05` "Exploration Tasks" — Assignment |
| Food-for-consumption assigned in planning; 4-step intelligent default ladder (last season's types → those + Rations top-up → Rations only → nothing) | `05` "Consumption — Pooled" |
| Sticky diet — a stable diet continues with no action; player can always override in planning | `05` "Consumption — Pooled" |
| Tier 1 — bulk shortfall → settler deaths; who dies drawn uniformly at random ("drawing lots"); confirmation dialog gates a planned-death season | `05` "Rations"; `05` "Consumption — Pooled" |
| Tier 2 — axis imbalance with bulk covered → no in-run consequence, score-only | `05` "Consumption — Pooled" |
| No penalty for excess; surplus accumulates in shared inventory | `05` "Consumption — Pooled" |
| Kitchen — deviates from the standard multi-recipe pattern: N independently-staffed simultaneous recipe slots; footprint = slot count (base 1 / Upgraded 2) | `04` "Kitchen" |
| Base recipes — 4 single-ingredient meals covering the four axes (Bread/Fruit dish/Dairy dish/Egg dish) | `04` "Kitchen" |
| Upgraded recipes — fixed set of combo meals (Sandwich/Pasta Dish/Fruit Pastry/Custard Dish), fixed ingredient lists, cosmetic flavor-name pools | `04` "Kitchen" |
| Gourmet tier — settler-specific: maxed Kitchen Experience (3 stacks) + a Seasoning in inventory → per-season "moment of brilliance" roll → that settler's personal recipe; only they cook it, only while assigned to Kitchen; feeds `TechAchievement` | `04` "Kitchen"; `05` "Experience" |
| Local Delicacy — recipe unlocked by a Peaceful Contact alliance; ingredient supplied via a Trade Agreement; name/flavor/input cost tied to civ class + planet | `04` "Kitchen"; `05` "Escalation Chains" |
| Meal-expiration — deliberately deferred open question | `04` "Kitchen" blockquote; `DESIGN_TODO.md` |
| Food Storage — unstaffed; deposit is reversible until season confirm, then **removed from the usable pool for the rest of the run**; identity discarded, only summed nutrient value retained; uncommitted inventory food contributes nothing | `04` "Food Storage"; `03` "Season Structure" (Planning Lock-in) |
| Food Storage capacity — real, limited (nutrient-value units); deliberately can't reach max `NutritionStockpile` unupgraded | `04` "Food Storage" |
| End-of-run Food Security score — `normalize(NutritionStockpile) + normalize(NutritionIncome)`; `NutritionStockpile = Σ sqrt(stockpiled amount)` over four axes; `NutritionIncome` = linear avg production rate over the last 5 seasons | `05` "End-of-Run Food Security Score"; `06` "SEED Factions" (Sustenance Bloc) |
| Starvation = a critical-failure (early-end) condition | `06` "Win / Lose Conditions" — Critical Failure |
| Pooled nutrition consumption resolves at Post-Sim sub-step (3), before Trade Agreement resolution | `03` "Season Structure" |

**Boundary notes (ambiguous ownership).**
- **Kitchen as a production site** — meal `production_time`, whether effort-stacking applies to a Kitchen slot, and how Aptitude/Experience/Storied speed a slot are Production-Model (#4) / Worker-Assignment (#3) questions that land on meals. This audit covers the *recipes and nutrient side*; the *conversion mechanics* sit with #4.
- **Rations as an exploration cost** — the strict Rations-only requirement and its consumption timing belong to Exploration (#10); this audit covers Rations' production and the headcount exclusion.
- **`NutritionIncome` production measurement** — shares a definition with Development Bloc's `ResourceIncome` (#7 / Scoring).
- **Seasonings supply** — the incidental-drop economy gating Gourmet is System #7.
- **Local Delicacy sourcing** — the Trade Agreement mechanism is System #10.

---

## 2. Completeness gaps

### Structural (blocks implementation / forces a fresh design decision)

- **G-S1. The Tier-1 bulk-shortfall test is never defined in units.** `05` "Rations" triggers deaths when "total available nutrition (Rations plus any meals) can't cover the settler headcount at all"; `05` "Consumption — Pooled" evaluates "1 Bread + 1 Apple + 2 Milk (… = 3/3/5/5)" against "a pooled 4/4/4/4 … as a whole" and files the Protein/Fat shortfall as *Tier 2 (soft)*. That only works if Tier 1 is a **summed-mass test** (Σ over 4 axes ≥ 4 × headcount), but the design never says so, and "cover the headcount at all" reads equally as a per-axis or per-settler-minimum test — which would make the same example a *death*. Blocks the death trigger. *Possible direction: state Tier 1 as `Σ(available across 4 axes) ≥ 4 × present-headcount`; per-axis coverage is purely Tier 2.*
- **G-S2. How many settlers die on a Tier-1 shortfall is unspecified.** `05` "Rations" says deaths happen and who is random; not how many (proportional to the gap? feed-as-many-as-possible and the rest die?). *Possible direction: feed `floor(Σ available / 4)` settlers; the remainder die; drawing lots selects them.*
- **G-S3. Gourmet dishes have no defined Input/Output.** `04` "Kitchen" gives Gourmet no ingredient list, nutrient profile, or `production_time`, and doesn't say whether the required Seasoning is consumed by the roll, by cooking the dish, or is a passive stock check for both. Recipe is unimplementable as written. *Possible direction: Gourmet dish = its Seasoning + one base ingredient → a meal with a premium PFCV profile; Seasoning consumed per cook, not per roll.*
- **G-S4. Local Delicacy has no defined Input/Output either** — "name, flavor, and exact input cost … tied to the specific planet type and civilization class," all TBD, and its ingredient supply is gated on Trade Agreements (#10). Structural recipe mechanics (nutrient profile, `production_time`, one slot or its own) are undefined beyond "a second, separate new recipe." (`04` "Kitchen")
- **G-S5. Ration Press timing vs. same-season production is unstated.** `04` "Ration Press": output "available the same season — including for exploration tasks being planned that same season." But this season's crops/meals aren't available until Post-Sim (`03` "Season Structure" — "food produced during the season should itself be consumable that same season"), and an exploring settler's Rations are "consumed at season-simulation-start." So Ration Press can only convert food that existed at planning start. Probably intended; not said. *Possible direction: state Ration Press consumes only food present at the start of the planning phase.*
- **G-S6. "Food type" is undefined for the sticky-diet default.** `05` step 1 keys on "the food types consumed last season" — item id, or category (any meal / any crop)? Do flavor-name variants of one combo meal count as one type? Determines whether the default actually sticks as the production mix shifts. *Possible direction: type = specific recipe/item id; a combo meal's flavor-name variants are one type.*
- **G-S7. Food-for-consumption selection granularity / UI is undefined.** `05` and `04` "Food Storage" both say they "reuse the existing 'assign food' planning-action pattern" — a superseded mobile-design mechanic (per-settler meal grids) that no longer exists in `full_design/`. There is no current spec for how the player earmarks food for consumption or for deposit. *Possible direction: a per-type quantity earmark; the rest stays in general inventory.*

### Numeric (deferred to balancing — catalogued only)

- **G-N1.** Starting Rations quantity. `05` "Rations". (Load-bearing: with the auto-regen safety net gone, this single number decides whether a run can reach first food production at all.)
- **G-N2.** PFCV profiles for the full food catalog (only Bread/Apple/Milk/Rations given as illustrative). `05` "Nutrient Axes".
- **G-N3.** Combo-meal PFCV profiles; Gourmet / Local Delicacy profiles. `04` "Kitchen".
- **G-N4.** Gourmet "moment of brilliance" chance (illustrative 75%). `04` "Kitchen".
- **G-N5.** Food Storage capacity (base + per upgrade tier). `04` "Food Storage".
- **G-N6.** `NutritionStockpile` sqrt-flattening function; `NutritionIncome` 5-season window / any constant. `05` "End-of-Run Food Security Score".
- **G-N7.** Ration Press construction cost. `04` "Ration Press".

### Cross-check with `DESIGN_TODO.md`

Currently flagged, touching this system: meal-expiration deferral (`04` blockquote, echoed in TODO); Sustenance Bloc numerics; Alien-trade / Local Delicacy sourcing (resolved structurally, numeric TBDs remain). **Not** flagged: G-S1 (Tier-1 threshold definition), G-S2 (death count), G-S3/G-S4 (Gourmet & Local Delicacy recipe mechanics), G-S6 ("food type"), G-S7 (selection UI). Recommend adding.

---

## 3. Internal consistency

- **IC1. Worked example vs. rule text.** The 3/3/5/5-vs-4/4/4/4 example is filed as Tier 2 (no consequence); a literal reading of "can't cover the settler headcount at all" makes an axis-short season a Tier-1 death. The summation rule must be stated so example and rule can't diverge. (→ G-S1.)
- **IC2. Tier-1 enumeration omits raw food.** `05` "Rations" writes the death test as "total available nutrition (Rations plus any meals)"; `05` "Consumption — Pooled" feeds settlers "1 Bread + 1 Apple + 2 Milk" — Apple/Milk are raw, not meals. Raw ingredients clearly feed settlers, but the Tier-1 sentence doesn't say so.
- **IC3. "assign food" pattern references a deleted mechanic.** `04` "Food Storage" and `05` "Consumption — Pooled" both lean on "the existing 'assign food' planning-action pattern" (the superseded per-settler SettlerFoodGrid). No such pattern exists in the current design. (→ G-S7.)
- **IC4. Process/history narration.** `05` "Rations" ("Replaces the old Nutrient Paste mechanic…", "the original mechanic, unchanged"); `05` "Meals" ("the old Morale-related meal effects … no longer apply, since Morale has been cut"); `04` "Kitchen" Gourmet ("unlike every other recipe in this design, it isn't a settlement-wide unlock"). Disallowed by `01` "Design docs describe the current design, not its history."

---

## 4. Cross-system consistency

- **CS1. Exploring-settler Rations vs. Ration Press (→ SF).** `05` Assignment consumes the settler's Ration cost "at season-simulation-start"; `04` Ration Press produces "the same season" during planning. Consistent only if Ration Press draws on pre-planning stock (G-S5) — confirm the Rations a settler carries can be pressed and reserved in the same planning phase.
- **CS2. Nutrition headcount vs. mid-Mid-Sim deaths (#9 / #11) (→ SF).** Pooled headcount = "settlers present that season"; nutrition resolves at Post-Sim sub-step (3). But `06` "In-Simulation Hazard Events" can kill a settler mid-Mid-Sim (Temperature Extremity extreme). The food-for-consumption plan was fixed at Planning Lock-in against the planning-phase headcount. Unspecified: whether the Post-Sim headcount is re-evaluated after hazard deaths, and whether a dead settler's earmarked food returns to the pool.
- **CS3. `NutritionIncome` production measurement (→ SF).** "Linear average production rate over the last 5 seasons, across the four axes" — undefined whether it's gross or net of consumption, whether a nutrient is counted at the crop stage and again at the meal stage (double count), and it must share its definition with Development Bloc's `ResourceIncome` (`06` "SEED Factions").
- **CS4. Food Storage commit at Planning Lock-in.** `03` "Season Structure" hosts "Food Storage deposits becoming committed" at Lock-in; `04` "Food Storage" says committed "once simulation runs." These agree. Note this is the game's sharpest one-way door (rest-of-run, not next-season) and leans entirely on Lock-in reading as unmistakable to the player (→ P2 / §7).
- **CS5. Kitchen conversion mechanics (#4 / #3).** Kitchen "deviates from the standard multi-recipe pattern" (N independently-staffed slots, "instead of one active recipe with effort stacking toward a shared cap"). Confirm meals still produce on the continuous-rate model, and define how a slot's worker Effort/Experience/Aptitude/Storied speed applies when there's no shared cap to stack toward.
- **CS6. Gourmet reachability depends on #7 drop rates.** Seasonings are incidental-only (Clear-Cutting / Survey / Mining / Exploration), ~2–3 Herbs + 2–3 Spices per planet, all rates TBD; Gourmet also needs 3 seasons of Kitchen Experience on one settler. The whole Gourmet sub-system's reachability is a function of System #7 numbers that don't exist yet.

---

## 5. Story & world consistency

- **Positive.** Rations as a finite countdown fits "cozy pioneering optimism, mild survival tension" far better than the old always-payable Matter tax — bounded, legible pressure, not an indefinite spiral. "Densely packed, unappetizing" and the lossy Ration Press both read as believable expedition logistics.
- **Positive.** Pooled, abstracted consumption ("no bookkeeping over which settler ate what") matches `02` "SEED's Culture, and the Player's Role" — the Herald directs at settlement altitude, not the individual meal.
- **Minor stretch (no change).** "Who dies is drawn uniformly at random / drawing lots" is a stark beat for a cozy-leaning game; the planned-death confirmation dialog is the right mitigation and satisfies `01` failure-legibility. Noted as a conscious tonal call.
- **Missed reinforcement (→ NTH3).** Nothing ties the finite starting Rations to `02` "Faster-Than-Light Travel" (expedition footprint constrained by the wormhole mass threshold). A one-line frame — Rations are heavy, only so many came through — would ground the single most important survival number in established lore.
- **Missed reinforcement (→ NTH3).** Gourmet invention and the first Local Delicacy cooked are the game's clearest "settlers building a life, not just surviving" beats and each fit a Transmission line. `02` "Settler story presence" is "deliberately minimal," so optional — but a natural fit.

---

## 6. Design-principle adherence

**Adherent — deliberate strengths:**
- *Numbers stay small* — 4 settlers × 4 axes; Food Security is kept as an inspectable sub-metric, not folded into one opaque score (`05` "End-of-Run Food Security Score").
- *Forgiving of individual mistakes, punishing of sustained neglect* — one axis-imbalanced season has no in-run cost (Tier 2); only a genuine bulk shortfall kills, and it's dialog-gated. The punishing case is sustained neglect (Rations dry, no production).
- *Difficulty from breadth of tradeoffs* — Food Storage locks food away from use to score; Ration Press trades ~half the nutrition for portability; Gourmet costs a scarce settler's Kitchen-seasons. All resource tradeoffs, no execution skill.
- *Planning phase reversible* — food-for-consumption and Food Storage deposits reversible until Lock-in.

**Risks / violations:**
- **P1 (→ SF1). Auto-queued defaults transparency bar.** `01` names *this exact mechanic* ("auto-spending Rations on basic sustenance") as the example that must be (a) obviously-correct and (b) surfaced at the very start of planning before the player acts. `05`'s 4-step ladder is the (a) logic; nothing specifies the (b) UI surface.
- **P2 (→ SF5). Failure legibility / luck-vs-certainty.** The planned-shortfall dialog covers the case the player confirms at Lock-in. A shortfall that emerges only because this season's production came in lower than the overlay implied (a hazard slowed a farm) resolves at Post-Sim with deaths the player never confirmed — the Post-Sim death resolution must clearly attribute cause.
- **P3 (→ SF9). Colour is never the sole channel.** The food-for-consumption readout and any Tier-2 "axis short" indicator will lean on red/green; a redundant cue must be on record.
- **P4 (→ NTH1). Docs describe the current design, not its history** — see IC4.
- Not engaged: units-unspecified (PFCV are category names — compliant), dexterity-timing, touch/mouse parity, normalize-before-combining (Food Security already normalizes both terms — compliant).

---

## 7. Player legibility

- **Bulk vs. axis shortfall** — legible only if the planning UI shows both "everyone fed? y/n" and "which axes are short" *before* Lock-in. Not specified (P1/P3).
- **Tier 2 has no in-run feedback** — a player can run 15 seasons never learning that axis diversity matters, until the end-of-run report. Acceptable per "inferable through play" only if the viability report breaks `NutritionStockpile` out per axis (→ NTH2).
- **Ration countdown** — a finite depleting stock with no replenishment needs a visible count and ideally a "seasons of runway at current diet" read. Not specified (→ SF8).
- **Food Storage one-way commitment** — "removed for the rest of the run" is the harshest irreversibility in the game; its deposit action needs an unmistakable confirm distinct from ordinary reversible planning (→ SF8; CS4).
- **Gourmet** — a per-settler, luck-gated, invisible-until-it-fires unlock; the player needs a signal that a settler is *eligible* so a fired "moment of brilliance" reads as earned, not random (→ SF10).
- **Next-season vs. same-season availability** — meals/crops produced this season feed this season's Post-Sim consumption; Ration Press output is available immediately. Two different timings the player must learn; worth an explicit tooltip.

---

## 8. Fun / scope risk

- **The Kitchen recipe ladder is four distinct unlock mechanisms for one building** — settlement-wide base + combo tier unlocks, per-settler luck-gated Gourmet, alliance+trade-gated Local Delicacy. Combo meals (better PFCV for a fixed ingredient list) clearly earn their place. Gourmet and Local Delicacy are both `TechAchievement`/flavor payoffs with thin mechanical distinction from "another combo meal with better numbers" — worth an explicit check they pull weight. *Cut-or-simplify candidate: Local Delicacy as one more alliance-unlocked combo recipe, unless the Trade-Agreement sourcing hook is doing narrative work worth the complexity.*
- **Food Storage as a mandatory score-gate** ("a hard requirement for any real Sustenance score") — a good forced tradeoff (lock food away vs. keep it usable) at low rule cost. Keep.
- **Ration Press** — lossy conversion for portability, single clean tradeoff. Keep.
- **Narrowing / going-inert risk** — the 4-step default is built so a stable diet needs zero action ("passable plan quick" — good). The opposite risk: if the default is always fine, food stops being a decision after the early game. Possibly intended (early pressure, then solved), but the balancing pass should confirm food production keeps competing for grid slots late, or this system goes inert mid-run.
- **Meal-expiration** — deferring it is right, but it's a latent scope grenade: adding it later would invalidate the "stockpile meals freely" assumption baked into Food Storage and the sticky-diet default.

---

## 9. Findings summary

### Blockers

- **B1.** Tier-1 bulk-shortfall test undefined in units — "can't cover the settler headcount at all" vs. the summed worked example (3/3/5/5 vs 4/4/4/4) admit different death outcomes; the death trigger is unimplementable. (§2 G-S1, §3 IC1 — `05` "Rations" / "Consumption — Pooled, Not Per-Settler")
- **B2.** How many settlers die on a Tier-1 shortfall is unspecified (proportional to the gap? feed-as-many-as-possible?). (§2 G-S2 — `05` "Rations")
- **B3.** Gourmet dishes and Local Delicacy have no defined ingredient list, nutrient profile, or `production_time`, and whether a Seasoning is consumed by the roll, by cooking, or neither is unstated — the recipes can't be built. (§2 G-S3, G-S4 — `04` "Kitchen")

### Should-fix

- **SF1.** Specify the food-for-consumption default UI surface — an inspectable "what will be eaten this season" readout shown at the very start of planning, per `01`'s auto-queued-defaults transparency bar (which names this exact mechanic). (§6 P1, §7 — `01` Design Principles; `05` "Consumption — Pooled")
- **SF2.** Reconcile the Tier-1 enumeration "Rations plus any meals" with raw crops/animal products also feeding settlers (the worked example uses Apple + Milk). (§3 IC2 — `05` "Rations" vs "Consumption — Pooled")
- **SF3.** Replace the "reuses the existing 'assign food' planning-action pattern" references (a superseded mobile-UI mechanic) with a defined selection interaction consistent with current UI conventions. (§3 IC3, §2 G-S7 — `04` "Food Storage"; `05` "Consumption — Pooled")
- **SF4.** State that Ration Press consumes only food present at the start of the planning phase (never this season's not-yet-produced output). (§2 G-S5, §4 CS1 — `04` "Ration Press" vs `03` "Season Structure")
- **SF5.** Define the Post-Sim interaction between hazard/injury deaths (Mid-Sim) and the nutrition headcount + the Lock-in-fixed food-for-consumption plan — is a dead settler's earmarked food refunded to the pool. (§4 CS2, §6 P2 — `03` "Season Structure" sub-step order; `06` "In-Simulation Hazard Events")
- **SF6.** Define "food type" for the sticky-diet default — specific item id vs. category; whether a combo meal's flavor-name variants are one type. (§2 G-S6 — `05` "Consumption — Pooled")
- **SF7.** Define the per-season production measurement feeding `NutritionIncome` (gross vs. net; crop-stage vs. meal-stage double-count) and share it with Development Bloc's `ResourceIncome`. (§4 CS3 — `05` "End-of-Run Food Security Score"; `06` "SEED Factions")
- **SF8.** Specify a visible Rations count + remaining-runway read, and an unmistakable non-standard confirm for the rest-of-run Food Storage commitment. (§7 — `05` "Rations"; `04` "Food Storage")
- **SF9.** Record the non-colour cue for the food-for-consumption / axis-short indicators. (§6 P3 — `01` Design Principles)
- **SF10.** Surface a signal that a settler is Gourmet-*eligible* (maxed Kitchen Experience + Seasoning present) so a fired "moment of brilliance" reads as earned. (§7 — `04` "Kitchen"; `05` "Experience")

### Nice-to-have

- **NTH1.** Fold history/change narration out of `05` "Rations" / "Meals" and `04` Kitchen's "unlike every other recipe in this design", per `01` "describe the current design, not its history". (§3 IC4)
- **NTH2.** Ensure the end-of-run viability report breaks `NutritionStockpile` out per axis so the Tier-2 diversity lesson is legible retrospectively. (§7)
- **NTH3.** Tie the finite starting Rations to the mass-constrained wormhole-transit fiction; optionally give Gourmet invention / the first Local Delicacy a Transmission line. (§5)
- **NTH4.** Consider collapsing Local Delicacy into an alliance-unlocked combo recipe unless the Trade-Agreement sourcing hook earns its complexity. (§8)

### Defer (numeric / content-pass)

- **D1.** Starting Rations quantity (load-bearing for early-game survival pressure). `05` "Rations".
- **D2.** PFCV profiles for the full food catalog; combo-meal profiles; Gourmet / Local Delicacy profiles. `05` "Nutrient Axes"; `04` "Kitchen".
- **D3.** Gourmet "moment of brilliance" chance (illustrative 75%). `04` "Kitchen".
- **D4.** Food Storage capacity per tier; Ration Press construction cost. `04` "Food Storage" / "Ration Press".
- **D5.** `NutritionStockpile` flattening function; `NutritionIncome` window / constant. `05` "End-of-Run Food Security Score".
- **D6.** Meal-expiration open question (already in `DESIGN_TODO.md`). `04` "Kitchen".
