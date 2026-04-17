# ExoFarm Autoload Access Map

Which classes access GameState, EventBus, Catalog, and Settings, and how.
Last updated: 2026-04-17

---

## GameState

| Class | Property | Access |
|-------|----------|--------|
| Game | `season` | read + write |
| Game | `matter` | read + write |
| Game | `settlers` | read |
| BuildingManager | `energy_capacity` | write |
| BuildingManager | `energy` | write |
| HudUI | `energy` | read |
| HudUI | `energy_capacity` | read |
| HudUI | `matter` | read |
| HudUI | `settler_count` | read |
| HudUI | `season` | read |
| HudUI | `settlers` | read |
| SimulationController | `settlers` | read |
| SettlerManager | `settlers` | read |

---

## EventBus

Signal connections are documented in full in `.claude/signal_graph.md`.
Summary of which classes emit vs. connect:

| Class | Operation | Signal(s) |
|-------|-----------|-----------|
| SimulationController | emit | `simulation_started` |
| Game | emit | `simulation_ended` |
| HudUI | emit | `log_overlay_opened`, `log_overlay_closed` |
| GameGrid (all instances) | connect | `simulation_started/ended`, `log_overlay_opened/closed` |

Note: `merge_grid_opened/closed` are no longer emitted — KitchenManager and SettlerManager
now call `set_grid_active(false/true)` and PIC registration directly instead of broadcasting via EventBus.

---

## Settings

| Class | Property | Access |
|-------|----------|--------|
| GameGrid | `drag_offset` | read (controls drag offset vector during piece hold) |

---

## Catalog

No active accesses. Stub autoload reserved for meta-progression unlock tracking.

---

## Notes

- `HudUI` is the heaviest GameState reader — it reads six properties on every `refresh()` call
- `BuildingManager` is the only class that writes `energy` and `energy_capacity` (via `recompute_power()`)
- `Game` is the only class that writes `matter` and `season`
- No class writes `settler_count` directly — it is a computed read-only property on GameState
- `settlers` array is owned by GameState but mutated during `_end_simulation()` in Game (health/morale updated via Settler object references)
