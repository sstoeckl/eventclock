# Option prices and implied volatility under the event mixture

Prices European options on an event-exposed asset whose terminal value,
normalized by its forward, is the two-component lognormal event mixture
of the accompanying working paper: with probability \\q\\ (outcome 1)
the gross event multiplier is lognormal with conditional mean \\m_1\\
and total dispersion \\s_1\\, with probability \\1-q\\ (outcome 2)
lognormal with mean \\m_2\\ and dispersion \\s_2\\. The
outcome-conditional means are parametrized by the event exposure
\$\$\theta = \log(m_1 / m_2)\$\$ and pinned down by the pricing-measure
adding-up (scale) normalization \\q\\m_1 + (1-q)\\m_2 = 1\\, so that the
mixture has forward value one.

## Usage

``` r
ec_mix_price(k, q, theta, s1, s2, type = c("call", "put"))

ec_mix_iv(k, q, theta, s1, s2)
```

## Arguments

- k:

  Log-forward moneyness \\\log(K/F)\\ (vector).

- q:

  State-price-implied probability of outcome 1.

- theta:

  Event exposure \\\log(m_1/m_2)\\; `theta = 0` collapses to a single
  lognormal.

- s1, s2:

  Outcome-conditional *total* dispersions (standard deviation of the
  conditional log multiplier over the remaining life; annualized
  volatility times \\\sqrt{\tau}\\).

- type:

  `"call"` or `"put"`.

## Value

`ec_mix_price()`: numeric vector of forward-normalized prices.
`ec_mix_iv()`: numeric vector of total implied dispersions (`NA` where
the price is at an arbitrage bound).

## Details

`ec_mix_price()` returns undiscounted forward-normalized option prices
(multiply by the discount factor and the forward to obtain currency
prices). `ec_mix_iv()` returns the Black *total* implied dispersion of
the mixture price; divide by \\\sqrt{\tau}\\ (time to expiry in years)
for an annualized implied volatility.

**Sign identification.** At \\q = 1/2\\ the mixture is observationally
symmetric in \\(\theta, s_1, s_2) \mapsto (-\theta, s_2, s_1)\\: option
prices alone cannot tell which outcome the asset favors. Take the sign
from an external source — e.g. the returns-based exposure of
[`event_beta()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_beta.md)
— when `q` is close to one half.

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "Learning
Before Scheduled Events: Prediction Markets, State Prices, and Option
Valuation".

## See also

[`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_theta_fit.md)
to estimate `theta` from observed surfaces,
[`ec_theta_hump()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_theta_hump.md)
for the first-order variance-hump estimator.

## Examples

``` r
# DJT-style exposure: theta = log(2.7), q = 0.55
k <- seq(-0.8, 0.8, by = 0.2)
ec_mix_iv(k, q = 0.55, theta = log(2.7), s1 = 0.6, s2 = 0.8)
#> [1] 0.8882645 0.8712423 0.8519806 0.8314890 0.8108516 0.7910076 0.7726148
#> [8] 0.7560262 0.7413451
```
