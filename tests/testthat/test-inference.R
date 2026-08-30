# Standard errors and confidence intervals for the clock estimate.

test_that("quarticity SE matches the closed form on a hand example", {
  d <- tibble::tibble(
    time = as.Date("2020-01-01") + 0:4,
    q = stats::plogis(c(0, 0.1, 0.3, 0.35, 0.5))
  )
  res <- event_clock(as_event_prices(d), methods = "rv", se = TRUE)
  dL <- diff(c(0, 0.1, 0.3, 0.35, 0.5))
  expect_equal(res$se, sqrt((2 / 3) * sum(dL^4)), tolerance = 1e-12)
  # log-based CI brackets the estimate and stays positive
  expect_lt(res$ci_lo, res$A)
  expect_gt(res$ci_hi, res$A)
  expect_gt(res$ci_lo, 0)
  # non-rv methods carry NA
  res2 <- event_clock(as_event_prices(d), methods = c("rv", "bipower"), se = TRUE)
  expect_true(is.na(res2$se[res2$method == "bipower"]))
  expect_false(is.na(res2$se[res2$method == "rv"]))
})

test_that("bootstrap SE agrees with the quarticity SE", {
  ep <- ep_brexit()
  set.seed(7)
  rq <- event_clock(ep, from = as.Date("2016-05-24"), methods = "rv",
                    se = TRUE)
  rb <- event_clock(ep, from = as.Date("2016-05-24"), methods = "rv",
                    se = TRUE, se_method = "bootstrap", boot_reps = 4000)
  # the two-point multipliers are moment-matched to the quarticity avar
  expect_lt(abs(rb$se - rq$se) / rq$se, 0.1)
  expect_lt(rb$ci_lo, rb$A)
  expect_gt(rb$ci_hi, rb$A)
})

test_that("CI coverage is close to nominal in a Monte Carlo", {
  set.seed(11)
  A <- 0.5
  n_steps <- 60
  hits <- vapply(seq_len(300), function(i) {
    p <- ec_simulate_path(1, n_steps, q = 0.4, A = A)
    ep <- as_event_prices(
      tibble::tibble(time = as.Date("2020-01-01") + p$step, q = p$q),
      clip = c(1e-8, 1 - 1e-8)
    )
    r <- event_clock(ep, methods = "rv", se = TRUE, conf = 0.90)
    r$ci_lo <= A && A <= r$ci_hi
  }, logical(1))
  # nominal 90%; allow generous MC slack (binomial se ~ 1.7pp)
  expect_gt(mean(hits), 0.82)
  expect_lt(mean(hits), 0.97)
})

test_that("event_clock validates se arguments", {
  expect_error(event_clock(ep_brexit(), methods = "rv", se = TRUE, conf = 1.2))
  expect_error(
    event_clock(ep_brexit(), methods = "rv", se = TRUE, se_method = "nope")
  )
})
