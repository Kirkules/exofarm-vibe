class_name RecipeDefinition
extends Resource

## Defines a crafting recipe: a multiset of ingredients → one or more output meal items.
##
## ingredients: Dictionary mapping PlaceableDefinition → int (quantity required).
##              Treat as a multiset — the same item type may appear more than once.
## output_item: the MealDefinition produced by one execution of this recipe.
## output_count: how many copies of output_item are produced per execution.
## labor_cost: seconds a settler must spend at the crafting station per execution.
##
## RecipeDefinition is intentionally decoupled from any specific building type;
## any crafting building can reference and execute recipes.

## Multiset of required ingredients: PlaceableDefinition → quantity (int).
var ingredients: Dictionary = {}
## The meal produced by this recipe.
var output_item: MealDefinition = null
## Number of output_item copies produced per craft execution.
var output_count: int = 1
## Seconds a settler occupies the crafting station per execution.
var labor_cost: float = 3.0
