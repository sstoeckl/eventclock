# Variance share of event learning

Fraction of total return variance over the tenor attributable to
learning about the event: \\(1 + \sigma^2 T / v)^{-1}\\ with \\v =
(\Delta\eta\\ q(1-q))^2 A\\.

## Usage

``` r
ec_variance_share(sigma, deta, q, A, tenor)
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

Numeric vector in \\\[0, 1\]\\.

## Examples

``` r
# Brexit 2W: about 0.2%; US election 2W: about 1.1%
ec_variance_share(sigma = 0.10590, deta = -0.012, q = 0.195,
                  A = 0.166, tenor = 14 / 365)
#> [1] 0.001367446
ec_variance_share(sigma = 0.19326, deta = -0.099, q = 0.172,
                  A = 0.046, tenor = 14 / 365)
#> [1] 0.006342542
```
