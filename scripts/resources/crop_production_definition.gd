class_name CropProductionDefinition
extends BuildingDefinition

## Intermediate resource for buildings that produce crops via settler labor.
## Subclass this for each crop-production building type (e.g. GreenhouseDefinition).
##
## During season simulation, settlers walk from the Solar Rig to this building to tend
## it. Each tending resets the tend_interval timer. After tend_per_yield tending
## operations the building produces one output item.

## Seconds between tending needs. Timer resets when a settler arrives and tends.
@export var tend_interval: float = 3.0
## Number of tending operations required to produce one output item.
@export var tend_per_yield: int = 3
