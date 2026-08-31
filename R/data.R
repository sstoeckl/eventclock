#' Brexit 2016 event probabilities
#'
#' Daily probabilities of the United Kingdom remaining in the European
#' Union, derived from betting quotes across multiple platforms, from
#' 2016-02-26 to referendum day 2016-06-23 (119 calendar days including
#' weekends). `q_leave = 1 - q_remain` is the series used in the
#' accompanying working paper.
#'
#' @format A tibble with 119 rows and 3 columns:
#' \describe{
#'   \item{date}{Calendar date (`Date`).}
#'   \item{q_remain}{Probability of Remain, from betting quotes.}
#'   \item{q_leave}{Probability of Leave, `1 - q_remain`.}
#' }
#' @source Betting-market state prices as in Hanke, M., Poulsen, R., and
#'   Weissensteiner, A. (2018), "Event-Related Exchange-Rate Forecasts
#'   Combining Information from Betting Quotes and Option Prices",
#'   *Journal of Financial and Quantitative Analysis* 53(6), 2663–2683.
#'   Used in Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper),
#'   "Learning Before Scheduled Events: Prediction Markets, State Prices,
#'   and Option Valuation".
#' @examples
#' data(brexit2016)
#' ep <- as_event_prices(brexit2016, time = "date", price = "q_leave",
#'                       event_date = as.Date("2016-06-23"))
#' event_clock(ep, from = as.Date("2016-05-24"))
"brexit2016"

#' U.S. presidential election 2016 event probabilities
#'
#' Daily win probabilities for the 2016 U.S. presidential election
#' candidates, derived from betting quotes, from 2016-03-10 to 2016-11-09
#' (237 calendar days including weekends). Candidate columns are
#' probabilities on the 0-1 scale; they need not sum to one across
#' candidates (they are raw one-sided quotes). The Trump series is the one
#' used in the accompanying working paper.
#'
#' @format A tibble with 237 rows and 9 columns:
#' \describe{
#'   \item{date}{Calendar date (`Date`).}
#'   \item{trump, clinton, sanders, cruz, kasich, biden, mcmullin}{Win
#'     probabilities per candidate.}
#'   \item{volume}{Betting volume (exchange units).}
#' }
#' @source See [brexit2016].
#' @examples
#' data(us2016)
#' ep <- as_event_prices(us2016, time = "date", price = "trump",
#'                       event_date = as.Date("2016-11-08"))
#' event_clock(ep, from = as.Date("2016-10-10"))
"us2016"

#' Polymarket 2024 U.S. presidential election prices (hourly)
#'
#' Hourly prices of the Polymarket contract "Will Donald Trump win the
#' 2024 US presidential election?" (the "Yes" outcome token), June to
#' November 2024, downloaded from the public CLOB API with [pm_prices()].
#' The claim price is the U.S.-dollar-numeraire event state price — the
#' state-price-implied event probability up to discounting. This dataset
#' powers the intraday examples; rebuild it any time with the script in
#' `data-raw/`.
#'
#' @format A tibble with hourly rows and 2 columns:
#' \describe{
#'   \item{time}{Timestamp (`POSIXct`, UTC).}
#'   \item{q}{Traded probability of the "Yes" outcome.}
#' }
#' @source Polymarket public CLOB API,
#'   \url{https://clob.polymarket.com/prices-history}, event
#'   `presidential-election-winner-2024`.
#' @examples
#' data(polymarket2024)
#' ep <- as_event_prices(polymarket2024,
#'   market_id = "Polymarket: Trump wins 2024",
#'   event_date = as.POSIXct("2024-11-05", tz = "UTC")
#' )
#' plot_clock(event_clock_path(ep))
"polymarket2024"

#' Scheduled FOMC meetings 2021-2027
#'
#' Decision dates (second day of the two-day meeting) of the scheduled
#' FOMC meetings, with a flag for meetings accompanied by a Summary of
#' Economic Projections and press conference. Unscheduled meetings and
#' notation votes are excluded. Companion calendar for
#' [q_from_ffutures()].
#'
#' @format A tibble with 56 rows and 3 columns:
#' \describe{
#'   \item{decision_date}{Decision day (`Date`).}
#'   \item{year}{Calendar year (integer).}
#'   \item{sep}{`TRUE` for meetings with a Summary of Economic
#'     Projections.}
#' }
#' @source Federal Reserve Board, "Meeting calendars and information",
#'   \url{https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm}
#'   (retrieved 2026-08-30).
#' @examples
#' data(fomc_meetings)
#' subset(fomc_meetings, year == 2024)
"fomc_meetings"

#' Trump Media & Technology Group (DJT) daily prices, June-November 2024
#'
#' Daily closing prices, adjusted closes, and volume of the stock most
#' directly exposed to the 2024 U.S. presidential election, matching the
#' window of [polymarket2024]. Companion asset series for the event-beta
#' example in [event_beta()].
#'
#' @format A tibble with 126 rows and 4 columns:
#' \describe{
#'   \item{date}{Trading day (`Date`).}
#'   \item{close}{Closing price (USD).}
#'   \item{adjusted}{Split/dividend-adjusted close (USD).}
#'   \item{volume}{Trading volume (shares).}
#' }
#' @source Yahoo Finance (via the `tidyquant` package), ticker `DJT`,
#'   retrieved 2026-08-30. See `data-raw/03-fetch-djt.R`.
#' @examples
#' data(djt2024)
#' data(polymarket2024)
#' event_beta(djt2024, pm_daily(as_event_prices(polymarket2024)))
"djt2024"
