# Clock plot: the cumulative event clock

Plots cumulative event-clock time \\\widehat A_t\\ against calendar time
— the "clock plot": how much of the window's information had arrived by
each date.

## Usage

``` r
plot_clock(path, normalize = TRUE, ...)
```

## Arguments

- path:

  An `event_clock_path` object from
  [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  (an `event_prices` object is converted automatically).

- normalize:

  Logical; plot the clock normalized to \\\[0,1\]\\ (default `TRUE`) or
  in raw units of `A`.

- ...:

  Unused.

## Value

A ggplot object.

## Examples

``` r
data(brexit2016)
ep <- as_event_prices(brexit2016, time = "date", price = "q_leave",
                      event_date = as.Date("2016-06-23"))
plot_clock(event_clock_path(ep))
```
