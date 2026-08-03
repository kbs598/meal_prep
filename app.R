app_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
project_library <- file.path(app_dir, "packages")
if (dir.exists(project_library)) .libPaths(c(project_library, .libPaths()))

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop("Shiny is not installed yet. Open setup.R and click Source, then try again.")
}

library(shiny)

source(file.path(app_dir, "R", "recipes.R"), local = TRUE)
source(file.path(app_dir, "R", "expanded_recipes.R"), local = TRUE)
source(file.path(app_dir, "R", "planner.R"), local = TRUE)
source(file.path(app_dir, "R", "storage.R"), local = TRUE)
source(file.path(app_dir, "R", "seasonality.R"), local = TRUE)

builtin_data <- combined_builtin_recipe_data()
saved_state_path <- state_file(app_dir)
saved_recipe_path <- custom_recipe_file(app_dir)
saved_deals_path <- deals_file(app_dir)
initial_state <- load_state(saved_state_path)
custom_data <- load_custom_recipe_data(saved_recipe_path)
initial_deals <- load_deals(saved_deals_path)
recipes <- rbind(builtin_data$recipes, custom_data$recipes)
ingredients <- rbind(builtin_data$ingredients, custom_data$ingredients)
all_proteins <- c("Chicken", "Turkey", "Beef", "Pork", "Fish", "Meatless")
meal_types <- c("Dinner", "Breakfast", "Lunch")
all_ingredients <- sort(unique(ingredients$ingredient))
ingredient_units <- c("count", "lb", "oz", "cup", "tbsp", "tsp", "can", "bag", "package", "slice", "clove", "bunch", "head", "stalk")
grocery_categories <- c("Produce", "Meat & Seafood", "Dairy", "Pantry", "Frozen", "Bakery")
season_regions <- c("Northeast", "Southeast", "Midwest", "Southwest", "West")
browser_storage_keys <- c(
  state = "weeknight-five.state.v1",
  recipes = "weeknight-five.recipes.v1",
  deals = "weeknight-five.deals.v1"
)

protein_emoji <- c(
  Chicken = "🐔", Turkey = "🦃", Beef = "🐮", Pork = "🐷",
  Fish = "🐟", Meatless = "🌱"
)

ui <- navbarPage(
  title = div(class = "brand", span(class = "brand-mark", "🌈"), "Weeknight Five"),
  id = "main_nav",
  collapsible = TRUE,
  header = tagList(
    tags$head(
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
      tags$script(src = "persistence.js")
    ),
    div(
      class = "gf-banner",
      span("🛡️"),
      div(
        strong("Celiac-aware planning"),
        span(" All starter recipes are gluten-free as written. Always verify labels, shared equipment, and cross-contact risks.")
      )
    )
  ),

  tabPanel(
    "This Week", icon = icon("calendar-days"),
    div(
      class = "page-shell",
      div(
        class = "hero rainbow-panel",
        div(
          class = "hero-copy",
          tags$h1("Five happy dinners. One easy week."),
          tags$p("Dinner stays front and center, with optional breakfast and lunch rotations underneath."),
          div(class = "hero-actions",
              actionButton("generate_plan", "✨ Make a fresh plan", class = "btn-rainbow"),
              actionButton("save_week", "Save to meal history", class = "btn-soft"),
              actionButton("print_week", "Print fridge plan", icon = icon("print"), class = "btn-soft"))
        ),
        div(class = "portion-bubble", span("Planning for"), strong(textOutput("portion_total", inline = TRUE)), tags$small("adult-size portions"))
      ),
      uiOutput("plan_summary"),
      tags$h2(class = "primary-plan-heading", "Dinner plan"),
      uiOutput("meal_cards"),
      uiOutput("breakfast_plan_ui"),
      uiOutput("lunch_plan_ui"),
      uiOutput("print_week_plan")
    )
  ),

  tabPanel(
    "Pantry", icon = icon("basket-shopping"),
    div(
      class = "page-shell",
      div(class = "page-heading",
          tags$h1("What's already at home?"),
          tags$p("Choose anything you have enough of for this week's meals. We'll leave it off the grocery list.")),
      div(
        class = "content-card pantry-card",
        selectizeInput(
          "pantry_items", "Ingredients on hand",
          choices = all_ingredients,
          selected = initial_state$pantry_items,
          multiple = TRUE,
          options = list(placeholder = "Start typing: rice, olive oil, eggs...", plugins = list("remove_button"))
        ),
        div(class = "tip-box", "💡 Start with proteins, produce that needs using, and staples you know are well stocked."),
        uiOutput("pantry_summary")
      )
    )
  ),

  tabPanel(
    "Recipes", icon = icon("book-open"),
    div(
      class = "page-shell",
      div(class = "page-heading",
          tags$h1("Easy family recipes"),
          tags$p("Every starter recipe is mild, gluten-free as written, and editable in a future recipe-entry step.")),
      div(
        class = "filter-bar",
        selectInput("recipe_meal_type", "Show meal", choices = c("All", meal_types), selected = "All"),
        selectInput("recipe_protein", "Show protein", choices = c("All", all_proteins), selected = "All"),
        sliderInput("recipe_time", "Maximum time", min = 20, max = 45, value = 45, step = 5, post = " min")
      ),
      uiOutput("recipe_gallery")
    )
  ),

  tabPanel(
    "My Recipes", icon = icon("pen-to-square"),
    div(
      class = "page-shell",
      div(class = "page-heading",
          tags$h1("Add a family recipe"),
          tags$p("Paste a recipe link for a head start, or fill in the friendly form yourself. Saved recipes immediately join the weekly rotation.")),
      div(
        class = "content-card recipe-import-card",
        div(
          class = "recipe-import-copy",
          tags$h2("🔗 Import from a recipe link"),
          tags$p("Paste the web address of a recipe. We’ll copy its recipe details into the editable form below so you can check everything before saving.")
        ),
        div(
          class = "recipe-import-controls",
          textInput("recipe_url", "Recipe webpage", placeholder = "https://example.com/favorite-recipe"),
          actionButton("import_recipe_url", "✨ Fill the form from this link", class = "btn-rainbow")
        ),
        uiOutput("recipe_import_status"),
        tags$p(class = "import-privacy-note", "The public link is sent to Jina Reader to retrieve the recipe page. Some websites block automated reading or do not publish standard recipe details.")
      ),
      div(
        class = "recipe-entry-layout",
        div(
          class = "content-card recipe-form-card",
          tags$h2("Recipe details"),
          selectInput("custom_meal_type", "Meal rotation", choices = meal_types, selected = "Dinner"),
          div(class = "form-row two-up",
              textInput("custom_name", "Recipe name", placeholder = "Grandma's easy meatloaf"),
              selectInput("custom_protein", "Main protein", choices = all_proteins)),
          div(class = "form-row two-up",
              numericInput("custom_minutes", "Total minutes", value = 30, min = 5, max = 480),
              numericInput("custom_servings", "Base servings", value = 4, min = 1, max = 30)),
          tags$h3(class = "nutrition-form-heading", "Estimated nutrition per serving"),
          div(class = "form-row three-up nutrition-inputs",
              numericInput("custom_calories", "Calories", value = 400, min = 0, max = 3000, step = 10),
              numericInput("custom_protein_g", "Protein (g)", value = 25, min = 0, max = 300, step = 1),
              numericInput("custom_fiber_g", "Fiber (g)", value = 5, min = 0, max = 100, step = 1)),
          tags$p(class = "setting-note nutrition-estimate-note", "These are planning estimates, not medical or dietetic calculations."),
          textAreaInput("custom_description", "Short description", rows = 2, placeholder = "What makes this dinner useful or family-friendly?"),
          textInput("custom_source_url", "Original recipe link", placeholder = "Optional"),
          textAreaInput("custom_instructions", "Directions", rows = 5, placeholder = "Write the cooking steps here..."),
          textAreaInput("custom_kid_note", "Little-kid serving note", rows = 2, placeholder = "For example: serve the components separately."),
          div(class = "ingredient-heading", tags$h2("Ingredients"), span("Use certified GF products where needed.")),
          uiOutput("ingredient_editor"),
          div(class = "ingredient-actions",
              actionButton("add_ingredient_row", "+ Add ingredient", class = "btn-soft"),
              actionButton("remove_ingredient_row", "Remove last", class = "card-button")),
          checkboxInput("custom_gf_confirm", "I reviewed every ingredient for gluten and cross-contact risk.", value = FALSE),
          actionButton("save_custom_recipe", "🌈 Save recipe to rotation", class = "btn-rainbow save-recipe-button")
        ),
        div(
          class = "content-card my-recipes-card",
          tags$h2("Your saved recipes"),
          uiOutput("custom_recipe_summary"),
          hr(),
          selectInput("delete_recipe_id", "Remove a saved recipe", choices = setNames(custom_data$recipes$recipe_id, custom_data$recipes$recipe_name)),
          actionButton("delete_custom_recipe", "Delete selected recipe", class = "btn-danger-soft")
        )
      )
    )
  ),

  tabPanel(
    "Season & Deals", icon = icon("tags"),
    div(
      class = "page-shell",
      div(class = "page-heading",
          tags$h1("Cook with the season—and the sales"),
          tags$p("Seasonal produce is highlighted automatically. Add useful weekly-ad offers and matching recipes and groceries will receive sale badges.")),
      div(
        class = "season-settings content-card",
        div(
          selectInput("season_region", "Seasonal region", choices = season_regions, selected = initial_state$settings$season_region),
          textInput("zip_code", "ZIP code for store ads", value = initial_state$settings$zip_code, placeholder = "12345")
        ),
        actionButton("save_location", "Save location settings", class = "btn-rainbow")
      ),
      div(class = "season-deal-grid",
          div(class = "content-card",
              tags$h2("🌱 In season now"),
              tags$p(class = "setting-note", "A general regional guide. Growing seasons vary within a region and from year to year."),
              uiOutput("seasonal_now")),
          div(class = "content-card",
              tags$h2("Open your official weekly ads"),
              tags$p(class = "setting-note", "Choose your local store on each retailer site, then add the food deals you want the planner to use."),
              div(class = "store-link-grid",
                  tags$a(class = "store-link aldi-link", href = "https://www.aldi.us/store/aldi/flyers/weekly", target = "_blank", "ALDI Weekly Ad ↗"),
                  tags$a(class = "store-link publix-link", href = "https://www.publix.com/savings/bogo", target = "_blank", "Publix BOGOs ↗")))
      ),
      div(
        class = "deal-entry-layout",
        div(class = "content-card deal-form-card",
            tags$h2("Add a food deal"),
            selectInput("deal_store", "Store", choices = c("ALDI", "Publix BOGO")),
            selectizeInput("deal_ingredient", "Food or ingredient", choices = all_ingredients,
                           options = list(create = TRUE, placeholder = "Ground turkey, broccoli, salmon...")),
            textInput("deal_offer", "Offer", placeholder = "$2.99/lb, rollback, or buy one get one free"),
            div(class = "form-row two-up",
                dateInput("deal_start", "Starts", value = Sys.Date()),
                dateInput("deal_end", "Ends", value = Sys.Date() + 6)),
            actionButton("save_deal", "Add deal highlights", class = "btn-rainbow")),
        div(class = "content-card",
            tags$h2("Active food deals"),
            uiOutput("active_deals_ui"),
            selectInput("delete_deal_id", "Remove a deal", choices = setNames(initial_deals$deal_id, paste(initial_deals$store, initial_deals$ingredient, sep = " — "))),
            actionButton("delete_deal", "Remove selected deal", class = "btn-danger-soft"))
      )
    )
  ),

  tabPanel(
    "Grocery List", icon = icon("list-check"),
    div(
      class = "page-shell",
      div(
        class = "page-heading heading-with-action",
        div(tags$h1("One colorful grocery list"), tags$p("Quantities are combined across dinner and any enabled breakfast or lunch plans. Pantry items are removed.")),
        downloadButton("download_grocery", "Download CSV", class = "btn-rainbow")
      ),
      uiOutput("grocery_list_ui")
    )
  ),

  tabPanel(
    "Settings", icon = icon("sliders"),
    div(
      class = "page-shell",
      div(class = "page-heading", tags$h1("Make it fit your family"), tags$p("These values can change anytime without changing the recipes.")),
      div(
        class = "settings-grid",
        div(
          class = "content-card",
          tags$h2("Household portions"),
          numericInput("adults", "Adults", value = initial_state$settings$adults, min = 0, max = 10),
          numericInput("toddlers", "Two-year-olds", value = initial_state$settings$toddlers, min = 0, max = 10),
          numericInput("young_children", "Four-year-olds", value = initial_state$settings$young_children, min = 0, max = 10),
          numericInput("lunch_servings", "Adult lunch servings to save", value = initial_state$settings$lunch_servings, min = 0, max = 10),
          tags$p(class = "setting-note", "Current child portion estimates: each two-year-old = 0.4 and each four-year-old = 0.6 adult portions.")
        ),
        div(
          class = "content-card",
          tags$h2("Protein rotation"),
          checkboxGroupInput("proteins", NULL, choices = all_proteins, selected = initial_state$settings$proteins),
          tags$p(class = "setting-note", "The planner avoids the same protein on neighboring nights whenever possible."),
          div(class = "safety-card", strong("Gluten-free safeguard"), tags$p("Ingredients that commonly hide gluten are labeled “certified GF” in recipes. Continue checking every package because brands and manufacturing practices change.")),
          actionButton("save_settings", "Save settings", class = "btn-rainbow")
        ),
        div(
          class = "content-card",
          tags$h2("Optional meal plans"),
          checkboxInput("plan_breakfast", "Include a five-day breakfast rotation", value = isTRUE(initial_state$settings$plan_breakfast)),
          checkboxInput("plan_lunch", "Include a five-day lunch rotation", value = isTRUE(initial_state$settings$plan_lunch)),
          tags$p(class = "setting-note", "Dinner always remains the main plan. Enabled breakfast and lunch meals also join the grocery list and printed fridge plan."),
          actionButton("save_meal_options", "Save meal options", class = "btn-rainbow")
        ),
        div(
          class = "content-card settings-wide",
          tags$h2("Phone data & backup"),
          tags$p(
            class = "setting-note",
            "On GitHub Pages, your pantry, recipes, settings, and deals stay in this browser on this device. Download a backup before clearing browser data or changing phones."
          ),
          div(
            class = "backup-actions",
            downloadButton("download_backup", "Download my backup", class = "btn-rainbow"),
            fileInput("restore_backup", "Restore a Weeknight Five backup", accept = ".rds")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  state <- reactiveValues(
    pantry_items = initial_state$pantry_items,
    recent_ids = initial_state$recent_ids,
    settings = initial_state$settings,
    recipes = recipes,
    ingredients = ingredients,
    deals = initial_deals,
    ingredient_row_count = 4,
    import_status = NULL,
    plan = NULL,
    breakfast_plan = NULL,
    lunch_plan = NULL
  )
  restore_pending <- reactiveVal(NULL)

  current_portions <- reactive({
    family_portions(
      adults = input$adults %||% state$settings$adults,
      toddlers = input$toddlers %||% state$settings$toddlers,
      young_children = input$young_children %||% state$settings$young_children,
      toddler_weight = state$settings$toddler_weight,
      child_weight = state$settings$child_weight,
      lunch_servings = input$lunch_servings %||% state$settings$lunch_servings
    )
  })

  current_household_portions <- reactive({
    household_portions(
      adults = input$adults %||% state$settings$adults,
      toddlers = input$toddlers %||% state$settings$toddlers,
      young_children = input$young_children %||% state$settings$young_children,
      toddler_weight = state$settings$toddler_weight,
      child_weight = state$settings$child_weight
    )
  })

  send_browser_data <- function(key, value) {
    session$sendCustomMessage(
      "weeknight-five-save",
      list(key = unname(key), value = encode_browser_data(value))
    )
  }

  saved_state_data <- function() {
    list(
      pantry_items = isolate(state$pantry_items),
      recent_ids = isolate(state$recent_ids),
      settings = isolate(state$settings)
    )
  }

  saved_custom_data <- function() {
    recipes_now <- isolate(state$recipes)
    ingredients_now <- isolate(state$ingredients)
    custom_recipes <- recipes_now[recipes_now$source == "My recipe", , drop = FALSE]
    custom_ids <- custom_recipes$recipe_id
    custom_ingredients <- ingredients_now[ingredients_now$recipe_id %in% custom_ids, , drop = FALSE]
    list(recipes = custom_recipes, ingredients = custom_ingredients)
  }

  persist <- function() {
    value <- saved_state_data()
    save_state(value, saved_state_path)
    send_browser_data(browser_storage_keys[["state"]], value)
  }

  persist_custom_recipes <- function() {
    value <- saved_custom_data()
    save_custom_recipe_data(value, saved_recipe_path)
    send_browser_data(browser_storage_keys[["recipes"]], value)
  }

  persist_deals <- function() {
    save_deals(state$deals, saved_deals_path)
    send_browser_data(browser_storage_keys[["deals"]], state$deals)
  }

  refresh_recipe_inputs <- function() {
    all_items <- sort(unique(state$ingredients$ingredient))
    updateSelectizeInput(session, "pantry_items", choices = all_items,
                         selected = state$pantry_items, server = TRUE)
    updateSelectizeInput(session, "deal_ingredient", choices = all_items, server = TRUE)
    custom <- state$recipes[state$recipes$source == "My recipe", , drop = FALSE]
    updateSelectInput(session, "delete_recipe_id", choices = setNames(custom$recipe_id, custom$recipe_name))
  }

  apply_saved_state <- function(saved) {
    if (!is.list(saved)) return(FALSE)
    merged <- utils::modifyList(default_state(), saved)
    state$pantry_items <- as.character(merged$pantry_items %||% character())
    state$recent_ids <- as.character(merged$recent_ids %||% character())
    state$settings <- merged$settings
    updateSelectizeInput(session, "pantry_items", selected = state$pantry_items)
    updateCheckboxGroupInput(session, "proteins", selected = state$settings$proteins)
    updateNumericInput(session, "adults", value = state$settings$adults)
    updateNumericInput(session, "toddlers", value = state$settings$toddlers)
    updateNumericInput(session, "young_children", value = state$settings$young_children)
    updateNumericInput(session, "lunch_servings", value = state$settings$lunch_servings)
    updateCheckboxInput(session, "plan_breakfast", value = isTRUE(state$settings$plan_breakfast))
    updateCheckboxInput(session, "plan_lunch", value = isTRUE(state$settings$plan_lunch))
    updateSelectInput(session, "season_region", selected = state$settings$season_region)
    updateTextInput(session, "zip_code", value = state$settings$zip_code)
    state$plan <- NULL
    state$breakfast_plan <- NULL
    state$lunch_plan <- NULL
    TRUE
  }

  apply_custom_data <- function(saved) {
    saved <- normalize_custom_recipe_data(saved)
    required_recipe_columns <- names(empty_custom_recipe_data()$recipes)
    required_ingredient_columns <- names(empty_custom_recipe_data()$ingredients)
    if (!all(required_recipe_columns %in% names(saved$recipes)) ||
        !all(required_ingredient_columns %in% names(saved$ingredients))) return(FALSE)
    state$recipes <- rbind(builtin_data$recipes, saved$recipes[, required_recipe_columns, drop = FALSE])
    state$ingredients <- rbind(builtin_data$ingredients, saved$ingredients[, required_ingredient_columns, drop = FALSE])
    state$recent_ids <- intersect(state$recent_ids, state$recipes$recipe_id)
    refresh_recipe_inputs()
    state$plan <- NULL
    state$breakfast_plan <- NULL
    state$lunch_plan <- NULL
    TRUE
  }

  apply_deals <- function(saved) {
    if (!is.data.frame(saved) || !all(names(empty_deals()) %in% names(saved))) return(FALSE)
    state$deals <- saved[, names(empty_deals()), drop = FALSE]
    state$deals$start_date <- as.Date(state$deals$start_date)
    state$deals$end_date <- as.Date(state$deals$end_date)
    updateSelectInput(session, "delete_deal_id",
                      choices = setNames(state$deals$deal_id, paste(state$deals$store, state$deals$ingredient, sep = " — ")))
    TRUE
  }

  sync_saved_inputs <- function() {
    isolate({
      refresh_recipe_inputs()
      updateCheckboxGroupInput(session, "proteins", selected = state$settings$proteins)
      updateNumericInput(session, "adults", value = state$settings$adults)
      updateNumericInput(session, "toddlers", value = state$settings$toddlers)
      updateNumericInput(session, "young_children", value = state$settings$young_children)
      updateNumericInput(session, "lunch_servings", value = state$settings$lunch_servings)
      updateCheckboxInput(session, "plan_breakfast", value = isTRUE(state$settings$plan_breakfast))
      updateCheckboxInput(session, "plan_lunch", value = isTRUE(state$settings$plan_lunch))
      updateSelectInput(session, "season_region", selected = state$settings$season_region)
      updateTextInput(session, "zip_code", value = state$settings$zip_code)
      updateSelectInput(session, "delete_deal_id",
                        choices = setNames(state$deals$deal_id, paste(state$deals$store, state$deals$ingredient, sep = " — ")))
    })
  }

  observeEvent(input$browser_state, {
    saved <- decode_browser_data(input$browser_state)
    if (is.null(saved)) {
      session$sendCustomMessage("weeknight-five-storage-status", "state-decode-failed")
    } else if (apply_saved_state(saved)) {
      session$sendCustomMessage("weeknight-five-storage-status", "state-restored")
    }
  }, ignoreInit = FALSE)

  observeEvent(input$browser_recipes, {
    saved <- decode_browser_data(input$browser_recipes)
    if (!is.null(saved)) apply_custom_data(saved)
  }, ignoreInit = FALSE)

  observeEvent(input$browser_deals, {
    saved <- decode_browser_data(input$browser_deals)
    if (!is.null(saved)) apply_deals(saved)
  }, ignoreInit = FALSE)

  observeEvent(input$browser_storage_ready, {
    if (!nzchar(input$browser_state %||% "")) send_browser_data(browser_storage_keys[["state"]], saved_state_data())
    if (!nzchar(input$browser_recipes %||% "")) send_browser_data(browser_storage_keys[["recipes"]], saved_custom_data())
    if (!nzchar(input$browser_deals %||% "")) send_browser_data(browser_storage_keys[["deals"]], state$deals)
    session$onFlushed(sync_saved_inputs, once = TRUE)
  }, ignoreInit = FALSE)

  observeEvent(input$browser_ui_ready, {
    sync_saved_inputs()
  }, ignoreInit = FALSE)

  observeEvent(input$browser_storage_error, {
    showNotification("This browser could not save your changes. Download a backup from Settings.", type = "error", duration = 8)
  }, ignoreInit = TRUE)

  current_region <- reactive(input$season_region %||% state$settings$season_region %||% "Southeast")

  recipe_ingredients <- function(recipe_id) {
    state$ingredients$ingredient[state$ingredients$recipe_id == recipe_id]
  }

  recipe_seasonal <- function(recipe_id) {
    seasonal_matches(recipe_ingredients(recipe_id), current_region())
  }

  recipe_deals <- function(recipe_id) {
    deal_matches(recipe_ingredients(recipe_id), state$deals)
  }

  make_plan <- function(keep_locked = TRUE) {
    proteins <- input$proteins %||% state$settings$proteins
    if (!length(proteins)) {
      showNotification("Choose at least one protein in Settings.", type = "error")
      return()
    }
    locked <- if (keep_locked) state$plan else NULL
    state$plan <- tryCatch(
      generate_meal_plan(
        state$recipes, state$ingredients, proteins,
        pantry_items = state$pantry_items,
        recent_ids = state$recent_ids,
        locked_plan = locked,
        meal_type = "Dinner"
      ),
      error = function(e) {
        showNotification(conditionMessage(e), type = "error")
        NULL
      }
    )
  }

  make_secondary_plan <- function(meal_type, keep_locked = TRUE) {
    plan_key <- paste0(tolower(meal_type), "_plan")
    setting_key <- paste0("plan_", tolower(meal_type))
    if (!isTRUE(state$settings[[setting_key]])) {
      state[[plan_key]] <- NULL
      return()
    }
    locked <- if (keep_locked) state[[plan_key]] else NULL
    state[[plan_key]] <- tryCatch(
      generate_meal_plan(
        state$recipes, state$ingredients, all_proteins,
        pantry_items = state$pantry_items,
        recent_ids = state$recent_ids,
        locked_plan = locked,
        meal_type = meal_type
      ),
      error = function(e) {
        showNotification(conditionMessage(e), type = "error")
        NULL
      }
    )
  }

  observe({
    if (is.null(state$plan)) make_plan(keep_locked = FALSE)
    if (isTRUE(state$settings$plan_breakfast) && is.null(state$breakfast_plan)) make_secondary_plan("Breakfast", keep_locked = FALSE)
    if (isTRUE(state$settings$plan_lunch) && is.null(state$lunch_plan)) make_secondary_plan("Lunch", keep_locked = FALSE)
  })

  observeEvent(input$generate_plan, make_plan(keep_locked = TRUE), ignoreInit = TRUE)
  observeEvent(input$generate_breakfast_plan, make_secondary_plan("Breakfast", keep_locked = TRUE), ignoreInit = TRUE)
  observeEvent(input$generate_lunch_plan, make_secondary_plan("Lunch", keep_locked = TRUE), ignoreInit = TRUE)

  observeEvent(input$pantry_items, {
    state$pantry_items <- input$pantry_items %||% character()
    persist()
  }, ignoreInit = TRUE)

  observeEvent(input$save_settings, {
    if (!length(input$proteins)) {
      showNotification("Please keep at least one protein selected.", type = "error")
      return()
    }
    state$settings$proteins <- input$proteins
    state$settings$adults <- input$adults
    state$settings$toddlers <- input$toddlers
    state$settings$young_children <- input$young_children
    state$settings$lunch_servings <- input$lunch_servings
    persist()
    showNotification("Family settings saved!", type = "message")
  }, ignoreInit = TRUE)

  observeEvent(input$save_meal_options, {
    state$settings$plan_breakfast <- isTRUE(input$plan_breakfast)
    state$settings$plan_lunch <- isTRUE(input$plan_lunch)
    if (state$settings$plan_breakfast) make_secondary_plan("Breakfast", keep_locked = TRUE) else state$breakfast_plan <- NULL
    if (state$settings$plan_lunch) make_secondary_plan("Lunch", keep_locked = TRUE) else state$lunch_plan <- NULL
    persist()
    showNotification("Breakfast and lunch options saved.", type = "message")
  }, ignoreInit = TRUE)

  observeEvent(input$save_location, {
    zip <- trimws(input$zip_code %||% "")
    if (nzchar(zip) && !grepl("^[0-9]{5}$", zip)) {
      showNotification("Enter a five-digit ZIP code, or leave it blank.", type = "error")
      return()
    }
    state$settings$season_region <- input$season_region
    state$settings$zip_code <- zip
    persist()
    showNotification("Season and store location saved.", type = "message")
  }, ignoreInit = TRUE)

  observeEvent(input$save_week, {
    req(state$plan)
    planned_ids <- c(
      state$plan$recipe_id,
      if (!is.null(state$breakfast_plan)) state$breakfast_plan$recipe_id else character(),
      if (!is.null(state$lunch_plan)) state$lunch_plan$recipe_id else character()
    )
    state$recent_ids <- unique(c(planned_ids, state$recent_ids))
    state$recent_ids <- head(state$recent_ids, 40)
    persist()
    showNotification("This week was added to meal history.", type = "message")
  }, ignoreInit = TRUE)

  guess_imported_protein <- function(items) {
    text <- tolower(paste(items, collapse = " "))
    checks <- list(
      Chicken = "chicken|chicken breast|chicken thigh",
      Turkey = "turkey",
      Beef = "beef|steak|ground chuck|roast",
      Pork = "pork|ham|bacon|sausage",
      Fish = "fish|salmon|tuna|cod|tilapia|trout|shrimp"
    )
    for (protein in names(checks)) {
      if (grepl(checks[[protein]], text, perl = TRUE)) return(protein)
    }
    "Meatless"
  }

  output$recipe_import_status <- renderUI({
    status <- state$import_status
    if (is.null(status)) return(NULL)
    icon_text <- switch(status$kind, loading = "⏳", success = "✅", error = "⚠️", "ℹ️")
    div(
      class = paste("recipe-import-status", paste0("status-", status$kind)),
      span(class = "import-status-icon", icon_text),
      span(status$message)
    )
  })

  observeEvent(input$import_recipe_url, {
    url <- trimws(input$recipe_url %||% "")
    if (!grepl("^https?://[^[:space:]]+$", url, ignore.case = TRUE)) {
      state$import_status <- list(kind = "error", message = "Paste a complete recipe link beginning with http:// or https://.")
      return()
    }
    state$import_status <- list(kind = "loading", message = "Reading the recipe page… this can take several seconds.")
    session$sendCustomMessage("weeknight-five-import-recipe", list(url = url))
  }, ignoreInit = TRUE)

  observeEvent(input$recipe_import_result, {
    result <- input$recipe_import_result
    if (!is.list(result) || !isTRUE(result$ok)) {
      message <- if (is.list(result)) result$message %||% "That page could not be imported." else "That page could not be imported."
      state$import_status <- list(kind = "error", message = message)
      return()
    }

    imported <- result$recipe
    imported_items <- imported$ingredients %||% list()
    if (!length(imported_items)) {
      state$import_status <- list(kind = "error", message = "The page did not provide a readable ingredient list. The form was not changed.")
      return()
    }

    imported_items <- head(imported_items, 30)
    item_names <- vapply(imported_items, function(x) as.character(x$ingredient %||% ""), character(1))
    imported_number <- function(value, fallback) {
      number <- suppressWarnings(as.numeric(value %||% fallback))
      if (!length(number) || !is.finite(number[1]) || number[1] < 0) fallback else number[1]
    }
    imported_meal_type <- as.character(imported$meal_type %||% "Dinner")
    if (!imported_meal_type %in% meal_types) imported_meal_type <- "Dinner"
    state$ingredient_row_count <- length(imported_items)
    updateTextInput(session, "custom_name", value = imported$name %||% "Imported recipe")
    updateSelectInput(session, "custom_meal_type", selected = imported_meal_type)
    updateSelectInput(session, "custom_protein", selected = guess_imported_protein(item_names))
    updateNumericInput(session, "custom_minutes", value = max(5, min(480, as.numeric(imported$minutes %||% 30))))
    updateNumericInput(session, "custom_servings", value = max(1, min(30, as.numeric(imported$servings %||% 4))))
    updateNumericInput(session, "custom_calories", value = imported_number(imported$calories, 400))
    updateNumericInput(session, "custom_protein_g", value = imported_number(imported$protein_g, 25))
    updateNumericInput(session, "custom_fiber_g", value = imported_number(imported$fiber_g, 5))
    updateTextAreaInput(session, "custom_description", value = imported$description %||% "Imported family recipe")
    updateTextInput(session, "custom_source_url", value = imported$url %||% "")
    updateTextAreaInput(session, "custom_instructions", value = imported$instructions %||% "")
    updateTextAreaInput(session, "custom_kid_note", value = "Review the directions and serve in age-appropriate pieces.")
    updateCheckboxInput(session, "custom_gf_confirm", value = FALSE)

    session$onFlushed(function() {
      for (i in seq_along(imported_items)) {
        item <- imported_items[[i]]
        quantity <- suppressWarnings(as.numeric(item$quantity %||% 1))
        if (!is.finite(quantity) || quantity <= 0) quantity <- 1
        unit <- as.character(item$unit %||% "count")
        if (!unit %in% ingredient_units) unit <- "count"
        category <- as.character(item$category %||% "Pantry")
        if (!category %in% grocery_categories) category <- "Pantry"
        updateNumericInput(session, paste0("custom_qty_", i), value = quantity)
        updateSelectInput(session, paste0("custom_unit_", i), selected = unit)
        updateTextInput(session, paste0("custom_ingredient_", i), value = as.character(item$ingredient %||% ""))
        updateSelectInput(session, paste0("custom_category_", i), selected = category)
      }
    }, once = TRUE)

    state$import_status <- list(
      kind = "success",
      message = paste0("Form filled with ", length(imported_items), " ingredients. Review the quantities, choose the main protein, and complete the gluten-free check before saving.")
    )
  }, ignoreInit = TRUE)

  output$ingredient_editor <- renderUI({
    div(class = "ingredient-editor", lapply(seq_len(state$ingredient_row_count), function(i) {
      div(
        class = "ingredient-row",
        numericInput(paste0("custom_qty_", i), paste("Ingredient", i, "quantity"),
                     value = input[[paste0("custom_qty_", i)]] %||% 1, min = 0.01, step = 0.25),
        selectInput(paste0("custom_unit_", i), "Unit", choices = ingredient_units,
                    selected = input[[paste0("custom_unit_", i)]] %||% "count"),
        textInput(paste0("custom_ingredient_", i), "Ingredient",
                  value = input[[paste0("custom_ingredient_", i)]] %||% "", placeholder = "yellow onion"),
        selectInput(paste0("custom_category_", i), "Grocery section", choices = grocery_categories,
                    selected = input[[paste0("custom_category_", i)]] %||% "Produce")
      )
    }))
  })

  observeEvent(input$add_ingredient_row, {
    if (state$ingredient_row_count < 30) state$ingredient_row_count <- state$ingredient_row_count + 1
  }, ignoreInit = TRUE)

  observeEvent(input$remove_ingredient_row, {
    if (state$ingredient_row_count > 1) state$ingredient_row_count <- state$ingredient_row_count - 1
  }, ignoreInit = TRUE)

  observeEvent(input$save_custom_recipe, {
    recipe_name <- trimws(input$custom_name %||% "")
    instructions_text <- trimws(input$custom_instructions %||% "")
    if (!nzchar(recipe_name) || !nzchar(instructions_text)) {
      showNotification("Add a recipe name and directions before saving.", type = "error")
      return()
    }
    if (!isTRUE(input$custom_gf_confirm)) {
      showNotification("Confirm the recipe's gluten and cross-contact review before saving.", type = "error")
      return()
    }

    entered <- lapply(seq_len(state$ingredient_row_count), function(i) {
      list(
        quantity = suppressWarnings(as.numeric(input[[paste0("custom_qty_", i)]])),
        unit = input[[paste0("custom_unit_", i)]] %||% "count",
        ingredient = trimws(input[[paste0("custom_ingredient_", i)]] %||% ""),
        category = input[[paste0("custom_category_", i)]] %||% "Pantry"
      )
    })
    valid <- vapply(entered, function(x) nzchar(x$ingredient) && is.finite(x$quantity) && x$quantity > 0, logical(1))
    entered <- entered[valid]
    if (!length(entered)) {
      showNotification("Add at least one ingredient with a quantity.", type = "error")
      return()
    }

    slug <- gsub("(^_+|_+$)", "", gsub("[^a-z0-9]+", "_", tolower(recipe_name)))
    recipe_id <- paste0("custom_", slug, "_", as.integer(Sys.time()))
    new_recipe <- data.frame(
      recipe_id = recipe_id,
      recipe_name = recipe_name,
      protein = input$custom_protein,
      meal_type = input$custom_meal_type %||% "Dinner",
      minutes = as.numeric(input$custom_minutes),
      base_servings = as.numeric(input$custom_servings),
      calories = as.numeric(input$custom_calories %||% 400),
      protein_g = as.numeric(input$custom_protein_g %||% 25),
      fiber_g = as.numeric(input$custom_fiber_g %||% 5),
      description = trimws(input$custom_description %||% "Family recipe"),
      kid_note = trimws(input$custom_kid_note %||% "Serve in age-appropriate pieces."),
      instructions = instructions_text,
      source = "My recipe",
      source_url = trimws(input$custom_source_url %||% ""),
      stringsAsFactors = FALSE
    )
    new_ingredients <- do.call(rbind, lapply(entered, function(x) {
      data.frame(
        recipe_id = recipe_id, quantity = x$quantity, unit = x$unit,
        ingredient = x$ingredient, category = x$category,
        stringsAsFactors = FALSE
      )
    }))

    state$recipes <- rbind(state$recipes, new_recipe)
    state$ingredients <- rbind(state$ingredients, new_ingredients)
    persist_custom_recipes()
    updateSelectizeInput(session, "pantry_items", choices = sort(unique(state$ingredients$ingredient)),
                         selected = state$pantry_items, server = TRUE)
    updateSelectizeInput(session, "deal_ingredient", choices = sort(unique(state$ingredients$ingredient)), server = TRUE)
    custom <- state$recipes[state$recipes$source == "My recipe", , drop = FALSE]
    updateSelectInput(session, "delete_recipe_id", choices = setNames(custom$recipe_id, custom$recipe_name))
    updateTextInput(session, "custom_name", value = "")
    updateSelectInput(session, "custom_meal_type", selected = "Dinner")
    updateTextAreaInput(session, "custom_description", value = "")
    updateTextInput(session, "custom_source_url", value = "")
    updateTextAreaInput(session, "custom_instructions", value = "")
    updateTextAreaInput(session, "custom_kid_note", value = "")
    updateNumericInput(session, "custom_minutes", value = 30)
    updateNumericInput(session, "custom_servings", value = 4)
    updateNumericInput(session, "custom_calories", value = 400)
    updateNumericInput(session, "custom_protein_g", value = 25)
    updateNumericInput(session, "custom_fiber_g", value = 5)
    updateCheckboxInput(session, "custom_gf_confirm", value = FALSE)
    state$ingredient_row_count <- 4
    state$import_status <- NULL
    showNotification(paste(recipe_name, "was added to the rotation!"), type = "message", duration = 5)
  }, ignoreInit = TRUE)

  observeEvent(input$delete_custom_recipe, {
    id <- input$delete_recipe_id %||% ""
    if (!nzchar(id)) {
      showNotification("There is no saved recipe selected.", type = "warning")
      return()
    }
    recipe_name <- state$recipes$recipe_name[state$recipes$recipe_id == id][1]
    state$recipes <- state$recipes[state$recipes$recipe_id != id, , drop = FALSE]
    state$ingredients <- state$ingredients[state$ingredients$recipe_id != id, , drop = FALSE]
    state$recent_ids <- setdiff(state$recent_ids, id)
    persist_custom_recipes()
    persist()
    custom <- state$recipes[state$recipes$source == "My recipe", , drop = FALSE]
    updateSelectInput(session, "delete_recipe_id", choices = setNames(custom$recipe_id, custom$recipe_name))
    updateSelectizeInput(session, "pantry_items", choices = sort(unique(state$ingredients$ingredient)),
                         selected = state$pantry_items, server = TRUE)
    if (!is.null(state$plan) && id %in% state$plan$recipe_id) make_plan(keep_locked = FALSE)
    if (!is.null(state$breakfast_plan) && id %in% state$breakfast_plan$recipe_id) make_secondary_plan("Breakfast", keep_locked = FALSE)
    if (!is.null(state$lunch_plan) && id %in% state$lunch_plan$recipe_id) make_secondary_plan("Lunch", keep_locked = FALSE)
    showNotification(paste(recipe_name, "was removed."), type = "message")
  }, ignoreInit = TRUE)

  observeEvent(input$save_deal, {
    item <- trimws(input$deal_ingredient %||% "")
    offer <- trimws(input$deal_offer %||% "")
    if (!nzchar(item) || !nzchar(offer)) {
      showNotification("Add both the food item and its offer.", type = "error")
      return()
    }
    if (as.Date(input$deal_end) < as.Date(input$deal_start)) {
      showNotification("The deal end date must be on or after its start date.", type = "error")
      return()
    }
    new_deal <- data.frame(
      deal_id = paste0("deal_", as.integer(Sys.time())),
      store = input$deal_store,
      ingredient = item,
      offer = offer,
      start_date = as.Date(input$deal_start),
      end_date = as.Date(input$deal_end),
      stringsAsFactors = FALSE
    )
    state$deals <- rbind(state$deals, new_deal)
    persist_deals()
    updateSelectInput(session, "delete_deal_id",
                      choices = setNames(state$deals$deal_id, paste(state$deals$store, state$deals$ingredient, sep = " — ")))
    updateTextInput(session, "deal_offer", value = "")
    showNotification("Deal highlights added.", type = "message")
  }, ignoreInit = TRUE)

  observeEvent(input$delete_deal, {
    id <- input$delete_deal_id %||% ""
    if (!nzchar(id)) return()
    state$deals <- state$deals[state$deals$deal_id != id, , drop = FALSE]
    persist_deals()
    updateSelectInput(session, "delete_deal_id",
                      choices = setNames(state$deals$deal_id, paste(state$deals$store, state$deals$ingredient, sep = " — ")))
  }, ignoreInit = TRUE)

  show_recipe_details <- function(id, planned_portions) {
    recipe <- state$recipes[state$recipes$recipe_id == id, , drop = FALSE]
    ing <- state$ingredients[state$ingredients$recipe_id == id, , drop = FALSE]
    seasonal <- recipe_seasonal(id)
    sales <- recipe_deals(id)
    scale <- planned_portions / recipe$base_servings
    showModal(modalDialog(
      title = tagList(span(class = "modal-emoji", unname(protein_emoji[recipe$protein])), recipe$recipe_name),
      tags$p(class = "recipe-description", recipe$description),
      if (nzchar(recipe$source_url)) tags$a(
        class = "recipe-source-link", href = recipe$source_url, target = "_blank", rel = "noopener noreferrer",
        if (grepl("adaptation", recipe$source, ignore.case = TRUE)) "View source inspiration ↗" else "Open original recipe ↗"
      ),
      div(class = "recipe-meta-row", span(paste(recipe$minutes, "minutes")), span(paste(sprintf("%.1f", planned_portions), "planned portions")), span(recipe$meal_type)),
      div(class = "nutrition-strip",
          span(strong(round(recipe$calories)), " calories"),
          span(strong(round(recipe$protein_g)), "g protein"),
          span(strong(round(recipe$fiber_g)), "g fiber")),
      tags$p(class = "nutrition-disclaimer", "Nutrition is an estimate per serving."),
      if (length(seasonal)) div(class = "season-note", strong("In season: "), paste(seasonal, collapse = ", ")),
      if (nrow(sales)) div(class = "sale-note", strong("Matching deals: "), paste(paste(sales$store, sales$ingredient, sales$offer, sep = " — "), collapse = "; ")),
      tags$h4("Ingredients"),
      tags$ul(class = "ingredient-list", lapply(seq_len(nrow(ing)), function(j) {
        tags$li(sprintf("%s %s %s", format_quantity(ing$quantity[j] * scale), ing$unit[j], ing$ingredient[j]))
      })),
      tags$h4("Easy directions"),
      tags$p(recipe$instructions),
      div(class = "kid-note", strong("Little-kid note: "), recipe$kid_note),
      div(class = "gf-note", strong("Celiac check: "), "Use the certified gluten-free products named above and clean, dedicated or thoroughly sanitized equipment."),
      easyClose = TRUE,
      footer = modalButton("Done")
    ))
  }

  for (i in seq_len(5)) {
    local({
      position <- i
      observeEvent(input[[paste0("swap_", position)]], {
        req(state$plan)
        if (isTRUE(state$plan$locked[position])) {
          showNotification("Unlock this meal before swapping it.", type = "warning")
          return()
        }
        state$plan <- swap_meal(
          state$plan, position, state$recipes, state$ingredients,
          input$proteins %||% state$settings$proteins,
          state$pantry_items, state$recent_ids
        )
      }, ignoreInit = TRUE)

      observeEvent(input[[paste0("lock_", position)]], {
        req(state$plan)
        state$plan$locked[position] <- !state$plan$locked[position]
      }, ignoreInit = TRUE)

      observeEvent(input[[paste0("view_", position)]], {
        req(state$plan)
        id <- state$plan$recipe_id[position]
        recipe <- state$recipes[state$recipes$recipe_id == id, , drop = FALSE]
        ing <- state$ingredients[state$ingredients$recipe_id == id, , drop = FALSE]
        seasonal <- recipe_seasonal(id)
        sales <- recipe_deals(id)
        scale <- current_portions() / recipe$base_servings
        showModal(modalDialog(
          title = tagList(span(class = "modal-emoji", unname(protein_emoji[recipe$protein])), recipe$recipe_name),
          tags$p(class = "recipe-description", recipe$description),
          if (nzchar(recipe$source_url)) tags$a(
            class = "recipe-source-link", href = recipe$source_url, target = "_blank", rel = "noopener noreferrer",
            if (grepl("adaptation", recipe$source, ignore.case = TRUE)) "View source inspiration ↗" else "Open original recipe ↗"
          ),
          div(class = "recipe-meta-row", span(paste(recipe$minutes, "minutes")), span(paste(sprintf("%.1f", current_portions()), "planned portions")), span(recipe$protein)),
          div(class = "nutrition-strip",
              span(strong(round(recipe$calories)), " calories"),
              span(strong(round(recipe$protein_g)), "g protein"),
              span(strong(round(recipe$fiber_g)), "g fiber")),
          tags$p(class = "nutrition-disclaimer", "Nutrition is an estimate per serving."),
          if (length(seasonal)) div(class = "season-note", strong("In season: "), paste(seasonal, collapse = ", ")),
          if (nrow(sales)) div(class = "sale-note", strong("Matching deals: "), paste(paste(sales$store, sales$ingredient, sales$offer, sep = " — "), collapse = "; ")),
          tags$h4("Ingredients"),
          tags$ul(class = "ingredient-list", lapply(seq_len(nrow(ing)), function(j) {
            tags$li(sprintf("%s %s %s", format_quantity(ing$quantity[j] * scale), ing$unit[j], ing$ingredient[j]))
          })),
          tags$h4("Easy directions"),
          tags$p(recipe$instructions),
          div(class = "kid-note", strong("Little-kid note: "), recipe$kid_note),
          div(class = "gf-note", strong("Celiac check: "), "Use the certified gluten-free products named above and clean, dedicated or thoroughly sanitized equipment."),
          easyClose = TRUE,
          footer = modalButton("Done")
        ))
      }, ignoreInit = TRUE)
    })
  }

  for (meal_type in c("Breakfast", "Lunch")) {
    local({
      this_meal_type <- meal_type
      prefix <- tolower(this_meal_type)
      plan_key <- paste0(prefix, "_plan")
      for (i in seq_len(5)) {
        local({
          position <- i
          observeEvent(input[[paste0("swap_", prefix, "_", position)]], {
            plan <- state[[plan_key]]
            req(plan)
            if (isTRUE(plan$locked[position])) {
              showNotification("Unlock this meal before swapping it.", type = "warning")
              return()
            }
            state[[plan_key]] <- swap_meal(
              plan, position, state$recipes, state$ingredients, all_proteins,
              state$pantry_items, state$recent_ids, meal_type = this_meal_type
            )
          }, ignoreInit = TRUE)

          observeEvent(input[[paste0("lock_", prefix, "_", position)]], {
            plan <- state[[plan_key]]
            req(plan)
            plan$locked[position] <- !plan$locked[position]
            state[[plan_key]] <- plan
          }, ignoreInit = TRUE)

          observeEvent(input[[paste0("view_", prefix, "_", position)]], {
            plan <- state[[plan_key]]
            req(plan)
            show_recipe_details(plan$recipe_id[position], current_household_portions())
          }, ignoreInit = TRUE)
        })
      }
    })
  }

  output$portion_total <- renderText(sprintf("%.1f", current_portions()))

  output$plan_summary <- renderUI({
    req(state$plan)
    chosen <- state$recipes[match(state$plan$recipe_id, state$recipes$recipe_id), , drop = FALSE]
    quick_count <- sum(chosen$minutes <= 30)
    pantry_rates <- vapply(chosen$recipe_id, pantry_match, numeric(1), state$ingredients, state$pantry_items)
    sale_count <- sum(vapply(chosen$recipe_id, function(id) nrow(recipe_deals(id)) > 0, logical(1)))
    div(
      class = "summary-strip",
      div(class = "summary-item", strong(length(unique(chosen$protein))), span("protein groups")),
      div(class = "summary-item", strong(quick_count), span("quick dinners")),
      div(class = "summary-item", strong(sprintf("%d%%", round(mean(pantry_rates) * 100))), span("average pantry match")),
      div(class = "summary-item", strong(sale_count), span("dinners with deals"))
    )
  })

  output$meal_cards <- renderUI({
    req(state$plan)
    cards <- lapply(seq_len(nrow(state$plan)), function(i) {
      item <- state$recipes[state$recipes$recipe_id == state$plan$recipe_id[i], , drop = FALSE]
      seasonal <- recipe_seasonal(item$recipe_id)
      sales <- recipe_deals(item$recipe_id)
      locked <- isTRUE(state$plan$locked[i])
      div(
        class = paste("meal-card", paste0("accent-", tolower(item$protein))),
        div(class = "day-pill", state$plan$day[i]),
        div(class = "protein-icon", unname(protein_emoji[item$protein])),
        div(
          class = "meal-main",
          div(class = "meal-tags",
              span(class = "protein-tag", item$protein),
              span(class = "time-tag", paste("⏱", item$minutes, "min")),
              span(class = "nutrition-tag", paste(round(item$calories), "cal •", round(item$protein_g), "g protein •", round(item$fiber_g), "g fiber")),
              if (length(seasonal)) span(class = "season-badge", paste("🌱", length(seasonal), "in season")),
              if (nrow(sales)) span(class = "sale-badge", paste("🏷️", nrow(sales), "deal match"))),
          tags$h2(item$recipe_name),
          tags$p(item$description),
          div(class = "reason-line", if (nrow(sales)) paste("On sale at", paste(unique(sales$store), collapse = " + ")) else selection_reason(item$recipe_id, state$recipes, state$ingredients, state$pantry_items))
        ),
        div(
          class = "meal-actions",
          actionButton(paste0("view_", i), "Recipe", class = "card-button"),
          actionButton(paste0("swap_", i), "Swap", class = "card-button", disabled = if (locked) "disabled" else NULL),
          actionButton(paste0("lock_", i), if (locked) "🔒 Locked" else "🔓 Lock", class = if (locked) "card-button locked" else "card-button")
        )
      )
    })
    div(class = "meal-grid", cards)
  })

  secondary_plan_section <- function(meal_type, plan) {
    prefix <- tolower(meal_type)
    cards <- lapply(seq_len(nrow(plan)), function(i) {
      item <- state$recipes[state$recipes$recipe_id == plan$recipe_id[i], , drop = FALSE]
      locked <- isTRUE(plan$locked[i])
      div(
        class = "secondary-meal-card",
        div(class = "secondary-day", plan$day[i]),
        div(class = "secondary-meal-copy",
            tags$h3(item$recipe_name),
            tags$p(paste(item$minutes, "min •", round(item$calories), "cal •", round(item$protein_g), "g protein •", round(item$fiber_g), "g fiber"))),
        div(class = "secondary-meal-actions",
            actionButton(paste0("view_", prefix, "_", i), "Recipe", class = "card-button"),
            actionButton(paste0("swap_", prefix, "_", i), "Swap", class = "card-button", disabled = if (locked) "disabled" else NULL),
            actionButton(paste0("lock_", prefix, "_", i), if (locked) "🔒 Locked" else "🔓 Lock", class = if (locked) "card-button locked" else "card-button"))
      )
    })
    div(
      class = paste("secondary-plan-section", paste0(prefix, "-plan-section")),
      div(class = "secondary-plan-heading",
          div(tags$h2(paste(meal_type, "plan")), tags$p(paste("A lighter five-day", tolower(meal_type), "rotation for the same family week."))),
          actionButton(paste0("generate_", prefix, "_plan"), paste("Fresh", tolower(meal_type), "week"), class = "btn-soft")),
      div(class = "secondary-meal-grid", cards)
    )
  }

  output$breakfast_plan_ui <- renderUI({
    if (!isTRUE(state$settings$plan_breakfast)) return(NULL)
    req(state$breakfast_plan)
    secondary_plan_section("Breakfast", state$breakfast_plan)
  })

  output$lunch_plan_ui <- renderUI({
    if (!isTRUE(state$settings$plan_lunch)) return(NULL)
    req(state$lunch_plan)
    secondary_plan_section("Lunch", state$lunch_plan)
  })

  observeEvent(input$print_week, {
    session$sendCustomMessage("weeknight-five-print", list())
  }, ignoreInit = TRUE)

  output$print_week_plan <- renderUI({
    req(state$plan)
    include_breakfast <- isTRUE(state$settings$plan_breakfast) && !is.null(state$breakfast_plan)
    include_lunch <- isTRUE(state$settings$plan_lunch) && !is.null(state$lunch_plan)
    print_cell <- function(plan, i) {
      item <- state$recipes[state$recipes$recipe_id == plan$recipe_id[i], , drop = FALSE]
      tags$td(
        tags$strong(item$recipe_name),
        tags$small(paste(round(item$calories), "cal •", round(item$protein_g), "g protein •", round(item$fiber_g), "g fiber"))
      )
    }
    header_cells <- list(tags$th("Day"))
    if (include_breakfast) header_cells <- c(header_cells, list(tags$th("Breakfast")))
    if (include_lunch) header_cells <- c(header_cells, list(tags$th("Lunch")))
    header_cells <- c(header_cells, list(tags$th("Dinner")))
    rows <- lapply(seq_len(nrow(state$plan)), function(i) {
      cells <- list(tags$th(state$plan$day[i]))
      if (include_breakfast) cells <- c(cells, list(print_cell(state$breakfast_plan, i)))
      if (include_lunch) cells <- c(cells, list(print_cell(state$lunch_plan, i)))
      cells <- c(cells, list(print_cell(state$plan, i)))
      do.call(tags$tr, cells)
    })
    div(
      class = "print-week-plan",
      tags$h1("Weeknight Five - This Week's Meal Plan"),
      tags$p(class = "print-subtitle", paste("Gluten-free family plan • Printed", format(Sys.Date(), "%B %d, %Y"))),
      tags$table(class = "print-plan-table", tags$thead(do.call(tags$tr, header_cells)), tags$tbody(rows)),
      tags$p(class = "print-footer-note", "Nutrition values are estimates per serving. Continue checking labels and cross-contact risks for every meal.")
    )
  })

  output$pantry_summary <- renderUI({
    count <- length(state$pantry_items)
    div(class = "pantry-count", strong(count), span(if (count == 1) " ingredient marked on hand" else " ingredients marked on hand"))
  })

  output$custom_recipe_summary <- renderUI({
    custom <- state$recipes[state$recipes$source == "My recipe", , drop = FALSE]
    if (!nrow(custom)) {
      return(div(class = "mini-empty-state", "No family recipes yet. Your first saved recipe will appear here."))
    }
    div(class = "saved-recipe-list", lapply(seq_len(nrow(custom)), function(i) {
      count <- sum(state$ingredients$recipe_id == custom$recipe_id[i])
      div(class = "saved-recipe-item",
          span(class = "protein-icon tiny", unname(protein_emoji[custom$protein[i]])),
          div(
            strong(custom$recipe_name[i]),
            tags$small(paste(custom$meal_type[i], "•", custom$protein[i], "•", custom$minutes[i], "min •", count, "ingredients")),
            tags$small(class = "saved-nutrition", paste(round(custom$calories[i]), "cal •", round(custom$protein_g[i]), "g protein •", round(custom$fiber_g[i]), "g fiber")),
            if (nzchar(custom$source_url[i])) tags$a(class = "saved-source-link", href = custom$source_url[i], target = "_blank", rel = "noopener noreferrer", "Original recipe ↗")
          ))
    }))
  })

  output$seasonal_now <- renderUI({
    current <- seasonal_items(current_region())
    if (!nrow(current)) return(div(class = "mini-empty-state", "No seasonal matches are listed for this month."))
    div(class = "season-chip-list", lapply(current$item, function(item) span(class = "season-chip", paste("🌱", item))))
  })

  output$active_deals_ui <- renderUI({
    current <- active_deals(state$deals)
    if (!nrow(current)) {
      return(div(class = "mini-empty-state", "No active food deals yet. Open an ad and add the offers worth planning around."))
    }
    div(class = "active-deal-list", lapply(seq_len(nrow(current)), function(i) {
      div(class = paste("active-deal-item", paste0("store-", gsub("[^a-z]", "", tolower(current$store[i])))),
          div(strong(current$ingredient[i]), span(class = "store-name", current$store[i])),
          tags$p(current$offer[i]),
          small(paste(format(current$start_date[i], "%b %d"), "–", format(current$end_date[i], "%b %d"))))
    }))
  })

  output$recipe_gallery <- renderUI({
    filtered <- state$recipes[state$recipes$minutes <= input$recipe_time, , drop = FALSE]
    if (!identical(input$recipe_meal_type, "All")) {
      filtered <- filtered[filtered$meal_type == input$recipe_meal_type, , drop = FALSE]
    }
    if (!identical(input$recipe_protein, "All")) {
      filtered <- filtered[filtered$protein == input$recipe_protein, , drop = FALSE]
    }
    if (!nrow(filtered)) return(div(class = "empty-state", "No recipes match these filters."))
    div(class = "recipe-grid", lapply(seq_len(nrow(filtered)), function(i) {
      item <- filtered[i, , drop = FALSE]
      seasonal <- recipe_seasonal(item$recipe_id)
      sales <- recipe_deals(item$recipe_id)
      div(
        class = paste("recipe-card", paste0("accent-", tolower(item$protein))),
        div(class = "recipe-card-top", span(class = "protein-icon small", unname(protein_emoji[item$protein])), span(class = "protein-tag", item$protein)),
        tags$h3(item$recipe_name),
        tags$p(item$description),
        div(class = "card-badges",
            if (length(seasonal)) span(class = "season-badge", paste("🌱", paste(seasonal, collapse = ", "))),
            if (nrow(sales)) span(class = "sale-badge", paste("🏷️", paste(unique(sales$store), collapse = " + ")))),
        div(class = "nutrition-card-row", span(paste(round(item$calories), "cal")), span(paste(round(item$protein_g), "g protein")), span(paste(round(item$fiber_g), "g fiber"))),
        div(class = "recipe-footer", span(item$meal_type), span(paste("⏱", item$minutes, "min")), span(paste(item$base_servings, "base servings")), span(item$source))
      )
    }))
  })

  current_grocery <- reactive({
    req(state$plan)
    lists <- list(grocery_list(state$plan, state$recipes, state$ingredients, current_portions(), state$pantry_items))
    if (isTRUE(state$settings$plan_breakfast) && !is.null(state$breakfast_plan)) {
      lists <- c(lists, list(grocery_list(state$breakfast_plan, state$recipes, state$ingredients, current_household_portions(), state$pantry_items)))
    }
    if (isTRUE(state$settings$plan_lunch) && !is.null(state$lunch_plan)) {
      lists <- c(lists, list(grocery_list(state$lunch_plan, state$recipes, state$ingredients, current_household_portions(), state$pantry_items)))
    }
    lists <- lists[vapply(lists, nrow, integer(1)) > 0]
    if (!length(lists)) return(data.frame(category = character(), ingredient = character(), unit = character(), quantity = numeric()))
    combined <- do.call(rbind, lists)
    result <- stats::aggregate(quantity ~ category + ingredient + unit, combined, sum)
    result[order(result$category, result$ingredient), , drop = FALSE]
  })

  output$grocery_list_ui <- renderUI({
    groceries <- current_grocery()
    if (!nrow(groceries)) return(div(class = "empty-state", tags$h3("Your pantry has it covered!"), tags$p("Nothing remains on the list.")))
    categories <- unique(groceries$category)
    div(class = "grocery-columns", lapply(seq_along(categories), function(category_index) {
      category <- categories[category_index]
      rows <- groceries[groceries$category == category, , drop = FALSE]
      div(
        class = "grocery-category content-card",
        tags$h2(category),
        lapply(seq_len(nrow(rows)), function(i) {
          seasonal <- length(seasonal_matches(rows$ingredient[i], current_region())) > 0
          sales <- deal_matches(rows$ingredient[i], state$deals)
          flags <- paste(c(if (seasonal) "🌱" else NULL, if (nrow(sales)) "🏷️" else NULL), collapse = " ")
          checkboxInput(
            paste0("grocery_", category_index, "_", i),
            label = trimws(sprintf("%s %s — %s %s", format_quantity(rows$quantity[i]), rows$unit[i], rows$ingredient[i], flags)),
            value = FALSE
          )
        })
      )
    }))
  })

  output$download_backup <- downloadHandler(
    filename = function() paste0("weeknight-five-backup-", Sys.Date(), ".rds"),
    content = function(file) {
      saveRDS(
        list(
          format_version = 1L,
          created_at = as.character(Sys.time()),
          state = isolate(saved_state_data()),
          custom_data = isolate(saved_custom_data()),
          deals = isolate(state$deals)
        ),
        file,
        version = 2
      )
    }
  )

  observeEvent(input$restore_backup, {
    upload <- input$restore_backup
    req(upload$datapath)
    backup <- tryCatch(readRDS(upload$datapath), error = function(e) NULL)
    valid <- is.list(backup) && is.list(backup$state) && is.list(backup$custom_data) &&
      is.data.frame(backup$custom_data$recipes) && is.data.frame(backup$custom_data$ingredients) &&
      is.data.frame(backup$deals)
    if (!valid) {
      restore_pending(NULL)
      showNotification("That file is not a valid Weeknight Five backup.", type = "error", duration = 7)
      return()
    }
    restore_pending(backup)
    showModal(modalDialog(
      title = "Restore this backup?",
      tags$p("This will replace the pantry, settings, meal history, personal recipes, and deals currently saved in this browser."),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_restore", "Restore backup", class = "btn-rainbow")
      ),
      easyClose = TRUE
    ))
  }, ignoreInit = TRUE)

  observeEvent(input$confirm_restore, {
    backup <- restore_pending()
    req(backup)
    ok <- apply_saved_state(backup$state) &&
      apply_custom_data(backup$custom_data) &&
      apply_deals(backup$deals)
    if (!ok) {
      showNotification("The backup could not be restored.", type = "error", duration = 7)
      return()
    }
    persist()
    persist_custom_recipes()
    persist_deals()
    restore_pending(NULL)
    removeModal()
    showNotification("Your Weeknight Five backup was restored.", type = "message", duration = 6)
  }, ignoreInit = TRUE)

  output$download_grocery <- downloadHandler(
    filename = function() paste0("weeknight-five-grocery-list-", Sys.Date(), ".csv"),
    content = function(file) utils::write.csv(isolate(current_grocery()), file, row.names = FALSE)
  )
}

shinyApp(ui, server)
