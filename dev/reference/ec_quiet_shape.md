# Ordinary-risk template shape for a target

Predicts a target surface's smile shape from earlier quiet surfaces, for
one or more template rules. Only library surfaces whose whole option
life ended at or before `cutoff` are eligible, so no information from
after the target's valuation date enters. The target contributes only
its valuation date, expiry, at-the-money volatility (which sets the
level and ranks templates for `atm<n>` rules), and the moneyness points
to predict at — never its wings.

## Usage

``` r
ec_quiet_shape(
  library,
  date,
  expiry,
  atm_iv,
  k,
  rules = ec_quiet_rules(),
  cutoff = date,
  exclude_block = NULL,
  tau = NULL
)
```

## Arguments

- library:

  An
  [`ec_quiet_library()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_library.md).

- date, expiry:

  Target valuation date and expiry (`Date` or `POSIXct`).

- atm_iv:

  Target at-the-money implied volatility.

- k:

  Log-forward moneyness points at which to predict.

- rules:

  Rule table from
  [`ec_quiet_rules()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_rules.md).

- cutoff:

  Templates must have expired at or before this time (default: the
  target's `date`); `NULL` disables the restriction (for a fixed,
  already pre-target library).

- exclude_block:

  Maturity block(s) to leave out.

- tau:

  Target time to expiry in years, used with a standardized library
  (default: calendar days to expiry / 365).

## Value

A tibble with one row per rule and point `k`: `rule`, `k`, `z`
(standardized moneyness; `NA` without a target ATM level), `shape`
(median template shape; `NA` where no template covers `k`), `iv_pred`
(target ATM volatility combined with the shape), `n_templates`
(templates covering `k`), `n_selected` (templates the rule selected),
and `threshold` (clock threshold applied). The attribute `templates`
lists the selected surfaces per rule.

## See also

[`ec_quiet_select()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_select.md).

## Examples

``` r
nodes <- expand.grid(i = 1:6, k = c(-0.2, -0.1, 0, 0.1, 0.2))
nodes$surface <- paste0("s", nodes$i)
nodes$date <- as.Date("2024-09-02") + 7 * (nodes$i - 1)
nodes$expiry <- nodes$date + 4
nodes$A <- c(0.01, 0.30, 0.02, 0.25, 0.03, 0.40)[nodes$i]
# quiet surfaces carry a symmetric smile, busy ones an added skew
nodes$iv <- 0.5 + 0.8 * nodes$k^2 - ifelse(nodes$A > 0.1, 0.3 * nodes$k, 0)
lib <- ec_quiet_library(nodes)
ec_quiet_shape(lib, date = as.Date("2024-10-14"), expiry = as.Date("2024-10-18"),
               atm_iv = 0.55, k = c(-0.1, 0.1),
               rules = ec_quiet_rules(0.5, aggregation = "all"))
#> # A tibble: 2 × 8
#>   rule                    k     z shape iv_pred n_templates n_selected threshold
#>   <chr>               <dbl> <dbl> <dbl>   <dbl>       <int>      <int>     <dbl>
#> 1 p50 | any DTE | all  -0.1 -1.74 8.e-3   0.558           3          3      0.14
#> 2 p50 | any DTE | all   0.1  1.74 8.e-3   0.558           3          3      0.14
```
