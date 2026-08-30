# List the markets and outcome tokens of a Polymarket event

Fetches an event by slug from the Gamma API and unpacks its markets into
one row per outcome token. The CLOB `token_id` is what
[`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_prices.md)
needs.

## Usage

``` r
pm_markets(event_slug)
```

## Arguments

- event_slug:

  Character, the event slug (from
  [`pm_search()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_search.md)
  or the polymarket.com URL).

## Value

A tibble with columns `event_slug`, `market_id`, `market_slug`,
`question`, `outcome`, and `token_id`. Outcomes and token ids are
returned in matching order (element 1 = first listed outcome, typically
"Yes").

## Examples

``` r
if (FALSE) { # \dontrun{
mkts <- pm_markets("presidential-election-winner-2024")
subset(mkts, grepl("Trump", question) & outcome == "Yes")
} # }
```
