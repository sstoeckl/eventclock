# Event-clock time versus calendar time

Plots the share of clock time elapsed against the share of calendar time
elapsed. The 45-degree line is the "information arrives uniformly"
benchmark; a curve below it means information is back-loaded (it waits
for the deadline), above it front-loaded.

## Usage

``` r
plot_clock_vs_calendar(path, ...)
```

## Arguments

- path:

  An `event_clock_path` object from
  [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  (an `event_prices` object is converted automatically).

- ...:

  Unused.

## Value

A ggplot object.

## Examples

``` r
data(us2016)
ep <- as_event_prices(us2016, time = "date", price = "trump",
                      event_date = as.Date("2016-11-08"))
plot_clock_vs_calendar(event_clock_path(ep))
```
