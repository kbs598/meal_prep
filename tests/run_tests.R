project_dir <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
if (basename(project_dir) == "tests") project_dir <- dirname(project_dir)

source(file.path(project_dir, "R", "recipes.R"))
source(file.path(project_dir, "R", "planner.R"))
source(file.path(project_dir, "R", "storage.R"))
source(file.path(project_dir, "R", "seasonality.R"))

data <- builtin_recipe_data()
stopifnot(nrow(data$recipes) == 20)
stopifnot(all(c("Chicken", "Turkey", "Beef", "Pork", "Fish", "Meatless") %in% data$recipes$protein))
stopifnot(all(data$recipes$minutes <= 35))
stopifnot(!anyDuplicated(data$recipes$recipe_id))
stopifnot(all(data$ingredients$recipe_id %in% data$recipes$recipe_id))
stopifnot(all(data$ingredients$quantity > 0))

set.seed(42)
plan <- generate_meal_plan(
  data$recipes, data$ingredients,
  proteins = c("Chicken", "Turkey", "Beef", "Pork", "Fish", "Meatless"),
  pantry_items = c("white rice", "olive oil")
)
stopifnot(nrow(plan) == 5)
stopifnot(length(unique(plan$recipe_id)) == 5)
plan_proteins <- data$recipes$protein[match(plan$recipe_id, data$recipes$recipe_id)]
stopifnot(all(plan_proteins[-1] != plan_proteins[-length(plan_proteins)]))
stopifnot(any(data$recipes$minutes[match(plan$recipe_id, data$recipes$recipe_id)] <= 30))

portions <- family_portions(2, 2, 1, lunch_servings = 2)
stopifnot(identical(portions, 5.4))
groceries <- grocery_list(plan, data$recipes, data$ingredients, portions, c("white rice", "olive oil"))
stopifnot(nrow(groceries) > 0)
stopifnot(!any(groceries$ingredient %in% c("white rice", "olive oil")))
stopifnot(all(groceries$quantity > 0))

august_southeast <- seasonal_items("Southeast", 8)
stopifnot("Tomatoes" %in% august_southeast$item)
stopifnot("Corn" %in% seasonal_matches(c("frozen corn", "white rice"), "Southeast", 8))

today <- Sys.Date()
test_deals <- data.frame(
  deal_id = c("active", "expired"),
  store = c("ALDI", "Walmart"),
  ingredient = c("ground turkey", "salmon"),
  offer = c("$2.99/lb", "rollback"),
  start_date = c(today - 1, today - 10),
  end_date = c(today + 1, today - 2),
  stringsAsFactors = FALSE
)
stopifnot(nrow(active_deals(test_deals, today)) == 1)
stopifnot(nrow(deal_matches(c("ground turkey", "rice"), test_deals, today)) == 1)

temp_custom_path <- file.path(tempdir(), "weeknight-five-test-recipes.rds")
custom <- empty_custom_recipe_data()
custom$recipes <- data$recipes[1, , drop = FALSE]
custom$recipes$source <- "My recipe"
custom$ingredients <- data$ingredients[data$ingredients$recipe_id == custom$recipes$recipe_id, , drop = FALSE]
save_custom_recipe_data(custom, temp_custom_path)
loaded_custom <- load_custom_recipe_data(temp_custom_path)
stopifnot(nrow(loaded_custom$recipes) == 1)
stopifnot(nrow(loaded_custom$ingredients) > 0)

cat("All planner, recipe, season, and deal checks passed.\n")
