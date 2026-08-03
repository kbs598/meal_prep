project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
project_library <- file.path(project_dir, "packages")
.libPaths(c(project_library, .libPaths()))

source(file.path(project_dir, "app.R"))

test_storage_dir <- file.path(tempdir(), paste0("weeknight-five-", Sys.getpid()))
dir.create(test_storage_dir, recursive = TRUE, showWarnings = FALSE)
saved_state_path <- file.path(test_storage_dir, "state.rds")
saved_recipe_path <- file.path(test_storage_dir, "custom_recipes.rds")
saved_deals_path <- file.path(test_storage_dir, "deals.rds")

shiny::testServer(server, {
  session$setInputs(
    adults = 2,
    toddlers = 2,
    young_children = 1,
    lunch_servings = 2,
    proteins = c("Chicken", "Turkey", "Beef", "Pork", "Fish", "Meatless"),
    pantry_items = character(),
    plan_breakfast = TRUE,
    plan_lunch = TRUE,
    recipe_meal_type = "All",
    recipe_protein = "All",
    recipe_time = 45,
    season_region = "Southeast",
    zip_code = "12345"
  )
  session$flushReact()

  stopifnot(nrow(state$plan) == 5)
  stopifnot(nrow(state$breakfast_plan) == 5)
  stopifnot(nrow(state$lunch_plan) == 5)
  stopifnot(all(state$recipes$meal_type[match(state$breakfast_plan$recipe_id, state$recipes$recipe_id)] == "Breakfast"))
  stopifnot(all(state$recipes$meal_type[match(state$lunch_plan$recipe_id, state$recipes$recipe_id)] == "Lunch"))
  stopifnot(output$portion_total == "5.4")

  first_recipe <- state$plan$recipe_id[1]
  session$setInputs(swap_1 = 1)
  session$flushReact()
  stopifnot(state$plan$recipe_id[1] != first_recipe)

  session$setInputs(lock_2 = 1)
  session$flushReact()
  stopifnot(isTRUE(state$plan$locked[2]))
  locked_recipe <- state$plan$recipe_id[2]

  session$setInputs(generate_plan = 1)
  session$flushReact()
  stopifnot(state$plan$recipe_id[2] == locked_recipe)

  groceries <- current_grocery()
  stopifnot(nrow(groceries) > 0)
  stopifnot(!is.null(output$meal_cards))
  stopifnot(!is.null(output$breakfast_plan_ui))
  stopifnot(!is.null(output$lunch_plan_ui))
  stopifnot(!is.null(output$print_week_plan))
  stopifnot(!is.null(output$recipe_gallery))
  stopifnot(!is.null(output$grocery_list_ui))
  stopifnot(!is.null(output$account_ui))

  session$setInputs(
    custom_name = "Test Family Chicken",
    custom_protein = "Chicken",
    custom_meal_type = "Lunch",
    custom_minutes = 25,
    custom_servings = 4,
    custom_calories = 420,
    custom_protein_g = 36,
    custom_fiber_g = 6,
    custom_description = "A test recipe",
    custom_instructions = "Cook the chicken safely.",
    custom_kid_note = "Cut into small pieces.",
    custom_gf_confirm = TRUE,
    custom_qty_1 = 1.5,
    custom_unit_1 = "lb",
    custom_ingredient_1 = "boneless chicken breast",
    custom_category_1 = "Meat & Seafood"
  )
  session$setInputs(save_custom_recipe = 1)
  session$flushReact()
  stopifnot(any(state$recipes$recipe_name == "Test Family Chicken"))
  test_recipe <- state$recipes[state$recipes$recipe_name == "Test Family Chicken", , drop = FALSE]
  stopifnot(test_recipe$meal_type == "Lunch")
  stopifnot(test_recipe$calories == 420)
  stopifnot(file.exists(saved_recipe_path))

  session$setInputs(supabase_auth = list(
    status = "signed_in", configured = TRUE, email = "cook@example.com",
    user_id = "user-1", family_id = "family-1", role = "owner",
    needs_password = FALSE, message = "Connected"
  ))
  session$flushReact()
  stopifnot(identical(state$cloud_auth$status, "signed_in"))
  stopifnot(identical(state$cloud_auth$family_id, "family-1"))
  stopifnot(!is.null(output$cloud_status_bar))

  cloud_recipe <- single_custom_recipe_data(
    test_recipe$recipe_id,
    state$recipes,
    state$ingredients
  )
  session$setInputs(supabase_recipe_sync = list(
    payloads = list(encode_browser_data(cloud_recipe)),
    recipes_empty = FALSE,
    no_family = FALSE
  ))
  session$flushReact()
  stopifnot(any(state$recipes$recipe_name == "Test Family Chicken"))

  session$setInputs(
    deal_store = "ALDI",
    deal_ingredient = "boneless chicken breast",
    deal_offer = "$2.49/lb",
    deal_start = Sys.Date(),
    deal_end = Sys.Date() + 6
  )
  session$setInputs(save_deal = 1)
  session$flushReact()
  stopifnot(nrow(state$deals) == 1)
  stopifnot(file.exists(saved_deals_path))
  stopifnot(nrow(recipe_deals(state$recipes$recipe_id[state$recipes$recipe_name == "Test Family Chicken"])) == 1)
  stopifnot(!is.null(output$seasonal_now))
})

cat("Interactive Shiny session checks passed.\n")
