# Event Clock on staggered time grids

With intraday prices, the measured clock depends on how often you
sample: very fine sampling picks up bid-ask bounce and stale quotes,
coarse sampling throws information away. A *staggered* grid estimate
samples the price every `interval` minutes (the last price at or before
each grid point) and repeats this for every possible starting offset of
the grid; the estimator is applied to each grid separately and the
results are averaged. This uses all the data while keeping the chosen
sampling frequency — the construction behind the working paper's 30-,
60-, and 120-minute clocks.

## Usage

``` r
event_clock_staggered(
  x,
  from = NULL,
  to = NULL,
  interval = 60,
  methods = "rv",
  offset_step = NULL,
  max_offsets = 60,
  trunc_sd = ec_default_params()$trunc_sd,
  scale_fn = stats::mad,
  clip = NULL
)
```

## Arguments

- x:

  An `event_prices` object (see
  [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)),
  or a `data.frame` coercible to one.

- from:

  Valuation date/time (default: first observation).

- to:

  One or more horizon dates/times (default: last observation = full
  sample). Names are used as horizon labels.

- interval:

  Sampling interval in minutes (default 60).

- methods:

  Character vector of estimator variants; see Details.

- offset_step:

  Spacing of the grid offsets in minutes (default: the median spacing of
  the observations).

- max_offsets:

  Maximum number of offset grids (default 60).

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

A tibble with one row per horizon and method: `market_id`, `from`, `to`,
`horizon`, `interval_min`, `n_offsets`, `n_incr` (average increments per
grid), `method`, `A` (average over grids), and `A_min`, `A_max` (range
over grids).

## Details

Each method is applied *within* each offset grid before averaging, so
`largest1` removes the largest move of every grid separately and
`bipower` uses neighbors on the same grid — matching the paper's
"largest-move exclusion in each staggered grid". Grid offsets run in
steps of `offset_step` minutes (default: the data's median spacing),
capped at `max_offsets` grids. Choose an `interval` no finer than the
data's own spacing; otherwise repeated prices create zero increments.
For daily data use `sample_every` in
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md)
or
[`ec_signature()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_signature.md)
instead.

## See also

[`ec_signature()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_signature.md)
for the full sampling-frequency profile.

## Examples

``` r
data(polymarket2024)
ep <- as_event_prices(polymarket2024)
event_clock_staggered(ep, interval = 120, methods = c("rv", "largest1"))
#> # A tibble: 2 × 11
#>   market_id from                to                  horizon         interval_min
#>   <chr>     <dttm>              <dttm>              <chr>                  <dbl>
#> 1 NA        2024-06-01 00:00:03 2024-11-05 23:00:02 2024-11-05 23:…          120
#> 2 NA        2024-06-01 00:00:03 2024-11-05 23:00:02 2024-11-05 23:…          120
#> # ℹ 6 more variables: n_offsets <int>, n_incr <dbl>, method <chr>, A <dbl>,
#> #   A_min <dbl>, A_max <dbl>
```
