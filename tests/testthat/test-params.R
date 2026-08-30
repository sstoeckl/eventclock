test_that("default parameters are complete and modifiable", {
  p <- ec_default_params()
  expect_named(
    p, c("clip", "methods", "sample_every", "trunc_sd", "trailing")
  )
  expect_equal(p$clip, c(0.01, 0.99))
  expect_equal(p$trailing, 40L)
  p2 <- utils::modifyList(p, list(trunc_sd = 4))
  expect_equal(p2$trunc_sd, 4)
  expect_equal(p2$clip, p$clip)
})

test_that("internal clip helper validates bounds", {
  expect_equal(eventclock:::clip_q(c(0.005, 0.5, 0.995), c(0.01, 0.99)),
               c(0.01, 0.5, 0.99))
  expect_error(eventclock:::clip_q(0.5, c(0.9, 0.1)))
  expect_error(eventclock:::clip_q(0.5, c(0, 0.99)))
})
