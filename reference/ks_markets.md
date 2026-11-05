# List the markets of a Kalshi event

Kalshi organizes contracts as *series* (e.g. `"PRES"`), *events* (one
occurrence, e.g. `"PRES-2024"`), and *markets* (one binary contract per
outcome, e.g. `"PRES-2024-DJT"`). `ks_markets()` lists the markets of an
event from both the live and the historical (settled) endpoints of the
public API; `ks_events()` lists the events of a series.

## Usage

``` r
ks_markets(event_ticker)

ks_events(series_ticker)
```

## Arguments

- event_ticker:

  Character, the event ticker.

- series_ticker:

  Character, the series ticker (e.g. `"PRES"`, `"KXFEDDECISION"`).

## Value

A tibble with columns `ticker`, `event_ticker`, `title`, `outcome`
(Kalshi's `yes_sub_title`), `status`, `open_time`, `close_time`, and
`result`.

`ks_events()`: a tibble with columns `event_ticker`, `series_ticker`,
`title`, and `sub_title`.

## See also

[`ks_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/ks_prices.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ks_events("PRES")
ks_markets("PRES-2024")
} # }
```
