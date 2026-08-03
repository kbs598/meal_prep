# Weeknight Five

A bright, family-friendly Shiny app that keeps five mild, gluten-free dinners at the center of the week, adds optional breakfast and lunch rotations, uses pantry ingredients, and builds one grocery list.

## First-time setup

1. Open this folder as an RStudio project or set it as your working directory.
2. Open `setup.R` and click **Source**. This installs Shiny inside this project.
3. Open `app.R` and click **Run App**.

You can also open `run_app.R` and click **Source** after setup. The Desktop copy already includes the required packages.

## What is included

- 126 easy starter recipes: 70 dinners, 28 breakfasts, and 28 lunches
- A no-code **My Recipes** form with ingredient rows and family sharing
- Recipe-link importing that pre-fills the editable My Recipes form from standard Recipe metadata
- Five-night planning with protein rotation, meal locks, and individual swaps
- Optional five-day breakfast and lunch plans with their own fresh-plan, lock, swap, and recipe controls
- Estimated calories, protein, and fiber per serving on every built-in recipe
- A landscape print view that fits the complete week on a fridge-friendly page
- Simple “have it / need it” pantry tracking
- Regional in-season produce highlights
- Active ALDI and Publix BOGO deal matching
- Quantities scaled to 5.4 adult-size portions by default: dinner for two adults, two two-year-olds, one four-year-old, plus two adult lunches
- Combined, categorized grocery list and CSV download
- Optional Supabase sign-in: shared family recipes plus private per-person planner data
- Browser storage and backup/restore controls that continue working while signed out
- Celiac reminders for commonly risky ingredients and cross-contact

## Family recipes

Use the **My Recipes** tab to enter a recipe without editing R files. Choose its dinner, breakfast, or lunch rotation; add estimated nutrition and as many ingredient rows as needed; then save. Personal recipes are stored separately from the built-in library and immediately become eligible for the matching weekly rotation.

You can also paste a public recipe-page link into **My Recipes > Import from a recipe link**. The app uses Jina Reader to retrieve the public page and looks for standard Schema.org Recipe data. It fills the form but does not save automatically: review ingredient quantities and grocery sections, select the correct main protein, and complete the gluten/cross-contact check first. Some websites block automated readers or omit standard recipe metadata; those links must be entered manually.

Nutrition values are convenient planning estimates per serving. Imported recipes use the webpage's published nutrition values when available; otherwise the form keeps editable starter estimates. They are not a substitute for a dietitian or a medical nutrition calculation.

The expanded recipe library contains mild, simplified gluten-free adaptations inspired by concepts in TheMealDB and the Wikibooks Cookbook. Each adapted recipe includes a link to its source inspiration. The directions are newly written for this app and the nutrition values are planning estimates. See `ATTRIBUTION.md` for source and license details.

The app always keeps an on-device browser copy. After Supabase is set up and you sign in under **Settings**, family recipes sync to everyone in the same family. Pantry selections, household settings, meal history, and store deals sync only to the signed-in person. Use **Settings > Download my backup** for an additional portable copy.

## Supabase family sharing

The public Supabase project address and publishable browser key live in `www/supabase-config.js`. The app never needs a secret or service-role key. Database access is protected by the Row Level Security policies in `supabase/schema.sql`.

Follow `SUPABASE_SETUP.md` to create the tables, configure the GitHub Pages redirect address, create the family owner, and invite relatives. No npm installation is needed because the browser library is included in `www/vendor/`.

## Publish with GitHub Pages

The repository includes `.github/workflows/deploy-app.yaml`. Every push to the `main` branch asks GitHub Actions to export the app with Shinylive and publish the static result. In the repository's GitHub settings, choose **Pages > Source > GitHub Actions**. The live address will be `https://kbs598.github.io/meal_prep/`.

## Seasonal food and store deals

Choose a seasonal region and enter a ZIP code on the **Season & Deals** tab. The seasonal calendar is a general regional guide; exact local harvest timing varies.

Weekly prices and BOGOs depend on the selected store. Use the official ALDI and Publix links in the app to view the correct local ad, then add relevant food offers using the short deal form. Active matching deals are highlighted on meal cards, recipe cards, and grocery items. Expired deals stop appearing automatically.

## Important gluten-free note

The recipes are designed to be gluten-free as written, but ingredient formulations and manufacturing practices change. Check every package label, use certified gluten-free products where indicated, and prevent cross-contact in storage, preparation, and cooking.

## Project structure

- `app.R` — app screens and interactions
- `R/recipes.R` — starter recipe library
- `R/expanded_recipes.R` — 90 sourced, simplified recipe adaptations
- `R/planner.R` — meal selection, portion scaling, and grocery calculations
- `R/storage.R` — local saved recipes, deals, and preferences
- `R/supabase.R` — cloud recipe-payload and account helpers
- `R/seasonality.R` — regional produce seasons and active-deal matching
- `supabase/` — database, security-policy, owner, and relative setup SQL
- `www/supabase-sync.js` — sign-in and cloud synchronization
- `www/styles.css` — colors and visual design
- `tests/` — automated planner and interactive-session checks
