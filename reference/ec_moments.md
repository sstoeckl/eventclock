# Moments of the terminal probability and log-odds

Closed-form moments of the resolution-date log-odds \\L_T\\ and event
probability \\q_T\\ implied by the exact logistic-normal transition law
(see
[`ec_transition_density()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_transition_density.md)),
given current probability `q` and event-clock time `A` until resolution.

## Usage

``` r
ec_moments(q, A)
```

## Arguments

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

## Value

A tibble with columns `q`, `A`, `L`, `E_qT`, `E_LT`, `var_LT`, `sd_LT`,
`m3_LT`, `var_qT` (approximation), and `var_qT_bound`.

## Details

Exact results: \\E\[q_T\] = q\\ (the martingale property — free of `A`),
\\E\[L_T\] = L + (q - 1/2)A\\, \\Var(L_T) = A + q(1-q)A^2\\, and the
third central moment \\m_3(L_T) = q(1-q)(1-2q)A^3\\. The variance of
\\q_T\\ is reported in its small-`A` approximation \\Var(q_T) \approx
(q(1-q))^2 A\\ together with the exact upper bound \\\min\\A/16,\\
q(1-q)\\\\.

## Examples

``` r
# Brexit, two weeks before the referendum: q = 0.195, A = 0.166
ec_moments(0.195, 0.166)
#> # A tibble: 1 × 10
#>       q     A     L  E_qT  E_LT var_LT sd_LT    m3_LT  var_qT var_qT_bound
#>   <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>    <dbl>   <dbl>        <dbl>
#> 1 0.195 0.166 -1.42 0.195 -1.47  0.170 0.413 0.000438 0.00409       0.0104
```
