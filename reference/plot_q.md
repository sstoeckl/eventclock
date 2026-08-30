# Plot the event-probability path

Line plot of the traded event probability \\q_t\\, with an optional
marker at the scheduled event date.

## Usage

``` r
plot_q(x, event_date = NULL, ...)
```

## Arguments

- x:

  An `event_prices` object (or coercible).

- event_date:

  Optional event date; defaults to the one stored on `x`.

- ...:

  Unused.

## Value

A ggplot object.

## Examples

``` r
data(brexit2016)
ep <- as_event_prices(brexit2016, time = "date", price = "q_leave",
                      event_date = as.Date("2016-06-23"))
plot_q(ep)
```
