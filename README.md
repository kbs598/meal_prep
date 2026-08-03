# Weeknight Five

A bright, family-friendly Shiny app that creates five mild, gluten-free dinners, rotates main proteins, uses pantry ingredients, scales for family dinner plus adult lunches, and builds one grocery list.

## First-time setup

1. Open this folder as an RStudio project or set it as your working directory.
2. Open `setup.R` and click **Source**. This installs Shiny inside this project.
3. Open `app.R` and click **Run App**.

You can also open `run_app.R` and click **Source** after setup. The Desktop copy already includes the required packages.

## What is included

- 20 easy starter recipes across chicken, turkey, beef, pork, fish, and meatless dinners
- A no-code **My Recipes** form with ingredient rows and local saving
- Recipe-link importing that pre-fills the editable My Recipes form from standard Recipe metadata
- Five-night planning with protein rotation, meal locks, and individual swaps
- Simple “have it / need it” pantry tracking
- Regional in-season produce highlights
- Active ALDI, Walmart, and Publix BOGO deal matching
- Quantities scaled to 5.4 adult-size portions by default: dinner for two adults, two two-year-olds, one four-year-old, plus two adult lunches
- Combined, categorized grocery list and CSV download
- Local settings, recipes, pantry items, deals, and meal-history storage
- Browser storage and backup/restore controls for the GitHub Pages version
- Celiac reminders for commonly risky ingredients and cross-contact

## Family recipes

Use the **My Recipes** tab to enter a recipe without editing R files. Add the recipe details and as many ingredient rows as needed, then save. Personal recipes are stored separately from the built-in library and immediately become eligible for weekly rotation.

You can also paste a public recipe-page link into **My Recipes > Import from a recipe link**. The app uses Jina Reader to retrieve the public page and looks for standard Schema.org Recipe data. It fills the form but does not save automatically: review ingredient quantities and grocery sections, select the correct main protein, and complete the gluten/cross-contact check first. Some websites block automated readers or omit standard recipe metadata; those links must be entered manually.

On GitHub Pages, personal data is saved only in the current browser on the current device. Use **Settings > Download my backup** before clearing browser data or moving to another phone. Restore that `.rds` file from the same Settings tab.

## Publish with GitHub Pages

The repository includes `.github/workflows/deploy-app.yaml`. Every push to the `main` branch asks GitHub Actions to export the app with Shinylive and publish the static result. In the repository's GitHub settings, choose **Pages > Source > GitHub Actions**. The live address will be `https://kbs598.github.io/meal_prep/`.

## Seasonal food and store deals

Choose a seasonal region and enter a ZIP code on the **Season & Deals** tab. The seasonal calendar is a general regional guide; exact local harvest timing varies.

Weekly prices and BOGOs depend on the selected store. Use the official ALDI, Walmart, and Publix links in the app to view the correct local ad, then add relevant food offers using the short deal form. Active matching deals are highlighted on meal cards, recipe cards, and grocery items. Expired deals stop appearing automatically.

## Important gluten-free note

The recipes are designed to be gluten-free as written, but ingredient formulations and manufacturing practices change. Check every package label, use certified gluten-free products where indicated, and prevent cross-contact in storage, preparation, and cooking.

## Project structure

- `app.R` — app screens and interactions
- `R/recipes.R` — starter recipe library
- `R/planner.R` — meal selection, portion scaling, and grocery calculations
- `R/storage.R` — local saved recipes, deals, and preferences
- `R/seasonality.R` — regional produce seasons and active-deal matching
- `www/styles.css` — colors and visual design
- `tests/` — automated planner and interactive-session checks
