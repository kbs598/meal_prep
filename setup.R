app_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
project_library <- file.path(app_dir, "packages")
dir.create(project_library, recursive = TRUE, showWarnings = FALSE)

message("Finding and installing the app's required packages. This can take a few minutes...")
repository <- "https://cloud.r-project.org"
available <- available.packages(repos = repository)
dependencies <- tools::package_dependencies(
  "shiny",
  db = available,
  which = c("Depends", "Imports", "LinkingTo"),
  recursive = TRUE
)[["shiny"]]
packages_needed <- unique(c(dependencies, "shiny"))
installed_here <- rownames(installed.packages(lib.loc = project_library))
packages_needed <- setdiff(packages_needed, installed_here)

if (length(packages_needed)) {
  install.packages(packages_needed, repos = repository, lib = project_library)
} else {
  message("All required packages are already installed.")
}
message("Setup complete. Open app.R and click Run App, or open run_app.R and click Source.")
