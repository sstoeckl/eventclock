# Standardize traded event probabilities as an `event_prices` object

`as_event_prices()` turns a `data.frame`/`tibble` holding a time series
of traded event probabilities (prediction-market prices, betting quotes,
state prices) into a standardized `event_prices` tibble that all
estimation and plotting functions of the package understand.

## Usage

``` r
as_event_prices(x, ...)

# S3 method for class 'event_prices'
as_event_prices(x, ...)

# S3 method for class 'data.frame'
as_event_prices(
  x,
  time = NULL,
  price = NULL,
  bid = NULL,
  ask = NULL,
  scale = 1,
  discount = 1,
  book = NULL,
  method = c("discount", "overround"),
  clip = ec_default_params()$clip,
  market_id = NULL,
  event_date = NULL,
  ...
)

# S3 method for class 'event_prices'
print(x, ...)

# S3 method for class 'event_prices'
summary(object, ...)

# S3 method for class 'event_prices'
plot(x, ...)
```

## Arguments

- x:

  A `data.frame`/`tibble` (or an existing `event_prices` object,
  returned unchanged).

- ...:

  Reserved for future methods.

- time:

  Name of the time column (character). If `NULL`, the first of `time`,
  `date`, `timestamp`, `datetime`, `t` (case-insensitive) is used.

- price:

  Name of the price/probability column (character). If `NULL`, the first
  of `q`, `price`, `p`, `q_t`, `value` (case-insensitive) is used.
  Ignored when `bid` and `ask` are given.

- bid, ask:

  Optional names of bid and ask columns; if both are given, the mid
  quote is used as price.

- scale:

  Numeric, divisor applied to the raw price first (use `scale = 100` for
  percent quotes; default 1).

- discount, book, method:

  Passed to
  [`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_price.md).

- clip:

  Numeric length-2, clipping bounds applied to `q` before the log-odds
  transform (default `c(0.01, 0.99)`, see
  [`ec_default_params()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_default_params.md)).

- market_id:

  Optional character label of the market.

- event_date:

  Optional `Date`/`POSIXct` of the scheduled event (resolution) date.

- object:

  An `event_prices` object (for
  [`summary()`](https://rdrr.io/r/base/summary.html)).

## Value

An `event_prices` tibble; see Details.

## Details

The constructor follows a strict *flag, don't drop* convention: raw
values are kept in `q_raw`, data problems are recorded in flag columns,
and nothing is silently deleted. The only structural interventions are
sorting by time and removing duplicated timestamps (keeping the first
occurrence, with a warning), because increments are undefined otherwise.

Columns of the returned object:

- time:

  `Date` or `POSIXct` timestamp (sorted, unique).

- q_raw:

  the raw input price after rescaling by `scale`.

- q:

  the normalized probability, `q_from_price(q_raw, ...)`.

- flag_na:

  `TRUE` where `q` is missing.

- flag_clip:

  `TRUE` where `q` falls outside the clipping bounds and will be clipped
  before the log-odds transform in
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md).

The clipping bounds, market id, and event date are stored as attributes
(`clip`, `market_id`, `event_date`) and are picked up by
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md),
[`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md),
and the plotting functions.

**Timezones.** A `POSIXct` time column is kept in the timezone it
carries; character timestamps are parsed as UTC. Window bounds passed as
`Date` to
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md)
and friends are interpreted in the series' timezone (with `to` covering
the full day), so mixing `Date` bounds with a non-UTC intraday series is
safe.

## Functions

- `print(event_prices)`: Print method; shows market, range, and flags.

- `summary(event_prices)`: Summary method; returns a one-row tibble
  including the full-sample event-clock estimate.

- `plot(event_prices)`: Plot method; dispatches to
  [`plot_q()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_q.md).

## Examples

``` r
data(brexit2016)
ep <- as_event_prices(brexit2016,
  time = "date", price = "q_leave",
  market_id = "Brexit: Leave", event_date = as.Date("2016-06-23")
)
ep
#> -- Event prices: Brexit: Leave
#> 119 observations, 2016-02-26 to 2016-06-23
#> Scheduled event: 2016-06-23
#> # A tibble: 119 × 5
#>    time       q_raw     q flag_na flag_clip
#>    <date>     <dbl> <dbl> <lgl>   <lgl>    
#>  1 2016-02-26 0.312 0.312 FALSE   FALSE    
#>  2 2016-02-27 0.315 0.315 FALSE   FALSE    
#>  3 2016-02-28 0.307 0.307 FALSE   FALSE    
#>  4 2016-02-29 0.307 0.307 FALSE   FALSE    
#>  5 2016-03-01 0.305 0.305 FALSE   FALSE    
#>  6 2016-03-02 0.296 0.296 FALSE   FALSE    
#>  7 2016-03-03 0.287 0.287 FALSE   FALSE    
#>  8 2016-03-04 0.262 0.262 FALSE   FALSE    
#>  9 2016-03-05 0.276 0.276 FALSE   FALSE    
#> 10 2016-03-06 0.279 0.279 FALSE   FALSE    
#> # ℹ 109 more rows
summary(ep)
#> # A tibble: 1 × 11
#>   market_id       n start      end        q_start q_end q_min q_max  n_na n_clip
#>   <chr>       <int> <date>     <date>       <dbl> <dbl> <dbl> <dbl> <int>  <int>
#> 1 Brexit: Le…   119 2016-02-26 2016-06-23   0.312  0.23  0.17   0.4     0      0
#> # ℹ 1 more variable: A_full <dbl>
```
