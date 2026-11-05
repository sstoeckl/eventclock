# Real-time Event Clock forecast

Before an option expires we do not yet know how much information will
arrive while it is alive. A real-time forecast uses only prices observed
up to the valuation time `at`: it measures the recent speed of the clock
(log-odds variation per calendar day over an estimation window) and
multiplies it by the remaining horizon, \$\$\widehat A^{rt}(h) =
\frac{\widehat A(\text{window})} {\text{window length in days}} \times
h.\$\$

## Usage

``` r
event_clock_forecast(
  x,
  at = NULL,
  horizon,
  trailing = ec_default_params()$trailing,
  days = NULL,
  expanding = FALSE,
  method = "rv",
  interval = NULL,
  sample_every = ec_default_params()$sample_every,
  trunc_sd = ec_default_params()$trunc_sd,
  scale_fn = stats::mad,
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
  observation). Only observations at or before `at` are used.

- horizon:

  Forecast horizon(s): either numeric (days) or `Date`/`POSIXct` horizon
  dates (converted to days from `at`; `POSIXct` horizons give fractional
  days). Names are used as labels.

- trailing:

  Integer, number of trailing observations in the estimation window
  (default 40). Ignored when `days` or `expanding` is set.

- days:

  Numeric, length of a trailing calendar-day window.

- expanding:

  Logical; use all observations up to `at`.

- method:

  Estimator for the window (default `"rv"`; see
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)).

- interval:

  Optional sampling interval in minutes for staggered grid sampling of
  intraday data.

- sample_every:

  Integer, use every k-th observation (sparse-sampling robustness;
  default 1).

- trunc_sd:

  Numeric, truncation threshold in robust standard deviations (default
  3).

- scale_fn:

  Function computing the robust scale of the increments for `truncated`
  (default [`stats::mad()`](https://rdrr.io/r/stats/mad.html)).

- clip:

  Numeric length-2 clipping bounds for `q` before the log-odds
  transform; defaults to the bounds stored in `x`.

## Value

A tibble with columns `market_id`, `at`, `horizon`, `horizon_days`,
`rule` (window and estimator), `trailing` (window size for observation
windows, else `NA`), `method`, `n_incr`, `n_gaps`, `max_gap_days`,
`rate_per_day`, and `A_forecast`. See
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)
for the gap diagnostics.

## Details

Three kinds of estimation window are available. By default the window is
the last `trailing` observations and its length is their calendar span.
With `days`, the window is the last `days` calendar days before `at`
(e.g. `days = 3` with hourly data); with `expanding = TRUE` it is the
whole history up to `at`. Any estimator of
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)
can measure the window (`method`), and with intraday data `interval`
turns on staggered grid sampling as in
[`event_clock_staggered()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_staggered.md).

Which window works best is an empirical question. Choose it the way the
accompanying working paper does — by forecast accuracy on earlier option
lives only, never on the options being tested — with
[`ec_forecast_select()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_forecast_select.md).

## See also

[`ec_forecast_select()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_forecast_select.md)
to choose the window by forecast accuracy;
[`ec_recovery_set()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_recovery_set.md)
for the low-clock sensitivity.

## Examples

``` r
data(us2016)
ep <- as_event_prices(us2016, time = "date", price = "trump")
# trailing 60 increments, as selected for this series in the paper
event_clock_forecast(ep, at = as.Date("2016-10-10"),
                     horizon = c(`1W` = 7, `2W` = 14), trailing = 61)
#> # A tibble: 2 × 12
#>   market_id at         horizon horizon_days rule   trailing method n_incr n_gaps
#>   <chr>     <date>     <chr>          <dbl> <chr>     <int> <chr>   <int>  <int>
#> 1 NA        2016-10-10 1W                 7 trail…       61 rv         60      0
#> 2 NA        2016-10-10 2W                14 trail…       61 rv         60      0
#> # ℹ 3 more variables: max_gap_days <dbl>, rate_per_day <dbl>, A_forecast <dbl>

# hourly data: clock speed over the last three days
data(polymarket2024)
event_clock_forecast(as_event_prices(polymarket2024),
  at = as.POSIXct("2024-10-25 19:45", tz = "UTC"),
  horizon = as.POSIXct("2024-11-01 19:45", tz = "UTC"), days = 3)
#> # A tibble: 1 × 12
#>   market_id at                  horizon       horizon_days rule  trailing method
#>   <chr>     <dttm>              <chr>                <dbl> <chr>    <int> <chr> 
#> 1 NA        2024-10-25 19:45:00 2024-11-01 1…            7 trai…       NA rv    
#> # ℹ 5 more variables: n_incr <int>, n_gaps <int>, max_gap_days <dbl>,
#> #   rate_per_day <dbl>, A_forecast <dbl>
```
