#' Default parameters of the eventclock package
#'
#' A single source of truth for the defaults used across the package.
#' Modify individual entries with [utils::modifyList()] and pass the result
#' to the estimation functions.
#'
#' @return A named list with elements
#'   \item{clip}{numeric length-2, bounds applied to `q` before the log-odds
#'     transform (default `c(0.01, 0.99)`).}
#'   \item{methods}{character, estimator variants computed by
#'     [event_clock()].}
#'   \item{sample_every}{integer, keep every k-th observation.}
#'   \item{trunc_sd}{numeric, truncation threshold in robust standard
#'     deviations.}
#'   \item{trailing}{integer, trailing window (in observations) of the
#'     real-time forecast rule of [event_clock_forecast()].}
#'
#' @examples
#' params <- utils::modifyList(ec_default_params(), list(trunc_sd = 4))
#' params$trunc_sd
#' @export
ec_default_params <- function() {
  list(
    clip         = c(0.01, 0.99),
    methods      = c("rv", "truncated", "bipower", "largest1", "largest2"),
    sample_every = 1L,
    trunc_sd     = 3,
    trailing     = 40L
  )
}
