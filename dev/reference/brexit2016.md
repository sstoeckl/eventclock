# Brexit 2016 event probabilities

Daily probabilities of the United Kingdom remaining in the European
Union, derived from betting quotes across multiple platforms, from
2016-02-26 to referendum day 2016-06-23 (119 calendar days including
weekends). `q_leave = 1 - q_remain` is the series used in the
accompanying working paper.

## Usage

``` r
brexit2016
```

## Format

A tibble with 119 rows and 3 columns:

- date:

  Calendar date (`Date`).

- q_remain:

  Probability of Remain, from betting quotes.

- q_leave:

  Probability of Leave, `1 - q_remain`.

## Source

Betting-market state prices as in Hanke, M., Poulsen, R., and
Weissensteiner, A. (2018), "Event-Related Exchange-Rate Forecasts
Combining Information from Betting Quotes and Option Prices", *Journal
of Financial and Quantitative Analysis* 53(6), 2663–2683. Used in Hanke,
Schadner, Stöckl, and Weissensteiner (Working Paper), "Learning Before
Scheduled Events: Prediction Markets, State Prices, and Option
Valuation".

## Examples

``` r
data(brexit2016)
ep <- as_event_prices(brexit2016, time = "date", price = "q_leave",
                      event_date = as.Date("2016-06-23"))
event_clock(ep, from = as.Date("2016-05-24"))
#> # A tibble: 5 × 10
#>   market_id from       to         horizon    n_obs n_incr n_gaps max_gap_days
#>   <chr>     <date>     <date>     <chr>      <int>  <int>  <int>        <dbl>
#> 1 NA        2016-05-24 2016-06-23 2016-06-23    31     30      0            1
#> 2 NA        2016-05-24 2016-06-23 2016-06-23    31     30      0            1
#> 3 NA        2016-05-24 2016-06-23 2016-06-23    31     30      0            1
#> 4 NA        2016-05-24 2016-06-23 2016-06-23    31     30      0            1
#> 5 NA        2016-05-24 2016-06-23 2016-06-23    31     30      0            1
#> # ℹ 2 more variables: method <chr>, A <dbl>
```
