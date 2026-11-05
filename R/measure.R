# ---------------------------------------------------------------------------
# Measurement layer: kernel dispatch, staggered time grids, real-time
# forecasts with rule selection, and multi-venue clocks.
# ---------------------------------------------------------------------------

apply_kernel <- function(dL, method, trunc_sd = 3, scale_fn = stats::mad) {
  if (length(dL) == 0) return(NA_real_)
  switch(method,
    rv        = kernel_rv(dL),
    truncated = kernel_truncated(dL, trunc_sd = trunc_sd, scale_fn = scale_fn),
    bipower   = kernel_bipower(dL),
    largest1  = kernel_drop_largest(dL, 1),
    largest2  = kernel_drop_largest(dL, 2),
    cli::cli_abort("Unknown estimator {.val {method}}.")
  )
}

# Time on a common numeric scale in days (Date: days; POSIXct: seconds/86400).
time_days <- function(t) {
  if (inherits(t, "POSIXct")) as.numeric(t) / 86400 else as.numeric(t)
}

# Previous-tick sampling: value of the last observation at or before each
# grid point (NA before the first observation). `time` sorted ascending.
prev_tick <- function(time, value, grid) {
  # tolerance (~0.1 ms in days) so a grid point that floating-point
  # arithmetic places just before an observation still picks it up
  i <- findInterval(grid + 1e-9, time)
  out <- rep(NA_real_, length(grid))
  out[i > 0] <- value[i[i > 0]]
  out
}

# Staggered estimates on a window: one sampling grid of spacing `step`
# (days) per offset; kernels applied per grid, then averaged over offsets.
staggered_core <- function(td, L, lo, hi, step, offset_step, methods,
                           trunc_sd, scale_fn, max_offsets) {
  offset_step <- max(offset_step, step / max_offsets)
  offsets <- seq(0, step, by = offset_step)
  offsets <- offsets[offsets < step - 1e-12]
  per <- lapply(offsets, function(o) {
    grid <- seq(lo + o, hi + 1e-9, by = step)
    v <- prev_tick(td, L, grid)
    v <- v[!is.na(v)]
    dL <- if (length(v) >= 2) diff(v) else numeric(0)
    list(
      A = vapply(methods, function(m) apply_kernel(dL, m, trunc_sd, scale_fn),
                 numeric(1)),
      n = length(dL)
    )
  })
  Amat <- matrix(vapply(per, function(p) p$A, numeric(length(methods))),
                 nrow = length(methods))
  list(
    A = rowMeans(Amat, na.rm = TRUE),
    A_min = apply(Amat, 1, function(r) suppressWarnings(min(r, na.rm = TRUE))),
    A_max = apply(Amat, 1, function(r) suppressWarnings(max(r, na.rm = TRUE))),
    n_incr = mean(vapply(per, function(p) p$n, numeric(1))),
    n_offsets = length(offsets)
  )
}

# Sorted, clipped log odds of the non-missing observations of x.
clean_logit <- function(x, clip) {
  d <- x[!is.na(x$q), , drop = FALSE]
  d <- d[order(d$time), , drop = FALSE]
  list(time = d$time, td = time_days(d$time), L = ec_logit(clip_q(d$q, clip)))
}

#' Event Clock on staggered time grids
#'
#' With intraday prices, the measured clock depends on how often you
#' sample: very fine sampling picks up bid-ask bounce and stale quotes,
#' coarse sampling throws information away. A *staggered* grid estimate
#' samples the price every `interval` minutes (the last price at or
#' before each grid point) and repeats this for every possible starting
#' offset of the grid; the estimator is applied to each grid separately
#' and the results are averaged. This uses all the data while keeping the
#' chosen sampling frequency — the construction behind the working
#' paper's 30-, 60-, and 120-minute clocks.
#'
#' @details
#' Each method is applied *within* each offset grid before averaging, so
#' `largest1` removes the largest move of every grid separately and
#' `bipower` uses neighbors on the same grid — matching the paper's
#' "largest-move exclusion in each staggered grid". Grid offsets run in
#' steps of `offset_step` minutes (default: the data's median spacing),
#' capped at `max_offsets` grids. Choose an `interval` no finer than the
#' data's own spacing; otherwise repeated prices create zero increments.
#' For daily data use `sample_every` in [event_clock()] or
#' [ec_signature()] instead.
#'
#' @inheritParams event_clock
#' @param interval Sampling interval in minutes (default 60).
#' @param offset_step Spacing of the grid offsets in minutes (default:
#'   the median spacing of the observations).
#' @param max_offsets Maximum number of offset grids (default 60).
#'
#' @return A tibble with one row per horizon and method: `market_id`,
#'   `from`, `to`, `horizon`, `interval_min`, `n_offsets`, `n_incr`
#'   (average increments per grid), `method`, `A` (average over grids),
#'   and `A_min`, `A_max` (range over grids).
#'
#' @examples
#' data(polymarket2024)
#' ep <- as_event_prices(polymarket2024)
#' event_clock_staggered(ep, interval = 120, methods = c("rv", "largest1"))
#' @seealso [ec_signature()] for the full sampling-frequency profile.
#' @export
event_clock_staggered <- function(x, from = NULL, to = NULL, interval = 60,
                                  methods = "rv", offset_step = NULL,
                                  max_offsets = 60,
                                  trunc_sd = ec_default_params()$trunc_sd,
                                  scale_fn = stats::mad, clip = NULL) {
  x <- as_event_prices(x)
  if (!inherits(x$time, "POSIXct")) {
    cli::cli_abort(c(
      "{.fn event_clock_staggered} needs intraday {.cls POSIXct} timestamps.",
      i = "For daily data use {.arg sample_every} in {.fn event_clock}."
    ))
  }
  methods <- match.arg(methods, ec_default_params()$methods, several.ok = TRUE)
  stopifnot(is.numeric(interval), length(interval) == 1, interval > 0)
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  cl <- clean_logit(x, clip)
  if (length(cl$td) < 2) cli::cli_abort("Need at least 2 non-missing observations.")

  from <- from %||% min(x$time)
  to <- to %||% max(x$time)
  labels <- names(to) %||% format(to)
  labels[labels == ""] <- format(to)[labels == ""]
  base_min <- stats::median(diff(cl$td)) * 1440
  offset_step <- offset_step %||% base_min
  stopifnot(offset_step > 0)

  rows <- lapply(seq_along(to), function(i) {
    lo <- time_days(align_bound(from, x$time, "start"))
    hi <- time_days(align_bound(to[i], x$time, "end"))
    keep <- cl$td >= lo & cl$td <= hi
    if (sum(keep) < 2) {
      res <- list(A = rep(NA_real_, length(methods)),
                  A_min = rep(NA_real_, length(methods)),
                  A_max = rep(NA_real_, length(methods)),
                  n_incr = 0, n_offsets = 0L)
    } else {
      res <- staggered_core(cl$td[keep], cl$L[keep], lo, hi,
                            step = interval / 1440,
                            offset_step = offset_step / 1440,
                            methods = methods, trunc_sd = trunc_sd,
                            scale_fn = scale_fn, max_offsets = max_offsets)
    }
    tibble::tibble(
      market_id = attr(x, "market_id") %||% NA_character_,
      from = from, to = to[i], horizon = labels[i],
      interval_min = interval, n_offsets = res$n_offsets,
      n_incr = res$n_incr, method = methods,
      A = unname(res$A), A_min = unname(res$A_min), A_max = unname(res$A_max)
    )
  })
  dplyr::bind_rows(rows)
}

# Core real-time forecast on cleaned series (td in days, L log odds):
# clock rate per day from the estimation window ending at `at_d`, times
# the horizon in days.
forecast_core <- function(td, L, at_d, h_days, type, window, method,
                          step, offset_step, trunc_sd, scale_fn) {
  na_out <- list(A_forecast = rep(NA_real_, length(h_days)), rate = NA_real_,
                 n_incr = 0L, idx = integer(0))
  upto <- which(td <= at_d + 1e-9)
  if (length(upto) < 2) return(na_out)
  idx <- switch(type,
    obs = utils::tail(upto, window),
    days = upto[td[upto] >= at_d - window - 1e-9],
    expanding = upto
  )
  if (length(idx) < 2) return(na_out)
  lo <- if (type == "days") at_d - window else td[idx[1]]
  span <- if (type == "days") window else td[idx[length(idx)]] - td[idx[1]]
  if (!is.finite(span) || span <= 0) return(na_out)
  if (is.null(step)) {
    est <- apply_kernel(diff(L[idx]), method, trunc_sd, scale_fn)
    n_incr <- length(idx) - 1L
  } else {
    sg <- staggered_core(td[idx], L[idx], lo, at_d, step, offset_step,
                         method, trunc_sd, scale_fn, max_offsets = 60)
    est <- sg$A[[1]]
    n_incr <- as.integer(round(sg$n_incr))
  }
  list(A_forecast = est / span * h_days, rate = est / span,
       n_incr = n_incr, idx = idx)
}

rule_label <- function(type, window, method) {
  w <- switch(type,
    obs = paste("trailing", window, "obs"),
    days = paste("trailing", window, "days"),
    expanding = "expanding"
  )
  paste0(w, " / ", method)
}

#' Real-time Event Clock forecast
#'
#' Before an option expires we do not yet know how much information will
#' arrive while it is alive. A real-time forecast uses only prices
#' observed up to the valuation time `at`: it measures the recent speed of
#' the clock (log-odds variation per calendar day over an estimation
#' window) and multiplies it by the remaining horizon,
#' \deqn{\widehat A^{rt}(h) = \frac{\widehat A(\text{window})}
#'   {\text{window length in days}} \times h.}
#'
#' @details
#' Three kinds of estimation window are available. By default the window
#' is the last `trailing` observations and its length is their calendar
#' span. With `days`, the window is the last `days` calendar days before
#' `at` (e.g. `days = 3` with hourly data); with `expanding = TRUE` it is
#' the whole history up to `at`. Any estimator of [event_clock()] can
#' measure the window (`method`), and with intraday data `interval` turns
#' on staggered grid sampling as in [event_clock_staggered()].
#'
#' Which window works best is an empirical question. Choose it the way the
#' accompanying working paper does — by forecast accuracy on earlier
#' option lives only, never on the options being tested — with
#' [ec_forecast_select()].
#'
#' @inheritParams event_clock
#' @param at Valuation date/time at which the forecast is made (default:
#'   last observation). Only observations at or before `at` are used.
#' @param horizon Forecast horizon(s): either numeric (days) or
#'   `Date`/`POSIXct` horizon dates (converted to days from `at`;
#'   `POSIXct` horizons give fractional days). Names are used as labels.
#' @param trailing Integer, number of trailing observations in the
#'   estimation window (default 40). Ignored when `days` or `expanding` is
#'   set.
#' @param days Numeric, length of a trailing calendar-day window.
#' @param expanding Logical; use all observations up to `at`.
#' @param method Estimator for the window (default `"rv"`; see
#'   [event_clock()]).
#' @param interval Optional sampling interval in minutes for staggered
#'   grid sampling of intraday data.
#'
#' @return A tibble with columns `market_id`, `at`, `horizon`,
#'   `horizon_days`, `rule` (window and estimator), `trailing` (window
#'   size for observation windows, else `NA`), `method`, `n_incr`,
#'   `n_gaps`, `max_gap_days`, `rate_per_day`, and `A_forecast`. See
#'   [event_clock()] for the gap diagnostics.
#'
#' @examples
#' data(us2016)
#' ep <- as_event_prices(us2016, time = "date", price = "trump")
#' # trailing 60 increments, as selected for this series in the paper
#' event_clock_forecast(ep, at = as.Date("2016-10-10"),
#'                      horizon = c(`1W` = 7, `2W` = 14), trailing = 61)
#'
#' # hourly data: clock speed over the last three days
#' data(polymarket2024)
#' event_clock_forecast(as_event_prices(polymarket2024),
#'   at = as.POSIXct("2024-10-25 19:45", tz = "UTC"),
#'   horizon = as.POSIXct("2024-11-01 19:45", tz = "UTC"), days = 3)
#' @seealso [ec_forecast_select()] to choose the window by forecast
#'   accuracy; [ec_recovery_set()] for the low-clock sensitivity.
#' @export
event_clock_forecast <- function(x, at = NULL, horizon,
                                 trailing = ec_default_params()$trailing,
                                 days = NULL, expanding = FALSE,
                                 method = "rv", interval = NULL,
                                 sample_every = ec_default_params()$sample_every,
                                 trunc_sd = ec_default_params()$trunc_sd,
                                 scale_fn = stats::mad,
                                 clip = NULL) {
  x <- as_event_prices(x)
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  method <- match.arg(method, ec_default_params()$methods)
  at <- at %||% max(x$time)
  if (!is.null(interval) && !inherits(x$time, "POSIXct")) {
    cli::cli_abort("{.arg interval} needs intraday {.cls POSIXct} timestamps.")
  }

  d <- window_rows(x, min(x$time), at)
  if (nrow(d) < 2) {
    cli::cli_abort("Need at least 2 non-missing observations up to {.val {format(at)}}.")
  }
  if (sample_every > 1) {
    d <- d[seq(1L, nrow(d), by = as.integer(sample_every)), , drop = FALSE]
  }
  d <- d[order(d$time), , drop = FALSE]
  td <- time_days(d$time)
  L <- ec_logit(clip_q(d$q, clip))
  at_d <- time_days(align_bound(at, x$time, "start"))

  type <- if (isTRUE(expanding)) "expanding" else if (!is.null(days)) "days" else "obs"
  window <- switch(type, obs = as.integer(trailing), days = days, expanding = NA)
  if (type == "days") stopifnot(is.numeric(days), length(days) == 1, days > 0)

  if (inherits(horizon, c("Date", "POSIXct"))) {
    h_days <- time_days(align_bound(horizon, x$time, "start")) - at_d
    labels <- names(horizon) %||% format(horizon)
  } else {
    h_days <- as.numeric(horizon)
    labels <- names(horizon) %||% paste0(h_days, "d")
  }
  labels[labels == ""] <- paste0(h_days, "d")[labels == ""]
  if (any(h_days <= 0)) {
    cli::cli_abort("{.arg horizon} must lie strictly after {.arg at}.")
  }

  fc <- forecast_core(td, L, at_d, h_days, type, window, method,
                      step = if (is.null(interval)) NULL else interval / 1440,
                      offset_step = if (is.null(interval)) NULL else
                        stats::median(diff(td)),
                      trunc_sd = trunc_sd, scale_fn = scale_fn)
  if (length(fc$idx) < 2 || !is.finite(fc$rate)) {
    cli::cli_abort("Estimation window has fewer than 2 observations or zero calendar span.")
  }
  g <- gap_stats(d$time[fc$idx])

  tibble::tibble(
    market_id = attr(x, "market_id") %||% NA_character_,
    at = at, horizon = labels, horizon_days = h_days,
    rule = rule_label(type, window, method),
    trailing = if (type == "obs") as.integer(window) else NA_integer_,
    method = method, n_incr = as.integer(fc$n_incr),
    n_gaps = g$n_gaps, max_gap_days = g$max_gap_days,
    rate_per_day = fc$rate, A_forecast = fc$A_forecast
  )
}

#' Candidate rules for real-time clock forecasts
#'
#' Builds the grid of forecasting rules compared by
#' [ec_forecast_select()]: trailing windows measured in observations or in
#' calendar days, optionally the expanding (all-history) window, crossed
#' with the estimators to compare.
#'
#' @param obs Integer vector of trailing-observation window sizes.
#' @param days Numeric vector of trailing calendar-day window lengths.
#' @param expanding Logical; include the expanding window.
#' @param methods Estimators to cross with the windows (see
#'   [event_clock()]).
#' @return A tibble with columns `rule`, `type`, `window`, `method`.
#' @examples
#' # the working paper's grid for hourly prediction-market data
#' ec_forecast_rules(days = c(3, 5, 7, 10, 14, 20), expanding = TRUE)
#' # its grid for daily data
#' ec_forecast_rules(obs = c(20, 40, 60),
#'                   methods = c("rv", "truncated", "bipower"))
#' @export
ec_forecast_rules <- function(obs = NULL, days = NULL, expanding = FALSE,
                              methods = "rv") {
  methods <- match.arg(methods, ec_default_params()$methods, several.ok = TRUE)
  win <- rbind(
    if (length(obs)) data.frame(type = "obs", window = as.numeric(obs)),
    if (length(days)) data.frame(type = "days", window = as.numeric(days)),
    if (isTRUE(expanding)) data.frame(type = "expanding", window = NA_real_)
  )
  if (is.null(win) || nrow(win) == 0) {
    cli::cli_abort("Specify at least one of {.arg obs}, {.arg days}, or {.arg expanding}.")
  }
  g <- merge(win, data.frame(method = methods), by = NULL)
  out <- tibble::tibble(
    rule = rule_label_vec(g$type, g$window, g$method),
    type = g$type, window = g$window, method = g$method
  )
  out[!duplicated(out$rule), ]
}

rule_label_vec <- function(type, window, method) {
  vapply(seq_along(type), function(i) {
    rule_label(type[i], window[i], method[i])
  }, character(1))
}

#' Choose the real-time forecasting rule by out-of-sample accuracy
#'
#' Compares candidate forecasting rules on a set of *earlier* option
#' lives: for each interval, every rule forecasts the clock from data
#' available at the interval's start, and the forecast is compared with
#' the clock that subsequently materialized over the interval. The rule
#' with the lowest root-mean-square error wins. Because the intervals end
#' before the options you want to study, the choice never looks at the
#' test sample — the no-look-ahead discipline of the accompanying working
#' paper.
#'
#' @param x An `event_prices` object (or coercible).
#' @param intervals A `data.frame` with columns `start` and `end`
#'   (valuation time and expiry of each earlier option life), of the same
#'   time type as `x` (or `Date` bounds for a `POSIXct` series).
#' @param rules Candidate rules from [ec_forecast_rules()].
#' @param realized_method Estimator for the realized clock over each
#'   interval (default `"rv"`).
#' @param interval Optional staggered sampling interval in minutes, used
#'   for both forecasts and realized clocks (intraday data only).
#' @param common Logical; if `TRUE` (default), score all rules on the
#'   intervals where every rule produces a forecast, so the comparison is
#'   like for like.
#' @inheritParams event_clock
#' @param ... Unused (for the `print` method).
#'
#' @return An object of class `ec_forecast_select`: a list with
#'   \item{scores}{tibble per rule: `rule`, `type`, `window`, `method`,
#'     `n` (intervals scored), `rmse`, `mae`, `bias` (mean forecast minus
#'     realized), sorted by `rmse`.}
#'   \item{best}{the winning row of `scores`.}
#'   \item{detail}{long tibble: interval, rule, forecast, realized.}
#'
#' @examples
#' data(us2016)
#' ep <- as_event_prices(us2016, time = "date", price = "trump")
#' # two-week option lives starting every day, all ending before Oct 10
#' starts <- seq(as.Date("2016-06-01"), as.Date("2016-09-25"), by = "day")
#' iv <- data.frame(start = starts, end = starts + 14)
#' sel <- ec_forecast_select(ep, iv,
#'   rules = ec_forecast_rules(obs = c(21, 41, 61)))
#' sel
#' @export
ec_forecast_select <- function(x, intervals,
                               rules = ec_forecast_rules(
                                 days = c(3, 5, 7, 10, 14, 20),
                                 expanding = TRUE),
                               realized_method = "rv", interval = NULL,
                               common = TRUE,
                               trunc_sd = ec_default_params()$trunc_sd,
                               scale_fn = stats::mad, clip = NULL) {
  x <- as_event_prices(x)
  stopifnot(is.data.frame(intervals), all(c("start", "end") %in% names(intervals)))
  stopifnot(is.data.frame(rules), all(c("rule", "type", "window", "method") %in% names(rules)))
  realized_method <- match.arg(realized_method, ec_default_params()$methods)
  if (!is.null(interval) && !inherits(x$time, "POSIXct")) {
    cli::cli_abort("{.arg interval} needs intraday {.cls POSIXct} timestamps.")
  }
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  cl <- clean_logit(x, clip)
  step <- if (is.null(interval)) NULL else interval / 1440
  ostep <- if (is.null(interval)) NULL else stats::median(diff(cl$td))

  s_d <- time_days(align_bound(intervals$start, x$time, "start"))
  e_d <- time_days(align_bound(intervals$end, x$time, "start"))
  if (any(e_d <= s_d)) cli::cli_abort("Every interval needs {.field end} after {.field start}.")

  realized <- vapply(seq_along(s_d), function(i) {
    keep <- cl$td >= s_d[i] - 1e-9 & cl$td <= e_d[i] + 1e-9
    if (sum(keep) < 2) return(NA_real_)
    if (is.null(step)) {
      apply_kernel(diff(cl$L[keep]), realized_method, trunc_sd, scale_fn)
    } else {
      staggered_core(cl$td[keep], cl$L[keep], s_d[i], e_d[i], step, ostep,
                     realized_method, trunc_sd, scale_fn, 60)$A[[1]]
    }
  }, numeric(1))

  detail <- lapply(seq_len(nrow(rules)), function(r) {
    fc <- vapply(seq_along(s_d), function(i) {
      forecast_core(cl$td, cl$L, s_d[i], e_d[i] - s_d[i], rules$type[r],
                    rules$window[r], rules$method[r], step, ostep,
                    trunc_sd, scale_fn)$A_forecast
    }, numeric(1))
    tibble::tibble(interval = seq_along(s_d), start = intervals$start,
                   end = intervals$end, rule = rules$rule[r],
                   forecast = fc, realized = realized)
  })
  detail <- dplyr::bind_rows(detail)

  ok <- is.finite(detail$forecast) & is.finite(detail$realized)
  if (common) {
    good <- tapply(ok, detail$interval, all)
    ok <- ok & detail$interval %in% as.integer(names(good)[good])
  }
  if (!any(ok)) cli::cli_abort("No interval could be scored; check the history before each start.")
  sc <- detail[ok, , drop = FALSE] |>
    dplyr::group_by(rule) |>
    dplyr::summarise(
      n = dplyr::n(),
      rmse = sqrt(mean((forecast - realized)^2)),
      mae = mean(abs(forecast - realized)),
      bias = mean(forecast - realized),
      .groups = "drop"
    )
  sc <- dplyr::left_join(rules, sc, by = "rule")
  sc <- sc[order(sc$rmse), , drop = FALSE]
  out <- list(scores = sc, best = sc[1, , drop = FALSE], detail = detail)
  class(out) <- "ec_forecast_select"
  out
}

#' @describeIn ec_forecast_select Print method.
#' @export
print.ec_forecast_select <- function(x, ...) {
  cat("-- Real-time clock forecast selection (", x$best$n,
      " option lives scored)\n", sep = "")
  cat("Best rule: ", x$best$rule, sprintf(" (RMSE %.4g)\n", x$best$rmse),
      sep = "")
  print(x$scores[, c("rule", "n", "rmse", "mae", "bias")], n = Inf)
  invisible(x)
}

#' Event Clocks from two venues: separating common news from venue noise
#'
#' When the same event trades on two venues (say Polymarket and Kalshi),
#' each venue's measured clock contains the common information flow plus
#' venue-specific noise (bid-ask bounce, stale quotes, idiosyncratic
#' flows). Comparing four clocks built from synchronized prices
#' separates the two:
#' \describe{
#'   \item{`A_x`, `A_y`}{each venue's own clock, \eqn{\sum (\Delta L)^2}.}
#'   \item{`A_composite`}{the clock of the equal-weight average of the two
#'     venues' log odds.}
#'   \item{`A_cross`}{the cross-venue clock
#'     \eqn{\sum \Delta L^x \Delta L^y}: news moves both venues, so it
#'     survives the product; independent venue noise does not, so on
#'     average it drops out.}
#' }
#'
#' @details
#' Under a simple benchmark in which each venue's log odds are the common
#' latent log odds plus independent noise, \eqn{E[A_x] = A + N_x} while
#' \eqn{E[A_{cross}] = A}. The reported `noise_share_x`
#' \eqn{= 1 - A_{cross}/A_x} is then the fraction of venue x's measured
#' clock attributable to its own noise. In finite samples `A_cross` can
#' fall below zero when there is little common news; it is a diagnostic,
#' not an exact measurement. The identity
#' \eqn{A_{composite} = (A_x + A_y + 2A_{cross})/4} holds exactly.
#'
#' Multiple venues help diagnose timing and filter venue-specific noise,
#' but they cannot by themselves pin down the absolute physical clock
#' scale; that still rests on the recovery restriction (see
#' [ec_recovery_set()]).
#'
#' Prices are matched on identical timestamps. Synchronize intraday series
#' first, e.g. with a common daily snapshot:
#' `pm_daily(x, snapshot_hour = 15.75)` takes the last price at or before
#' 15:45 New York time.
#'
#' @param x,y `event_prices` objects (or coercible) for the same event
#'   outcome on two venues.
#' @inheritParams event_clock
#' @param labels Optional venue labels (default: the `market_id`s).
#'
#' @return A tibble with one row per horizon: `venue_x`, `venue_y`,
#'   `from`, `to`, `horizon`, `n_common` (synchronized observations),
#'   `A_x`, `A_y`, `A_composite`, `A_cross`, `corr` (correlation of the two
#'   venues' log-odds changes), `noise_share_x`, `noise_share_y`.
#'
#' @references Hanke, Schadner, Stöckl, and Weissensteiner (Working
#'   Paper), "The Event Clock: What State Prices Identify About Physical
#'   Information".
#' @examples
#' # two noisy venues observing the same simulated news
#' set.seed(7)
#' p <- ec_simulate_path(1, 120, q = 0.5, A = 1)
#' days <- as.Date("2024-06-01") + 0:120
#' noisy <- function(sd) data.frame(time = days,
#'   q = ec_ilogit(p$L + stats::rnorm(121, sd = sd)))
#' event_clock_venues(noisy(0.05), noisy(0.10), labels = c("A", "B"))
#' @seealso [event_clock_venues_path()] for the cumulative clocks.
#' @export
event_clock_venues <- function(x, y, from = NULL, to = NULL, labels = NULL,
                               clip = NULL) {
  m <- venue_merge(x, y, labels, clip)
  from <- from %||% min(m$time)
  to <- to %||% max(m$time)
  hl <- names(to) %||% format(to)
  hl[hl == ""] <- format(to)[hl == ""]

  rows <- lapply(seq_along(to), function(i) {
    lo <- align_bound(from, m$time, "start")
    hi <- align_bound(to[i], m$time, "end")
    w <- m[m$time >= lo & m$time <= hi, , drop = FALSE]
    if (nrow(w) < 3) {
      cli::cli_abort("Fewer than 3 synchronized observations in window {.val {hl[i]}}.")
    }
    dx <- diff(w$Lx); dy <- diff(w$Ly); dc <- (dx + dy) / 2
    Ax <- sum(dx^2); Ay <- sum(dy^2); Ac <- sum(dx * dy)
    tibble::tibble(
      venue_x = attr(m, "labels")[1], venue_y = attr(m, "labels")[2],
      from = from, to = to[i], horizon = hl[i], n_common = nrow(w),
      A_x = Ax, A_y = Ay, A_composite = sum(dc^2), A_cross = Ac,
      corr = if (stats::sd(dx) > 0 && stats::sd(dy) > 0) stats::cor(dx, dy) else NA_real_,
      noise_share_x = if (Ax > 0) 1 - Ac / Ax else NA_real_,
      noise_share_y = if (Ay > 0) 1 - Ac / Ay else NA_real_
    )
  })
  dplyr::bind_rows(rows)
}

#' Cumulative Event Clocks from two venues
#'
#' The running versions of the four clocks of [event_clock_venues()] —
#' each venue's own clock, the composite clock, and the cross-venue clock
#' — for plotting how much common news versus venue noise accumulated
#' over time.
#'
#' @inheritParams event_clock_venues
#' @param ... Unused (for the `plot` method).
#' @return A tibble of class `event_clock_venues_path` with columns
#'   `time`, `q_x`, `q_y`, `A_x`, `A_y`, `A_composite`, `A_cross`; venue
#'   labels are stored in the `labels` attribute.
#' @examples
#' set.seed(7)
#' p <- ec_simulate_path(1, 120, q = 0.5, A = 1)
#' days <- as.Date("2024-06-01") + 0:120
#' noisy <- function(sd) data.frame(time = days,
#'   q = ec_ilogit(p$L + stats::rnorm(121, sd = sd)))
#' path <- event_clock_venues_path(noisy(0.05), noisy(0.10),
#'                                 labels = c("A", "B"))
#' plot(path)
#' @export
event_clock_venues_path <- function(x, y, from = NULL, to = NULL,
                                    labels = NULL, clip = NULL) {
  m <- venue_merge(x, y, labels, clip)
  from <- from %||% min(m$time)
  to <- to %||% max(m$time)
  stopifnot(length(to) == 1)
  w <- m[m$time >= align_bound(from, m$time, "start") &
           m$time <= align_bound(to, m$time, "end"), , drop = FALSE]
  if (nrow(w) < 2) cli::cli_abort("Need at least 2 synchronized observations.")
  dx <- c(0, diff(w$Lx)); dy <- c(0, diff(w$Ly)); dc <- (dx + dy) / 2
  out <- tibble::tibble(
    time = w$time, q_x = w$qx, q_y = w$qy,
    A_x = cumsum(dx^2), A_y = cumsum(dy^2),
    A_composite = cumsum(dc^2), A_cross = cumsum(dx * dy)
  )
  attr(out, "labels") <- attr(m, "labels")
  class(out) <- c("event_clock_venues_path", class(tibble::tibble()))
  out
}

#' @describeIn event_clock_venues_path Plot method.
#' @export
plot.event_clock_venues_path <- function(x, ...) {
  lab <- attr(x, "labels") %||% c("x", "y")
  long <- rbind(
    data.frame(time = x$time, clock = lab[1], A = x$A_x),
    data.frame(time = x$time, clock = lab[2], A = x$A_y),
    data.frame(time = x$time, clock = "composite", A = x$A_composite),
    data.frame(time = x$time, clock = "cross-venue", A = x$A_cross)
  )
  long$clock <- factor(long$clock, levels = c(lab, "composite", "cross-venue"))
  ggplot2::ggplot(long, ggplot2::aes(x = time, y = A, color = clock)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::scale_color_manual(
      values = c("#e67e22", "#2980b9", "#7f8c8d", "#2c3e50"), name = NULL
    ) +
    ggplot2::labs(x = NULL, y = expression(hat(A)[t]),
                  subtitle = "Cumulative Event Clocks by venue") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")
}

# Synchronize two event_prices series on identical timestamps.
venue_merge <- function(x, y, labels, clip) {
  x <- as_event_prices(x)
  y <- as_event_prices(y)
  if (!identical(class(x$time)[1], class(y$time)[1])) {
    cli::cli_abort("{.arg x} and {.arg y} must have the same time type (both {.cls Date} or both {.cls POSIXct}).")
  }
  labels <- labels %||% c(attr(x, "market_id") %||% "x",
                          attr(y, "market_id") %||% "y")
  stopifnot(length(labels) == 2)
  cx <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  cy <- clip %||% attr(y, "clip") %||% ec_default_params()$clip
  a <- x[!is.na(x$q), c("time", "q")]
  b <- y[!is.na(y$q), c("time", "q")]
  names(a)[2] <- "qx"; names(b)[2] <- "qy"
  m <- dplyr::inner_join(a, b, by = "time")
  m <- m[order(m$time), , drop = FALSE]
  if (nrow(m) < 3) {
    cli::cli_abort(c(
      "Fewer than 3 identical timestamps across the two venues.",
      i = "Synchronize first, e.g. {.code pm_daily(x, snapshot_hour = 15.75)}."
    ))
  }
  m$Lx <- ec_logit(clip_q(m$qx, cx))
  m$Ly <- ec_logit(clip_q(m$qy, cy))
  attr(m, "labels") <- labels
  m
}
