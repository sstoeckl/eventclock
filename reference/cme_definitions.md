# Read CME Globex instrument definitions

Reads instrument definitions in Databento's `definition` schema for the
CME Globex dataset (`GLBX.MDP3`) and keeps one row per instrument
*phase*: the period during which an instrument identifier denotes one
contract. Every column is coerced by content, not by its stored type, so
files in which all columns arrived as text (which happens when one
column holds an unexpected value) read the same as typed files.

## Usage

``` r
cme_definitions(x, classes = c("C", "P", "F"))
```

## Arguments

- x:

  A `data.frame` of definition records, or path(s) to Parquet (needs the
  arrow package) or CSV files, or directories containing them.

- classes:

  Instrument classes to keep: `"C"` call, `"P"` put, `"F"` future
  (default). Spreads (`"S"`, `"T"`, `"M"`) are dropped unless listed.

## Value

A tibble of class `cme_definitions`, one row per instrument phase, with
columns `instrument_id`, `valid_from`, `valid_to` (POSIXct, UTC),
`deleted` (logical: the phase ended with a deletion record), `ts_recv`
(receive time of the phase's most recent record), `raw_symbol`, `asset`
(product code, e.g. `"6M"`), `instrument_class`, `type` (`"call"`,
`"put"`, `"future"`, or `NA`), `exercise` (`"american"`, `"european"`,
or `NA`), `cfi`, `expiration` (POSIXct, UTC), `strike`, `underlying_id`,
`underlying`, `currency`, `unit_of_measure`.

## Details

**Reused identifiers.** The exchange assigns an expired or deleted
contract's `instrument_id` to a new contract, sometimes within days and
across classes (a call can become a put, a spread an option). A phase is
a run of records for one identifier with the same `raw_symbol` (or,
without symbols, the same class, strike, and expiration date), in
receive-time order. A modification that only changes, say, the
expiration time stays in the same phase; a deletion record
(`security_update_action = "D"`) ends it. Each phase reports the
attributes of its most recent record and is valid from its first record
(`valid_from`) until the next phase of the same identifier starts or the
deletion arrives (`valid_to`; `NA` while open).
[`cme_option_surfaces()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_option_surfaces.md)
assigns each daily statistic to the phase in force on its trading date.

**Exercise style.** For options, the third character of the ISO 10962
CFI code is the exercise style (`A` American, `E` European). On CME
currency options it differs across products and years — for example,
weekly and monthly contracts on the same future can differ — so it is
read per instrument rather than assumed.

**Expiration.** `expiration` is the last eligible trade time (UTC) as
published by the exchange. Expiry times differ across products and
years, so use this field rather than a fixed clock time.

## References

Databento documentation of the instrument-definition schema and of the
CME Globex MDP 3.0 dataset (GLBX.MDP3),
<https://databento.com/docs/venues-and-datasets/glbx-mdp3>.

## See also

[`cme_statistics()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_statistics.md),
[`cme_option_surfaces()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_option_surfaces.md).

## Examples

``` r
defs <- data.frame(
  ts_recv = c("2016-06-01T00:00:00Z", "2016-06-02T00:00:00Z", "2016-06-01T00:00:00Z"),
  instrument_id = c("11", "11", "20"),
  raw_symbol = c("6BN6 C1450", "6BN6 C1450", "6BN6"),
  asset = c("6B", "6B", "6B"),
  instrument_class = c("C", "C", "F"),
  cfi = c("OCAFPS", "OCAFPS", "FFCXSX"),
  expiration = c("2016-07-08T19:00:00Z", "2016-07-08T19:00:00Z", "2016-09-19T14:16:00Z"),
  strike_price = c("1.45", "1.45", ""),
  underlying_id = c("20", "20", "0")
)
cme_definitions(defs)
#> # A tibble: 2 × 17
#>   instrument_id valid_from          valid_to deleted
#>           <dbl> <dttm>              <dttm>   <lgl>  
#> 1            11 2016-06-01 00:00:00 NA       FALSE  
#> 2            20 2016-06-01 00:00:00 NA       FALSE  
#> # ℹ 13 more variables: ts_recv <dttm>, raw_symbol <chr>, asset <chr>,
#> #   instrument_class <chr>, type <chr>, exercise <chr>, cfi <chr>,
#> #   expiration <dttm>, strike <dbl>, underlying_id <dbl>, underlying <chr>,
#> #   currency <chr>, unit_of_measure <chr>
```
