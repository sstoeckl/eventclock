test_that("fed funds futures extraction matches the hand-computed example", {
  # decision on the 15th of a 30-day month, pre 5.33, futures 94.79
  r <- q_from_ffutures(94.79, pre_rate = 5.33,
                       meeting_date = as.Date("2024-09-15"), step = -0.25)
  expect_equal(r$implied_avg, 5.21, tolerance = 1e-12)
  expect_equal(r$implied_post, (30 * 5.21 - 15 * 5.33) / 15, tolerance = 1e-12)
  expect_equal(r$q, 0.96, tolerance = 1e-10)
  # no move priced: q = 0
  r0 <- q_from_ffutures(100 - 5.33, pre_rate = 5.33,
                        meeting_date = as.Date("2024-09-15"))
  expect_equal(r0$q, 0, tolerance = 1e-10)
})

test_that("fed funds futures extraction warns on multi-step and month-end", {
  # more than one 25bp step priced
  expect_warning(
    q_from_ffutures(95.00, pre_rate = 5.33,
                    meeting_date = as.Date("2024-09-15"), step = -0.25),
    "outside"
  )
  # decision at the very end of the month is ill-conditioned (and the
  # degenerate extraction also prices multiple steps -> second warning)
  expect_warning(
    expect_warning(
      q_from_ffutures(94.79, pre_rate = 5.33,
                      meeting_date = as.Date("2024-09-29"), step = -0.25),
      "ill-conditioned"
    ),
    "outside"
  )
})

test_that("fomc_meetings calendar is consistent", {
  expect_equal(nrow(fomc_meetings), 56)
  expect_equal(unique(table(fomc_meetings$year)), 8L)
  expect_equal(sum(fomc_meetings$sep), 28)
  # known decision days
  expect_true(as.Date("2024-09-18") %in% fomc_meetings$decision_date)
  expect_true(as.Date("2024-11-07") %in% fomc_meetings$decision_date)
  expect_true(as.Date("2026-09-16") %in% fomc_meetings$decision_date)
  # SEP meetings are the Mar/Jun/Sep/Dec ones
  sep24 <- fomc_meetings$decision_date[
    fomc_meetings$year == 2024 & fomc_meetings$sep
  ]
  expect_equal(format(sep24, "%m"), c("03", "06", "09", "12"))
})

test_that("deal-spread probabilities follow the merger-arb formula", {
  expect_equal(q_from_deal_spread(47, offer = 50, fallback = 35), 0.8)
  expect_equal(q_from_deal_spread(35, offer = 50, fallback = 35), 0)
  expect_equal(q_from_deal_spread(50, offer = 50, fallback = 35), 1)
  # discounted offer
  expect_equal(
    q_from_deal_spread(47, offer = 50, fallback = 35, discount = 0.98),
    (47 - 35) / (49 - 35)
  )
  expect_warning(q_from_deal_spread(52, offer = 50, fallback = 35), "outside")
  expect_error(q_from_deal_spread(47, offer = 30, fallback = 35), "exceed")
  # vectorized over the target path -> feeds straight into the clock
  qs <- q_from_deal_spread(c(40, 42, 45, 47), 50, 35)
  expect_equal(length(qs), 4)
})

test_that("ec_relevance ties out with variance share and IV rule", {
  rho <- ec_relevance(deta = -0.099, q = 0.172, A = 0.046,
                      sigma = 0.19326, tenor = 14 / 365)
  vs <- ec_variance_share(sigma = 0.19326, deta = -0.099, q = 0.172,
                          A = 0.046, tenor = 14 / 365)
  iv <- ec_iv_rule(deta = -0.099, q = 0.172, A = 0.046,
                   sigma = 0.19326, tenor = 14 / 365)
  expect_equal(vs, rho / (1 + rho), tolerance = 1e-12)
  expect_equal(iv, 0.19326 * rho / 2, tolerance = 1e-12)
})
