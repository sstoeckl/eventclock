# Event Clocks from two venues: separating common news from venue noise

When the same event trades on two venues (say Polymarket and Kalshi),
each venue's measured clock contains the common information flow plus
venue-specific noise (bid-ask bounce, stale quotes, idiosyncratic
flows). Comparing four clocks built from synchronized prices separates
the two:

- `A_x`, `A_y`:

  each venue's own clock, \\\sum (\Delta L)^2\\.

- `A_composite`:

  the clock of the equal-weight average of the two venues' log odds.

- `A_cross`:

  the cross-venue clock \\\sum \Delta L^x \Delta L^y\\: news moves both
  venues, so it survives the product; independent venue noise does not,
  so on average it drops out.

## Usage

``` r
event_clock_venues(x, y, from = NULL, to = NULL, labels = NULL, clip = NULL)
```

## Arguments

- x, y:

  `event_prices` objects (or coercible) for the same event outcome on
  two venues.

- from:

  Valuation date/time (default: first observation).

- to:

  One or more horizon dates/times (default: last observation = full
  sample). Names are used as horizon labels.

- labels:

  Optional venue labels (default: the `market_id`s).

- clip:

  Numeric length-2 clipping bounds for `q` before the log-odds
  transform; defaults to the bounds stored in `x`.

## Value

A tibble with one row per horizon: `venue_x`, `venue_y`, `from`, `to`,
`horizon`, `n_common` (synchronized observations), `A_x`, `A_y`,
`A_composite`, `A_cross`, `corr` (correlation of the two venues'
log-odds changes), `noise_share_x`, `noise_share_y`.

## Details

Under a simple benchmark in which each venue's log odds are the common
latent log odds plus independent noise, \\E\[A_x\] = A + N_x\\ while
\\E\[A\_{cross}\] = A\\. The reported `noise_share_x` \\= 1 -
A\_{cross}/A_x\\ is then the fraction of venue x's measured clock
attributable to its own noise. In finite samples `A_cross` can fall
below zero when there is little common news; it is a diagnostic, not an
exact measurement. The identity \\A\_{composite} = (A_x + A_y +
2A\_{cross})/4\\ holds exactly.

Multiple venues help diagnose timing and filter venue-specific noise,
but they cannot by themselves pin down the absolute physical clock
scale; that still rests on the recovery restriction (see
[`ec_recovery_set()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_recovery_set.md)).

Prices are matched on identical timestamps. Synchronize intraday series
first, e.g. with a common daily snapshot:
`pm_daily(x, snapshot_hour = 15.75)` takes the last price at or before
15:45 New York time.

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "The Event
Clock: What State Prices Identify About Physical Information".

## See also

[`event_clock_venues_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_venues_path.md)
for the cumulative clocks.

## Examples

``` r
# two noisy venues observing the same simulated news
set.seed(7)
p <- ec_simulate_path(1, 120, q = 0.5, A = 1)
days <- as.Date("2024-06-01") + 0:120
noisy <- function(sd) data.frame(time = days,
  q = ec_ilogit(p$L + stats::rnorm(121, sd = sd)))
event_clock_venues(noisy(0.05), noisy(0.10), labels = c("A", "B"))
#> # A tibble: 1 × 13
#>   venue_x venue_y from       to         horizon n_common   A_x   A_y A_composite
#>   <chr>   <chr>   <date>     <date>     <chr>      <int> <dbl> <dbl>       <dbl>
#> 1 A       B       2024-06-01 2024-09-29 2024-0…      121  1.32  2.94        1.50
#> # ℹ 4 more variables: A_cross <dbl>, corr <dbl>, noise_share_x <dbl>,
#> #   noise_share_y <dbl>
```
