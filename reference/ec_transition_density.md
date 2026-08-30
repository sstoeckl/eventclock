# Density of the terminal log-odds

Exact density of the resolution-date log-odds \\L_T\\ given current
probability `q` and event-clock time `A`: a two-component Gaussian
mixture with means \\L \pm A/2\\, common variance `A`, and weights \\(q,
1-q)\\.

## Usage

``` r
ec_transition_density(l, q, A)
```

## Arguments

- l:

  Numeric vector of evaluation points (log-odds scale).

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

## Value

Numeric vector of density values.

## Examples

``` r
grid <- seq(-4, 2, length.out = 200)
dens <- ec_transition_density(grid, q = 0.195, A = 0.166)
# integrates to one:
sum(dens) * diff(grid)[1]
#> [1] 1
```
