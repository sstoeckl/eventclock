suppressMessages(devtools::load_all("."))
data(polymarket2024)
ep <- as_event_prices(polymarket2024)

# daily contribution to the clock (daily snapshots, NY time)
pd <- pm_daily(ep)
path <- event_clock_path(pd)
top_d <- path[order(-path$dA), c("time", "q", "dL", "dA")]
top_d$share <- top_d$dA / sum(path$dA, na.rm = TRUE)
cat("== Top 14 Tage nach Beitrag zur Uhr (taeglich) ==\n")
print(as.data.frame(head(top_d, 14)), digits = 3, row.names = FALSE)

# largest single hourly moves with timestamps (UTC)
hp <- event_clock_path(ep)
top_h <- hp[order(-hp$dA), c("time", "q", "dL")]
cat("\n== Top 10 Stunden-Moves (UTC) ==\n")
print(as.data.frame(head(top_h, 10)), digits = 3, row.names = FALSE)
