suppressMessages(devtools::load_all("."))
data(brexit2016)
ep <- as_event_prices(brexit2016, time = "date", price = "q_leave")
path <- event_clock_path(ep)
top <- path[order(-path$dA), c("time", "q", "dL", "dA")]
top$share <- top$dA / sum(path$dA, na.rm = TRUE)
cat("== Top 15 Tage nach Beitrag zur Uhr (Brexit, q_leave) ==\n")
print(as.data.frame(head(top, 15)), digits = 3, row.names = FALSE)
