# Meeting-implied probability from a fed funds futures price

Converts the price of the 30-day fed funds futures contract for a
meeting month into the probability of a rate move of size `step`, using
the standard month-average extraction: the contract settles on the
monthly average effective rate, the pre-meeting rate applies through the
decision day, so \$\$r\_{post} = \frac{M\\\bar r - d\\ r\_{pre}}{M - d},
\qquad q = \frac{r\_{post} - r\_{pre}}{step},\$\$ with \\\bar r = 100 -
\mathrm{price}\\, `M` calendar days in the month, and `d` the day of the
month of the decision.

## Usage

``` r
q_from_ffutures(price, pre_rate, meeting_date, step = 0.25)
```

## Arguments

- price:

  Futures price(s), e.g. `95.21`.

- pre_rate:

  Effective rate prevailing before the meeting (percent, e.g. `5.33`).

- meeting_date:

  Decision date(s) (`Date`); see
  [fomc_meetings](https://www.sebastianstoeckl.com/eventclock/reference/fomc_meetings.md).

- step:

  Assumed move size in percentage points (default `0.25`).

## Value

A tibble with columns `meeting_date`, `implied_avg`, `implied_post`,
`delta_rate`, and `q` (probability of one `step` move; sign of
`delta_rate` gives the direction).

## Details

`q` is the probability of a single move of `step` under a two-point
assumption (no change vs. one move). Values outside \\\[0,1\]\\ indicate
that more than one step (or a move of the opposite sign) is priced:
`q = 1.6` means 25bp fully priced plus a 60% chance of a second step;
negative values indicate a priced move of the opposite sign. Flag, don't
drop. For a decision on the last day(s) of the month the denominator
degenerates — use the next-month contract. Intermeeting moves and months
with two meetings violate the two-point assumption; flag such periods
separately.

## See also

[fomc_meetings](https://www.sebastianstoeckl.com/eventclock/reference/fomc_meetings.md),
[`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_price.md),
[`q_from_deal_spread()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_deal_spread.md)

## Examples

``` r
# decision on the 15th of a 30-day month, pre-meeting rate 5.33%,
# futures at 94.79 -> a 25bp cut is priced with ~96% probability
q_from_ffutures(94.79, pre_rate = 5.33,
                meeting_date = as.Date("2024-09-15"), step = -0.25)
#> # A tibble: 1 × 5
#>   meeting_date implied_avg implied_post delta_rate     q
#>   <date>             <dbl>        <dbl>      <dbl> <dbl>
#> 1 2024-09-15          5.21         5.09     -0.240 0.960
```
