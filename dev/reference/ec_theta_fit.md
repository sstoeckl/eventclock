# Estimate the event exposure theta from event-spanning option surfaces

Fits the lognormal event mixture of
[`ec_mix_price()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_mix_price.md)
to a panel of event-spanning option surfaces: each surface (one
valuation date and one expiry) gets its own outcome-conditional
dispersions \\(s_1, s_2)\\, while the event exposure \\\theta =
\log(m_1/m_2)\\ is restricted to be common across all surfaces — the
working paper's common conditional-mean-ratio design. The objective is
the working paper's: price residuals divided by the Black vega at the
observed node (the implied-volatility error to first order), averaged
with node weights within each surface and surface-balanced across
surfaces, so each surface carries equal weight regardless of how many
quotes it has.

## Usage

``` r
ec_theta_fit(surfaces, theta_range = c(-3, 3), common = TRUE, min_nodes = 4)

# S3 method for class 'ec_theta_fit'
print(x, ...)
```

## Arguments

- surfaces:

  A `data.frame` with one row per observed node and columns:

  `surface`

  :   surface identifier (valuation date \\\times\\ expiry); anything
      coercible to a factor.

  `k`

  :   log-forward moneyness \\\log(K/F)\\ (see
      [`ec_delta_to_k()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_delta_to_k.md)
      for delta grids).

  `iv`

  :   observed implied volatility. Annualized if `tau` is supplied,
      otherwise interpreted as *total* dispersion.

  `q`

  :   state-price-implied probability of outcome 1 at the surface's
      valuation date (constant within surface).

  `tau`

  :   optional: time to expiry in years; converts between annualized and
      total units.

  `w`

  :   optional: node weight (e.g. quote count or inverse spread);
      defaults to 1.

- theta_range:

  Search interval for the common exposure.

- common:

  If `FALSE`, every surface gets its own \\\theta\\ instead (the working
  paper's free-ratio diagnostic); the common estimate is then `NA` and
  the per-surface exposures are reported in the `surfaces` table.

- min_nodes:

  Surfaces with fewer observed nodes are dropped with a warning (two
  free dispersions need cross-sectional information).

- x, ...:

  Print method arguments.

## Value

An object of class `ec_theta_fit`: a list with

- theta, ratio:

  the common event exposure and \\m_1/m_2 = e^{\theta}\\.

- rmse:

  surface-balanced root mean squared vega-scaled pricing error —
  implied-volatility units to first order, in the units of the `iv`
  input (annualized if `tau` was supplied).

- surfaces:

  per-surface tibble: `q`, nodes, fitted `s1`, `s2` (total dispersions),
  per-surface `rmse`, and `theta` when `common = FALSE`.

- n_surfaces, n_obs, common:

  bookkeeping.

## Details

**Sign at `q` near one half.** See
[`ec_mix_price()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_mix_price.md):
with symmetric `q` the sign of \\\theta\\ is not identified from option
prices alone and the optimizer returns one of the two equivalent
solutions. Fix the sign externally (e.g.
[`event_beta()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_beta.md)).

## Methods (by generic)

- `print(ec_theta_fit)`: Print method.

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "Learning
Before Scheduled Events: Prediction Markets, State Prices, and Option
Valuation".

## See also

[`ec_theta_hump()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_theta_hump.md)
for the first-order shortcut,
[`event_beta()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_beta.md)
for the returns-based exposure.

## Examples

``` r
# recover a known exposure from two noiseless simulated surfaces
k <- seq(-0.5, 0.5, by = 0.25)
surf <- rbind(
  data.frame(surface = "d1", k = k, q = 0.60,
             iv = ec_mix_iv(k, 0.60, 0.8, 0.30, 0.35)),
  data.frame(surface = "d2", k = k, q = 0.65,
             iv = ec_mix_iv(k, 0.65, 0.8, 0.28, 0.32))
)
ec_theta_fit(surf)
#> -- Event-spanning mixture fit (2 surfaces, 10 nodes)
#> Common event exposure theta = 0.8000 (conditional-mean ratio m1/m2 = 2.226)
#> Surface-balanced RMSE = 0.0000 (IV units of the input)
```
