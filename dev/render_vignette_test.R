pkg <- "D:/OneDrive - University of Liechtenstein/ROOT/Packages/eventclock"
setwd(pkg)
devtools::install(pkg, quick = TRUE, upgrade = FALSE, quiet = TRUE)
out <- rmarkdown::render(
  file.path(pkg, "vignettes", "eventclock-event-spanning.Rmd"),
  output_dir = tempdir(), quiet = TRUE
)
cat("Rendered OK:", out, "\n")
