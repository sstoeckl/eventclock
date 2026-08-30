test_that("as_event_prices standardizes the shipped datasets", {
  ep <- ep_brexit()
  expect_s3_class(ep, "event_prices")
  expect_named(ep, c("time", "q_raw", "q", "flag_na", "flag_clip"))
  expect_equal(nrow(ep), 119)
  expect_s3_class(ep$time, "Date")
  expect_equal(attr(ep, "market_id"), "Brexit: Leave")
  expect_equal(attr(ep, "event_date"), as.Date("2016-06-23"))
  expect_equal(attr(ep, "clip"), c(0.01, 0.99))
  # q_leave on the paper's 1M valuation date: 1 - 0.798 = 0.202
  expect_equal(ep$q[ep$time == as.Date("2016-05-24")], 0.202, tolerance = 1e-6)
})

test_that("column guessing works and explicit names are respected", {
  d <- tibble::tibble(date = as.Date("2020-01-01") + 0:2, price = c(0.4, 0.5, 0.6))
  ep <- as_event_prices(d)
  expect_equal(ep$q, c(0.4, 0.5, 0.6))
  # explicit names
  d2 <- tibble::tibble(when = as.Date("2020-01-01") + 0:2, prob = c(0.4, 0.5, 0.6))
  ep2 <- as_event_prices(d2, time = "when", price = "prob")
  expect_equal(ep2$q, c(0.4, 0.5, 0.6))
  # unresolvable columns error clearly
  expect_error(as_event_prices(d2), "Cannot guess")
  expect_error(as_event_prices(d, time = "nope"), "not found")
})

test_that("scale, discount, and mid-quote construction work", {
  d <- tibble::tibble(date = as.Date("2020-01-01") + 0:1, price = c(40, 60))
  ep <- as_event_prices(d, scale = 100)
  expect_equal(ep$q, c(0.4, 0.6))
  expect_equal(ep$q_raw, c(0.4, 0.6))

  epd <- as_event_prices(d, scale = 100, discount = 0.99)
  expect_equal(epd$q, c(0.4, 0.6) / 0.99)

  d2 <- tibble::tibble(
    date = as.Date("2020-01-01") + 0:1,
    b = c(0.39, 0.59), a = c(0.41, 0.61)
  )
  epm <- as_event_prices(d2, bid = "b", ask = "a")
  expect_equal(epm$q, c(0.4, 0.6))
})

test_that("flag-don't-drop: NA and out-of-bounds values are flagged, kept", {
  d <- tibble::tibble(
    date = as.Date("2020-01-01") + 0:3,
    q = c(0.005, 0.5, NA, 0.995)
  )
  ep <- as_event_prices(d)
  expect_equal(nrow(ep), 4)
  expect_equal(ep$flag_na, c(FALSE, FALSE, TRUE, FALSE))
  expect_equal(ep$flag_clip, c(TRUE, FALSE, FALSE, TRUE))
  # custom clip bounds
  ep2 <- as_event_prices(d, clip = c(0.001, 0.999))
  expect_equal(sum(ep2$flag_clip), 0)
})

test_that("unsorted input is sorted; duplicate timestamps warn and dedupe", {
  d <- tibble::tibble(
    date = as.Date(c("2020-01-03", "2020-01-01", "2020-01-02")),
    q = c(0.6, 0.4, 0.5)
  )
  ep <- as_event_prices(d)
  expect_equal(ep$q, c(0.4, 0.5, 0.6))
  d2 <- tibble::tibble(
    date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-02")),
    q = c(0.4, 0.45, 0.5)
  )
  expect_warning(ep2 <- as_event_prices(d2), "duplicated timestamp")
  expect_equal(nrow(ep2), 2)
  expect_equal(ep2$q, c(0.4, 0.5)) # first occurrence kept
})

test_that("character dates are parsed, bad time columns error", {
  d <- tibble::tibble(date = c("2020-01-01", "2020-01-02"), q = c(0.4, 0.5))
  ep <- as_event_prices(d)
  expect_equal(nrow(ep), 2)
  d2 <- tibble::tibble(date = c(1, 2), q = c(0.4, 0.5))
  expect_error(as_event_prices(d2), "must be")
})

test_that("rows with missing timestamps are removed with a warning", {
  d <- tibble::tibble(
    date = as.Date(c("2020-01-01", NA, "2020-01-03")),
    q = c(0.4, 0.5, 0.6)
  )
  expect_warning(ep <- as_event_prices(d), "missing timestamp")
  expect_equal(nrow(ep), 2)
  expect_equal(ep$q, c(0.4, 0.6))
})

test_that("as_event_prices is idempotent on event_prices objects", {
  ep <- ep_brexit()
  expect_identical(as_event_prices(ep), ep)
})

test_that("print and summary methods work", {
  ep <- ep_brexit()
  expect_output(print(ep), "Event prices")
  s <- summary(ep)
  expect_s3_class(s, "tbl_df")
  expect_equal(nrow(s), 1)
  expect_equal(s$n, 119)
  expect_equal(s$market_id, "Brexit: Leave")
  expect_equal(s$n_na, 0)
  # full-sample clock matches event_clock
  expect_equal(s$A_full, event_clock(ep, methods = "rv")$A, tolerance = 1e-12)
})
