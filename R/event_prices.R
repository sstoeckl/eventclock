#' Standardize traded event state prices as an `event_prices` object
#'
#' `as_event_prices()` turns a `data.frame`/`tibble` holding a time series
#' of traded event state prices or the implied event probabilities
#' (prediction-market contracts, betting quotes) into a standardized
#' `event_prices` tibble that all estimation and plotting functions of the
#' package understand.
#'
#' @details
#' The constructor follows a strict *flag, don't drop* convention: raw
#' values are kept in `q_raw`, data problems are recorded in flag columns,
#' and nothing is silently deleted. The only structural interventions are
#' sorting by time and removing duplicated timestamps (keeping the first
#' occurrence, with a warning), because increments are undefined otherwise.
#'
#' Columns of the returned object:
#' \describe{
#'   \item{time}{`Date` or `POSIXct` timestamp (sorted, unique).}
#'   \item{q_raw}{the raw input price after rescaling by `scale`.}
#'   \item{q}{the normalized probability, `q_from_price(q_raw, ...)`.}
#'   \item{flag_na}{`TRUE` where `q` is missing.}
#'   \item{flag_clip}{`TRUE` where `q` falls outside the clipping bounds and
#'     will be clipped before the log-odds transform in [event_clock()].}
#' }
#'
#' The clipping bounds, market id, and event date are stored as attributes
#' (`clip`, `market_id`, `event_date`) and are picked up by
#' [event_clock()], [event_clock_path()], and the plotting functions.
#'
#' **Timezones.** A `POSIXct` time column is kept in the timezone it
#' carries; character timestamps are parsed as UTC. Window bounds passed
#' as `Date` to [event_clock()] and friends are interpreted in the
#' series' timezone (with `to` covering the full day), so mixing `Date`
#' bounds with a non-UTC intraday series is safe.
#'
#' @param x A `data.frame`/`tibble` (or an existing `event_prices` object,
#'   returned unchanged).
#' @param time Name of the time column (character). If `NULL`, the first of
#'   `time`, `date`, `timestamp`, `datetime`, `t` (case-insensitive) is
#'   used.
#' @param price Name of the price/probability column (character). If
#'   `NULL`, the first of `q`, `price`, `p`, `q_t`, `value`
#'   (case-insensitive) is used. Ignored when `bid` and `ask` are given.
#' @param bid,ask Optional names of bid and ask columns; if both are given,
#'   the mid quote is used as price.
#' @param scale Numeric, divisor applied to the raw price first (use
#'   `scale = 100` for percent quotes; default 1).
#' @param discount,book,method Passed to [q_from_price()].
#' @param clip Numeric length-2, clipping bounds applied to `q` before the
#'   log-odds transform (default `c(0.01, 0.99)`, see
#'   [ec_default_params()]).
#' @param market_id Optional character label of the market.
#' @param event_date Optional `Date`/`POSIXct` of the scheduled event
#'   (resolution) date.
#' @param object An `event_prices` object (for `summary()`).
#' @param ... Reserved for future methods.
#'
#' @return An `event_prices` tibble; see Details.
#'
#' @examples
#' data(brexit2016)
#' ep <- as_event_prices(brexit2016,
#'   time = "date", price = "q_leave",
#'   market_id = "Brexit: Leave", event_date = as.Date("2016-06-23")
#' )
#' ep
#' summary(ep)
#' @export
as_event_prices <- function(x, ...) UseMethod("as_event_prices")

#' @rdname as_event_prices
#' @export
as_event_prices.event_prices <- function(x, ...) x

#' @rdname as_event_prices
#' @export
as_event_prices.data.frame <- function(x, time = NULL, price = NULL,
                                       bid = NULL, ask = NULL,
                                       scale = 1,
                                       discount = 1, book = NULL,
                                       method = c("discount", "overround"),
                                       clip = ec_default_params()$clip,
                                       market_id = NULL, event_date = NULL,
                                       ...) {
  method <- rlang::arg_match(method)
  nms <- names(x)

  pick_col <- function(given, candidates, what) {
    if (!is.null(given)) {
      if (!given %in% nms) {
        cli::cli_abort("Column {.val {given}} not found in {.arg x}.")
      }
      return(given)
    }
    hit <- nms[match(candidates, tolower(nms))]
    hit <- hit[!is.na(hit)]
    if (length(hit) == 0) {
      cli::cli_abort(c(
        "Cannot guess the {what} column.",
        i = "Pass {.arg {what}} explicitly; tried {.val {candidates}}."
      ))
    }
    hit[1]
  }

  time_col <- pick_col(time, c("time", "date", "timestamp", "datetime", "t"), "time")
  tt <- x[[time_col]]
  if (is.character(tt)) {
    parsed <- as.POSIXct(tt, tz = "UTC", tryFormats = c(
      "%Y-%m-%d %H:%M:%OS", "%Y-%m-%d %H:%M", "%Y-%m-%d", "%d.%m.%Y"
    ))
    if (anyNA(parsed) && !anyNA(tt)) {
      cli::cli_abort("Could not parse the time column {.val {time_col}}; supply {.cls Date} or {.cls POSIXct}.")
    }
    tt <- parsed
  }
  if (!inherits(tt, c("Date", "POSIXct"))) {
    cli::cli_abort("The time column {.val {time_col}} must be {.cls Date} or {.cls POSIXct}.")
  }

  if (!is.null(bid) && !is.null(ask)) {
    if (!all(c(bid, ask) %in% nms)) {
      cli::cli_abort("Columns {.val {bid}} / {.val {ask}} not found in {.arg x}.")
    }
    pp <- (as.numeric(x[[bid]]) + as.numeric(x[[ask]])) / 2
  } else {
    price_col <- pick_col(price, c("q", "price", "p", "q_t", "value"), "price")
    pp <- as.numeric(x[[price_col]])
  }

  stopifnot(is.numeric(scale), length(scale) == 1, scale > 0)
  q_raw <- pp / scale
  q <- q_from_price(q_raw, discount = discount, book = book, method = method)

  out <- tibble::tibble(time = tt, q_raw = q_raw, q = q)

  # rows without a timestamp are unusable -> drop with a warning
  if (anyNA(out$time)) {
    cli::cli_warn("{sum(is.na(out$time))} row{?s} with missing timestamp removed.")
    out <- out[!is.na(out$time), , drop = FALSE]
  }

  # sort; duplicated timestamps break increments -> keep first, warn
  out <- out[order(out$time), , drop = FALSE]
  dup <- duplicated(out$time)
  if (any(dup)) {
    cli::cli_warn("{sum(dup)} duplicated timestamp{?s} removed (first occurrence kept).")
    out <- out[!dup, , drop = FALSE]
  }

  out$flag_na <- is.na(out$q)
  out$flag_clip <- !out$flag_na & (out$q < clip[1] | out$q > clip[2])

  new_event_prices(out, market_id = market_id, event_date = event_date, clip = clip)
}

# low-level constructor (internal)
new_event_prices <- function(df, market_id = NULL, event_date = NULL,
                             clip = ec_default_params()$clip) {
  stopifnot(is.data.frame(df), all(c("time", "q") %in% names(df)))
  out <- tibble::as_tibble(df)
  attr(out, "market_id") <- market_id
  attr(out, "event_date") <- event_date
  attr(out, "clip") <- clip
  class(out) <- c("event_prices", class(tibble::tibble()))
  out
}

#' @describeIn as_event_prices Print method; shows market, range, and flags.
#' @export
print.event_prices <- function(x, ...) {
  mid <- attr(x, "market_id")
  ed <- attr(x, "event_date")
  cat("-- Event prices", if (!is.null(mid)) paste0(": ", mid), "\n", sep = "")
  cat(nrow(x), " observations, ", format(min(x$time)), " to ",
      format(max(x$time)), "\n", sep = "")
  if (!is.null(ed)) cat("Scheduled event: ", format(ed), "\n", sep = "")
  nfl <- sum(x$flag_na | x$flag_clip)
  if (nfl > 0) {
    cat(nfl, " flagged observations (NA or outside clipping bounds)\n", sep = "")
  }
  NextMethod()
  invisible(x)
}

#' @describeIn as_event_prices Summary method; returns a one-row tibble
#'   including the full-sample event-clock estimate.
#' @export
summary.event_prices <- function(object, ...) {
  ok <- !object$flag_na
  a_full <- if (sum(ok) >= 2) {
    unclass(event_clock(object, methods = "rv")$A)
  } else {
    NA_real_
  }
  tibble::tibble(
    market_id = attr(object, "market_id") %||% NA_character_,
    n = nrow(object),
    start = min(object$time),
    end = max(object$time),
    q_start = object$q[ok][1],
    q_end = utils::tail(object$q[ok], 1),
    q_min = min(object$q, na.rm = TRUE),
    q_max = max(object$q, na.rm = TRUE),
    n_na = sum(object$flag_na),
    n_clip = sum(object$flag_clip),
    A_full = a_full
  )
}

#' @describeIn as_event_prices Plot method; dispatches to [plot_q()].
#' @export
plot.event_prices <- function(x, ...) plot_q(x, ...)
