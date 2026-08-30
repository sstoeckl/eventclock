# ---------------------------------------------------------------------------
# Plotting helpers (ggplot2). All functions return ggplot objects.
# ---------------------------------------------------------------------------

#' Plot the event-probability path
#'
#' Line plot of the traded event probability \eqn{q_t}, with an optional
#' marker at the scheduled event date.
#'
#' @param x An `event_prices` object (or coercible).
#' @param event_date Optional event date; defaults to the one stored on
#'   `x`.
#' @param ... Unused.
#'
#' @return A ggplot object.
#'
#' @examples
#' data(brexit2016)
#' ep <- as_event_prices(brexit2016, time = "date", price = "q_leave",
#'                       event_date = as.Date("2016-06-23"))
#' plot_q(ep)
#' @export
plot_q <- function(x, event_date = NULL, ...) {
  x <- as_event_prices(x)
  event_date <- event_date %||% attr(x, "event_date")
  p <- ggplot2::ggplot(x, ggplot2::aes(x = time, y = q)) +
    ggplot2::geom_hline(yintercept = 0.5, linetype = 3, color = "grey60") +
    ggplot2::geom_line(linewidth = 0.7, color = "#2c3e50") +
    ggplot2::labs(
      x = NULL, y = expression(q[t]),
      title = attr(x, "market_id"),
      subtitle = "Traded event probability"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  if (!is.null(event_date)) {
    p <- p + ggplot2::geom_vline(
      xintercept = event_date, linetype = 2, color = "firebrick"
    )
  }
  p
}

#' Clock plot: the cumulative event clock
#'
#' Plots cumulative event-clock time \eqn{\widehat A_t} against calendar
#' time — the "clock plot": how much of the window's information had
#' arrived by each date.
#'
#' @param path An `event_clock_path` object from [event_clock_path()] (an
#'   `event_prices` object is converted automatically).
#' @param normalize Logical; plot the clock normalized to \eqn{[0,1]}
#'   (default `TRUE`) or in raw units of `A`.
#' @param ... Unused.
#'
#' @return A ggplot object.
#'
#' @examples
#' data(brexit2016)
#' ep <- as_event_prices(brexit2016, time = "date", price = "q_leave",
#'                       event_date = as.Date("2016-06-23"))
#' plot_clock(event_clock_path(ep))
#' @export
plot_clock <- function(path, normalize = TRUE, ...) {
  if (inherits(path, "event_prices")) path <- event_clock_path(path)
  stopifnot(inherits(path, "event_clock_path"))
  yvar <- if (normalize && "A_frac" %in% names(path)) "A_frac" else "A"
  ylab <- if (yvar == "A_frac") "Share of clock time elapsed" else expression(hat(A)[t])
  p <- ggplot2::ggplot(path, ggplot2::aes(x = time, y = .data[[yvar]])) +
    ggplot2::geom_step(linewidth = 0.7, color = "#2c3e50") +
    ggplot2::labs(
      x = NULL, y = ylab,
      title = attr(path, "market_id"),
      subtitle = "Cumulative event clock"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  ed <- attr(path, "event_date")
  if (!is.null(ed)) {
    p <- p + ggplot2::geom_vline(xintercept = ed, linetype = 2, color = "firebrick")
  }
  p
}

#' Event-clock time versus calendar time
#'
#' Plots the share of clock time elapsed against the share of calendar
#' time elapsed. The 45-degree line is the "information arrives uniformly"
#' benchmark; a curve below it means information is back-loaded (it waits
#' for the deadline), above it front-loaded.
#'
#' @inheritParams plot_clock
#'
#' @return A ggplot object.
#'
#' @examples
#' data(us2016)
#' ep <- as_event_prices(us2016, time = "date", price = "trump",
#'                       event_date = as.Date("2016-11-08"))
#' plot_clock_vs_calendar(event_clock_path(ep))
#' @export
plot_clock_vs_calendar <- function(path, ...) {
  if (inherits(path, "event_prices")) path <- event_clock_path(path)
  stopifnot(inherits(path, "event_clock_path"))
  if (!all(c("A_frac", "cal_frac") %in% names(path))) {
    cli::cli_abort("{.arg path} must be built with {.code normalize = TRUE}.")
  }
  ggplot2::ggplot(path, ggplot2::aes(x = cal_frac, y = A_frac)) +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = 2, color = "grey60") +
    ggplot2::geom_line(linewidth = 0.7, color = "#2c3e50") +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(
      x = "Share of calendar time elapsed",
      y = "Share of clock time elapsed",
      title = attr(path, "market_id"),
      subtitle = "Event-clock vs. calendar time"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
