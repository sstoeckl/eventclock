# ---------------------------------------------------------------------------
# The exact logistic-normal transition law:
#   L_T = L_t + (1{J=1} - 1/2) A + sqrt(A) * zeta,   zeta ~ N(0,1) indep. of J
# Bayes consistency pins the drift to +/- A/2 (drift m and variance v of the
# conditional Gaussian must satisfy 2m/v = 1, i.e. m = v/2 = A/2).
# ---------------------------------------------------------------------------

#' Density of the terminal log-odds
#'
#' Exact density of the resolution-date log-odds \eqn{L_T} given current
#' probability `q` and event-clock time `A`: a two-component Gaussian
#' mixture with means \eqn{L \pm A/2}, common variance `A`, and weights
#' \eqn{(q, 1-q)}.
#'
#' @param l Numeric vector of evaluation points (log-odds scale).
#' @inheritParams ec_moments
#'
#' @return Numeric vector of density values.
#'
#' @examples
#' grid <- seq(-4, 2, length.out = 200)
#' dens <- ec_transition_density(grid, q = 0.195, A = 0.166)
#' # integrates to one:
#' sum(dens) * diff(grid)[1]
#' @export
ec_transition_density <- function(l, q, A) {
  check_prob(q); check_nonneg(A)
  if (any(!is.na(A) & A == 0)) {
    cli::cli_abort("{.arg A} must be strictly positive for a density (A = 0 is degenerate).")
  }
  L <- ec_logit(q)
  s <- sqrt(A)
  q * stats::dnorm(l, mean = L + A / 2, sd = s) +
    (1 - q) * stats::dnorm(l, mean = L - A / 2, sd = s)
}

#' Simulate the exact transition to resolution
#'
#' Draws the outcome indicator \eqn{J \sim \mathrm{Bernoulli}(q)} and the
#' terminal log-odds from the exact transition law
#' \eqn{L_T = L + (1\{J=1\} - 1/2)A + \sqrt{A}\,\zeta}. The martingale
#' property \eqn{E[q_T] = q} holds by construction (Bayes consistency of
#' the \eqn{\pm A/2} drift).
#'
#' @param n Integer, number of draws.
#' @inheritParams ec_moments
#'
#' @return A tibble with columns `J` (0/1 outcome), `zeta`, `L_T`, and
#'   `q_T`.
#'
#' @examples
#' set.seed(1)
#' sim <- ec_simulate(1e4, q = 0.195, A = 0.166)
#' mean(sim$q_T) # close to 0.195
#' mean(sim$J)   # close to 0.195
#' @export
ec_simulate <- function(n, q, A) {
  stopifnot(length(q) == 1, length(A) == 1)
  check_prob(q); check_nonneg(A)
  L <- ec_logit(q)
  J <- stats::rbinom(n, 1, q)
  zeta <- stats::rnorm(n)
  L_T <- L + (J - 0.5) * A + sqrt(A) * zeta
  tibble::tibble(J = J, zeta = zeta, L_T = L_T, q_T = ec_ilogit(L_T))
}

#' Simulate event-clock consistent probability paths
#'
#' Simulates paths of the event probability by composing the exact
#' transition law over `n_steps` equal clock increments \eqn{a = A /
#' n_{steps}}: the outcome `J` is drawn once per path, and conditional on
#' `J` the log-odds follow a Gaussian random walk with drift
#' \eqn{\pm a/2} and variance `a` per step. Unconditionally, each step is
#' Bayes-consistent and \eqn{q_t} is a martingale.
#'
#' @param n_paths Integer, number of paths.
#' @param n_steps Integer, number of clock increments per path.
#' @inheritParams ec_moments
#'
#' @return A tibble with columns `path`, `step` (0..`n_steps`), `t_frac`
#'   (fraction of clock time elapsed), `J`, `L`, and `q`.
#'
#' @examples
#' set.seed(1)
#' paths <- ec_simulate_path(n_paths = 3, n_steps = 50, q = 0.3, A = 1)
#' # realized clock of one path is close to A:
#' sum(diff(subset(paths, path == 1)$L)^2)
#' @export
ec_simulate_path <- function(n_paths, n_steps, q, A) {
  stopifnot(length(q) == 1, length(A) == 1, n_steps >= 1)
  check_prob(q); check_nonneg(A)
  a <- A / n_steps
  L0 <- ec_logit(q)
  out <- lapply(seq_len(n_paths), function(i) {
    J <- stats::rbinom(1, 1, q)
    incr <- (J - 0.5) * a + sqrt(a) * stats::rnorm(n_steps)
    L <- c(L0, L0 + cumsum(incr))
    tibble::tibble(
      path = i, step = 0:n_steps, t_frac = (0:n_steps) / n_steps,
      J = J, L = L, q = ec_ilogit(L)
    )
  })
  dplyr::bind_rows(out)
}
