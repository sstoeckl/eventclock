# Choose the ordinary-risk template rule on earlier pseudo-targets

Cross-validates every rule of a pre-specified grid on earlier surfaces
treated as if they were the target ("pseudo-targets") and picks the rule
with the lowest wing-shape error. Each pseudo-target's whole maturity
block is left out of its template library, and with
`available_only = TRUE` only templates that had expired by the
pseudo-target's own valuation date are used. The real target's wings are
never consulted.

## Usage

``` r
ec_quiet_select(
  library,
  rules = ec_quiet_rules(),
  pseudo = NULL,
  pseudo_quiet = NULL,
  pseudo_min_dte = NULL,
  cutoff = NULL,
  available_only = TRUE,
  wing = NULL,
  common = TRUE,
  target = NULL
)
```

## Arguments

- library:

  An
  [`ec_quiet_library()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_library.md).

- rules:

  Rule table from
  [`ec_quiet_rules()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_rules.md).

- pseudo:

  Optional surface identifiers of the pseudo-targets.

- pseudo_quiet:

  Optional clock threshold: surfaces with \\A\\ at or below it are
  pseudo-targets (used when `pseudo` is `NULL`; default: all surfaces
  with a known clock).

- pseudo_min_dte:

  Optional minimum calendar days to expiry of a pseudo-target (applied
  on top of `pseudo` or `pseudo_quiet`). Shorter surfaces still serve as
  templates.

- cutoff:

  Optional real-target valuation date: the library is first restricted
  to surfaces that expired at or before it.

- available_only:

  Logical; restrict each pseudo-target's templates to those expired by
  its own valuation date (default `TRUE`). With `FALSE`, the whole
  (pre-cutoff) library minus the pseudo-target's maturity block is used.

- wing:

  Moneyness band of the loss, in the library's moneyness (default
  `c(0.04, 0.30)` in log-moneyness, `c(0.5, 3)` standard deviations for
  a standardized library).

- common:

  Logical; score all rules on a common set of nodes.

- target:

  Optional list with `date`, `expiry`, `atm_iv`, `k`, and optionally
  `tau` for the real target; adds its predicted shape under every rule.

## Value

An object of class `ec_quiet_select`: a list with `scores` (one row per
rule: `rule`, rule columns, `rmse`, `mae`, `rmse_target`, `n_targets`,
`n_nodes`, sorted best first), `best` (the selected row), `detail`
(pseudo-target × rule × node: `surface`, `rule`, `k`, `z`, `actual`,
`shape`, `error`), `pseudo` (the pseudo-target surfaces), and with
`target` also `target_shapes` (the
[`ec_quiet_shape()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_shape.md)
output for all rules, with a logical `selected` column).

## Details

**Loss.** For each pseudo-target the predicted shape is compared with
its realized shape at its own nodes with `wing[1] <= |k| <= wing[2]` (or
`|z|` for a standardized library). Errors are in implied-volatility
units (for `shape = "ratio"` the ratio error is scaled by the
pseudo-target's at-the-money volatility). `rmse` pools all nodes;
`rmse_target` averages the per-target RMSE.

**Common nodes.** Rules can differ in which nodes they can predict (a
rule may select no template). With `common = TRUE` (default) every rule
is scored on the same nodes — those every rule predicts.

**Ties.** Rules whose RMSE agrees to 10 significant digits are ordered
by the stricter quietness threshold, then by their position in the grid.

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "Learning
Before Scheduled Events: Prediction Markets, State Prices, and Option
Valuation".

## See also

[`ec_quiet_rules()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_rules.md),
[`ec_quiet_shape()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_quiet_shape.md).

## Examples

``` r
set.seed(1)
nodes <- expand.grid(i = 1:20, k = seq(-0.3, 0.3, by = 0.05))
nodes$surface <- paste0("s", nodes$i)
nodes$date <- as.Date("2024-06-03") + 7 * (nodes$i - 1)
nodes$expiry <- nodes$date + 4
A <- c(0.01, 0.3, 0.02, 0.2, 0.01, 0.5, 0.03, 0.02, 0.4, 0.01,
       0.25, 0.02, 0.01, 0.35, 0.03, 0.02, 0.45, 0.01, 0.02, 0.3)
nodes$A <- A[nodes$i]
nodes$iv <- 0.5 + 0.8 * nodes$k^2 - ifelse(nodes$A > 0.1, 0.3 * nodes$k, 0) +
  rnorm(nrow(nodes), sd = 0.002)
lib <- ec_quiet_library(nodes)
sel <- ec_quiet_select(lib, pseudo_quiet = 0.02)
sel
#> <ec_quiet_select> 15 rules on 10 pseudo-targets (templates available at each pseudo-target, wing 0.04-0.3 log-moneyness)
#> Selected: p50 | any DTE | atm5  (RMSE 0.0024 on 108 nodes, 9 targets)
#> # A tibble: 5 × 5
#>   rule                        rmse     mae n_targets n_nodes
#>   <chr>                      <dbl>   <dbl>     <int>   <int>
#> 1 p50 | any DTE | atm5     0.00239 0.00194         9     108
#> 2 p50 | any DTE | recent5  0.00242 0.00197         9     108
#> 3 p50 | any DTE | all      0.00244 0.00197         9     108
#> 4 p50 | any DTE | recent10 0.00244 0.00197         9     108
#> 5 p50 | any DTE | atm10    0.00244 0.00197         9     108
```
