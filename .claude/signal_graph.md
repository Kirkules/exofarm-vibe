# ExoFarm Signal Graph

Directed graph of all Godot signal connections in the project.
Format: `EMITTER.signal(args) → RECEIVER.handler` or `EMITTER → EventBus.signal → [RECEIVERS]`

Last updated: 2026-04-11

---

## Direct Signals

### GameGrid (base) — emitted by FarmGrid, KitchenGrid, SettlerFoodGrid instances

```
GameGrid.piece_picked_up_from_grid(piece_id, shape)
  FarmGrid    → BuildingManager._on_piece_picked_up_from_grid
  KitchenGrid → KitchenManager._on_piece_picked_up(kg, cid, pid, shape)  [closure per cafeteria]
  SFGrid[i]   → SettlerManager._on_piece_picked_up(g, i, pid, shape)     [closure per settler]

GameGrid.piece_placed_on_grid(piece_id)
  FarmGrid    → BuildingManager._on_piece_placed_on_grid
  KitchenGrid → KitchenManager._on_piece_placed(cid, pid)                [closure per cafeteria]
  SFGrid[i]   → SettlerManager._on_piece_placed(i, pid)                  [closure per settler]

GameGrid.piece_returned_to_grid(piece_id)
  FarmGrid    → BuildingManager._on_piece_returned_to_grid
  KitchenGrid → KitchenManager._on_piece_placed(cid, pid)                [closure; same as placed]
  SFGrid[i]   → SettlerManager._on_piece_placed(i, pid)                  [closure; same as placed]

GameGrid.inventory_item_pickup_confirmed(item)
  FarmGrid    → BuildingManager._on_inventory_item_pickup_confirmed
  KitchenGrid → KitchenManager._on_inventory_item_pickup_confirmed(item) [closure per cafeteria]
  SFGrid[i]   → SettlerManager._on_inventory_item_pickup_confirmed(item) [closure per settler]

GameGrid.piece_released(com_screen_pos)
  FarmGrid    → BuildingManager._on_piece_released
  KitchenGrid → KitchenManager._on_piece_released(cid)                   [closure per cafeteria]
  SFGrid[i]   → SettlerManager._on_piece_released(i)                     [closure per settler]

GameGrid.piece_double_tapped(piece_id)
  FarmGrid    → BuildingManager.toggle_piece

GameGrid.piece_long_pressed(piece_id)
  FarmGrid    → BuildingManager._on_piece_long_pressed

KitchenGrid.piece_ejected(piece_id)
  KitchenGrid → KitchenManager._on_piece_ejected(cid, pid)               [closure per cafeteria]

SettlerFoodGrid.piece_placed_on_grid  → self._update_paste_label   [internal]
SettlerFoodGrid.piece_picked_up_from_grid → self._update_paste_label [internal]
SettlerFoodGrid.piece_returned_to_grid → self._update_paste_label   [internal]
```

### BuildingManager → game.gd

```
BuildingManager.power_changed(placed)          → game._on_power_changed
BuildingManager.piece_released_off_farm(item, build_state, com_screen_pos)
                                               → game._on_piece_released_off_farm
BuildingManager.cafeteria_long_pressed(piece_id) → game._on_cafeteria_long_pressed
BuildingManager.piece_picked_up_from_farm()    → game._on_piece_picked_up_from_farm
```

### SimulationController → game.gd

```
SimulationController.finished()   → game._end_simulation
SimulationController._sim_timer.timeout → SimulationController._on_timer_finished  [internal]
```

### SettlerManager → game.gd

```
SettlerManager.assignments_changed → game._refresh_food_hud
```

### HudUI → game.gd

```
HudUI.next_season_pressed          → game._on_next_season_pressed
HudUI.settler_label_tapped         → game (lambda: toggle settler panel)
HudUI.settler_panel_layout_changed → game (lambda: reposition SettlerFoodGrid nodes)
```

### InventoryUI → game.gd

```
InventoryUI.item_requested(item)   → game._on_item_requested
InventoryUI.state_changed(collapsed) → game._on_inventory_state_changed
```

### BuildMenu → game.gd

```
BuildMenu.building_requested(def)  → game._on_building_requested
```

### Inventory (data model) → InventoryUI

```
Inventory.changed  → InventoryUI._refresh
```

### ConfirmDialog → game.gd

```
ConfirmDialog.confirmed  → game._begin_simulation
```

---

## EventBus Signals

### Emitters

```
SimulationController.begin()     → EventBus.simulation_started.emit()
game._end_simulation()           → EventBus.simulation_ended.emit()
HudUI._open_log()                → EventBus.log_overlay_opened.emit()
HudUI._close_log()               → EventBus.log_overlay_closed.emit()
KitchenManager.open(cid)         → EventBus.merge_grid_opened.emit(kg)
KitchenManager.close()           → EventBus.merge_grid_closed.emit()
SettlerManager.open()            → EventBus.merge_grid_opened.emit(_settler_grids[0])
SettlerManager.close()           → EventBus.merge_grid_closed.emit()
```

### Receivers

```
EventBus.simulation_started   → GameGrid (all instances): set_planning_locked(true)
EventBus.simulation_ended     → GameGrid (all instances): set_planning_locked(false)
EventBus.log_overlay_opened   → GameGrid (all instances): set_planning_locked(true)
EventBus.log_overlay_closed   → GameGrid (all instances): set_planning_locked(false)
EventBus.merge_grid_opened(g) → GameGrid (all instances): set_planning_locked(true) if self != g
EventBus.merge_grid_closed    → GameGrid (all instances): _on_merge_grid_closed()
                                  KitchenGrid override: suppresses restore
                                  SettlerFoodGrid: reactivates if currently visible
```

---

## EventBus Stubs (declared, no active connections as of 2026-04-11)

```
EventBus.piece_placed(piece_id, row, col)   — unused
EventBus.piece_removed(piece_id)            — unused
EventBus.piece_picked_up(piece_id)          — unused
EventBus.season_confirmed()                 — unused
EventBus.simulation_complete()              — unused
EventBus.morale_changed(new_value)          — unused
EventBus.settler_count_changed(new_count)   — unused
```

---

## Notes

- All `GameGrid` subscriptions to EventBus are wired in `GameGrid._ready()`, so every subclass
  instance (FarmGrid, KitchenGrid, SettlerFoodGrid) subscribes automatically.
- KitchenGrid and SettlerFoodGrid subscriptions to their own `piece_*` signals are wired
  via closures in `KitchenManager._wire_kitchen_grid(kg)` and
  `SettlerManager._wire_settler_grid(g, i)` at creation time.
- `SFGrid` = SettlerFoodGrid instance (one per settler, indexed by `i`).
- `cid` = cafeteria piece_id used as key in KitchenManager dicts.
