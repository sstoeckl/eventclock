# Daily prices of Trump Media & Technology Group (DJT), June-November 2024,
# from Yahoo Finance via tidyquant. Companion asset series for the 2024
# election event-beta example. Requires network access.
stopifnot(file.exists("DESCRIPTION"))

raw <- tidyquant::tq_get("DJT", from = "2024-06-01", to = "2024-11-30")
stopifnot(nrow(raw) > 100)

djt2024 <- tibble::tibble(
  date = as.Date(raw$date),
  close = raw$close,
  adjusted = raw$adjusted,
  volume = raw$volume
)
stopifnot(!anyNA(djt2024$close))

usethis::use_data(djt2024, overwrite = TRUE, compress = "xz")
