class_name BuildingDefinition
extends PlaceableDefinition

## Resource for buildings: fixed structures that produce resources and interact
## with the power system. Buildings are non-moveable by default.
##
## Production values are per-season outputs during the simulation phase.
## Power fields will be populated when the power system is implemented.

## Energy units produced per season (if this building is a power source).
@export var energy_production: int = 0
## Matter units produced per season.
@export var matter_production: int = 0
