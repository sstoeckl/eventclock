# Changelog

## eventclock 0.5.0

### Bug fix

- [`event_beta()`](https://www.sebastianstoeckl.com/eventclock/reference/event_beta.md)
  now takes the probability *level* at each asset date (the last
  observation on or before it) and differences it between consecutive
  asset dates. Previously probability changes were computed on the
  calendar-daily series before matching, so moves over weekends and
  holidays were lost: a Monday return was paired with the
  Sunday-to-Monday change only. On the shipped DJT/Polymarket example
  the exposure estimate rises from 1.28 (t = 2.6) to 1.47 (t = 3.9).

### Synchronization with the current working paper

- [`ec_recovery_set()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_recovery_set.md)
  now uses the paper’s notation: the partial-recovery bound is `delta`
  (the old argument `eps` still works with a deprecation warning; the
  output column is now `delta`). The documentation states the bound
  exactly as in the paper — valuation variation at most `delta^2` times
  the *measured* log-odds variation — and explains the low-clock
  endpoint `(1 - delta)^2`.
- The companion working paper *The Event Clock: What State Prices
  Identify About Physical Information* (SSRN 7420838) is now cited in
  `citation("eventclock")`, the README, and the vignettes; the package
  version in the citation is read from `DESCRIPTION`.
- “Event Clock” is capitalized throughout, as in the papers
  (“event-clock time” stays lower case).
- [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md)
  is documented as the first-order screening formula; the exact
  pre-resolution value is
  [`ec_mix_iv_pre()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price_pre.md),
  which reproduces the paper’s Brexit two-week learning contribution
  (0.0083 IV points).
- Golden tests relabeled: Brexit 1W/2W/1M clocks are the paper’s
  main-text numbers; robustness variants are pinned against earlier
  versions’ reference values; the trailing-60 real-time forecast
  reproduces the paper’s 2016 values (0.0476 / 0.0951) to within 1%.

### Measuring the clock in practice

- [`event_clock_forecast()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_forecast.md)
  is rebuilt around the paper’s no-look-ahead forecast: estimation
  windows in trailing observations (default, unchanged results),
  trailing calendar days (`days = 3` with hourly data), or the whole
  history (`expanding = TRUE`); any estimator (`method`); optional
  staggered sampling (`interval`). New output columns `rule` and
  `rate_per_day`.
- [`ec_forecast_rules()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_forecast_rules.md)
  and
  [`ec_forecast_select()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_forecast_select.md)
  choose the forecasting rule by out-of-sample RMSE on earlier option
  lives only. On the shipped data they reproduce the working paper’s
  choices: trailing-60 realized variation for the 2016 daily series, and
  a trailing three-day window for hourly Polymarket prices with weekly
  option lives in 2024.
- [`event_clock_staggered()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_staggered.md)
  — clocks on staggered time grids (e.g. 30-, 60-, 120-minute sampling
  averaged over all grid offsets), with the estimator applied within
  each grid.
- [`event_clock_venues()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_venues.md)
  /
  [`event_clock_venues_path()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_venues_path.md)
  — clocks from two venues: each venue’s own clock, the equal-weight
  composite, and the cross-venue clock that filters venue-specific
  noise; reports increment correlation and each venue’s noise share.

### Option-implied exposure and a second venue

- [`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_fit.md)
  gains a date-block (moving-block) bootstrap for the common exposure
  (`boot_reps`, `block`, `block_length`, `conf`), the working paper’s
  inference for the conditional-mean ratio; per-node fitted values and
  residuals (`$nodes`); and, when bid and ask implied volatilities are
  supplied, the share of fitted values inside the quotes
  (`$inside_share`).
- Kalshi connector:
  [`ks_events()`](https://www.sebastianstoeckl.com/eventclock/reference/ks_markets.md),
  [`ks_markets()`](https://www.sebastianstoeckl.com/eventclock/reference/ks_markets.md),
  [`ks_prices()`](https://www.sebastianstoeckl.com/eventclock/reference/ks_prices.md)
  on the public, keyless trade API (live and settled markets, chunked
  candlesticks, last-trade or mid prices), returning `event_prices`
  objects.
- New dataset `kalshi2024`: daily 15:45 New York snapshot of the Kalshi
  Trump-win contract, October 4 to November 5, 2024 — the second venue
  for
  [`event_clock_venues()`](https://www.sebastianstoeckl.com/eventclock/reference/event_clock_venues.md).

### Pricing, data, and documentation

- [`ec_mix_price_pre()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price_pre.md)
  /
  [`ec_mix_iv_pre()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price_pre.md)
  — exact pre-resolution option prices under event learning: the future
  event probability follows the maintained two-component logistic-normal
  transition, ordinary risk is an independent lognormal, and `A = 0`
  collapses to the fixed-probability (no-learning) Black benchmark.
  Completes the pricing side of the framework; the first-order
  formula-book versions
  ([`ec_sigma_eff()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_sigma_eff.md),
  [`ec_iv_rule()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_iv_rule.md))
  remain as back-of-the-envelope checks.
- The event-spanning vignette was rewritten for general readers:
  motivation without paper context, an explicit “what you need” section,
  and a new pre-resolution pricing section.
- README gains a workflow section mapping the paper’s sequential
  architecture (probability -\> clock -\> validation -\> returns-based
  exposure -\> option-implied exposure -\> learning test) to functions
  and vignettes.
- pkgdown now renders help-page math via MathJax (previously raw LaTeX
  appeared on reference pages).
- New dataset `us2016_surfaces_sim`: simulated event-spanning delta-grid
  surfaces matching the S&P 500 profile over the last four weeks before
  the 2016 U.S. election (47 surfaces, common exposure theta = -0.077).
  Fully synthetic — generated from the event mixture with fitted
  parameters as calibration targets — and the worked real-scale example
  of the event-spanning vignette.

## eventclock 0.4.0

### Event-spanning options

- [`ec_mix_price()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price.md)
  /
  [`ec_mix_iv()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_mix_price.md)
  — forward-normalized option prices and Black implied dispersions under
  the two-component lognormal event mixture (outcome-conditional means
  parametrized by the event exposure `theta = log(m1/m2)` under the
  pricing-measure adding-up normalization).
- [`ec_theta_fit()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_fit.md)
  — the common conditional-mean-ratio design: per-surface
  outcome-conditional dispersions, one event exposure `theta` across all
  event-spanning surfaces (surface-balanced IV objective);
  `common = FALSE` gives the free-ratio diagnostic.
- [`ec_theta_hump()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_theta_hump.md)
  — first-order `|theta|` from the spanning total-variance hump,
  `sqrt(dvar / (q (1 - q)))`; the quick estimator on top of an existing
  maturity-hump pipeline.
- [`ec_delta_to_k()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_delta_to_k.md)
  — call-equivalent delta grid to log-forward moneyness.

### Event clock

- [`ec_recovery_set()`](https://www.sebastianstoeckl.com/eventclock/reference/ec_recovery_set.md)
  — the sharp partial-recovery interval
  `[(1 - eps)_+^2 A, (1 + eps)^2 A]` for the physical event clock, the
  working paper’s sensitivity grid around exact recovery.

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
