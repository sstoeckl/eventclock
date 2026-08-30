# ---------------------------------------------------------------------------
# Estimator kernels (base R, operate on the vector of log-odds increments)
# ---------------------------------------------------------------------------

kernel_rv <- function(dL) sum(dL^2)

kernel_bipower <- function(dL) {
  n <- length(dL)
  if (n < 2) return(NA_real_)
  (pi / 2) * sum(abs(dL[-1]) * abs(dL[-n]))
}

kernel_truncated <- function(dL, trunc_sd = 3, scale_fn = stats::mad) {
  s <- scale_fn(dL)
  if (!is.finite(s) || s <= 0) return(kernel_rv(dL))
  sum(dL[abs(dL) <= trunc_sd * s]^2)
}

kernel_drop_largest <- function(dL, k = 1) {
  n <- length(dL)
  if (n <= k) return(NA_real_)
  o <- order(abs(dL), decreasing = TRUE)
  sum(dL[-o[seq_len(k)]]^2)
}

# Extract clipped log-odds increments from an event_prices window.
# Returns list(dL, n_obs) after NA removal and subsampling.
window_increments <- function(x, from, to, sample_every, clip) {
  keep <- x$time >= from & x$time <= to & !is.na(x$q)
  q <- x$q[keep]
  n_obs <- length(q)
  if (n_obs < 2) return(list(dL = numeric(0), n_obs = n_obs))
  idx <- seq(1L, n_obs, by = sample_every)
  L <- ec_logit(clip_q(q[idx], clip))
  list(dL = diff(L), n_obs = n_obs)
}

# ---------------------------------------------------------------------------
# User-facing estimator
# ---------------------------------------------------------------------------

#' Estimate event-clock (information) time from log-odds variation
#'
#' The information accumulated about a scheduled event over a window
#' \eqn{[t, T]} — *event-clock time* \eqn{A_{t,T}} — equals the quadratic
#' variation of the log-odds of the traded event probability,
#' \eqn{A_{t,T} = [\mathrm{logit}(q)]_{t,T}}. `event_clock()` estimates it
#' by the realized variation
#' \deqn{\widehat A_{t,T} = \sum_i \left[\mathrm{logit}(q_{t_{i+1}}) -
#'   \mathrm{logit}(q_{t_i})\right]^2}
#' together with standard robustness variants.
#'
#' @details
#' Because quadratic variation ignores finite-variation drift and is
#' invariant under equivalent measure changes, \eqn{\widehat A} is
#' *measure-robust*: it does not require a martingale assumption under the
#' physical measure, and any (approximately) constant level distortion of
#' `q` — discounting, a constant state-price tilt, a constant cross-market
#' wedge — drops out entirely.
#'
#' Available `methods`:
#' \describe{
#'   \item{`rv`}{plain realized variation (the baseline).}
#'   \item{`truncated`}{drops increments larger than `trunc_sd` robust
#'     standard deviations, where the robust scale is `scale_fn(dL)`
#'     ([stats::mad()] by default). Note that with daily data and short
#'     windows this criterion is coarse; reference results reported as
#'     "truncated" often coincide with dropping the single largest
#'     increment (`largest1`). Compare both.}
#'   \item{`bipower`}{bipower variation
#'     \eqn{BV = \frac{\pi}{2}\sum_{i\ge 2} |\Delta L_i||\Delta L_{i-1}|},
#'     a jump-robust companion; the gap \eqn{RV - BV} is a descriptive
#'     *jumpiness index*.}
#'   \item{`largest1`, `largest2`}{realized variation after removing the
#'     one or two largest absolute increments.}
#' }
#'
#' Windows are defined in calendar time from the valuation date `from` to
#' each horizon date in `to` (they are *anchored* windows, not trailing
#' ones). All observations in the window are used, including weekends if
#' the series has them.
#'
#' @param x An `event_prices` object (see [as_event_prices()]), or a
#'   `data.frame` coercible to one.
#' @param from Valuation date/time (default: first observation).
#' @param to One or more horizon dates/times (default: last observation =
#'   full sample). Names are used as horizon labels.
#' @param methods Character vector of estimator variants; see Details.
#' @param sample_every Integer, use every k-th observation (sparse-sampling
#'   robustness; default 1).
#' @param trunc_sd Numeric, truncation threshold in robust standard
#'   deviations (default 3).
#' @param scale_fn Function computing the robust scale of the increments
#'   for `truncated` (default [stats::mad()]).
#' @param clip Numeric length-2 clipping bounds for `q` before the
#'   log-odds transform; defaults to the bounds stored in `x`.
#'
#' @return A tibble with one row per horizon and method:
#'   \item{market_id}{market label (from `x`).}
#'   \item{from, to}{window bounds actually used.}
#'   \item{horizon}{horizon label (names of `to`, or the date).}
#'   \item{n_obs}{number of non-missing observations in the window.}
#'   \item{n_incr}{number of increments used (after subsampling).}
#'   \item{method}{estimator variant.}
#'   \item{A}{the estimate \eqn{\widehat A_{t,T}}.}
#'
#' @examples
#' data(brexit2016)
#' ep <- as_event_prices(brexit2016,
#'   time = "date", price = "q_leave",
#'   market_id = "Brexit: Leave", event_date = as.Date("2016-06-23")
#' )
#' # the working paper's 1M valuation date and 1W/2W/1M horizons
#' event_clock(ep,
#'   from = as.Date("2016-05-24"),
#'   to = c(`1W` = as.Date("2016-05-31"), `2W` = as.Date("2016-06-07"),
#'          `1M` = as.Date("2016-06-23"))
#' )
#' @seealso [event_clock_path()] for the cumulative clock,
#'   [event_clock_forecast()] for the real-time benchmark.
#' @export
event_clock <- function(x, from = NULL, to = NULL,
                        methods = ec_default_params()$methods,
                        sample_every = ec_default_params()$sample_every,
                        trunc_sd = ec_default_params()$trunc_sd,
                        scale_fn = stats::mad,
                        clip = NULL) {
  x <- as_event_prices(x)
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  methods <- match.arg(methods, ec_default_params()$methods, several.ok = TRUE)
  stopifnot(sample_every >= 1)
  sample_every <- as.integer(sample_every)

  from <- from %||% min(x$time)
  to <- to %||% max(x$time)
  labels <- names(to) %||% format(to)
  labels[labels == ""] <- format(to)[labels == ""]

  res <- lapply(seq_along(to), function(i) {
    w <- window_increments(x, from, to[i], sample_every, clip)
    A <- vapply(methods, function(m) {
      if (length(w$dL) == 0) return(NA_real_)
      switch(m,
        rv        = kernel_rv(w$dL),
        truncated = kernel_truncated(w$dL, trunc_sd = trunc_sd, scale_fn = scale_fn),
        bipower   = kernel_bipower(w$dL),
        largest1  = kernel_drop_largest(w$dL, 1),
        largest2  = kernel_drop_largest(w$dL, 2)
      )
    }, numeric(1))
    tibble::tibble(
      market_id = attr(x, "market_id") %||% NA_character_,
      from = from, to = to[i], horizon = labels[i],
      n_obs = w$n_obs, n_incr = length(w$dL),
      method = methods, A = unname(A)
    )
  })
  dplyr::bind_rows(res)
}

#' Cumulative event-clock path
#'
#' Computes the running (cumulative) event clock
#' \eqn{\widehat A_t = \sum_{s \le t} (\Delta L_s)^2} — the object behind
#' the "clock plot": how much of the eventual information had arrived by
#' each calendar date.
#'
#' @inheritParams event_clock
#' @param normalize Logical; if `TRUE` (default) also return `A_frac`, the
#'   clock normalized to \eqn{[0, 1]} over the window.
#' @param ... Unused (for the `plot` method).
#'
#' @return A tibble of class `event_clock_path` with columns `time`, `q`,
#'   `L` (clipped log-odds), `dL`, `dA` (squared increment), `A`
#'   (cumulative clock), and — with `normalize = TRUE` — `A_frac` and
#'   `cal_frac` (fraction of calendar time elapsed). Attributes carry the
#'   market id and event date.
#'
#' @examples
#' data(brexit2016)
#' ep <- as_event_prices(brexit2016, time = "date", price = "q_leave")
#' path <- event_clock_path(ep)
#' tail(path)
#' @export
event_clock_path <- function(x, from = NULL, to = NULL,
                             sample_every = ec_default_params()$sample_every,
                             clip = NULL, normalize = TRUE) {
  x <- as_event_prices(x)
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  from <- from %||% min(x$time)
  to <- to %||% max(x$time)
  stopifnot(length(to) == 1)

  keep <- x$time >= from & x$time <= to & !is.na(x$q)
  d <- x[keep, , drop = FALSE]
  if (nrow(d) < 2) {
    cli::cli_abort("Need at least 2 non-missing observations in the window.")
  }
  idx <- seq(1L, nrow(d), by = as.integer(sample_every))
  d <- d[idx, , drop = FALSE]

  L <- ec_logit(clip_q(d$q, clip))
  dL <- c(NA_real_, diff(L))
  dA <- dL^2
  A <- cumsum(dplyr::coalesce(dA, 0))

  out <- tibble::tibble(time = d$time, q = d$q, L = L, dL = dL, dA = dA, A = A)
  if (normalize) {
    total <- A[length(A)]
    out$A_frac <- if (total > 0) A / total else NA_real_
    span <- as.numeric(difftime(out$time[nrow(out)], out$time[1], units = "days"))
    out$cal_frac <- as.numeric(difftime(out$time, out$time[1], units = "days")) / span
  }
  attr(out, "market_id") <- attr(x, "market_id")
  attr(out, "event_date") <- attr(x, "event_date")
  class(out) <- c("event_clock_path", class(tibble::tibble()))
  out
}

#' @describeIn event_clock_path Plot method; dispatches to [plot_clock()].
#' @export
plot.event_clock_path <- function(x, ...) plot_clock(x, ...)

#' Real-time event-clock forecast
#'
#' The real-time benchmark used in the accompanying working paper: estimate
#' the current information intensity from a trailing window and scale it to
#' the forecast horizon,
#' \deqn{\widehat A^{rt}(h) = \frac{RV(\text{trailing } k \text{ obs.})}
#'   {\text{calendar span in days}} \times h.}
#'
#' @inheritParams event_clock
#' @param at Valuation date/time at which the forecast is made (default:
#'   last observation).
#' @param horizon Forecast horizon(s): either numeric (days) or
#'   `Date`/`POSIXct` horizon dates (converted to days from `at`). Names
#'   are used as labels.
#' @param trailing Integer, number of trailing observations in the
#'   estimation window (default 40, the paper's headline choice; 20 and 60
#'   are common robustness settings).
#'
#' @return A tibble with columns `market_id`, `at`, `horizon`,
#'   `horizon_days`, `trailing`, `n_incr`, and `A_forecast`.
#'
#' @examples
#' data(us2016)
#' ep <- as_event_prices(us2016, time = "date", price = "trump")
#' event_clock_forecast(ep,
#'   at = as.Date("2016-10-10"),
#'   horizon = c(`1W` = 7, `2W` = 14)
#' )
#' @export
event_clock_forecast <- function(x, at = NULL, horizon,
                                 trailing = ec_default_params()$trailing,
                                 sample_every = ec_default_params()$sample_every,
                                 clip = NULL) {
  x <- as_event_prices(x)
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  at <- at %||% max(x$time)

  keep <- x$time <= at & !is.na(x$q)
  d <- x[keep, , drop = FALSE]
  if (nrow(d) < 2) {
    cli::cli_abort("Need at least 2 non-missing observations up to {.val {format(at)}}.")
  }
  d <- utils::tail(d, as.integer(trailing))
  idx <- seq(1L, nrow(d), by = as.integer(sample_every))
  d <- d[idx, , drop = FALSE]

  L <- ec_logit(clip_q(d$q, clip))
  rv <- kernel_rv(diff(L))
  span_days <- as.numeric(difftime(d$time[nrow(d)], d$time[1], units = "days"))
  if (span_days <= 0) {
    cli::cli_abort("Trailing window has zero calendar span.")
  }

  if (inherits(horizon, c("Date", "POSIXct"))) {
    h_days <- as.numeric(difftime(horizon, at, units = "days"))
    labels <- names(horizon) %||% format(horizon)
  } else {
    h_days <- as.numeric(horizon)
    labels <- names(horizon) %||% paste0(h_days, "d")
  }
  labels[labels == ""] <- paste0(h_days, "d")[labels == ""]
  if (any(h_days <= 0)) {
    cli::cli_abort("{.arg horizon} must lie strictly after {.arg at}.")
  }

  tibble::tibble(
    market_id = attr(x, "market_id") %||% NA_character_,
    at = at, horizon = labels, horizon_days = h_days,
    trailing = as.integer(trailing), n_incr = length(L) - 1L,
    A_forecast = rv / span_days * h_days
  )
}
