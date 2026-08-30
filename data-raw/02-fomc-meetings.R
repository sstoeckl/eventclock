# Scheduled FOMC meetings 2021-2027 (decision day = second meeting day).
# Source: Federal Reserve Board, "Meeting calendars and information",
# https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm
# (retrieved 2026-08-30). Unscheduled/notation votes are excluded.
stopifnot(file.exists("DESCRIPTION"))

fomc_meetings <- tibble::tibble(
  decision_date = as.Date(c(
    # 2021
    "2021-01-27", "2021-03-17", "2021-04-28", "2021-06-16",
    "2021-07-28", "2021-09-22", "2021-11-03", "2021-12-15",
    # 2022
    "2022-01-26", "2022-03-16", "2022-05-04", "2022-06-15",
    "2022-07-27", "2022-09-21", "2022-11-02", "2022-12-14",
    # 2023
    "2023-02-01", "2023-03-22", "2023-05-03", "2023-06-14",
    "2023-07-26", "2023-09-20", "2023-11-01", "2023-12-13",
    # 2024
    "2024-01-31", "2024-03-20", "2024-05-01", "2024-06-12",
    "2024-07-31", "2024-09-18", "2024-11-07", "2024-12-18",
    # 2025
    "2025-01-29", "2025-03-19", "2025-05-07", "2025-06-18",
    "2025-07-30", "2025-09-17", "2025-10-29", "2025-12-10",
    # 2026
    "2026-01-28", "2026-03-18", "2026-04-29", "2026-06-17",
    "2026-07-29", "2026-09-16", "2026-10-28", "2026-12-09",
    # 2027
    "2027-01-27", "2027-03-17", "2027-04-28", "2027-06-09",
    "2027-07-28", "2027-09-15", "2027-10-27", "2027-12-08"
  )),
  sep = rep(c(FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE), 7)
)
fomc_meetings$year <- as.integer(format(fomc_meetings$decision_date, "%Y"))
fomc_meetings <- fomc_meetings[, c("decision_date", "year", "sep")]

stopifnot(nrow(fomc_meetings) == 56, !anyNA(fomc_meetings$decision_date))
usethis::use_data(fomc_meetings, overwrite = TRUE, compress = "xz")
