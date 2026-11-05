## kalshi2024: daily 15:45 New York snapshot of the Kalshi contract
## "Will Donald Trump or another Republican win the Presidency?"
## (market PRES-2024-DJT), October 4 (listing) to November 5, 2024.
## Built with the package's own public-API connector.

pkg <- "D:/OneDrive - University of Liechtenstein/ROOT/Packages/eventclock"
setwd(pkg)
suppressMessages(devtools::load_all(pkg, quiet = TRUE))

ks <- ks_prices("PRES-2024-DJT", from = "2024-10-04", to = "2024-11-06",
                interval = "1h", market_id = "Kalshi: Trump wins 2024")
daily <- pm_daily(ks, snapshot_hour = 15.75)
kalshi2024 <- tibble::tibble(date = daily$time, q = daily$q)
kalshi2024 <- kalshi2024[kalshi2024$date <= as.Date("2024-11-05"), ]

stopifnot(nrow(kalshi2024) >= 30, all(kalshi2024$q > 0 & kalshi2024$q < 1))
save(kalshi2024, file = "data/kalshi2024.rda", compress = "xz")
cat("Saved data/kalshi2024.rda:", nrow(kalshi2024), "rows,",
    format(min(kalshi2024$date)), "to", format(max(kalshi2024$date)), "\n")
print(utils::head(kalshi2024, 3)); print(utils::tail(kalshi2024, 3))

## the matching Polymarket snapshot from the shipped hourly series
data(polymarket2024)
pm <- pm_daily(as_event_prices(polymarket2024), snapshot_hour = 15.75)
both <- merge(kalshi2024, data.frame(date = pm$time, q_pm = pm$q), by = "date")
cat("Overlapping days with Polymarket:", nrow(both), "\n")
print(utils::tail(both, 5))
