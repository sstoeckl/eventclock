# Changelog

## eventclock 0.0.0.9000 (development version)

### New features

- Initial version of the package.
- [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/as_event_prices.md)
  turns any `data.frame`/`tibble` of traded event probabilities into a
  standardized `event_prices` object with flag-don’t-drop cleaning
  ([`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/q_from_price.md)
  handles discount and overround normalization).
- [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock.md)
  estimates event-clock (information) time `A` as the realized variation
  of log-odds, with truncation, bipower, and largest-move robustness
  variants;
  [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_path.md)
  returns the cumulative clock;
  [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/event_clock_forecast.md)
  implements the trailing-window real-time benchmark.
- Formula-book calculators
  [`ec_moments()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_moments.md),
  [`ec_exceedance()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_exceedance.md),
  [`ec_revision()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_revision.md),
  [`ec_atm_event_call()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_atm_event_call.md),
  [`ec_sigma_eff()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_sigma_eff.md),
  [`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_variance_share.md),
  [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_iv_rule.md),
  and
  [`ec_target_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_target_clock.md).
- Exact logistic-normal transition tools
  [`ec_transition_density()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_transition_density.md),
  [`ec_simulate()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_simulate.md),
  and
  [`ec_simulate_path()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/ec_simulate_path.md).
- Polymarket connector
  [`pm_search()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_search.md),
  [`pm_markets()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_markets.md),
  [`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_prices.md),
  and
  [`pm_daily()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/pm_daily.md)
  built on the public Gamma and CLOB APIs.
- Plotting helpers
  [`plot_q()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/plot_q.md),
  [`plot_clock()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/plot_clock.md),
  and
  [`plot_clock_vs_calendar()`](https://www.sebastianstoeckl.com/eventclock/dev/reference/plot_clock_vs_calendar.md).
- Datasets `brexit2016` and `us2016` reproducing the headline
  event-clock estimates of the accompanying working paper.
