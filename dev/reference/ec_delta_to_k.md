# Convert a call-equivalent delta grid to log-moneyness

Standardized option surfaces are usually quoted on a delta grid. Under
the Black model with unit forward and total dispersion `s`, the strike
with (call) delta \\\Delta\\ has log-forward moneyness \$\$k = s^2/2 -
s\\\Phi^{-1}(\Delta).\$\$ Put deltas convert as call-equivalent \\\Delta
= 1 + \delta\_{put}\\.

## Usage

``` r
ec_delta_to_k(delta, s)
```

## Arguments

- delta:

  Call-equivalent delta in (0, 1).

- s:

  Total dispersion at the node (annualized volatility times
  \\\sqrt{\tau}\\).

## Value

Log-forward moneyness \\k = \log(K/F)\\.

## Examples

``` r
ec_delta_to_k(c(0.25, 0.5, 0.75), s = 0.3)
#> [1]  0.2473469  0.0450000 -0.1573469
```
