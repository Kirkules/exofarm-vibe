class_name GreenhouseDefinition
extends BuildingDefinition

## Resource for greenhouse pieces: moveable powered structures that produce crop
## items during season simulation.
##
## Greenhouses extend BuildingDefinition so they participate in the power system
## (power_draw > 0). They default to moveable=true so BUILT greenhouses can still
## be rearranged on the grid, unlike fixed buildings (Solar Rig, etc.).

## Number of output items produced per season when the greenhouse yields normally.
@export var yield_per_season: int = 1
## The item definition placed into inventory as output each season.
@export var output_item: PlaceableDefinition
