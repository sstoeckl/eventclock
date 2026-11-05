# Partial-recovery interval for the Event Clock

A traded event price can move for two reasons: news about the outcome,
or a change in how the market values the two outcomes relative to each
other. Under *exact recovery* only the first moves log odds
continuously, and the measured log-odds variation *is* the physical
Event Clock. *Partial recovery* allows the valuation gap to contribute
too, but at most a fraction \\\delta^2\\ of the measured variation,
\\\[\upsilon\]^c \le \delta^2 \[L\]^c\\. The physical clock then lies in
the sharp interval \$\$(1-\delta)\_+^2\\\widehat{A} \\\le\\ A \\\le\\
(1+\delta)^2\\\widehat{A},\$\$ where \\\widehat{A}\\ is the measured
log-odds variation. Exact recovery is \\\delta = 0\\. The lower end is
the "low-clock endpoint" used for conservative sensitivity analysis: at
\\\delta = 0.5\\ it scales the measured clock by \\(1 - 0.5)^2 = 0.25\\.

## Usage

``` r
ec_recovery_set(A, delta = c(0, 0.1, 0.25, 0.5), eps = NULL)
```

## Arguments

- A:

  Measured log-odds quadratic variation (e.g. the `A` column of
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md),
  or a forecast from
  [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_forecast.md)).

- delta:

  Partial-recovery bound(s) \\\delta \ge 0\\; the default is a
  sensitivity grid up to the deliberately wide \\\delta = 0.5\\.

- eps:

  Deprecated alias for `delta` (the argument name used up to version
  0.4.0).

## Value

A tibble with columns `A`, `delta`, `lower`, `upper` (one row per `A`
\\\times\\ `delta` combination).

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "The Event
Clock: What State Prices Identify About Physical Information".

## Examples

``` r
ec_recovery_set(0.511)                   # Brexit 1M clock
#> # A tibble: 4 × 4
#>       A delta lower upper
#>   <dbl> <dbl> <dbl> <dbl>
#> 1 0.511  0    0.511 0.511
#> 2 0.511  0.1  0.414 0.618
#> 3 0.511  0.25 0.287 0.798
#> 4 0.511  0.5  0.128 1.15 
ec_recovery_set(c(0.064, 0.166), delta = 0.5)
#> # A tibble: 2 × 4
#>       A delta  lower upper
#>   <dbl> <dbl>  <dbl> <dbl>
#> 1 0.064   0.5 0.016  0.144
#> 2 0.166   0.5 0.0415 0.374
```
