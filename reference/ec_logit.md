# Log-odds (logit) transform

Thin wrappers around
[`stats::qlogis()`](https://rdrr.io/r/stats/Logistic.html) and
[`stats::plogis()`](https://rdrr.io/r/stats/Logistic.html). Exported
because every quantity in the event-clock framework is defined on the
log-odds scale \\L_t = \mathrm{logit}(q_t)\\.

## Usage

``` r
ec_logit(q)

ec_ilogit(l)
```

## Arguments

- q:

  Numeric vector of probabilities in \\(0, 1)\\.

- l:

  Numeric vector of log-odds.

## Value

`ec_logit()` returns log-odds; `ec_ilogit()` returns probabilities.

## Examples

``` r
ec_logit(0.195)
#> [1] -1.417843
ec_ilogit(-1.418)
#> [1] 0.1949753
```
