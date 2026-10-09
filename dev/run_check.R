setwd("D:/OneDrive - University of Liechtenstein/ROOT/Packages/eventclock")
res <- rcmdcheck::rcmdcheck(args = "--as-cran", error_on = "never")
cat("\n==== CHECK SUMMARY ====\n")
cat("Errors:", length(res$errors), "| Warnings:", length(res$warnings),
    "| Notes:", length(res$notes), "\n")
if (length(res$errors)) print(res$errors)
if (length(res$warnings)) print(res$warnings)
if (length(res$notes)) print(res$notes)
