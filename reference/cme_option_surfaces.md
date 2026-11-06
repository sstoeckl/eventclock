# Option surfaces from CME Globex settlements

Joins option and futures settlement prices to their instrument
definitions and returns one row per valuation date, expiry, and strike,
with the futures price as forward, time to expiry, Black (1976) implied
volatilities, vega, log-forward moneyness, open interest, and a put-call
parity diagnostic. The output feeds
[`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_fit.md)
(columns `surface`, `k`, `iv`, `tau`, and `q` when `x` is supplied),
[`ec_mix_iv_pre()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price_pre.md),
and
[`ec_quiet_library()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_quiet_library.md)
directly.

## Usage

``` r
cme_option_surfaces(
  definitions,
  statistics,
  assets = NULL,
  from = NULL,
  to = NULL,
  rate = 0,
  settle_time = "14:00",
  tz = "America/Chicago",
  invert = FALSE,
  min_price = 0,
  x = NULL
)
```

## Arguments

- definitions:

  Output of
  [`cme_definitions()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_definitions.md),
  or anything it accepts.

- statistics:

  Output of
  [`cme_statistics()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_statistics.md),
  or anything it accepts.

- assets:

  Optional product codes of the options to keep (for example
  `c("6M", "1M", "2M")`).

- from, to:

  Optional first and last trading date.

- rate:

  Continuously compounded annual interest rate for discounting: a number
  (default 0) or a function of `(date, tau)` returning one rate per row.

- settle_time, tz:

  Valuation clock time and time zone (default `"14:00"`,
  `"America/Chicago"`).

- invert:

  Logical; express prices per unit of the quote currency (see Details).
  Default `FALSE`.

- min_price:

  Settlements at or below this value get no implied volatility (default
  0).

- x:

  Optional `event_prices` object; adds `q`, the last event probability
  at or before each valuation time.

## Value

A tibble with one row per trading date, product, expiry, and strike:
`surface` (identifier `asset date expiry`), `date`, `valuation`,
`asset`, `underlying`, `expiry`, `exercise`, `tau`, `F`, `F_final`,
`strike`, `k` (\\\log(K/F)\\), `call`, `put`, `call_final`, `put_final`,
`oi_call`, `oi_put`, `iv`, `iv_call`, `iv_put`, `otm` (side used for
`iv`), `vega` (price change per unit of annualized volatility),
`parity_gap`, `parity_gap_rel`, `F_parity`, `call_id`, `put_id`,
`call_symbol`, `put_symbol` (exchange symbols of the contracts used;
with `invert = TRUE` the original put is the new call), and `q` if `x`
is supplied.

## Details

**Which contract.** Instrument identifiers are reused (see
[`cme_definitions()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_definitions.md)),
so each daily statistic is attributed to the definition phase in force
on its trading date: the latest phase of its identifier that started on
or before that date (UTC calendar of the daily definition snapshots),
provided the next phase has not started, the phase was not deleted
earlier, and the contract had not expired (trading date after the
expiration date). Statistics outside every phase are dropped, including
settlements dated before a contract's first definition record, such as
the theoretical reference settlement the exchange sends with a new
listing, dated the previous session.

**Forward and timing.** Each option is matched to its underlying future
through `underlying_id`; the forward is that future's settlement on the
same trading date. Where both symbols are published, the future's
`raw_symbol` must equal the option's `underlying`; otherwise the forward
is missing. The valuation time is `settle_time` on the trading date in
time zone `tz` (14:00 Chicago time, the settlement time of CME currency
futures and options); time to expiry `tau` is measured in years of 365
days from the valuation time to the published `expiration`. Options with
`tau <= 0` are dropped.

**Implied volatility.** Prices are discounted with \\e^{-r\tau}\\
(`rate`) and inverted in the Black (1976) model. `iv_call` and `iv_put`
are both reported; `iv` is the out-of-the-money side (calls at or above
the forward, puts below it). Settlements at or below `min_price`, or
outside the no-arbitrage interval, give `NA`. For American-style options
(see `exercise`) the Black volatility is a European approximation;
quantify the early-exercise premium separately (for example on a
binomial tree) before relying on in-the-money quotes.

**Inverted quotes.** CME quotes currency futures in U.S. dollars per
unit of foreign currency (for example `6M`: dollars per peso). With
`invert = TRUE` all quantities are re-expressed per dollar: forward
\\1/F\\, strike \\1/K\\, calls and puts swap roles, and prices are
converted with \\C'(1/K) = P(K)/(FK)\\ and \\P'(1/K) = C(K)/(FK)\\.
Implied volatilities are unchanged and log-moneyness changes sign.

**Parity diagnostic.** `parity_gap` is \\(C - P)/e^{-r\tau} - (F - K)\\,
in forward price units, and `parity_gap_rel` divides it by \\F\\;
`F_parity` is the forward implied by the call-put pair. Large gaps flag
stale or mismatched settlements (American options can deviate slightly
by construction).

## References

Black, F. (1976). The pricing of commodity contracts. *Journal of
Financial Economics* 3, 167–179.

## See also

[`cme_definitions()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_definitions.md),
[`cme_statistics()`](https://www.sebastianstoeckl.com/eventclock/reference/cme_statistics.md),
[`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_fit.md),
[`ec_quiet_library()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_quiet_library.md).

## Examples

``` r
# one future and a call/put pair, priced at 10% volatility
F0 <- 0.0540; K <- 0.0545; tau <- 30 / 365
s <- 0.10 * sqrt(tau)
d1 <- (log(F0 / K) + s^2 / 2) / s
cl <- F0 * pnorm(d1) - K * pnorm(d1 - s)
pt <- cl - (F0 - K)
defs <- data.frame(
  instrument_id = 1:3, instrument_class = c("F", "C", "P"),
  asset = "6M", cfi = c("FFCXSX", "OCEFPS", "OPEFPS"),
  expiration = as.POSIXct("2016-07-01 19:00", tz = "UTC") +
    c(80, 30, 30) * 86400,
  strike_price = c(NA, K, K), underlying_id = c(0, 1, 1)
)
st <- data.frame(
  instrument_id = 1:3, stat_type = 3, stat_flags = 3L,
  ts_event = as.POSIXct("2016-07-01 22:00", tz = "UTC"),
  ts_ref = as.POSIXct("2016-07-01", tz = "UTC"),
  price = c(F0, cl, pt)
)
cme_option_surfaces(defs, st)[, c("date", "tau", "F", "k", "iv", "parity_gap")]
#> # A tibble: 1 × 6
#>   date          tau     F       k    iv parity_gap
#>   <date>      <dbl> <dbl>   <dbl> <dbl>      <dbl>
#> 1 2016-07-01 0.0822 0.054 0.00922 0.100          0
```
