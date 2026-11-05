# ---------------------------------------------------------------------------
# Connector for the public, keyless Kalshi trade API (v2):
#   https://api.elections.kalshi.com/trade-api/v2
# Live markets:    /markets, /series/{series}/markets/{ticker}/candlesticks
# Settled markets: /historical/markets, /historical/markets/{ticker}/candlesticks
# ---------------------------------------------------------------------------

ks_url <- "https://api.elections.kalshi.com/trade-api/v2"

ks_get <- function(path, query = list(), allow_404 = FALSE) {
  req <- httr2::request(ks_url) |>
    httr2::req_url_path_append(path) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_user_agent("eventclock R package (https://github.com/sstoeckl/eventclock)") |>
    httr2::req_retry(max_tries = 4) |>
    httr2::req_error(is_error = function(resp) FALSE)
  resp <- httr2::req_perform(req)
  status <- httr2::resp_status(resp)
  if (status == 404 && allow_404) return(NULL)
  if (status != 200) {
    body <- tryCatch(substr(httr2::resp_body_string(resp), 1, 200),
                     error = function(e) "")
    cli::cli_abort(c(
      "Kalshi API returned HTTP {status} for {.path {path}}.",
      if (nzchar(body)) c(i = "Response: {body}")
    ))
  }
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

# Follow Kalshi's cursor pagination and collect the `key` element.
ks_paged <- function(path, query, key) {
  out <- list()
  cur <- NULL
  repeat {
    x <- ks_get(path, c(query, list(limit = 200),
                        if (!is.null(cur)) list(cursor = cur)))
    out <- c(out, x[[key]])
    cur <- x$cursor
    if (is.null(cur) || !nzchar(cur)) break
  }
  out
}

# Live endpoints suffix numeric fields with `_dollars`/`_fp`; historical
# endpoints use the bare name. Both are dollars (0-1 per contract).
ks_num <- function(x, nm) {
  v <- x[[paste0(nm, "_dollars")]] %||% x[[paste0(nm, "_fp")]] %||% x[[nm]]
  if (is.null(v)) NA_real_ else suppressWarnings(as.numeric(v))
}

ks_chr <- function(x, nm) {
  v <- x[[nm]]
  if (is.null(v)) NA_character_ else as.character(v)
}

#' List the markets of a Kalshi event
#'
#' Kalshi organizes contracts as *series* (e.g. `"PRES"`), *events* (one
#' occurrence, e.g. `"PRES-2024"`), and *markets* (one binary contract per
#' outcome, e.g. `"PRES-2024-DJT"`). `ks_markets()` lists the markets of
#' an event from both the live and the historical (settled) endpoints of
#' the public API; `ks_events()` lists the events of a series.
#'
#' @param event_ticker Character, the event ticker.
#'
#' @return A tibble with columns `ticker`, `event_ticker`, `title`,
#'   `outcome` (Kalshi's `yes_sub_title`), `status`, `open_time`,
#'   `close_time`, and `result`.
#'
#' @examples
#' \dontrun{
#' ks_events("PRES")
#' ks_markets("PRES-2024")
#' }
#' @seealso [ks_prices()]
#' @export
ks_markets <- function(event_ticker) {
  stopifnot(is.character(event_ticker), length(event_ticker) == 1)
  mk <- c(ks_paged("markets", list(event_ticker = event_ticker), "markets"),
          ks_paged("historical/markets", list(event_ticker = event_ticker),
                   "markets"))
  if (length(mk) == 0) {
    cli::cli_abort("No markets found for event {.val {event_ticker}}.")
  }
  out <- tibble::tibble(
    ticker = vapply(mk, ks_chr, "", nm = "ticker"),
    event_ticker = vapply(mk, ks_chr, "", nm = "event_ticker"),
    title = vapply(mk, ks_chr, "", nm = "title"),
    outcome = vapply(mk, ks_chr, "", nm = "yes_sub_title"),
    status = vapply(mk, ks_chr, "", nm = "status"),
    open_time = vapply(mk, ks_chr, "", nm = "open_time"),
    close_time = vapply(mk, ks_chr, "", nm = "close_time"),
    result = vapply(mk, ks_chr, "", nm = "result")
  )
  out[!duplicated(out$ticker), ]
}

#' @rdname ks_markets
#' @param series_ticker Character, the series ticker (e.g. `"PRES"`,
#'   `"KXFEDDECISION"`).
#' @return `ks_events()`: a tibble with columns `event_ticker`,
#'   `series_ticker`, `title`, and `sub_title`.
#' @export
ks_events <- function(series_ticker) {
  stopifnot(is.character(series_ticker), length(series_ticker) == 1)
  ev <- ks_paged("events", list(series_ticker = series_ticker), "events")
  if (length(ev) == 0) {
    cli::cli_warn("No events found for series {.val {series_ticker}}.")
  }
  tibble::tibble(
    event_ticker = vapply(ev, ks_chr, "", nm = "event_ticker"),
    series_ticker = vapply(ev, ks_chr, "", nm = "series_ticker"),
    title = vapply(ev, ks_chr, "", nm = "title"),
    sub_title = vapply(ev, ks_chr, "", nm = "sub_title")
  )
}

# Flatten a list of candlesticks into a tibble (internal).
ks_candles_tibble <- function(cs) {
  if (length(cs) == 0) {
    return(tibble::tibble(ts = numeric(), close = numeric(), bid = numeric(),
                          ask = numeric(), volume = numeric()))
  }
  tibble::tibble(
    ts = vapply(cs, function(c) as.numeric(c$end_period_ts), 0),
    close = vapply(cs, function(c) ks_num(c$price, "close"), 0),
    bid = vapply(cs, function(c) ks_num(c$yes_bid, "close"), 0),
    ask = vapply(cs, function(c) ks_num(c$yes_ask, "close"), 0),
    volume = vapply(cs, function(c) ks_num(c, "volume"), 0)
  )
}

#' Download Kalshi price history for one market
#'
#' Pulls candlesticks for a Kalshi market from the public API and returns
#' them as an `event_prices` object, ready for [event_clock()] and
#' friends. Settled markets are served by the historical endpoint, live
#' markets by the series endpoint; `ks_prices()` tries the former first.
#' Long periods are split into chunks automatically.
#'
#' @details
#' Kalshi returns a candle only for periods with activity, so hourly and
#' minute series have gaps in quiet periods (see the gap diagnostics of
#' [event_clock()]). `price = "close"` uses the last traded price of each
#' candle; `price = "mid"` the midpoint of the closing bid and ask, which
#' is less exposed to bid-ask bounce. To compare with another venue, take
#' a common daily snapshot, e.g. `pm_daily(x, snapshot_hour = 15.75)` for
#' 15:45 New York time.
#'
#' @param ticker Character, the market ticker (from [ks_markets()]).
#' @param from,to Start and end (anything [as.POSIXct()] understands, in
#'   UTC); default: the last 30 days.
#' @param interval Candle length: `"1h"` (default), `"1d"`, or `"1m"`.
#' @param price `"close"` (last trade, default) or `"mid"`.
#' @param series_ticker Optional series ticker for live markets (default:
#'   the part of `ticker` before the first `-`).
#' @param market_id,event_date Passed to [as_event_prices()].
#'
#' @return An `event_prices` object with `POSIXct` (UTC) timestamps at the
#'   end of each candle.
#'
#' @examples
#' \dontrun{
#' ks <- ks_prices("PRES-2024-DJT", from = "2024-10-04", to = "2024-11-06",
#'                 market_id = "Kalshi: Trump wins 2024")
#' event_clock(pm_daily(ks, snapshot_hour = 15.75))
#' }
#' @seealso [ks_markets()], [pm_prices()], [event_clock_venues()]
#' @export
ks_prices <- function(ticker, from = NULL, to = NULL,
                      interval = c("1h", "1d", "1m"),
                      price = c("close", "mid"),
                      series_ticker = NULL, market_id = ticker,
                      event_date = NULL) {
  stopifnot(is.character(ticker), length(ticker) == 1)
  interval <- rlang::arg_match(interval)
  price <- rlang::arg_match(price)
  to <- as.POSIXct(to %||% Sys.time(), tz = "UTC")
  from <- as.POSIXct(from %||% (to - 30 * 86400), tz = "UTC")
  if (from >= to) cli::cli_abort("{.arg from} must be before {.arg to}.")
  series_ticker <- series_ticker %||% sub("-.*$", "", ticker)

  minutes <- c(`1m` = 1, `1h` = 60, `1d` = 1440)[[interval]]
  chunk_days <- c(`1m` = 3, `1h` = 150, `1d` = 4000)[[interval]]
  s0 <- as.numeric(from)
  e0 <- as.numeric(to)
  bounds <- unique(c(seq(s0, e0, by = chunk_days * 86400), e0))
  if (length(bounds) < 2) bounds <- c(s0, e0)

  chunks <- lapply(seq_len(length(bounds) - 1), function(i) {
    q <- list(start_ts = floor(bounds[i]), end_ts = ceiling(bounds[i + 1]),
              period_interval = minutes)
    h <- ks_get(sprintf("historical/markets/%s/candlesticks", ticker), q,
                allow_404 = TRUE)
    if (is.null(h)) {
      h <- ks_get(sprintf("series/%s/markets/%s/candlesticks",
                          series_ticker, ticker), q)
    }
    ks_candles_tibble(h$candlesticks)
  })
  raw <- dplyr::bind_rows(chunks)
  if (nrow(raw) == 0) {
    cli::cli_abort("No candles returned for {.val {ticker}} in the requested window.")
  }
  raw <- raw[!duplicated(raw$ts), , drop = FALSE]
  raw <- raw[order(raw$ts), , drop = FALSE]
  q <- if (price == "close") raw$close else (raw$bid + raw$ask) / 2
  df <- tibble::tibble(
    time = as.POSIXct(raw$ts, origin = "1970-01-01", tz = "UTC"),
    q = q
  )
  as_event_prices(df, time = "time", price = "q",
                  market_id = market_id, event_date = event_date)
}
