# Download Polymarket price history for one outcome token

Pulls the price history of a CLOB outcome token from the public
`/prices-history` endpoint and returns it as an
[`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
object. The Polymarket price is already a probability in \\\[0,1\]\\.

## Usage

``` r
pm_prices(
  token_id,
  from,
  to,
  fidelity = 60,
  chunk_days = NULL,
  market_id = NULL,
  event_date = NULL
)
```

## Arguments

- token_id:

  Character, the CLOB token id (from
  [`pm_markets()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_markets.md)).

- from, to:

  Start and end of the window (`Date` or `POSIXct`, interpreted in UTC).

- fidelity:

  Integer, bar size in minutes (60 = hourly, 1440 = daily; default 60).

- chunk_days:

  Integer, chunk length in days (default: `max(1, floor(fidelity / 6))`,
  i.e. 10 days for hourly bars).

- market_id:

  Optional label stored on the result (default: the token id).

- event_date:

  Optional scheduled event date stored on the result.

## Value

An `event_prices` object with `time` (`POSIXct`, UTC) and `q`.

## Details

The endpoint caps the number of points per call (a few hundred), so the
requested window is split into chunks and stitched (deduplicated on the
timestamp). The default chunk length adapts to `fidelity`; with
`fidelity = 60` (hourly bars) chunks of 10 days are used.

## Examples

``` r
if (FALSE) { # \dontrun{
mkts <- pm_markets("presidential-election-winner-2024")
tok <- mkts$token_id[grepl("Trump", mkts$question) & mkts$outcome == "Yes"]
ep <- pm_prices(tok, from = "2024-06-01", to = "2024-11-06")
event_clock(pm_daily(ep))
} # }
```
