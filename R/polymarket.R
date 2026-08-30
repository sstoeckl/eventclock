# ---------------------------------------------------------------------------
# Connector for the public, keyless Polymarket REST APIs:
#   Gamma API  https://gamma-api.polymarket.com  -> find events/markets/tokens
#   CLOB API   https://clob.polymarket.com       -> price history per token
# ---------------------------------------------------------------------------

pm_gamma_url <- "https://gamma-api.polymarket.com"
pm_clob_url <- "https://clob.polymarket.com"

pm_request <- function(base, path) {
  httr2::request(base) |>
    httr2::req_url_path_append(path) |>
    httr2::req_user_agent("eventclock R package (https://github.com/sstoeckl/eventclock)") |>
    httr2::req_retry(max_tries = 4) |>
    httr2::req_error(is_error = function(resp) FALSE)
}

pm_perform <- function(req) {
  resp <- httr2::req_perform(req)
  if (httr2::resp_status(resp) != 200) {
    body <- tryCatch(
      substr(httr2::resp_body_string(resp), 1, 200),
      error = function(e) ""
    )
    cli::cli_abort(c(
      "Polymarket API returned HTTP {httr2::resp_status(resp)}.",
      if (nzchar(body)) c(i = "Response: {body}")
    ))
  }
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

# Stitch chunked price-history pulls: bind, dedupe on the timestamp, sort.
pm_stitch <- function(chunks) {
  raw <- dplyr::bind_rows(chunks)
  if (NROW(raw) == 0) return(raw)
  raw |>
    dplyr::distinct(t, .keep_all = TRUE) |>
    dplyr::arrange(t)
}

#' Search Polymarket events
#'
#' Free-text search over Polymarket events via the public Gamma API. Use
#' the returned `event_slug` with [pm_markets()] to obtain the tradable
#' outcome tokens.
#'
#' @param query Character search string (e.g. `"fed decision"`).
#' @param limit Integer, maximum number of events (default 20).
#'
#' @return A tibble with columns `event_id`, `event_slug`, `title`,
#'   `start_date`, `end_date`, `closed`, and `volume` (columns missing in
#'   the API response are dropped).
#'
#' @examples
#' \dontrun{
#' pm_search("presidential election winner 2024")
#' }
#' @seealso [pm_markets()], [pm_prices()]
#' @export
pm_search <- function(query, limit = 20) {
  stopifnot(is.character(query), length(query) == 1)
  body <- pm_request(pm_gamma_url, "public-search") |>
    httr2::req_url_query(q = query, limit_per_type = limit) |>
    pm_perform()
  ev <- body$events
  if (is.null(ev) || NROW(ev) == 0) {
    cli::cli_warn("No events found for {.val {query}}.")
    return(tibble::tibble(
      event_id = character(), event_slug = character(), title = character(),
      start_date = character(), end_date = character(), closed = logical(),
      volume = numeric()
    ))
  }
  pm_events_tibble(ev)
}

# normalize a Gamma events data.frame to a tibble (internal)
pm_events_tibble <- function(ev) {
  grab <- function(nm) if (nm %in% names(ev)) ev[[nm]] else NA
  tibble::tibble(
    event_id = as.character(grab("id")),
    event_slug = as.character(grab("slug")),
    title = as.character(grab("title")),
    start_date = as.character(grab("startDate")),
    end_date = as.character(grab("endDate")),
    closed = as.logical(grab("closed")),
    volume = suppressWarnings(as.numeric(grab("volume")))
  )
}

#' List the markets and outcome tokens of a Polymarket event
#'
#' Fetches an event by slug from the Gamma API and unpacks its markets
#' into one row per outcome token. The CLOB `token_id` is what
#' [pm_prices()] needs.
#'
#' @param event_slug Character, the event slug (from [pm_search()] or the
#'   polymarket.com URL).
#'
#' @return A tibble with columns `event_slug`, `market_id`, `market_slug`,
#'   `question`, `outcome`, and `token_id`. Outcomes and token ids are
#'   returned in matching order (element 1 = first listed outcome,
#'   typically "Yes").
#'
#' @examples
#' \dontrun{
#' mkts <- pm_markets("presidential-election-winner-2024")
#' subset(mkts, grepl("Trump", question) & outcome == "Yes")
#' }
#' @export
pm_markets <- function(event_slug) {
  stopifnot(is.character(event_slug), length(event_slug) == 1)
  body <- pm_request(pm_gamma_url, "events") |>
    httr2::req_url_query(slug = event_slug) |>
    pm_perform()
  if (NROW(body) == 0) {
    cli::cli_abort("No event found for slug {.val {event_slug}}.")
  }
  mk <- if (is.data.frame(body)) body$markets[[1]] else body$markets
  if (is.null(mk) || NROW(mk) == 0) {
    cli::cli_abort("Event {.val {event_slug}} has no markets.")
  }
  pm_markets_tibble(mk, event_slug)
}

# unpack a Gamma markets data.frame into one row per outcome token (internal)
pm_markets_tibble <- function(mk, event_slug) {
  rows <- lapply(seq_len(NROW(mk)), function(i) {
    outcomes <- tryCatch(jsonlite::fromJSON(mk$outcomes[i]), error = function(e) NULL)
    tokens <- tryCatch(jsonlite::fromJSON(mk$clobTokenIds[i]), error = function(e) NULL)
    if (is.null(outcomes) || is.null(tokens) || length(outcomes) != length(tokens)) {
      return(NULL)
    }
    tibble::tibble(
      event_slug = event_slug,
      market_id = as.character(mk$id[i]),
      market_slug = as.character(mk$slug[i]),
      question = as.character(mk$question[i]),
      outcome = as.character(outcomes),
      token_id = as.character(tokens)
    )
  })
  dplyr::bind_rows(rows)
}

#' Download Polymarket price history for one outcome token
#'
#' Pulls the price history of a CLOB outcome token from the public
#' `/prices-history` endpoint and returns it as an [as_event_prices()]
#' object. The Polymarket price is already a probability in \eqn{[0,1]}.
#'
#' @details
#' The endpoint caps the number of points per call (a few hundred), so the
#' requested window is split into chunks and stitched (deduplicated on the
#' timestamp). The default chunk length adapts to `fidelity`; with
#' `fidelity = 60` (hourly bars) chunks of 10 days are used.
#'
#' @param token_id Character, the CLOB token id (from [pm_markets()]).
#' @param from,to Start and end of the window (`Date` or `POSIXct`,
#'   interpreted in UTC).
#' @param fidelity Integer, bar size in minutes (60 = hourly, 1440 =
#'   daily; default 60).
#' @param chunk_days Integer, chunk length in days (default:
#'   `max(1, floor(fidelity / 6))`, i.e. 10 days for hourly bars).
#' @param market_id Optional label stored on the result (default: the
#'   token id).
#' @param event_date Optional scheduled event date stored on the result.
#'
#' @return An `event_prices` object with `time` (`POSIXct`, UTC) and `q`.
#'
#' @examples
#' \dontrun{
#' mkts <- pm_markets("presidential-election-winner-2024")
#' tok <- mkts$token_id[grepl("Trump", mkts$question) & mkts$outcome == "Yes"]
#' ep <- pm_prices(tok, from = "2024-06-01", to = "2024-11-06")
#' event_clock(pm_daily(ep))
#' }
#' @export
pm_prices <- function(token_id, from, to, fidelity = 60,
                      chunk_days = NULL, market_id = NULL,
                      event_date = NULL) {
  stopifnot(is.character(token_id), length(token_id) == 1)
  s <- as.integer(as.numeric(as.POSIXct(from, tz = "UTC")))
  e <- as.integer(as.numeric(as.POSIXct(to, tz = "UTC")))
  stopifnot(s < e)
  chunk_days <- chunk_days %||% max(1L, floor(fidelity / 6))
  bounds <- unique(c(seq(s, e, by = as.integer(chunk_days) * 86400L), e))

  fetch_chunk <- function(cs, ce) {
    body <- pm_request(pm_clob_url, "prices-history") |>
      httr2::req_url_query(market = token_id, startTs = cs, endTs = ce,
                           fidelity = fidelity) |>
      pm_perform()
    h <- body$history
    if (is.null(h) || NROW(h) == 0) return(NULL)
    tibble::tibble(t = as.numeric(h$t), p = as.numeric(h$p))
  }

  raw <- pm_stitch(lapply(seq_len(length(bounds) - 1), function(i) {
    fetch_chunk(bounds[i], bounds[i + 1])
  }))
  if (NROW(raw) == 0) {
    cli::cli_abort("No price history returned for token {.val {token_id}} in this window.")
  }

  as_event_prices(
    tibble::tibble(
      time = as.POSIXct(raw$t, tz = "UTC"),
      q = raw$p
    ),
    time = "time", price = "q",
    market_id = market_id %||% paste0("polymarket:", substr(token_id, 1, 12), "..."),
    event_date = event_date
  )
}

#' Collapse intraday event prices to one daily snapshot
#'
#' Takes the last observation at or before `snapshot_hour` (local time in
#' `tz`) of each calendar day — the convention used to align prediction
#' market prices with market closes (e.g. 16:00 New York time for US
#' equities).
#'
#' @details
#' Seconds are deliberately truncated when comparing against the cutoff:
#' an observation stamped `16:00:59` still counts as `16:00`. API bars are
#' typically stamped a few seconds after the full hour they represent, so
#' minute precision is the robust convention for bar data. The stored
#' `event_date` attribute is coerced to `Date` to match the collapsed
#' time scale.
#'
#' @param x An `event_prices` object with intraday timestamps.
#' @param tz Character time zone of the snapshot (default
#'   `"America/New_York"`).
#' @param snapshot_hour Numeric, snapshot cutoff hour in `tz` (default 16).
#'
#' @return An `event_prices` object with one (Date-typed) observation per
#'   day.
#'
#' @examples
#' \dontrun{
#' ep <- pm_prices(tok, from = "2024-06-01", to = "2024-11-06")
#' daily <- pm_daily(ep)
#' }
#' @export
pm_daily <- function(x, tz = "America/New_York", snapshot_hour = 16) {
  x <- as_event_prices(x)
  if (!inherits(x$time, "POSIXct")) {
    cli::cli_abort("{.fn pm_daily} expects intraday {.cls POSIXct} timestamps.")
  }
  lt <- as.POSIXlt(x$time, tz = tz)
  d <- tibble::tibble(
    date = as.Date(lt),
    hr = lt$hour + lt$min / 60,
    q = x$q
  )
  daily <- d |>
    dplyr::filter(hr <= snapshot_hour) |>
    dplyr::group_by(date) |>
    dplyr::slice_max(hr, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(time = date, q)
  ed <- attr(x, "event_date")
  if (!is.null(ed) && inherits(ed, "POSIXct")) {
    ed <- as.Date(ed, tz = attr(ed, "tzone") %||% "UTC")
  }
  as_event_prices(
    daily,
    time = "time", price = "q",
    clip = attr(x, "clip"),
    market_id = attr(x, "market_id"),
    event_date = ed
  )
}
