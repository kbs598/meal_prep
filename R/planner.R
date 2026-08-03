LEFTOVER_ID <- "LEFTOVERS"

family_portions <- function(adults = 2, toddlers = 2, young_children = 1,
                            toddler_weight = 0.4, child_weight = 0.6,
                            lunch_servings = 2) {
  household_portions(adults, toddlers, young_children, toddler_weight, child_weight) + lunch_servings
}

household_portions <- function(adults = 2, toddlers = 2, young_children = 1,
                               toddler_weight = 0.4, child_weight = 0.6) {
  adults + toddlers * toddler_weight + young_children * child_weight
}

pantry_match <- function(recipe_id, ingredients, pantry_items) {
  needed <- unique(ingredients$ingredient[ingredients$recipe_id == recipe_id])
  if (!length(needed)) return(0)
  mean(needed %in% pantry_items)
}

recipe_scores <- function(candidates, ingredients, pantry_items, recent_ids = character()) {
  scores <- vapply(candidates$recipe_id, function(id) {
    5 * pantry_match(id, ingredients, pantry_items) -
      ifelse(id %in% recent_ids, 4, 0) +
      ifelse(candidates$minutes[candidates$recipe_id == id] <= 30, 0.35, 0)
  }, numeric(1))
  scores + stats::runif(length(scores), 0, 0.5)
}

pick_one_recipe <- function(candidates, ingredients, pantry_items, recent_ids,
                            excluded_ids = character(), avoid_protein = NULL,
                            require_quick = FALSE) {
  pool <- candidates[!candidates$recipe_id %in% excluded_ids, , drop = FALSE]
  if (!is.null(avoid_protein)) {
    varied <- pool[pool$protein != avoid_protein, , drop = FALSE]
    if (nrow(varied)) pool <- varied
  }
  if (require_quick) {
    quick <- pool[pool$minutes <= 30, , drop = FALSE]
    if (nrow(quick)) pool <- quick
  }
  if (!nrow(pool)) return(NULL)
  scores <- recipe_scores(pool, ingredients, pantry_items, recent_ids)
  pool[which.max(scores), , drop = FALSE]
}

generate_meal_plan <- function(recipes, ingredients, proteins, pantry_items = character(),
                               recent_ids = character(), locked_plan = NULL, n = 5,
                               meal_type = NULL) {
  candidates <- recipes[recipes$protein %in% proteins, , drop = FALSE]
  if (!is.null(meal_type)) candidates <- candidates[candidates$meal_type == meal_type, , drop = FALSE]
  if (!nrow(candidates)) stop("Choose at least one protein category with available recipes.")

  plan <- data.frame(
    day = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")[seq_len(n)],
    recipe_id = rep(NA_character_, n),
    locked = rep(FALSE, n),
    stringsAsFactors = FALSE
  )
  if (!is.null(locked_plan) && nrow(locked_plan) == n) {
    keep <- locked_plan$locked &
      (locked_plan$recipe_id %in% candidates$recipe_id | locked_plan$recipe_id == LEFTOVER_ID)
    plan$recipe_id[keep] <- locked_plan$recipe_id[keep]
    plan$locked[keep] <- TRUE
  }

  used <- stats::na.omit(plan$recipe_id)
  for (i in seq_len(n)) {
    if (!is.na(plan$recipe_id[i])) next
    previous_protein <- NULL
    if (i > 1 && !is.na(plan$recipe_id[i - 1])) {
      previous_protein <- candidates$protein[match(plan$recipe_id[i - 1], candidates$recipe_id)]
    }
    selected <- pick_one_recipe(
      candidates, ingredients, pantry_items, recent_ids,
      excluded_ids = used, avoid_protein = previous_protein,
      require_quick = i == n && !any(candidates$recipe_id[candidates$minutes <= 30] %in% used)
    )
    if (is.null(selected)) {
      selected <- pick_one_recipe(candidates, ingredients, pantry_items, recent_ids,
                                  avoid_protein = previous_protein)
    }
    plan$recipe_id[i] <- selected$recipe_id[1]
    used <- c(used, selected$recipe_id[1])
  }
  plan
}

swap_meal <- function(plan, position, recipes, ingredients, proteins,
                      pantry_items = character(), recent_ids = character(), meal_type = NULL) {
  candidates <- recipes[recipes$protein %in% proteins, , drop = FALSE]
  if (!is.null(meal_type)) candidates <- candidates[candidates$meal_type == meal_type, , drop = FALSE]
  adjacent <- character()
  if (position > 1) adjacent <- c(adjacent, plan$recipe_id[position - 1])
  if (position < nrow(plan)) adjacent <- c(adjacent, plan$recipe_id[position + 1])
  avoid_proteins <- unique(recipes$protein[match(adjacent, recipes$recipe_id)])
  pool <- candidates[
    !candidates$recipe_id %in% plan$recipe_id & !candidates$protein %in% avoid_proteins,
    , drop = FALSE
  ]
  if (!nrow(pool)) pool <- candidates[!candidates$recipe_id %in% plan$recipe_id, , drop = FALSE]
  if (!nrow(pool)) pool <- candidates[candidates$recipe_id != plan$recipe_id[position], , drop = FALSE]
  if (!nrow(pool)) return(plan)
  scores <- recipe_scores(pool, ingredients, pantry_items, recent_ids)
  plan$recipe_id[position] <- pool$recipe_id[which.max(scores)]
  plan
}

grocery_list <- function(plan, recipes, ingredients, portions, pantry_items = character()) {
  plan <- plan[plan$recipe_id %in% recipes$recipe_id, , drop = FALSE]
  if (!nrow(plan)) {
    return(data.frame(category = character(), ingredient = character(), unit = character(),
                      quantity = numeric(), stringsAsFactors = FALSE))
  }
  selected <- merge(plan[c("day", "recipe_id")], recipes[c("recipe_id", "base_servings")],
                    by = "recipe_id", all.x = TRUE)
  rows <- merge(selected, ingredients, by = "recipe_id", all.x = TRUE)
  rows$scaled_quantity <- rows$quantity * portions / rows$base_servings
  rows <- rows[!rows$ingredient %in% pantry_items, , drop = FALSE]
  if (!nrow(rows)) {
    return(data.frame(category = character(), ingredient = character(), unit = character(),
                      quantity = numeric(), stringsAsFactors = FALSE))
  }
  result <- stats::aggregate(scaled_quantity ~ category + ingredient + unit, rows, sum)
  names(result)[names(result) == "scaled_quantity"] <- "quantity"
  result <- result[order(result$category, result$ingredient), , drop = FALSE]
  rownames(result) <- NULL
  result
}

format_quantity <- function(x) {
  rounded <- round(x * 4) / 4
  format(rounded, trim = TRUE, scientific = FALSE)
}

selection_reason <- function(recipe_id, recipes, ingredients, pantry_items) {
  recipe <- recipes[recipes$recipe_id == recipe_id, , drop = FALSE]
  match_rate <- pantry_match(recipe_id, ingredients, pantry_items)
  if (!identical(recipe$meal_type[1], "Dinner")) {
    if (match_rate >= 0.5) return(sprintf("Great pantry match - %d minutes", recipe$minutes))
    if (recipe$minutes <= 15) return(sprintf("Fast family %s - %d minutes", tolower(recipe$meal_type), recipe$minutes))
    return(sprintf("Adds variety - %d minutes", recipe$minutes))
  }
  if (match_rate >= 0.5) {
    sprintf("Great pantry match • %d minutes", recipe$minutes)
  } else if (recipe$minutes <= 30) {
    sprintf("Quick family dinner • %d minutes", recipe$minutes)
  } else {
    sprintf("Adds variety • %d minutes", recipe$minutes)
  }
}
