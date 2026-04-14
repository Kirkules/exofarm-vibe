# ExoFarm Virtual/Override Map

Project-defined virtual methods and Godot built-in virtual overrides across all classes.
Last updated: 2026-04-11

---

## Project-Defined Virtual Methods

Methods declared in base classes intended for subclasses to override.

### GameGrid — three overridable methods

| Method | Declared in | FarmGrid | KitchenGrid | SettlerFoodGrid |
|--------|-------------|----------|-------------|----------------|
| `_draw_grid_overlays()` | GameGrid | ✓ power + effect overlays | ✓ inactive cell shading | — |
| `_can_place_at_cell(cell) → bool` | GameGrid | — | ✓ active cells only | — |
| `_on_merge_grid_closed()` | GameGrid | — | ✓ suppresses grid restore | ✓ reactivates if visible |

---

## Godot Built-in Virtual Overrides

✓ = non-trivially implemented; — = not present

| Class | `_ready` | `_process` | `_draw` | `_input` | `_unhandled_input` | `_notification` |
|-------|----------|-----------|---------|----------|-------------------|----------------|
| Game | ✓ wires managers | — | — | — | ✓ closes panels on outside press | — |
| BuildingManager | — | — | — | — | — | — |
| KitchenManager | — | — | — | — | — | — |
| SettlerManager | — | — | — | — | — | — |
| SimulationController | ✓ builds UI | ✓ ticks sim | — | — | — | — |
| GameGrid | ✓ wires EventBus | ✓ flash timer | ✓ draws cells/sprites | ✓ all drag/tap input | — | — |
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
- `KitchenGrid._on_merge_grid_closed()` intentionally suppresses the default GameGrid restore behavior (which would re-show the grid after any merge grid closes)
- `SettlerFoodGrid._on_merge_grid_closed()` reactivates the grid only if it is currently visible — prevents ghost reactivation when the settler panel is closed
- `GameGrid._process()` drives the flashing animation for UNBUILT pieces via a timer accumulator
- When adding a new GameGrid subclass, check all three project virtuals and decide whether each needs an override
