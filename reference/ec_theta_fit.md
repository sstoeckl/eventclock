# Estimate the log exposure theta from event-spanning option surfaces

Fits the lognormal event mixture of
[`ec_mix_price()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price.md)
to a panel of event-spanning option surfaces: each surface (one
valuation date and one expiry) gets its own outcome-conditional
dispersions \\(s_1, s_2)\\, while the log exposure \\\theta =
\log(m_1/m_2)\\ is restricted to be common across all surfaces — the
working paper's common conditional-mean-ratio design. The objective is
the working paper's: price residuals divided by the Black vega at the
observed node (the implied-volatility error to first order), averaged
with node weights within each surface and surface-balanced across
surfaces, so each surface carries equal weight regardless of how many
quotes it has.

## Usage

``` r
ec_theta_fit(
  surfaces,
  theta_range = c(-3, 3),
  common = TRUE,
  min_nodes = 4,
  boot_reps = 0,
  block = NULL,
  block_length = 1,
  conf = 0.95
)

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
      [`ec_delta_to_k()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_delta_to_k.md)
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

  `iv_bid`, `iv_ask`

  :   optional: implied volatilities of the bid and ask quotes (same
      units as `iv`); enables the bid-ask diagnostic.

- theta_range:

  Search interval for the common exposure.

- common:

  If `FALSE`, every surface gets its own \\\theta\\ instead (the working
  paper's free-ratio diagnostic); the common estimate is then `NA` and
  the per-surface exposures are reported in the `surfaces` table.

- min_nodes:

  Surfaces with fewer observed nodes are dropped with a warning (two
  free dispersions need cross-sectional information).

- boot_reps:

  Number of block-bootstrap replications for a confidence interval of
  the common exposure (default 0 = none).

- block:

  Name of the column defining the bootstrap blocks — typically the
  valuation date, so that all maturities observed on one date are
  resampled together (the working paper's date-block bootstrap).
  Required when `boot_reps > 0`.

- block_length:

  Number of consecutive blocks drawn together (moving-block bootstrap;
  default 1).

- conf:

  Confidence level of the bootstrap interval (default 0.95).

- x, ...:

  Print method arguments.

## Value

An object of class `ec_theta_fit`: a list with

- theta, ratio:

  the common log exposure and \\m_1/m_2 = e^{\theta}\\.

- rmse:

  surface-balanced root mean squared vega-scaled pricing error —
  implied-volatility units to first order, in the units of the `iv`
  input (annualized if `tau` was supplied).

- surfaces:

  per-surface tibble: `q`, nodes, fitted `s1`, `s2` (total dispersions),
  per-surface `rmse`, and `theta` when `common = FALSE`.

- nodes:

  per-node tibble: `surface`, `k`, `iv`, the fitted `iv_fit` and
  residual `iv_err`; with bid and ask also `iv_bid`, `iv_ask`, and
  `inside` (fitted value within the quotes).

- inside_share:

  share of nodes whose fitted implied volatility lies inside the bid-ask
  interval (`NA` without quotes). Because prices are monotone in implied
  volatility, this equals the share of model prices inside the quoted
  price interval.

- theta_ci, ratio_ci, theta_boot:

  with `boot_reps > 0`: the percentile interval for \\\theta\\ and
  \\e^\theta\\, and the bootstrap draws.

- n_surfaces, n_obs, common:

  bookkeeping.

## Details

**Sign at `q` near one half.** See
[`ec_mix_price()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price.md):
with symmetric `q` the sign of \\\theta\\ is not identified from option
prices alone and the optimizer returns one of the two equivalent
solutions. Fix the sign externally (e.g.
[`event_beta()`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)).

**Bootstrap.** Each replication draws blocks with replacement, refits
the common exposure on the surfaces of the drawn blocks (warm-started
from the full-sample fit), and records \\\theta\\. Runtime is roughly
`boot_reps` times a full fit; a few hundred replications are typical.

## Methods (by generic)

- `print(ec_theta_fit)`: Print method.

## References

Hanke, Schadner, Stöckl, and Weissensteiner (Working Paper), "Learning
Before Scheduled Events: Prediction Markets, State Prices, and Option
Valuation".

## See also

[`ec_theta_hump()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_hump.md)
for the first-order shortcut,
[`event_beta()`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)
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
#> Common log exposure theta = 0.8000 (conditional-mean ratio eta1/eta2 = 2.226)
#> Surface-balanced RMSE = 0.0000 (IV units of the input)
```
