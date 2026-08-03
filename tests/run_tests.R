project_dir <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
if (basename(project_dir) == "tests") project_dir <- dirname(project_dir)
project_library <- file.path(project_dir, "packages")
if (dir.exists(project_library)) .libPaths(c(project_library, .libPaths()))

source(file.path(project_dir, "R", "recipes.R"))
source(file.path(project_dir, "R", "expanded_recipes.R"))
source(file.path(project_dir, "R", "planner.R"))
source(file.path(project_dir, "R", "storage.R"))
source(file.path(project_dir, "R", "supabase.R"))
source(file.path(project_dir, "R", "seasonality.R"))

expanded <- expanded_recipe_data()
stopifnot(nrow(expanded$recipes) == 90)
stopifnot(sum(expanded$recipes$meal_type == "Dinner") == 50)
stopifnot(sum(expanded$recipes$meal_type == "Breakfast") == 20)
stopifnot(sum(expanded$recipes$meal_type == "Lunch") == 20)
stopifnot(sum(expanded$recipes$source == "TheMealDB adaptation") == 64)
stopifnot(sum(expanded$recipes$source == "Wikibooks adaptation (CC BY-SA)") == 26)
stopifnot(all(nzchar(expanded$recipes$source_url)))

data <- combined_builtin_recipe_data()
stopifnot(nrow(data$recipes) == 126)
stopifnot(identical(sort(unique(data$recipes$meal_type)), c("Breakfast", "Dinner", "Lunch")))
stopifnot(sum(data$recipes$meal_type == "Dinner") == 70)
stopifnot(sum(data$recipes$meal_type == "Breakfast") == 28)
stopifnot(sum(data$recipes$meal_type == "Lunch") == 28)
stopifnot(all(data$recipes$calories > 0))
stopifnot(all(data$recipes$protein_g > 0))
stopifnot(all(data$recipes$fiber_g > 0))
stopifnot(all(c("Chicken", "Turkey", "Beef", "Pork", "Fish", "Meatless") %in% data$recipes$protein))
stopifnot(all(data$recipes$minutes <= 35))
stopifnot(!anyDuplicated(data$recipes$recipe_id))
stopifnot(all(data$ingredients$recipe_id %in% data$recipes$recipe_id))
stopifnot(all(data$ingredients$quantity > 0))

set.seed(42)
plan <- generate_meal_plan(
  data$recipes, data$ingredients,
  proteins = c("Chicken", "Turkey", "Beef", "Pork", "Fish", "Meatless"),
  pantry_items = c("white rice", "olive oil"),
  meal_type = "Dinner"
)
stopifnot(nrow(plan) == 5)
stopifnot(length(unique(plan$recipe_id)) == 5)
plan_proteins <- data$recipes$protein[match(plan$recipe_id, data$recipes$recipe_id)]
stopifnot(all(plan_proteins[-1] != plan_proteins[-length(plan_proteins)]))
stopifnot(any(data$recipes$minutes[match(plan$recipe_id, data$recipes$recipe_id)] <= 30))

breakfast_plan <- generate_meal_plan(data$recipes, data$ingredients, unique(data$recipes$protein), meal_type = "Breakfast")
lunch_plan <- generate_meal_plan(data$recipes, data$ingredients, unique(data$recipes$protein), meal_type = "Lunch")
stopifnot(all(data$recipes$meal_type[match(breakfast_plan$recipe_id, data$recipes$recipe_id)] == "Breakfast"))
stopifnot(all(data$recipes$meal_type[match(lunch_plan$recipe_id, data$recipes$recipe_id)] == "Lunch"))

portions <- family_portions(2, 2, 1, lunch_servings = 2)
stopifnot(identical(portions, 5.4))
stopifnot(identical(household_portions(2, 2, 1), 3.4))
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
  store = c("ALDI", "Publix BOGO"),
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
stopifnot("source_url" %in% names(loaded_custom$recipes))

legacy_custom <- custom
legacy_custom$recipes$source_url <- NULL
legacy_custom$recipes$meal_type <- NULL
legacy_custom$recipes$calories <- NULL
legacy_custom$recipes$protein_g <- NULL
legacy_custom$recipes$fiber_g <- NULL
normalized_legacy <- normalize_custom_recipe_data(legacy_custom)
stopifnot("source_url" %in% names(normalized_legacy$recipes))
stopifnot(identical(normalized_legacy$recipes$source_url, ""))
stopifnot(identical(normalized_legacy$recipes$meal_type, "Dinner"))
stopifnot(identical(normalized_legacy$recipes$calories, 400))

cloud_single <- single_custom_recipe_data(
  custom$recipes$recipe_id[1],
  custom$recipes,
  custom$ingredients
)
stopifnot(nrow(cloud_single$recipes) == 1)
stopifnot(nrow(cloud_single$ingredients) > 0)
cloud_combined <- combine_cloud_recipe_payloads(list(encode_browser_data(cloud_single)))
stopifnot(identical(cloud_combined$recipes$recipe_id, cloud_single$recipes$recipe_id))
stopifnot(nrow(cloud_combined$ingredients) == nrow(cloud_single$ingredients))
cloud_auth <- normalize_cloud_auth(list(status = "signed_in", email = "cook@example.com", family_id = "family-1"))
stopifnot(identical(cloud_auth$status, "signed_in"))
stopifnot(identical(cloud_auth$email, "cook@example.com"))
stopifnot(!isTRUE(cloud_auth$needs_password))

cat("All planner, recipe, season, and deal checks passed.\n")
