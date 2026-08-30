test_that("transition density is a proper density with the right moments", {
  q <- 0.195
  A <- 0.166
  grid <- seq(-8, 6, length.out = 4001)
  dens <- ec_transition_density(grid, q = q, A = A)
  dx <- diff(grid)[1]
  expect_equal(sum(dens) * dx, 1, tolerance = 1e-6)
  # mean and variance match ec_moments (Bayes-consistent +/- A/2 drift)
  m <- ec_moments(q, A)
  expect_equal(sum(grid * dens) * dx, m$E_LT, tolerance = 1e-4)
  expect_equal(
    sum((grid - m$E_LT)^2 * dens) * dx, m$var_LT, tolerance = 1e-4
  )
  expect_error(ec_transition_density(0, q = 0.5, A = 0), "strictly positive")
})

test_that("ec_simulate satisfies the martingale property and transition law", {
  set.seed(1)
  sim <- ec_simulate(2e5, q = 0.195, A = 0.166)
  expect_named(sim, c("J", "zeta", "L_T", "q_T"))
  # E[q_T] = q and E[J] = q
  expect_equal(mean(sim$q_T), 0.195, tolerance = 3e-3)
  expect_equal(mean(sim$J), 0.195, tolerance = 5e-3)
  # conditional drift: E[L_T - L | J = 1] = +A/2, | J = 0] = -A/2
  L0 <- ec_logit(0.195)
  expect_lt(abs(mean(sim$L_T[sim$J == 1]) - L0 - 0.166 / 2), 8e-3)
  expect_lt(abs(mean(sim$L_T[sim$J == 0]) - L0 + 0.166 / 2), 8e-3)
  # conditional variance = A
  expect_lt(abs(stats::var(sim$L_T[sim$J == 0]) - 0.166), 5e-3)
})

test_that("ec_simulate_path composes the transition and realizes the clock", {
  set.seed(2)
  paths <- ec_simulate_path(n_paths = 300, n_steps = 100, q = 0.3, A = 1)
  expect_equal(nrow(paths), 300 * 101)
  # starting point
  expect_equal(unique(paths$L[paths$step == 0]), ec_logit(0.3))
  # realized quadratic variation close to A on average
  qv <- vapply(
    split(paths$L, paths$path),
    function(L) sum(diff(L)^2), numeric(1)
  )
  expect_equal(mean(qv), 1, tolerance = 0.05)
  # terminal q is a martingale
  qT <- paths$q[paths$step == 100]
  expect_equal(mean(qT), 0.3, tolerance = 0.05)
  # measuring the path with event_clock recovers the clock
  p1 <- paths[paths$path == 1, ]
  ep <- as_event_prices(
    tibble::tibble(time = as.Date("2020-01-01") + p1$step, q = p1$q),
    clip = c(1e-6, 1 - 1e-6)
  )
  expect_equal(event_clock(ep, methods = "rv")$A, sum(diff(p1$L)^2), tolerance = 1e-6)
})
