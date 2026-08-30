# Offline tests of the parsing/collapsing logic, plus guarded live tests.

test_that("pm_markets_tibble unpacks outcomes and token ids in order", {
  mk <- data.frame(
    id = c("101", "102"),
    slug = c("mkt-a", "mkt-b"),
    question = c("Will A happen?", "Will B happen?"),
    outcomes = c('["Yes","No"]', '["Yes","No"]'),
    clobTokenIds = c('["111","222"]', '["333","444"]'),
    stringsAsFactors = FALSE
  )
  out <- eventclock:::pm_markets_tibble(mk, "ev")
  expect_equal(nrow(out), 4)
  expect_equal(out$token_id, c("111", "222", "333", "444"))
  expect_equal(out$outcome, rep(c("Yes", "No"), 2))
  expect_equal(unique(out$event_slug), "ev")
  # malformed rows are skipped, not fatal
  mk$clobTokenIds[2] <- "not json"
  out2 <- eventclock:::pm_markets_tibble(mk, "ev")
  expect_equal(nrow(out2), 2)
})

test_that("pm_events_tibble tolerates missing columns", {
  ev <- data.frame(id = "1", slug = "s", title = "T", stringsAsFactors = FALSE)
  out <- eventclock:::pm_events_tibble(ev)
  expect_equal(out$event_slug, "s")
  expect_true(is.na(out$closed))
  expect_true(is.na(out$volume))
})

test_that("pm_daily collapses intraday data to one snapshot per day", {
  # constructed: three days, several intraday points each (UTC == snapshot tz
  # here to keep the arithmetic transparent)
  times <- as.POSIXct(
    c(
      "2024-01-01 10:00", "2024-01-01 15:59", "2024-01-01 20:00",
      "2024-01-02 09:00", "2024-01-02 16:00",
      "2024-01-03 08:00"
    ),
    tz = "America/New_York"
  )
  ep <- as_event_prices(
    tibble::tibble(time = times, q = c(0.4, 0.45, 0.5, 0.55, 0.6, 0.65))
  )
  daily <- pm_daily(ep, tz = "America/New_York", snapshot_hour = 16)
  expect_equal(nrow(daily), 3)
  expect_s3_class(daily$time, "Date")
  # last observation at or before 16:00 local: 0.45, 0.60, 0.65
  expect_equal(daily$q, c(0.45, 0.60, 0.65))
  # Date input errors clearly
  expect_error(pm_daily(ep_brexit()), "POSIXct")
})

test_that("pm_daily on the shipped polymarket2024 data is stable", {
  ep <- as_event_prices(polymarket2024)
  daily <- pm_daily(ep)
  expect_equal(nrow(daily), 158)
  expect_true(all(!duplicated(daily$time)))
  expect_true(all(daily$q > 0 & daily$q < 1))
  expect_equal(daily$q[daily$time == as.Date("2024-11-04")], 0.578, tolerance = 1e-6)
})

test_that("live Polymarket endpoints respond (skipped offline/on CRAN)", {
  skip_on_cran()
  skip_if_offline("clob.polymarket.com")

  mkts <- pm_markets("presidential-election-winner-2024")
  expect_gt(nrow(mkts), 0)
  tok <- mkts$token_id[grepl("Trump", mkts$question) & mkts$outcome == "Yes"]
  expect_length(tok, 1)

  ep <- pm_prices(tok, from = "2024-11-01", to = "2024-11-05", fidelity = 1440)
  expect_s3_class(ep, "event_prices")
  expect_gt(nrow(ep), 0)
  expect_true(all(ep$q >= 0 & ep$q <= 1))

  res <- pm_search("presidential election winner 2024", limit = 5)
  expect_true("presidential-election-winner-2024" %in% res$event_slug)
})
