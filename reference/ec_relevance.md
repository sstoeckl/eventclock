# Pricing relevance of event learning: the sufficient statistic

The single number that decides whether learning about an event is
first-order for an asset's option prices: the ratio of learning variance
to no-learning variance over the tenor, \$\$\rho = \frac{\[\Delta\eta\\
q(1-q)\]^2\\ A}{\sigma^2 (T-t)}.\$\$

## Usage

``` r
ec_relevance(deta, q, A, sigma, tenor)
```

## Arguments

- deta:

  Numeric, the event exposure \\\Delta\eta = \eta_1 - \eta_2\\.

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

- sigma:

  Numeric, annualized no-learning volatility (decimal, e.g. `0.19` for
  19%).

- tenor:

  Numeric, option tenor \\T - t\\ in years.

## Value

Numeric vector \\\rho \ge 0\\.

## Details

The other headline objects are monotone transforms of \\\rho\\: the
variance share of learning is \\\rho / (1 + \rho)\\
([`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_variance_share.md))
and the rule-of-thumb IV contribution is \\\sigma \rho / 2\\
([`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md)).
Use \\\rho\\ to screen (event, asset) pairs: FX pairs around elections
sit at \\\rho \approx 0.002\\–\\0.01\\ (irrelevant to two decimals),
single names with large exposures can reach first-order magnitudes.

## See also

[`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_variance_share.md),
[`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md),
[`event_beta()`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)

## Examples

``` r
# US election 2016, 2W tenor: rho of about 1.1% -> variance share 1.1%
ec_relevance(deta = -0.099, q = 0.172, A = 0.046,
             sigma = 0.19326, tenor = 14 / 365)
#> [1] 0.006383027
```
