# Local pkgdown build check.
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
pkgdown::build_site(new_process = TRUE, install = TRUE, preview = FALSE)
# CLAUDE.md is an internal working file; CI removes it before building.
unlink(c("docs/CLAUDE.html", "docs/CLAUDE.md"))
cat("site root files:\n")
print(list.files("docs", recursive = FALSE))
