# ---------------------------------------------------------------------------
# Additional price -> q converters: every traded event state price maps into
# the same q -> logit -> A pipeline.
# ---------------------------------------------------------------------------

#' Meeting-implied probability from a fed funds futures price
#'
#' Converts the price of the 30-day fed funds futures contract for a
#' meeting month into the probability of a rate move of size `step`,
#' using the standard month-average extraction: the contract settles on
#' the monthly average effective rate, the pre-meeting rate applies
#' through the decision day, so
#' \deqn{r_{post} = \frac{M\,\bar r - d\, r_{pre}}{M - d}, \qquad
#'   q = \frac{r_{post} - r_{pre}}{step},}
#' with \eqn{\bar r = 100 - \mathrm{price}}, `M` calendar days in the
#' month, and `d` the day of the month of the decision.
#'
#' @details
#' `q` is the probability of a single move of `step` under a two-point
#' assumption (no change vs. one move). Values outside \eqn{[0,1]}
#' indicate that more than one step (or a move of the opposite sign) is
#' priced: `q = 1.6` means 25bp fully priced plus a 60% chance of a
#' second step; negative values indicate a priced move of the opposite
#' sign. Flag, don't drop. For a decision on the last day(s) of the
#' month the denominator degenerates — use the next-month contract.
#' Intermeeting moves and months with two meetings violate the two-point
#' assumption; flag such periods separately.
#'
#' @param price Futures price(s), e.g. `95.21`.
#' @param pre_rate Effective rate prevailing before the meeting (percent,
#'   e.g. `5.33`).
#' @param meeting_date Decision date(s) (`Date`); see [fomc_meetings].
#' @param step Assumed move size in percentage points (default `0.25`).
#'
#' @return A tibble with columns `meeting_date`, `implied_avg`,
#'   `implied_post`, `delta_rate`, and `q` (probability of one `step`
#'   move; sign of `delta_rate` gives the direction).
#'
#' @examples
#' # decision on the 15th of a 30-day month, pre-meeting rate 5.33%,
#' # futures at 94.79 -> a 25bp cut is priced with ~96% probability
#' q_from_ffutures(94.79, pre_rate = 5.33,
#'                 meeting_date = as.Date("2024-09-15"), step = -0.25)
#' @seealso [fomc_meetings], [q_from_price()], [q_from_deal_spread()]
#' @export
q_from_ffutures <- function(price, pre_rate, meeting_date, step = 0.25) {
  stopifnot(is.numeric(price), is.numeric(pre_rate), inherits(meeting_date, "Date"),
            is.numeric(step), all(step != 0))
  n <- max(length(price), length(pre_rate), length(meeting_date), length(step))
  price <- rep_len(price, n)
  pre_rate <- rep_len(pre_rate, n)
  meeting_date <- rep(meeting_date, length.out = n)
  step <- rep_len(step, n)

  som <- as.Date(format(meeting_date, "%Y-%m-01"))
  last_of_month <- as.Date(format(som + 32, "%Y-%m-01")) - 1
  M <- as.numeric(format(last_of_month, "%d"))
  d <- as.numeric(format(meeting_date, "%d"))
  if (any(M - d < 3)) {
    cli::cli_warn("Decision within the last 3 days of the month: the extraction is ill-conditioned; use the next-month contract.")
  }
  avg <- 100 - price
  post <- (M * avg - d * pre_rate) / (M - d)
  delta <- post - pre_rate
  q <- delta / step
  n_out <- sum(!is.na(q) & (q < -1e-9 | q > 1 + 1e-9))
  if (n_out > 0) {
    cli::cli_warn("{n_out} implied probabilit{?y/ies} outside [0, 1]: more than one step (or the opposite sign) is priced; see the two-point caveat in {.code ?q_from_ffutures}.")
  }
  tibble::tibble(
    meeting_date = meeting_date, implied_avg = avg,
    implied_post = post, delta_rate = delta, q = q
  )
}

#' Completion probability from a merger-arbitrage spread
#'
#' The target's traded price is itself an event state price: with offer
#' value `offer` on completion and `fallback` value on deal break,
#' \deqn{q = \frac{P - F}{O\,D - F},} where `D` discounts the offer to
#' today (deal-horizon discount factor, default 1).
#'
#' @param target Target's traded price(s).
#' @param offer Offer value per share on completion.
#' @param fallback Estimated standalone ("deal-break") value per share.
#' @param discount Discount factor applied to the offer (default 1).
#'
#' @return Numeric vector of completion probabilities. Values outside
#'   \eqn{[0,1]} trigger a warning (check `fallback`), but are returned
#'   unchanged (flag, don't drop).
#'
#' @examples
#' # target at 47, cash offer 50, fallback 35: q = 0.8
#' q_from_deal_spread(47, offer = 50, fallback = 35)
#' @seealso [q_from_price()], [q_from_ffutures()]
#' @export
q_from_deal_spread <- function(target, offer, fallback, discount = 1) {
  stopifnot(is.numeric(target), is.numeric(offer), is.numeric(fallback),
            is.numeric(discount))
  denom <- offer * discount - fallback
  if (any(!is.na(denom) & denom <= 0)) {
    cli::cli_abort("{.arg offer} (discounted) must exceed {.arg fallback}.")
  }
  q <- (target - fallback) / denom
  n_out <- sum(!is.na(q) & (q < -1e-9 | q > 1 + 1e-9))
  if (n_out > 0) {
    cli::cli_warn("{n_out} completion probabilit{?y/ies} outside [0, 1]; check {.arg fallback}.")
  }
  q
}
