suppressMessages(devtools::load_all("."))
data(brexit2016); data(us2016); data(polymarket2024)

ep_gb <- as_event_prices(brexit2016, time = "date", price = "q_leave",
                         market_id = "Brexit: Leave", event_date = as.Date("2016-06-23"))
ep_us <- as_event_prices(us2016, time = "date", price = "trump",
                         market_id = "US 2016: Trump", event_date = as.Date("2016-11-08"))

gb <- event_clock(ep_gb, from = as.Date("2016-05-24"),
                  to = c(`1W` = as.Date("2016-05-31"), `2W` = as.Date("2016-06-07"),
                         `1M` = as.Date("2016-06-23")))
us <- event_clock(ep_us, from = as.Date("2016-10-10"),
                  to = c(`1W` = as.Date("2016-10-17"), `2W` = as.Date("2016-10-24"),
                         `1M` = as.Date("2016-11-08")))
print(as.data.frame(gb[, c("horizon", "n_obs", "n_incr", "method", "A")]), digits = 6)
print(as.data.frame(us[, c("horizon", "n_obs", "n_incr", "method", "A")]), digits = 6)

fgb <- event_clock_forecast(ep_gb, at = as.Date("2016-05-24"), horizon = c(`1W` = 7, `2W` = 14))
fus <- event_clock_forecast(ep_us, at = as.Date("2016-10-10"), horizon = c(`1W` = 7, `2W` = 14))
print(as.data.frame(fgb[, c("horizon", "n_incr", "A_forecast")]), digits = 6)
print(as.data.frame(fus[, c("horizon", "n_incr", "A_forecast")]), digits = 6)

cat("\npolymarket2024:", nrow(polymarket2024), "rows,",
    format(min(polymarket2024$time)), "to", format(max(polymarket2024$time)), "\n")
pd <- pm_daily(as_event_prices(polymarket2024))
cat("daily rows:", nrow(pd), " q on 2024-11-04:", pd$q[pd$time == as.Date("2024-11-04")], "\n")
cat("full-sample A (hourly):", event_clock(as_event_prices(polymarket2024), methods = "rv")$A, "\n")
cat("full-sample A (daily):", event_clock(pd, methods = "rv")$A, "\n")
