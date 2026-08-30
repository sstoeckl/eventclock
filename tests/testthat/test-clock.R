# Golden tests: the estimator must reproduce the working paper's headline
# information-time table from the shipped datasets. Exact values pinned at
# 1e-6; the published (rounded) values checked at 2e-3.

test_that("Brexit event-clock estimates reproduce the paper table", {
  res <- event_clock(ep_brexit(), from = as.Date("2016-05-24"), to = brexit_horizons)

  # exact pins (regression guard)
  expect_equal(clock_value(res, "1W", "rv"), 0.06391206, tolerance = 1e-6)
  expect_equal(clock_value(res, "2W", "rv"), 0.16574907, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "rv"), 0.51046899, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "bipower"), 0.37418353, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "largest1"), 0.42547325, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "largest2"), 0.34076037, tolerance = 1e-6)

  # published (rounded) values, absolute deviation
  expect_lt(abs(clock_value(res, "1W", "rv") - 0.064), 1.1e-3)
  expect_lt(abs(clock_value(res, "2W", "rv") - 0.166), 1.1e-3)
  expect_lt(abs(clock_value(res, "1M", "rv") - 0.511), 1.1e-3)
  expect_lt(abs(clock_value(res, "1M", "bipower") - 0.375), 1.1e-3)
  # the paper's "truncated" value coincides with dropping the largest move
  expect_lt(abs(clock_value(res, "1M", "largest1") - 0.426), 1.1e-3)

  # window sizes: calendar-daily including weekends, anchored windows
  expect_equal(res$n_obs[res$horizon == "1W"][1], 8)
  expect_equal(res$n_obs[res$horizon == "2W"][1], 15)
  expect_equal(res$n_obs[res$horizon == "1M"][1], 31)
})

test_that("US election event-clock estimates reproduce the paper table", {
  res <- event_clock(ep_us(), from = as.Date("2016-10-10"), to = us_horizons)

  expect_equal(clock_value(res, "1W", "rv"), 0.01520781, tolerance = 1e-6)
  expect_equal(clock_value(res, "2W", "rv"), 0.04600595, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "rv"), 0.37046375, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "bipower"), 0.38639860, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "truncated"), 0.25877271, tolerance = 1e-6)
  expect_equal(clock_value(res, "1M", "largest1"), 0.25877271, tolerance = 1e-6)

  expect_lt(abs(clock_value(res, "1W", "rv") - 0.015), 1.1e-3)
  expect_lt(abs(clock_value(res, "2W", "rv") - 0.046), 1.1e-3)
  expect_lt(abs(clock_value(res, "1M", "rv") - 0.370), 1.1e-3)
  expect_lt(abs(clock_value(res, "1M", "bipower") - 0.386), 1.1e-3)
  # here the 3-robust-SD truncation binds and equals largest1, as in the paper
  expect_lt(abs(clock_value(res, "1M", "truncated") - 0.259), 1.1e-3)
})

test_that("real-time forecast rule reproduces the paper numbers", {
  fus <- event_clock_forecast(ep_us(),
    at = as.Date("2016-10-10"), horizon = c(`1W` = 7, `2W` = 14)
  )
  expect_equal(fus$A_forecast[fus$horizon == "1W"], 0.06809, tolerance = 1e-4)
  expect_equal(fus$A_forecast[fus$horizon == "2W"], 0.13618, tolerance = 1e-4)
  # paper: 0.068 / 0.135
  expect_lt(abs(fus$A_forecast[fus$horizon == "1W"] - 0.068), 1.1e-3)
  expect_lt(abs(fus$A_forecast[fus$horizon == "2W"] - 0.135), 1.5e-3)
  expect_equal(unique(fus$n_incr), 39L)

  # Brexit real-time (the paper's series differs marginally; pin ours)
  fgb <- event_clock_forecast(ep_brexit(),
    at = as.Date("2016-05-24"), horizon = c(`1W` = 7, `2W` = 14)
  )
  expect_equal(fgb$A_forecast[fgb$horizon == "1W"], 0.0439927, tolerance = 1e-4)
  expect_equal(fgb$A_forecast[fgb$horizon == "2W"], 0.0879854, tolerance = 1e-4)

  # linear in the horizon by construction
  expect_equal(fgb$A_forecast[2] / fgb$A_forecast[1], 2)

  # date-typed horizons are converted to days
  fd <- event_clock_forecast(ep_us(),
    at = as.Date("2016-10-10"), horizon = as.Date("2016-10-17")
  )
  expect_equal(fd$horizon_days, 7)
  expect_equal(fd$A_forecast, fus$A_forecast[fus$horizon == "1W"])
})

test_that("polymarket2024 full-sample clock is pinned (hourly vs daily)", {
  ep <- as_event_prices(polymarket2024)
  expect_equal(event_clock(ep, methods = "rv")$A, 1.263125, tolerance = 1e-4)
  daily <- pm_daily(ep)
  expect_equal(event_clock(daily, methods = "rv")$A, 0.7756132, tolerance = 1e-4)
  # sparser sampling reduces measured variation (microstructure noise)
  expect_lt(
    event_clock(daily, methods = "rv")$A,
    event_clock(ep, methods = "rv")$A
  )
})

test_that("estimator kernels are correct on hand-computed examples", {
  expect_equal(eventclock:::kernel_rv(c(1, 2, 3)), 14)
  expect_equal(eventclock:::kernel_bipower(c(1, 2, 3)), (pi / 2) * (2 + 6))
  expect_true(is.na(eventclock:::kernel_bipower(c(1))))
  expect_equal(eventclock:::kernel_drop_largest(c(1, -3, 2), 1), 5)
  expect_equal(eventclock:::kernel_drop_largest(c(1, -3, 2), 2), 1)
  expect_true(is.na(eventclock:::kernel_drop_largest(c(1), 1)))

  # truncation drops the outlier but keeps the small moves
  dL <- c(0.01, 0.012, -0.011, 0.009, -0.013, 0.014, -0.01, 0.011, 0.5)
  expect_equal(
    eventclock:::kernel_truncated(dL, trunc_sd = 3),
    sum(dL[abs(dL) <= 3 * stats::mad(dL)]^2)
  )
  expect_lt(eventclock:::kernel_truncated(dL, trunc_sd = 3), sum(dL^2))
  # degenerate robust scale falls back to plain RV
  expect_equal(eventclock:::kernel_truncated(rep(0.1, 5)), sum(rep(0.1, 5)^2))
})

test_that("the clock is invariant to constant logit shifts (wedge property)", {
  ep <- ep_brexit()
  shifted <- brexit2016
  shifted$q_leave <- stats::plogis(stats::qlogis(brexit2016$q_leave) + 0.5)
  ep2 <- as_event_prices(shifted, time = "date", price = "q_leave")
  a1 <- event_clock(ep, from = as.Date("2016-05-24"), to = brexit_horizons, methods = "rv")
  a2 <- event_clock(ep2, from = as.Date("2016-05-24"), to = brexit_horizons, methods = "rv")
  expect_equal(a1$A, a2$A, tolerance = 1e-12)
})

test_that("sparse sampling and window logic behave as documented", {
  # constructed series with equal logit steps of 0.1
  d <- tibble::tibble(
    time = as.Date("2020-01-01") + 0:4,
    q = stats::plogis(seq(0, 0.4, by = 0.1))
  )
  ep <- as_event_prices(d)
  expect_equal(event_clock(ep, methods = "rv")$A, 4 * 0.01, tolerance = 1e-12)
  # every 2nd observation: increments of 0.2 between obs 1,3,5
  r2 <- event_clock(ep, methods = "rv", sample_every = 2)
  expect_equal(r2$A, 2 * 0.04, tolerance = 1e-12)
  expect_equal(r2$n_incr, 2L)
  # anchored window excludes observations outside [from, to]
  r3 <- event_clock(ep,
    from = as.Date("2020-01-02"), to = as.Date("2020-01-04"), methods = "rv"
  )
  expect_equal(r3$A, 2 * 0.01, tolerance = 1e-12)
  # forecast rule on the same series: rv/span * h
  f <- event_clock_forecast(ep, horizon = 8, trailing = 5)
  expect_equal(f$A_forecast, 0.04 / 4 * 8, tolerance = 1e-12)
})

test_that("event_clock_path returns a consistent cumulative clock", {
  path <- event_clock_path(ep_brexit())
  expect_s3_class(path, "event_clock_path")
  expect_equal(nrow(path), nrow(brexit2016))
  expect_true(is.na(path$dL[1]))
  expect_equal(path$A[1], 0)
  # the terminal cumulative value equals the full-sample estimate
  full <- event_clock(ep_brexit(), methods = "rv")$A
  expect_equal(path$A[nrow(path)], full, tolerance = 1e-12)
  # normalization
  expect_equal(path$A_frac[nrow(path)], 1)
  expect_equal(path$cal_frac[1], 0)
  expect_equal(path$cal_frac[nrow(path)], 1)
  expect_true(all(diff(path$A) >= 0))
})

test_that("clock functions validate their inputs", {
  d <- tibble::tibble(time = as.Date("2020-01-01"), q = 0.5)
  ep <- as_event_prices(d)
  expect_error(event_clock_path(ep), "at least 2")
  expect_error(event_clock_forecast(ep, horizon = 7), "at least 2")
  d2 <- tibble::tibble(time = as.Date("2020-01-01") + 0:4, q = rep(0.5, 5))
  expect_error(
    event_clock_forecast(as_event_prices(d2), horizon = -1),
    "strictly after"
  )
  # NA q values are flagged and skipped, not propagated
  d3 <- tibble::tibble(
    time = as.Date("2020-01-01") + 0:4,
    q = c(0.5, NA, 0.55, 0.6, NA)
  )
  res <- event_clock(as_event_prices(d3), methods = "rv")
  expect_equal(res$n_obs, 3L)
  expect_false(is.na(res$A))
})
