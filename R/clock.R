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
  if (!is.finite(s) || s <= 0) {
    cli::cli_inform(c(
      i = "Robust scale of the increments is degenerate (0 or non-finite); truncation is disabled and plain realized variation returned."
    ))
    return(kernel_rv(dL))
  }
  sum(dL[abs(dL) <= trunc_sd * s]^2)
}

kernel_drop_largest <- function(dL, k = 1) {
  n <- length(dL)
  if (n <= k) return(NA_real_)
  o <- order(abs(dL), decreasing = TRUE)
  sum(dL[-o[seq_len(k)]]^2)
}

# Asymptotic standard error of the realized variation via the quarticity
# analogue: Var(RV) ~= 2 * sum(sigma_i^4), estimated by (2/3) * sum(dL^4)
# (E[r^4] = 3 sigma^4 for Gaussian increments).
kernel_rv_se <- function(dL) {
  if (length(dL) < 2) return(NA_real_)
  sqrt((2 / 3) * sum(dL^4))
}

# Wild bootstrap of the realized variation with two-point multipliers whose
# squared value has mean 1 and variance 2/3, matching the quarticity-based
# asymptotic variance (Goncalves-Meddahi-style moment matching).
kernel_rv_boot <- function(dL, reps = 999) {
  if (length(dL) < 2) return(matrix(numeric(0), nrow = 0))
  d2 <- dL^2
  m <- 1 + sqrt(2 / 3) * (2 * stats::rbinom(reps * length(d2), 1, 0.5) - 1)
  m <- matrix(m, nrow = reps)
  as.numeric(m %*% d2)
}

# ---------------------------------------------------------------------------
# Shared window logic
# ---------------------------------------------------------------------------

# Select the non-missing observations inside [from, to], with bounds aligned
# to the class/timezone of x$time. Warns when missing values inside the
# window are skipped, because increments then bridge the resulting gaps.
window_rows <- function(x, from, to, warn_na = TRUE) {
  from <- align_bound(from, x$time, side = "start")
  to <- align_bound(to, x$time, side = "end")
  in_win <- x$time >= from & x$time <= to
  n_na <- sum(in_win & is.na(x$q))
  if (warn_na && n_na > 0) {
    cli::cli_warn(
      "{n_na} missing observation{?s} inside the window skipped; adjacent increments bridge these gaps (see the Missing observations section of {.code ?event_clock})."
    )
  }
  x[in_win & !is.na(x$q), , drop = FALSE]
}

# Gap diagnostics on the observations actually used: number of increments
# spanning more than 1.5x the median observation spacing, and the largest
# spacing in days.
gap_stats <- function(time) {
  if (length(time) < 2) {
    return(list(n_gaps = 0L, max_gap_days = NA_real_))
  }
  dt <- as.numeric(difftime(time[-1], time[-length(time)], units = "days"))
  list(
    n_gaps = sum(dt > 1.5 * stats::median(dt)),
    max_gap_days = max(dt)
  )
}

# Extract clipped log-odds increments from an event_prices window.
window_increments <- function(x, from, to, sample_every, clip) {
  d <- window_rows(x, from, to)
  n_obs <- nrow(d)
  empty <- list(
    dL = numeric(0), n_obs = n_obs, n_gaps = 0L, max_gap_days = NA_real_
  )
  if (n_obs < 2) return(empty)
  idx <- seq(1L, n_obs, by = sample_every)
  d <- d[idx, , drop = FALSE]
  if (nrow(d) < 2) return(empty)
  L <- ec_logit(clip_q(d$q, clip))
  g <- gap_stats(d$time)
  list(
    dL = diff(L), n_obs = n_obs,
    n_gaps = g$n_gaps, max_gap_days = g$max_gap_days
  )
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
#'     increment (`largest1`). Compare both. When the robust scale is
#'     degenerate (e.g. more than half of the increments are identical),
#'     truncation is disabled with a message and plain realized variation
#'     is returned.}
#'   \item{`bipower`}{bipower variation
#'     \eqn{BV = \frac{\pi}{2}\sum_{i\ge 2} |\Delta L_i||\Delta L_{i-1}|},
#'     a jump-robust companion; the gap \eqn{RV - BV} is a descriptive
#'     *jumpiness index*. No finite-sample correction is applied, so `BV`
#'     is biased downward in very short windows (a 1-week window has only
#'     six neighbor products); read it as descriptive, not as an unbiased
#'     estimate.}
#'   \item{`largest1`, `largest2`}{realized variation after removing the
#'     one or two largest absolute increments.}
#' }
#'
#' **Windows.** Windows are defined in calendar time from the valuation
#' date `from` to each horizon date in `to` (they are *anchored* windows,
#' not trailing ones). All observations in the window are used, including
#' weekends if the series has them. `Date`-typed bounds combined with a
#' `POSIXct`-typed series are interpreted in the series' timezone, with
#' `to` covering the full horizon day.
#'
#' **Missing observations and gaps.** Missing `q` values inside the window
#' are skipped with a warning; the increment then *bridges* the gap and
#' aggregates more elapsed time than a regular one-period increment. Plain
#' realized variation remains a valid (sparser) estimate of the window's
#' total variation, but the robustness variants treat all increments as
#' homogeneous: a gap-spanning increment is mechanically larger and can be
#' misclassified as a jump by `truncated`/`largest1`/`largest2`, and it
#' distorts the neighbor products of `bipower`. The output columns
#' `n_gaps` (increments spanning more than 1.5 times the median
#' observation spacing) and `max_gap_days` flag affected windows —
#' interpret the robustness variants cautiously whenever `n_gaps > 0`.
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
#' @param se Logical; if `TRUE`, add a standard error and confidence
#'   interval for the `rv` estimate (columns are `NA` for the other
#'   methods). The asymptotic variance is estimated by the quarticity
#'   analogue \eqn{\widehat{Var}(\widehat A) = \tfrac{2}{3}\sum (\Delta
#'   L_i)^4}; the interval is log-based,
#'   \eqn{\exp\{\log \widehat A \pm z\, se/\widehat A\}}. With
#'   `se_method = "bootstrap"`, a wild bootstrap with two-point
#'   multipliers (moment-matched to the same asymptotic variance) is used
#'   and the interval is the percentile interval. Conditional drift
#'   contributes at order \eqn{(\Delta t)^2} and is ignored.
#' @param conf Confidence level (default 0.95).
#' @param se_method `"quarticity"` (default) or `"bootstrap"`.
#' @param boot_reps Bootstrap replications (default 999).
#'
#' @return A tibble with one row per horizon and method:
#'   \item{market_id}{market label (from `x`).}
#'   \item{from, to}{window bounds as supplied.}
#'   \item{horizon}{horizon label (names of `to`, or the date).}
#'   \item{n_obs}{number of non-missing observations in the window.}
#'   \item{n_incr}{number of increments used (after subsampling).}
#'   \item{n_gaps}{number of increments spanning more than 1.5 times the
#'     median observation spacing (see Details).}
#'   \item{max_gap_days}{largest spacing (in days) between consecutive
#'     observations used.}
#'   \item{method}{estimator variant.}
#'   \item{A}{the estimate \eqn{\widehat A_{t,T}}.}
#'   \item{se, ci_lo, ci_hi}{(only with `se = TRUE`) standard error and
#'     confidence bounds for the `rv` rows.}
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
                        clip = NULL,
                        se = FALSE, conf = 0.95,
                        se_method = c("quarticity", "bootstrap"),
                        boot_reps = 999) {
  x <- as_event_prices(x)
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  methods <- match.arg(methods, ec_default_params()$methods, several.ok = TRUE)
  se_method <- rlang::arg_match(se_method)
  stopifnot(sample_every >= 1, conf > 0, conf < 1)
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
    out <- tibble::tibble(
      market_id = attr(x, "market_id") %||% NA_character_,
      from = from, to = to[i], horizon = labels[i],
      n_obs = w$n_obs, n_incr = length(w$dL),
      n_gaps = w$n_gaps, max_gap_days = w$max_gap_days,
      method = methods, A = unname(A)
    )
    if (se) {
      out$se <- NA_real_
      out$ci_lo <- NA_real_
      out$ci_hi <- NA_real_
      irv <- which(methods == "rv")
      if (length(irv) == 1 && length(w$dL) >= 2 && out$A[irv] > 0) {
        z <- stats::qnorm(1 - (1 - conf) / 2)
        if (se_method == "quarticity") {
          s <- kernel_rv_se(w$dL)
          out$se[irv] <- s
          out$ci_lo[irv] <- exp(log(out$A[irv]) - z * s / out$A[irv])
          out$ci_hi[irv] <- exp(log(out$A[irv]) + z * s / out$A[irv])
        } else {
          rv_star <- kernel_rv_boot(w$dL, reps = boot_reps)
          out$se[irv] <- stats::sd(rv_star)
          qq <- stats::quantile(rv_star, c((1 - conf) / 2, 1 - (1 - conf) / 2),
                                names = FALSE)
          out$ci_lo[irv] <- qq[1]
          out$ci_hi[irv] <- qq[2]
        }
      }
    }
    out
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

  d <- window_rows(x, from, to)
  if (nrow(d) >= 2) {
    idx <- seq(1L, nrow(d), by = as.integer(sample_every))
    d <- d[idx, , drop = FALSE]
  }
  if (nrow(d) < 2) {
    cli::cli_abort("Need at least 2 non-missing observations in the window (after subsampling).")
  }

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
#'   `horizon_days`, `trailing`, `n_incr`, `n_gaps`, `max_gap_days`, and
#'   `A_forecast`. See [event_clock()] for the gap diagnostics.
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

  d <- window_rows(x, min(x$time), at)
  if (nrow(d) < 2) {
    cli::cli_abort("Need at least 2 non-missing observations up to {.val {format(at)}}.")
  }
  d <- utils::tail(d, as.integer(trailing))
  idx <- seq(1L, nrow(d), by = as.integer(sample_every))
  d <- d[idx, , drop = FALSE]

  L <- ec_logit(clip_q(d$q, clip))
  rv <- kernel_rv(diff(L))
  g <- gap_stats(d$time)
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
    n_gaps = g$n_gaps, max_gap_days = g$max_gap_days,
    A_forecast = rv / span_days * h_days
  )
}
