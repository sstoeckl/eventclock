# Measurement layer: forecasts, rule selection, staggered grids, venues ----

# deterministic daily series: log odds rise by 0.1 per day -> clock 0.01/day
ramp_daily <- function(n = 80) {
  data.frame(time = as.Date("2024-01-01") + 0:(n - 1),
             q = ec_ilogit(-2 + 0.1 * (0:(n - 1))))
}
ramp_hourly <- function(n = 24 * 20, step = 0.01) {
  data.frame(time = as.POSIXct("2024-03-01 00:00", tz = "UTC") + 3600 * (0:(n - 1)),
             q = ec_ilogit(-1 + step * (0:(n - 1))))
}

test_that("forecast windows (obs, days, expanding) give the same constant rate", {
  ep <- as_event_prices(ramp_daily(), clip = c(1e-6, 1 - 1e-6))
  at <- as.Date("2024-02-20")
  f_obs <- event_clock_forecast(ep, at = at, horizon = 7, trailing = 11)
  f_day <- event_clock_forecast(ep, at = at, horizon = 7, days = 3)
  f_exp <- event_clock_forecast(ep, at = at, horizon = 7, expanding = TRUE)
  expect_equal(f_obs$A_forecast, 0.07, tolerance = 1e-10)
  expect_equal(f_day$A_forecast, 0.07, tolerance = 1e-10)
  expect_equal(f_exp$A_forecast, 0.07, tolerance = 1e-10)
  expect_equal(f_day$n_incr, 3L)
  expect_equal(f_obs$trailing, 11L)
  expect_true(is.na(f_day$trailing))
  expect_equal(f_day$rule, "trailing 3 days / rv")
  expect_equal(f_exp$rule, "expanding / rv")
  expect_equal(f_obs$rate_per_day, 0.01, tolerance = 1e-10)
})

test_that("forecasts use only data up to the valuation time", {
  d <- ramp_daily()
  # a huge move after `at` must not change the forecast
  d2 <- d
  d2$q[d2$time > as.Date("2024-02-20")] <- 0.999
  at <- as.Date("2024-02-20")
  f1 <- event_clock_forecast(as_event_prices(d), at = at, horizon = 7, days = 5)
  f2 <- event_clock_forecast(as_event_prices(d2), at = at, horizon = 7, days = 5)
  expect_equal(f1$A_forecast, f2$A_forecast)
})

test_that("forecast handles POSIXct horizons, estimators, and errors", {
  ep <- as_event_prices(ramp_hourly(), clip = c(1e-6, 1 - 1e-6))
  at <- as.POSIXct("2024-03-15 12:00", tz = "UTC")
  f <- event_clock_forecast(ep, at = at, horizon = at + 36 * 3600, days = 3)
  expect_equal(f$horizon_days, 1.5)
  # 24 increments per day of 0.01 each -> 24 * 1e-4 per day
  expect_equal(f$A_forecast, 1.5 * 24 * 1e-4, tolerance = 1e-10)
  fb <- event_clock_forecast(ep, at = at, horizon = 2, days = 3, method = "bipower")
  expect_equal(fb$method, "bipower")
  expect_true(is.finite(fb$A_forecast))
  expect_error(event_clock_forecast(ep, at = at, horizon = -1), "strictly after")
  ed <- as_event_prices(ramp_daily())
  expect_error(event_clock_forecast(ed, at = as.Date("2024-02-20"), horizon = 7,
                                    interval = 60), "POSIXct")
})

test_that("staggered forecast with the data's own spacing equals the plain one", {
  ep <- as_event_prices(ramp_hourly(), clip = c(1e-6, 1 - 1e-6))
  at <- as.POSIXct("2024-03-15 12:00", tz = "UTC")
  a <- event_clock_forecast(ep, at = at, horizon = 2, days = 3)
  b <- event_clock_forecast(ep, at = at, horizon = 2, days = 3, interval = 60)
  expect_equal(a$A_forecast, b$A_forecast, tolerance = 1e-10)
})

test_that("ec_forecast_rules builds the candidate grid", {
  r <- ec_forecast_rules(obs = c(20, 40), days = 3, expanding = TRUE,
                         methods = c("rv", "bipower"))
  expect_equal(nrow(r), 8L)
  expect_setequal(unique(r$type), c("obs", "days", "expanding"))
  expect_true("trailing 40 obs / bipower" %in% r$rule)
  expect_error(ec_forecast_rules(), "at least one")
})

test_that("rule selection reproduces the working paper's 2016 choice", {
  # paper (Internet Appendix): both tenors select realized variation over
  # the preceding 60 observations, among 20/40/60 obs x RV/truncated/bipower
  ep <- ep_us()
  rules <- ec_forecast_rules(obs = c(20, 40, 60),
                             methods = c("rv", "truncated", "bipower"))
  for (h in c(7, 14)) {
    starts <- seq(as.Date("2016-05-15"), as.Date("2016-10-10") - h, by = "day")
    sel <- suppressMessages(
      ec_forecast_select(ep, data.frame(start = starts, end = starts + h),
                         rules = rules)
    )
    expect_s3_class(sel, "ec_forecast_select")
    expect_equal(sel$best$rule, "trailing 60 obs / rv")
    expect_true(all(diff(sel$scores$rmse) >= 0))
  }
})

test_that("rule selection reproduces the paper's three-day choice on hourly data", {
  # weekly option lives (valuation Mon-Thu 15:45 ET, Friday expiry) ending
  # by Oct 25, 2024: the trailing three-day window wins, as in the paper
  data(polymarket2024)
  ep <- as_event_prices(polymarket2024)
  fridays <- seq(as.Date("2024-09-06"), as.Date("2024-10-25"), by = "week")
  iv <- do.call(rbind, lapply(fridays, function(f) {
    data.frame(start = as.POSIXct(paste(f - (4:1), "19:45"), tz = "UTC"),
               end = as.POSIXct(paste(f, "19:45"), tz = "UTC"))
  }))
  sel <- ec_forecast_select(ep, iv)
  expect_equal(sel$best$rule, "trailing 3 days / rv")
  expect_equal(sel$best$n, 32L)
  expect_output(print(sel), "Best rule: trailing 3 days")
})

test_that("ec_forecast_select validates its inputs", {
  ep <- as_event_prices(ramp_daily())
  expect_error(ec_forecast_select(ep, data.frame(a = 1)))
  bad <- data.frame(start = as.Date("2024-02-10"), end = as.Date("2024-02-01"))
  expect_error(ec_forecast_select(ep, bad), "after")
  early <- data.frame(start = as.Date("2024-01-01"), end = as.Date("2024-01-05"))
  expect_error(ec_forecast_select(ep, early, rules = ec_forecast_rules(obs = 40)),
               "No interval")
})

test_that("bounds in another time zone select the same instants without warnings", {
  ep <- as_event_prices(ramp_hourly(), clip = c(1e-6, 1 - 1e-6))
  utc <- as.POSIXct("2024-03-05 12:00", tz = "UTC")
  ny <- as.POSIXct("2024-03-05 07:00", tz = "America/New_York")
  expect_equal(as.numeric(utc), as.numeric(ny))
  expect_no_warning(a <- event_clock(ep, from = ny, methods = "rv"))
  b <- event_clock(ep, from = utc, methods = "rv")
  expect_equal(a$A, b$A)
  expect_no_warning(event_clock_forecast(ep, at = ny, horizon = 1, days = 2))
})

test_that("staggered grid at the data's spacing equals plain realized variation", {
  ep <- as_event_prices(ramp_hourly(n = 100, step = 0.02),
                        clip = c(1e-6, 1 - 1e-6))
  s <- event_clock_staggered(ep, interval = 60)
  p <- event_clock(ep, methods = "rv")
  expect_equal(s$n_offsets, 1L)
  expect_equal(s$A, p$A, tolerance = 1e-10)
})

test_that("staggered grid averages over all offsets", {
  set.seed(3)
  n <- 200
  L <- cumsum(c(0, stats::rnorm(n - 1, sd = 0.05)))
  ep <- as_event_prices(data.frame(
    time = as.POSIXct("2024-03-01", tz = "UTC") + 3600 * (0:(n - 1)),
    q = ec_ilogit(L)
  ), clip = c(1e-6, 1 - 1e-6))
  s <- event_clock_staggered(ep, interval = 120, methods = c("rv", "largest1"))
  manual <- mean(c(sum(diff(L[seq(1, n, 2)])^2), sum(diff(L[seq(2, n, 2)])^2)))
  expect_equal(s$n_offsets[1], 2L)
  expect_equal(s$A[s$method == "rv"], manual, tolerance = 1e-10)
  expect_lte(s$A[s$method == "largest1"], s$A[s$method == "rv"])
  expect_true(all(s$A_min <= s$A & s$A <= s$A_max))
  expect_error(event_clock_staggered(as_event_prices(ramp_daily())), "POSIXct")
})

test_that("venue clocks: identities and noise filtering", {
  set.seed(11)
  p <- ec_simulate_path(1, 600, q = 0.5, A = 1)
  days <- as.Date("2024-01-01") + 0:600
  mk <- function(sd) data.frame(time = days,
                                q = ec_ilogit(p$L + stats::rnorm(601, sd = sd)))
  v <- event_clock_venues(mk(0.04), mk(0.08), labels = c("A", "B"),
                          clip = c(1e-6, 1 - 1e-6))
  expect_equal(v$A_composite, (v$A_x + v$A_y + 2 * v$A_cross) / 4,
               tolerance = 1e-12)
  truth <- sum(diff(p$L)^2)
  # cross clock is close to the common clock; own clocks are inflated
  expect_lt(abs(v$A_cross / truth - 1), 0.25)
  expect_gt(v$A_x, truth)
  expect_gt(v$A_y, v$A_x)
  expect_gt(v$noise_share_y, v$noise_share_x)
  expect_equal(v$n_common, 601L)

  # identical venues: no noise, perfect correlation
  same <- event_clock_venues(mk(0), mk(0), clip = c(1e-6, 1 - 1e-6))
  expect_equal(same$A_cross, same$A_x, tolerance = 1e-12)
  expect_equal(same$noise_share_x, 0, tolerance = 1e-12)
  expect_equal(same$corr, 1, tolerance = 1e-12)
})

test_that("venue clocks validate synchronization and support windows", {
  a <- ramp_daily(30)
  b <- a
  b$time <- b$time + 0.5   # no identical timestamps
  expect_error(event_clock_venues(a, b), "identical timestamps")
  v <- event_clock_venues(a, ramp_daily(30),
                          to = c(`10d` = as.Date("2024-01-10"),
                                 all = as.Date("2024-01-30")))
  expect_equal(v$horizon, c("10d", "all"))
  expect_lt(v$A_x[1], v$A_x[2])
  hourly <- ramp_hourly(50)
  expect_error(event_clock_venues(a, hourly), "same time type")
})

test_that("venue path ends at the full-window clocks and plots", {
  set.seed(5)
  p <- ec_simulate_path(1, 100, q = 0.4, A = 0.8)
  days <- as.Date("2024-01-01") + 0:100
  x <- data.frame(time = days, q = ec_ilogit(p$L + stats::rnorm(101, sd = 0.03)))
  y <- data.frame(time = days, q = ec_ilogit(p$L + stats::rnorm(101, sd = 0.03)))
  path <- event_clock_venues_path(x, y, labels = c("PM", "KS"),
                                  clip = c(1e-6, 1 - 1e-6))
  v <- event_clock_venues(x, y, clip = c(1e-6, 1 - 1e-6))
  expect_s3_class(path, "event_clock_venues_path")
  expect_equal(utils::tail(path$A_cross, 1), v$A_cross, tolerance = 1e-12)
  expect_equal(utils::tail(path$A_x, 1), v$A_x, tolerance = 1e-12)
  expect_s3_class(plot(path), "ggplot")
})
