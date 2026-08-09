ingredient_rows <- function(recipe_id, rows) {
  parsed <- strsplit(rows, "|", fixed = TRUE)
  data.frame(
    recipe_id = recipe_id,
    quantity = as.numeric(vapply(parsed, `[[`, character(1), 1)),
    unit = vapply(parsed, `[[`, character(1), 2),
    ingredient = vapply(parsed, `[[`, character(1), 3),
    category = vapply(parsed, `[[`, character(1), 4),
    stringsAsFactors = FALSE
  )
}

make_recipe <- function(id, name, protein, minutes, description, instructions,
                        ingredient_lines, kid_note = "Serve in small, age-appropriate pieces.",
                        meal_type = "Dinner", source = "My recipe", source_url = "") {
  list(
    meta = data.frame(
      recipe_id = id,
      recipe_name = name,
      protein = protein,
      meal_type = meal_type,
      minutes = minutes,
      base_servings = 4,
      description = description,
      kid_note = kid_note,
      instructions = instructions,
      source = source,
      source_url = source_url,
      stringsAsFactors = FALSE
    ),
    ingredients = ingredient_rows(id, ingredient_lines)
  )
}

sample_recipe_data <- function() {
  recipes <- list(
    make_recipe(
      "test_chicken", "Test Chicken Bowl", "Chicken", 30,
      "A quick chicken dinner for tests.",
      "Cook the chicken through and serve with rice.",
      c("1.25|lb|boneless chicken breast|Meat & Seafood", "1.5|cup|white rice|Pantry", "1|tbsp|olive oil|Pantry")
    ),
    make_recipe(
      "test_turkey", "Test Turkey Skillet", "Turkey", 25,
      "A simple turkey skillet for tests.",
      "Brown the turkey and stir in rice.",
      c("1.25|lb|ground turkey|Meat & Seafood", "3|cup|cooked white rice|Pantry")
    ),
    make_recipe(
      "test_beef", "Test Beef Bowls", "Beef", 30,
      "A beef bowl for planner variety tests.",
      "Brown the beef and serve over rice.",
      c("1.25|lb|ground beef|Meat & Seafood", "1.5|cup|white rice|Pantry")
    ),
    make_recipe(
      "test_pork", "Test Pork Rice", "Pork", 30,
      "A pork dinner for planner variety tests.",
      "Cook the pork and serve with rice.",
      c("1|lb|ground pork|Meat & Seafood", "4|cup|cooked white rice|Pantry")
    ),
    make_recipe(
      "test_fish", "Test Fish Plate", "Fish", 25,
      "A fish dinner for planner variety tests.",
      "Cook the fish until flaky and serve.",
      c("1.5|lb|salmon fillets|Meat & Seafood", "1|count|lemon|Produce")
    ),
    make_recipe(
      "test_meatless", "Test Bean Bowl", "Meatless", 20,
      "A meatless dinner for planner variety tests.",
      "Warm the beans and serve over rice.",
      c("1|can|black beans|Pantry", "1.5|cup|white rice|Pantry")
    ),
    make_recipe(
      "test_breakfast", "Test Breakfast Oats", "Meatless", 15,
      "A breakfast recipe for secondary plan tests.",
      "Cook the oats and serve warm.",
      c("2|cup|rolled oats (certified GF)|Pantry", "4|count|eggs|Dairy"),
      meal_type = "Breakfast"
    ),
    make_recipe(
      "test_lunch", "Test Lunch Wraps", "Chicken", 20,
      "A lunch recipe for secondary plan tests.",
      "Fill the tortillas with chicken and vegetables.",
      c("1|lb|boneless chicken breast|Meat & Seafood", "8|count|corn tortillas (certified GF)|Bakery"),
      meal_type = "Lunch"
    )
  )
  list(
    recipes = do.call(rbind, lapply(recipes, `[[`, "meta")),
    ingredients = do.call(rbind, lapply(recipes, `[[`, "ingredients"))
  )
}
