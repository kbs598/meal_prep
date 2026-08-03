single_custom_recipe_data <- function(recipe_id, recipes, ingredients) {
  recipe_id <- as.character(recipe_id %||% "")
  custom <- recipes[
    recipes$source == "My recipe" & recipes$recipe_id == recipe_id,
    , drop = FALSE
  ]
  if (!nrow(custom)) return(empty_custom_recipe_data())

  list(
    recipes = custom[1, names(empty_custom_recipe_data()$recipes), drop = FALSE],
    ingredients = ingredients[
      ingredients$recipe_id == recipe_id,
      names(empty_custom_recipe_data()$ingredients),
      drop = FALSE
    ]
  )
}

combine_cloud_recipe_payloads <- function(payloads) {
  if (is.null(payloads)) return(empty_custom_recipe_data())
  payloads <- unlist(payloads, recursive = FALSE, use.names = FALSE)
  if (!length(payloads)) return(empty_custom_recipe_data())

  decoded <- lapply(payloads, function(payload) {
    value <- decode_browser_data(as.character(payload), fallback = NULL)
    if (is.null(value)) return(NULL)
    value <- normalize_custom_recipe_data(value)
    if (!nrow(value$recipes)) return(NULL)
    value
  })
  decoded <- Filter(Negate(is.null), decoded)
  if (!length(decoded)) return(empty_custom_recipe_data())

  recipes <- do.call(rbind, lapply(decoded, `[[`, "recipes"))
  ingredients <- do.call(rbind, lapply(decoded, `[[`, "ingredients"))
  recipes <- recipes[!duplicated(recipes$recipe_id, fromLast = TRUE), , drop = FALSE]
  ingredients <- ingredients[ingredients$recipe_id %in% recipes$recipe_id, , drop = FALSE]
  normalize_custom_recipe_data(list(recipes = recipes, ingredients = ingredients))
}

normalize_cloud_auth <- function(value) {
  fallback <- list(
    status = "starting",
    configured = TRUE,
    email = "",
    user_id = "",
    family_id = "",
    role = "",
    needs_password = FALSE,
    message = "Connecting to your family recipe collection..."
  )
  if (!is.list(value)) return(fallback)
  result <- utils::modifyList(fallback, value)
  character_fields <- c("status", "email", "user_id", "family_id", "role", "message")
  for (field in character_fields) result[[field]] <- as.character(result[[field]] %||% "")[1]
  result$configured <- isTRUE(result$configured)
  result$needs_password <- isTRUE(result$needs_password)
  result
}
