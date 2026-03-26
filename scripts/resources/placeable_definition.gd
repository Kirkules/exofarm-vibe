class_name PlaceableDefinition
extends Resource

## Base resource for all placeable grid elements (buildings, crops, modules, etc.).
## Subclass this for each category of placeable; add type-specific fields there.

## Display name shown in the inventory and on tooltips.
@export var display_name: String = ""
## The polyomino shape and visual properties of this piece.
@export var shape: PieceShape
## Number of inventory slots this item occupies.
@export var slot_size: int = 1
## If false, the piece cannot be picked up from the grid during planning.
## Buildings are fixed by default; other placeables are moveable.
@export var moveable: bool = true
## Matter spent when this piece transitions from UNBUILT to BUILT at season confirmation.
## 0 = no construction cost.
@export var matter_cost: int = 0
## Which grid UIs this item may be placed on.
## Use PlaceableDefinition.GridType values. Defaults to farm grid only.
enum GridType { FARM_GRID, KITCHEN_GRID }
@export var allowed_grids: Array[int] = [GridType.FARM_GRID]
