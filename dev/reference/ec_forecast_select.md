# Choose the real-time forecasting rule by out-of-sample accuracy

Compares candidate forecasting rules on a set of *earlier* option lives:
for each interval, every rule forecasts the clock from data available at
the interval's start, and the forecast is compared with the clock that
subsequently materialized over the interval. The rule with the lowest
root-mean-square error wins. Because the intervals end before the
options you want to study, the choice never looks at the test sample —
the no-look-ahead discipline of the accompanying working paper.

## Usage

``` r
ec_forecast_select(
  x,
  intervals,
  rules = ec_forecast_rules(days = c(3, 5, 7, 10, 14, 20), expanding = TRUE),
  realized_method = "rv",
  interval = NULL,
  common = TRUE,
  trunc_sd = ec_default_params()$trunc_sd,
  scale_fn = stats::mad,
  clip = NULL
)

# S3 method for class 'ec_forecast_select'
print(x, ...)
```

## Arguments

- x:

  An `event_prices` object (or coercible).

- intervals:

  A `data.frame` with columns `start` and `end` (valuation time and
  expiry of each earlier option life), of the same time type as `x` (or
  `Date` bounds for a `POSIXct` series).

- rules:

  Candidate rules from
  [`ec_forecast_rules()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_forecast_rules.md).

- realized_method:

  Estimator for the realized clock over each interval (default `"rv"`).

- interval:

  Optional staggered sampling interval in minutes, used for both
  forecasts and realized clocks (intraday data only).

- common:

  Logical; if `TRUE` (default), score all rules on the intervals where
  every rule produces a forecast, so the comparison is like for like.

- trunc_sd:

  Numeric, truncation threshold in robust standard deviations (default
  3).

- scale_fn:

  Function computing the robust scale of the increments for `truncated`
  (default [`stats::mad()`](https://rdrr.io/r/stats/mad.html)).

- clip:

  Numeric length-2 clipping bounds for `q` before the log-odds
  transform; defaults to the bounds stored in `x`.

- ...:

  Unused (for the `print` method).

## Value

An object of class `ec_forecast_select`: a list with

- scores:

  tibble per rule: `rule`, `type`, `window`, `method`, `n` (intervals
  scored), `rmse`, `mae`, `bias` (mean forecast minus realized), sorted
  by `rmse`.

- best:

  the winning row of `scores`.

- detail:

  long tibble: interval, rule, forecast, realized.

## Methods (by generic)

- `print(ec_forecast_select)`: Print method.

## Examples

``` r
data(us2016)
ep <- as_event_prices(us2016, time = "date", price = "trump")
# two-week option lives starting every day, all ending before Oct 10
starts <- seq(as.Date("2016-06-01"), as.Date("2016-09-25"), by = "day")
iv <- data.frame(start = starts, end = starts + 14)
sel <- ec_forecast_select(ep, iv,
  rules = ec_forecast_rules(obs = c(21, 41, 61)))
sel
#> -- Real-time clock forecast selection (117 option lives scored)
#> Best rule: trailing 61 obs / rv (RMSE 0.04052)
#> # A tibble: 3 × 5
#>   rule                     n   rmse    mae      bias
#>   <chr>                <int>  <dbl>  <dbl>     <dbl>
#> 1 trailing 61 obs / rv   117 0.0405 0.0315 -0.000658
#> 2 trailing 41 obs / rv   117 0.0417 0.0311 -0.00279 
#> 3 trailing 21 obs / rv   117 0.0483 0.0393 -0.00422 
```
