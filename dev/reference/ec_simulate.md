# Simulate the exact transition to resolution

Draws the outcome indicator \\J \sim \mathrm{Bernoulli}(q)\\ and the
terminal log-odds from the exact transition law \\L_T = L + (1\\J=1\\ -
1/2)A + \sqrt{A}\\\zeta\\. The martingale property \\E\[q_T\] = q\\
holds by construction (Bayes consistency of the \\\pm A/2\\ drift).

## Usage

``` r
ec_simulate(n, q, A)
```

## Arguments

- n:

  Integer, number of draws.

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

## Value

A tibble with columns `J` (0/1 outcome), `zeta`, `L_T`, and `q_T`.

## Examples

``` r
set.seed(1)
sim <- ec_simulate(1e4, q = 0.195, A = 0.166)
mean(sim$q_T) # close to 0.195
#> [1] 0.1940241
mean(sim$J)   # close to 0.195
#> [1] 0.2024
```
