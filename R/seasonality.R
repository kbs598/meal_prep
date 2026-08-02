season_record <- function(item, pattern, northeast, southeast, midwest, southwest, west) {
  data.frame(
    item = item,
    pattern = pattern,
    Northeast = northeast,
    Southeast = southeast,
    Midwest = midwest,
    Southwest = southwest,
    West = west,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

seasonal_calendar <- function() {
  rbind(
    season_record("Apples", "apple", "8,9,10,11", "7,8,9,10,11", "8,9,10,11", "7,8,9,10", "7,8,9,10,11"),
    season_record("Avocados", "avocado", "", "3,4,5,6,7,8,9", "", "2,3,4,5,6,7,8,9", "2,3,4,5,6,7,8,9"),
    season_record("Broccoli", "broccoli", "6,7,8,9,10,11", "1,2,3,4,10,11,12", "6,7,8,9,10", "1,2,3,4,10,11,12", "1,2,3,4,5,10,11,12"),
    season_record("Cabbage", "cabbage", "6,7,8,9,10,11", "1,2,3,4,5,10,11,12", "6,7,8,9,10,11", "1,2,3,4,10,11,12", "1,2,3,4,5,10,11,12"),
    season_record("Carrots", "carrot", "6,7,8,9,10,11", "1,2,3,4,5,10,11,12", "6,7,8,9,10,11", "1,2,3,4,10,11,12", "1,2,3,4,5,6,10,11,12"),
    season_record("Corn", "corn", "7,8,9", "5,6,7,8,9", "7,8,9", "5,6,7,8,9", "6,7,8,9"),
    season_record("Green beans", "green beans", "7,8,9", "4,5,6,7,8,9,10", "7,8,9", "4,5,6,7,8,9,10", "5,6,7,8,9,10"),
    season_record("Leafy greens", "spinach|lettuce", "5,6,7,8,9,10", "1,2,3,4,5,10,11,12", "5,6,7,8,9,10", "1,2,3,4,10,11,12", "1,2,3,4,5,10,11,12"),
    season_record("Lemons and limes", "lemon|lime", "", "10,11,12,1,2,3,4", "", "10,11,12,1,2,3,4,5", "10,11,12,1,2,3,4,5"),
    season_record("Onions", "onion", "7,8,9,10", "4,5,6,7,8,9,10", "7,8,9,10", "4,5,6,7,8,9,10", "4,5,6,7,8,9,10"),
    season_record("Peas", "peas", "5,6,7", "2,3,4,5", "5,6,7", "2,3,4,5", "2,3,4,5,6"),
    season_record("Peppers", "pepper", "7,8,9,10", "5,6,7,8,9,10", "7,8,9,10", "5,6,7,8,9,10", "5,6,7,8,9,10"),
    season_record("Potatoes", "potato", "6,7,8,9,10", "4,5,6,7,8,9,10", "6,7,8,9,10", "4,5,6,7,8,9,10", "4,5,6,7,8,9,10"),
    season_record("Sweet potatoes", "sweet potato", "8,9,10,11", "7,8,9,10,11,12", "8,9,10,11", "7,8,9,10,11", "7,8,9,10,11"),
    season_record("Tomatoes", "tomato", "7,8,9", "5,6,7,8,9,10", "7,8,9", "5,6,7,8,9,10", "5,6,7,8,9,10"),
    season_record("Winter squash", "squash", "8,9,10,11", "8,9,10,11,12", "8,9,10,11", "8,9,10,11", "8,9,10,11"),
    season_record("Berries", "strawberr|blueberr|raspberr|blackberr", "6,7,8", "3,4,5,6", "6,7,8", "3,4,5,6", "3,4,5,6,7,8"),
    season_record("Peaches", "peach", "7,8,9", "5,6,7,8", "7,8,9", "5,6,7,8", "5,6,7,8,9")
  )
}

seasonal_items <- function(region = "Southeast", month = as.integer(format(Sys.Date(), "%m"))) {
  calendar <- seasonal_calendar()
  if (!region %in% c("Northeast", "Southeast", "Midwest", "Southwest", "West")) {
    region <- "Southeast"
  }
  in_month <- vapply(calendar[[region]], function(months) {
    if (!nzchar(months)) return(FALSE)
    month %in% as.integer(strsplit(months, ",", fixed = TRUE)[[1]])
  }, logical(1))
  calendar[in_month, c("item", "pattern"), drop = FALSE]
}

seasonal_matches <- function(ingredient_names, region = "Southeast", month = as.integer(format(Sys.Date(), "%m"))) {
  current <- seasonal_items(region, month)
  if (!length(ingredient_names) || !nrow(current)) return(character())
  matched <- vapply(seq_len(nrow(current)), function(i) {
    any(grepl(current$pattern[i], ingredient_names, ignore.case = TRUE))
  }, logical(1))
  current$item[matched]
}

active_deals <- function(deals, date = Sys.Date()) {
  if (is.null(deals) || !nrow(deals)) return(empty_deals())
  deals[deals$start_date <= date & deals$end_date >= date, , drop = FALSE]
}

item_matches <- function(deal_item, ingredient_name) {
  deal_item <- trimws(tolower(deal_item))
  ingredient_name <- trimws(tolower(ingredient_name))
  nzchar(deal_item) && (grepl(deal_item, ingredient_name, fixed = TRUE) ||
    grepl(ingredient_name, deal_item, fixed = TRUE))
}

deal_matches <- function(ingredient_names, deals, date = Sys.Date()) {
  current <- active_deals(deals, date)
  if (!length(ingredient_names) || !nrow(current)) return(current[0, , drop = FALSE])
  matched <- vapply(seq_len(nrow(current)), function(i) {
    any(vapply(ingredient_names, function(ingredient) item_matches(current$ingredient[i], ingredient), logical(1)))
  }, logical(1))
  current[matched, , drop = FALSE]
}

