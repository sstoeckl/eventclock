# ---------------------------------------------------------------------------
# Ordinary-risk benchmark from quiet-clock surfaces: a library of earlier
# option surfaces with the Event Clock realized over each surface's own
# remaining life, a pre-specified grid of template rules, template shapes
# for a target, and rule selection by cross-validation on earlier
# pseudo-targets. Only information available before the target enters.
# ---------------------------------------------------------------------------

# Date or POSIXct as an instant (Date = midnight in tz).
as_instant <- function(x, tz = "UTC") {
  if (inherits(x, "POSIXct")) return(x)
  if (inherits(x, "Date")) return(as.POSIXct(format(x), tz = tz))
  cli::cli_abort("Dates must be {.cls Date} or {.cls POSIXct}.")
}

# Calendar day number (Date) of a Date or POSIXct in time zone tz.
cal_day <- function(x, tz = "UTC") {
  if (inherits(x, "Date")) return(as.numeric(x))
  as.numeric(as.Date(as_instant(x, tz), tz = tz))
}

# ATM implied volatility by linear interpolation at k = 0; without nodes
# on both sides, the nearest node within atm_tol.
atm_interp <- function(k, iv, atm_tol) {
  ok <- is.finite(k) & is.finite(iv)
  k <- k[ok]
  iv <- iv[ok]
  if (length(k) == 0) return(NA_real_)
  if (any(k == 0)) return(mean(iv[k == 0]))
  if (any(k < 0) && any(k > 0)) {
    return(stats::approx(k, iv, xout = 0, ties = mean)$y)
  }
  j <- which.min(abs(k))
  if (abs(k[j]) <= atm_tol) iv[j] else NA_real_
}

#' Library of earlier option surfaces with their realized Event Clock
#'
#' Builds the candidate library for the ordinary-risk benchmark: one row
#' per option surface with its at-the-money implied volatility, its smile
#' *shape* relative to at-the-money, days to expiry, and its quietness —
#' the Event Clock realized over the surface's own remaining life, from
#' its valuation date to its expiry. A surface whose life saw little
#' movement in the event probability carries little event learning in its
#' smile, so quiet surfaces proxy for ordinary option risk.
#'
#' @details
#' **Shape.** With `shape = "difference"` the shape is
#' \eqn{\sigma(k) - \sigma_{ATM}} (implied-volatility units); with
#' `"ratio"` it is \eqn{\sigma(k)/\sigma_{ATM}}. A target's own
#' at-the-money quote later fixes only the level, so a target's wings
#' never enter the benchmark.
#'
#' **Moneyness.** With `moneyness = "log"` (default) shapes are compared
#' at equal log-forward moneyness \eqn{k}. With `"standardized"` they are
#' compared at equal \eqn{z = k / (\sigma_{ATM}\sqrt{\tau})}, the distance
#' from the forward in at-the-money standard deviations. Standardized
#' moneyness lines up surfaces of different maturities and volatility
#' levels; it matters for low-volatility assets with short maturities,
#' where a fixed log-moneyness band reaches far into the wings.
#'
#' **Quietness.** If `x` is supplied, `A` is computed from the
#' event-probability series over \[valuation, expiry\] of each surface:
#' realized variation of the log-odds on the series' own observations
#' (`interval = NULL`) or on staggered grids of `interval` minutes (as in
#' [event_clock_staggered()]). Surfaces whose life extends beyond the last
#' observation of `x` get `A = NA` (`A_complete = FALSE`). Alternatively,
#' supply a column `A` in `surfaces`.
#'
#' @param surfaces A `data.frame` with one row per node and columns
#'   `surface` (identifier), `date` (valuation date, `Date` or `POSIXct`),
#'   `expiry` (`Date` or `POSIXct`), `k` (log-forward moneyness), `iv`
#'   (implied volatility); optional `atm_iv` (otherwise interpolated at
#'   \eqn{k = 0}), `A` (quietness), `block` (maturity block used for
#'   leave-block-out validation; default the expiry), and `tau` (time to
#'   expiry in years; default calendar days / 365). The output of
#'   [cme_option_surfaces()] can be passed as is.
#' @param x Optional `event_prices` object for computing `A`.
#' @param method Estimator for `A` (default `"rv"`; see [event_clock()]).
#' @param interval Optional sampling interval in minutes for staggered
#'   grids (intraday `x` only).
#' @param shape `"difference"` (default) or `"ratio"`.
#' @param moneyness `"log"` (default) or `"standardized"` (see Details).
#' @param atm_tol Largest \eqn{|k|} of a node used as at-the-money when no
#'   nodes bracket \eqn{k = 0} (default 0.02).
#' @param tz Time zone for calendar days to expiry and for `Date` bounds
#'   (default `"UTC"`).
#' @inheritParams event_clock
#'
#' @return A tibble of class `ec_quiet_library`, one row per surface:
#'   `surface`, `date`, `expiry`, `block`, `dte` (calendar days to
#'   expiry), `tau`, `atm_iv`, `A`, `A_complete`, `n_nodes`, and `nodes`
#'   (a list-column of tibbles with `k`, `z` (standardized moneyness),
#'   `iv`, `shape`).
#'
#' @references Hanke, Schadner, Stöckl, and Weissensteiner (Working
#'   Paper), "Learning Before Scheduled Events: Prediction Markets, State
#'   Prices, and Option Valuation".
#' @examples
#' lib_nodes <- expand.grid(i = 1:4, k = c(-0.2, -0.1, 0, 0.1, 0.2))
#' lib_nodes$surface <- paste0("s", lib_nodes$i)
#' lib_nodes$date <- as.Date("2024-09-02") + 7 * (lib_nodes$i - 1)
#' lib_nodes$expiry <- lib_nodes$date + 4
#' lib_nodes$iv <- 0.5 + 0.8 * lib_nodes$k^2
#' lib_nodes$A <- c(0.01, 0.20, 0.02, 0.03)[lib_nodes$i]
#' ec_quiet_library(lib_nodes)
#' @seealso [ec_quiet_rules()], [ec_quiet_shape()], [ec_quiet_select()].
#' @export
ec_quiet_library <- function(surfaces, x = NULL, method = "rv", interval = NULL,
                             shape = c("difference", "ratio"),
                             moneyness = c("log", "standardized"),
                             atm_tol = 0.02, tz = "UTC", clip = NULL,
                             trunc_sd = ec_default_params()$trunc_sd,
                             scale_fn = stats::mad) {
  stopifnot(is.data.frame(surfaces))
  shape <- rlang::arg_match(shape)
  moneyness <- rlang::arg_match(moneyness)
  need <- c("surface", "date", "expiry", "k", "iv")
  miss <- setdiff(need, names(surfaces))
  if (length(miss)) cli::cli_abort("{.arg surfaces} is missing column{?s} {.field {miss}}.")
  method <- match.arg(method, ec_default_params()$methods)
  sf <- as.data.frame(surfaces)
  sf$surface <- as.character(sf$surface)
  ids <- unique(sf$surface)
  parts <- split(sf, factor(sf$surface, levels = ids))

  rows <- lapply(parts, function(d) {
    if (length(unique(as.numeric(as_instant(d$date, tz)))) > 1 ||
        length(unique(as.numeric(as_instant(d$expiry, tz)))) > 1) {
      cli::cli_abort("Surface {.val {d$surface[1]}} has more than one valuation date or expiry.")
    }
    ok <- is.finite(d$k) & is.finite(d$iv)
    nd <- d[ok, , drop = FALSE]
    nd <- nd[order(nd$k), , drop = FALSE]
    atm <- if ("atm_iv" %in% names(d) && is.finite(d$atm_iv[1])) d$atm_iv[1] else
      atm_interp(nd$k, nd$iv, atm_tol)
    shp <- if (shape == "difference") nd$iv - atm else nd$iv / atm
    tau <- if ("tau" %in% names(d) && is.finite(d$tau[1])) d$tau[1] else
      (cal_day(d$expiry[1], tz) - cal_day(d$date[1], tz)) / 365
    list(
      atm = atm, tau = tau,
      A = if ("A" %in% names(d)) as.numeric(d$A[1]) else NA_real_,
      block = if ("block" %in% names(d)) as.character(d$block[1]) else
        format(d$expiry[1]),
      nodes = tibble::tibble(k = nd$k, z = nd$k / (atm * sqrt(tau)),
                             iv = nd$iv, shape = shp)
    )
  })
  first <- match(ids, sf$surface)
  lib <- tibble::tibble(
    surface = ids,
    date = sf$date[first],
    expiry = sf$expiry[first],
    block = vapply(rows, function(r) r$block, character(1), USE.NAMES = FALSE),
    dte = cal_day(sf$expiry[first], tz) - cal_day(sf$date[first], tz),
    tau = vapply(rows, function(r) r$tau, numeric(1), USE.NAMES = FALSE),
    atm_iv = vapply(rows, function(r) r$atm, numeric(1), USE.NAMES = FALSE),
    A = vapply(rows, function(r) r$A, numeric(1), USE.NAMES = FALSE),
    A_complete = NA,
    n_nodes = vapply(rows, function(r) nrow(r$nodes), integer(1), USE.NAMES = FALSE),
    nodes = unname(lapply(rows, function(r) r$nodes))
  )
  lib$A_complete <- is.finite(lib$A)

  if (!is.null(x)) {
    x <- as_event_prices(x)
    clip <- clip %||% attr(x, "clip") %||% ec_default_params()$clip
    cl <- clean_logit(x, clip)
    last <- max(cl$td)
    if (!is.null(interval) && !inherits(x$time, "POSIXct")) {
      cli::cli_abort("{.arg interval} needs intraday {.cls POSIXct} event prices.")
    }
    for (i in seq_len(nrow(lib))) {
      lo <- time_days(align_bound(lib$date[i], x$time, "start"))
      hi <- time_days(align_bound(lib$expiry[i], x$time, "end"))
      complete <- hi <= last + 1e-9
      keep <- cl$td >= lo - 1e-9 & cl$td <= hi + 1e-9
      A <- NA_real_
      if (complete && sum(keep) >= 2) {
        if (is.null(interval)) {
          A <- apply_kernel(diff(cl$L[keep]), method, trunc_sd, scale_fn)
        } else {
          A <- staggered_core(cl$td[keep], cl$L[keep], lo, hi,
                              step = interval / 1440,
                              offset_step = stats::median(diff(cl$td)),
                              methods = method, trunc_sd = trunc_sd,
                              scale_fn = scale_fn, max_offsets = 60)$A[[1]]
        }
      }
      lib$A[i] <- A
      lib$A_complete[i] <- complete
    }
  }
  attr(lib, "shape") <- shape
  attr(lib, "moneyness") <- moneyness
  attr(lib, "tz") <- tz
  class(lib) <- c("ec_quiet_library", class(tibble::tibble()))
  lib
}

#' @export
print.ec_quiet_library <- function(x, ...) {
  cat(sprintf("<ec_quiet_library> %d surfaces, shape = %s, moneyness = %s, A known for %d\n",
              nrow(x), attr(x, "shape"), attr(x, "moneyness") %||% "log",
              sum(is.finite(x$A))))
  y <- x
  class(y) <- class(tibble::tibble())
  print(y[, setdiff(names(y), "nodes")], ...)
  invisible(x)
}

#' Pre-specified rules for the ordinary-risk template
#'
#' Builds the grid of template rules, crossing a quietness threshold, a
#' days-to-expiry matching band, and an aggregation rule. Fixing the grid
#' before looking at the target is what makes the benchmark honest: the
#' rule is then chosen by [ec_quiet_select()] on earlier pseudo-targets
#' only.
#'
#' @details
#' **Quietness threshold.** With `quiet_type = "quantile"`, `quiet` holds
#' probabilities and the threshold is that quantile of the realized clocks
#' of the surfaces available at the (pseudo-)target date; with
#' `"absolute"`, `quiet` holds clock values. Eligible templates have
#' \eqn{A} at or below the threshold.
#'
#' **Aggregation.** `"all"` uses every eligible template; `"recent<n>"`
#' the `n` with the latest valuation dates; `"atm<n>"` the `n` whose
#' at-the-money volatility is closest to the target's. The template shape
#' is the node-by-node median across the selected templates.
#'
#' The defaults give 15 rules (25th/50th/75th percentile × all, recent 5,
#' recent 10, 5 and 10 ATM-nearest, no DTE matching). A 30-rule variant:
#' `ec_quiet_rules(c(0.03, 0.04, 0.06), "absolute", dte_band = c(1, 2),
#' aggregation = c("all", "atm1", "atm2", "atm3", "atm5"))`.
#'
#' @param quiet Threshold values (probabilities or clock values).
#' @param quiet_type `"quantile"` (default) or `"absolute"`.
#' @param dte_band Maximum absolute difference in calendar days to expiry
#'   between template and target; `Inf` (default) for no matching.
#' @param aggregation Character vector of aggregation rules (see Details).
#'
#' @return A tibble with one row per rule: `rule` (label), `quiet_type`,
#'   `quiet`, `dte_band`, `aggregation`, `agg_type`, `agg_n`.
#' @examples
#' ec_quiet_rules()
#' ec_quiet_rules(c(0.03, 0.04, 0.06), "absolute", dte_band = c(1, 2),
#'                aggregation = c("all", "atm1", "atm2", "atm3", "atm5"))
#' @seealso [ec_quiet_select()].
#' @export
ec_quiet_rules <- function(quiet = c(0.25, 0.50, 0.75),
                           quiet_type = c("quantile", "absolute"),
                           dte_band = Inf,
                           aggregation = c("all", "recent5", "recent10",
                                           "atm5", "atm10")) {
  quiet_type <- rlang::arg_match(quiet_type)
  stopifnot(is.numeric(quiet), length(quiet) >= 1, all(is.finite(quiet)),
            is.numeric(dte_band), all(dte_band >= 0))
  if (quiet_type == "quantile" && any(quiet <= 0 | quiet > 1)) {
    cli::cli_abort("Quantile thresholds must lie in (0, 1].")
  }
  ok <- grepl("^(all|recent[1-9][0-9]*|atm[1-9][0-9]*)$", aggregation)
  if (!all(ok)) {
    cli::cli_abort("Unknown aggregation{?s} {.val {aggregation[!ok]}}; use {.val all}, {.val recent<n>}, or {.val atm<n>}.")
  }
  g <- expand.grid(aggregation = aggregation, dte_band = dte_band,
                   quiet = quiet, stringsAsFactors = FALSE,
                   KEEP.OUT.ATTRS = FALSE)
  g <- g[, c("quiet", "dte_band", "aggregation")]
  agg_type <- sub("[0-9]+$", "", g$aggregation)
  agg_n <- suppressWarnings(as.integer(sub("^[a-z]+", "", g$aggregation)))
  qlab <- if (quiet_type == "quantile") sprintf("p%g", 100 * g$quiet) else
    sprintf("A<=%g", g$quiet)
  dlab <- ifelse(is.finite(g$dte_band), sprintf("DTE+-%g", g$dte_band), "any DTE")
  tibble::tibble(
    rule = paste(qlab, dlab, g$aggregation, sep = " | "),
    quiet_type = quiet_type, quiet = g$quiet, dte_band = g$dte_band,
    aggregation = g$aggregation, agg_type = agg_type, agg_n = agg_n
  )
}

check_rules <- function(rules) {
  need <- c("rule", "quiet_type", "quiet", "dte_band", "agg_type", "agg_n")
  if (!is.data.frame(rules) || length(setdiff(need, names(rules)))) {
    cli::cli_abort("{.arg rules} must come from {.fn ec_quiet_rules}.")
  }
  invisible(rules)
}

check_library <- function(library) {
  if (!inherits(library, "ec_quiet_library")) {
    cli::cli_abort("{.arg library} must come from {.fn ec_quiet_library}.")
  }
  invisible(library)
}

#' Ordinary-risk template shape for a target
#'
#' Predicts a target surface's smile shape from earlier quiet surfaces,
#' for one or more template rules. Only library surfaces whose whole
#' option life ended at or before `cutoff` are eligible, so no
#' information from after the target's valuation date enters. The target
#' contributes only its valuation date, expiry, at-the-money volatility
#' (which sets the level and ranks templates for `atm<n>` rules), and the
#' moneyness points to predict at — never its wings.
#'
#' @param library An [ec_quiet_library()].
#' @param date,expiry Target valuation date and expiry (`Date` or
#'   `POSIXct`).
#' @param atm_iv Target at-the-money implied volatility.
#' @param k Log-forward moneyness points at which to predict.
#' @param rules Rule table from [ec_quiet_rules()].
#' @param cutoff Templates must have expired at or before this time
#'   (default: the target's `date`); `NULL` disables the restriction
#'   (for a fixed, already pre-target library).
#' @param exclude_block Maturity block(s) to leave out.
#' @param tau Target time to expiry in years, used with a standardized
#'   library (default: calendar days to expiry / 365).
#'
#' @return A tibble with one row per rule and point `k`: `rule`, `k`,
#'   `z` (standardized moneyness; `NA` without a target ATM level),
#'   `shape` (median template shape; `NA` where no template covers `k`),
#'   `iv_pred` (target ATM volatility combined with the shape),
#'   `n_templates` (templates covering `k`), `n_selected` (templates the
#'   rule selected), and `threshold` (clock threshold applied). The
#'   attribute `templates` lists the selected surfaces per rule.
#' @examples
#' nodes <- expand.grid(i = 1:6, k = c(-0.2, -0.1, 0, 0.1, 0.2))
#' nodes$surface <- paste0("s", nodes$i)
#' nodes$date <- as.Date("2024-09-02") + 7 * (nodes$i - 1)
#' nodes$expiry <- nodes$date + 4
#' nodes$A <- c(0.01, 0.30, 0.02, 0.25, 0.03, 0.40)[nodes$i]
#' # quiet surfaces carry a symmetric smile, busy ones an added skew
#' nodes$iv <- 0.5 + 0.8 * nodes$k^2 - ifelse(nodes$A > 0.1, 0.3 * nodes$k, 0)
#' lib <- ec_quiet_library(nodes)
#' ec_quiet_shape(lib, date = as.Date("2024-10-14"), expiry = as.Date("2024-10-18"),
#'                atm_iv = 0.55, k = c(-0.1, 0.1),
#'                rules = ec_quiet_rules(0.5, aggregation = "all"))
#' @seealso [ec_quiet_select()].
#' @export
ec_quiet_shape <- function(library, date, expiry, atm_iv, k,
                           rules = ec_quiet_rules(), cutoff = date,
                           exclude_block = NULL, tau = NULL) {
  check_library(library)
  check_rules(rules)
  stopifnot(length(date) == 1, length(expiry) == 1, length(atm_iv) == 1,
            is.numeric(k), length(k) >= 1)
  tz <- attr(library, "tz") %||% "UTC"
  shape_type <- attr(library, "shape") %||% "difference"
  standardized <- identical(attr(library, "moneyness"), "standardized")
  tau <- tau %||% ((cal_day(expiry, tz) - cal_day(date, tz)) / 365)
  z <- k / (atm_iv * sqrt(tau))
  xout <- if (standardized) z else k
  xcol <- if (standardized) "z" else "k"
  lib <- library[is.finite(library$A), , drop = FALSE]
  if (!is.null(cutoff)) {
    lib <- lib[as.numeric(as_instant(lib$expiry, tz)) <=
                 as.numeric(as_instant(cutoff, tz)), , drop = FALSE]
  }
  if (!is.null(exclude_block)) {
    lib <- lib[!lib$block %in% as.character(exclude_block), , drop = FALSE]
  }
  target_dte <- cal_day(expiry, tz) - cal_day(date, tz)
  lib_t <- as.numeric(as_instant(lib$date, tz))
  lib_e <- as.numeric(as_instant(lib$expiry, tz))

  used <- vector("list", nrow(rules))
  res <- lapply(seq_len(nrow(rules)), function(r) {
    ru <- rules[r, ]
    thr <- if (ru$quiet_type == "quantile") {
      if (nrow(lib)) stats::quantile(lib$A, ru$quiet, names = FALSE) else NA_real_
    } else ru$quiet
    sel <- which(lib$A <= thr + 1e-12)
    if (is.finite(ru$dte_band)) {
      sel <- sel[abs(lib$dte[sel] - target_dte) <= ru$dte_band + 1e-9]
    }
    if (ru$agg_type == "recent") {
      sel <- sel[order(-lib_t[sel], -lib_e[sel])]
      sel <- utils::head(sel, ru$agg_n)
    } else if (ru$agg_type == "atm") {
      if (!is.finite(atm_iv)) {
        sel <- integer(0)
      } else {
        sel <- sel[is.finite(lib$atm_iv[sel])]
        sel <- sel[order(abs(lib$atm_iv[sel] - atm_iv), -lib_t[sel])]
        sel <- utils::head(sel, ru$agg_n)
      }
    }
    used[[r]] <<- lib$surface[sel]
    M <- matrix(NA_real_, nrow = length(k), ncol = length(sel))
    for (j in seq_along(sel)) {
      nd <- lib$nodes[[sel[j]]]
      xx <- nd[[xcol]]
      ok <- is.finite(xx) & is.finite(nd$shape)
      if (sum(ok) >= 2 && any(is.finite(xout))) {
        M[, j] <- stats::approx(xx[ok], nd$shape[ok], xout = xout, rule = 1,
                                ties = mean)$y
      } else if (sum(ok) == 1) {
        M[, j] <- ifelse(abs(xout - xx[ok]) < 1e-12, nd$shape[ok], NA_real_)
      }
    }
    n_k <- rowSums(!is.na(M))
    shp <- rep(NA_real_, length(k))
    has <- n_k > 0
    if (any(has)) {
      shp[has] <- apply(M[has, , drop = FALSE], 1, stats::median, na.rm = TRUE)
    }
    tibble::tibble(
      rule = ru$rule, k = k, z = z, shape = shp,
      iv_pred = if (shape_type == "difference") atm_iv + shp else atm_iv * shp,
      n_templates = as.integer(n_k), n_selected = length(sel),
      threshold = thr
    )
  })
  out <- dplyr::bind_rows(res)
  attr(out, "templates") <- stats::setNames(used, rules$rule)
  out
}

#' Choose the ordinary-risk template rule on earlier pseudo-targets
#'
#' Cross-validates every rule of a pre-specified grid on earlier
#' surfaces treated as if they were the target ("pseudo-targets") and
#' picks the rule with the lowest wing-shape error. Each pseudo-target's
#' whole maturity block is left out of its template library, and with
#' `available_only = TRUE` only templates that had expired by the
#' pseudo-target's own valuation date are used. The real target's wings
#' are never consulted.
#'
#' @details
#' **Loss.** For each pseudo-target the predicted shape is compared with
#' its realized shape at its own nodes with `wing[1] <= |k| <= wing[2]`
#' (or `|z|` for a standardized library). Errors are in implied-volatility units
#' (for `shape = "ratio"` the ratio error is scaled by the pseudo-target's
#' at-the-money volatility). `rmse` pools all nodes; `rmse_target` averages
#' the per-target RMSE.
#'
#' **Common nodes.** Rules can differ in which nodes they can predict
#' (a rule may select no template). With `common = TRUE` (default) every
#' rule is scored on the same nodes — those every rule predicts.
#'
#' **Ties.** Rules whose RMSE agrees to 10 significant digits are ordered
#' by the stricter quietness threshold, then by their position in the
#' grid.
#'
#' @param library An [ec_quiet_library()].
#' @param rules Rule table from [ec_quiet_rules()].
#' @param pseudo Optional surface identifiers of the pseudo-targets.
#' @param pseudo_quiet Optional clock threshold: surfaces with
#'   \eqn{A} at or below it are pseudo-targets (used when `pseudo` is
#'   `NULL`; default: all surfaces with a known clock).
#' @param pseudo_min_dte Optional minimum calendar days to expiry of a
#'   pseudo-target (applied on top of `pseudo` or `pseudo_quiet`). Shorter
#'   surfaces still serve as templates.
#' @param cutoff Optional real-target valuation date: the library is first
#'   restricted to surfaces that expired at or before it.
#' @param available_only Logical; restrict each pseudo-target's templates
#'   to those expired by its own valuation date (default `TRUE`). With
#'   `FALSE`, the whole (pre-cutoff) library minus the pseudo-target's
#'   maturity block is used.
#' @param wing Moneyness band of the loss, in the library's moneyness
#'   (default `c(0.04, 0.30)` in log-moneyness, `c(0.5, 3)` standard
#'   deviations for a standardized library).
#' @param common Logical; score all rules on a common set of nodes.
#' @param target Optional list with `date`, `expiry`, `atm_iv`, `k`, and
#'   optionally `tau` for the real target; adds its predicted shape under
#'   every rule.
#'
#' @return An object of class `ec_quiet_select`: a list with `scores`
#'   (one row per rule: `rule`, rule columns, `rmse`, `mae`,
#'   `rmse_target`, `n_targets`, `n_nodes`, sorted best first), `best`
#'   (the selected row), `detail` (pseudo-target × rule × node: `surface`,
#'   `rule`, `k`, `z`, `actual`, `shape`, `error`), `pseudo` (the
#'   pseudo-target surfaces), and with `target` also `target_shapes`
#'   (the [ec_quiet_shape()] output for all rules, with a logical
#'   `selected` column).
#' @references Hanke, Schadner, Stöckl, and Weissensteiner (Working
#'   Paper), "Learning Before Scheduled Events: Prediction Markets, State
#'   Prices, and Option Valuation".
#' @examples
#' set.seed(1)
#' nodes <- expand.grid(i = 1:20, k = seq(-0.3, 0.3, by = 0.05))
#' nodes$surface <- paste0("s", nodes$i)
#' nodes$date <- as.Date("2024-06-03") + 7 * (nodes$i - 1)
#' nodes$expiry <- nodes$date + 4
#' A <- c(0.01, 0.3, 0.02, 0.2, 0.01, 0.5, 0.03, 0.02, 0.4, 0.01,
#'        0.25, 0.02, 0.01, 0.35, 0.03, 0.02, 0.45, 0.01, 0.02, 0.3)
#' nodes$A <- A[nodes$i]
#' nodes$iv <- 0.5 + 0.8 * nodes$k^2 - ifelse(nodes$A > 0.1, 0.3 * nodes$k, 0) +
#'   rnorm(nrow(nodes), sd = 0.002)
#' lib <- ec_quiet_library(nodes)
#' sel <- ec_quiet_select(lib, pseudo_quiet = 0.02)
#' sel
#' @seealso [ec_quiet_rules()], [ec_quiet_shape()].
#' @export
ec_quiet_select <- function(library, rules = ec_quiet_rules(), pseudo = NULL,
                            pseudo_quiet = NULL, pseudo_min_dte = NULL,
                            cutoff = NULL, available_only = TRUE, wing = NULL,
                            common = TRUE, target = NULL) {
  check_library(library)
  check_rules(rules)
  if (!is.null(pseudo_min_dte) &&
      !(is.numeric(pseudo_min_dte) && length(pseudo_min_dte) == 1 &&
        is.finite(pseudo_min_dte) && pseudo_min_dte >= 0)) {
    cli::cli_abort("{.arg pseudo_min_dte} must be a single non-negative number of days.")
  }
  tz <- attr(library, "tz") %||% "UTC"
  shape_type <- attr(library, "shape") %||% "difference"
  standardized <- identical(attr(library, "moneyness"), "standardized")
  wing <- wing %||% (if (standardized) c(0.5, 3) else c(0.04, 0.30))
  stopifnot(length(wing) == 2, wing[1] >= 0, wing[2] > wing[1])
  xcol <- if (standardized) "z" else "k"
  lib <- library
  if (!is.null(cutoff)) {
    lib <- lib[as.numeric(as_instant(lib$expiry, tz)) <=
                 as.numeric(as_instant(cutoff, tz)), , drop = FALSE]
  }
  cand <- lib[is.finite(lib$A) & is.finite(lib$atm_iv), , drop = FALSE]
  if (!is.null(pseudo)) {
    cand <- cand[cand$surface %in% as.character(pseudo), , drop = FALSE]
  } else if (!is.null(pseudo_quiet)) {
    cand <- cand[cand$A <= pseudo_quiet + 1e-12, , drop = FALSE]
  }
  if (!is.null(pseudo_min_dte)) {
    cand <- cand[cand$dte >= pseudo_min_dte - 1e-9, , drop = FALSE]
  }
  if (nrow(cand) == 0) cli::cli_abort("No pseudo-targets with a known clock and ATM volatility.")

  detail <- lapply(seq_len(nrow(cand)), function(i) {
    p <- cand[i, ]
    nd <- p$nodes[[1]]
    xx <- abs(nd[[xcol]])
    w <- is.finite(xx) & xx >= wing[1] - 1e-12 & xx <= wing[2] + 1e-12 &
      is.finite(nd$shape)
    if (!any(w)) return(NULL)
    pr <- ec_quiet_shape(lib, p$date, p$expiry, p$atm_iv, nd$k[w], rules,
                         cutoff = if (available_only) p$date else NULL,
                         exclude_block = p$block, tau = p$tau)
    pr$actual <- rep(nd$shape[w], times = nrow(rules))
    pr$surface <- p$surface
    pr$error <- if (shape_type == "difference") pr$shape - pr$actual else
      (pr$shape - pr$actual) * p$atm_iv
    pr[, c("surface", "rule", "k", "z", "actual", "shape", "error")]
  })
  detail <- dplyr::bind_rows(detail)
  if (nrow(detail) == 0) cli::cli_abort("No pseudo-target has nodes inside {.arg wing}.")
  node <- paste(detail$surface, detail$k)
  if (common) {
    nfin <- tapply(is.finite(detail$error), node, sum)
    keep_nodes <- names(nfin)[nfin == nrow(rules)]
    use <- node %in% keep_nodes
  } else {
    use <- is.finite(detail$error)
  }
  d <- detail[use & is.finite(detail$error), , drop = FALSE]
  if (nrow(d) == 0) {
    cli::cli_abort("No node is predicted by every rule; try {.code common = FALSE} or more pseudo-targets.")
  }

  sc <- lapply(seq_len(nrow(rules)), function(r) {
    e <- d[d$rule == rules$rule[r], , drop = FALSE]
    per <- tapply(e$error, e$surface, function(v) sqrt(mean(v^2)))
    tibble::tibble(
      rmse = if (nrow(e)) sqrt(mean(e$error^2)) else NA_real_,
      mae = if (nrow(e)) mean(abs(e$error)) else NA_real_,
      rmse_target = if (nrow(e)) mean(per) else NA_real_,
      n_targets = length(unique(e$surface)),
      n_nodes = nrow(e)
    )
  })
  scores <- dplyr::bind_cols(rules, dplyr::bind_rows(sc))
  scores$grid_order <- seq_len(nrow(scores))
  o <- order(signif(scores$rmse, 10), scores$quiet, scores$grid_order, na.last = TRUE)
  scores <- scores[o, , drop = FALSE]
  scores$grid_order <- NULL
  best <- scores[1, , drop = FALSE]

  out <- list(scores = scores, best = best, detail = detail,
              pseudo = cand$surface, rules = rules,
              settings = list(available_only = available_only, wing = wing,
                              common = common, cutoff = cutoff,
                              pseudo_min_dte = pseudo_min_dte,
                              shape = shape_type,
                              moneyness = if (standardized) "standardized" else "log"))
  if (!is.null(target)) {
    need <- c("date", "expiry", "atm_iv", "k")
    if (!is.list(target) || length(setdiff(need, names(target)))) {
      cli::cli_abort("{.arg target} needs elements {.field {need}}.")
    }
    ts <- ec_quiet_shape(lib, target$date, target$expiry, target$atm_iv,
                         target$k, rules, cutoff = target$date,
                         tau = target$tau)
    ts$selected <- ts$rule == best$rule
    out$target_shapes <- ts
  }
  class(out) <- "ec_quiet_select"
  out
}

#' @export
print.ec_quiet_select <- function(x, n = 5, ...) {
  cat(sprintf("<ec_quiet_select> %d rules on %d pseudo-targets (%s, wing %g-%g %s)\n",
              nrow(x$scores), length(x$pseudo),
              if (x$settings$available_only) "templates available at each pseudo-target"
              else "leave-maturity-block-out",
              x$settings$wing[1], x$settings$wing[2],
              if (identical(x$settings$moneyness, "standardized")) "ATM sd" else "log-moneyness"))
  cat(sprintf("Selected: %s  (RMSE %.4f on %d nodes, %d targets)\n",
              x$best$rule, x$best$rmse, x$best$n_nodes, x$best$n_targets))
  s <- x$scores[, c("rule", "rmse", "mae", "n_targets", "n_nodes")]
  print(utils::head(s, n), ...)
  invisible(x)
}
