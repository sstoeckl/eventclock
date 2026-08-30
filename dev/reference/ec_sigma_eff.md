# Effective volatility ahead of a scheduled event

First-order decomposition of pre-event implied volatility into the
no-learning component and the learning component:
\\\sigma\_{\mathrm{eff}} = \sqrt{\sigma^2 + (\Delta\eta\\ q(1-q))^2 A /
T}\\.

## Usage

``` r
ec_sigma_eff(sigma, deta, q, A, tenor)
```

## Arguments

- sigma:

  Numeric, annualized no-learning volatility (decimal, e.g. `0.19` for
  19%).

- deta:

  Numeric, the event exposure \\\Delta\eta = \eta_1 - \eta_2\\.

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

- tenor:

  Numeric, option tenor \\T - t\\ in years.

## Value

Numeric vector, annualized effective volatility (decimal).

## Examples

``` r
ec_sigma_eff(sigma = 0.19326, deta = -0.099, q = 0.172, A = 0.046,
             tenor = 14 / 365)
#> [1] 0.1938758
```
