pkg <- "D:/OneDrive - University of Liechtenstein/ROOT/Packages/eventclock"
setwd(pkg)
suppressMessages(devtools::document(quiet = TRUE))
devtools::install(pkg, quick = TRUE, upgrade = FALSE, quiet = TRUE)
args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args)) args[1] else file.path(tempdir(), "vig")
dir.create(out_dir, showWarnings = FALSE)
for (v in list.files(file.path(pkg, "vignettes"), "\\.Rmd$", full.names = TRUE)) {
  t0 <- Sys.time()
  res <- tryCatch(
    rmarkdown::render(v, output_dir = out_dir, quiet = TRUE,
                      envir = new.env(parent = globalenv())),
    error = function(e) paste("ERROR:", conditionMessage(e))
  )
  cat(sprintf("%-36s %5.1fs  %s\n", basename(v),
              as.numeric(difftime(Sys.time(), t0, units = "secs")),
              if (grepl("^ERROR", res)) res else "OK"))
}
cat("output:", out_dir, "\n")
