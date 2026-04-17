# ExoFarm Dependency Graph

Directed edges: `A → B` means A holds a typed reference to, instantiates, or calls methods/properties on B.
Godot built-in types excluded. Autoload edges included.
Last updated: 2026-04-17

---

## Edges

```
Game →
  PieceInputController, BuildingManager, KitchenManager, SettlerManager, SimulationController,
  FarmGrid, InventoryUI, HudUI, BuildMenu, Inventory,
  PlaceableDefinition, PieceShape, InventoryItem,
  RecipeDefinition, MealDefinition, GreenhouseDefinition, CafeteriaDefinition,
  KitchenGrid, Settler,
  GameState, EventBus

PieceInputController →
  GameGrid, PieceShape, PieceSpriteGenerator,
  Settings

BuildingManager →
  PieceInputController, FarmGrid, Inventory, InventoryItem, PlaceableDefinition, PieceShape,
  PowerSystem, NeighborSystem, BuildingDefinition, CafeteriaDefinition,
  GameState

KitchenManager →
  PieceInputController, FarmGrid, Inventory, InventoryUI, KitchenGrid,
  InventoryItem, RecipeDefinition, PlaceableDefinition, CafeteriaDefinition

SettlerManager →
  PieceInputController, FarmGrid, Inventory, InventoryUI, HudUI, SettlerFoodGrid,
  InventoryItem, PlaceableDefinition, Settler,
  GameState

SimulationController →
  FarmGrid, Inventory, HudUI, PowerSystem,
  GreenhouseDefinition, CafeteriaDefinition, InventoryItem,
  RecipeDefinition, Settler, PlaceableDefinition,
  GameState, EventBus

FarmGrid →
  GameGrid

HudUI →
  Settler,
  GameState, EventBus

InventoryUI →
  Inventory, InventoryItem, PlaceableDefinition, PieceShape, PieceSpriteGenerator

BuildMenu →
  PlaceableDefinition, PieceShape, PieceSpriteGenerator

KitchenGrid →
  GameGrid, RecipeDefinition, PlaceableDefinition

SettlerFoodGrid →
  GameGrid

GameGrid →
  GridData, PieceShape, PieceSpriteGenerator, PieceInputController,
  EventBus, Settings

Inventory →
  InventoryItem

RecipeDefinition →
  PlaceableDefinition

PlaceableDefinition →
  PieceShape

GreenhouseDefinition →
  CropProductionDefinition, PlaceableDefinition

PowerSystem →
  BuildingDefinition, PlaceableDefinition

NeighborSystem →
  PlaceableDefinition, PieceShape

GameState →
  Settler

EventBus →
  GameGrid
```

---

## Notes

- **Leaf nodes** (no outgoing project-class edges): InventoryItem, PieceShape, Settler, GridData, PieceSpriteGenerator, BuildingDefinition, CafeteriaDefinition, CropProductionDefinition, MealDefinition
- **High fan-in** (referenced by many): PlaceableDefinition, InventoryItem, PieceShape, Inventory, PieceInputController — changes to these ripple widely
- **High fan-out** (references many): Game, SimulationController — these are the integration points
- Resource hierarchy edges (GreenhouseDefinition → CropProductionDefinition etc.) are `extends` relationships, not runtime references; see Resource Hierarchy in CLAUDE.md
- Catalog has no active edges — stub autoload
