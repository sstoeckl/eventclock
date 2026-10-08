# ---------------------------------------------------------------------------
# Event-spanning options: the two-component lognormal event mixture, model
# implied volatilities, and estimation of the outcome-conditional mean ratio
# (the "event exposure" theta) from event-spanning option surfaces.
# Base-R numerical kernels; no proprietary data enters the package.
# ---------------------------------------------------------------------------

# Undiscounted Black (1976) call on a forward f with strike K and *total*
# (non-annualized) dispersion s. All arguments same length.
black_call <- function(f, K, s) {
  out <- pmax(f - K, 0)
  ok <- is.finite(f) & is.finite(K) & is.finite(s) & s > 0 & f > 0 & K > 0
  if (any(ok)) {
    d1 <- (log(f[ok] / K[ok]) + s[ok]^2 / 2) / s[ok]
    d2 <- d1 - s[ok]
    out[ok] <- f[ok] * stats::pnorm(d1) - K[ok] * stats::pnorm(d2)
  }
  out
}

# Invert the Black call on a unit forward for the total implied dispersion.
# Returns NA (with no error) where the price is outside the no-arbitrage
# interval (intrinsic, forward).
black_iv_total <- function(price, K) {
  n <- length(price)
  out <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    p <- price[i]
    if (!is.finite(p) || !is.finite(K[i])) next
    intr <- max(1 - K[i], 0)
    if (p <= intr + 1e-14 || p >= 1 - 1e-14) next
    root <- try(
      stats::uniroot(
        function(s) black_call(1, K[i], s) - p,
        lower = 1e-10, upper = 20, tol = 1e-12
      ),
      silent = TRUE
    )
    if (!inherits(root, "try-error")) out[i] <- root$root
  }
  out
}

# Outcome-conditional mean multipliers under the adding-up normalization
# q m1 + (1 - q) m2 = 1, parametrized by theta = log(m1 / m2).
mix_means <- function(q, theta) {
  rho <- exp(theta)
  denom <- q * rho + (1 - q)
  list(m1 = rho / denom, m2 = 1 / denom)
}

#' Option prices and implied volatility under the event mixture
#'
#' Prices European options on an event-exposed asset whose terminal value,
#' normalized by its forward, is the two-component lognormal event mixture
#' of the accompanying working paper: with probability \eqn{q} (outcome 1)
#' the gross event multiplier is lognormal with conditional mean \eqn{m_1}
#' and total dispersion \eqn{s_1}, with probability \eqn{1-q} (outcome 2)
#' lognormal with mean \eqn{m_2} and dispersion \eqn{s_2}. The
#' outcome-conditional means are parametrized by the event exposure
#' \deqn{\theta = \log(m_1 / m_2)}
#' and pinned down by the pricing-measure adding-up (scale) normalization
#' \eqn{q\,m_1 + (1-q)\,m_2 = 1}, so that the mixture has forward value one.
#'
#' `ec_mix_price()` returns undiscounted forward-normalized option prices
#' (multiply by the discount factor and the forward to obtain currency
#' prices). `ec_mix_iv()` returns the Black *total* implied dispersion of
#' the mixture price; divide by \eqn{\sqrt{\tau}} (time to expiry in years)
#' for an annualized implied volatility.
#'
#' @details
#' **Sign identification.** At \eqn{q = 1/2} the mixture is observationally
#' symmetric in \eqn{(\theta, s_1, s_2) \mapsto (-\theta, s_2, s_1)}: option
#' prices alone cannot tell which outcome the asset favors. Take the sign
#' from an external source — e.g. the returns-based exposure of
#' [event_beta()] — when `q` is close to one half.
#'
#' @param k Log-forward moneyness \eqn{\log(K/F)} (vector).
#' @param q State-price-implied probability of outcome 1.
#' @param theta Event exposure \eqn{\log(m_1/m_2)}; `theta = 0` collapses to
#'   a single lognormal.
#' @param s1,s2 Outcome-conditional *total* dispersions (standard deviation
#'   of the conditional log multiplier over the remaining life; annualized
#'   volatility times \eqn{\sqrt{\tau}}).
#' @param type `"call"` or `"put"`.
#'
#' @return `ec_mix_price()`: numeric vector of forward-normalized prices.
#'   `ec_mix_iv()`: numeric vector of total implied dispersions (`NA` where
#'   the price is at an arbitrage bound).
#'
#' @references Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper),
#'   "Learning Before Scheduled Events: Prediction Markets, State Prices,
#'   and Option Valuation".
#'
#' @examples
#' # DJT-style exposure: theta = log(2.7), q = 0.55
#' k <- seq(-0.8, 0.8, by = 0.2)
#' ec_mix_iv(k, q = 0.55, theta = log(2.7), s1 = 0.6, s2 = 0.8)
#' @seealso [ec_theta_fit()] to estimate `theta` from observed surfaces,
#'   [ec_theta_hump()] for the first-order variance-hump estimator.
#' @export
ec_mix_price <- function(k, q, theta, s1, s2, type = c("call", "put")) {
  type <- match.arg(type)
  r <- ec_recycle(k = k, q = q, theta = theta, s1 = s1, s2 = s2)
  check_prob(r$q)
  check_nonneg(r$s1, "s1")
  check_nonneg(r$s2, "s2")
  m <- mix_means(r$q, r$theta)
  K <- exp(r$k)
  price <- r$q * black_call(m$m1, K, r$s1) +
    (1 - r$q) * black_call(m$m2, K, r$s2)
  if (type == "put") price <- price - 1 + K
  price
}

#' @rdname ec_mix_price
#' @export
ec_mix_iv <- function(k, q, theta, s1, s2) {
  r <- ec_recycle(k = k, q = q, theta = theta, s1 = s1, s2 = s2)
  price <- ec_mix_price(r$k, r$q, r$theta, r$s1, r$s2, type = "call")
  black_iv_total(price, exp(r$k))
}

#' Convert a call-equivalent delta grid to log-moneyness
#'
#' Standardized option surfaces are usually quoted on a delta grid. Under
#' the Black model with unit forward and total dispersion `s`, the strike
#' with (call) delta \eqn{\Delta} has log-forward moneyness
#' \deqn{k = s^2/2 - s\,\Phi^{-1}(\Delta).}
#' Put deltas convert as call-equivalent \eqn{\Delta = 1 + \delta_{put}}.
#'
#' @param delta Call-equivalent delta in (0, 1).
#' @param s Total dispersion at the node (annualized volatility times
#'   \eqn{\sqrt{\tau}}).
#' @return Log-forward moneyness \eqn{k = \log(K/F)}.
#' @examples
#' ec_delta_to_k(c(0.25, 0.5, 0.75), s = 0.3)
#' @export
ec_delta_to_k <- function(delta, s) {
  r <- ec_recycle(delta = delta, s = s)
  if (any(r$delta <= 0 | r$delta >= 1, na.rm = TRUE)) {
    cli::cli_abort("{.arg delta} must lie strictly between 0 and 1.")
  }
  check_nonneg(r$s, "s")
  r$s^2 / 2 - r$s * stats::qnorm(r$delta)
}

#' First-order event exposure from the spanning variance hump
#'
#' For the two-point event mixture, the event contributes exactly
#' \eqn{q(1-q)\,\theta_{\log}^2} to the *total* variance of the terminal
#' log multiplier, where \eqn{\theta_{\log}} is the difference of the
#' conditional log means (equal to \eqn{\theta} when the conditional
#' dispersions coincide). Reading an event-spanning option's total ATM
#' variance in excess of its no-event baseline as that contribution gives
#' the moment-based estimator
#' \deqn{|\hat\theta| = \sqrt{\Delta V / (q(1-q))}.}
#'
#' This is the quick first-pass estimator: it needs only the total-variance
#' hump of the spanning maturity (computed in variance units, not in
#' annualized volatilities) and the event probability. It identifies the
#' *magnitude* only; take the sign from [event_beta()] or from the smile
#' asymmetry via the full fit in [ec_theta_fit()].
#'
#' @param dvar Event-induced increment in total variance of the spanning
#'   expiry (total variance of the spanning maturity minus the no-event
#'   baseline, both as \eqn{\sigma^2 \tau}).
#' @param q State-price-implied probability of outcome 1.
#' @return \eqn{|\hat\theta|}; `NA` (with a warning) where `dvar` is
#'   negative.
#' @examples
#' # a 10-point IV hump at 40% baseline vol, one month to expiry, q = 0.5
#' tau <- 1 / 12
#' dvar <- (0.50^2 - 0.40^2) * tau
#' ec_theta_hump(dvar, q = 0.5)
#' @seealso [ec_theta_fit()] for the full surface fit.
#' @export
ec_theta_hump <- function(dvar, q) {
  r <- ec_recycle(dvar = dvar, q = q)
  check_prob(r$q)
  out <- rep(NA_real_, length(r$dvar))
  neg <- is.finite(r$dvar) & r$dvar < 0
  if (any(neg)) {
    cli::cli_warn(
      "{sum(neg)} negative variance hump{?s} set to NA (no event variance)."
    )
  }
  ok <- is.finite(r$dvar) & r$dvar >= 0
  out[ok] <- sqrt(r$dvar[ok] / (r$q[ok] * (1 - r$q[ok])))
  out
}

#' Partial-recovery interval for the event clock
#'
#' Under exact recovery the measured state-price log-odds quadratic
#' variation *is* the physical event clock. Under the partial-recovery
#' bound of the working paper — valuation-wedge quadratic variation no
#' larger than \eqn{\varepsilon^2} times the physical clock — the sharp
#' implied interval for the clock is
#' \deqn{\big((1-\varepsilon)_+\big)^2\,\widehat{A} \;\le\; A \;\le\;
#'   (1+\varepsilon)^2\,\widehat{A},}
#' where \eqn{\widehat{A}} is the measured log-odds variation. Exact
#' recovery is \eqn{\varepsilon = 0}.
#'
#' @param A Measured log-odds quadratic variation (e.g. the `A` column of
#'   [event_clock()]).
#' @param eps Partial-recovery bound(s) \eqn{\varepsilon \ge 0}; the
#'   default reproduces the working paper's sensitivity grid.
#' @return A tibble with columns `A`, `eps`, `lower`, `upper` (one row per
#'   `A` \eqn{\times} `eps` combination).
#' @examples
#' ec_recovery_set(0.511)                   # Brexit 1M clock
#' ec_recovery_set(c(0.064, 0.166), eps = 0.25)
#' @export
ec_recovery_set <- function(A, eps = c(0, 0.10, 0.25, 0.50)) {
  check_nonneg(A, "A")
  check_nonneg(eps, "eps")
  g <- expand.grid(A = A, eps = eps, KEEP.OUT.ATTRS = FALSE)
  tibble::tibble(
    A = g$A,
    eps = g$eps,
    lower = pmax(1 - g$eps, 0)^2 * g$A,
    upper = (1 + g$eps)^2 * g$A
  )
}

# Per-surface inner fit: dispersions (log-parametrized) given theta.
# obs: list with k, iv (in input units), w, scale (total = iv_units * scale,
# i.e. scale = sqrt(tau) when iv is annualized, 1 otherwise), q (scalar).
fit_dispersions <- function(obs, theta, par0 = NULL) {
  if (is.null(par0)) {
    s0 <- obs$iv[which.min(abs(obs$k))] * obs$scale[which.min(abs(obs$k))]
    s0 <- max(s0, 1e-3)
    par0 <- log(c(s0, s0))
  }
  obj <- function(par) {
    s <- exp(par)
    if (any(!is.finite(s)) || any(s > 20)) return(1e10)
    tot <- ec_mix_iv(obs$k, obs$q, theta, s[1], s[2])
    model <- tot / obs$scale
    err <- model - obs$iv
    if (any(!is.finite(err))) return(1e10)
    sum(obs$w * err^2) / sum(obs$w)
  }
  fit <- stats::optim(par0, obj, method = "Nelder-Mead",
                      control = list(maxit = 400, reltol = 1e-10))
  list(s1 = exp(fit$par[1]), s2 = exp(fit$par[2]),
       mse = fit$value, par = fit$par, convergence = fit$convergence)
}

#' Estimate the event exposure theta from event-spanning option surfaces
#'
#' Fits the lognormal event mixture of [ec_mix_price()] to a panel of
#' event-spanning option surfaces: each surface (one valuation date and one
#' expiry) gets its own outcome-conditional dispersions \eqn{(s_1, s_2)},
#' while the event exposure \eqn{\theta = \log(m_1/m_2)} is restricted to
#' be common across all surfaces — the working paper's common
#' conditional-mean-ratio design. The objective is the surface-balanced
#' mean of per-surface weighted squared implied-volatility errors, so each
#' surface carries equal weight regardless of how many quotes it has.
#'
#' @param surfaces A `data.frame` with one row per observed node and
#'   columns:
#'   \describe{
#'     \item{`surface`}{surface identifier (valuation date \eqn{\times}
#'       expiry); anything coercible to a factor.}
#'     \item{`k`}{log-forward moneyness \eqn{\log(K/F)} (see
#'       [ec_delta_to_k()] for delta grids).}
#'     \item{`iv`}{observed implied volatility. Annualized if `tau` is
#'       supplied, otherwise interpreted as *total* dispersion.}
#'     \item{`q`}{state-price-implied probability of outcome 1 at the
#'       surface's valuation date (constant within surface).}
#'     \item{`tau`}{optional: time to expiry in years; converts between
#'       annualized and total units.}
#'     \item{`w`}{optional: node weight (e.g. quote count or inverse
#'       spread); defaults to 1.}
#'   }
#' @param theta_range Search interval for the common exposure.
#' @param common If `FALSE`, every surface gets its own \eqn{\theta}
#'   instead (the working paper's free-ratio diagnostic); the common
#'   estimate is then `NA` and the per-surface exposures are reported in
#'   the `surfaces` table.
#' @param min_nodes Surfaces with fewer observed nodes are dropped with a
#'   warning (two free dispersions need cross-sectional information).
#'
#' @return An object of class `ec_theta_fit`: a list with
#'   \item{theta, ratio}{the common event exposure and
#'     \eqn{m_1/m_2 = e^{\theta}}.}
#'   \item{rmse}{surface-balanced root mean squared IV error, in the units
#'     of the `iv` input (annualized if `tau` was supplied).}
#'   \item{surfaces}{per-surface tibble: `q`, nodes, fitted `s1`, `s2`
#'     (total dispersions), per-surface `rmse`, and `theta` when
#'     `common = FALSE`.}
#'   \item{n_surfaces, n_obs, common}{bookkeeping.}
#'
#' @details
#' **Sign at `q` near one half.** See [ec_mix_price()]: with symmetric `q`
#' the sign of \eqn{\theta} is not identified from option prices alone and
#' the optimizer returns one of the two equivalent solutions. Fix the sign
#' externally (e.g. [event_beta()]).
#'
#' @references Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper),
#'   "Learning Before Scheduled Events: Prediction Markets, State Prices,
#'   and Option Valuation".
#'
#' @examples
#' # recover a known exposure from two noiseless simulated surfaces
#' k <- seq(-0.5, 0.5, by = 0.25)
#' surf <- rbind(
#'   data.frame(surface = "d1", k = k, q = 0.60,
#'              iv = ec_mix_iv(k, 0.60, 0.8, 0.30, 0.35)),
#'   data.frame(surface = "d2", k = k, q = 0.65,
#'              iv = ec_mix_iv(k, 0.65, 0.8, 0.28, 0.32))
#' )
#' ec_theta_fit(surf)
#' @seealso [ec_theta_hump()] for the first-order shortcut,
#'   [event_beta()] for the returns-based exposure.
#' @export
ec_theta_fit <- function(surfaces, theta_range = c(-3, 3), common = TRUE,
                         min_nodes = 4) {
  stopifnot(is.data.frame(surfaces))
  need <- c("surface", "k", "iv", "q")
  miss <- setdiff(need, names(surfaces))
  if (length(miss) > 0) {
    cli::cli_abort("{.arg surfaces} is missing column{?s} {.field {miss}}.")
  }
  sf <- as.data.frame(surfaces)
  sf$w <- if ("w" %in% names(sf)) as.numeric(sf$w) else 1
  sf$scale <- if ("tau" %in% names(sf)) sqrt(as.numeric(sf$tau)) else 1
  if (any(!is.finite(sf$scale) | sf$scale <= 0)) {
    cli::cli_abort("{.field tau} must be positive where supplied.")
  }
  sf <- sf[is.finite(sf$k) & is.finite(sf$iv) & is.finite(sf$q) &
             is.finite(sf$w) & sf$iv > 0 & sf$w > 0, , drop = FALSE]
  check_prob(sf$q)

  pieces <- split(sf, factor(sf$surface, levels = unique(sf$surface)))
  small <- vapply(pieces, nrow, 0L) < min_nodes
  if (any(small)) {
    cli::cli_warn(
      "Dropping {sum(small)} surface{?s} with fewer than {min_nodes} nodes."
    )
    pieces <- pieces[!small]
  }
  if (length(pieces) == 0) cli::cli_abort("No usable surfaces left.")
  obs <- lapply(pieces, function(p) {
    qs <- unique(p$q)
    if (length(qs) > 1 && diff(range(qs)) > 1e-8) {
      cli::cli_abort(
        "Surface {.val {as.character(p$surface[1])}} has non-constant {.field q}."
      )
    }
    list(k = p$k, iv = p$iv, w = p$w, scale = p$scale, q = qs[1])
  })

  warm <- vector("list", length(obs))
  surface_mse <- function(theta) {
    mse <- numeric(length(obs))
    for (i in seq_along(obs)) {
      f <- fit_dispersions(obs[[i]], theta, par0 = warm[[i]])
      warm[[i]] <<- f$par
      mse[i] <- f$mse
    }
    mse
  }

  if (common) {
    opt <- stats::optimize(function(th) mean(surface_mse(th)),
                           interval = theta_range, tol = 1e-4)
    theta_hat <- opt$minimum
    fits <- lapply(obs, fit_dispersions, theta = theta_hat)
    theta_col <- rep(theta_hat, length(obs))
  } else {
    fits <- vector("list", length(obs))
    theta_col <- numeric(length(obs))
    for (i in seq_along(obs)) {
      o <- stats::optimize(function(th) fit_dispersions(obs[[i]], th)$mse,
                           interval = theta_range, tol = 1e-4)
      theta_col[i] <- o$minimum
      fits[[i]] <- fit_dispersions(obs[[i]], o$minimum)
    }
    theta_hat <- NA_real_
  }

  per <- tibble::tibble(
    surface = names(obs),
    q = unname(vapply(obs, function(o) o$q, 0)),
    n = unname(vapply(obs, function(o) length(o$k), 0L)),
    theta = theta_col,
    s1 = unname(vapply(fits, function(f) f$s1, 0)),
    s2 = unname(vapply(fits, function(f) f$s2, 0)),
    rmse = sqrt(unname(vapply(fits, function(f) f$mse, 0)))
  )
  out <- list(
    theta = theta_hat,
    ratio = exp(theta_hat),
    rmse = sqrt(mean(vapply(fits, function(f) f$mse, 0))),
    surfaces = per,
    n_surfaces = length(obs),
    n_obs = sum(per$n),
    common = common
  )
  class(out) <- "ec_theta_fit"
  out
}

#' @describeIn ec_theta_fit Print method.
#' @param x,... Print method arguments.
#' @export
print.ec_theta_fit <- function(x, ...) {
  cat("-- Event-spanning mixture fit (", x$n_surfaces, " surface",
      if (x$n_surfaces != 1) "s", ", ", x$n_obs, " nodes)\n", sep = "")
  if (x$common) {
    cat(sprintf(
      "Common event exposure theta = %.4f (conditional-mean ratio m1/m2 = %.3f)\n",
      x$theta, x$ratio
    ))
  } else {
    cat(sprintf(
      "Free per-surface exposures: median theta = %.4f (range %.3f to %.3f)\n",
      stats::median(x$surfaces$theta), min(x$surfaces$theta),
      max(x$surfaces$theta)
    ))
  }
  cat(sprintf("Surface-balanced RMSE = %.4f (IV units of the input)\n", x$rmse))
  invisible(x)
}
