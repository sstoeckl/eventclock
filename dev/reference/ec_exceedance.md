# Exceedance probability of the terminal event probability

Exact probability that the resolution-date event probability exceeds a
threshold, \\P(q_T \> x)\\, under the logistic-normal transition law:
\$\$P(q_T \> x) = q\\\Phi\\\left(\frac{L + A/2 - \mathrm{logit}\\x}
{\sqrt A}\right) + (1-q)\\\Phi\\\left(\frac{L - A/2 -
\mathrm{logit}\\x}{\sqrt A}\right).\$\$

## Usage

``` r
ec_exceedance(x, q, A)
```

## Arguments

- x:

  Numeric vector of thresholds in \\(0,1)\\.

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

## Value

Numeric vector of probabilities.

## Examples

``` r
# probability that the market ends up above 50% by resolution
ec_exceedance(0.5, q = 0.195, A = 0.166)
#> [1] 0.0001951016
```
