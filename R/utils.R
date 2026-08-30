# Internal numerical helpers. The log-odds transform and its inverse are the
# base-R quantile/distribution functions of the logistic distribution.

#' Log-odds (logit) transform
#'
#' Thin wrappers around [stats::qlogis()] and [stats::plogis()]. Exported
#' because every quantity in the event-clock framework is defined on the
#' log-odds scale \eqn{L_t = \mathrm{logit}(q_t)}.
#'
#' @param q Numeric vector of probabilities in \eqn{(0, 1)}.
#' @param l Numeric vector of log-odds.
#'
#' @return `ec_logit()` returns log-odds; `ec_ilogit()` returns
#'   probabilities.
#'
#' @examples
#' ec_logit(0.195)
#' ec_ilogit(-1.418)
#' @export
ec_logit <- function(q) stats::qlogis(q)

#' @rdname ec_logit
#' @export
ec_ilogit <- function(l) stats::plogis(l)

# Clip probabilities into [lo, hi] before taking log-odds. Follows the
# flag-don't-drop convention: callers keep the raw values and record where
# clipping binds.
clip_q <- function(q, clip) {
  stopifnot(length(clip) == 2, clip[1] < clip[2], clip[1] > 0, clip[2] < 1)
  pmin(pmax(q, clip[1]), clip[2])
}

# Input validation used across the formula book.
check_prob <- function(q, name = "q") {
  if (any(!is.na(q) & (q <= 0 | q >= 1))) {
    cli::cli_abort("{.arg {name}} must lie strictly inside (0, 1).")
  }
  invisible(q)
}

check_nonneg <- function(A, name = "A") {
  if (any(!is.na(A) & A < 0)) {
    cli::cli_abort("{.arg {name}} must be non-negative.")
  }
  invisible(A)
}

# Explicit common-length recycling for the vectorized formula book. Errors on
# incompatible lengths instead of silently misaligning values.
ec_recycle <- function(...) {
  args <- list(...)
  n <- max(lengths(args))
  bad <- vapply(args, function(a) n %% length(a) != 0, logical(1))
  if (any(bad)) {
    cli::cli_abort(
      "Argument lengths ({toString(lengths(args))}) are incompatible; they must recycle to {n}."
    )
  }
  lapply(args, rep_len, length.out = n)
}

# Align a window bound (from/to/at/event_date) with the class and timezone of
# a time vector, so Date bounds and POSIXct series (or vice versa) compare as
# a user expects instead of via R's implicit UTC-midnight coercion.
# side = "end" maps a Date bound to the end of that day (23:59:59) so that
# `to = as.Date(...)` includes the day's intraday observations.
align_bound <- function(bound, time, side = c("start", "end")) {
  side <- rlang::arg_match(side)
  if (is.null(bound)) return(NULL)
  if (inherits(time, "Date") && inherits(bound, "POSIXct")) {
    return(as.Date(bound, tz = attr(bound, "tzone") %||% "UTC"))
  }
  if (inherits(time, "POSIXct") && inherits(bound, "Date")) {
    tz <- attr(time, "tzone") %||% "UTC"
    out <- as.POSIXct(format(bound), tz = tz)
    if (side == "end") out <- out + (86400 - 1)
    return(out)
  }
  bound
}
