# Pre-resolution option prices under event learning

Prices a European option that expires *before* the event is resolved.
The option never sees the outcome, but it is exposed to *learning*:
while it is alive, the state-price-implied event probability moves by
the elapsed event-clock time `A`, and with it the event component of the
asset value. `ec_mix_price_pre()` evaluates this exactly under the
package's maintained transition: the future probability follows the
two-component logistic-normal law of
[`ec_transition_density()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_transition_density.md),
the event component is \\E = q' m_1 + (1-q') m_2\\ with the means of
[`ec_mix_price()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price.md),
and ordinary (non-event) risk is lognormal with total dispersion `s_cf`,
independent of event learning.

## Usage

``` r
ec_mix_price_pre(k, q, theta, A, s_cf, type = c("call", "put"))

ec_mix_iv_pre(k, q, theta, A, s_cf)
```

## Arguments

- k:

  Log-forward moneyness \\\log(K/F)\\ (vector).

- q:

  Current state-price-implied probability of outcome 1.

- theta:

  Event exposure \\\log(m_1/m_2)\\, e.g. from
  [`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_fit.md)
  on event-spanning surfaces.

- A:

  Event-clock time expected to elapse over the option's remaining life,
  e.g. from
  [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_forecast.md).

- s_cf:

  Total dispersion of the counterfactual (ordinary, no-event) asset risk
  over the option's life.

- type:

  `"call"` or `"put"`.

## Value

`ec_mix_price_pre()`: forward-normalized undiscounted prices;
`ec_mix_iv_pre()`: the corresponding Black total implied dispersions.

## Details

`A = 0` is the **no-learning benchmark**: the price collapses to the
plain Black price with dispersion `s_cf` — the fixed-probability
scheduled-jump special case. For convex payoffs the price is
nondecreasing in elapsed clock time (the convex-order effect of
learning), which is what makes held-out pre-resolution options a *test*
of the learning channel rather than a calibration input.

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "Learning
Before Scheduled Events: Prediction Markets, State Prices, and Option
Valuation".

## See also

[`ec_sigma_eff()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_sigma_eff.md)
and
[`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md)
for the first-order (formula-book) versions of the same channel.

## Examples

``` r
# learning raises the pre-event ATM value relative to no learning
ec_mix_price_pre(0, q = 0.4, theta = 0.8, A = c(0, 0.25, 1), s_cf = 0.2)
#> [1] 0.07965567 0.08836316 0.10776207
# ... and the effect vanishes without exposure
ec_mix_price_pre(0, q = 0.4, theta = 0, A = c(0, 1), s_cf = 0.2)
#> [1] 0.07965567 0.07965567
```
