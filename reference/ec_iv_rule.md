# Rule of thumb: implied-volatility contribution of event learning

The paper's four-lever rule of thumb for the ATM implied-volatility
contribution of learning ahead of a scheduled event: \$\$\Delta
\mathrm{IV} \approx \frac{\[\Delta\eta\\ q(1-q)\]^2\\
A}{2\\\sigma\\(T-t)}.\$\$

## Usage

``` r
ec_iv_rule(deta, q, A, sigma, tenor)
```

## Arguments

- deta:

  Numeric, the event exposure \\\Delta\eta = \eta_1 - \eta_2\\.

- q:

  Numeric vector of current event probabilities in \\(0,1)\\.

- A:

  Numeric vector of event-clock time (non-negative).

- sigma:

  Numeric, annualized no-learning volatility (decimal, e.g. `0.19` for
  19%).

- tenor:

  Numeric, option tenor \\T - t\\ in years.

## Value

Numeric vector, the IV contribution in decimal volatility units.

## Details

The four levers: the event exposure \\\Delta\eta\\ (squared), the
movability of the probability \\q(1-q)\\ (squared), the event-clock time
\\A\\, and the dilution by the no-learning volatility and tenor.

**Units and the \\\sigma\\ convention.** With `sigma` as decimal
annualized volatility and `tenor` in years, the result is a decimal
volatility increment; multiply by 100 for annualized percentage points.
Use the *tenor-specific no-learning ATM volatility* for `sigma`; using a
different maturity's volatility changes the result mechanically (e.g.
the Brexit 2W contribution is 0.007 IV points with the 2W ATM of 10.59%
but 0.008 with 9.325%).

## Examples

``` r
# US election 2016, 2W: about 0.062 annualized IV percentage points
100 * ec_iv_rule(deta = -0.099, q = 0.172, A = 0.046,
                 sigma = 0.19326, tenor = 14 / 365)
#> [1] 0.06167919
```
