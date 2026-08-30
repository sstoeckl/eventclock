# Event-clock time needed to reach near-certainty

Rule of thumb for the amount of event-clock time required for the market
to move from its current probability `q` to a target probability
`target` (conditional on the corresponding outcome): \\A^\* \approx
2(\mathrm{logit}\\ x^\* - L)\\.

## Usage

``` r
ec_target_clock(q, target)
```

## Arguments

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- target:

  Numeric vector of target probabilities in \\(0,1)\\.

## Value

Numeric vector \\A^\*\\.

## Examples

``` r
# from 19.5% to "90% sure": A* is about 7.2 -- roughly 40 times the
# clock time measured over the final two pre-referendum weeks (0.166)
ec_target_clock(q = 0.195, target = 0.9)
#> [1] 7.230135
```
