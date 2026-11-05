# Download Kalshi price history for one market

Pulls candlesticks for a Kalshi market from the public API and returns
them as an `event_prices` object, ready for
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)
and friends. Settled markets are served by the historical endpoint, live
markets by the series endpoint; `ks_prices()` tries the former first.
Long periods are split into chunks automatically.

## Usage

``` r
ks_prices(
  ticker,
  from = NULL,
  to = NULL,
  interval = c("1h", "1d", "1m"),
  price = c("close", "mid"),
  series_ticker = NULL,
  market_id = ticker,
  event_date = NULL
)
```

## Arguments

- ticker:

  Character, the market ticker (from
  [`ks_markets()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ks_markets.md)).

- from, to:

  Start and end (anything
  [`as.POSIXct()`](https://rdrr.io/r/base/as.POSIXlt.html) understands,
  in UTC); default: the last 30 days.

- interval:

  Candle length: `"1h"` (default), `"1d"`, or `"1m"`.

- price:

  `"close"` (last trade, default) or `"mid"`.

- series_ticker:

  Optional series ticker for live markets (default: the part of `ticker`
  before the first `-`).

- market_id, event_date:

  Passed to
  [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md).

## Value

An `event_prices` object with `POSIXct` (UTC) timestamps at the end of
each candle.

## Details

Kalshi returns a candle only for periods with activity, so hourly and
minute series have gaps in quiet periods (see the gap diagnostics of
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)).
`price = "close"` uses the last traded price of each candle;
`price = "mid"` the midpoint of the closing bid and ask, which is less
exposed to bid-ask bounce. To compare with another venue, take a common
daily snapshot, e.g. `pm_daily(x, snapshot_hour = 15.75)` for 15:45 New
York time.

## See also

[`ks_markets()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ks_markets.md),
[`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_prices.md),
[`event_clock_venues()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_venues.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ks <- ks_prices("PRES-2024-DJT", from = "2024-10-04", to = "2024-11-06",
                market_id = "Kalshi: Trump wins 2024")
event_clock(pm_daily(ks, snapshot_hour = 15.75))
} # }
```
