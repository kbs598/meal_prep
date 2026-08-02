app_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
project_library <- file.path(app_dir, "packages")
if (dir.exists(project_library)) .libPaths(c(project_library, .libPaths()))

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop("Please open setup.R and click Source once before launching the app.")
}

shiny::runApp(app_dir, launch.browser = TRUE)

