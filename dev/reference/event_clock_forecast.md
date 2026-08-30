# Real-time event-clock forecast

The real-time benchmark used in the accompanying working paper: estimate
the current information intensity from a trailing window and scale it to
the forecast horizon, \$\$\widehat A^{rt}(h) = \frac{RV(\text{trailing }
k \text{ obs.})} {\text{calendar span in days}} \times h.\$\$

## Usage

``` r
event_clock_forecast(
  x,
  at = NULL,
  horizon,
  trailing = ec_default_params()$trailing,
  sample_every = ec_default_params()$sample_every,
  clip = NULL
)
```

## Arguments

- x:

  An `event_prices` object (see
  [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md)),
  or a `data.frame` coercible to one.

- at:

  Valuation date/time at which the forecast is made (default: last
  observation).

- horizon:

  Forecast horizon(s): either numeric (days) or `Date`/`POSIXct` horizon
  dates (converted to days from `at`). Names are used as labels.

- trailing:

  Integer, number of trailing observations in the estimation window
  (default 40, the paper's headline choice; 20 and 60 are common
  robustness settings).

- sample_every:

  Integer, use every k-th observation (sparse-sampling robustness;
  default 1).

- clip:

  Numeric length-2 clipping bounds for `q` before the log-odds
  transform; defaults to the bounds stored in `x`.

## Value

A tibble with columns `market_id`, `at`, `horizon`, `horizon_days`,
`trailing`, `n_incr`, `n_gaps`, `max_gap_days`, and `A_forecast`. See
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)
for the gap diagnostics.

## Examples

``` r
data(us2016)
ep <- as_event_prices(us2016, time = "date", price = "trump")
event_clock_forecast(ep,
  at = as.Date("2016-10-10"),
  horizon = c(`1W` = 7, `2W` = 14)
)
#> # A tibble: 2 × 9
#>   market_id at         horizon horizon_days trailing n_incr n_gaps max_gap_days
#>   <chr>     <date>     <chr>          <dbl>    <int>  <int>  <int>        <dbl>
#> 1 NA        2016-10-10 1W                 7       40     39      0            1
#> 2 NA        2016-10-10 2W                14       40     39      0            1
#> # ℹ 1 more variable: A_forecast <dbl>
```
