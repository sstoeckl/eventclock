# Library of earlier option surfaces with their realized Event Clock

Builds the candidate library for the ordinary-risk benchmark: one row
per option surface with its at-the-money implied volatility, its smile
*shape* relative to at-the-money, days to expiry, and its quietness —
the Event Clock realized over the surface's own remaining life, from its
valuation date to its expiry. A surface whose life saw little movement
in the event probability carries little event learning in its smile, so
quiet surfaces proxy for ordinary option risk.

## Usage

``` r
ec_quiet_library(
  surfaces,
  x = NULL,
  method = "rv",
  interval = NULL,
  shape = c("difference", "ratio"),
  moneyness = c("log", "standardized"),
  atm_tol = 0.02,
  tz = "UTC",
  clip = NULL,
  trunc_sd = ec_default_params()$trunc_sd,
  scale_fn = stats::mad
)
```

## Arguments

- surfaces:

  A `data.frame` with one row per node and columns `surface`
  (identifier), `date` (valuation date, `Date` or `POSIXct`), `expiry`
  (`Date` or `POSIXct`), `k` (log-forward moneyness), `iv` (implied
  volatility); optional `atm_iv` (otherwise interpolated at \\k = 0\\),
  `A` (quietness), `block` (maturity block used for leave-block-out
  validation; default the expiry), and `tau` (time to expiry in years;
  default calendar days / 365). The output of
  [`cme_option_surfaces()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/cme_option_surfaces.md)
  can be passed as is.

- x:

  Optional `event_prices` object for computing `A`.

- method:

  Estimator for `A` (default `"rv"`; see
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)).

- interval:

  Optional sampling interval in minutes for staggered grids (intraday
  `x` only).

- shape:

  `"difference"` (default) or `"ratio"`.

- moneyness:

  `"log"` (default) or `"standardized"` (see Details).

- atm_tol:

  Largest \\\|k\|\\ of a node used as at-the-money when no nodes bracket
  \\k = 0\\ (default 0.02).

- tz:

  Time zone for calendar days to expiry and for `Date` bounds (default
  `"UTC"`).

- clip:

  Numeric length-2 clipping bounds for `q` before the log-odds
  transform; defaults to the bounds stored in `x`.

- trunc_sd:

  Numeric, truncation threshold in robust standard deviations (default
  3).

- scale_fn:

  Function computing the robust scale of the increments for `truncated`
  (default [`stats::mad()`](https://rdrr.io/r/stats/mad.html)).

## Value

A tibble of class `ec_quiet_library`, one row per surface: `surface`,
`date`, `expiry`, `block`, `dte` (calendar days to expiry), `tau`,
`atm_iv`, `A`, `A_complete`, `n_nodes`, and `nodes` (a list-column of
tibbles with `k`, `z` (standardized moneyness), `iv`, `shape`).

## Details

**Shape.** With `shape = "difference"` the shape is \\\sigma(k) -
\sigma\_{ATM}\\ (implied-volatility units); with `"ratio"` it is
\\\sigma(k)/\sigma\_{ATM}\\. A target's own at-the-money quote later
fixes only the level, so a target's wings never enter the benchmark.

**Moneyness.** With `moneyness = "log"` (default) shapes are compared at
equal log-forward moneyness \\k\\. With `"standardized"` they are
compared at equal \\z = k / (\sigma\_{ATM}\sqrt{\tau})\\, the distance
from the forward in at-the-money standard deviations. Standardized
moneyness lines up surfaces of different maturities and volatility
levels; it matters for low-volatility assets with short maturities,
where a fixed log-moneyness band reaches far into the wings.

**Quietness.** If `x` is supplied, `A` is computed from the
event-probability series over \[valuation, expiry\] of each surface:
realized variation of the log-odds on the series' own observations
(`interval = NULL`) or on staggered grids of `interval` minutes (as in
[`event_clock_staggered()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_staggered.md)).
Surfaces whose life extends beyond the last observation of `x` get
`A = NA` (`A_complete = FALSE`). Alternatively, supply a column `A` in
`surfaces`.

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "Learning
Before Scheduled Events: Prediction Markets, State Prices, and Option
Valuation".

## See also

[`ec_quiet_rules()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_rules.md),
[`ec_quiet_shape()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_shape.md),
[`ec_quiet_select()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_select.md).

## Examples

``` r
lib_nodes <- expand.grid(i = 1:4, k = c(-0.2, -0.1, 0, 0.1, 0.2))
lib_nodes$surface <- paste0("s", lib_nodes$i)
lib_nodes$date <- as.Date("2024-09-02") + 7 * (lib_nodes$i - 1)
lib_nodes$expiry <- lib_nodes$date + 4
lib_nodes$iv <- 0.5 + 0.8 * lib_nodes$k^2
lib_nodes$A <- c(0.01, 0.20, 0.02, 0.03)[lib_nodes$i]
ec_quiet_library(lib_nodes)
#> <ec_quiet_library> 4 surfaces, shape = difference, moneyness = log, A known for 4
#> # A tibble: 4 × 10
#>   surface date       expiry     block        dte    tau atm_iv     A A_complete
#>   <chr>   <date>     <date>     <chr>      <dbl>  <dbl>  <dbl> <dbl> <lgl>     
#> 1 s1      2024-09-02 2024-09-06 2024-09-06     4 0.0110    0.5  0.01 TRUE      
#> 2 s2      2024-09-09 2024-09-13 2024-09-13     4 0.0110    0.5  0.2  TRUE      
#> 3 s3      2024-09-16 2024-09-20 2024-09-20     4 0.0110    0.5  0.02 TRUE      
#> 4 s4      2024-09-23 2024-09-27 2024-09-27     4 0.0110    0.5  0.03 TRUE      
#> # ℹ 1 more variable: n_nodes <int>
```
