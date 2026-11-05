# Kalshi connector: parsing helpers offline, live endpoints when online ----

test_that("ks_num reads live (suffixed) and historical (bare) field names", {
  expect_equal(ks_num(list(close_dollars = "0.53"), "close"), 0.53)
  expect_equal(ks_num(list(volume_fp = "12.00"), "volume"), 12)
  expect_equal(ks_num(list(close = "0.97"), "close"), 0.97)
  expect_true(is.na(ks_num(list(), "close")))
  # the suffixed variant wins when both are present
  expect_equal(ks_num(list(close_dollars = "0.5", close = "0.9"), "close"), 0.5)
})

test_that("ks_candles_tibble flattens candlesticks", {
  cs <- list(
    list(end_period_ts = 1728046800L, volume = "10",
         price = list(close = "0.50"), yes_bid = list(close = "0.49"),
         yes_ask = list(close = "0.51")),
    list(end_period_ts = 1728050400L, volume = "4",
         price = list(close_dollars = "0.52"),
         yes_bid = list(close_dollars = "0.51"),
         yes_ask = list(close_dollars = "0.53"))
  )
  tb <- ks_candles_tibble(cs)
  expect_equal(nrow(tb), 2L)
  expect_equal(tb$close, c(0.50, 0.52))
  expect_equal((tb$bid + tb$ask) / 2, c(0.50, 0.52))
  expect_equal(tb$volume, c(10, 4))
  expect_equal(nrow(ks_candles_tibble(list())), 0L)
})

test_that("the shipped kalshi2024 snapshot is a valid event-price series", {
  data(kalshi2024)
  expect_equal(nrow(kalshi2024), 33L)
  expect_true(all(kalshi2024$q > 0 & kalshi2024$q < 1))
  expect_equal(range(kalshi2024$date), as.Date(c("2024-10-04", "2024-11-05")))
  ep <- as_event_prices(kalshi2024, time = "date", price = "q")
  expect_s3_class(ep, "event_prices")
  # synchronized with the shipped Polymarket series at 15:45 New York time
  data(polymarket2024)
  pm <- pm_daily(as_event_prices(polymarket2024), snapshot_hour = 15.75)
  v <- event_clock_venues(pm, ep, labels = c("Polymarket", "Kalshi"))
  expect_equal(v$n_common, 33L)
  expect_gt(v$corr, 0.3)
  expect_equal(v$A_composite, (v$A_x + v$A_y + 2 * v$A_cross) / 4,
               tolerance = 1e-12)
})

test_that("live Kalshi endpoints respond (skipped offline/on CRAN)", {
  skip_on_cran()
  skip_if_offline("api.elections.kalshi.com")
  mk <- ks_markets("PRES-2024")
  expect_true("PRES-2024-DJT" %in% mk$ticker)
  ks <- ks_prices("PRES-2024-DJT", from = "2024-11-01", to = "2024-11-03",
                  interval = "1h")
  expect_s3_class(ks, "event_prices")
  expect_gt(nrow(ks), 10)
  expect_true(all(ks$q > 0 & ks$q < 1, na.rm = TRUE))
  ksm <- ks_prices("PRES-2024-DJT", from = "2024-11-01", to = "2024-11-02",
                   interval = "1h", price = "mid")
  expect_true(all(is.finite(ksm$q)))
})

test_that("ks_prices validates its window", {
  expect_error(ks_prices("X", from = "2024-11-02", to = "2024-11-01"),
               "before")
})
