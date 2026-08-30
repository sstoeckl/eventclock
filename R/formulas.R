# ---------------------------------------------------------------------------
# The formula book: closed-form objects in (q, A).
# Throughout: q = current event probability, L = logit(q), A = event-clock
# time remaining until resolution. All functions are vectorized and pure.
# ---------------------------------------------------------------------------

#' Moments of the terminal probability and log-odds
#'
#' Closed-form moments of the resolution-date log-odds \eqn{L_T} and event
#' probability \eqn{q_T} implied by the exact logistic-normal transition
#' law (see [ec_transition_density()]), given current probability `q` and
#' event-clock time `A` until resolution.
#'
#' @details
#' Exact results: \eqn{E[q_T] = q} (the martingale property — free of `A`),
#' \eqn{E[L_T] = L + (q - 1/2)A},
#' \eqn{Var(L_T) = A + q(1-q)A^2}, and the third central moment
#' \eqn{m_3(L_T) = q(1-q)(1-2q)A^3}.
#' The variance of \eqn{q_T} is reported in its small-`A` approximation
#' \eqn{Var(q_T) \approx (q(1-q))^2 A} together with the exact upper bound
#' \eqn{\min\{A/16,\; q(1-q)\}}.
#'
#' @param q Numeric vector of current event probabilities in \eqn{(0,1)}.
#' @param A Numeric vector of event-clock time (non-negative).
#'
#' @return A tibble with columns `q`, `A`, `L`, `E_qT`, `E_LT`, `var_LT`,
#'   `sd_LT`, `m3_LT`, `var_qT` (approximation), and `var_qT_bound`.
#'
#' @examples
#' # Brexit, two weeks before the referendum: q = 0.195, A = 0.166
#' ec_moments(0.195, 0.166)
#' @export
ec_moments <- function(q, A) {
  check_prob(q); check_nonneg(A)
  L <- ec_logit(q)
  var_LT <- A + q * (1 - q) * A^2
  tibble::tibble(
    q = q, A = A, L = L,
    E_qT = q,
    E_LT = L + (q - 0.5) * A,
    var_LT = var_LT,
    sd_LT = sqrt(var_LT),
    m3_LT = q * (1 - q) * (1 - 2 * q) * A^3,
    var_qT = (q * (1 - q))^2 * A,
    var_qT_bound = pmin(A / 16, q * (1 - q))
  )
}

#' Exceedance probability of the terminal event probability
#'
#' Exact probability that the resolution-date event probability exceeds a
#' threshold, \eqn{P(q_T > x)}, under the logistic-normal transition law:
#' \deqn{P(q_T > x) = q\,\Phi\!\left(\frac{L + A/2 - \mathrm{logit}\,x}
#'   {\sqrt A}\right) + (1-q)\,\Phi\!\left(\frac{L - A/2 -
#'   \mathrm{logit}\,x}{\sqrt A}\right).}
#'
#' @inheritParams ec_moments
#' @param x Numeric vector of thresholds in \eqn{(0,1)}.
#'
#' @return Numeric vector of probabilities.
#'
#' @examples
#' # probability that the market ends up above 50% by resolution
#' ec_exceedance(0.5, q = 0.195, A = 0.166)
#' @export
ec_exceedance <- function(x, q, A) {
  check_prob(x, "x"); check_prob(q); check_nonneg(A)
  n <- max(length(x), length(q), length(A))
  x <- rep_len(x, n); q <- rep_len(q, n); A <- rep_len(A, n)
  L <- ec_logit(q)
  lx <- ec_logit(x)
  out <- q * stats::pnorm((L + A / 2 - lx) / sqrt(A)) +
    (1 - q) * stats::pnorm((L - A / 2 - lx) / sqrt(A))
  # A = 0: degenerate at the current q
  deg <- !is.na(A) & A == 0
  if (any(deg)) out[deg] <- as.numeric(q[deg] > x[deg])
  out
}

#' Typical revision of the event probability
#'
#' Folded-normal approximation of the expected absolute revision of the
#' event probability until resolution:
#' \eqn{E|q_T - q| \approx q(1-q)\sqrt{2A/\pi}}.
#'
#' @inheritParams ec_moments
#' @return Numeric vector.
#' @examples
#' # Brexit two weeks out: about 5 probability points
#' ec_revision(0.195, 0.166)
#' @export
ec_revision <- function(q, A) {
  check_prob(q); check_nonneg(A)
  q * (1 - q) * sqrt(2 * A / pi)
}

#' ATM claim on the event factor
#'
#' Bachelier-style approximation of the value of an at-the-money claim on
#' the event factor: \eqn{\approx |\Delta\eta|\, q(1-q)\sqrt{A/(2\pi)}},
#' where \eqn{\Delta\eta} is the gap between the outcome-conditional mean
#' multipliers of the underlying (the *event exposure*).
#'
#' @inheritParams ec_moments
#' @param deta Numeric, the event exposure \eqn{\Delta\eta = \eta_1 -
#'   \eta_2}.
#' @return Numeric vector (same units as the underlying's return).
#' @examples
#' ec_atm_event_call(q = 0.195, A = 0.166, deta = -0.012)
#' @export
ec_atm_event_call <- function(q, A, deta) {
  check_prob(q); check_nonneg(A)
  abs(deta) * q * (1 - q) * sqrt(A / (2 * pi))
}

#' Effective volatility ahead of a scheduled event
#'
#' First-order decomposition of pre-event implied volatility into the
#' no-learning component and the learning component:
#' \eqn{\sigma_{\mathrm{eff}} = \sqrt{\sigma^2 + (\Delta\eta\,
#' q(1-q))^2 A / T}}.
#'
#' @inheritParams ec_atm_event_call
#' @param sigma Numeric, annualized no-learning volatility (decimal, e.g.
#'   `0.19` for 19%).
#' @param tenor Numeric, option tenor \eqn{T - t} in years.
#' @return Numeric vector, annualized effective volatility (decimal).
#' @examples
#' ec_sigma_eff(sigma = 0.19326, deta = -0.099, q = 0.172, A = 0.046,
#'              tenor = 14 / 365)
#' @export
ec_sigma_eff <- function(sigma, deta, q, A, tenor) {
  check_prob(q); check_nonneg(A)
  stopifnot(all(is.na(tenor) | tenor > 0))
  sqrt(sigma^2 + (deta * q * (1 - q))^2 * A / tenor)
}

#' Variance share of event learning
#'
#' Fraction of total return variance over the tenor attributable to
#' learning about the event:
#' \eqn{(1 + \sigma^2 T / v)^{-1}} with
#' \eqn{v = (\Delta\eta\, q(1-q))^2 A}.
#'
#' @inheritParams ec_sigma_eff
#' @return Numeric vector in \eqn{[0, 1]}.
#' @examples
#' # Brexit 2W: about 0.2%; US election 2W: about 1.1%
#' ec_variance_share(sigma = 0.10590, deta = -0.012, q = 0.195,
#'                   A = 0.166, tenor = 14 / 365)
#' ec_variance_share(sigma = 0.19326, deta = -0.099, q = 0.172,
#'                   A = 0.046, tenor = 14 / 365)
#' @export
ec_variance_share <- function(sigma, deta, q, A, tenor) {
  check_prob(q); check_nonneg(A)
  v <- (deta * q * (1 - q))^2 * A
  1 / (1 + sigma^2 * tenor / v)
}

#' Rule of thumb: implied-volatility contribution of event learning
#'
#' The paper's four-lever rule of thumb for the ATM implied-volatility
#' contribution of learning ahead of a scheduled event:
#' \deqn{\Delta \mathrm{IV} \approx \frac{[\Delta\eta\; q(1-q)]^2\,
#'   A}{2\,\sigma\,(T-t)}.}
#'
#' @details
#' The four levers: the event exposure \eqn{\Delta\eta} (squared), the
#' movability of the probability \eqn{q(1-q)} (squared), the event-clock
#' time \eqn{A}, and the dilution by the no-learning volatility and tenor.
#'
#' **Units and the \eqn{\sigma} convention.** With `sigma` as decimal
#' annualized volatility and `tenor` in years, the result is a decimal
#' volatility increment; multiply by 100 for annualized percentage points.
#' Use the *tenor-specific no-learning ATM volatility* for `sigma`; using a
#' different maturity's volatility changes the result mechanically (e.g.
#' the Brexit 2W contribution is 0.007 IV points with the 2W ATM of 10.59%
#' but 0.008 with 9.325%).
#'
#' @inheritParams ec_sigma_eff
#' @return Numeric vector, the IV contribution in decimal volatility units.
#' @examples
#' # US election 2016, 2W: about 0.062 annualized IV percentage points
#' 100 * ec_iv_rule(deta = -0.099, q = 0.172, A = 0.046,
#'                  sigma = 0.19326, tenor = 14 / 365)
#' @export
ec_iv_rule <- function(deta, q, A, sigma, tenor) {
  check_prob(q); check_nonneg(A)
  stopifnot(all(is.na(tenor) | tenor > 0), all(is.na(sigma) | sigma > 0))
  (deta * q * (1 - q))^2 * A / (2 * sigma * tenor)
}

#' Event-clock time needed to reach near-certainty
#'
#' Rule of thumb for the amount of event-clock time required for the
#' market to move from its current probability `q` to a target probability
#' `target` (conditional on the corresponding outcome):
#' \eqn{A^* \approx 2(\mathrm{logit}\, x^* - L)}.
#'
#' @inheritParams ec_moments
#' @param target Numeric vector of target probabilities in \eqn{(0,1)}.
#' @return Numeric vector \eqn{A^*}.
#' @examples
#' # from 19.5% to "90% sure": A* is about 7.2 -- roughly 40 times the
#' # clock time measured over the final two pre-referendum weeks (0.166)
#' ec_target_clock(q = 0.195, target = 0.9)
#' @export
ec_target_clock <- function(q, target) {
  check_prob(q); check_prob(target, "target")
  2 * (ec_logit(target) - ec_logit(q))
}
