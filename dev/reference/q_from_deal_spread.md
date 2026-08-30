# Completion probability from a merger-arbitrage spread

The target's traded price is itself an event state price: with offer
value `offer` on completion and `fallback` value on deal break, \$\$q =
\frac{P - F}{O\\D - F},\$\$ where `D` discounts the offer to today
(deal-horizon discount factor, default 1).

## Usage

``` r
q_from_deal_spread(target, offer, fallback, discount = 1)
```

## Arguments

- target:

  Target's traded price(s).

- offer:

  Offer value per share on completion.

- fallback:

  Estimated standalone ("deal-break") value per share.

- discount:

  Discount factor applied to the offer (default 1).

## Value

Numeric vector of completion probabilities. Values outside \\\[0,1\]\\
trigger a warning (check `fallback`), but are returned unchanged (flag,
don't drop).

## See also

[`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/q_from_price.md),
[`q_from_ffutures()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/q_from_ffutures.md)

## Examples

``` r
# target at 47, cash offer 50, fallback 35: q = 0.8
q_from_deal_spread(47, offer = 50, fallback = 35)
#> [1] 0.8
```
