# Estimate event-clock (information) time from log-odds variation

The information accumulated about a scheduled event over a window \\\[t,
T\]\\ — *event-clock time* \\A\_{t,T}\\ — equals the quadratic variation
of the log-odds of the traded event probability, \\A\_{t,T} =
\[\mathrm{logit}(q)\]\_{t,T}\\. `event_clock()` estimates it by the
realized variation \$\$\widehat A\_{t,T} = \sum_i
\left\[\mathrm{logit}(q\_{t\_{i+1}}) -
\mathrm{logit}(q\_{t_i})\right\]^2\$\$ together with standard robustness
variants.

## Usage

``` r
event_clock(
  x,
  from = NULL,
  to = NULL,
  methods = ec_default_params()$methods,
  sample_every = ec_default_params()$sample_every,
  trunc_sd = ec_default_params()$trunc_sd,
  scale_fn = stats::mad,
  clip = NULL,
  se = FALSE,
  conf = 0.95,
  se_method = c("quarticity", "bootstrap"),
  boot_reps = 999
)
```

## Arguments

- x:

  An `event_prices` object (see
  [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md)),
  or a `data.frame` coercible to one.

- from:

  Valuation date/time (default: first observation).

- to:

  One or more horizon dates/times (default: last observation = full
  sample). Names are used as horizon labels.

- methods:

  Character vector of estimator variants; see Details.

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

- se:

  Logical; if `TRUE`, add a standard error and confidence interval for
  the `rv` estimate (columns are `NA` for the other methods). The
  asymptotic variance is estimated by the quarticity analogue
  \\\widehat{Var}(\widehat A) = \tfrac{2}{3}\sum (\Delta L_i)^4\\; the
  interval is log-based, \\\exp\\\log \widehat A \pm z\\ se/\widehat
  A\\\\. With `se_method = "bootstrap"`, a wild bootstrap with two-point
  multipliers (moment-matched to the same asymptotic variance) is used
  and the interval is the percentile interval. Conditional drift
  contributes at order \\(\Delta t)^2\\ and is ignored.

- conf:

  Confidence level (default 0.95).

- se_method:

  `"quarticity"` (default) or `"bootstrap"`.

- boot_reps:

  Bootstrap replications (default 999).

## Value

A tibble with one row per horizon and method:

- market_id:

  market label (from `x`).

- from, to:

  window bounds as supplied.

- horizon:

  horizon label (names of `to`, or the date).

- n_obs:

  number of non-missing observations in the window.

- n_incr:

  number of increments used (after subsampling).

- n_gaps:

  number of increments spanning more than 1.5 times the median
  observation spacing (see Details).

- max_gap_days:

  largest spacing (in days) between consecutive observations used.

- method:

  estimator variant.

- A:

  the estimate \\\widehat A\_{t,T}\\.

- se, ci_lo, ci_hi:

  (only with `se = TRUE`) standard error and confidence bounds for the
  `rv` rows.

## Details

Because quadratic variation ignores finite-variation drift and is
invariant under equivalent measure changes, \\\widehat A\\ is
*measure-robust*: it does not require a martingale assumption under the
physical measure, and any (approximately) constant level distortion of
`q` — discounting, a constant state-price tilt, a constant cross-market
wedge — drops out entirely.

Available `methods`:

- `rv`:

  plain realized variation (the baseline).

- `truncated`:

  drops increments larger than `trunc_sd` robust standard deviations,
  where the robust scale is `scale_fn(dL)`
  ([`stats::mad()`](https://rdrr.io/r/stats/mad.html) by default). Note
  that with daily data and short windows this criterion is coarse;
  reference results reported as "truncated" often coincide with dropping
  the single largest increment (`largest1`). Compare both. When the
  robust scale is degenerate (e.g. more than half of the increments are
  identical), truncation is disabled with a message and plain realized
  variation is returned.

- `bipower`:

  bipower variation \\BV = \frac{\pi}{2}\sum\_{i\ge 2} \|\Delta
  L_i\|\|\Delta L\_{i-1}\|\\, a jump-robust companion; the gap \\RV -
  BV\\ is a descriptive *jumpiness index*. No finite-sample correction
  is applied, so `BV` is biased downward in very short windows (a 1-week
  window has only six neighbor products); read it as descriptive, not as
  an unbiased estimate.

- `largest1`, `largest2`:

  realized variation after removing the one or two largest absolute
  increments.

**Windows.** Windows are defined in calendar time from the valuation
date `from` to each horizon date in `to` (they are *anchored* windows,
not trailing ones). All observations in the window are used, including
weekends if the series has them. `Date`-typed bounds combined with a
`POSIXct`-typed series are interpreted in the series' timezone, with
`to` covering the full horizon day.

**Missing observations and gaps.** Missing `q` values inside the window
are skipped with a warning; the increment then *bridges* the gap and
aggregates more elapsed time than a regular one-period increment. Plain
realized variation remains a valid (sparser) estimate of the window's
total variation, but the robustness variants treat all increments as
homogeneous: a gap-spanning increment is mechanically larger and can be
misclassified as a jump by `truncated`/`largest1`/`largest2`, and it
distorts the neighbor products of `bipower`. The output columns `n_gaps`
(increments spanning more than 1.5 times the median observation spacing)
and `max_gap_days` flag affected windows — interpret the robustness
variants cautiously whenever `n_gaps > 0`.

## See also

[`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_path.md)
for the cumulative clock,
[`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_forecast.md)
for the real-time benchmark.

## Examples

``` r
data(brexit2016)
ep <- as_event_prices(brexit2016,
  time = "date", price = "q_leave",
  market_id = "Brexit: Leave", event_date = as.Date("2016-06-23")
)
# the working paper's 1M valuation date and 1W/2W/1M horizons
event_clock(ep,
  from = as.Date("2016-05-24"),
  to = c(`1W` = as.Date("2016-05-31"), `2W` = as.Date("2016-06-07"),
         `1M` = as.Date("2016-06-23"))
)
#> # A tibble: 15 × 10
#>    market_id     from       to         horizon n_obs n_incr n_gaps max_gap_days
#>    <chr>         <date>     <date>     <chr>   <int>  <int>  <int>        <dbl>
#>  1 Brexit: Leave 2016-05-24 2016-05-31 1W          8      7      0            1
#>  2 Brexit: Leave 2016-05-24 2016-05-31 1W          8      7      0            1
#>  3 Brexit: Leave 2016-05-24 2016-05-31 1W          8      7      0            1
#>  4 Brexit: Leave 2016-05-24 2016-05-31 1W          8      7      0            1
#>  5 Brexit: Leave 2016-05-24 2016-05-31 1W          8      7      0            1
#>  6 Brexit: Leave 2016-05-24 2016-06-07 2W         15     14      0            1
#>  7 Brexit: Leave 2016-05-24 2016-06-07 2W         15     14      0            1
#>  8 Brexit: Leave 2016-05-24 2016-06-07 2W         15     14      0            1
#>  9 Brexit: Leave 2016-05-24 2016-06-07 2W         15     14      0            1
#> 10 Brexit: Leave 2016-05-24 2016-06-07 2W         15     14      0            1
#> 11 Brexit: Leave 2016-05-24 2016-06-23 1M         31     30      0            1
#> 12 Brexit: Leave 2016-05-24 2016-06-23 1M         31     30      0            1
#> 13 Brexit: Leave 2016-05-24 2016-06-23 1M         31     30      0            1
#> 14 Brexit: Leave 2016-05-24 2016-06-23 1M         31     30      0            1
#> 15 Brexit: Leave 2016-05-24 2016-06-23 1M         31     30      0            1
#> # ℹ 2 more variables: method <chr>, A <dbl>
```
