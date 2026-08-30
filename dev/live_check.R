suppressMessages(devtools::load_all("."))
s <- pm_search("presidential election winner 2024", limit = 5)
print(as.data.frame(s))
m <- pm_markets("presidential-election-winner-2024")
print(dim(m))
print(as.data.frame(m[grepl("Trump", m$question) & m$outcome == "Yes",
                      c("market_slug", "outcome")]))
cat("token:", m$token_id[grepl("Trump", m$question) & m$outcome == "Yes"], "\n")
