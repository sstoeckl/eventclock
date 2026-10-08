# Event-spanning mixture: pricer, implied volatility, theta estimation ------

test_that("theta = 0 with equal dispersions collapses to a flat Black smile", {
  k <- seq(-0.6, 0.6, by = 0.15)
  iv <- ec_mix_iv(k, q = 0.4, theta = 0, s1 = 0.3, s2 = 0.3)
  expect_equal(iv, rep(0.3, length(k)), tolerance = 1e-8)
})

test_that("put-call parity holds on the unit forward", {
  k <- c(-0.4, 0, 0.3)
  cc <- ec_mix_price(k, q = 0.55, theta = 0.8, s1 = 0.3, s2 = 0.5, type = "call")
  pp <- ec_mix_price(k, q = 0.55, theta = 0.8, s1 = 0.3, s2 = 0.5, type = "put")
  expect_equal(cc - pp, 1 - exp(k), tolerance = 1e-12)
})

test_that("deep-ITM call approaches the forward, deep-OTM call vanishes", {
  expect_equal(
    ec_mix_price(-8, q = 0.5, theta = 1, s1 = 0.3, s2 = 0.4),
    1 - exp(-8),
    tolerance = 1e-6
  )
  expect_lt(ec_mix_price(8, q = 0.5, theta = 1, s1 = 0.3, s2 = 0.4), 1e-8)
})

test_that("ATM implied dispersion increases with |theta| (convex-order effect)", {
  ivs <- vapply(
    c(0, 0.3, 0.6, 1.2),
    function(th) ec_mix_iv(0, q = 0.5, theta = th, s1 = 0.25, s2 = 0.25),
    0
  )
  expect_true(all(diff(ivs) > 0))
  # and symmetric in the sign of theta at q = 1/2 with equal dispersions
  expect_equal(
    ec_mix_iv(0.2, q = 0.5, theta = 0.7, s1 = 0.3, s2 = 0.3),
    ec_mix_iv(0.2, q = 0.5, theta = -0.7, s1 = 0.3, s2 = 0.3),
    tolerance = 1e-9
  )
})

test_that("mixture means satisfy the adding-up normalization", {
  q <- 0.37; theta <- 1.1
  rho <- exp(theta)
  m1 <- rho / (q * rho + 1 - q)
  m2 <- 1 / (q * rho + 1 - q)
  expect_equal(q * m1 + (1 - q) * m2, 1, tolerance = 1e-14)
  expect_equal(log(m1 / m2), theta, tolerance = 1e-14)
})

test_that("ec_delta_to_k round-trips through the Black call delta", {
  s <- 0.35
  delta <- c(0.1, 0.25, 0.5, 0.75, 0.9)
  k <- ec_delta_to_k(delta, s)
  d1 <- (-k) / s + s / 2
  expect_equal(stats::pnorm(d1), delta, tolerance = 1e-12)
  expect_error(ec_delta_to_k(1.2, s), "between 0 and 1")
})

test_that("ec_theta_hump inverts the two-point variance identity exactly", {
  q <- 0.42; theta <- 0.9
  dvar <- q * (1 - q) * theta^2
  expect_equal(ec_theta_hump(dvar, q), theta, tolerance = 1e-12)
  expect_warning(out <- ec_theta_hump(c(-0.01, dvar), q), "negative")
  expect_true(is.na(out[1]))
  expect_equal(out[2], theta, tolerance = 1e-12)
})

test_that("ec_recovery_set reproduces the sharp partial-recovery interval", {
  rs <- ec_recovery_set(0.5, eps = c(0, 0.25, 1, 2))
  expect_equal(rs$lower[rs$eps == 0], 0.5)
  expect_equal(rs$upper[rs$eps == 0], 0.5)
  expect_equal(rs$lower[rs$eps == 0.25], 0.75^2 * 0.5)
  expect_equal(rs$upper[rs$eps == 0.25], 1.25^2 * 0.5)
  expect_equal(rs$lower[rs$eps == 1], 0)    # (1 - eps)_+ at eps >= 1
  expect_equal(rs$lower[rs$eps == 2], 0)
  # intervals are nested in eps
  expect_true(all(diff(rs$lower) <= 0) && all(diff(rs$upper) >= 0))
  expect_equal(nrow(ec_recovery_set(c(0.1, 0.2))), 8L)
})

test_that("ec_theta_fit recovers a known common exposure from clean surfaces", {
  k <- seq(-0.5, 0.5, by = 1 / 7)
  true_theta <- 0.8
  cfg <- data.frame(
    surface = c("d1", "d2", "d3"),
    q = c(0.45, 0.55, 0.60),
    s1 = c(0.25, 0.30, 0.28),
    s2 = c(0.32, 0.36, 0.30)
  )
  surf <- do.call(rbind, lapply(seq_len(nrow(cfg)), function(i) {
    data.frame(
      surface = cfg$surface[i], k = k, q = cfg$q[i],
      iv = ec_mix_iv(k, cfg$q[i], true_theta, cfg$s1[i], cfg$s2[i])
    )
  }))
  fit <- ec_theta_fit(surf)
  expect_s3_class(fit, "ec_theta_fit")
  expect_equal(fit$theta, true_theta, tolerance = 0.02)
  expect_equal(fit$surfaces$s1, cfg$s1, tolerance = 0.05)
  expect_equal(fit$surfaces$s2, cfg$s2, tolerance = 0.05)
  expect_lt(fit$rmse, 1e-3)
  expect_output(print(fit), "Common event exposure")
})

test_that("ec_theta_fit handles annualized IVs via tau and node weights", {
  k <- seq(-0.4, 0.4, by = 0.1)
  tau <- 30 / 365
  true_theta <- 0.6
  tot <- ec_mix_iv(k, q = 0.58, theta = true_theta, s1 = 0.20, s2 = 0.26)
  surf <- data.frame(
    surface = "s1", k = k, q = 0.58,
    iv = tot / sqrt(tau), tau = tau, w = c(1, 2, 3, 4, 5, 4, 3, 2, 1)
  )
  # a single surface cannot pin theta sign/level tightly; use common = FALSE
  fit <- ec_theta_fit(surf, common = FALSE)
  expect_true(is.na(fit$theta))
  expect_equal(fit$surfaces$theta[1], true_theta, tolerance = 0.05)
  expect_output(print(fit), "Free per-surface exposures")
})

test_that("ec_theta_fit input validation works", {
  expect_error(ec_theta_fit(data.frame(k = 1)), "missing column")
  surf <- data.frame(surface = "a", k = c(-0.1, 0, 0.1), q = 0.5, iv = 0.3)
  expect_warning(expect_error(ec_theta_fit(surf), "No usable surfaces"),
                 "fewer than")
  bad <- data.frame(
    surface = "a", k = seq(-0.3, 0.3, 0.1),
    q = c(0.5, 0.5, 0.5, 0.6, 0.6, 0.6, 0.6), iv = 0.3
  )
  expect_error(ec_theta_fit(bad), "non-constant")
})
