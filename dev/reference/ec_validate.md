# Data-quality report for an event-probability series

Screens an `event_prices` object for the data problems that matter for
clock estimation, following the flag-don't-drop philosophy: nothing is
altered, everything is reported.

## Usage

``` r
ec_validate(x)

# S3 method for class 'ec_validation'
print(x, ...)
```

## Arguments

- x:

  An `event_prices` object (or coercible).

- ...:

  Unused (for the `print` method).

## Value

A one-row tibble of class `ec_validation` with columns `market_id`,
`n_obs`, `start`, `end`, `spacing_days`, `n_na`, `share_clip`,
`share_zero_incr`, `max_stale_run`, `tick`, `n_gaps`, `max_gap_days`,
`max_abs_dL`, and `outlier_ratio` (`max_abs_dL` / robust SD). Printed as
a formatted report.

## Details

The checks:

- **Coverage** — observations, span, median spacing, missing values,
  share outside the clipping bounds.

- **Staleness** — share of zero increments and the longest run of
  unchanged quotes; long stale runs depress \\\widehat A\\.

- **Tick size** — smallest non-zero price move; on a coarse tick grid
  the logit of small-probability quotes moves in lumps (microstructure
  noise; compare
  [`ec_signature()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_signature.md)).

- **Gaps** — increments spanning more than 1.5 times the median spacing
  (see
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)).

- **Outliers** — largest absolute log-odds increment relative to the
  robust scale of all increments; values far above the truncation
  threshold deserve a manual look (data error vs. genuine news).

## Functions

- `print(ec_validation)`: Print method; formatted report.

## Examples

``` r
ec_validate(as_event_prices(brexit2016, time = "date", price = "q_leave"))
#> -- Event-price data-quality report
#> Coverage:  119 obs, 2016-02-26 to 2016-06-23, median spacing 1 days, 0 NA
#> Clipping:  0.0% of observations outside the clipping bounds
#> Staleness: 11.0% zero increments, longest stale run 2 obs
#> Tick:      smallest non-zero move 0.001
#> Gaps:      0 gap increment(s), largest 1 days
#> Outliers:  max |dL| = 0.292 (5.5 robust SDs)
```
