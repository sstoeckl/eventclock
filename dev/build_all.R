# Full local build: document, test, readme, check.
pandoc_candidates <- c(
  "C:/R/RStudio/resources/app/bin/quarto/bin/tools",
  "C:/R/RStudio/resources/app/bin/pandoc",
  "C:/R/RStudio/bin/quarto/bin/tools",
  "C:/R/RStudio/bin/pandoc"
)
for (p in pandoc_candidates) {
  if (file.exists(file.path(p, "pandoc.exe"))) {
    Sys.setenv(RSTUDIO_PANDOC = p)
    break
  }
}
cat("pandoc:", rmarkdown::pandoc_version() |> as.character(), "\n")

devtools::document()
devtools::build_readme()
res <- devtools::check(
  document = FALSE,
  args = c("--no-manual", "--as-cran"),
  error_on = "never"
)
print(res)
