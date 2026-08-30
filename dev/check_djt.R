load("data/djt2024.rda")
cat(nrow(djt2024), "rows,", format(min(djt2024$date)), "to", format(max(djt2024$date)), "\n")
print(as.data.frame(djt2024[djt2024$date >= as.Date("2024-07-12") & djt2024$date <= as.Date("2024-07-16"), ]))
r <- diff(log(djt2024$adjusted))
cat("Return 2024-07-15 (Montag nach Attentat):",
    round(100 * r[which(djt2024$date == as.Date("2024-07-15")) - 1], 1), "%\n")
