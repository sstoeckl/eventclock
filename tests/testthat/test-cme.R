# Synthetic CME-style fixture: one future, calls and puts on a strike grid,
# two trading dates, prices from Black (1976) with a known smile.

bs76 <- function(F, K, sigma, tau, r, type) {
  s <- sigma * sqrt(tau)
  d1 <- (log(F / K) + s^2 / 2) / s
  d2 <- d1 - s
  DF <- exp(-r * tau)
  if (type == "call") DF * (F * pnorm(d1) - K * pnorm(d2)) else
    DF * (K * pnorm(-d2) - F * pnorm(-d1))
}
smile <- function(k) 0.12 + 0.5 * k^2 - 0.05 * k

make_fixture <- function(r = 0.02, F0 = c(0.0540, 0.0548)) {
  strikes <- c(0.0500, 0.0520, 0.0540, 0.0560, 0.0580)
  exp_opt <- as.POSIXct("2016-07-29 19:00:00", tz = "UTC")
  defs <- data.frame(
    ts_recv = as.POSIXct("2016-06-01", tz = "UTC"),
    instrument_id = c(1, 100 + seq_along(strikes), 200 + seq_along(strikes), 900),
    raw_symbol = c("6MU6", paste0("6MQ6 C", strikes), paste0("6MQ6 P", strikes), "6MU6-6MZ6"),
    asset = "6M",
    instrument_class = c("F", rep("C", 5), rep("P", 5), "S"),
    cfi = c("FFCXSX", rep("OCAFPS", 5), rep("OPAFPS", 5), "FMCXSX"),
    expiration = c(as.POSIXct("2016-09-19 14:16:00", tz = "UTC"),
                   rep(exp_opt, 10), as.POSIXct("2016-09-19 14:16:00", tz = "UTC")),
    strike_price = c(NA, strikes, strikes, NA),
    underlying_id = c(0, rep(1, 10), 0),
    underlying = c("", rep("6MU6", 10), ""),
    security_update_action = "A",
    stringsAsFactors = FALSE
  )
  dates <- as.Date(c("2016-07-01", "2016-07-05"))
  st <- list()
  for (d in seq_along(dates)) {
    val <- as.POSIXct(paste(dates[d], "14:00"), tz = "America/Chicago")
    tau <- as.numeric(difftime(exp_opt, val, units = "days")) / 365
    ref <- as.POSIXct(format(dates[d]), tz = "UTC")
    pub <- as.POSIXct(paste(dates[d], "22:00"), tz = "UTC")
    px <- c(F0[d],
            vapply(strikes, function(K) bs76(F0[d], K, smile(log(K / F0[d])), tau, r, "call"), 0),
            vapply(strikes, function(K) bs76(F0[d], K, smile(log(K / F0[d])), tau, r, "put"), 0))
    ids <- c(1, 100 + seq_along(strikes), 200 + seq_along(strikes))
    # preliminary (flag 4, wrong price), then final (flag 3)
    st[[length(st) + 1]] <- data.frame(ts_recv = pub - 3600, ts_event = pub - 3600,
      instrument_id = ids, ts_ref = ref, price = px * 1.1, quantity = NA,
      sequence = 1, stat_type = 3, update_action = 1, stat_flags = 4L)
    st[[length(st) + 1]] <- data.frame(ts_recv = pub, ts_event = pub,
      instrument_id = ids, ts_ref = ref, price = px, quantity = NA,
      sequence = 2, stat_type = 3, update_action = 1, stat_flags = 3L)
    # open interest
    st[[length(st) + 1]] <- data.frame(ts_recv = pub + 86400, ts_event = pub + 86400,
      instrument_id = ids, ts_ref = ref, price = NA, quantity = 10 * seq_along(ids),
      sequence = 3, stat_type = 9, update_action = 1, stat_flags = 0L)
  }
  list(defs = defs, st = do.call(rbind, st), strikes = strikes, r = r, F0 = F0,
       dates = dates, exp_opt = exp_opt)
}

to_text <- function(d) {
  out <- d
  for (v in names(out)) {
    x <- out[[v]]
    out[[v]] <- if (inherits(x, "POSIXct")) {
      ifelse(is.na(x), "", format(x, "%Y-%m-%dT%H:%M:%S.000000000Z", tz = "UTC"))
    } else ifelse(is.na(x), "", as.character(x))
  }
  out
}

test_that("definitions: latest record per instrument, classes, exercise style", {
  fx <- make_fixture()
  d <- fx$defs
  # an older, outdated record for instrument 101 (wrong strike)
  old <- d[d$instrument_id == 101, ]
  old$ts_recv <- old$ts_recv - 86400
  old$strike_price <- 0.0999
  dd <- cme_definitions(rbind(old, d))
  expect_s3_class(dd, "cme_definitions")
  expect_equal(dd$strike[dd$instrument_id == 101], 0.05)
  expect_false(900 %in% dd$instrument_id)           # spread dropped
  expect_equal(sort(unique(dd$type)), c("call", "future", "put"))
  expect_equal(unique(dd$exercise[dd$type %in% c("call", "put")]), "american")
  expect_true(is.na(dd$exercise[dd$type == "future"]))
  expect_true(900 %in% cme_definitions(d, classes = c("C", "P", "F", "S"))$instrument_id)
})

test_that("definitions read the same from an all-text file", {
  fx <- make_fixture()
  typed <- cme_definitions(fx$defs)
  text <- cme_definitions(to_text(fx$defs))
  expect_equal(text$instrument_id, typed$instrument_id)
  expect_equal(text$strike, typed$strike)
  expect_equal(as.numeric(text$expiration), as.numeric(typed$expiration))
  expect_equal(text$exercise, typed$exercise)
})

test_that("deleted instruments are dropped", {
  fx <- make_fixture()
  d <- fx$defs
  del <- d[d$instrument_id == 105, ]
  del$ts_recv <- del$ts_recv + 86400
  del$security_update_action <- "D"
  expect_false(105 %in% cme_definitions(rbind(d, del))$instrument_id)
})

test_that("statistics: last final settlement wins over preliminary ones", {
  base <- data.frame(instrument_id = 7, ts_ref = as.POSIXct("2016-07-01", tz = "UTC"),
                     stat_type = 3, update_action = 1)
  t0 <- as.POSIXct("2016-07-01 19:00", tz = "UTC")
  st <- rbind(
    cbind(base, ts_event = t0, ts_recv = t0, sequence = 1, price = 1.00, stat_flags = 4L),
    cbind(base, ts_event = t0 + 600, ts_recv = t0 + 600, sequence = 2, price = 1.01, stat_flags = 2L),
    cbind(base, ts_event = t0 + 1200, ts_recv = t0 + 1200, sequence = 3, price = 1.02, stat_flags = 3L),
    # a later preliminary re-send must not override the final value
    cbind(base, ts_event = t0 + 1800, ts_recv = t0 + 1800, sequence = 4, price = 9.99, stat_flags = 4L),
    # a second final re-send overrides the first final
    cbind(base, ts_event = t0 + 2400, ts_recv = t0 + 2400, sequence = 5, price = 1.03, stat_flags = 1L)
  )
  s <- cme_statistics(st)
  expect_equal(nrow(s), 1)
  expect_equal(s$settle, 1.03)
  expect_true(s$settle_final)
  # only preliminary -> last preliminary, flagged
  s2 <- cme_statistics(st[1:2, ])
  expect_equal(s2$settle, 1.01)
  expect_false(s2$settle_final)
})

test_that("statistics: missing ts_ref maps weekend publications to Friday", {
  fri <- as.POSIXct("2016-05-20", tz = "UTC")
  st <- data.frame(
    instrument_id = c(1, 2, 3),
    ts_event = as.POSIXct(c("2016-05-22 16:00:44",   # Sunday
                            "2016-05-24 01:30:00",   # Monday evening Chicago
                            "2016-05-23 21:00:00"), tz = "UTC"),
    ts_ref = as.POSIXct(c(NA, NA, NA), tz = "UTC"),
    stat_type = 3, price = c(1, 2, 3), stat_flags = 3L
  )
  s <- cme_statistics(st)
  expect_equal(s$date, as.Date(c("2016-05-20", "2016-05-23", "2016-05-23")))
  # a reference-dated final takes precedence over a fallback-dated one
  st2 <- data.frame(
    instrument_id = 1,
    ts_event = as.POSIXct(c("2016-05-20 22:00", "2016-05-22 16:00"), tz = "UTC"),
    ts_ref = c(fri, NA), stat_type = 3, price = c(1.5, 1.4), stat_flags = 3L
  )
  expect_equal(cme_statistics(st2)$settle, 1.5)
})

test_that("statistics: deletions, undefined quantities, open interest", {
  t0 <- as.POSIXct("2016-07-01 19:00", tz = "UTC")
  ref <- as.POSIXct("2016-07-01", tz = "UTC")
  st <- data.frame(
    instrument_id = 5, ts_ref = ref,
    ts_event = t0 + c(0, 60, 120, 86400),
    ts_recv = t0 + c(0, 60, 120, 86400),
    sequence = 1:4,
    stat_type = c(3, 3, 3, 9),
    update_action = c(1, 2, 1, 1),
    price = c(2.0, 2.0, 2.2, NA),
    quantity = c(NA, NA, NA, 9.223372036854775807e18),
    stat_flags = c(3L, 3L, 4L, 0L)
  )
  s <- cme_statistics(st)
  # the delete removes the first final; the later preliminary survives
  expect_equal(s$settle, 2.2)
  expect_false(s$settle_final)
  expect_true(is.na(s$open_interest))
  st$quantity[4] <- 1234
  expect_equal(cme_statistics(st)$open_interest, 1234)
})

test_that("statistics read the same from an all-text file", {
  fx <- make_fixture()
  a <- cme_statistics(fx$st)
  b <- cme_statistics(to_text(fx$st))
  expect_equal(b$settle, a$settle)
  expect_equal(b$date, a$date)
  expect_equal(b$open_interest, a$open_interest)
})

test_that("surfaces recover the Black-76 smile, forward, tau, and parity", {
  fx <- make_fixture()
  s <- cme_option_surfaces(fx$defs, fx$st, rate = fx$r)
  expect_equal(nrow(s), 10)
  expect_equal(length(unique(s$surface)), 2)
  expect_equal(sort(unique(s$F)), sort(fx$F0))
  val <- as.POSIXct("2016-07-01 14:00", tz = "America/Chicago")
  tau1 <- as.numeric(difftime(fx$exp_opt, val, units = "days")) / 365
  expect_equal(s$tau[s$date == as.Date("2016-07-01")][1], tau1)
  expect_equal(s$iv, smile(s$k), tolerance = 1e-8)
  expect_equal(s$iv_call, s$iv_put, tolerance = 1e-8)
  expect_equal(s$k, log(s$strike / s$F))
  expect_equal(s$parity_gap, rep(0, 10), tolerance = 1e-12)
  expect_equal(s$F_parity, s$F, tolerance = 1e-12)
  expect_equal(s$otm, ifelse(s$strike >= s$F, "call", "put"))
  expect_true(all(s$call_final & s$put_final & s$F_final))
  expect_true(all(s$oi_call > 0 & s$oi_put > 0))
  expect_equal(unique(s$exercise), "american")
  # vega matches a numerical derivative of the discounted call
  i <- 3
  h <- 1e-6
  num <- (bs76(s$F[i], s$strike[i], s$iv[i] + h, s$tau[i], fx$r, "call") -
          bs76(s$F[i], s$strike[i], s$iv[i] - h, s$tau[i], fx$r, "call")) / (2 * h)
  expect_equal(s$vega[i], num, tolerance = 1e-6)
})

test_that("surfaces: discounting matters, min_price, window, assets", {
  fx <- make_fixture()
  s0 <- cme_option_surfaces(fx$defs, fx$st, rate = 0)
  expect_false(isTRUE(all.equal(s0$iv, smile(s0$k), tolerance = 1e-6)))
  rf <- function(date, tau) rep(fx$r, length(tau))
  s1 <- cme_option_surfaces(fx$defs, fx$st, rate = rf)
  expect_equal(s1$iv, smile(s1$k), tolerance = 1e-8)
  s2 <- cme_option_surfaces(fx$defs, fx$st, rate = fx$r, min_price = 1)
  expect_true(all(is.na(s2$iv)))
  s3 <- cme_option_surfaces(fx$defs, fx$st, rate = fx$r, from = "2016-07-02")
  expect_equal(unique(s3$date), as.Date("2016-07-05"))
  expect_error(cme_option_surfaces(fx$defs, fx$st, assets = "6B"), "No option")
})

test_that("inverted quotes: same volatility, mirrored moneyness, converted prices", {
  fx <- make_fixture()
  s <- cme_option_surfaces(fx$defs, fx$st, rate = fx$r)
  v <- cme_option_surfaces(fx$defs, fx$st, rate = fx$r, invert = TRUE)
  m <- match(paste(v$date, round(1 / v$strike, 10)), paste(s$date, round(s$strike, 10)))
  expect_equal(v$F, 1 / s$F[m])
  expect_equal(v$k, -s$k[m])
  expect_equal(v$iv_call, s$iv_put[m], tolerance = 1e-8)
  expect_equal(v$iv_put, s$iv_call[m], tolerance = 1e-8)
  expect_equal(v$call, s$put[m] / (s$F[m] * s$strike[m]))
  expect_equal(v$oi_call, s$oi_put[m])
  expect_equal(v$parity_gap, rep(0, nrow(v)), tolerance = 1e-9)
})

test_that("surfaces attach the event probability without look-ahead", {
  fx <- make_fixture()
  ep <- as_event_prices(data.frame(
    time = as.POSIXct(c("2016-07-01 14:00", "2016-07-01 16:00",
                        "2016-07-05 13:00", "2016-07-05 20:00"), tz = "America/New_York"),
    q = c(0.30, 0.31, 0.40, 0.45)
  ))
  # valuation 14:00 Chicago = 15:00 New York
  s <- cme_option_surfaces(fx$defs, fx$st, rate = fx$r, x = ep)
  expect_equal(unique(s$q[s$date == as.Date("2016-07-01")]), 0.30)
  expect_equal(unique(s$q[s$date == as.Date("2016-07-05")]), 0.40)
  # the output feeds ec_theta_fit directly
  expect_true(all(c("surface", "k", "iv", "q", "tau") %in% names(s)))
})

test_that("missing forward keeps the row without a volatility", {
  fx <- make_fixture()
  st <- fx$st[!(fx$st$instrument_id == 1 & fx$st$ts_ref == as.POSIXct("2016-07-05", tz = "UTC")), ]
  s <- cme_option_surfaces(fx$defs, st, rate = fx$r)
  expect_true(all(is.na(s$F[s$date == as.Date("2016-07-05")])))
  expect_true(all(is.na(s$iv[s$date == as.Date("2016-07-05")])))
  expect_true(all(is.finite(s$iv[s$date == as.Date("2016-07-01")])))
})

test_that("Parquet and CSV paths read like data frames", {
  skip_if_not_installed("arrow")
  fx <- make_fixture()
  dir <- tempfile("cme")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  arrow::write_parquet(to_text(fx$defs), file.path(dir, "defs.parquet"))
  arrow::write_parquet(fx$st, file.path(dir, "stats.parquet"))
  s_path <- cme_option_surfaces(file.path(dir, "defs.parquet"),
                                file.path(dir, "stats.parquet"), rate = fx$r)
  s_df <- cme_option_surfaces(fx$defs, fx$st, rate = fx$r)
  expect_equal(s_path$iv, s_df$iv)
  utils::write.csv(fx$defs, file.path(dir, "defs.csv"), row.names = FALSE)
  expect_equal(cme_definitions(file.path(dir, "defs.csv"))$strike,
               cme_definitions(fx$defs)$strike)
})

test_that("time and number coercion handle sentinels and formats", {
  expect_true(is.na(eventclock:::as_num("9223372036854775807")))
  expect_equal(eventclock:::as_num(c("1.5", "", "x")), c(1.5, NA, NA))
  t1 <- eventclock:::as_utc_time("2016-07-01T19:00:00.123456789Z")
  expect_equal(format(t1, "%Y-%m-%d %H:%M:%S", tz = "UTC"), "2016-07-01 19:00:00")
  t2 <- eventclock:::as_utc_time(1467399600000000000)
  expect_equal(as.numeric(t2), 1467399600)
  t3 <- eventclock:::as_utc_time("2016-07-01")
  expect_equal(format(t3, tz = "UTC"), "2016-07-01")
  expect_true(is.na(eventclock:::as_utc_time("18446744073709551615")))
})
