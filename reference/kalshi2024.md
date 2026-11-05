# Kalshi 2024 U.S. presidential election prices (daily 15:45 snapshot)

Daily prices of the Kalshi contract "Will Donald Trump or another
Republican win the Presidency?" (market `PRES-2024-DJT`), taken as the
last hourly price at or before 15:45 New York time, from the contract's
listing on October 4 to election day, November 5, 2024. Together with
the same snapshot of
[polymarket2024](https://www.sebastianstoeckl.com/eventclock/reference/polymarket2024.md)
it gives two synchronized venues for the same event — the input of
[`event_clock_venues()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_venues.md).

## Usage

``` r
kalshi2024
```

## Format

A tibble with 33 rows and 2 columns:

- date:

  Calendar date (`Date`).

- q:

  Traded price of the "Yes" contract (0-1).

## Source

Kalshi public trade API (v2), downloaded with
[`ks_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/ks_prices.md);
see `data-raw/kalshi2024.R`.

## Examples

``` r
data(kalshi2024)
data(polymarket2024)
pm <- pm_daily(as_event_prices(polymarket2024), snapshot_hour = 15.75)
ks <- as_event_prices(kalshi2024, time = "date", price = "q")
event_clock_venues(pm, ks, labels = c("Polymarket", "Kalshi"))
#> # A tibble: 1 × 13
#>   venue_x venue_y from       to         horizon n_common   A_x   A_y A_composite
#>   <chr>   <chr>   <date>     <date>     <chr>      <int> <dbl> <dbl>       <dbl>
#> 1 Polyma… Kalshi  2024-10-04 2024-11-05 2024-1…       33 0.262 0.223       0.213
#> # ℹ 4 more variables: A_cross <dbl>, corr <dbl>, noise_share_x <dbl>,
#> #   noise_share_y <dbl>
```
