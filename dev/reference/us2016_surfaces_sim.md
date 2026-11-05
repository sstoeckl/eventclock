# Simulated event-spanning option surfaces, 2016 U.S. election profile

**Simulated** implied-volatility surfaces for event-spanning options
around the 2016 U.S. presidential election (event date 2016-11-08),
matching the empirical profile of S&P 500 index options over the last
four pre-election weeks. Every implied volatility is generated from the
lognormal event mixture of
[`ec_mix_iv()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_mix_price.md)
plus Gaussian noise (sd 0.004); the generator is parametrized by
estimation results only — a common log exposure \\\theta = -0.077\\ and
per-surface conditional dispersions and event probabilities fitted with
[`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_theta_fit.md)
— so the dataset contains no third-party data values. 47 surfaces
(valuation dates 2016-10-11 to 2016-11-07, expiries 2016-11-16/18/21) on
a nine-point call-equivalent delta grid. The event probabilities are the
Trump series of
[us2016](https://www.sebastianstoeckl.com/eventclock/dev/reference/us2016.md).

## Usage

``` r
us2016_surfaces_sim
```

## Format

A tibble with 423 rows and 6 columns:

- event_date:

  Election day (`Date`), 2016-11-08.

- obs_date:

  Valuation date (`Date`).

- expiry_date:

  Option expiry (`Date`), after the election.

- node:

  Call-equivalent delta grid node (0.1-0.9).

- iv:

  Simulated annualized Black implied volatility.

- q:

  State-price-implied probability of a Trump win at `obs_date` (from
  [us2016](https://www.sebastianstoeckl.com/eventclock/dev/reference/us2016.md)).

## Source

Simulated; see `data-raw/us2016_surfaces_sim.R`. Calibration targets
estimated from index-option surfaces around the 2016 election; used in
the event-spanning vignette.

## Examples

``` r
data(us2016_surfaces_sim)
head(us2016_surfaces_sim)
#> # A tibble: 6 × 6
#>   event_date obs_date   expiry_date  node    iv     q
#>   <date>     <date>     <date>      <dbl> <dbl> <dbl>
#> 1 2016-11-08 2016-10-11 2016-11-18    0.1 0.110 0.164
#> 2 2016-11-08 2016-10-11 2016-11-18    0.2 0.113 0.164
#> 3 2016-11-08 2016-10-11 2016-11-18    0.3 0.117 0.164
#> 4 2016-11-08 2016-10-11 2016-11-18    0.4 0.116 0.164
#> 5 2016-11-08 2016-10-11 2016-11-18    0.5 0.123 0.164
#> 6 2016-11-08 2016-10-11 2016-11-18    0.6 0.138 0.164
```
