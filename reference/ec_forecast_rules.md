# Candidate rules for real-time clock forecasts

Builds the grid of forecasting rules compared by
[`ec_forecast_select()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_forecast_select.md):
trailing windows measured in observations or in calendar days,
optionally the expanding (all-history) window, crossed with the
estimators to compare.

## Usage

``` r
ec_forecast_rules(obs = NULL, days = NULL, expanding = FALSE, methods = "rv")
```

## Arguments

- obs:

  Integer vector of trailing-observation window sizes.

- days:

  Numeric vector of trailing calendar-day window lengths.

- expanding:

  Logical; include the expanding window.

- methods:

  Estimators to cross with the windows (see
  [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md)).

## Value

A tibble with columns `rule`, `type`, `window`, `method`.

## Examples

``` r
# the working paper's grid for hourly prediction-market data
ec_forecast_rules(days = c(3, 5, 7, 10, 14, 20), expanding = TRUE)
#> # A tibble: 7 × 4
#>   rule                  type      window method
#>   <chr>                 <chr>      <dbl> <chr> 
#> 1 trailing 3 days / rv  days           3 rv    
#> 2 trailing 5 days / rv  days           5 rv    
#> 3 trailing 7 days / rv  days           7 rv    
#> 4 trailing 10 days / rv days          10 rv    
#> 5 trailing 14 days / rv days          14 rv    
#> 6 trailing 20 days / rv days          20 rv    
#> 7 expanding / rv        expanding     NA rv    
# its grid for daily data
ec_forecast_rules(obs = c(20, 40, 60),
                  methods = c("rv", "truncated", "bipower"))
#> # A tibble: 9 × 4
#>   rule                        type  window method   
#>   <chr>                       <chr>  <dbl> <chr>    
#> 1 trailing 20 obs / rv        obs       20 rv       
#> 2 trailing 40 obs / rv        obs       40 rv       
#> 3 trailing 60 obs / rv        obs       60 rv       
#> 4 trailing 20 obs / truncated obs       20 truncated
#> 5 trailing 40 obs / truncated obs       40 truncated
#> 6 trailing 60 obs / truncated obs       60 truncated
#> 7 trailing 20 obs / bipower   obs       20 bipower  
#> 8 trailing 40 obs / bipower   obs       40 bipower  
#> 9 trailing 60 obs / bipower   obs       60 bipower  
```
