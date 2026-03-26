class_name CropDefinition
extends PlaceableDefinition

## Resource for crop greenhouse pieces: moveable grid elements that produce crop items
## during season simulation.
##
## Greenhouses do not interact with the power system directly. They may have an
## effect_range on their shape to define neighbor interactions (e.g. synergy with
## adjacent greenhouses, or coverage from a weather-protection building).

## Number of output items produced per season when the crop yields normally.
@export var yield_per_season: int = 1
## The item definition placed into inventory as output each season.
@export var output_item: PlaceableDefinition
