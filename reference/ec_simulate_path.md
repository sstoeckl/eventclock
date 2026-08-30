# Simulate event-clock consistent probability paths

Simulates paths of the event probability by composing the exact
transition law over `n_steps` clock increments: the outcome `J` is drawn
once per path, and conditional on `J` the log-odds follow a Gaussian
random walk with drift \\\pm a_i/2\\ and variance \\a_i\\ per step,
where \\\sum_i a_i = A\\. Unconditionally, each step is Bayes-consistent
and \\q_t\\ is a martingale.

## Usage

``` r
ec_simulate_path(n_paths, n_steps, q, A, jump_share = 0, n_jumps = 1)
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

- jump_share:

  Numeric in \\\[0, 1)\\: share of `A` arriving in jump steps (default 0
  = smooth information flow).

- n_jumps:

  Integer, number of jump steps per path (default 1; only used when
  `jump_share > 0`).

## Value

A tibble with columns `path`, `step` (0..`n_steps`), `t_frac` (fraction
of calendar steps elapsed), `J`, `L`, `q`, and `is_jump` (`TRUE` for the
jump steps; `FALSE` for step 0).

## Details

With `jump_share > 0`, information arrives *lumpily*: a fraction
`jump_share` of total clock time `A` is concentrated in `n_jumps`
randomly placed steps (scheduled sub-events: debates, data releases),
and the rest flows evenly. Every step still follows the exact
Bayes-consistent transition, so all closed-form results continue to
hold; lumpiness only changes *when* the clock ticks. This is the testbed
for the jump-robust estimator variants of
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md).

## Examples

``` r
set.seed(1)
paths <- ec_simulate_path(n_paths = 3, n_steps = 50, q = 0.3, A = 1)
# realized clock of one path is close to A:
sum(diff(subset(paths, path == 1)$L)^2)
#> [1] 0.7973274

# lumpy information: half of A arrives in two jump steps
lumpy <- ec_simulate_path(2, 50, q = 0.3, A = 1,
                          jump_share = 0.5, n_jumps = 2)
```
