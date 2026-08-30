# Package index

## Event prices

Standardize and screen traded event probabilities.

- [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`print(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`summary(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`plot(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  :

  Standardize traded event probabilities as an `event_prices` object

- [`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_price.md)
  : Convert traded state prices into risk-adjusted event probabilities

- [`q_from_ffutures()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_ffutures.md)
  : Meeting-implied probability from a fed funds futures price

- [`q_from_deal_spread()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_deal_spread.md)
  : Completion probability from a merger-arbitrage spread

- [`ec_validate()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_validate.md)
  [`print(`*`<ec_validation>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/ec_validate.md)
  : Data-quality report for an event-probability series

## The event clock

Estimate information time A from log-odds variation.

- [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md)
  : Estimate event-clock (information) time from log-odds variation
- [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  [`plot(`*`<event_clock_path>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  : Cumulative event-clock path
- [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_forecast.md)
  : Real-time event-clock forecast
- [`ec_signature()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_signature.md)
  [`plot(`*`<ec_signature>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/ec_signature.md)
  : Sampling-frequency signature of the event clock
- [`plot_signature()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_signature.md)
  : Plot the sampling-frequency signature
- [`ec_default_params()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_default_params.md)
  : Default parameters of the eventclock package

## Assets & finance

Event exposures and pricing relevance.

- [`event_beta()`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)
  [`print(`*`<event_beta>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)
  : Event beta: realized loading of asset returns on event-probability
  news
- [`ec_relevance()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_relevance.md)
  : Pricing relevance of event learning: the sufficient statistic

## Formula book

Closed-form calculators in (q, A).

- [`ec_moments()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_moments.md)
  : Moments of the terminal probability and log-odds
- [`ec_exceedance()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_exceedance.md)
  : Exceedance probability of the terminal event probability
- [`ec_revision()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_revision.md)
  : Typical revision of the event probability
- [`ec_atm_event_call()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_atm_event_call.md)
  : ATM claim on the event factor
- [`ec_sigma_eff()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_sigma_eff.md)
  : Effective volatility ahead of a scheduled event
- [`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_variance_share.md)
  : Variance share of event learning
- [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md)
  : Rule of thumb: implied-volatility contribution of event learning
- [`ec_target_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_target_clock.md)
  : Event-clock time needed to reach near-certainty
- [`ec_logit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_logit.md)
  [`ec_ilogit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_logit.md)
  : Log-odds (logit) transform

## Transition & simulation

- [`ec_transition_density()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_transition_density.md)
  : Density of the terminal log-odds
- [`ec_simulate()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_simulate.md)
  : Simulate the exact transition to resolution
- [`ec_simulate_path()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_simulate_path.md)
  : Simulate event-clock consistent probability paths

## Plots

- [`plot_q()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_q.md)
  : Plot the event-probability path
- [`plot_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_clock.md)
  : Clock plot: the cumulative event clock
- [`plot_clock_vs_calendar()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_clock_vs_calendar.md)
  : Event-clock time versus calendar time

## Polymarket connector

- [`pm_daily()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_daily.md)
  : Collapse intraday event prices to one daily snapshot
- [`pm_markets()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_markets.md)
  : List the markets and outcome tokens of a Polymarket event
- [`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_prices.md)
  : Download Polymarket price history for one outcome token
- [`pm_search()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_search.md)
  : Search Polymarket events

## Data

- [`brexit2016`](https://www.sebastianstoeckl.com/eventclock/reference/brexit2016.md)
  : Brexit 2016 event probabilities
- [`us2016`](https://www.sebastianstoeckl.com/eventclock/reference/us2016.md)
  : U.S. presidential election 2016 event probabilities
- [`polymarket2024`](https://www.sebastianstoeckl.com/eventclock/reference/polymarket2024.md)
  : Polymarket 2024 U.S. presidential election prices (hourly)
- [`fomc_meetings`](https://www.sebastianstoeckl.com/eventclock/reference/fomc_meetings.md)
  : Scheduled FOMC meetings 2021-2027
- [`djt2024`](https://www.sebastianstoeckl.com/eventclock/reference/djt2024.md)
  : Trump Media & Technology Group (DJT) daily prices, June-November
  2024
