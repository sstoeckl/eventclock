# Pre-specified rules for the ordinary-risk template

Builds the grid of template rules, crossing a quietness threshold, a
days-to-expiry matching band, and an aggregation rule. Fixing the grid
before looking at the target is what makes the benchmark honest: the
rule is then chosen by
[`ec_quiet_select()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_quiet_select.md)
on earlier pseudo-targets only.

## Usage

``` r
ec_quiet_rules(
  quiet = c(0.25, 0.5, 0.75),
  quiet_type = c("quantile", "absolute"),
  dte_band = Inf,
  aggregation = c("all", "recent5", "recent10", "atm5", "atm10")
)
```

## Arguments

- quiet:

  Threshold values (probabilities or clock values).

- quiet_type:

  `"quantile"` (default) or `"absolute"`.

- dte_band:

  Maximum absolute difference in calendar days to expiry between
  template and target; `Inf` (default) for no matching.

- aggregation:

  Character vector of aggregation rules (see Details).

## Value

A tibble with one row per rule: `rule` (label), `quiet_type`, `quiet`,
`dte_band`, `aggregation`, `agg_type`, `agg_n`.

## Details

**Quietness threshold.** With `quiet_type = "quantile"`, `quiet` holds
probabilities and the threshold is that quantile of the realized clocks
of the surfaces available at the (pseudo-)target date; with
`"absolute"`, `quiet` holds clock values. Eligible templates have \\A\\
at or below the threshold.

**Aggregation.** `"all"` uses every eligible template; `"recent<n>"` the
`n` with the latest valuation dates; `"atm<n>"` the `n` whose
at-the-money volatility is closest to the target's. The template shape
is the node-by-node median across the selected templates.

The defaults give 15 rules (25th/50th/75th percentile × all, recent 5,
recent 10, 5 and 10 ATM-nearest, no DTE matching). A 30-rule variant:
`ec_quiet_rules(c(0.03, 0.04, 0.06), "absolute", dte_band = c(1, 2), aggregation = c("all", "atm1", "atm2", "atm3", "atm5"))`.

## See also

[`ec_quiet_select()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_quiet_select.md).

## Examples

``` r
ec_quiet_rules()
#> # A tibble: 15 × 7
#>    rule                     quiet_type quiet dte_band aggregation agg_type agg_n
#>    <chr>                    <chr>      <dbl>    <dbl> <chr>       <chr>    <int>
#>  1 p25 | any DTE | all      quantile    0.25      Inf all         all         NA
#>  2 p25 | any DTE | recent5  quantile    0.25      Inf recent5     recent       5
#>  3 p25 | any DTE | recent10 quantile    0.25      Inf recent10    recent      10
#>  4 p25 | any DTE | atm5     quantile    0.25      Inf atm5        atm          5
#>  5 p25 | any DTE | atm10    quantile    0.25      Inf atm10       atm         10
#>  6 p50 | any DTE | all      quantile    0.5       Inf all         all         NA
#>  7 p50 | any DTE | recent5  quantile    0.5       Inf recent5     recent       5
#>  8 p50 | any DTE | recent10 quantile    0.5       Inf recent10    recent      10
#>  9 p50 | any DTE | atm5     quantile    0.5       Inf atm5        atm          5
#> 10 p50 | any DTE | atm10    quantile    0.5       Inf atm10       atm         10
#> 11 p75 | any DTE | all      quantile    0.75      Inf all         all         NA
#> 12 p75 | any DTE | recent5  quantile    0.75      Inf recent5     recent       5
#> 13 p75 | any DTE | recent10 quantile    0.75      Inf recent10    recent      10
#> 14 p75 | any DTE | atm5     quantile    0.75      Inf atm5        atm          5
#> 15 p75 | any DTE | atm10    quantile    0.75      Inf atm10       atm         10
ec_quiet_rules(c(0.03, 0.04, 0.06), "absolute", dte_band = c(1, 2),
               aggregation = c("all", "atm1", "atm2", "atm3", "atm5"))
#> # A tibble: 30 × 7
#>    rule                    quiet_type quiet dte_band aggregation agg_type agg_n
#>    <chr>                   <chr>      <dbl>    <dbl> <chr>       <chr>    <int>
#>  1 A<=0.03 | DTE+-1 | all  absolute    0.03        1 all         all         NA
#>  2 A<=0.03 | DTE+-1 | atm1 absolute    0.03        1 atm1        atm          1
#>  3 A<=0.03 | DTE+-1 | atm2 absolute    0.03        1 atm2        atm          2
#>  4 A<=0.03 | DTE+-1 | atm3 absolute    0.03        1 atm3        atm          3
#>  5 A<=0.03 | DTE+-1 | atm5 absolute    0.03        1 atm5        atm          5
#>  6 A<=0.03 | DTE+-2 | all  absolute    0.03        2 all         all         NA
#>  7 A<=0.03 | DTE+-2 | atm1 absolute    0.03        2 atm1        atm          1
#>  8 A<=0.03 | DTE+-2 | atm2 absolute    0.03        2 atm2        atm          2
#>  9 A<=0.03 | DTE+-2 | atm3 absolute    0.03        2 atm3        atm          3
#> 10 A<=0.03 | DTE+-2 | atm5 absolute    0.03        2 atm5        atm          5
#> # ℹ 20 more rows
```
