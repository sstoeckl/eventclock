# Changelog

## eventclock 0.3.0

### Assets & finance

- [`event_beta()`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)
  — realized-loading regression of asset returns on event-probability
  news, with a base-R Newey-West (Bartlett/HAC) covariance,
  model-implied outcome levels under the risk-neutral adding-up
  constraint, and — given an externally measured exposure via `deta` —
  the loading test of `beta = 1`.
- [`ec_relevance()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_relevance.md)
  — the sufficient statistic for whether event learning is first-order
  for an asset’s option prices; ties out exactly with
  [`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_variance_share.md)
  and
  [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md).
- [`q_from_ffutures()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_ffutures.md)
  — meeting-implied probabilities from 30-day fed funds futures on the
  standard month-average extraction, with the new `fomc_meetings`
  calendar dataset (2021-2027).
- [`q_from_deal_spread()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_deal_spread.md)
  — completion probabilities from merger-arb spreads: deal clocks feed
  the same q -\> logit -\> A pipeline.
- New dataset `djt2024` (daily DJT prices, June-November 2024) powering
  the event-beta example against `polymarket2024`.

## eventclock 0.2.0

### Inference & validation

- `event_clock(se = TRUE)` — standard errors and confidence intervals
  for the realized-variation estimate, via the quarticity analogue
  (log-based intervals) or a moment-matched wild bootstrap
  (`se_method = "bootstrap"`).
- [`ec_signature()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_signature.md)
  and
  [`plot_signature()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_signature.md)
  — the sampling-frequency signature plot of the clock
  (subsample-averaged), the standard microstructure-noise diagnostic.
- [`ec_validate()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_validate.md)
  — data-quality report for event-probability series: coverage,
  staleness, tick size, gaps, and outliers, in the flag-don’t-drop
  spirit.
- [`ec_simulate_path()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_simulate_path.md)
  gains `jump_share`/`n_jumps` for lumpy information arrival
  (Bayes-consistent per step), the testbed for the jump-robust estimator
  variants.
- New vignette “Validating the event-clock estimator” (Monte Carlo:
  consistency, CI coverage, outcome-independence/measure robustness,
  bipower under jumps, microstructure and the snapshot rule).
- CI now runs the full `R CMD check` including vignettes on a three-OS
  matrix in a non-UTC timezone, plus a coverage job.

## eventclock 0.1.0 (initial version)

### New features

- Initial version of the package.
- [`as_event_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/as_event_prices.md)
  turns any `data.frame`/`tibble` of traded event probabilities into a
  standardized `event_prices` object with flag-don’t-drop cleaning
  ([`q_from_price()`](https://www.sebastianstoeckl.com/eventclock/reference/q_from_price.md)
  handles discount and overround normalization).
- [`event_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock.md)
  estimates event-clock (information) time `A` as the realized variation
  of log-odds, with truncation, bipower, and largest-move robustness
  variants;
  [`event_clock_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_path.md)
  returns the cumulative clock;
  [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_forecast.md)
  implements the trailing-window real-time benchmark.
- Formula-book calculators
  [`ec_moments()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_moments.md),
  [`ec_exceedance()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_exceedance.md),
  [`ec_revision()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_revision.md),
  [`ec_atm_event_call()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_atm_event_call.md),
  [`ec_sigma_eff()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_sigma_eff.md),
  [`ec_variance_share()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_variance_share.md),
  [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md),
  and
  [`ec_target_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_target_clock.md).
- Exact logistic-normal transition tools
  [`ec_transition_density()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_transition_density.md),
  [`ec_simulate()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_simulate.md),
  and
  [`ec_simulate_path()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_simulate_path.md).
- Polymarket connector
  [`pm_search()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_search.md),
  [`pm_markets()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_markets.md),
  [`pm_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_prices.md),
  and
  [`pm_daily()`](https://www.sebastianstoeckl.com/eventclock/reference/pm_daily.md)
  built on the public Gamma and CLOB APIs.
- Plotting helpers
  [`plot_q()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_q.md),
  [`plot_clock()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_clock.md),
  and
  [`plot_clock_vs_calendar()`](https://www.sebastianstoeckl.com/eventclock/reference/plot_clock_vs_calendar.md).
- Datasets `brexit2016` and `us2016` reproducing the headline
  event-clock estimates of the accompanying working paper.
