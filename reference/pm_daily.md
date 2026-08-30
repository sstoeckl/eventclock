# Collapse intraday event prices to one daily snapshot

Takes the last observation at or before `snapshot_hour` (local time in
`tz`) of each calendar day — the convention used to align prediction
market prices with market closes (e.g. 16:00 New York time for US
equities).

## Usage

``` r
pm_daily(x, tz = "America/New_York", snapshot_hour = 16)
```

## Arguments

- x:

  An `event_prices` object with intraday timestamps.

- tz:

  Character time zone of the snapshot (default `"America/New_York"`).

- snapshot_hour:

  Numeric, snapshot cutoff hour in `tz` (default 16).

## Value

An `event_prices` object with one (Date-typed) observation per day.

## Details

Seconds are deliberately truncated when comparing against the cutoff: an
observation stamped `16:00:59` still counts as `16:00`. API bars are
typically stamped a few seconds after the full hour they represent, so
minute precision is the robust convention for bar data. The stored
`event_date` attribute is coerced to `Date` to match the collapsed time
scale.

## Examples

``` r
if (FALSE) { # \dontrun{
ep <- pm_prices(tok, from = "2024-06-01", to = "2024-11-06")
daily <- pm_daily(ep)
} # }
```
