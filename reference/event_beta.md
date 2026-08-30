# Event beta: realized loading of asset returns on event-probability news

Regresses asset returns on the innovations of a traded event
probability, \$\$r_t = \alpha + b\\ \Delta q_t + \gamma' c_t + u_t,\$\$
with Newey-West (Bartlett/HAC) standard errors. To first order the model
implies \\r_t \approx \Delta\eta\\\Delta q_t\\, so the slope `b` *is*
the returns-based estimate of the event exposure
\\\widehat{\Delta\eta}\\.

## Usage

``` r
event_beta(asset, x, deta = NULL, controls = NULL, lags = NULL)

# S3 method for class 'event_beta'
print(x, ...)
```

## Arguments

- asset:

  A `data.frame` with a time column and either a return column (`ret`)
  or a price column (`adjusted`, `close`, or `price`; log returns are
  computed).

- x:

  An `event_prices` object (or coercible); its probability innovations
  \\\Delta q_t\\ are the regressor. Observations are matched on the
  calendar date.

- deta:

  Optional externally measured event exposure \\\Delta\eta\\; enables
  the \\\beta = 1\\ test.

- controls:

  Optional `data.frame` with a time column and control variables (e.g.
  market returns), matched on date.

- lags:

  Newey-West lag order; default \\\lfloor 4 (n/100)^{2/9} \rfloor\\. Use
  `lags = 0` for heteroskedasticity-robust (HC0) errors.

- ...:

  Unused (for the `print` method).

## Value

An object of class `event_beta`: a list with

- coefficients:

  tibble of terms, estimates, HAC standard errors, t-statistics, and
  p-values.

- deta_hat, deta_se:

  the slope on \\\Delta q\\ and its SE.

- eta1, eta2:

  model-implied levels (see Details).

- beta, beta_se, beta_z, beta_p:

  (only with `deta`) the loading \\b/\Delta\eta\\ and the Wald test of
  \\\beta = 1\\.

- r2, n, lags:

  regression diagnostics; `r2` is the realized variance share of event
  news over the sample.

## Details

**What is (and is not) identified.** Returns identify only the *spread*
\\\Delta\eta = \eta_1 - \eta_2\\, not the outcome-conditional levels
\\\eta_1, \eta_2\\ separately (those require event-spanning option
smiles). Consequently the loading test \\\beta = 1\\ is only meaningful
against an *externally* measured exposure: supply `deta` (e.g.
option-implied, or from an independent sample) and the function reports
\\\beta = b / \Delta\eta\\ with a Wald test of \\\beta = 1\\. Without
`deta`, the regression is exactly identified and only
\\\widehat{\Delta\eta}\\ is reported.

Under the risk-neutral adding-up constraint \\q\\\eta_1 + (1-q)\\\eta_2
= 1\\, point estimates of the levels can be backed out as \\\eta_1 = 1 +
(1-q)\Delta\eta\\ and \\\eta_2 = 1 - q\Delta\eta\\; these are
model-implied, not independently identified, and are returned for
convenience (evaluated at the sample-average `q`).

## Methods (by generic)

- `print(event_beta)`: Print method.

## See also

[`ec_relevance()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_relevance.md)
for the pricing-relevance screen.

## Examples

``` r
data(djt2024)
data(polymarket2024)
ep <- pm_daily(as_event_prices(polymarket2024))
event_beta(djt2024, ep)
#> -- Event-beta regression (Newey-West, 4 lags)
#> Event exposure deta_hat = 1.2765 (se 0.4838, t = 2.64), n = 108, R^2 = 0.064
#> Model-implied levels at mean q = 0.554: eta1 = 1.5699, eta2 = 0.2934
#> (No external deta supplied: levels/loading test not identified from returns alone.)
```
