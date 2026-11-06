# Daily settlement prices and open interest from CME Globex statistics

Reduces Databento `statistics` records for the CME Globex dataset
(`GLBX.MDP3`) to one row per instrument and trading date: the settlement
price, its status, open interest, and cleared volume.

## Usage

``` r
cme_statistics(x, tz = "America/Chicago", price_scale = 1)
```

## Arguments

- x:

  A `data.frame` of statistics records, or path(s) to Parquet (needs the
  arrow package) or CSV files, or directories.

- tz:

  Exchange time zone used only for the `ts_ref` fallback (default
  `"America/Chicago"`).

- price_scale:

  Multiplier applied to `price` (default 1, for files with decimal
  prices; use `1e-9` for raw fixed-precision integers).

## Value

A tibble of class `cme_statistics` with columns `instrument_id`, `date`
(trading date), `settle`, `settle_final` (logical), `settle_flags`,
`open_interest`, `volume` (cleared volume).

## Details

**Which settlement.** The exchange publishes several settlement messages
per instrument and session: preliminary values first, the final value
last (and occasionally re-sends). Bit 0 of `stat_flags` marks a final
price (bit 1: actual rather than theoretical; bit 2: rounding to the
trading tick, or an unrounded preliminary price for products that are
not rounded; bit 3: intraday). For each instrument and trading date the
function keeps the *last final* message; if no final message exists, it
keeps the last preliminary one and sets `settle_final = FALSE`.

**Trading date.** The trading date is the exchange's trading reference
date (`ts_ref`), used at date precision without time-zone conversion.
Where `ts_ref` is missing, the publication time `ts_event` is converted
to the exchange time zone and weekend publications are assigned to the
preceding Friday session; messages with a reference date take precedence
over such fallback messages.

**Deletions and undefined values.** A record with `update_action = 2`
deletes the statistic: earlier records for the same instrument, type,
and date are discarded. Quantities equal to the 64-bit integer maximum
mean "undefined" and become `NA`.

## References

Databento documentation of the statistics schema and of the CME Globex
MDP 3.0 dataset (GLBX.MDP3),
<https://databento.com/docs/schemas-and-data-formats/statistics>.

## See also

[`cme_definitions()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/cme_definitions.md),
[`cme_option_surfaces()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/cme_option_surfaces.md).

## Examples

``` r
st <- data.frame(
  instrument_id = 11,
  ts_event = as.POSIXct(c("2016-06-01 19:00", "2016-06-01 21:40",
                          "2016-06-01 23:40"), tz = "UTC"),
  ts_ref = as.POSIXct("2016-06-01", tz = "UTC"),
  stat_type = 3,
  price = c(0.0101, 0.0102, 0.0102),
  stat_flags = c(4L, 2L, 3L)   # preliminary, actual preliminary, final
)
cme_statistics(st)
#> # A tibble: 1 × 7
#>   instrument_id date       settle settle_final settle_flags open_interest volume
#>           <dbl> <date>      <dbl> <lgl>               <int>         <dbl>  <dbl>
#> 1            11 2016-06-01 0.0102 TRUE                    3            NA     NA
```
