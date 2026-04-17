# ExoFarm Virtual/Override Map

Project-defined virtual methods and Godot built-in virtual overrides across all classes.
Last updated: 2026-04-17

---

## Project-Defined Virtual Methods

Methods declared in base classes intended for subclasses to override.

### GameGrid — three overridable methods

| Method | Declared in | FarmGrid | KitchenGrid | SettlerFoodGrid |
|--------|-------------|----------|-------------|----------------|
| `_draw_grid_overlays()` | GameGrid | ✓ power + effect overlays | ✓ inactive cell shading + recipe group highlights | — |
| `_can_place_at_cell(cell) → bool` | GameGrid | — | ✓ active cells only | — |
| `try_receive_drop(cursor_screen, shape, payload, hint) → int` | GameGrid | ✓ enforces FARM_GRID type | ✓ enforces KITCHEN_GRID, rejects FARM_GRID | ✓ enforces SETTLER_GRID |

---

## Godot Built-in Virtual Overrides

✓ = non-trivially implemented; — = not present

| Class | `_ready` | `_process` | `_draw` | `_input` | `_unhandled_input` | `_notification` |
|-------|----------|-----------|---------|----------|-------------------|----------------|
| Game | ✓ wires managers | — | — | — | ✓ closes panels on outside press | — |
| PieceInputController | ✓ builds held sprite layer | ✓ pending timer + drag_moved emit | — | ✓ all drag/tap input | — | — |
| BuildingManager | — | — | — | — | — | — |
| KitchenManager | — | — | — | — | — | — |
| SettlerManager | — | — | — | — | — | — |
| SimulationController | ✓ builds UI | ✓ ticks sim | — | — | — | — |
| GameGrid | ✓ wires EventBus | ✓ flash timer | ✓ draws cells/sprites | — | — | — |
| FarmGrid | — | — | — | — | — | — |
| KitchenGrid | ✓ sets up grid | — | ✓ draws background/border | — | — | — |
| SettlerFoodGrid | ✓ wires paste label | — | — | — | — | — |
| HudUI | ✓ builds UI | — | — | ✓ log overlay input | — | ✓ safe area |
| InventoryUI | ✓ builds UI | — | — | — | — | — |
| BuildMenu | ✓ builds UI | — | — | — | — | — |
| SimulationOverlay | ✓ (stub) | — | — | — | — | — |
| GameState | ✓ init state | — | — | — | — | ✓ save on quit |
| Settings | ✓ loads settings | — | — | — | — | — |

---

## Notes

- `FarmGrid._draw_grid_overlays()` calls two private helpers: `_draw_power_overlays()` and `_draw_effect_overlays()`
- `GameGrid._process()` drives the flashing animation for UNBUILT pieces via a timer accumulator
- `PieceInputController._process()` advances the pending-pickup timer and emits `drag_moved` each frame while a piece is held
- When adding a new GameGrid subclass, check all three project virtuals and decide whether each needs an override
- `_on_merge_grid_closed()` virtual was removed in the PIC refactor — panel open/close now uses `set_grid_active()` + PIC registration directly
