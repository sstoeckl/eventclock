# ATM claim on the event factor

Bachelier-style approximation of the value of an at-the-money claim on
the event factor: \\\approx \|\Delta\eta\|\\ q(1-q)\sqrt{A/(2\pi)}\\,
where \\\Delta\eta\\ is the gap between the outcome-conditional mean
multipliers of the underlying (the *event exposure*).

## Usage

``` r
ec_atm_event_call(q, A, deta)
```

## Arguments

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

- deta:

  Numeric, the event exposure \\\Delta\eta = \eta_1 - \eta_2\\.

## Value

Numeric vector (same units as the underlying's return).

## Examples

``` r
ec_atm_event_call(q = 0.195, A = 0.166, deta = -0.012)
#> [1] 0.0003061793
```
