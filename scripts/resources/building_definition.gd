class_name BuildingDefinition
extends PlaceableDefinition

## Resource for buildings: fixed structures that produce resources and interact
## with the power system. Buildings are non-moveable by default.
##
## Production values are per-season outputs during the simulation phase.

## Energy units produced per season. Also the amount this building contributes
## to its power network's shared pool.
@export var energy_production: int = 0
## Matter units produced per season.
@export var matter_production: int = 0
## Manhattan-distance radius this building broadcasts power.
## 0 = not a power source.
@export var power_range: int = 0
## Energy units drawn from the connected power network per season.
## 0 = this building does not consume power.
@export var power_draw: int = 0
