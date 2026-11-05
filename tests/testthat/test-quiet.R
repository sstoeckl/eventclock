# Synthetic library: weekly surfaces; quiet ones (small A) carry the
# ordinary smile, busy ones an added event skew.
ord_shape <- function(k) 0.8 * k^2
evt_shape <- function(k) 0.8 * k^2 - 0.3 * k

make_nodes <- function(A, atm = 0.5, start = as.Date("2024-06-03"),
                       k = round(seq(-0.3, 0.3, by = 0.05), 10), dte = 4) {
  n <- length(A)
  nd <- expand.grid(i = seq_len(n), k = k)
  nd$surface <- sprintf("s%02d", nd$i)
  nd$date <- start + 7 * (nd$i - 1)
  nd$expiry <- nd$date + if (length(dte) == 1) dte else dte[nd$i]
  atm_i <- rep_len(atm, n)[nd$i]
  nd$A <- A[nd$i]
  nd$iv <- atm_i + ifelse(nd$A > 0.1, evt_shape(nd$k), ord_shape(nd$k))
  nd
}

test_that("rule grids have the pre-specified sizes and labels", {
  r15 <- ec_quiet_rules()
  expect_equal(nrow(r15), 15)
  expect_equal(r15$rule[1], "p25 | any DTE | all")
  expect_true("p75 | any DTE | atm5" %in% r15$rule)
  r30 <- ec_quiet_rules(c(0.03, 0.04, 0.06), "absolute", dte_band = c(1, 2),
                        aggregation = c("all", "atm1", "atm2", "atm3", "atm5"))
  expect_equal(nrow(r30), 30)
  expect_true("A<=0.04 | DTE+-2 | all" %in% r30$rule)
  expect_equal(r30$agg_n[r30$aggregation == "atm3"][1], 3L)
  expect_error(ec_quiet_rules(aggregation = "nearest5"), "Unknown")
  expect_error(ec_quiet_rules(quiet = 1.5), "Quantile")
})

test_that("library: ATM interpolation, shapes, days to expiry", {
  nd <- data.frame(surface = "a", date = as.Date("2024-01-02"),
                   expiry = as.Date("2024-01-05"), k = c(-0.1, 0.1, 0.2),
                   iv = c(0.20, 0.22, 0.30), A = 0.01)
  lib <- ec_quiet_library(nd)
  expect_s3_class(lib, "ec_quiet_library")
  expect_equal(lib$atm_iv, 0.21)
  expect_equal(lib$dte, 3)
  expect_equal(lib$nodes[[1]]$shape, c(-0.01, 0.01, 0.09))
  libr <- ec_quiet_library(nd, shape = "ratio")
  expect_equal(libr$nodes[[1]]$shape, c(0.20, 0.22, 0.30) / 0.21)
  # one-sided nodes: nearest node within atm_tol, else NA
  one <- transform(nd, k = c(0.01, 0.1, 0.2))
  expect_equal(ec_quiet_library(one)$atm_iv, 0.20)
  expect_true(is.na(ec_quiet_library(one, atm_tol = 0.005)$atm_iv))
  expect_error(ec_quiet_library(nd[, -1]), "missing")
  bad <- nd
  bad$date[2] <- as.Date("2024-01-03")
  expect_error(ec_quiet_library(bad), "more than one")
})

test_that("library: realized clock over each surface's own life", {
  days <- seq(as.Date("2024-01-01"), as.Date("2024-01-20"), by = "day")
  L <- cumsum(c(0, rep(c(0.1, -0.2), length.out = length(days) - 1)))
  ep <- as_event_prices(data.frame(time = days, q = plogis(L)), clip = c(1e-8, 1 - 1e-8))
  nd <- data.frame(surface = rep(c("a", "b"), each = 3),
                   date = rep(as.Date(c("2024-01-03", "2024-01-15")), each = 3),
                   expiry = rep(as.Date(c("2024-01-08", "2024-01-25")), each = 3),
                   k = rep(c(-0.1, 0, 0.1), 2), iv = 0.3)
  lib <- ec_quiet_library(nd, x = ep)
  w <- days >= as.Date("2024-01-03") & days <= as.Date("2024-01-08")
  expect_equal(lib$A[1], sum(diff(L[w])^2), tolerance = 1e-10)
  expect_true(lib$A_complete[1])
  # life extends beyond the data: no clock
  expect_true(is.na(lib$A[2]))
  expect_false(lib$A_complete[2])
})

test_that("library: staggered intraday clock", {
  tt <- as.POSIXct("2024-01-01 00:00", tz = "UTC") + 3600 * (0:200)
  set.seed(3)
  L <- cumsum(c(0, rnorm(200, sd = 0.05)))
  ep <- as_event_prices(data.frame(time = tt, q = plogis(L)), clip = c(1e-8, 1 - 1e-8))
  nd <- data.frame(surface = "a", date = tt[10], expiry = tt[150],
                   k = c(-0.1, 0, 0.1), iv = 0.3)
  lib <- ec_quiet_library(nd, x = ep, interval = 120)
  ref <- event_clock_staggered(ep, from = tt[10], to = tt[150], interval = 120)$A
  expect_equal(lib$A, ref, tolerance = 1e-10)
})

test_that("shape: only templates expired by the cutoff enter", {
  A <- c(0.01, 0.02, 0.01, 0.02, 0.01)
  nd <- make_nodes(A)
  # a poisoned future template with a wild shape and a tiny clock
  poison <- make_nodes(0.001, start = as.Date("2024-08-05"))
  poison$surface <- "poison"
  poison$iv <- 0.5 + 5 * poison$k
  lib <- ec_quiet_library(rbind(nd, poison))
  tgt <- as.Date("2024-07-15")
  rules <- ec_quiet_rules(1, aggregation = "all")
  a <- ec_quiet_shape(lib, tgt, tgt + 4, 0.5, k = c(-0.2, 0.2), rules)
  expect_equal(a$shape, ord_shape(c(-0.2, 0.2)), tolerance = 1e-12)
  expect_false("poison" %in% attr(a, "templates")[[1]])
  expect_equal(a$iv_pred, 0.5 + ord_shape(c(-0.2, 0.2)), tolerance = 1e-12)
  # without the cutoff the poison template enters
  b <- ec_quiet_shape(lib, tgt, tgt + 4, 0.5, k = c(-0.2, 0.2), rules, cutoff = NULL)
  expect_true("poison" %in% attr(b, "templates")[[1]])
})

test_that("shape: quantile threshold on the available set, DTE band, block", {
  A <- c(0.01, 0.30, 0.02, 0.20, 0.03, 0.50)
  lib <- ec_quiet_library(make_nodes(A, dte = c(4, 4, 11, 4, 4, 4)))
  tgt <- as.Date("2024-08-05")
  r <- ec_quiet_rules(0.5, aggregation = "all")
  s <- ec_quiet_shape(lib, tgt, tgt + 4, 0.5, k = 0.1, r)
  expect_equal(s$threshold, stats::median(A))
  expect_setequal(attr(s, "templates")[[1]], c("s01", "s03", "s05"))
  expect_equal(s$shape, ord_shape(0.1))
  rd <- ec_quiet_rules(0.5, dte_band = 1, aggregation = "all")
  sd <- ec_quiet_shape(lib, tgt, tgt + 4, 0.5, k = 0.1, rd)
  expect_setequal(attr(sd, "templates")[[1]], c("s01", "s05"))
  sb <- ec_quiet_shape(lib, tgt, tgt + 4, 0.5, k = 0.1, r,
                       exclude_block = lib$block[lib$surface == "s01"])
  expect_false("s01" %in% attr(sb, "templates")[[1]])
  expect_equal(sb$threshold, stats::median(A[-1]))
})

test_that("shape: recent and ATM-nearest aggregation, median, coverage", {
  A <- rep(0.01, 6)
  atm <- c(0.40, 0.45, 0.50, 0.55, 0.60, 0.65)
  nd <- make_nodes(A, atm = atm)
  # give each template a distinct level shift in its wing so the median is visible
  nd$iv <- nd$iv + ifelse(abs(nd$k) > 0, 0.01 * nd$i, 0)
  lib <- ec_quiet_library(nd)
  tgt <- as.Date("2024-08-05")
  rr <- ec_quiet_rules(1, aggregation = c("recent2", "atm3", "all"))
  s <- ec_quiet_shape(lib, tgt, tgt + 4, 0.52, k = c(0.1, 0.9), rr)
  tp <- attr(s, "templates")
  expect_equal(tp[[1]], c("s06", "s05"))
  expect_setequal(tp[[2]], c("s03", "s04", "s02"))
  rec <- s[s$rule == rr$rule[1] & s$k == 0.1, ]
  expect_equal(rec$shape, ord_shape(0.1) + 0.01 * stats::median(c(5, 6)))
  all1 <- s[s$rule == rr$rule[3] & s$k == 0.1, ]
  expect_equal(all1$shape, ord_shape(0.1) + 0.01 * stats::median(1:6))
  # outside the templates' moneyness range: no prediction
  expect_true(all(is.na(s$shape[s$k == 0.9])))
  expect_true(all(s$n_templates[s$k == 0.9] == 0))
  # atm rules need the target ATM level
  s_na <- ec_quiet_shape(lib, tgt, tgt + 4, NA_real_, k = 0.1, rr)
  expect_true(is.na(s_na$shape[s_na$rule == rr$rule[2]]))
})

test_that("selection picks the quiet rule and never uses later templates", {
  A <- c(0.01, 0.30, 0.02, 0.20, 0.01, 0.50, 0.03, 0.02, 0.40, 0.01,
         0.25, 0.02, 0.01, 0.35, 0.03, 0.02, 0.45, 0.01, 0.02, 0.30)
  lib <- ec_quiet_library(make_nodes(A))
  rules <- ec_quiet_rules(c(0.25, 1), aggregation = c("all", "recent2"))
  sel <- ec_quiet_select(lib, rules, pseudo_quiet = 0.02)
  expect_s3_class(sel, "ec_quiet_select")
  expect_equal(nrow(sel$scores), 4)
  # strict quiet rules reproduce the ordinary smile exactly
  expect_equal(sel$best$rmse, 0, tolerance = 1e-12)
  expect_equal(sel$best$quiet, 0.25)
  expect_gt(max(sel$scores$rmse), 0.001)
  # every rule scored on the same nodes
  expect_equal(length(unique(sel$scores$n_nodes)), 1)
  # no template used for a pseudo-target expired after its own date
  for (p in unique(sel$detail$surface)) {
    pd <- lib$date[lib$surface == p]
    sh <- ec_quiet_shape(lib, pd, pd + 4, 0.5, 0.1, rules, cutoff = pd)
    used <- unlist(attr(sh, "templates"))
    expect_true(all(lib$expiry[match(used, lib$surface)] <= pd))
  }
})

test_that("selection: block holdout variant, ties, and target shapes", {
  A <- c(0.01, 0.30, 0.02, 0.20, 0.01, 0.50, 0.03, 0.02)
  lib <- ec_quiet_library(make_nodes(A))
  rules <- ec_quiet_rules(c(0.04, 0.06), "absolute", aggregation = "all")
  sel <- ec_quiet_select(lib, rules, pseudo_quiet = 0.02, available_only = FALSE,
                         target = list(date = as.Date("2024-08-05"),
                                       expiry = as.Date("2024-08-09"),
                                       atm_iv = 0.55, k = c(-0.1, 0.1)))
  # both thresholds select the same templates: a tie broken by the stricter one
  expect_equal(sel$scores$rmse[1], sel$scores$rmse[2])
  expect_equal(sel$best$quiet, 0.04)
  ts <- sel$target_shapes
  expect_equal(nrow(ts), 4)
  expect_equal(sum(ts$selected), 2)
  expect_equal(ts$iv_pred[ts$selected], 0.55 + ord_shape(c(-0.1, 0.1)), tolerance = 1e-12)
  # with available_only, the earliest pseudo-target has no templates and drops out
  sel2 <- ec_quiet_select(lib, rules, pseudo_quiet = 0.02)
  expect_lt(sel2$best$n_targets, sel$best$n_targets)
  expect_output(print(sel), "Selected: A<=0.04")
})

test_that("selection: cutoff restricts the library, errors are informative", {
  A <- c(0.01, 0.30, 0.02, 0.20, 0.01, 0.50, 0.03, 0.02)
  lib <- ec_quiet_library(make_nodes(A))
  rules <- ec_quiet_rules(0.5, aggregation = "all")
  sel <- ec_quiet_select(lib, rules, cutoff = as.Date("2024-07-01"),
                         available_only = FALSE)
  expect_true(all(lib$expiry[lib$surface %in% sel$pseudo] <= as.Date("2024-07-01")))
  expect_error(ec_quiet_select(lib, rules, pseudo = "nope"), "No pseudo-targets")
  expect_error(ec_quiet_shape(data.frame(), as.Date("2024-01-01"), as.Date("2024-01-05"),
                              0.5, 0.1), "ec_quiet_library")
  expect_error(ec_quiet_select(lib, data.frame(x = 1)), "ec_quiet_rules")
})

test_that("ratio shapes measure errors in volatility units", {
  A <- c(0.01, 0.30, 0.02, 0.20, 0.01, 0.50, 0.03, 0.02)
  nd <- make_nodes(A)
  lib_d <- ec_quiet_library(nd)
  lib_r <- ec_quiet_library(nd, shape = "ratio")
  rules <- ec_quiet_rules(1, aggregation = "all")
  sd <- ec_quiet_select(lib_d, rules, pseudo_quiet = 0.02, available_only = FALSE)
  sr <- ec_quiet_select(lib_r, rules, pseudo_quiet = 0.02, available_only = FALSE)
  # all surfaces share the ATM level 0.5, so both shape types agree
  expect_equal(sr$best$rmse, sd$best$rmse, tolerance = 1e-10)
})

test_that("pseudo_min_dte filters pseudo-targets only, not templates", {
  A <- c(0.01, 0.30, 0.02, 0.20, 0.01, 0.50, 0.03, 0.02, 0.01, 0.02)
  dte <- c(2, 4, 4, 2, 4, 4, 2, 4, 2, 4)
  lib <- ec_quiet_library(make_nodes(A, dte = dte))
  rules <- ec_quiet_rules(c(0.04, 0.06), "absolute", aggregation = "all")
  sel <- ec_quiet_select(lib, rules, pseudo_quiet = 0.02, pseudo_min_dte = 3)
  ids <- lib$surface[lib$A <= 0.02 & lib$dte >= 3]
  expect_setequal(sel$pseudo, ids)
  expect_false(any(c("s01", "s09") %in% sel$pseudo))
  expect_equal(sel$settings$pseudo_min_dte, 3)
  # same as handing over the filtered identifiers
  manual <- ec_quiet_select(lib, rules, pseudo = ids)
  expect_equal(sel$scores, manual$scores)
  expect_equal(sel$detail, manual$detail)
  # s03's only quiet template available on its date is s01 (2 days to expiry)
  scored <- unique(sel$detail$surface[is.finite(sel$detail$error)])
  expect_true("s03" %in% scored)
  # filter also applies to explicit identifiers
  sel_id <- ec_quiet_select(lib, rules, pseudo = c("s01", "s03"), pseudo_min_dte = 3)
  expect_equal(sel_id$pseudo, "s03")
  expect_error(ec_quiet_select(lib, rules, pseudo_min_dte = 10), "No pseudo-targets")
  expect_error(ec_quiet_select(lib, rules, pseudo_min_dte = -1), "non-negative")
  expect_error(ec_quiet_select(lib, rules, pseudo_min_dte = c(1, 2)), "non-negative")
})

test_that("standardized moneyness lines up maturities and volatility levels", {
  # smile shape identical in z = k / (atm * sqrt(tau)): shape = 0.01 * z^2
  mk <- function(id, date, dte, atm, A) {
    tau <- dte / 365
    z <- seq(-3, 3, by = 0.05)
    k <- z * atm * sqrt(tau)
    data.frame(surface = id, date = date, expiry = date + dte, k = k,
               iv = atm + 0.01 * z^2, A = A, tau = tau)
  }
  nd <- rbind(mk("a", as.Date("2024-01-01"), 7, 0.15, 0.01),
              mk("b", as.Date("2024-01-08"), 14, 0.20, 0.01),
              mk("c", as.Date("2024-01-15"), 21, 0.12, 0.01))
  lib_z <- ec_quiet_library(nd, moneyness = "standardized")
  lib_k <- ec_quiet_library(nd)
  expect_equal(lib_z$tau, c(7, 14, 21) / 365)
  expect_equal(lib_z$nodes[[2]]$z, seq(-3, 3, by = 0.05))
  tgt <- as.Date("2024-03-01")
  kk <- c(-0.02, 0.01, 0.03)
  r <- ec_quiet_rules(1, aggregation = "all")
  pz <- ec_quiet_shape(lib_z, tgt, tgt + 60, 0.18, kk, r)
  z_t <- kk / (0.18 * sqrt(60 / 365))
  expect_equal(pz$z, z_t)
  expect_equal(pz$shape, 0.01 * z_t^2, tolerance = 1e-2)
  pk <- ec_quiet_shape(lib_k, tgt, tgt + 60, 0.18, kk, r)
  expect_gt(max(abs(pk$shape - 0.01 * z_t^2), na.rm = TRUE), 0.005)
  # selection uses a standard-deviation wing by default
  sel <- ec_quiet_select(lib_z, r, available_only = FALSE)
  expect_equal(sel$settings$wing, c(0.5, 3))
  expect_lt(sel$best$rmse, 0.002)
  expect_true(all(abs(sel$detail$z) >= 0.5 - 1e-9))
})

test_that("CME surfaces feed the library directly", {
  nd <- make_nodes(c(0.01, 0.02))
  nd$tau <- 4 / 365
  nd$valuation <- as.POSIXct(paste(nd$date, "14:00"), tz = "America/Chicago")
  lib <- ec_quiet_library(nd)
  expect_equal(nrow(lib), 2)
})
