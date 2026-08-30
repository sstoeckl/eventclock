# The worked Brexit example of the teaching companion, section "Formelbuch":
# q = 0.195, L = -1.418, q(1-q) = 0.157, A = 0.166, deta = -0.012.

test_that("moments reproduce the worked Brexit example", {
  m <- ec_moments(0.195, 0.166)
  expect_equal(m$L, -1.4178431, tolerance = 1e-6)
  expect_equal(m$E_qT, 0.195) # A-free martingale property
  expect_equal(m$E_LT, stats::qlogis(0.195) + (0.195 - 0.5) * 0.166, tolerance = 1e-10)
  expect_equal(m$sd_LT, 0.4127, tolerance = 1e-3) # "0.41" in the companion
  expect_equal(m$var_LT, 0.166 + 0.195 * 0.805 * 0.166^2, tolerance = 1e-10)
  expect_equal(m$m3_LT, 0.195 * 0.805 * (1 - 0.39) * 0.166^3, tolerance = 1e-10)
  # variance approximation respects its exact bound
  expect_lte(m$var_qT, m$var_qT_bound)
})

test_that("typical revision: about 5 probability points in two weeks", {
  expect_equal(ec_revision(0.195, 0.166), 0.05103, tolerance = 1e-4)
})

test_that("ATM event claim: about 3 basis points", {
  val <- ec_atm_event_call(q = 0.195, A = 0.166, deta = -0.012)
  expect_lt(abs(val - 0.000306), 1e-6)
  # sign of the exposure does not matter
  expect_equal(val, ec_atm_event_call(q = 0.195, A = 0.166, deta = 0.012))
})

test_that("target clock: from 19.5% to 90% takes A* of about 7.2", {
  expect_equal(ec_target_clock(0.195, 0.9), 7.2301, tolerance = 1e-4)
  # symmetric definition: moving down is negative
  expect_lt(ec_target_clock(0.9, 0.195), 0)
})

test_that("rule of thumb reproduces the paper's IV contributions", {
  # US 2016, 2W, tenor ATM 19.326%: about 0.062 IV percentage points
  us <- 100 * ec_iv_rule(
    deta = -0.099, q = 0.172, A = 0.046, sigma = 0.19326, tenor = 14 / 365
  )
  expect_lt(abs(us - 0.0617), 1e-4)
  # Brexit 2016, 2W: 0.007 with the 2W ATM (10.59%), 0.008 with 9.325%
  gb1 <- 100 * ec_iv_rule(
    deta = -0.012, q = 0.195, A = 0.166, sigma = 0.10590, tenor = 14 / 365
  )
  gb2 <- 100 * ec_iv_rule(
    deta = -0.012, q = 0.195, A = 0.166, sigma = 0.09325, tenor = 14 / 365
  )
  expect_lt(abs(gb1 - 0.00725), 1e-5)
  expect_lt(abs(gb2 - 0.00823), 1e-5)
})

test_that("variance shares match the companion's FAQ (0.2% / 1.1%)", {
  gb <- ec_variance_share(
    sigma = 0.09325, deta = -0.012, q = 0.195, A = 0.166, tenor = 14 / 365
  )
  us <- ec_variance_share(
    sigma = 0.146, deta = -0.099, q = 0.172, A = 0.046, tenor = 14 / 365
  )
  # pinned values; the companion quotes them rounded as 0.2% and 1.1%
  expect_lt(abs(gb - 0.00176), 1e-5)
  expect_lt(abs(us - 0.01110), 1e-4)
  expect_equal(round(100 * gb, 1), 0.2)
  expect_equal(round(100 * us, 1), 1.1)
})

test_that("sigma_eff is consistent with the rule of thumb to first order", {
  sigma <- 0.19326
  tenor <- 14 / 365
  se <- ec_sigma_eff(sigma, deta = -0.099, q = 0.172, A = 0.046, tenor = tenor)
  rule <- ec_iv_rule(deta = -0.099, q = 0.172, A = 0.046, sigma = sigma, tenor = tenor)
  expect_lt(abs((se - sigma) - rule), 5e-6)
  expect_gt(se, sigma)
})

test_that("exceedance probability behaves correctly", {
  # monotone decreasing in the threshold
  x <- c(0.1, 0.3, 0.5, 0.7, 0.9)
  p <- ec_exceedance(x, q = 0.195, A = 0.166)
  expect_true(all(diff(p) < 0))
  expect_true(all(p >= 0 & p <= 1))
  # extreme thresholds
  expect_gt(ec_exceedance(0.0001, q = 0.5, A = 0.1), 0.999)
  expect_lt(ec_exceedance(0.9999, q = 0.5, A = 0.1), 0.001)
  # A = 0 degenerates to an indicator at the current q
  expect_equal(ec_exceedance(0.5, q = 0.6, A = 0), 1)
  expect_equal(ec_exceedance(0.7, q = 0.6, A = 0), 0)
  # consistency with simulation
  set.seed(42)
  sim <- ec_simulate(2e5, q = 0.195, A = 0.166)
  expect_lt(
    abs(mean(sim$q_T > 0.3) - ec_exceedance(0.3, q = 0.195, A = 0.166)),
    3e-3
  )
})

test_that("formula-book inputs are validated", {
  expect_error(ec_moments(0, 0.1), "inside")
  expect_error(ec_moments(1, 0.1), "inside")
  expect_error(ec_moments(0.5, -0.1), "non-negative")
  expect_error(ec_revision(1.2, 0.1), "inside")
  expect_error(ec_target_clock(0.5, 1), "inside")
})

test_that("vector recycling is explicit and incompatible lengths error", {
  # compatible: scalar against vector
  expect_length(ec_revision(q = c(0.2, 0.3, 0.4), A = 0.1), 3)
  # compatible: exact multiples
  expect_length(ec_iv_rule(
    deta = -0.01, q = c(0.2, 0.3), A = c(0.1, 0.2, 0.1, 0.2),
    sigma = 0.1, tenor = 14 / 365
  ), 4)
  # incompatible lengths must error, not silently misalign
  expect_error(ec_revision(q = c(0.2, 0.3), A = c(0.1, 0.2, 0.3)), "incompatible")
  expect_error(
    ec_sigma_eff(sigma = c(0.1, 0.2), deta = -0.01, q = c(0.2, 0.3, 0.4),
                 A = 0.1, tenor = 14 / 365),
    "incompatible"
  )
  # recycled call matches the element-wise call
  expect_equal(
    ec_revision(q = c(0.2, 0.3), A = 0.1),
    c(ec_revision(0.2, 0.1), ec_revision(0.3, 0.1))
  )
})
