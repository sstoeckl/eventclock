# Convert traded state prices into risk-adjusted event probabilities

Traded event claims (prediction-market contracts, betting quotes, binary
options) pay one unit at resolution. Their price is therefore a
*discounted* probability: \\\psi_t = D(t,\tau)\\ q_t\\, where
\\D(t,\tau)\\ is the discount factor of the payout numeraire. This
function undoes that discounting, or alternatively removes the bookmaker
overround by normalizing with the sum of all outcome prices in the book.

## Usage

``` r
q_from_price(
  price,
  discount = 1,
  book = NULL,
  method = c("discount", "overround")
)
```

## Arguments

- price:

  Numeric vector of raw claim prices \\\psi_t\\ (on the 0-1 scale;
  rescale percent quotes first).

- discount:

  Numeric scalar or vector, the discount factor \\D(t,\tau) \in (0,
  1\]\\ applicable to the payout (default 1, i.e. no discounting).

- book:

  Numeric scalar or vector, the sum of prices over all outcomes of the
  same market. Required for `method = "overround"`.

- method:

  Character, `"discount"` or `"overround"`.

## Value

A numeric vector of probabilities `q`. Values outside \\\[0,1\]\\
trigger a warning (they indicate a wrong `discount`/`book`), but are
returned unchanged so that the caller can flag rather than drop them.

## Details

Two normalizations are available:

- `method = "discount"` (default): \\q = \psi / D\\. Under deterministic
  interest rates the result is the risk-adjusted (risk-neutral) event
  probability; with stochastic rates it is a forward-measure
  probability. At short horizons the correction is a few basis points
  but it is systematic.

- `method = "overround"`: \\q_j = \psi_j / \sum_i \psi_i\\, where `book`
  supplies \\\sum_i \psi_i\\. Use this only when the raw quotes include
  a bookmaker margin that has *not* already been removed by the data
  provider. Note that series which are already margin-adjusted must not
  be normalized twice.

A level distortion that is (approximately) constant on the log-odds
scale — a constant discount factor, a constant state-price tilt — shifts
\\L_t = \mathrm{logit}(q_t)\\ by a constant and therefore leaves the
event clock unchanged: quadratic variation is invariant to level shifts.
Getting the level of `q` exactly right matters for probability
statements, not for
[`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md).

## See also

[`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md),
which applies this conversion while constructing an `event_prices`
object.

## Examples

``` r
# a 90-day claim priced at 0.19 with a 2% (annualized) short rate
q_from_price(0.19, discount = exp(-0.02 * 90 / 365))
#> [1] 0.1909393

# two-sided book with overround: prices sum to 1.04
q_from_price(0.52, book = 0.52 + 0.52, method = "overround")
#> [1] 0.5
```
