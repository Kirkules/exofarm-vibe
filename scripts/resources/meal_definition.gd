class_name MealDefinition
extends PlaceableDefinition

## A crafted food item produced by a recipe.
## One meal satisfies one settler for a full season.
## Can be placed in a KitchenGrid (as an ingredient in chain recipes)
## or in a settler food slot.

## Flat morale change applied to the settler who eats this meal.
## 0 = neutral (removes the Nutrient Paste -1 penalty but adds nothing).
## Positive values come from higher-quality recipes.
var morale_modifier: int = 0
