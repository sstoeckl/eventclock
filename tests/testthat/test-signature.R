test_that("signature averages subsample offsets and reports spacing", {
  # clean random-walk logit path: signature should be roughly flat
  set.seed(3)
  p <- ec_simulate_path(1, 400, q = 0.4, A = 1)
  ep <- as_event_prices(
    tibble::tibble(time = as.Date("2020-01-01") + p$step, q = p$q),
    clip = c(1e-8, 1 - 1e-8)
  )
  sig <- ec_signature(ep, max_every = 8)
  expect_s3_class(sig, "ec_signature")
  expect_equal(sig$sample_every, 1:8)
  expect_equal(sig$spacing_days, 1:8)
  expect_true(all(sig$A_min <= sig$A & sig$A <= sig$A_max))
  # flat within sampling noise: sparse estimates stay within 25% of k=1
  expect_true(all(abs(sig$A / sig$A[1] - 1) < 0.25))

  # k = 1 equals the plain full-sample estimate
  expect_equal(sig$A[1], event_clock(ep, methods = "rv")$A, tolerance = 1e-12)
})

test_that("signature detects additive microstructure noise", {
  set.seed(4)
  p <- ec_simulate_path(1, 400, q = 0.4, A = 1)
  noisy <- stats::plogis(p$L + stats::rnorm(nrow(p), sd = 0.05))
  ep <- as_event_prices(
    tibble::tibble(time = as.Date("2020-01-01") + p$step, q = noisy),
    clip = c(1e-8, 1 - 1e-8)
  )
  sig <- ec_signature(ep, max_every = 10)
  # iid noise adds ~2*n*var per grid: finest sampling inflated well above
  # the sparsest estimate
  expect_gt(sig$A[1], 1.5 * sig$A[10])
  # and the plot works
  expect_s3_class(plot_signature(sig), "ggplot")
  expect_s3_class(plot(sig), "ggplot")
})

test_that("signature input validation", {
  d <- tibble::tibble(time = as.Date("2020-01-01") + 0:5, q = rep(0.5, 6))
  expect_error(ec_signature(as_event_prices(d), max_every = 10), "observations")
})
