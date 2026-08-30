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
#' transition law over `n_steps` clock increments: the outcome `J` is
#' drawn once per path, and conditional on `J` the log-odds follow a
#' Gaussian random walk with drift \eqn{\pm a_i/2} and variance
#' \eqn{a_i} per step, where \eqn{\sum_i a_i = A}. Unconditionally, each
#' step is Bayes-consistent and \eqn{q_t} is a martingale.
#'
#' @details
#' With `jump_share > 0`, information arrives *lumpily*: a fraction
#' `jump_share` of total clock time `A` is concentrated in `n_jumps`
#' randomly placed steps (scheduled sub-events: debates, data releases),
#' and the rest flows evenly. Every step still follows the exact
#' Bayes-consistent transition, so all closed-form results continue to
#' hold; lumpiness only changes *when* the clock ticks. This is the
#' testbed for the jump-robust estimator variants of [event_clock()].
#'
#' @param n_paths Integer, number of paths.
#' @param n_steps Integer, number of clock increments per path.
#' @inheritParams ec_moments
#' @param jump_share Numeric in \eqn{[0, 1)}: share of `A` arriving in
#'   jump steps (default 0 = smooth information flow).
#' @param n_jumps Integer, number of jump steps per path (default 1;
#'   only used when `jump_share > 0`).
#'
#' @return A tibble with columns `path`, `step` (0..`n_steps`), `t_frac`
#'   (fraction of calendar steps elapsed), `J`, `L`, `q`, and `is_jump`
#'   (`TRUE` for the jump steps; `FALSE` for step 0).
#'
#' @examples
#' set.seed(1)
#' paths <- ec_simulate_path(n_paths = 3, n_steps = 50, q = 0.3, A = 1)
#' # realized clock of one path is close to A:
#' sum(diff(subset(paths, path == 1)$L)^2)
#'
#' # lumpy information: half of A arrives in two jump steps
#' lumpy <- ec_simulate_path(2, 50, q = 0.3, A = 1,
#'                           jump_share = 0.5, n_jumps = 2)
#' @export
ec_simulate_path <- function(n_paths, n_steps, q, A,
                             jump_share = 0, n_jumps = 1) {
  stopifnot(
    length(q) == 1, length(A) == 1, n_steps >= 1,
    jump_share >= 0, jump_share < 1, n_jumps >= 1
  )
  check_prob(q); check_nonneg(A)
  n_jumps <- as.integer(n_jumps)
  if (jump_share > 0 && n_jumps >= n_steps) {
    cli::cli_abort("{.arg n_jumps} must be smaller than {.arg n_steps}.")
  }
  L0 <- ec_logit(q)
  out <- lapply(seq_len(n_paths), function(i) {
    a <- rep(A * (1 - jump_share) / n_steps, n_steps)
    is_jump <- rep(FALSE, n_steps)
    if (jump_share > 0) {
      pos <- sample.int(n_steps, n_jumps)
      a[pos] <- a[pos] + A * jump_share / n_jumps
      is_jump[pos] <- TRUE
    }
    J <- stats::rbinom(1, 1, q)
    incr <- (J - 0.5) * a + sqrt(a) * stats::rnorm(n_steps)
    L <- c(L0, L0 + cumsum(incr))
    tibble::tibble(
      path = i, step = 0:n_steps, t_frac = (0:n_steps) / n_steps,
      J = J, L = L, q = ec_ilogit(L), is_jump = c(FALSE, is_jump)
    )
  })
  dplyr::bind_rows(out)
}
