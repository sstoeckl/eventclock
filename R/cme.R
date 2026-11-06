# ---------------------------------------------------------------------------
# Exchange option settlements: CME Globex instrument definitions and daily
# statistics (as normalized by Databento's GLBX.MDP3 dataset) turned into
# option surfaces with Black (1976) implied volatilities.
# Base-R kernels; no exchange data ships with the package.
# ---------------------------------------------------------------------------

# Column `nm` of `d`, or NULL. Avoids the partial matching of `$`.
col_or_null <- function(d, nm) if (nm %in% names(d)) d[[nm]] else NULL

# Numeric coercion that tolerates files in which every column arrived as
# text, 64-bit integers, and the INT64_MAX / UINT64_MAX "undefined" sentinels.
as_num <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "integer64")) {
    rlang::check_installed("bit64", reason = "to read 64-bit integer columns.")
    x <- as.character(x)
  }
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) x <- suppressWarnings(as.numeric(trimws(x)))
  x <- as.numeric(x)
  x[!is.finite(x) | abs(x) >= 9.2e18] <- NA_real_
  x
}

# Timestamps as POSIXct (UTC) from POSIXct, Date, nanoseconds since the
# epoch (numeric or text), or ISO 8601 text with optional fractional
# seconds and a trailing "Z".
as_utc_time <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "POSIXct")) {
    attr(x, "tzone") <- "UTC"
    return(x)
  }
  if (inherits(x, "Date")) return(as.POSIXct(format(x), tz = "UTC"))
  if (inherits(x, "integer64") || is.numeric(x)) {
    return(as.POSIXct(as_num(x) / 1e9, origin = "1970-01-01", tz = "UTC"))
  }
  s <- trimws(as.character(x))
  out <- rep(NA_real_, length(s))
  ns <- !is.na(s) & grepl("^[0-9]+$", s)
  if (any(ns)) out[ns] <- as_num(s[ns]) / 1e9
  iso <- !is.na(s) & !ns & nzchar(s)
  if (any(iso)) {
    v <- sub("Z$", "", s[iso])
    v <- sub("T", " ", v, fixed = TRUE)
    v <- sub("(\\d{2}:\\d{2}:\\d{2})\\.\\d+", "\\1", v)
    long <- nchar(v) > 10
    tt <- rep(NA_real_, length(v))
    tt[long] <- as.numeric(as.POSIXct(v[long], format = "%Y-%m-%d %H:%M:%S", tz = "UTC"))
    tt[!long] <- as.numeric(as.POSIXct(v[!long], format = "%Y-%m-%d", tz = "UTC"))
    out[iso] <- tt
  }
  as.POSIXct(out, origin = "1970-01-01", tz = "UTC")
}

# Expand directories, read Parquet (via arrow) or CSV files, and return a
# list of data frames, one per file; data frames pass through unchanged.
dbn_parts <- function(x, cols) {
  if (is.data.frame(x)) return(list(x))
  if (!is.character(x)) {
    cli::cli_abort("Supply a {.cls data.frame} or path(s) to Parquet/CSV files.")
  }
  files <- unlist(lapply(x, function(p) {
    if (dir.exists(p)) {
      list.files(p, pattern = "\\.(parquet|csv)$", full.names = TRUE,
                 recursive = TRUE, ignore.case = TRUE)
    } else p
  }))
  if (length(files) == 0) cli::cli_abort("No Parquet or CSV files found.")
  miss <- files[!file.exists(files)]
  if (length(miss)) cli::cli_abort("File{?s} not found: {.file {miss}}.")
  lapply(files, function(f) {
    if (grepl("\\.parquet$", f, ignore.case = TRUE)) {
      rlang::check_installed("arrow", reason = "to read Parquet files.")
      nm <- names(arrow::open_dataset(f))
      as.data.frame(arrow::read_parquet(f, col_select = dplyr::all_of(intersect(cols, nm))))
    } else {
      d <- utils::read.csv(f, colClasses = "character", check.names = FALSE)
      d[, intersect(cols, names(d)), drop = FALSE]
    }
  })
}

def_cols <- c("ts_recv", "ts_event", "instrument_id", "raw_symbol", "asset",
              "instrument_class", "cfi", "expiration", "strike_price",
              "underlying_id", "underlying", "currency", "unit_of_measure",
              "security_update_action")

normalize_definitions <- function(d) {
  miss <- setdiff(c("instrument_id", "instrument_class", "expiration"), names(d))
  if (length(miss)) cli::cli_abort("Definitions lack column{?s} {.field {miss}}.")
  chr <- function(nm) {
    v <- col_or_null(d, nm)
    if (is.null(v)) rep(NA_character_, nrow(d)) else as.character(v)
  }
  num <- function(nm) as_num(col_or_null(d, nm)) %||% rep(NA_real_, nrow(d))
  ts <- as_utc_time(col_or_null(d, "ts_recv") %||% col_or_null(d, "ts_event")) %||%
    as.POSIXct(rep(NA_real_, nrow(d)), origin = "1970-01-01", tz = "UTC")
  tibble::tibble(
    instrument_id = num("instrument_id"),
    ts_recv = ts,
    raw_symbol = chr("raw_symbol"),
    asset = chr("asset"),
    instrument_class = trimws(chr("instrument_class")),
    cfi = chr("cfi"),
    expiration = as_utc_time(d[["expiration"]]),
    strike = num("strike_price"),
    underlying_id = num("underlying_id"),
    underlying = chr("underlying"),
    currency = chr("currency"),
    unit_of_measure = chr("unit_of_measure"),
    security_update_action = chr("security_update_action")
  )
}

#' Read CME Globex instrument definitions
#'
#' Reads instrument definitions in Databento's `definition` schema for the
#' CME Globex dataset (`GLBX.MDP3`) and keeps one row per instrument
#' *phase*: the period during which an instrument identifier denotes one
#' contract. Every column is coerced by content, not by its stored type,
#' so files in which all columns arrived as text (which happens when one
#' column holds an unexpected value) read the same as typed files.
#'
#' @details
#' **Reused identifiers.** The exchange assigns an expired or deleted
#' contract's `instrument_id` to a new contract, sometimes within days
#' and across classes (a call can become a put, a spread an option). A
#' phase is a run of records for one identifier with the same
#' `raw_symbol` (or, without symbols, the same class, strike, and
#' expiration date), in receive-time order. A modification that only
#' changes, say, the expiration time stays in the same phase; a deletion
#' record (`security_update_action = "D"`) ends it. Each phase reports
#' the attributes of its most recent record and is valid from its first
#' record (`valid_from`) until the next phase of the same identifier
#' starts or the deletion arrives (`valid_to`; `NA` while open).
#' [cme_option_surfaces()] assigns each daily statistic to the phase in
#' force on its trading date.
#'
#' **Exercise style.** For options, the third character of the ISO 10962
#' CFI code is the exercise style (`A` American, `E` European). On CME
#' currency options it differs across products and years — for example,
#' weekly and monthly contracts on the same future can differ — so it is
#' read per instrument rather than assumed.
#'
#' **Expiration.** `expiration` is the last eligible trade time (UTC) as
#' published by the exchange. Expiry times differ across products and
#' years, so use this field rather than a fixed clock time.
#'
#' @param x A `data.frame` of definition records, or path(s) to Parquet
#'   (needs the arrow package) or CSV files, or directories containing
#'   them.
#' @param classes Instrument classes to keep: `"C"` call, `"P"` put, `"F"`
#'   future (default). Spreads (`"S"`, `"T"`, `"M"`) are dropped unless
#'   listed.
#'
#' @return A tibble of class `cme_definitions`, one row per instrument
#'   phase, with columns `instrument_id`, `valid_from`, `valid_to`
#'   (POSIXct, UTC), `deleted` (logical: the phase ended with a deletion
#'   record), `ts_recv` (receive time of the phase's most recent record),
#'   `raw_symbol`, `asset` (product code, e.g. `"6M"`), `instrument_class`,
#'   `type` (`"call"`, `"put"`, `"future"`, or `NA`), `exercise`
#'   (`"american"`, `"european"`, or `NA`), `cfi`, `expiration` (POSIXct,
#'   UTC), `strike`, `underlying_id`, `underlying`, `currency`,
#'   `unit_of_measure`.
#'
#' @references Databento documentation of the instrument-definition schema
#'   and of the CME Globex MDP 3.0 dataset (GLBX.MDP3),
#'   <https://databento.com/docs/venues-and-datasets/glbx-mdp3>.
#' @examples
#' defs <- data.frame(
#'   ts_recv = c("2016-06-01T00:00:00Z", "2016-06-02T00:00:00Z", "2016-06-01T00:00:00Z"),
#'   instrument_id = c("11", "11", "20"),
#'   raw_symbol = c("6BN6 C1450", "6BN6 C1450", "6BN6"),
#'   asset = c("6B", "6B", "6B"),
#'   instrument_class = c("C", "C", "F"),
#'   cfi = c("OCAFPS", "OCAFPS", "FFCXSX"),
#'   expiration = c("2016-07-08T19:00:00Z", "2016-07-08T19:00:00Z", "2016-09-19T14:16:00Z"),
#'   strike_price = c("1.45", "1.45", ""),
#'   underlying_id = c("20", "20", "0")
#' )
#' cme_definitions(defs)
#' @seealso [cme_statistics()], [cme_option_surfaces()].
#' @export
cme_definitions <- function(x, classes = c("C", "P", "F")) {
  parts <- dbn_parts(x, def_cols)
  out <- dplyr::bind_rows(lapply(parts, normalize_definitions))
  out <- out[!is.na(out$instrument_id), , drop = FALSE]
  o <- order(out$instrument_id, as.numeric(out$ts_recv), na.last = FALSE)
  out <- out[o, , drop = FALSE]
  out <- definition_phases(out)
  out <- out[out$instrument_class %in% classes, , drop = FALSE]
  out$type <- unname(c(C = "call", P = "put", F = "future")[out$instrument_class])
  ex <- toupper(substr(out$cfi, 3, 3))
  out$exercise <- ifelse(out$type %in% c("call", "put"),
                         unname(c(A = "american", E = "european")[ex]),
                         NA_character_)
  out <- out[, c("instrument_id", "valid_from", "valid_to", "deleted",
                 "ts_recv", "raw_symbol", "asset", "instrument_class", "type",
                 "exercise", "cfi", "expiration", "strike", "underlying_id",
                 "underlying", "currency", "unit_of_measure")]
  class(out) <- c("cme_definitions", class(tibble::tibble()))
  out
}

# Collapse definition records (sorted by identifier and receive time) to
# one row per phase: a run of records with the same contract identity,
# ended by a change of identity or by a deletion record.
definition_phases <- function(d) {
  n <- nrow(d)
  if (n == 0) {
    d$valid_from <- d$valid_to <- d$ts_recv
    d$deleted <- logical(0)
    return(d[, setdiff(names(d), "security_update_action")])
  }
  ident <- ifelse(is.na(d$raw_symbol) | !nzchar(trimws(d$raw_symbol)),
                  paste(d$instrument_class, d$strike,
                        format(as.Date(d$expiration, tz = "UTC"))),
                  trimws(d$raw_symbol))
  del <- d$security_update_action %in% "D"
  same_id <- c(FALSE, d$instrument_id[-1] == d$instrument_id[-n])
  new_phase <- !same_id | c(TRUE, ident[-1] != ident[-n]) | c(FALSE, del[-n])
  first <- which(new_phase)
  last <- c(first[-1] - 1L, n)
  # a deletion can only be a phase's last record; attributes come from
  # the latest record before it
  deleted <- del[last]
  attr_row <- ifelse(deleted, last - 1L, last)
  nxt_same <- c(d$instrument_id[first[-1]] == d$instrument_id[first[-length(first)]], FALSE)
  valid_to <- rep(NA_real_, length(first))
  valid_to[nxt_same] <- as.numeric(d$ts_recv[first[-1]])[nxt_same[-length(first)]]
  valid_to[deleted] <- as.numeric(d$ts_recv[last[deleted]])
  keep <- attr_row >= first
  out <- d[attr_row[keep], setdiff(names(d), "security_update_action"), drop = FALSE]
  out$valid_from <- d$ts_recv[first[keep]]
  out$valid_to <- as.POSIXct(valid_to[keep], origin = "1970-01-01", tz = "UTC")
  out$deleted <- deleted[keep]
  out
}

# Row of `defs` (an instrument phase) in force for each (instrument,
# trading date), or NA: the latest phase of that identifier whose first
# record falls on or before the date, provided the date precedes the
# next phase (or falls on or before the deletion day) and does not lie
# after the contract's expiration date. Dates are compared in UTC, the
# calendar of the daily definition snapshots.
cme_phase_index <- function(id, date, defs) {
  if (length(id) == 0) return(integer(0))
  day <- function(nm) {
    t <- col_or_null(defs, nm)
    if (is.null(t)) rep(NA_real_, nrow(defs)) else as.numeric(as.Date(t, tz = "UTC"))
  }
  from <- day("valid_from")
  to <- day("valid_to")
  deleted <- col_or_null(defs, "deleted") %||% rep(FALSE, nrow(defs))
  deleted[is.na(deleted)] <- FALSE
  expiry <- day("expiration")
  ids <- sort(unique(defs$instrument_id))
  rp <- match(defs$instrument_id, ids)
  rs <- match(id, ids)
  d <- as.numeric(date)
  # rank of the identifier, then day: exact as a double for any date
  # within +-5 million days
  kp <- rp * 1e7 + ifelse(is.na(from), -4e6, from)
  ks <- rs * 1e7 + d
  o <- order(kp)
  pos <- findInterval(ks, kp[o])
  idx <- rep(NA_integer_, length(ks))
  hit <- !is.na(pos) & pos > 0
  idx[hit] <- o[pos[hit]]
  idx[!is.na(idx) & rp[idx] != rs] <- NA_integer_
  ok <- !is.na(idx)
  i <- idx[ok]
  dd <- d[ok]
  bad <- (!is.na(to[i]) & (dd > to[i] | (dd == to[i] & !deleted[i]))) |
    (!is.na(expiry[i]) & dd > expiry[i])
  idx[which(ok)[bad]] <- NA_integer_
  idx
}

stat_cols <- c("ts_recv", "ts_event", "instrument_id", "ts_ref", "price",
               "quantity", "sequence", "stat_type", "update_action",
               "stat_flags")

normalize_statistics <- function(s, types, price_scale) {
  miss <- setdiff(c("instrument_id", "stat_type", "ts_event"), names(s))
  if (length(miss)) cli::cli_abort("Statistics lack column{?s} {.field {miss}}.")
  st <- as_num(s[["stat_type"]])
  keep <- !is.na(st) & st %in% types
  s <- s[keep, , drop = FALSE]
  n <- nrow(s)
  num <- function(nm, default) {
    v <- as_num(col_or_null(s, nm))
    if (is.null(v)) rep(default, n) else v
  }
  ts_event <- as_utc_time(s[["ts_event"]])
  flags <- as.integer(num("stat_flags", 0))
  flags[is.na(flags)] <- 0L
  tibble::tibble(
    instrument_id = as_num(s[["instrument_id"]]),
    stat_type = st[keep],
    ts_recv = as_utc_time(col_or_null(s, "ts_recv")) %||% ts_event,
    ts_event = ts_event,
    ts_ref = as_utc_time(col_or_null(s, "ts_ref")) %||%
      as.POSIXct(rep(NA_real_, n), origin = "1970-01-01", tz = "UTC"),
    price = num("price", NA_real_) * price_scale,
    quantity = num("quantity", NA_real_),
    sequence = num("sequence", NA_real_),
    update_action = num("update_action", 1),
    stat_flags = flags
  )
}

# Trading date of a daily statistic: the exchange's trading reference date
# (date precision, not localized); if absent, the publication date in the
# exchange time zone, with weekend publications assigned to the Friday
# session.
cme_trading_date <- function(ts_ref, ts_event, tz) {
  d <- as.Date(ts_ref, tz = "UTC")
  miss <- is.na(d) & !is.na(ts_event)
  if (any(miss)) {
    e <- as.Date(ts_event[miss], tz = tz)
    wd <- as.POSIXlt(e)$wday
    e[wd == 6] <- e[wd == 6] - 1
    e[wd == 0] <- e[wd == 0] - 2
    d[miss] <- e
  }
  d
}

# Last record per (instrument, date) after ordering by `ord` columns.
last_per_day <- function(d, ...) {
  if (nrow(d) == 0) return(d)
  o <- do.call(order, c(list(d$instrument_id, as.numeric(d$date)), list(...)))
  d <- d[o, , drop = FALSE]
  d[!duplicated(d[, c("instrument_id", "date")], fromLast = TRUE), , drop = FALSE]
}

#' Daily settlement prices and open interest from CME Globex statistics
#'
#' Reduces Databento `statistics` records for the CME Globex dataset
#' (`GLBX.MDP3`) to one row per instrument and trading date: the
#' settlement price, its status, open interest, and cleared volume.
#'
#' @details
#' **Which settlement.** The exchange publishes several settlement
#' messages per instrument and session: preliminary values first, the
#' final value last (and occasionally re-sends). Bit 0 of `stat_flags`
#' marks a final price (bit 1: actual rather than theoretical; bit 2:
#' rounding to the trading tick, or an unrounded preliminary price for
#' products that are not rounded; bit 3: intraday). For each instrument
#' and trading date the function keeps the *last final* message; if no
#' final message exists, it keeps the last preliminary one and sets
#' `settle_final = FALSE`.
#'
#' **Trading date.** The trading date is the exchange's trading reference
#' date (`ts_ref`), used at date precision without time-zone conversion.
#' Where `ts_ref` is missing, the publication time `ts_event` is converted
#' to the exchange time zone and weekend publications are assigned to the
#' preceding Friday session; messages with a reference date take
#' precedence over such fallback messages.
#'
#' **Deletions and undefined values.** A record with `update_action = 2`
#' deletes the statistic: earlier records for the same instrument, type,
#' and date are discarded. Quantities equal to the 64-bit integer maximum
#' mean "undefined" and become `NA`.
#'
#' @param x A `data.frame` of statistics records, or path(s) to Parquet
#'   (needs the arrow package) or CSV files, or directories.
#' @param tz Exchange time zone used only for the `ts_ref` fallback
#'   (default `"America/Chicago"`).
#' @param price_scale Multiplier applied to `price` (default 1, for files
#'   with decimal prices; use `1e-9` for raw fixed-precision integers).
#'
#' @return A tibble of class `cme_statistics` with columns
#'   `instrument_id`, `date` (trading date), `settle`, `settle_final`
#'   (logical), `settle_flags`, `open_interest`, `volume` (cleared
#'   volume).
#'
#' @references Databento documentation of the statistics schema and of
#'   the CME Globex MDP 3.0 dataset (GLBX.MDP3),
#'   <https://databento.com/docs/schemas-and-data-formats/statistics>.
#' @examples
#' st <- data.frame(
#'   instrument_id = 11,
#'   ts_event = as.POSIXct(c("2016-06-01 19:00", "2016-06-01 21:40",
#'                           "2016-06-01 23:40"), tz = "UTC"),
#'   ts_ref = as.POSIXct("2016-06-01", tz = "UTC"),
#'   stat_type = 3,
#'   price = c(0.0101, 0.0102, 0.0102),
#'   stat_flags = c(4L, 2L, 3L)   # preliminary, actual preliminary, final
#' )
#' cme_statistics(st)
#' @seealso [cme_definitions()], [cme_option_surfaces()].
#' @export
cme_statistics <- function(x, tz = "America/Chicago", price_scale = 1) {
  parts <- dbn_parts(x, stat_cols)
  st <- dplyr::bind_rows(lapply(parts, normalize_statistics,
                                types = c(3, 6, 9), price_scale = price_scale))
  st <- st[!is.na(st$instrument_id), , drop = FALSE]
  st$date <- cme_trading_date(st$ts_ref, st$ts_event, tz)
  st <- st[!is.na(st$date), , drop = FALSE]

  # deletions cancel earlier records of the same instrument, type, and date
  o <- order(st$instrument_id, st$stat_type, as.numeric(st$date),
             as.numeric(st$ts_recv), st$sequence)
  st <- st[o, , drop = FALSE]
  if (any(st$update_action == 2, na.rm = TRUE)) {
    g <- cumsum(c(TRUE, diff(st$instrument_id) != 0 | diff(st$stat_type) != 0 |
                  diff(as.numeric(st$date)) != 0))
    idx <- seq_len(nrow(st))
    dpos <- ifelse(st$update_action %in% 2, idx, 0)
    lastdel <- stats::ave(dpos, g, FUN = max)
    st <- st[idx > lastdel, , drop = FALSE]
  }

  s3 <- st[st$stat_type == 3, , drop = FALSE]
  s3$final <- bitwAnd(s3$stat_flags, 1L) == 1L
  s3$has_ref <- !is.na(s3$ts_ref)
  s3 <- last_per_day(s3, s3$final, s3$has_ref, as.numeric(s3$ts_recv), s3$sequence)
  settle <- tibble::tibble(instrument_id = s3$instrument_id, date = s3$date,
                           settle = s3$price, settle_final = s3$final,
                           settle_flags = s3$stat_flags)

  qty <- function(type, name) {
    d <- st[st$stat_type == type, , drop = FALSE]
    d <- last_per_day(d, !is.na(d$ts_ref), as.numeric(d$ts_recv), d$sequence)
    out <- tibble::tibble(instrument_id = d$instrument_id, date = d$date,
                          v = d$quantity)
    names(out)[3] <- name
    out
  }
  out <- merge(settle, qty(9, "open_interest"), by = c("instrument_id", "date"),
               all = TRUE)
  out <- merge(out, qty(6, "volume"), by = c("instrument_id", "date"), all = TRUE)
  out <- out[order(out$instrument_id, out$date), , drop = FALSE]
  out <- tibble::as_tibble(out)
  class(out) <- c("cme_statistics", class(tibble::tibble()))
  out
}

# Total implied dispersion of an undiscounted call on a unit forward,
# vectorized bisection (prices outside the no-arbitrage interval -> NA).
black_iv_total_vec <- function(price, K, upper = 10, iter = 100) {
  n <- length(price)
  K <- rep_len(K, n)
  out <- rep(NA_real_, n)
  ok <- is.finite(price) & is.finite(K) & K > 0 &
    price > pmax(1 - K, 0) + 1e-14 & price < 1 - 1e-14
  if (!any(ok)) return(out)
  p <- price[ok]
  kk <- K[ok]
  lo <- rep(0, length(p))
  hi <- rep(upper, length(p))
  for (i in seq_len(iter)) {
    mid <- (lo + hi) / 2
    up <- black_call(1, kk, mid) > p
    hi[up] <- mid[up]
    lo[!up] <- mid[!up]
  }
  s <- (lo + hi) / 2
  s[black_call(1, kk, upper) < p] <- NA_real_
  out[ok] <- s
  out
}

#' Option surfaces from CME Globex settlements
#'
#' Joins option and futures settlement prices to their instrument
#' definitions and returns one row per valuation date, expiry, and strike,
#' with the futures price as forward, time to expiry, Black (1976)
#' implied volatilities, vega, log-forward moneyness, open interest, and a
#' put-call parity diagnostic. The output feeds [ec_theta_fit()] (columns
#' `surface`, `k`, `iv`, `tau`, and `q` when `x` is supplied),
#' [ec_mix_iv_pre()], and [ec_quiet_library()] directly.
#'
#' @details
#' **Which contract.** Instrument identifiers are reused (see
#' [cme_definitions()]), so each daily statistic is attributed to the
#' definition phase in force on its trading date: the latest phase of its
#' identifier that started on or before that date (UTC calendar of the
#' daily definition snapshots), provided the next phase has not started,
#' the phase was not deleted earlier, and the contract had not expired
#' (trading date after the expiration date). Statistics outside every
#' phase are dropped, including settlements dated before a contract's
#' first definition record, such as the theoretical reference settlement
#' the exchange sends with a new listing, dated the previous session.
#'
#' **Forward and timing.** Each option is matched to its underlying future
#' through `underlying_id`; the forward is that future's settlement on the
#' same trading date. Where both symbols are published, the future's
#' `raw_symbol` must equal the option's `underlying`; otherwise the
#' forward is missing. The valuation time is `settle_time` on the trading
#' date in time zone `tz` (14:00 Chicago time, the settlement time of CME
#' currency futures and options); time to expiry `tau` is measured in years
#' of 365 days from the valuation time to the published `expiration`.
#' Options with `tau <= 0` are dropped.
#'
#' **Implied volatility.** Prices are discounted with
#' \eqn{e^{-r\tau}} (`rate`) and inverted in the Black (1976) model.
#' `iv_call` and `iv_put` are both reported; `iv` is the out-of-the-money
#' side (calls at or above the forward, puts below it). Settlements at or
#' below `min_price`, or outside the no-arbitrage interval, give `NA`.
#' For American-style options (see `exercise`) the Black volatility is a
#' European approximation; quantify the early-exercise premium separately
#' (for example on a binomial tree) before relying on in-the-money quotes.
#'
#' **Inverted quotes.** CME quotes currency futures in U.S. dollars per
#' unit of foreign currency (for example `6M`: dollars per peso). With
#' `invert = TRUE` all quantities are re-expressed per dollar: forward
#' \eqn{1/F}, strike \eqn{1/K}, calls and puts swap roles, and prices are
#' converted with \eqn{C'(1/K) = P(K)/(FK)} and \eqn{P'(1/K) = C(K)/(FK)}.
#' Implied volatilities are unchanged and log-moneyness changes sign.
#'
#' **Parity diagnostic.** `parity_gap` is
#' \eqn{(C - P)/e^{-r\tau} - (F - K)}, in forward price units, and
#' `parity_gap_rel` divides it by \eqn{F}; `F_parity` is the forward
#' implied by the call-put pair. Large gaps flag stale or mismatched
#' settlements (American options can deviate slightly by construction).
#'
#' @param definitions Output of [cme_definitions()], or anything it
#'   accepts.
#' @param statistics Output of [cme_statistics()], or anything it accepts.
#' @param assets Optional product codes of the options to keep (for
#'   example `c("6M", "1M", "2M")`).
#' @param from,to Optional first and last trading date.
#' @param rate Continuously compounded annual interest rate for
#'   discounting: a number (default 0) or a function of `(date, tau)`
#'   returning one rate per row.
#' @param settle_time,tz Valuation clock time and time zone (default
#'   `"14:00"`, `"America/Chicago"`).
#' @param invert Logical; express prices per unit of the quote currency
#'   (see Details). Default `FALSE`.
#' @param min_price Settlements at or below this value get no implied
#'   volatility (default 0).
#' @param x Optional `event_prices` object; adds `q`, the last event
#'   probability at or before each valuation time.
#'
#' @return A tibble with one row per trading date, product, expiry, and
#'   strike: `surface` (identifier `asset date expiry`), `date`,
#'   `valuation`, `asset`, `underlying`, `expiry`, `exercise`, `tau`, `F`,
#'   `F_final`, `strike`, `k` (\eqn{\log(K/F)}), `call`, `put`,
#'   `call_final`, `put_final`, `oi_call`, `oi_put`, `iv`, `iv_call`,
#'   `iv_put`, `otm` (side used for `iv`), `vega` (price change per unit
#'   of annualized volatility), `parity_gap`, `parity_gap_rel`,
#'   `F_parity`, `call_id`, `put_id`, `call_symbol`, `put_symbol`
#'   (exchange symbols of the contracts used; with `invert = TRUE` the
#'   original put is the new call), and `q` if `x` is supplied.
#'
#' @references Black, F. (1976). The pricing of commodity contracts.
#'   *Journal of Financial Economics* 3, 167--179.
#' @examples
#' # one future and a call/put pair, priced at 10% volatility
#' F0 <- 0.0540; K <- 0.0545; tau <- 30 / 365
#' s <- 0.10 * sqrt(tau)
#' d1 <- (log(F0 / K) + s^2 / 2) / s
#' cl <- F0 * pnorm(d1) - K * pnorm(d1 - s)
#' pt <- cl - (F0 - K)
#' defs <- data.frame(
#'   instrument_id = 1:3, instrument_class = c("F", "C", "P"),
#'   asset = "6M", cfi = c("FFCXSX", "OCEFPS", "OPEFPS"),
#'   expiration = as.POSIXct("2016-07-01 19:00", tz = "UTC") +
#'     c(80, 30, 30) * 86400,
#'   strike_price = c(NA, K, K), underlying_id = c(0, 1, 1)
#' )
#' st <- data.frame(
#'   instrument_id = 1:3, stat_type = 3, stat_flags = 3L,
#'   ts_event = as.POSIXct("2016-07-01 22:00", tz = "UTC"),
#'   ts_ref = as.POSIXct("2016-07-01", tz = "UTC"),
#'   price = c(F0, cl, pt)
#' )
#' cme_option_surfaces(defs, st)[, c("date", "tau", "F", "k", "iv", "parity_gap")]
#' @seealso [cme_definitions()], [cme_statistics()], [ec_theta_fit()],
#'   [ec_quiet_library()].
#' @export
cme_option_surfaces <- function(definitions, statistics, assets = NULL,
                                from = NULL, to = NULL, rate = 0,
                                settle_time = "14:00",
                                tz = "America/Chicago", invert = FALSE,
                                min_price = 0, x = NULL) {
  defs <- if (inherits(definitions, "cme_definitions")) definitions else
    cme_definitions(definitions)
  st <- if (inherits(statistics, "cme_statistics")) statistics else
    cme_statistics(statistics, tz = tz)
  stopifnot(is.numeric(rate) || is.function(rate), is.logical(invert))

  is_opt <- defs$type %in% c("call", "put") &
    (is.null(assets) | defs$asset %in% assets)
  if (!any(is_opt)) cli::cli_abort("No option definitions found (check {.arg assets}).")

  # each daily statistic belongs to the definition phase in force on its date
  so <- st[st$instrument_id %in% defs$instrument_id[is_opt],
           c("instrument_id", "date", "settle", "settle_final", "open_interest")]
  if (!is.null(from)) so <- so[so$date >= as.Date(from), , drop = FALSE]
  if (!is.null(to)) so <- so[so$date <= as.Date(to), , drop = FALSE]
  so <- so[!is.na(so$settle), , drop = FALSE]
  i <- cme_phase_index(so$instrument_id, so$date, defs)
  keep <- !is.na(i)
  keep[keep] <- is_opt[i[keep]]
  so <- so[keep, , drop = FALSE]
  i <- i[keep]
  if (nrow(so) == 0) cli::cli_abort("No option settlements in the requested window.")
  for (v in c("raw_symbol", "asset", "type", "exercise", "expiration", "strike",
              "underlying_id", "underlying")) {
    so[[v]] <- defs[[v]][i]
  }
  sf <- st[st$instrument_id %in% defs$instrument_id[defs$type %in% "future"] &
             !is.na(st$settle), , drop = FALSE]
  jf <- cme_phase_index(sf$instrument_id, sf$date, defs)
  fkeep <- !is.na(jf)
  fkeep[fkeep] <- defs$type[jf[fkeep]] %in% "future"
  sf <- sf[fkeep, , drop = FALSE]
  sf_symbol <- defs$raw_symbol[jf[fkeep]]
  j <- match(paste(so$underlying_id, so$date), paste(sf$instrument_id, sf$date))
  # where both symbols are published, the future must be the option's underlying
  clash <- !is.na(j) & !is.na(so$underlying) & nzchar(so$underlying) &
    !is.na(sf_symbol[j]) & so$underlying != sf_symbol[j]
  j[clash] <- NA_integer_
  so$F <- sf$settle[j]
  so$F_final <- sf$settle_final[j]

  ud <- sort(unique(so$date))
  so$valuation <- as.POSIXct(paste(format(ud), settle_time), tz = tz)[match(so$date, ud)]
  so$tau <- as.numeric(difftime(so$expiration, so$valuation, units = "days")) / 365
  so <- so[is.finite(so$tau) & so$tau > 0, , drop = FALSE]
  if (nrow(so) == 0) cli::cli_abort("No unexpired options in the requested window.")

  key <- paste(format(so$date), so$asset, as.numeric(so$expiration),
               formatC(so$strike, digits = 15, format = "g"))
  w <- so[!duplicated(key), c("date", "valuation", "asset", "underlying",
                              "expiration", "exercise", "tau", "F", "F_final",
                              "strike")]
  wkey <- key[!duplicated(key)]
  side <- function(tp) {
    s <- so[so$type == tp, , drop = FALSE]
    m <- match(wkey, key[so$type == tp])
    list(id = s$instrument_id[m], sym = s$raw_symbol[m], p = s$settle[m],
         fin = s$settle_final[m], oi = s$open_interest[m])
  }
  cs <- side("call")
  ps <- side("put")

  Fv <- w$F
  K <- w$strike
  call <- cs$p
  put <- ps$p
  if (invert) {
    fk <- Fv * K
    call_new <- put / fk
    put_new <- call / fk
    call <- call_new
    put <- put_new
    Fv <- 1 / Fv
    K <- 1 / K
    tmp <- cs
    cs <- ps
    ps <- tmp
  }
  r <- if (is.function(rate)) rate(w$date, w$tau) else rep_len(rate, nrow(w))
  DF <- exp(-r * w$tau)
  kF <- K / Fv
  cn <- call / (DF * Fv)
  pn <- put / (DF * Fv)
  sq <- sqrt(w$tau)
  iv_call <- black_iv_total_vec(cn, kF) / sq
  iv_put <- black_iv_total_vec(pn + 1 - kF, kF) / sq
  iv_call[!is.na(call) & call <= min_price] <- NA_real_
  iv_put[!is.na(put) & put <= min_price] <- NA_real_
  otm <- ifelse(kF >= 1, "call", "put")
  iv <- ifelse(otm == "call", iv_call, iv_put)
  k <- log(kF)
  d1 <- (-k + iv^2 * w$tau / 2) / (iv * sq)
  vega <- DF * Fv * stats::dnorm(d1) * sq
  gap <- (call - put) / DF - (Fv - K)

  expiry_day <- format(w$expiration, "%Y-%m-%d", tz = tz)
  out <- tibble::tibble(
    surface = paste(w$asset, format(w$date), expiry_day),
    date = w$date, valuation = w$valuation, asset = w$asset,
    underlying = w$underlying, expiry = w$expiration, exercise = w$exercise,
    tau = w$tau, F = Fv, F_final = w$F_final, strike = K, k = k,
    call = call, put = put, call_final = cs$fin, put_final = ps$fin,
    oi_call = cs$oi, oi_put = ps$oi,
    iv = iv, iv_call = iv_call, iv_put = iv_put, otm = otm, vega = vega,
    parity_gap = gap, parity_gap_rel = gap / Fv,
    F_parity = K + (call - put) / DF,
    call_id = cs$id, put_id = ps$id,
    call_symbol = cs$sym, put_symbol = ps$sym
  )
  if (!is.null(x)) {
    x <- as_event_prices(x)
    xt <- x[!is.na(x$q), , drop = FALSE]
    xt <- xt[order(xt$time), , drop = FALSE]
    at <- if (inherits(xt$time, "Date")) {
      as.numeric(as.Date(out$valuation, tz = tz))
    } else {
      as.numeric(out$valuation)
    }
    ii <- findInterval(at, as.numeric(xt$time))
    out$q <- NA_real_
    out$q[ii > 0] <- xt$q[ii[ii > 0]]
  }
  out <- out[order(out$date, out$asset, out$expiry, out$strike), , drop = FALSE]
  if (any(out$exercise %in% "american")) {
    cli::cli_inform(
      c(i = "Some options are American-style; their Black implied volatilities treat them as European."),
      .frequency = "once", .frequency_id = "eventclock_cme_american"
    )
  }
  out
}
