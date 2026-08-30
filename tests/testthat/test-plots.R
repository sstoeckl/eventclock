test_that("plot functions return ggplot objects without errors", {
  ep <- ep_brexit()
  expect_s3_class(plot_q(ep), "ggplot")
  expect_s3_class(plot(ep), "ggplot")

  path <- event_clock_path(ep)
  expect_s3_class(plot_clock(path), "ggplot")
  expect_s3_class(plot_clock(path, normalize = FALSE), "ggplot")
  expect_s3_class(plot(path), "ggplot")
  expect_s3_class(plot_clock_vs_calendar(path), "ggplot")

  # event_prices input is converted automatically
  expect_s3_class(plot_clock(ep), "ggplot")

  # un-normalized paths cannot feed the calendar comparison
  path2 <- event_clock_path(ep, normalize = FALSE)
  expect_error(plot_clock_vs_calendar(path2), "normalize")
})

test_that("plots also work for the US and Polymarket series", {
  expect_s3_class(plot_q(ep_us()), "ggplot")
  ep <- as_event_prices(polymarket2024,
    market_id = "Polymarket: Trump wins 2024",
    event_date = as.POSIXct("2024-11-05", tz = "UTC")
  )
  expect_s3_class(plot_clock(event_clock_path(ep)), "ggplot")
})
