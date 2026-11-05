# Package index

## Event prices

Standardize and screen traded event probabilities.

- [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md)
  [`print(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md)
  [`summary(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md)
  [`plot(`*`<event_prices>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md)
  :

  Standardize traded event state prices as an `event_prices` object

- [`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/q_from_price.md)
  : Convert event state prices into state-price-implied event
  probabilities

- [`q_from_ffutures()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/q_from_ffutures.md)
  : Meeting-implied probability from a fed funds futures price

- [`q_from_deal_spread()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/q_from_deal_spread.md)
  : Completion probability from a merger-arbitrage spread

- [`ec_validate()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_validate.md)
  [`print(`*`<ec_validation>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_validate.md)
  : Data-quality report for an event-probability series

## The event clock

Estimate information time A from log-odds variation.

- [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)
  : Estimate event-clock time from log-odds variation
- [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_path.md)
  [`plot(`*`<event_clock_path>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_path.md)
  : Cumulative event-clock path
- [`ec_recovery_set()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_recovery_set.md)
  : Partial-recovery interval for the Event Clock
- [`ec_default_params()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_default_params.md)
  : Default parameters of the eventclock package

## Measuring the clock in practice

Sampling frequency, real-time forecasts, and multiple venues.

- [`event_clock_staggered()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_staggered.md)
  : Event Clock on staggered time grids
- [`ec_signature()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_signature.md)
  [`plot(`*`<ec_signature>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_signature.md)
  : Sampling-frequency signature of the Event Clock
- [`plot_signature()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/plot_signature.md)
  : Plot the sampling-frequency signature
- [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_forecast.md)
  : Real-time Event Clock forecast
- [`ec_forecast_rules()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_forecast_rules.md)
  : Candidate rules for real-time clock forecasts
- [`ec_forecast_select()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_forecast_select.md)
  [`print(`*`<ec_forecast_select>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_forecast_select.md)
  : Choose the real-time forecasting rule by out-of-sample accuracy
- [`event_clock_venues()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_venues.md)
  : Event Clocks from two venues: separating common news from venue
  noise
- [`event_clock_venues_path()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_venues_path.md)
  [`plot(`*`<event_clock_venues_path>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_venues_path.md)
  : Cumulative Event Clocks from two venues

## Event-spanning options

The lognormal event mixture and the event exposure theta.

- [`ec_mix_price()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_mix_price.md)
  [`ec_mix_iv()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_mix_price.md)
  : Option prices and implied volatility under the event mixture
- [`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_theta_fit.md)
  [`print(`*`<ec_theta_fit>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_theta_fit.md)
  : Estimate the log exposure theta from event-spanning option surfaces
- [`ec_theta_hump()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_theta_hump.md)
  : First-order log exposure from the spanning variance hump
- [`ec_delta_to_k()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_delta_to_k.md)
  : Convert a call-equivalent delta grid to log-moneyness
- [`ec_mix_price_pre()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_mix_price_pre.md)
  [`ec_mix_iv_pre()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_mix_price_pre.md)
  : Pre-resolution option prices under event learning

## Assets & finance

Event exposures and pricing relevance.

- [`event_beta()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_beta.md)
  [`print(`*`<event_beta>`*`)`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_beta.md)
  : Event beta: realized loading of asset returns on event-probability
  news
- [`ec_relevance()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_relevance.md)
  : Pricing relevance of event learning: the sufficient statistic

## Formula book

Closed-form calculators in (q, A).

- [`ec_moments()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_moments.md)
  : Moments of the terminal probability and log-odds
- [`ec_exceedance()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_exceedance.md)
  : Exceedance probability of the terminal event probability
- [`ec_revision()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_revision.md)
  : Typical revision of the event probability
- [`ec_atm_event_call()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_atm_event_call.md)
  : ATM claim on the event factor
- [`ec_sigma_eff()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_sigma_eff.md)
  : Effective volatility ahead of a scheduled event
- [`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_variance_share.md)
  : Variance share of event learning
- [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_iv_rule.md)
  : First-order implied-volatility contribution of event learning
- [`ec_target_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_target_clock.md)
  : Event-clock time needed to reach near-certainty
- [`ec_logit()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_logit.md)
  [`ec_ilogit()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_logit.md)
  : Log-odds (logit) transform

## Transition & simulation

- [`ec_transition_density()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_transition_density.md)
  : Density of the terminal log-odds
- [`ec_simulate()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_simulate.md)
  : Simulate the exact transition to resolution
- [`ec_simulate_path()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_simulate_path.md)
  : Simulate event-clock consistent probability paths

## Plots

- [`plot_q()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/plot_q.md)
  : Plot the event-probability path
- [`plot_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/plot_clock.md)
  : Clock plot: the cumulative Event Clock
- [`plot_clock_vs_calendar()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/plot_clock_vs_calendar.md)
  : Event-clock time versus calendar time

## Prediction-market connectors

Public, keyless price histories from Polymarket and Kalshi.

- [`pm_daily()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_daily.md)
  : Collapse intraday event prices to one daily snapshot
- [`pm_markets()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_markets.md)
  : List the markets and outcome tokens of a Polymarket event
- [`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_prices.md)
  : Download Polymarket price history for one outcome token
- [`pm_search()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_search.md)
  : Search Polymarket events
- [`ks_markets()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ks_markets.md)
  [`ks_events()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ks_markets.md)
  : List the markets of a Kalshi event
- [`ks_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ks_prices.md)
  : Download Kalshi price history for one market

## Data

- [`brexit2016`](https://www.sebastianstoeckl.com/eventclock/dev/reference/brexit2016.md)
  : Brexit 2016 event probabilities
- [`us2016`](https://www.sebastianstoeckl.com/eventclock/dev/reference/us2016.md)
  : U.S. presidential election 2016 event probabilities
- [`us2016_surfaces_sim`](https://www.sebastianstoeckl.com/eventclock/dev/reference/us2016_surfaces_sim.md)
  : Simulated event-spanning option surfaces, 2016 U.S. election profile
- [`polymarket2024`](https://www.sebastianstoeckl.com/eventclock/dev/reference/polymarket2024.md)
  : Polymarket 2024 U.S. presidential election prices (hourly)
- [`kalshi2024`](https://www.sebastianstoeckl.com/eventclock/dev/reference/kalshi2024.md)
  : Kalshi 2024 U.S. presidential election prices (daily 15:45 snapshot)
- [`fomc_meetings`](https://www.sebastianstoeckl.com/eventclock/dev/reference/fomc_meetings.md)
  : Scheduled FOMC meetings 2021-2027
- [`djt2024`](https://www.sebastianstoeckl.com/eventclock/dev/reference/djt2024.md)
  : Trump Media & Technology Group (DJT) daily prices, June-November
  2024
