# Partial-recovery interval for the event clock

Under exact recovery the measured state-price log-odds quadratic
variation *is* the physical event clock. Under the partial-recovery
bound of the working paper — valuation-wedge quadratic variation no
larger than \\\varepsilon^2\\ times the physical clock — the sharp
implied interval for the clock is
\$\$\big((1-\varepsilon)\_+\big)^2\\\widehat{A} \\\le\\ A \\\le\\
(1+\varepsilon)^2\\\widehat{A},\$\$ where \\\widehat{A}\\ is the
measured log-odds variation. Exact recovery is \\\varepsilon = 0\\.

## Usage

``` r
ec_recovery_set(A, eps = c(0, 0.1, 0.25, 0.5))
```

## Arguments

- A:

  Measured log-odds quadratic variation (e.g. the `A` column of
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)).

- eps:

  Partial-recovery bound(s) \\\varepsilon \ge 0\\; the default
  reproduces the working paper's sensitivity grid.

## Value

A tibble with columns `A`, `eps`, `lower`, `upper` (one row per `A`
\\\times\\ `eps` combination).

## Examples

``` r
ec_recovery_set(0.511)                   # Brexit 1M clock
#> # A tibble: 4 × 4
#>       A   eps lower upper
#>   <dbl> <dbl> <dbl> <dbl>
#> 1 0.511  0    0.511 0.511
#> 2 0.511  0.1  0.414 0.618
#> 3 0.511  0.25 0.287 0.798
#> 4 0.511  0.5  0.128 1.15 
ec_recovery_set(c(0.064, 0.166), eps = 0.25)
#> # A tibble: 2 × 4
#>       A   eps  lower upper
#>   <dbl> <dbl>  <dbl> <dbl>
#> 1 0.064  0.25 0.036  0.1  
#> 2 0.166  0.25 0.0934 0.259
```
