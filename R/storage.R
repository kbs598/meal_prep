state_file <- function(app_dir = getwd()) file.path(app_dir, "user_data", "state.rds")
custom_recipe_file <- function(app_dir = getwd()) file.path(app_dir, "user_data", "custom_recipes.rds")
deals_file <- function(app_dir = getwd()) file.path(app_dir, "user_data", "deals.rds")

default_state <- function() {
  list(
    pantry_items = character(),
    recent_ids = character(),
    settings = list(
      proteins = c("Chicken", "Turkey", "Beef", "Pork", "Fish", "Meatless"),
      adults = 2,
      toddlers = 2,
      young_children = 1,
      toddler_weight = 0.4,
      child_weight = 0.6,
      lunch_servings = 2,
      season_region = "Southeast",
      zip_code = ""
    )
  )
}

empty_custom_recipe_data <- function() {
  list(
    recipes = data.frame(
      recipe_id = character(), recipe_name = character(), protein = character(),
      minutes = numeric(), base_servings = numeric(), description = character(),
      kid_note = character(), instructions = character(), source = character(),
      source_url = character(),
      stringsAsFactors = FALSE
    ),
    ingredients = data.frame(
      recipe_id = character(), quantity = numeric(), unit = character(),
      ingredient = character(), category = character(), stringsAsFactors = FALSE
    )
  )
}

normalize_custom_recipe_data <- function(data) {
  fallback <- empty_custom_recipe_data()
  if (!is.list(data) || !is.data.frame(data$recipes) || !is.data.frame(data$ingredients)) {
    return(fallback)
  }

  if (!"source_url" %in% names(data$recipes)) data$recipes$source_url <- ""
  missing_recipe_columns <- setdiff(names(fallback$recipes), names(data$recipes))
  missing_ingredient_columns <- setdiff(names(fallback$ingredients), names(data$ingredients))
  if (length(missing_recipe_columns) || length(missing_ingredient_columns)) return(fallback)

  list(
    recipes = data$recipes[, names(fallback$recipes), drop = FALSE],
    ingredients = data$ingredients[, names(fallback$ingredients), drop = FALSE]
  )
}

load_custom_recipe_data <- function(path) {
  fallback <- empty_custom_recipe_data()
  if (!file.exists(path)) return(fallback)
  saved <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(saved) || !is.list(saved) || is.null(saved$recipes) || is.null(saved$ingredients)) {
    return(fallback)
  }
  normalize_custom_recipe_data(saved)
}

save_custom_recipe_data <- function(data, path) {
  try({
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(data, path)
  }, silent = TRUE)
  invisible(path)
}

empty_deals <- function() {
  data.frame(
    deal_id = character(), store = character(), ingredient = character(),
    offer = character(), start_date = as.Date(character()),
    end_date = as.Date(character()), stringsAsFactors = FALSE
  )
}

load_deals <- function(path) {
  if (!file.exists(path)) return(empty_deals())
  saved <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(saved) || !is.data.frame(saved)) return(empty_deals())
  saved$start_date <- as.Date(saved$start_date)
  saved$end_date <- as.Date(saved$end_date)
  saved
}

save_deals <- function(deals, path) {
  try({
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(deals, path)
  }, silent = TRUE)
  invisible(path)
}

load_state <- function(path) {
  fallback <- default_state()
  if (!file.exists(path)) return(fallback)
  saved <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(saved) || !is.list(saved)) return(fallback)
  utils::modifyList(fallback, saved)
}

save_state <- function(state, path) {
  try({
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(state, path)
  }, silent = TRUE)
  invisible(path)
}

encode_browser_data <- function(value) {
  base64enc::base64encode(serialize(value, NULL, version = 2))
}

decode_browser_data <- function(value, fallback = NULL) {
  if (is.null(value) || !is.character(value) || length(value) != 1L || !nzchar(value)) {
    return(fallback)
  }
  tryCatch(
    unserialize(base64enc::base64decode(value)),
    error = function(e) fallback
  )
}
