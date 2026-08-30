#' Convert traded state prices into risk-adjusted event probabilities
#'
#' Traded event claims (prediction-market contracts, betting quotes, binary
#' options) pay one unit at resolution. Their price is therefore a
#' *discounted* probability: \eqn{\psi_t = D(t,\tau)\, q_t}, where
#' \eqn{D(t,\tau)} is the discount factor of the payout numeraire. This
#' function undoes that discounting, or alternatively removes the bookmaker
#' overround by normalizing with the sum of all outcome prices in the book.
#'
#' @details
#' Two normalizations are available:
#'
#' * `method = "discount"` (default): \eqn{q = \psi / D}. Under
#'   deterministic interest rates the result is the risk-adjusted
#'   (risk-neutral) event probability; with stochastic rates it is a
#'   forward-measure probability. At short horizons the correction is a few
#'   basis points but it is systematic.
#' * `method = "overround"`: \eqn{q_j = \psi_j / \sum_i \psi_i}, where
#'   `book` supplies \eqn{\sum_i \psi_i}. Use this only when the raw quotes
#'   include a bookmaker margin that has *not* already been removed by the
#'   data provider. Note that series which are already margin-adjusted must
#'   not be normalized twice.
#'
#' A level distortion that is (approximately) constant on the log-odds scale
#' — a constant discount factor, a constant state-price tilt — shifts
#' \eqn{L_t = \mathrm{logit}(q_t)} by a constant and therefore leaves the
#' event clock unchanged: quadratic variation is invariant to level shifts.
#' Getting the level of `q` exactly right matters for probability
#' statements, not for [event_clock()].
#'
#' @param price Numeric vector of raw claim prices \eqn{\psi_t} (on the 0-1
#'   scale; rescale percent quotes first).
#' @param discount Numeric scalar or vector, the discount factor
#'   \eqn{D(t,\tau) \in (0, 1]} applicable to the payout (default 1, i.e.
#'   no discounting).
#' @param book Numeric scalar or vector, the sum of prices over all
#'   outcomes of the same market. Required for `method = "overround"`.
#' @param method Character, `"discount"` or `"overround"`.
#'
#' @return A numeric vector of probabilities `q`. Values outside \eqn{[0,1]}
#'   trigger a warning (they indicate a wrong `discount`/`book`), but are
#'   returned unchanged so that the caller can flag rather than drop them.
#'
#' @examples
#' # a 90-day claim priced at 0.19 with a 2% (annualized) short rate
#' q_from_price(0.19, discount = exp(-0.02 * 90 / 365))
#'
#' # two-sided book with overround: prices sum to 1.04
#' q_from_price(0.52, book = 0.52 + 0.52, method = "overround")
#'
#' @seealso [as_event_prices()], which applies this conversion while
#'   constructing an `event_prices` object.
#' @export
q_from_price <- function(price, discount = 1, book = NULL,
                         method = c("discount", "overround")) {
  method <- rlang::arg_match(method)
  stopifnot(is.numeric(price))
  q <- switch(method,
    discount = {
      stopifnot(is.numeric(discount))
      if (any(!is.na(discount) & (discount <= 0 | discount > 1))) {
        cli::cli_abort("{.arg discount} must lie in (0, 1].")
      }
      price / discount
    },
    overround = {
      if (is.null(book)) {
        cli::cli_abort("{.arg book} (sum of all outcome prices) is required for {.code method = \"overround\"}.")
      }
      stopifnot(is.numeric(book))
      price / book
    }
  )
  n_out <- sum(!is.na(q) & (q < 0 | q > 1))
  if (n_out > 0) {
    cli::cli_warn("{n_out} normalized probabilit{?y/ies} fall{?s/} outside [0, 1]; check {.arg discount}/{.arg book}.")
  }
  q
}
