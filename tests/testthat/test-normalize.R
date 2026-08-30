test_that("discount normalization undoes discounting", {
  expect_equal(q_from_price(0.5), 0.5)
  expect_equal(q_from_price(0.495, discount = 0.99), 0.5)
  # vectorized discounts
  expect_equal(
    q_from_price(c(0.49, 0.48), discount = c(0.98, 0.96)),
    c(0.5, 0.5)
  )
  expect_error(q_from_price(0.5, discount = 1.01), "must lie in")
  expect_error(q_from_price(0.5, discount = 0), "must lie in")
})

test_that("overround normalization divides by the book", {
  expect_equal(q_from_price(0.52, book = 1.04, method = "overround"), 0.5)
  expect_error(q_from_price(0.52, method = "overround"), "book")
})

test_that("out-of-bounds results warn but are returned (flag, don't drop)", {
  expect_warning(res <- q_from_price(1.05), "outside")
  expect_equal(res, 1.05)
  expect_silent(q_from_price(c(0.2, NA, 0.8)))
})

test_that("logit helpers agree with base R", {
  q <- c(0.195, 0.5, 0.9)
  expect_equal(ec_logit(q), stats::qlogis(q))
  expect_equal(ec_ilogit(ec_logit(q)), q)
  expect_equal(ec_logit(0.195), -1.4178431, tolerance = 1e-6)
})
