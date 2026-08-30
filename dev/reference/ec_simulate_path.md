# Simulate event-clock consistent probability paths

Simulates paths of the event probability by composing the exact
transition law over `n_steps` equal clock increments \\a = A /
n\_{steps}\\: the outcome `J` is drawn once per path, and conditional on
`J` the log-odds follow a Gaussian random walk with drift \\\pm a/2\\
and variance `a` per step. Unconditionally, each step is
Bayes-consistent and \\q_t\\ is a martingale.

## Usage

``` r
ec_simulate_path(n_paths, n_steps, q, A)
```

## Arguments

- n_paths:

  Integer, number of paths.

- n_steps:

  Integer, number of clock increments per path.

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

## Value

A tibble with columns `path`, `step` (0..`n_steps`), `t_frac` (fraction
of clock time elapsed), `J`, `L`, and `q`.

## Examples

``` r
set.seed(1)
paths <- ec_simulate_path(n_paths = 3, n_steps = 50, q = 0.3, A = 1)
# realized clock of one path is close to A:
sum(diff(subset(paths, path == 1)$L)^2)
#> [1] 0.7973274
```
