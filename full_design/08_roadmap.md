# Roadmap

## Development Phases

### Phase 0 — Foundation
- [x] Project structure and scene organization
- [x] Core grid data model (cells, polyomino piece shapes, rotation logic)
- [x] Grid rendering with placeholder visuals (colored rectangles)
- [x] Piece placement, rotation, and removal input handling
- [x] Inventory data model and UI (collapsed/partial/full panel; drag-to-pick-up from
  inventory with 16px-drag or 0.5s-hold threshold; drop-to-inventory via sprite CoM
  detection; snap-back to original grid position on invalid drop; 32×32 piece icons)
- [x] Mouse/desktop input parity (left-click = tap, right-click-while-dragging = rotate)
- [x] Basic field-of-effect overlay system (shown while dragging; Manhattan distance radius
  per piece; toggleable per-piece via effect_range property)

### Phase 1 — Core Planning Loop
- [x] Initial set of placeable element types (GreenhouseDefinition class; Wheat/Tomato/Eggplant
  Greenhouses in build menu; 1×1 crop pieces, yield_per_season=1; separate
  PlaceableDefinition instances for Wheat/Tomato/Eggplant crop items as harvest output)
- [x] Resource system (Energy + Matter, seasonal regeneration; production computed from
  placed active buildings; HUD shows stored/capacity/+production; overflow warning on
  Next Season)
- [x] Power system: broadcast range, network formation, shared pool, binary power state
- [x] Building on/off toggle (double-tap on fixed building)
- [x] Neighbor effect calculation engine (NeighborSystem.compute(); effects not yet
  applied to simulation output)
- [x] Visual synergy and coverage indicators during planning (permanent effect-range
  overlay for placed pieces with effect_range > 0, dimmer shade than drag preview;
  power overlay refactored into shared _refresh_overlays() path)
- [x] Power range visual overlay during planning (placed buildings + hold preview)
- [x] "Proceed to Next Season" confirmation and lock-in (buildings lock in on Next Season;
  conditional dialog warns when Energy or Matter production would overflow storage)
- [x] Moveable vs. fixed piece distinction (all pieces moveable during planning; buildings
  lock to moveable=false on Next Season confirmation; upgrade hook deferred)
- [x] UNBUILT/BUILT building state: UNBUILT buildings (placed from build menu) flash and
  can be moved; if dropped off-grid they are discarded; transition to BUILT at season
  confirmation (stop flashing, lock moveable, enable toggle)
- [x] Build menu: shown below the grid when inventory is collapsed; lists buildable
  definitions; tapping begins the hold-to-place flow onto the grid as an UNBUILT building
- [x] HUD tooltips: press-and-hold Energy label shows per-building energy deltas; same
  for Matter label (includes stored amount); colored deltas (#88ee88 positive, #ee8888
  negative) used consistently throughout HUD

### Phase 2 — Season Simulation
- [ ] Season resolution logic (crop yield, resource consumption, weather events)
- [ ] Animated simulation playback with outcome log
- [x] Playback speed controls (1×, 2×, 3×, 5×)
- [x] Settler food consumption and starvation check (Nutrient Paste auto-queue from
  powered Matter Manipulator; shortfall → settler death; confirmation dialog; per-settler
  fed/starving tracking; colony-lost condition when all settlers die)
- [x] Morale calculation (fresh each season from inputs); hidden happiness accumulator in GameState for end-of-run score
- [x] Cafeteria building: merge space (KitchenGrid) + consumption area UI (SettlerFoodGrid
  per-settler meal assignment panel; meals draggable across slots; HUD reflects savings)
- [x] Meal item crafting data: RecipeDefinition populated ({2 Wheat}→Pasta,
  {2 Tomato}→Tomato Sauce, {1 Pasta+1 Tomato Sauce+1 Eggplant}→3 Pasta alla Norma);
  MealDefinition extends PlaceableDefinition with nutrient_value + morale_modifier
- [ ] Recipe execution during simulation (actually run recipes in KitchenGrid at sim time)
- [ ] Exploration task resolution (outcome roll, Morale modifier, windfall delivery,
  site reveal conversion)

### Phase 3 — Run Structure & Progression
- [ ] Exploration task pool generation (every 3rd season, count/quality by planet type)
- [ ] Settler assignment UI for exploration tasks during planning phase
- [ ] Run start: planet setup, fixed terrain, settler names, starting resources
- [ ] Planet-side material deposits and extraction
- [ ] Resource-gated design unlocking within a run
- [x] Critical failure detection and early run end (colony lost + season 15 + player-initiated via settings)
- [x] End-of-run Mission Report popup (settler roster, food/nutrition, production, assessment; saved to disk immediately)
- [x] Earth hub: home screen (continue/new run CTA, settings, catalog, history); run history screen; catalog stub; settings screen (with in-run End Mission option); new-run interstitial popup
- [ ] In-progress run save/load: SaveData Resource subclass saved to user:// via
  ResourceSaver; save after every meaningful planning action and on app pause
  (NOTIFICATION_APPLICATION_PAUSED); load on app start if save exists; this establishes
  the persistence paradigm for all future run-state additions

### Phase 4 — Meta-Progression & Content
- [ ] New design unlocking via novel resource discovery (cross-run)
- [ ] Multiple exoplanet types with distinct properties
- [ ] Full initial set of buildings, crops, and modules
- [ ] Cafeteria building content: meal recipes, crop and animal output items
- [ ] Earth hub fleshed out

### Phase 5 — Polish
- [ ] Sound effects and music
- [ ] Visual feedback (animations, particles, transitions)
- [ ] Art pass (replace placeholder graphics)
- [ ] Balancing and playtesting
- [ ] Main menu, settings, save/load
