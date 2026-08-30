# Default parameters of the eventclock package

A single source of truth for the defaults used across the package.
Modify individual entries with
[`utils::modifyList()`](https://rdrr.io/r/utils/modifyList.html) and
pass the result to the estimation functions.

## Usage

``` r
ec_default_params()
```

## Value

A named list with elements

- clip:

  numeric length-2, bounds applied to `q` before the log-odds transform
  (default `c(0.01, 0.99)`).

- methods:

  character, estimator variants computed by
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md).

- sample_every:

  integer, keep every k-th observation.

- trunc_sd:

  numeric, truncation threshold in robust standard deviations.

- trailing:

  integer, trailing window (in observations) of the real-time forecast
  rule of
  [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_forecast.md).

## Examples

``` r
params <- utils::modifyList(ec_default_params(), list(trunc_sd = 4))
params$trunc_sd
#> [1] 4
```
