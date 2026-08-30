# Search Polymarket events

Free-text search over Polymarket events via the public Gamma API. Use
the returned `event_slug` with
[`pm_markets()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_markets.md)
to obtain the tradable outcome tokens.

## Usage

``` r
pm_search(query, limit = 20)
```

## Arguments

- query:

  Character search string (e.g. `"fed decision"`).

- limit:

  Integer, maximum number of events (default 20).

## Value

A tibble with columns `event_id`, `event_slug`, `title`, `start_date`,
`end_date`, `closed`, and `volume` (columns missing in the API response
are dropped).

## See also

[`pm_markets()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_markets.md),
[`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_prices.md)

## Examples

``` r
if (FALSE) { # \dontrun{
pm_search("presidential election winner 2024")
} # }
```
