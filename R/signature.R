#' Sampling-frequency signature of the event clock
#'
#' Computes the clock estimate \eqn{\widehat A} across sampling
#' frequencies — the analogue of the volatility signature plot. For each
#' subsampling step \eqn{k}, the realized variation is averaged over all
#' \eqn{k} possible offsets of the sparse grid. A pronounced increase of
#' \eqn{\widehat A} at the finest frequencies signals microstructure
#' noise (bid-ask bounce on a coarse tick grid); a flat signature means
#' the clock is measured cleanly.
#'
#' @inheritParams event_clock
#' @param max_every Integer, largest subsampling step (default 10).
#'
#' @return A tibble of class `ec_signature` with columns
#'   \item{sample_every}{subsampling step \eqn{k}.}
#'   \item{spacing_days}{median spacing of the sparse grid in days.}
#'   \item{n_incr}{average number of increments per offset grid.}
#'   \item{A}{realized variation averaged over the \eqn{k} offsets.}
#'   \item{A_min, A_max}{range over the offsets.}
#'
#' @examples
#' data(polymarket2024)
#' sig <- ec_signature(as_event_prices(polymarket2024), max_every = 24)
#' head(sig)
#' plot_signature(sig)
#' @seealso [plot_signature()], [pm_daily()]
#' @export
ec_signature <- function(x, max_every = 10, from = NULL, to = NULL,
                         clip = NULL) {
  x <- as_event_prices(x)
  clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
  from <- from %||% min(x$time)
  to <- to %||% max(x$time)
  stopifnot(max_every >= 1)
  max_every <- as.integer(max_every)

  d <- window_rows(x, from, to)
  n <- nrow(d)
  if (n < max_every + 1) {
    cli::cli_abort("Need more than {.arg max_every} observations in the window.")
  }
  L <- ec_logit(clip_q(d$q, clip))
  base_dt <- stats::median(as.numeric(difftime(d$time[-1], d$time[-n],
                                               units = "days")))

  rows <- lapply(seq_len(max_every), function(k) {
    rv <- vapply(seq_len(k), function(o) {
      idx <- seq(o, n, by = k)
      if (length(idx) < 2) return(NA_real_)
      sum(diff(L[idx])^2)
    }, numeric(1))
    n_incr <- vapply(seq_len(k), function(o) {
      max(0L, length(seq(o, n, by = k)) - 1L)
    }, integer(1))
    tibble::tibble(
      sample_every = k,
      spacing_days = k * base_dt,
      n_incr = mean(n_incr),
      A = mean(rv, na.rm = TRUE),
      A_min = min(rv, na.rm = TRUE),
      A_max = max(rv, na.rm = TRUE)
    )
  })
  out <- dplyr::bind_rows(rows)
  attr(out, "market_id") <- attr(x, "market_id")
  class(out) <- c("ec_signature", class(tibble::tibble()))
  out
}

#' @describeIn ec_signature Plot method; dispatches to [plot_signature()].
#' @export
plot.ec_signature <- function(x, ...) plot_signature(x, ...)

#' Plot the sampling-frequency signature
#'
#' @param sig An `ec_signature` object from [ec_signature()] (an
#'   `event_prices` object is converted automatically).
#' @param ... Unused.
#'
#' @return A ggplot object.
#'
#' @examples
#' data(polymarket2024)
#' plot_signature(ec_signature(as_event_prices(polymarket2024), max_every = 24))
#' @export
plot_signature <- function(sig, ...) {
  if (inherits(sig, "event_prices")) sig <- ec_signature(sig)
  stopifnot(inherits(sig, "ec_signature"))
  ggplot2::ggplot(sig, ggplot2::aes(x = spacing_days, y = A)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = A_min, ymax = A_max),
                         fill = "grey85") +
    ggplot2::geom_line(linewidth = 0.7, color = "#2c3e50") +
    ggplot2::geom_point(size = 1.6, color = "#2c3e50") +
    ggplot2::labs(
      x = "Sampling interval (days)", y = expression(hat(A)),
      title = attr(sig, "market_id"),
      subtitle = "Signature plot: measured clock vs. sampling frequency"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
