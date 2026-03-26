class_name GreenhouseDefinition
extends CropProductionDefinition

## Resource for greenhouse pieces: moveable powered structures that produce crop
## items during season simulation via settler labor.
##
## Greenhouses extend CropProductionDefinition so they participate in the power
## system (power_draw > 0) and the settler tending system (tend_interval,
## tend_per_yield). They default to moveable=true so BUILT greenhouses can still
## be rearranged on the grid, unlike fixed buildings (Solar Rig, etc.).

## The item definition placed into inventory after tend_per_yield tending operations.
@export var output_item: PlaceableDefinition
