# Cumulative event-clock path

Computes the running (cumulative) event clock \\\widehat A_t = \sum\_{s
\le t} (\Delta L_s)^2\\ — the object behind the "clock plot": how much
of the eventual information had arrived by each calendar date.

## Usage

``` r
event_clock_path(
  x,
  from = NULL,
  to = NULL,
  sample_every = ec_default_params()$sample_every,
  clip = NULL,
  normalize = TRUE
)

# S3 method for class 'event_clock_path'
plot(x, ...)
```

## Arguments

- x:

  An `event_prices` object (see
  [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)),
  or a `data.frame` coercible to one.

- from:

  Valuation date/time (default: first observation).

- to:

  One or more horizon dates/times (default: last observation = full
  sample). Names are used as horizon labels.

- sample_every:

  Integer, use every k-th observation (sparse-sampling robustness;
  default 1).

- clip:

  Numeric length-2 clipping bounds for `q` before the log-odds
  transform; defaults to the bounds stored in `x`.

- normalize:

  Logical; if `TRUE` (default) also return `A_frac`, the clock
  normalized to \\\[0, 1\]\\ over the window.

- ...:

  Unused (for the `plot` method).

## Value

A tibble of class `event_clock_path` with columns `time`, `q`, `L`
(clipped log-odds), `dL`, `dA` (squared increment), `A` (cumulative
clock), and — with `normalize = TRUE` — `A_frac` and `cal_frac`
(fraction of calendar time elapsed). Attributes carry the market id and
event date.

## Methods (by generic)

- `plot(event_clock_path)`: Plot method; dispatches to
  [`plot_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_clock.md).

## Examples

``` r
data(brexit2016)
ep <- as_event_prices(brexit2016, time = "date", price = "q_leave")
path <- event_clock_path(ep)
tail(path)
#> # A tibble: 6 × 8
#>   time           q      L       dL        dA     A A_frac cal_frac
#>   <date>     <dbl>  <dbl>    <dbl>     <dbl> <dbl>  <dbl>    <dbl>
#> 1 2016-06-18 0.36  -0.575 -0.00434 0.0000188 0.759  0.860    0.958
#> 2 2016-06-19 0.296 -0.866 -0.291   0.0847    0.844  0.956    0.966
#> 3 2016-06-20 0.274 -0.974 -0.108   0.0117    0.856  0.969    0.975
#> 4 2016-06-21 0.252 -1.09  -0.114   0.0129    0.868  0.984    0.983
#> 5 2016-06-22 0.252 -1.09   0       0         0.868  0.984    0.992
#> 6 2016-06-23 0.23  -1.21  -0.120   0.0145    0.883  1        1    
```
