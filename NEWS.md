# eventclock 0.3.0

## Assets & finance

* `event_beta()` — realized-loading regression of asset returns on
  event-probability news, with a base-R Newey-West (Bartlett/HAC)
  covariance, model-implied outcome levels under the risk-neutral
  adding-up constraint, and — given an externally measured exposure via
  `deta` — the loading test of `beta = 1`.
* `ec_relevance()` — the sufficient statistic for whether event learning
  is first-order for an asset's option prices; ties out exactly with
  `ec_variance_share()` and `ec_iv_rule()`.
* `q_from_ffutures()` — meeting-implied probabilities from 30-day fed
  funds futures on the standard month-average extraction, with the new
  `fomc_meetings` calendar dataset (2021-2027).
* `q_from_deal_spread()` — completion probabilities from merger-arb
  spreads: deal clocks feed the same q -> logit -> A pipeline.
* New dataset `djt2024` (daily DJT prices, June-November 2024) powering
  the event-beta example against `polymarket2024`.

# eventclock 0.2.0

## Inference & validation

* `event_clock(se = TRUE)` — standard errors and confidence intervals
  for the realized-variation estimate, via the quarticity analogue
  (log-based intervals) or a moment-matched wild bootstrap
  (`se_method = "bootstrap"`).
* `ec_signature()` and `plot_signature()` — the sampling-frequency
  signature plot of the clock (subsample-averaged), the standard
  microstructure-noise diagnostic.
* `ec_validate()` — data-quality report for event-probability series:
  coverage, staleness, tick size, gaps, and outliers, in the
  flag-don't-drop spirit.
* `ec_simulate_path()` gains `jump_share`/`n_jumps` for lumpy
  information arrival (Bayes-consistent per step), the testbed for the
  jump-robust estimator variants.
* New vignette "Validating the event-clock estimator" (Monte Carlo:
  consistency, CI coverage, outcome-independence/measure robustness,
  bipower under jumps, microstructure and the snapshot rule).
* CI now runs the full `R CMD check` including vignettes on a
  three-OS matrix in a non-UTC timezone, plus a coverage job.

# eventclock 0.1.0 (initial version)

## New features

* Initial version of the package.
* `as_event_prices()` turns any `data.frame`/`tibble` of traded event
  probabilities into a standardized `event_prices` object with
  flag-don't-drop cleaning (`q_from_price()` handles discount and overround
  normalization).
* `event_clock()` estimates event-clock (information) time `A` as the
  realized variation of log-odds, with truncation, bipower, and
  largest-move robustness variants; `event_clock_path()` returns the
  cumulative clock; `event_clock_forecast()` implements the trailing-window
  real-time benchmark.
* Formula-book calculators `ec_moments()`, `ec_exceedance()`,
  `ec_revision()`, `ec_atm_event_call()`, `ec_sigma_eff()`,
  `ec_variance_share()`, `ec_iv_rule()`, and `ec_target_clock()`.
* Exact logistic-normal transition tools `ec_transition_density()`,
  `ec_simulate()`, and `ec_simulate_path()`.
* Polymarket connector `pm_search()`, `pm_markets()`, `pm_prices()`, and
  `pm_daily()` built on the public Gamma and CLOB APIs.
* Plotting helpers `plot_q()`, `plot_clock()`, and
  `plot_clock_vs_calendar()`.
* Datasets `brexit2016` and `us2016` reproducing the headline event-clock
  estimates of the accompanying working paper.
