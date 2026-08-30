test_that("ec_validate reports a clean series as clean", {
  v <- ec_validate(ep_brexit())
  expect_s3_class(v, "ec_validation")
  expect_equal(v$n_obs, 119)
  expect_equal(v$n_na, 0)
  expect_equal(v$n_gaps, 0L)
  expect_equal(v$spacing_days, 1)
  expect_equal(v$share_clip, 0)
  expect_output(print(v), "data-quality report")
})

test_that("ec_validate flags staleness, gaps, clipping, and outliers", {
  d <- tibble::tibble(
    time = as.Date("2020-01-01") + c(0:5, 8:12),
    q = c(0.40, 0.40, 0.40, 0.41, NA, 0.415, 0.42, 0.42, 0.005, 0.42, 0.43)
  )
  v <- ec_validate(as_event_prices(d))
  expect_equal(v$n_na, 1)
  expect_gte(v$max_stale_run, 2)      # the 0.40, 0.40, 0.40 run
  expect_gt(v$n_gaps, 0)              # NA + calendar hole
  expect_gt(v$share_clip, 0)          # the 0.005 quote
  expect_gt(v$outlier_ratio, 3)       # the plunge to 0.005 and back
  # tick: smallest non-zero move
  expect_equal(v$tick, 0.005, tolerance = 1e-12)
})

test_that("ec_validate needs at least two clean observations", {
  d <- tibble::tibble(time = as.Date("2020-01-01") + 0:1, q = c(0.5, NA))
  expect_error(ec_validate(as_event_prices(d)), "at least 2")
})
