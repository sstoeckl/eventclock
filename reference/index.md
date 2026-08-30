# Package index

## Event prices

Standardize traded event probabilities.

- [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`print(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`summary(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`plot(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  :

  Standardize traded event probabilities as an `event_prices` object

- [`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_price.md)
  : Convert traded state prices into risk-adjusted event probabilities

## The event clock

Estimate information time A from log-odds variation.

- [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md)
  : Estimate event-clock (information) time from log-odds variation
- [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  [`plot(`*`<event_clock_path>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  : Cumulative event-clock path
- [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_forecast.md)
  : Real-time event-clock forecast

## Formula book

Closed-form calculators in (q, A).

- [`ec_atm_event_call()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_atm_event_call.md)
  : ATM claim on the event factor
- [`ec_default_params()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_default_params.md)
  : Default parameters of the eventclock package
- [`ec_exceedance()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_exceedance.md)
  : Exceedance probability of the terminal event probability
- [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md)
  : Rule of thumb: implied-volatility contribution of event learning
- [`ec_logit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_logit.md)
  [`ec_ilogit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_logit.md)
  : Log-odds (logit) transform
- [`ec_moments()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_moments.md)
  : Moments of the terminal probability and log-odds
- [`ec_revision()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_revision.md)
  : Typical revision of the event probability
- [`ec_sigma_eff()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_sigma_eff.md)
  : Effective volatility ahead of a scheduled event
- [`ec_simulate()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_simulate.md)
  : Simulate the exact transition to resolution
- [`ec_simulate_path()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_simulate_path.md)
  : Simulate event-clock consistent probability paths
- [`ec_target_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_target_clock.md)
  : Event-clock time needed to reach near-certainty
- [`ec_transition_density()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_transition_density.md)
  : Density of the terminal log-odds
- [`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_variance_share.md)
  : Variance share of event learning

## Plots

- [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`print(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`summary(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  [`plot(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  :

  Standardize traded event probabilities as an `event_prices` object

- [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  [`plot(`*`<event_clock_path>`*`)`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  : Cumulative event-clock path

- [`plot_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_clock.md)
  : Clock plot: the cumulative event clock

- [`plot_clock_vs_calendar()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_clock_vs_calendar.md)
  : Event-clock time versus calendar time

- [`plot_q()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_q.md)
  : Plot the event-probability path

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
