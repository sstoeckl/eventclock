# First-order event exposure from the spanning variance hump

For the two-point event mixture, the event contributes exactly
\\q(1-q)\\\theta\_{\log}^2\\ to the *total* variance of the terminal log
multiplier, where \\\theta\_{\log}\\ is the difference of the
conditional log means (equal to \\\theta\\ when the conditional
dispersions coincide). Reading an event-spanning option's total ATM
variance in excess of its no-event baseline as that contribution gives
the moment-based estimator \$\$\|\hat\theta\| = \sqrt{\Delta V /
(q(1-q))}.\$\$

## Usage

``` r
ec_theta_hump(dvar, q)
```

## Arguments

- dvar:

  Event-induced increment in total variance of the spanning expiry
  (total variance of the spanning maturity minus the no-event baseline,
  both as \\\sigma^2 \tau\\).

- q:

  State-price-implied probability of outcome 1.

## Value

\\\|\hat\theta\|\\; `NA` (with a warning) where `dvar` is negative.

## Details

This is the quick first-pass estimator: it needs only the total-variance
hump of the spanning maturity (computed in variance units, not in
annualized volatilities) and the event probability. It identifies the
*magnitude* only; take the sign from
[`event_beta()`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)
or from the smile asymmetry via the full fit in
[`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_fit.md).

## See also

[`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_fit.md)
for the full surface fit.

## Examples

``` r
# a 10-point IV hump at 40% baseline vol, one month to expiry, q = 0.5
tau <- 1 / 12
dvar <- (0.50^2 - 0.40^2) * tau
ec_theta_hump(dvar, q = 0.5)
#> [1] 0.1732051
```
