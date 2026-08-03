# Curated adaptations based on recipe concepts from TheMealDB's official API
# and the openly licensed Wikibooks Cookbook. Directions below are original,
# simplified for this app, and all gluten-containing staples are replaced with
# certified gluten-free alternatives. See ATTRIBUTION.md for source and license
# information. Nutrition values are planning estimates per serving.

expanded_ingredient_tokens <- function() {
  c(
    chicken_breast = "1.5|lb|boneless chicken breast|Meat & Seafood",
    chicken_thighs = "1.5|lb|boneless chicken thighs|Meat & Seafood",
    ground_turkey = "1.25|lb|ground turkey|Meat & Seafood",
    turkey_cutlets = "1.5|lb|turkey cutlets|Meat & Seafood",
    ground_beef = "1.25|lb|ground beef|Meat & Seafood",
    beef_stew = "1.5|lb|beef stew meat|Meat & Seafood",
    chuck_roast = "2.5|lb|beef chuck roast|Meat & Seafood",
    pork_chops = "1.5|lb|boneless pork chops|Meat & Seafood",
    pork_tenderloin = "1.5|lb|pork tenderloin|Meat & Seafood",
    ground_pork = "1.25|lb|ground pork|Meat & Seafood",
    mild_sausage = "1|lb|mild sausage (certified GF)|Meat & Seafood",
    salmon = "1.5|lb|salmon fillets|Meat & Seafood",
    cod = "1.5|lb|cod fillets|Meat & Seafood",
    shrimp = "1.5|lb|peeled shrimp|Meat & Seafood",
    canned_tuna = "3|can|tuna|Pantry",
    canned_salmon = "3|can|salmon|Pantry",
    eggs = "8|count|eggs|Dairy",
    eggs_ten = "10|count|eggs|Dairy",
    tofu = "24|oz|firm tofu (certified GF)|Produce",
    chickpeas = "2|can|chickpeas|Pantry",
    chickpea_flour = "1.5|cup|chickpea flour (certified GF)|Pantry",
    black_beans = "2|can|black beans|Pantry",
    white_beans = "2|can|white beans|Pantry",
    lentils = "2|can|lentils|Pantry",
    rice = "1.5|cup|white rice|Pantry",
    cooked_rice = "4|cup|cooked white rice|Pantry",
    brown_rice = "1.5|cup|brown rice|Pantry",
    quinoa = "1.5|cup|quinoa|Pantry",
    potatoes = "1.5|lb|yellow potatoes|Produce",
    sweet_potatoes = "3|count|sweet potatoes|Produce",
    gf_pasta = "12|oz|gluten-free pasta|Pantry",
    corn_tortillas = "12|count|corn tortillas (certified GF)|Bakery",
    gf_bread = "8|slice|gluten-free bread|Bakery",
    gf_crackers = "8|oz|gluten-free crackers|Pantry",
    gf_crumbs = "0.5|cup|gluten-free breadcrumbs|Pantry",
    gf_flour = "1.5|cup|gluten-free all-purpose flour|Pantry",
    oats = "2|cup|rolled oats (certified GF)|Pantry",
    cornmeal = "1.5|cup|cornmeal (certified GF)|Pantry",
    buckwheat = "1.5|cup|buckwheat flour (certified GF)|Pantry",
    broccoli = "4|cup|broccoli florets|Produce",
    carrots = "4|count|carrots|Produce",
    peas = "2|cup|frozen peas|Frozen",
    green_beans = "4|cup|green beans|Produce",
    spinach = "5|oz|baby spinach|Produce",
    tomatoes = "3|count|tomatoes|Produce",
    diced_tomatoes = "1|can|diced tomatoes|Pantry",
    bell_peppers = "3|count|bell peppers|Produce",
    zucchini = "3|count|zucchini|Produce",
    mushrooms = "8|oz|mushrooms|Produce",
    onion = "1|count|yellow onion|Produce",
    cabbage = "4|cup|shredded cabbage|Produce",
    cucumber = "2|count|cucumbers|Produce",
    corn = "2|cup|frozen corn|Frozen",
    pumpkin = "3|cup|cubed pumpkin or butternut squash|Produce",
    cauliflower = "1|head|cauliflower|Produce",
    eggplant = "2|count|eggplant|Produce",
    avocado = "2|count|avocados|Produce",
    berries = "2|cup|mixed berries|Produce",
    bananas = "3|count|bananas|Produce",
    apples = "3|count|apples|Produce",
    pears = "3|count|pears|Produce",
    peaches = "3|count|peaches|Produce",
    lemon = "1|count|lemon|Produce",
    lime = "2|count|limes|Produce",
    milk = "3|cup|milk|Dairy",
    yogurt = "2|cup|plain Greek yogurt|Dairy",
    cottage_cheese = "3|cup|cottage cheese|Dairy",
    cheddar = "1.5|cup|shredded cheddar cheese|Dairy",
    parmesan = "0.5|cup|grated Parmesan|Dairy",
    butter = "2|tbsp|butter|Dairy",
    coconut_milk = "1|can|coconut milk|Pantry",
    broth = "4|cup|chicken broth (certified GF)|Pantry",
    veg_broth = "4|cup|vegetable broth (certified GF)|Pantry",
    marinara = "24|oz|marinara sauce (certified GF)|Pantry",
    olive_oil = "2|tbsp|olive oil|Pantry",
    tamari = "3|tbsp|tamari (certified GF)|Pantry",
    maple = "2|tbsp|maple syrup|Pantry",
    honey = "2|tbsp|honey|Pantry",
    mustard = "2|tbsp|Dijon mustard (certified GF)|Pantry",
    mild_taco = "2|tsp|mild taco seasoning (certified GF)|Pantry",
    italian = "2|tsp|Italian seasoning (certified GF)|Pantry",
    cinnamon = "1|tsp|cinnamon (certified GF)|Pantry",
    chia = "4|tbsp|chia seeds|Pantry",
    peanut_butter = "4|tbsp|peanut butter|Pantry",
    pumpkin_seeds = "0.5|cup|pumpkin seeds|Pantry"
  )
}

expanded_source_url <- function(provider, reference) {
  if (identical(provider, "TheMealDB")) {
    paste0("https://www.themealdb.com/meal/", reference)
  } else {
    paste0("https://en.wikibooks.org/wiki/", utils::URLencode(gsub(" ", "_", reference), reserved = TRUE))
  }
}

expanded_directions <- function(method) {
  switch(
    method,
    roast = "Heat oven to 425°F. Toss the vegetables with olive oil and spread on a sheet pan. Add the protein and mild seasonings. Roast until vegetables are tender and the protein reaches a safe temperature.",
    skillet = "Warm oil in a large skillet. Cook the protein or beans first, then add the vegetables and sauce ingredients. Cover and cook gently until everything is tender and hot throughout.",
    stir_fry = "Cook the protein in a large skillet and set it aside. Stir-fry the vegetables until crisp-tender. Add the cooked rice, protein, and certified gluten-free tamari; toss until hot.",
    stew = "Brown the protein if included. Add the vegetables, beans or starch, and broth. Cover and simmer gently until tender, stirring occasionally and adding water if needed.",
    soup = "Add the vegetables, beans or protein, and certified gluten-free broth to a soup pot. Simmer until tender. Stir in any dairy at the end and season mildly.",
    pasta = "Cook gluten-free pasta according to the package. Cook the protein and vegetables in a skillet, add the sauce, then fold in the drained pasta and heat through.",
    casserole = "Heat oven to 375°F. Combine the cooked protein or beans, vegetables, starch, and sauce in a baking dish. Top with cheese if included and bake until bubbling and hot throughout.",
    slow_cooker = "Place the vegetables in the slow cooker and add the protein, broth, and mild seasonings. Cook on low until very tender, then shred or cut the protein into family-friendly pieces.",
    tacos = "Cook the protein or beans with the vegetables and mild seasoning. Warm certified gluten-free corn tortillas. Let everyone build tacos with the remaining toppings.",
    bowl = "Cook the grain according to its package. Cook or warm the protein and vegetables, then divide everything among bowls. Add the mild sauce or topping just before serving.",
    patties = "Mash or finely chop the main ingredients and mix with egg and gluten-free crumbs if included. Shape into small patties and cook in a lightly oiled skillet until golden and hot throughout.",
    pancakes = "Whisk the batter ingredients until just combined. Cook small pancakes on a lightly buttered skillet over medium heat, flipping when bubbles form and cooking until the centers are set.",
    porridge = "Combine the grain and milk in a saucepan. Simmer gently, stirring often, until creamy and tender. Add fruit and mild toppings just before serving.",
    eggs = "Cook the vegetables in a lightly oiled skillet until tender. Add beaten eggs and cook gently until set. Finish with cheese or other toppings if included.",
    breakfast_bake = "Heat oven to 375°F. Stir the ingredients together in a greased baking dish or muffin tin. Bake until the center is set, then cool briefly before serving.",
    overnight = "Stir the grain, milk or yogurt, fruit, and seeds together. Refrigerate overnight. Serve cold or warm gently in the morning.",
    no_cook = "Prepare and portion all ingredients into bowls or lunch containers. Keep wet and crunchy ingredients separate until serving.",
    salad = "Cook any grain or protein and let it cool slightly. Toss with the vegetables and a mild dressing. Keep small-child portions separated if preferred.",
    toast = "Toast certified gluten-free bread. Prepare the topping, spread it over the toast, and add the remaining ingredients. Cut into age-appropriate pieces.",
    "Combine the prepared ingredients and cook gently until hot throughout. Check the source link for the original concept and adjust the mild seasonings to taste."
  )
}

expanded_recipe_specs <- function() {
  spec <- function(id, name, protein, meal_type, minutes, calories, protein_g, fiber_g,
                   provider, reference, method, tokens) {
    list(id = id, name = name, protein = protein, meal_type = meal_type,
         minutes = minutes, calories = calories, protein_g = protein_g, fiber_g = fiber_g,
         provider = provider, reference = reference, method = method, tokens = tokens)
  }

  list(
    # 50 dinner adaptations: 42 TheMealDB concepts and 8 Wikibooks concepts.
    spec("x_chicken_halloumi_bowls", "Chicken and Halloumi Rice Bowls", "Chicken", "Dinner", 25, 520, 42, 6, "TheMealDB", "53085", "bowl", c("chicken_breast", "rice", "bell_peppers", "spinach", "cheddar", "lemon")),
    spec("x_mild_coconut_chicken", "Mild Coconut Chicken and Green Beans", "Chicken", "Dinner", 30, 510, 39, 7, "TheMealDB", "53050", "skillet", c("chicken_thighs", "coconut_milk", "green_beans", "carrots", "rice")),
    spec("x_chicken_waterzooi", "Creamy Chicken Vegetable Stew", "Chicken", "Dinner", 35, 490, 38, 6, "TheMealDB", "53466", "stew", c("chicken_breast", "potatoes", "carrots", "peas", "broth", "yogurt")),
    spec("x_bengali_chicken_potato", "Gentle Chicken and Potato Skillet", "Chicken", "Dinner", 35, 530, 40, 7, "TheMealDB", "53453", "skillet", c("chicken_thighs", "potatoes", "diced_tomatoes", "spinach", "olive_oil")),
    spec("x_chicken_mushroom_hotpot", "Chicken Mushroom Potato Hotpot", "Chicken", "Dinner", 35, 500, 39, 6, "TheMealDB", "52846", "casserole", c("chicken_breast", "potatoes", "mushrooms", "peas", "broth")),
    spec("x_chicken_alfredo_primavera", "Chicken Alfredo Primavera", "Chicken", "Dinner", 30, 590, 43, 7, "TheMealDB", "52796", "pasta", c("chicken_breast", "gf_pasta", "broccoli", "zucchini", "yogurt", "parmesan")),
    spec("x_chicken_basquaise", "Chicken, Tomato, and Pepper Rice", "Chicken", "Dinner", 30, 520, 39, 7, "TheMealDB", "52934", "skillet", c("chicken_thighs", "rice", "bell_peppers", "diced_tomatoes", "onion")),
    spec("x_chicken_congee", "Gentle Chicken Rice Congee", "Chicken", "Dinner", 30, 430, 34, 4, "TheMealDB", "52956", "soup", c("chicken_breast", "rice", "carrots", "peas", "broth")),
    spec("x_chicken_enchilada_bake", "Mild Chicken Enchilada Casserole", "Chicken", "Dinner", 35, 560, 42, 9, "TheMealDB", "52765", "casserole", c("chicken_breast", "corn_tortillas", "black_beans", "corn", "marinara", "cheddar")),
    spec("x_orange_chicken_skillet", "Orange-Maple Chicken Skillet", "Chicken", "Dinner", 25, 500, 40, 6, "TheMealDB", "53531", "skillet", c("chicken_breast", "broccoli", "carrots", "rice", "maple", "tamari")),
    spec("x_kefta_rice_bowls", "Gentle Beef Meatball Rice Bowls", "Beef", "Dinner", 35, 570, 39, 6, "TheMealDB", "53281", "patties", c("ground_beef", "gf_crumbs", "eggs", "rice", "cucumber", "yogurt")),
    spec("x_beef_broccoli", "Beef and Broccoli Stir-Fry", "Beef", "Dinner", 25, 520, 38, 7, "TheMealDB", "53366", "stir_fry", c("ground_beef", "broccoli", "carrots", "cooked_rice", "tamari")),
    spec("x_easy_beef_bourguignon", "Easy Beef and Mushroom Stew", "Beef", "Dinner", 35, 550, 41, 7, "TheMealDB", "52904", "stew", c("beef_stew", "mushrooms", "carrots", "potatoes", "broth")),
    spec("x_brisket_pot_roast", "Slow Cooker Beef Pot Roast with Carrots", "Beef", "Dinner", 20, 590, 45, 7, "TheMealDB", "52812", "slow_cooker", c("chuck_roast", "potatoes", "carrots", "onion", "broth")),
    spec("x_beef_pumpkin_stew", "Beef and Pumpkin Stew", "Beef", "Dinner", 35, 510, 38, 8, "TheMealDB", "53469", "stew", c("beef_stew", "pumpkin", "carrots", "white_beans", "broth")),
    spec("x_beef_stroganoff", "Easy Beef Mushroom Stroganoff", "Beef", "Dinner", 30, 600, 39, 6, "TheMealDB", "52834", "pasta", c("ground_beef", "gf_pasta", "mushrooms", "yogurt", "broth")),
    spec("x_belgian_meatballs", "Maple-Mustard Beef Meatballs", "Beef", "Dinner", 35, 580, 40, 5, "TheMealDB", "53463", "patties", c("ground_beef", "gf_crumbs", "eggs", "maple", "mustard", "potatoes")),
    spec("x_beef_borscht", "Beef, Beet, and Cabbage Soup", "Beef", "Dinner", 35, 470, 34, 9, "TheMealDB", "53311", "soup", c("beef_stew", "cabbage", "carrots", "potatoes", "diced_tomatoes", "broth")),
    spec("x_baked_pork_rice", "Baked Pork and Vegetable Rice", "Pork", "Dinner", 35, 560, 37, 6, "TheMealDB", "53156", "casserole", c("ground_pork", "rice", "bell_peppers", "peas", "broth")),
    spec("x_grilled_pork_rice", "Lime Pork Tenderloin Rice Bowls", "Pork", "Dinner", 30, 530, 41, 6, "TheMealDB", "53496", "bowl", c("pork_tenderloin", "rice", "cucumber", "carrots", "lime", "yogurt")),
    spec("x_sausage_chickpea_stew", "Mild Sausage, Chickpea, and Spinach Stew", "Pork", "Dinner", 30, 540, 30, 11, "TheMealDB", "53166", "stew", c("mild_sausage", "chickpeas", "spinach", "diced_tomatoes", "broth")),
    spec("x_sausage_chickpea_soup", "Sausage and Chickpea Soup", "Pork", "Dinner", 30, 500, 29, 10, "TheMealDB", "53168", "soup", c("mild_sausage", "chickpeas", "carrots", "spinach", "broth")),
    spec("x_creole_pork_chops", "Mild Tomato Pork Chops", "Pork", "Dinner", 35, 520, 42, 7, "TheMealDB", "53528", "skillet", c("pork_chops", "diced_tomatoes", "bell_peppers", "rice", "olive_oil")),
    spec("x_cider_apple_pork", "Apple Pork Tenderloin Skillet", "Pork", "Dinner", 35, 510, 41, 7, "TheMealDB", "53037", "skillet", c("pork_tenderloin", "apples", "potatoes", "green_beans", "mustard")),
    spec("x_sausage_greens", "Crispy Sausage, Potatoes, and Greens", "Pork", "Dinner", 30, 550, 28, 8, "TheMealDB", "52999", "roast", c("mild_sausage", "potatoes", "green_beans", "spinach", "olive_oil")),
    spec("x_pork_cabbage_goulash", "Pork and Cabbage Goulash", "Pork", "Dinner", 35, 500, 38, 9, "TheMealDB", "53301", "stew", c("ground_pork", "cabbage", "potatoes", "diced_tomatoes", "broth")),
    spec("x_mild_coconut_fish", "Mild Coconut Fish and Rice", "Fish", "Dinner", 30, 520, 38, 5, "TheMealDB", "53495", "skillet", c("cod", "coconut_milk", "rice", "green_beans", "carrots")),
    spec("x_tomato_shrimp_stew", "Tomato Coconut Shrimp Stew", "Fish", "Dinner", 30, 480, 34, 7, "TheMealDB", "53481", "stew", c("shrimp", "coconut_milk", "diced_tomatoes", "bell_peppers", "rice")),
    spec("x_salmon_fennel_tomato", "Baked Salmon with Tomatoes and Green Beans", "Fish", "Dinner", 30, 560, 42, 8, "TheMealDB", "52959", "roast", c("salmon", "tomatoes", "green_beans", "potatoes", "lemon", "olive_oil")),
    spec("x_moroccan_cod", "Mild Moroccan Carrot and Cod Soup", "Fish", "Dinner", 30, 490, 39, 7, "TheMealDB", "53047", "soup", c("cod", "carrots", "chickpeas", "diced_tomatoes", "veg_broth")),
    spec("x_mild_fish_tacos", "Mild Cabbage Fish Tacos", "Fish", "Dinner", 25, 480, 37, 8, "TheMealDB", "52819", "tacos", c("cod", "corn_tortillas", "cabbage", "avocado", "lime", "yogurt")),
    spec("x_green_onion_shrimp", "Shrimp and Cabbage Rice Skillet", "Fish", "Dinner", 25, 510, 36, 5, "TheMealDB", "53377", "skillet", c("shrimp", "cooked_rice", "cabbage", "carrots", "tamari")),
    spec("x_clam_white_bean_stew", "White Bean and Fish Stew", "Fish", "Dinner", 30, 500, 38, 10, "TheMealDB", "53154", "stew", c("cod", "white_beans", "diced_tomatoes", "spinach", "veg_broth")),
    spec("x_gentle_fish_soup", "Gentle Fish and Potato Soup", "Fish", "Dinner", 30, 450, 36, 6, "TheMealDB", "53079", "soup", c("cod", "potatoes", "carrots", "peas", "broth", "milk")),
    spec("x_roasted_potato_bowls", "Roasted Potato and White Bean Bowls", "Meatless", "Dinner", 30, 470, 18, 12, "TheMealDB", "53158", "bowl", c("potatoes", "white_beans", "broccoli", "spinach", "yogurt")),
    spec("x_eggplant_hummus_grill", "Roasted Eggplant Chickpea Plates", "Meatless", "Dinner", 30, 460, 17, 13, "TheMealDB", "53278", "roast", c("eggplant", "chickpeas", "tomatoes", "quinoa", "lemon")),
    spec("x_black_bean_hotpot", "Black Bean Sweet Potato Hotpot", "Meatless", "Dinner", 30, 490, 19, 16, "TheMealDB", "52863", "stew", c("black_beans", "sweet_potatoes", "corn", "diced_tomatoes", "veg_broth")),
    spec("x_cabbage_bean_soup", "Cabbage and White Bean Soup", "Meatless", "Dinner", 25, 390, 17, 13, "TheMealDB", "53077", "soup", c("cabbage", "white_beans", "carrots", "diced_tomatoes", "veg_broth")),
    spec("x_carrot_bean_fritters", "Carrot and White Bean Patties", "Meatless", "Dinner", 30, 450, 20, 11, "TheMealDB", "53576", "patties", c("white_beans", "carrots", "eggs", "gf_crumbs", "potatoes")),
    spec("x_chickpea_fajitas", "Mild Chickpea Fajitas", "Meatless", "Dinner", 25, 490, 18, 14, "TheMealDB", "52870", "tacos", c("chickpeas", "corn_tortillas", "bell_peppers", "avocado", "mild_taco")),
    spec("x_tomato_egg_rice", "Tomato Egg Rice Skillet", "Meatless", "Dinner", 20, 440, 22, 6, "TheMealDB", "53372", "skillet", c("eggs", "tomatoes", "spinach", "cooked_rice", "tamari")),
    spec("x_easy_white_bean_soup", "Creamy White Bean Vegetable Soup", "Meatless", "Dinner", 25, 420, 19, 14, "TheMealDB", "53486", "soup", c("white_beans", "carrots", "spinach", "potatoes", "veg_broth", "yogurt")),
    spec("x_wiki_california_chicken", "California Peach Chicken Skillet", "Chicken", "Dinner", 30, 500, 39, 6, "Wikibooks", "Cookbook:California Curry Chicken", "skillet", c("chicken_breast", "peaches", "bell_peppers", "rice", "olive_oil")),
    spec("x_wiki_corn_shrimp_chowder", "Corn and Shrimp Chowder", "Fish", "Dinner", 30, 480, 31, 7, "Wikibooks", "Cookbook:Corn and Shrimp Chowder", "soup", c("shrimp", "corn", "potatoes", "milk", "veg_broth")),
    spec("x_wiki_butter_chicken", "Mild Tomato Butter Chicken", "Chicken", "Dinner", 30, 550, 40, 6, "Wikibooks", "Cookbook:Indian Butter Chicken I", "skillet", c("chicken_thighs", "diced_tomatoes", "yogurt", "butter", "rice")),
    spec("x_wiki_lentil_rice", "Lentils and Brown Rice with Carrots", "Meatless", "Dinner", 30, 450, 20, 15, "Wikibooks", "Cookbook:Lentils and Rice (Mjeddrah)", "skillet", c("lentils", "brown_rice", "carrots", "spinach", "veg_broth")),
    spec("x_wiki_aloo_gobi", "Mild Potato and Cauliflower Skillet", "Meatless", "Dinner", 30, 430, 14, 12, "Wikibooks", "Cookbook:Potato and Cauliflower Curry (Aloo Gobi)", "skillet", c("potatoes", "cauliflower", "chickpeas", "diced_tomatoes", "yogurt")),
    spec("x_wiki_coconut_tofu", "Tofu in Mild Coconut Sauce", "Meatless", "Dinner", 25, 470, 24, 8, "Wikibooks", "Cookbook:Tofu in Spiced Coconut Sauce", "skillet", c("tofu", "coconut_milk", "broccoli", "carrots", "rice")),
    spec("x_wiki_turkey_plantain", "Turkey and Sweet Potato Bake", "Turkey", "Dinner", 35, 540, 38, 8, "Wikibooks", "Cookbook:Turkey with Plantain Stuffing (Pavo Relleno de Mofongo)", "casserole", c("ground_turkey", "sweet_potatoes", "bell_peppers", "spinach", "broth")),
    spec("x_wiki_azteca_soup", "Aztec-Style Black Bean Soup", "Meatless", "Dinner", 25, 410, 18, 15, "Wikibooks", "Cookbook:Azteca (Aztec-inspired Bean Soup)", "soup", c("black_beans", "corn", "diced_tomatoes", "bell_peppers", "veg_broth")),

    # 20 breakfast adaptations: 10 TheMealDB and 10 Wikibooks.
    spec("x_breakfast_potatoes", "Breakfast Potato and Egg Bowls", "Meatless", "Breakfast", 25, 390, 20, 6, "TheMealDB", "52965", "bowl", c("potatoes", "eggs", "spinach", "cheddar")),
    spec("x_mini_buckwheat_pancakes", "Mini Buckwheat Pancakes with Berries", "Meatless", "Breakfast", 20, 350, 14, 7, "TheMealDB", "53379", "pancakes", c("buckwheat", "eggs", "milk", "berries", "maple")),
    spec("x_cheesy_grits_eggs", "Cheesy Grits with Eggs", "Meatless", "Breakfast", 20, 380, 21, 4, "TheMealDB", "53450", "porridge", c("cornmeal", "milk", "eggs", "cheddar", "spinach")),
    spec("x_jamaican_cornmeal_porridge", "Banana Cornmeal Breakfast Porridge", "Meatless", "Breakfast", 15, 340, 12, 6, "TheMealDB", "53363", "porridge", c("cornmeal", "milk", "bananas", "cinnamon")),
    spec("x_oatmeal_pancakes", "Oatmeal Yogurt Pancakes", "Meatless", "Breakfast", 20, 360, 18, 7, "TheMealDB", "53331", "pancakes", c("oats", "eggs", "yogurt", "bananas", "cinnamon")),
    spec("x_apple_cream_porridge", "Apple Cream Oat Porridge", "Meatless", "Breakfast", 15, 370, 15, 7, "TheMealDB", "53118", "porridge", c("oats", "milk", "yogurt", "apples", "cinnamon")),
    spec("x_salmon_egg_toast", "Salmon and Egg Gluten-Free Toast", "Fish", "Breakfast", 15, 410, 28, 5, "TheMealDB", "52962", "toast", c("canned_salmon", "eggs", "gf_bread", "yogurt", "lemon")),
    spec("x_haddock_kedgeree", "Gentle Fish and Egg Breakfast Rice", "Fish", "Breakfast", 20, 420, 30, 5, "TheMealDB", "52964", "skillet", c("cod", "cooked_rice", "eggs", "peas", "lemon")),
    spec("x_ugali_breakfast", "Cornmeal Breakfast Bowls with Fruit", "Meatless", "Breakfast", 15, 330, 13, 6, "TheMealDB", "53114", "porridge", c("cornmeal", "milk", "bananas", "berries", "pumpkin_seeds")),
    spec("x_gentle_shakshuka", "Gentle Tomato Egg Skillet", "Meatless", "Breakfast", 20, 320, 22, 7, "TheMealDB", "53225", "eggs", c("eggs", "diced_tomatoes", "bell_peppers", "spinach", "cheddar")),
    spec("x_wiki_gf_waffles", "Gluten-Free Yogurt Waffles", "Meatless", "Breakfast", 25, 360, 17, 5, "Wikibooks", "Cookbook:Breakfast Waffles (Gluten-Free)", "pancakes", c("gf_flour", "eggs", "milk", "yogurt", "berries")),
    spec("x_wiki_buckwheat_crepes", "Buckwheat Berry Crepes", "Meatless", "Breakfast", 25, 340, 15, 7, "Wikibooks", "Cookbook:Buckwheat Crêpes", "pancakes", c("buckwheat", "eggs", "milk", "berries", "yogurt")),
    spec("x_wiki_blackberry_oat_bake", "Blackberry Oat Breakfast Bake", "Meatless", "Breakfast", 30, 350, 13, 8, "Wikibooks", "Cookbook:Blackberry Oat Bars (Gluten-Free)", "breakfast_bake", c("oats", "berries", "eggs", "milk", "chia")),
    spec("x_wiki_pear_smoothie_bowl", "Pear Almond Yogurt Bowls", "Meatless", "Breakfast", 10, 330, 23, 7, "Wikibooks", "Cookbook:Pear and Almond Smoothie (Vegan)", "no_cook", c("pears", "yogurt", "oats", "chia", "pumpkin_seeds")),
    spec("x_wiki_appam_eggs", "Rice Pancakes with Soft Eggs", "Meatless", "Breakfast", 25, 370, 18, 5, "Wikibooks", "Cookbook:Appam (Fermented Rice Pancake)", "pancakes", c("rice", "coconut_milk", "eggs", "spinach")),
    spec("x_wiki_almond_pancakes", "Banana Almond Oat Pancakes", "Meatless", "Breakfast", 20, 390, 17, 8, "Wikibooks", "Cookbook:Almond Pancakes", "pancakes", c("oats", "eggs", "bananas", "peanut_butter", "milk")),
    spec("x_wiki_asparagus_frittata", "Green Vegetable Cheddar Frittata", "Meatless", "Breakfast", 25, 310, 24, 4, "Wikibooks", "Cookbook:Asparagus Frittata", "breakfast_bake", c("eggs_ten", "broccoli", "spinach", "cheddar", "milk")),
    spec("x_wiki_baked_oatmeal", "Apple Cinnamon Baked Oatmeal", "Meatless", "Breakfast", 30, 360, 15, 8, "Wikibooks", "Cookbook:Baked Oatmeal", "breakfast_bake", c("oats", "apples", "eggs", "milk", "cinnamon", "chia")),
    spec("x_wiki_banana_pancakes", "Banana Buckwheat Pancakes", "Meatless", "Breakfast", 20, 350, 15, 7, "Wikibooks", "Cookbook:Banana Pancakes", "pancakes", c("buckwheat", "bananas", "eggs", "milk", "maple")),
    spec("x_wiki_brown_rice_breakfast", "Brown Rice Berry Breakfast Bowls", "Meatless", "Breakfast", 15, 360, 18, 8, "Wikibooks", "Cookbook:Brown Rice Breakfast Bowl", "porridge", c("brown_rice", "milk", "berries", "yogurt", "chia")),

    # 20 lunch adaptations: 12 TheMealDB and 8 Wikibooks.
    spec("x_lunch_potato_bean_bowls", "Roasted Potato White Bean Lunch Bowls", "Meatless", "Lunch", 25, 430, 18, 11, "TheMealDB", "53158", "bowl", c("potatoes", "white_beans", "spinach", "cucumber", "yogurt")),
    spec("x_lunch_eggplant_hummus", "Eggplant Chickpea Lunch Plates", "Meatless", "Lunch", 25, 410, 17, 12, "TheMealDB", "53278", "roast", c("eggplant", "chickpeas", "tomatoes", "gf_crackers", "lemon")),
    spec("x_lunch_avocado_potatoes", "Avocado Potato and Egg Plates", "Meatless", "Lunch", 20, 450, 21, 10, "TheMealDB", "53107", "no_cook", c("potatoes", "avocado", "eggs", "cucumber", "lemon")),
    spec("x_lunch_beet_patties", "Vegetable Bean Patties", "Meatless", "Lunch", 25, 400, 19, 10, "TheMealDB", "53313", "patties", c("white_beans", "carrots", "eggs", "gf_crumbs", "spinach")),
    spec("x_lunch_carrot_bean_fritters", "Carrot Bean Fritter Lunchboxes", "Meatless", "Lunch", 25, 420, 20, 11, "TheMealDB", "53576", "patties", c("white_beans", "carrots", "eggs", "gf_crumbs", "cucumber")),
    spec("x_lunch_chickpea_fajitas", "Chickpea Fajita Lunch Wraps", "Meatless", "Lunch", 20, 450, 17, 13, "TheMealDB", "52870", "tacos", c("chickpeas", "corn_tortillas", "bell_peppers", "avocado", "mild_taco")),
    spec("x_lunch_tomato_egg_rice", "Tomato Egg Lunch Rice", "Meatless", "Lunch", 15, 410, 21, 5, "TheMealDB", "53372", "skillet", c("eggs", "tomatoes", "cooked_rice", "spinach", "tamari")),
    spec("x_lunch_white_bean_soup", "White Bean Spinach Lunch Soup", "Meatless", "Lunch", 20, 380, 18, 14, "TheMealDB", "53486", "soup", c("white_beans", "spinach", "carrots", "diced_tomatoes", "veg_broth")),
    spec("x_lunch_egg_drop_soup", "Egg Drop Vegetable Soup", "Meatless", "Lunch", 15, 330, 22, 5, "TheMealDB", "52955", "soup", c("eggs", "broth", "corn", "spinach", "carrots", "tamari")),
    spec("x_lunch_ful_bowls", "Lemon White Bean Lunch Bowls", "Meatless", "Lunch", 15, 400, 19, 13, "TheMealDB", "53025", "bowl", c("white_beans", "tomatoes", "cucumber", "eggs", "lemon")),
    spec("x_lunch_chicken_quinoa_salad", "Chicken Quinoa Cucumber Salad", "Chicken", "Lunch", 20, 460, 36, 7, "TheMealDB", "53011", "salad", c("chicken_breast", "quinoa", "cucumber", "tomatoes", "yogurt", "lemon")),
    spec("x_lunch_sausage_tomato_salad", "Mild Sausage Tomato Potato Salad", "Pork", "Lunch", 20, 470, 27, 7, "TheMealDB", "53185", "salad", c("mild_sausage", "potatoes", "tomatoes", "spinach", "mustard")),
    spec("x_wiki_quinoa_slaw", "Quinoa Vegetable Slaw with Peanut Dressing", "Meatless", "Lunch", 20, 430, 18, 10, "Wikibooks", "Cookbook:Quinoa Vegetable Slaw With Peanut Dressing (Gluten-Free)", "salad", c("quinoa", "cabbage", "carrots", "cucumber", "peanut_butter", "lime")),
    spec("x_wiki_summer_roll_bowls", "Summer Roll Rice Bowls", "Meatless", "Lunch", 20, 420, 20, 9, "Wikibooks", "Cookbook:Summer Rolls", "bowl", c("tofu", "cooked_rice", "cabbage", "carrots", "cucumber", "tamari")),
    spec("x_wiki_socca_lunch", "Chickpea Flatbread Lunch Plates", "Meatless", "Lunch", 25, 410, 18, 10, "Wikibooks", "Cookbook:Socca (Italian Chickpea Flatbread)", "pancakes", c("chickpea_flour", "eggs", "tomatoes", "cucumber", "yogurt")),
    spec("x_wiki_corn_chowder", "Corn Potato Lunch Chowder", "Meatless", "Lunch", 25, 390, 17, 7, "Wikibooks", "Cookbook:Corn Chowder I", "soup", c("corn", "potatoes", "milk", "white_beans", "veg_broth")),
    spec("x_wiki_potato_salad", "Yogurt Egg Potato Salad", "Meatless", "Lunch", 20, 400, 22, 6, "Wikibooks", "Cookbook:American Potato Salad I", "salad", c("potatoes", "eggs", "yogurt", "mustard", "cucumber")),
    spec("x_wiki_beanburgers", "Black Bean Lunch Patties", "Meatless", "Lunch", 25, 430, 21, 13, "Wikibooks", "Cookbook:Beanburger", "patties", c("black_beans", "eggs", "gf_crumbs", "corn", "avocado")),
    spec("x_wiki_black_bean_soup", "Black Bean Tomato Lunch Soup", "Meatless", "Lunch", 20, 370, 17, 15, "Wikibooks", "Cookbook:Black Bean Soup", "soup", c("black_beans", "diced_tomatoes", "corn", "bell_peppers", "veg_broth")),
    spec("x_wiki_broccoli_burgers", "Broccoli Cheddar Lunch Patties", "Meatless", "Lunch", 25, 390, 23, 8, "Wikibooks", "Cookbook:Broccoli Burgers", "patties", c("broccoli", "white_beans", "eggs", "gf_crumbs", "cheddar"))
  )
}

expanded_recipe_data <- function() {
  tokens <- expanded_ingredient_tokens()
  specs <- expanded_recipe_specs()
  records <- lapply(specs, function(item) {
    missing <- setdiff(item$tokens, names(tokens))
    if (length(missing)) stop("Unknown expanded recipe ingredient token: ", paste(missing, collapse = ", "))
    source_label <- if (identical(item$provider, "Wikibooks")) {
      "Wikibooks adaptation (CC BY-SA)"
    } else {
      "TheMealDB adaptation"
    }
    make_recipe(
      id = item$id,
      name = item$name,
      protein = item$protein,
      minutes = item$minutes,
      description = paste("A mild, gluten-free family adaptation of", item$name, "with an intentionally simple method."),
      instructions = expanded_directions(item$method),
      ingredient_lines = unname(tokens[item$tokens]),
      kid_note = "Serve components separately or cut into small, age-appropriate pieces.",
      meal_type = item$meal_type,
      calories = item$calories,
      protein_g = item$protein_g,
      fiber_g = item$fiber_g,
      source = source_label,
      source_url = expanded_source_url(item$provider, item$reference)
    )
  })
  list(
    recipes = do.call(rbind, lapply(records, `[[`, "meta")),
    ingredients = do.call(rbind, lapply(records, `[[`, "ingredients"))
  )
}

combined_builtin_recipe_data <- function() {
  original <- builtin_recipe_data()
  expanded <- expanded_recipe_data()
  list(
    recipes = rbind(original$recipes, expanded$recipes),
    ingredients = rbind(original$ingredients, expanded$ingredients)
  )
}
