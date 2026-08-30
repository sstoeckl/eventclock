test_that("Newey-West vcov matches sandwich::NeweyWest", {
  skip_if_not_installed("sandwich")
  set.seed(5)
  n <- 200
  x <- stats::rnorm(n)
  # AR(1) errors so that HAC actually differs from OLS
  u <- stats::filter(stats::rnorm(n), 0.5, method = "recursive")
  y <- 0.1 + 2 * x + as.numeric(u)
  fit <- stats::lm(y ~ x)
  for (L in c(0L, 3L, 6L)) {
    V_own <- eventclock:::newey_west_vcov(
      stats::model.matrix(fit), stats::residuals(fit), L
    )
    V_ref <- sandwich::NeweyWest(fit, lag = L, prewhite = FALSE, adjust = FALSE)
    expect_equal(unname(V_own), unname(as.matrix(V_ref)), tolerance = 1e-8)
  }
})

test_that("event_beta recovers a known exposure from simulated data", {
  set.seed(6)
  n <- 250
  deta_true <- -0.10
  dq <- stats::rnorm(n, sd = 0.02)
  ret <- deta_true * dq + stats::rnorm(n, sd = 0.005)
  dates <- as.Date("2024-01-01") + 0:n
  asset <- tibble::tibble(date = dates[-1], ret = ret)
  ep <- as_event_prices(
    tibble::tibble(time = dates, q = 0.5 + cumsum(c(0, dq)))
  )
  eb <- event_beta(asset, ep)
  expect_s3_class(eb, "event_beta")
  # within 3 standard errors of the truth (se ~ 0.016 by design)
  expect_lt(abs(eb$deta_hat - deta_true), 3 * eb$deta_se)
  expect_gt(abs(eb$deta_hat / eb$deta_se), 4)
  expect_equal(eb$n, n)
  # model-implied levels respect the adding-up constraint at mean q
  expect_equal(
    eb$q_mean * eb$eta1 + (1 - eb$q_mean) * eb$eta2, 1, tolerance = 1e-12
  )
  # with the true deta supplied, beta is close to 1 and the test does not
  # reject
  eb2 <- event_beta(asset, ep, deta = deta_true)
  expect_equal(eb2$beta, 1, tolerance = 0.2)
  expect_gt(eb2$beta_p, 0.05)
  # against a wrong external deta the test rejects
  eb3 <- event_beta(asset, ep, deta = deta_true / 3)
  expect_lt(eb3$beta_p, 0.01)
  expect_output(print(eb2), "beta")
})

test_that("event_beta handles price input, controls, and validation", {
  set.seed(8)
  n <- 120
  dates <- as.Date("2024-01-01") + 0:n
  dq <- stats::rnorm(n, sd = 0.02)
  mkt <- stats::rnorm(n, sd = 0.01)
  ret <- -0.05 * dq + 0.9 * mkt + stats::rnorm(n, sd = 0.004)
  price <- 100 * exp(cumsum(c(0, ret)))
  asset <- tibble::tibble(date = dates, adjusted = price)
  ep <- as_event_prices(tibble::tibble(time = dates, q = 0.5 + cumsum(c(0, dq))))
  ctl <- tibble::tibble(date = dates[-1], mkt = mkt)

  eb <- event_beta(asset, ep, controls = ctl)
  expect_lt(abs(eb$deta_hat - (-0.05)), 3 * eb$deta_se)
  expect_true("mkt" %in% eb$coefficients$term)
  # the market control is picked up as well
  b_mkt <- eb$coefficients$estimate[eb$coefficients$term == "mkt"]
  expect_lt(abs(b_mkt - 0.9), 0.2)

  expect_error(event_beta(tibble::tibble(a = 1), ep), "time column")
  expect_error(
    event_beta(tibble::tibble(date = dates, foo = 1), ep),
    "return nor a price"
  )
})

test_that("event_beta on the shipped DJT/Polymarket data is stable", {
  eb <- event_beta(djt2024, pm_daily(as_event_prices(polymarket2024)))
  # DJT is significantly positively exposed to the Trump probability
  # (meme-stock idiosyncratic noise keeps the R^2 modest)
  expect_gt(eb$deta_hat, 1)
  expect_gt(eb$deta_hat / eb$deta_se, 2)
  expect_gt(eb$r2, 0.04)
  expect_gt(eb$n, 90)
})
