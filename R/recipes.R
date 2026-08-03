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
                        meal_type = "Dinner", calories = NA_real_, protein_g = NA_real_,
                        fiber_g = NA_real_, source = "Built in", source_url = "") {
  list(
    meta = data.frame(
      recipe_id = id,
      recipe_name = name,
      protein = protein,
      meal_type = meal_type,
      minutes = minutes,
      base_servings = 4,
      calories = calories,
      protein_g = protein_g,
      fiber_g = fiber_g,
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

builtin_recipe_data <- function() {
  recipes <- list(
    make_recipe(
      "chicken_sheet_pan", "Lemon-Herb Sheet Pan Chicken", "Chicken", 35,
      "Chicken, potatoes, and broccoli roast together on one colorful pan.",
      "Heat oven to 425°F. Toss halved potatoes with half the oil and roast 10 minutes. Add chicken and broccoli, drizzle with remaining oil, lemon, garlic, and herbs. Roast 20–25 minutes, until chicken reaches 165°F.",
      c("1.5|lb|boneless chicken thighs|Meat & Seafood", "1.5|lb|baby potatoes|Produce", "5|cup|broccoli florets|Produce", "2|tbsp|olive oil|Pantry", "1|count|lemon|Produce", "1|tsp|garlic powder|Pantry", "1|tsp|Italian seasoning (certified GF)|Pantry")
    ),
    make_recipe(
      "chicken_taco_bowls", "Mild Chicken Taco Rice Bowls", "Chicken", 30,
      "Build-your-own bowls make it easy to serve every ingredient separately.",
      "Cook rice. Dice and sauté chicken in oil with the mild seasoning until it reaches 165°F. Warm beans and corn. Set out rice, chicken, beans, corn, avocado, cheese, and lime for everyone to build a bowl.",
      c("1.25|lb|boneless chicken breast|Meat & Seafood", "1.5|cup|white rice|Pantry", "1|can|black beans|Pantry", "1|cup|frozen corn|Frozen", "1|count|avocado|Produce", "1|cup|shredded cheddar cheese|Dairy", "1|count|lime|Produce", "1|tbsp|olive oil|Pantry", "2|tsp|mild taco seasoning (certified GF)|Pantry"),
      "Offer the components separately; omit seasoning from a child portion if preferred."
    ),
    make_recipe(
      "chicken_honey_mustard", "Honey-Mustard Chicken and Carrots", "Chicken", 35,
      "A gentle sweet-and-savory skillet with peas and carrots.",
      "Whisk mustard, honey, broth, and cornstarch. Brown chicken pieces in oil. Add carrots and sauce, cover, and simmer until chicken reaches 165°F and carrots are tender. Stir in peas and serve with rice.",
      c("1.5|lb|boneless chicken thighs|Meat & Seafood", "4|count|carrots|Produce", "1|cup|frozen peas|Frozen", "1.5|cup|white rice|Pantry", "2|tbsp|Dijon mustard (certified GF)|Pantry", "2|tbsp|honey|Pantry", "1|cup|chicken broth (certified GF)|Pantry", "1|tbsp|cornstarch|Pantry", "1|tbsp|olive oil|Pantry")
    ),
    make_recipe(
      "chicken_fried_rice", "Easy Chicken Fried Rice", "Chicken", 25,
      "A quick one-pan dinner that is ideal for leftover rice.",
      "Cook diced chicken in oil until it reaches 165°F and set aside. Scramble eggs in the same skillet. Add cold rice, peas, carrots, chicken, and tamari; stir-fry until hot throughout.",
      c("1|lb|boneless chicken breast|Meat & Seafood", "4|cup|cooked white rice|Pantry", "3|count|eggs|Dairy", "2|cup|frozen peas and carrots|Frozen", "3|tbsp|tamari (certified GF)|Pantry", "1|tbsp|sesame oil|Pantry", "1|tbsp|olive oil|Pantry")
    ),
    make_recipe(
      "turkey_meatballs", "Baked Turkey Meatballs and Pasta", "Turkey", 35,
      "Tender oven-baked meatballs with gluten-free pasta and tomato sauce.",
      "Heat oven to 400°F. Mix turkey, egg, crumbs, Parmesan, and seasoning. Form small meatballs and bake 15–18 minutes to 165°F. Cook pasta according to package directions, warm sauce, and combine.",
      c("1.25|lb|ground turkey|Meat & Seafood", "1|count|egg|Dairy", "0.5|cup|gluten-free breadcrumbs|Pantry", "0.25|cup|grated Parmesan|Dairy", "1|tsp|Italian seasoning (certified GF)|Pantry", "12|oz|gluten-free pasta|Pantry", "24|oz|marinara sauce (certified GF)|Pantry"),
      "Cut meatballs and pasta into age-appropriate pieces."
    ),
    make_recipe(
      "turkey_taco_skillet", "Mild Turkey Taco Skillet", "Turkey", 25,
      "A simple skillet of turkey, rice, beans, corn, and melted cheese.",
      "Brown turkey in a large skillet. Stir in seasoning, cooked rice, drained beans, corn, and tomatoes. Heat through, top with cheese, cover until melted, and serve.",
      c("1.25|lb|ground turkey|Meat & Seafood", "3|cup|cooked white rice|Pantry", "1|can|black beans|Pantry", "1|cup|frozen corn|Frozen", "1|can|diced tomatoes|Pantry", "1|cup|shredded cheddar cheese|Dairy", "2|tsp|mild taco seasoning (certified GF)|Pantry")
    ),
    make_recipe(
      "turkey_burgers", "Turkey Burgers and Sweet Potato Wedges", "Turkey", 35,
      "Juicy bunless turkey burgers with oven-roasted sweet potatoes.",
      "Heat oven to 425°F. Cut sweet potatoes into wedges, toss with half the oil, and roast 25–30 minutes. Mix turkey with garlic powder, form patties, and cook in remaining oil to 165°F. Serve with lettuce, tomato, and cheese.",
      c("1.5|lb|ground turkey|Meat & Seafood", "3|count|sweet potatoes|Produce", "2|tbsp|olive oil|Pantry", "1|tsp|garlic powder|Pantry", "1|count|lettuce|Produce", "2|count|tomatoes|Produce", "6|slice|cheddar cheese|Dairy"),
      "Serve a crumbled patty and soft wedges rather than a whole burger."
    ),
    make_recipe(
      "beef_potato_skillet", "Cheesy Beef and Potato Skillet", "Beef", 35,
      "A cozy one-pan meal with ground beef, tender potatoes, and green beans.",
      "Brown beef in a deep skillet and drain if needed. Add thinly sliced potatoes, broth, garlic powder, and paprika. Cover and simmer until tender. Stir in green beans, top with cheese, and cover until melted.",
      c("1.25|lb|ground beef|Meat & Seafood", "1.5|lb|yellow potatoes|Produce", "2|cup|green beans|Produce", "1|cup|beef broth (certified GF)|Pantry", "1|tsp|garlic powder|Pantry", "0.5|tsp|sweet paprika (certified GF)|Pantry", "1|cup|shredded cheddar cheese|Dairy")
    ),
    make_recipe(
      "beef_taco_bowls", "Mild Beef Taco Bowls", "Beef", 25,
      "A fast, flexible dinner with seasoned beef and colorful toppings.",
      "Cook rice. Brown beef, drain if needed, and add mild seasoning plus a splash of water. Set out beef, rice, lettuce, tomato, avocado, cheese, and yogurt in separate bowls.",
      c("1.25|lb|ground beef|Meat & Seafood", "1.5|cup|white rice|Pantry", "2|tsp|mild taco seasoning (certified GF)|Pantry", "1|count|lettuce|Produce", "2|count|tomatoes|Produce", "1|count|avocado|Produce", "1|cup|shredded cheddar cheese|Dairy", "0.5|cup|plain Greek yogurt|Dairy")
    ),
    make_recipe(
      "beef_pot_roast", "Slow Cooker Beef Pot Roast", "Beef", 20,
      "Ten minutes of morning prep produces a complete, tender dinner.",
      "Place vegetables in the slow cooker and set beef on top. Whisk broth, tomato paste, and herbs; pour over beef. Cook on low 8 hours or high 4–5 hours, until very tender. Shred or slice before serving.",
      c("2.5|lb|beef chuck roast|Meat & Seafood", "1.5|lb|baby potatoes|Produce", "5|count|carrots|Produce", "1|count|yellow onion|Produce", "2|cup|beef broth (certified GF)|Pantry", "2|tbsp|tomato paste|Pantry", "1|tsp|dried thyme (certified GF)|Pantry"),
      "Shred meat finely and serve very soft vegetables in age-appropriate pieces."
    ),
    make_recipe(
      "pork_apple_sheet_pan", "Sheet Pan Pork Chops, Apples, and Carrots", "Pork", 35,
      "Pork and naturally sweet apples roast together on one pan.",
      "Heat oven to 425°F. Toss sliced carrots and apples with oil and thyme; roast 10 minutes. Add pork chops, season lightly, and roast 12–16 minutes until pork reaches 145°F, then rest 3 minutes.",
      c("1.5|lb|boneless pork chops|Meat & Seafood", "3|count|apples|Produce", "5|count|carrots|Produce", "2|tbsp|olive oil|Pantry", "1|tsp|dried thyme (certified GF)|Pantry", "1.5|lb|baby potatoes|Produce")
    ),
    make_recipe(
      "pork_tenderloin", "Maple Pork Tenderloin with Green Beans", "Pork", 35,
      "A mild maple glaze makes this simple roasted pork especially family-friendly.",
      "Heat oven to 425°F. Stir maple syrup, mustard, and garlic powder. Brush over pork and roast 20–25 minutes to 145°F. Rest 3 minutes. Steam green beans and serve with cooked rice.",
      c("1.5|lb|pork tenderloin|Meat & Seafood", "2|tbsp|maple syrup|Pantry", "1|tbsp|Dijon mustard (certified GF)|Pantry", "1|tsp|garlic powder|Pantry", "1.5|lb|green beans|Produce", "1.5|cup|white rice|Pantry")
    ),
    make_recipe(
      "pork_fried_rice", "Pork and Pineapple Fried Rice", "Pork", 25,
      "A quick sweet-savory skillet using ground pork and frozen vegetables.",
      "Brown pork in a large skillet. Push it aside and scramble eggs. Add rice, vegetables, drained pineapple, tamari, and sesame oil. Stir-fry until everything is hot and pork is fully cooked.",
      c("1|lb|ground pork|Meat & Seafood", "4|cup|cooked white rice|Pantry", "2|count|eggs|Dairy", "2|cup|frozen peas and carrots|Frozen", "1|can|pineapple chunks|Pantry", "3|tbsp|tamari (certified GF)|Pantry", "1|tbsp|sesame oil|Pantry")
    )
  )

  dinner_nutrition <- data.frame(
    recipe_id = c(
      "chicken_sheet_pan", "chicken_taco_bowls", "chicken_honey_mustard", "chicken_fried_rice",
      "turkey_meatballs", "turkey_taco_skillet", "turkey_burgers", "beef_potato_skillet",
      "beef_taco_bowls", "beef_pot_roast", "pork_apple_sheet_pan", "pork_tenderloin",
      "pork_fried_rice", "salmon_rice", "fish_tacos", "lemon_cod",
      "black_bean_quesadillas", "chickpea_coconut", "lentil_pasta", "veggie_egg_rice"
    ),
    calories = c(520, 560, 540, 510, 590, 570, 560, 610, 620, 590, 540, 520, 560, 610, 500, 530, 520, 570, 560, 490),
    protein_g = c(40, 39, 38, 35, 39, 38, 42, 38, 40, 45, 40, 42, 32, 43, 38, 40, 22, 19, 25, 23),
    fiber_g = c(8, 10, 7, 5, 7, 10, 8, 7, 9, 8, 9, 6, 6, 7, 8, 8, 12, 13, 12, 7),
    stringsAsFactors = FALSE
  )

  for (column in c("calories", "protein_g", "fiber_g")) {
    index <- match(vapply(recipes, function(x) x$meta$recipe_id, character(1)), dinner_nutrition$recipe_id)
    values <- dinner_nutrition[[column]][index]
    for (i in which(!is.na(values))) recipes[[i]]$meta[[column]] <- values[i]
  }

  list(
    recipes = do.call(rbind, lapply(recipes, `[[`, "meta")),
    ingredients = do.call(rbind, lapply(recipes, `[[`, "ingredients"))
  )
}
