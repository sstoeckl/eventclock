# Plot the sampling-frequency signature

Plot the sampling-frequency signature

## Usage

``` r
plot_signature(sig, ...)
```

## Arguments

- sig:

  An `ec_signature` object from
  [`ec_signature()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_signature.md)
  (an `event_prices` object is converted automatically).

- ...:

  Unused.

## Value

A ggplot object.

## Examples

``` r
data(polymarket2024)
plot_signature(ec_signature(as_event_prices(polymarket2024), max_every = 24))
```
