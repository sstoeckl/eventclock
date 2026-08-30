#' Data-quality report for an event-probability series
#'
#' Screens an `event_prices` object for the data problems that matter for
#' clock estimation, following the flag-don't-drop philosophy: nothing is
#' altered, everything is reported.
#'
#' @details
#' The checks:
#' * **Coverage** — observations, span, median spacing, missing values,
#'   share outside the clipping bounds.
#' * **Staleness** — share of zero increments and the longest run of
#'   unchanged quotes; long stale runs depress \eqn{\widehat A}.
#' * **Tick size** — smallest non-zero price move; on a coarse tick grid
#'   the logit of small-probability quotes moves in lumps
#'   (microstructure noise; compare [ec_signature()]).
#' * **Gaps** — increments spanning more than 1.5 times the median
#'   spacing (see [event_clock()]).
#' * **Outliers** — largest absolute log-odds increment relative to the
#'   robust scale of all increments; values far above the truncation
#'   threshold deserve a manual look (data error vs. genuine news).
#'
#' @param x An `event_prices` object (or coercible).
#' @param ... Unused (for the `print` method).
#'
#' @return A one-row tibble of class `ec_validation` with columns
#'   `market_id`, `n_obs`, `start`, `end`, `spacing_days`, `n_na`,
#'   `share_clip`, `share_zero_incr`, `max_stale_run`, `tick`,
#'   `n_gaps`, `max_gap_days`, `max_abs_dL`, and `outlier_ratio`
#'   (`max_abs_dL` / robust SD). Printed as a formatted report.
#'
#' @examples
#' ec_validate(as_event_prices(brexit2016, time = "date", price = "q_leave"))
#' @export
ec_validate <- function(x) {
  x <- as_event_prices(x)
  ok <- !x$flag_na
  q <- x$q[ok]
  tt <- x$time[ok]
  n <- length(q)
  if (n < 2) cli::cli_abort("Need at least 2 non-missing observations.")

  dq <- diff(q)
  clip <- attr(x, "clip") %||% ec_default_params()$clip
  L <- ec_logit(clip_q(q, clip))
  dL <- diff(L)
  s <- stats::mad(dL)

  # longest run of unchanged quotes
  runs <- rle(c(TRUE, dq != 0))
  stale <- runs$lengths[!runs$values]
  max_stale <- if (length(stale)) max(stale) else 0L

  nz <- abs(dq)[abs(dq) > 0]
  g <- gap_stats(tt)

  out <- tibble::tibble(
    market_id = attr(x, "market_id") %||% NA_character_,
    n_obs = nrow(x),
    start = min(x$time),
    end = max(x$time),
    spacing_days = stats::median(as.numeric(difftime(tt[-1], tt[-n],
                                                     units = "days"))),
    n_na = sum(x$flag_na),
    share_clip = mean(x$flag_clip[ok]),
    share_zero_incr = mean(dq == 0),
    max_stale_run = as.integer(max_stale),
    tick = if (length(nz)) min(nz) else NA_real_,
    n_gaps = g$n_gaps,
    max_gap_days = g$max_gap_days,
    max_abs_dL = max(abs(dL)),
    outlier_ratio = if (is.finite(s) && s > 0) max(abs(dL)) / s else NA_real_
  )
  class(out) <- c("ec_validation", class(tibble::tibble()))
  out
}

#' @describeIn ec_validate Print method; formatted report.
#' @export
print.ec_validation <- function(x, ...) {
  cat("-- Event-price data-quality report",
      if (!is.na(x$market_id)) paste0(": ", x$market_id), "\n", sep = "")
  cat(sprintf("Coverage:  %d obs, %s to %s, median spacing %.2g days, %d NA\n",
              x$n_obs, format(x$start), format(x$end), x$spacing_days, x$n_na))
  cat(sprintf("Clipping:  %.1f%% of observations outside the clipping bounds\n",
              100 * x$share_clip))
  cat(sprintf("Staleness: %.1f%% zero increments, longest stale run %d obs\n",
              100 * x$share_zero_incr, x$max_stale_run))
  cat(sprintf("Tick:      smallest non-zero move %.4g\n", x$tick))
  cat(sprintf("Gaps:      %d gap increment(s), largest %.3g days\n",
              x$n_gaps, x$max_gap_days))
  cat(sprintf("Outliers:  max |dL| = %.3g (%.1f robust SDs)\n",
              x$max_abs_dL, x$outlier_ratio))
  invisible(x)
}
