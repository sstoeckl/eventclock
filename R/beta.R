# ---------------------------------------------------------------------------
# Event-beta (realized loading) regression: asset returns on event-probability
# innovations, with Newey-West standard errors (base-R implementation).
# ---------------------------------------------------------------------------

# Bartlett-kernel HAC covariance of an OLS fit. X: model matrix, u: residuals.
newey_west_vcov <- function(X, u, lags) {
  n <- nrow(X)
  Xu <- X * u
  S <- crossprod(Xu) / n
  if (lags > 0) {
    for (l in seq_len(lags)) {
      w <- 1 - l / (lags + 1)
      Gl <- crossprod(
        Xu[(l + 1):n, , drop = FALSE],
        Xu[1:(n - l), , drop = FALSE]
      ) / n
      S <- S + w * (Gl + t(Gl))
    }
  }
  B <- solve(crossprod(X) / n)
  (B %*% S %*% B) / n
}

#' Event beta: realized loading of asset returns on event-probability news
#'
#' Regresses asset returns on the innovations of a traded event
#' probability, \deqn{r_t = \alpha + b\, \Delta q_t + \gamma' c_t + u_t,}
#' with Newey-West (Bartlett/HAC) standard errors. To first order the
#' model implies \eqn{r_t \approx \Delta\eta\,\Delta q_t}, so the slope
#' `b` *is* the returns-based estimate of the event exposure
#' \eqn{\widehat{\Delta\eta}}.
#'
#' @details
#' **What is (and is not) identified.** Returns identify only the
#' *spread* \eqn{\Delta\eta = \eta_1 - \eta_2}, not the
#' outcome-conditional levels \eqn{\eta_1, \eta_2} separately (those
#' require event-spanning option smiles). Consequently the loading test
#' \eqn{\beta = 1} is only meaningful against an *externally* measured
#' exposure: supply `deta` (e.g. option-implied, or from an independent
#' sample) and the function reports \eqn{\beta = b / \Delta\eta} with a
#' Wald test of \eqn{\beta = 1}. Without `deta`, the regression is
#' exactly identified and only \eqn{\widehat{\Delta\eta}} is reported.
#'
#' Under the risk-neutral adding-up constraint
#' \eqn{q\,\eta_1 + (1-q)\,\eta_2 = 1}, point estimates of the levels can
#' be backed out as \eqn{\eta_1 = 1 + (1-q)\Delta\eta} and
#' \eqn{\eta_2 = 1 - q\Delta\eta}; these are model-implied, not
#' independently identified, and are returned for convenience
#' (evaluated at the sample-average `q`).
#'
#' @param asset A `data.frame` with a time column and either a return
#'   column (`ret`) or a price column (`adjusted`, `close`, or `price`;
#'   log returns are computed).
#' @param x An `event_prices` object (or coercible); its probability
#'   innovations \eqn{\Delta q_t} are the regressor. Observations are
#'   matched on the calendar date.
#' @param deta Optional externally measured event exposure
#'   \eqn{\Delta\eta}; enables the \eqn{\beta = 1} test.
#' @param controls Optional `data.frame` with a time column and control
#'   variables (e.g. market returns), matched on date.
#' @param lags Newey-West lag order; default
#'   \eqn{\lfloor 4 (n/100)^{2/9} \rfloor}. Use `lags = 0` for
#'   heteroskedasticity-robust (HC0) errors.
#' @param ... Unused (for the `print` method).
#'
#' @return An object of class `event_beta`: a list with
#'   \item{coefficients}{tibble of terms, estimates, HAC standard
#'     errors, t-statistics, and p-values.}
#'   \item{deta_hat, deta_se}{the slope on \eqn{\Delta q} and its SE.}
#'   \item{eta1, eta2}{model-implied levels (see Details).}
#'   \item{beta, beta_se, beta_z, beta_p}{(only with `deta`) the loading
#'     \eqn{b/\Delta\eta} and the Wald test of \eqn{\beta = 1}.}
#'   \item{r2, n, lags}{regression diagnostics; `r2` is the realized
#'     variance share of event news over the sample.}
#'
#' @examples
#' data(djt2024)
#' data(polymarket2024)
#' ep <- pm_daily(as_event_prices(polymarket2024))
#' event_beta(djt2024, ep)
#' @seealso [ec_relevance()] for the pricing-relevance screen.
#' @export
event_beta <- function(asset, x, deta = NULL, controls = NULL, lags = NULL) {
  stopifnot(is.data.frame(asset))
  x <- as_event_prices(x)

  find_col <- function(df, cands) {
    hit <- names(df)[match(cands, tolower(names(df)))]
    hit <- hit[!is.na(hit)]
    if (length(hit) == 0) return(NULL)
    hit[1]
  }
  tcol <- find_col(asset, c("time", "date", "timestamp", "datetime"))
  if (is.null(tcol)) cli::cli_abort("No time column found in {.arg asset}.")
  a_date <- as.Date(asset[[tcol]])

  rcol <- find_col(asset, c("ret", "return"))
  if (!is.null(rcol)) {
    a <- tibble::tibble(date = a_date, ret = as.numeric(asset[[rcol]]))
  } else {
    pcol <- find_col(asset, c("adjusted", "close", "price", "value"))
    if (is.null(pcol)) {
      cli::cli_abort("Found neither a return nor a price column in {.arg asset}.")
    }
    p <- as.numeric(asset[[pcol]])
    a <- tibble::tibble(date = a_date[-1], ret = diff(log(p)))
  }

  ev <- tibble::tibble(date = as.Date(x$time), q = x$q) |>
    dplyr::filter(!is.na(q)) |>
    dplyr::mutate(dq = q - dplyr::lag(q)) |>
    dplyr::select(date, dq)

  d <- dplyr::inner_join(a, ev, by = "date")
  if (!is.null(controls)) {
    stopifnot(is.data.frame(controls))
    ctcol <- find_col(controls, c("time", "date", "timestamp", "datetime"))
    if (is.null(ctcol)) cli::cli_abort("No time column found in {.arg controls}.")
    ctl <- controls
    ctl[[ctcol]] <- as.Date(ctl[[ctcol]])
    names(ctl)[names(ctl) == ctcol] <- "date"
    d <- dplyr::inner_join(d, ctl, by = "date")
  }
  d <- stats::na.omit(d)
  n <- nrow(d)
  if (n < 10) cli::cli_abort("Only {n} matched observations; need at least 10.")

  rhs <- setdiff(names(d), c("date", "ret"))
  fml <- stats::as.formula(paste("ret ~", paste(rhs, collapse = " + ")))
  fit <- stats::lm(fml, data = d)
  X <- stats::model.matrix(fit)
  u <- stats::residuals(fit)
  lags <- lags %||% floor(4 * (n / 100)^(2 / 9))
  V <- newey_west_vcov(X, u, lags)
  est <- stats::coef(fit)
  se <- sqrt(diag(V))
  tstat <- est / se
  coefs <- tibble::tibble(
    term = names(est), estimate = unname(est), se = unname(se),
    statistic = unname(tstat),
    p.value = 2 * stats::pnorm(-abs(unname(tstat)))
  )

  deta_hat <- unname(est["dq"])
  deta_se <- unname(se["dq"])
  qbar <- mean(x$q, na.rm = TRUE)

  out <- list(
    coefficients = coefs,
    deta_hat = deta_hat, deta_se = deta_se,
    eta1 = 1 + (1 - qbar) * deta_hat,
    eta2 = 1 - qbar * deta_hat,
    q_mean = qbar,
    r2 = summary(fit)$r.squared,
    n = n, lags = as.integer(lags)
  )
  if (!is.null(deta)) {
    stopifnot(is.numeric(deta), length(deta) == 1, deta != 0)
    out$deta_external <- deta
    out$beta <- deta_hat / deta
    out$beta_se <- deta_se / abs(deta)
    out$beta_z <- (out$beta - 1) / out$beta_se
    out$beta_p <- 2 * stats::pnorm(-abs(out$beta_z))
  }
  class(out) <- "event_beta"
  out
}

#' @describeIn event_beta Print method.
#' @export
print.event_beta <- function(x, ...) {
  cat("-- Event-beta regression (Newey-West, ", x$lags, " lag",
      if (x$lags != 1) "s", ")\n", sep = "")
  cat(sprintf(
    "Event exposure deta_hat = %.4f (se %.4f, t = %.2f), n = %d, R^2 = %.3f\n",
    x$deta_hat, x$deta_se, x$deta_hat / x$deta_se, x$n, x$r2
  ))
  cat(sprintf(
    "Model-implied levels at mean q = %.3f: eta1 = %.4f, eta2 = %.4f\n",
    x$q_mean, x$eta1, x$eta2
  ))
  if (!is.null(x$beta)) {
    cat(sprintf(
      "Loading vs. external deta = %.4f: beta = %.3f (se %.3f), H0 beta=1: z = %.2f, p = %.3f\n",
      x$deta_external, x$beta, x$beta_se, x$beta_z, x$beta_p
    ))
  } else {
    cat("(No external deta supplied: levels/loading test not identified from returns alone.)\n")
  }
  invisible(x)
}
