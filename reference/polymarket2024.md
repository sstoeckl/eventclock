# Polymarket 2024 U.S. presidential election prices (hourly)

Hourly prices of the Polymarket contract "Will Donald Trump win the 2024
US presidential election?" (the "Yes" outcome token), June to November
2024, downloaded from the public CLOB API with
[`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_prices.md).
The claim price is the U.S.-dollar-numeraire event state price — the
state-price-implied event probability up to discounting. This dataset
powers the intraday examples; rebuild it any time with the script in
`data-raw/`.

## Usage

``` r
polymarket2024
```

## Format

A tibble with hourly rows and 2 columns:

- time:

  Timestamp (`POSIXct`, UTC).

- q:

  Traded probability of the "Yes" outcome.

## Source

Polymarket public CLOB API,
<https://clob.polymarket.com/prices-history>, event
`presidential-election-winner-2024`.

## Examples

``` r
data(polymarket2024)
ep <- as_event_prices(polymarket2024,
  market_id = "Polymarket: Trump wins 2024",
  event_date = as.POSIXct("2024-11-05", tz = "UTC")
)
plot_clock(event_clock_path(ep))
```
