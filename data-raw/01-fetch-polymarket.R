# Build the polymarket2024 dataset from the public Polymarket CLOB API.
# Requires network access. Run from the package root after devtools::load_all().
stopifnot(file.exists("DESCRIPTION"))
devtools::load_all(".")

# Trump-"Yes" token of event "presidential-election-winner-2024" (public id,
# resolvable any time via pm_markets("presidential-election-winner-2024")).
token <- "21742633143463906290569050155826241533067272736897614950488156847949938836455"

ep <- pm_prices(
  token,
  from = "2024-06-01", to = "2024-11-06",
  fidelity = 60,
  market_id = "Polymarket: Trump wins 2024",
  event_date = as.POSIXct("2024-11-05", tz = "UTC")
)

polymarket2024 <- tibble::tibble(time = ep$time, q = ep$q)
stopifnot(nrow(polymarket2024) > 3000, !anyNA(polymarket2024$q))

usethis::use_data(polymarket2024, overwrite = TRUE, compress = "xz")
