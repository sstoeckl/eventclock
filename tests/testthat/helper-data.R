# Shared fixtures for the test suite.

ep_brexit <- function() {
  as_event_prices(brexit2016,
    time = "date", price = "q_leave",
    market_id = "Brexit: Leave", event_date = as.Date("2016-06-23")
  )
}

ep_us <- function() {
  as_event_prices(us2016,
    time = "date", price = "trump",
    market_id = "US 2016: Trump", event_date = as.Date("2016-11-08")
  )
}

# horizons of the working paper's 1M valuation dates
brexit_horizons <- c(
  `1W` = as.Date("2016-05-31"), `2W` = as.Date("2016-06-07"),
  `1M` = as.Date("2016-06-23")
)
us_horizons <- c(
  `1W` = as.Date("2016-10-17"), `2W` = as.Date("2016-10-24"),
  `1M` = as.Date("2016-11-08")
)

clock_value <- function(res, h, m) res$A[res$horizon == h & res$method == m]
