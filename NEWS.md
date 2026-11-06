# eventclock 0.6.0

## Ordinary-risk benchmark from quiet-clock surfaces

* `ec_quiet_library()` builds the library of earlier option surfaces:
  at-the-money volatility, smile shape relative to at-the-money
  (difference or ratio), calendar days to expiry, and the Event Clock
  realized over each surface's own remaining life (from event prices,
  optionally on staggered intraday grids, or supplied).
* `ec_quiet_rules()` fixes the template-rule grid in advance: quietness
  threshold (quantile of the available clocks or absolute) ×
  days-to-expiry band × aggregation (all, most recent *n*, *n* nearest by
  at-the-money volatility). The defaults are the 15-rule grid; the
  30-rule variant is one call.
* `ec_quiet_shape()` predicts a target's smile shape under each rule from
  templates that expired at or before the target date; the target
  contributes only its date, expiry, and at-the-money level.
* `ec_quiet_select()` chooses the rule by cross-validation on earlier
  pseudo-targets (maturity block left out; optionally only templates
  available at each pseudo-target date; optionally only pseudo-targets
  with a minimum days to expiry, `pseudo_min_dte`), with wing-shape RMSE
  over `0.04 <= |k| <= 0.30` (or `0.5 <= |z| <= 3` in standardized
  moneyness, `k / (ATM volatility × sqrt(tau))`), a common node set
  across rules, and the target's predicted shape under every rule.

## Exchange option data

* `cme_definitions()`, `cme_statistics()`, `cme_option_surfaces()` turn
  CME Globex instrument definitions and daily statistics (Databento's
  `GLBX.MDP3` schemas, as Parquet or CSV files or data frames) into
  option surfaces: last final settlement per trading date, futures
  settlement as forward, time to the published expiration, Black (1976)
  implied volatilities (both sides and out-of-the-money), vega, open
  interest, a put-call parity diagnostic, exercise style from the CFI
  code, inverted quotes (`invert = TRUE`), and the event probability at
  the valuation time. Files whose columns all arrived as text read the
  same as typed files. The output feeds `ec_theta_fit()` and
  `ec_quiet_library()` directly. No exchange data ships with the
  package.
* The exchange reuses instrument identifiers after a contract expires or
  is deleted (a call can become a put, a spread an option).
  `cme_definitions()` therefore returns one row per identifier *phase*
  (`valid_from`, `valid_to`, `deleted`), and `cme_option_surfaces()`
  attributes each daily statistic to the phase in force on its trading
  date; the output names the contracts used (`call_symbol`,
  `put_symbol`).

# eventclock 0.5.0

## Bug fix

* `event_beta()` now takes the probability *level* at each asset date
  (the last observation on or before it) and differences it between
  consecutive asset dates. Previously probability changes were computed
  on the calendar-daily series before matching, so moves over weekends
  and holidays were lost: a Monday return was paired with the
  Sunday-to-Monday change only. On the shipped DJT/Polymarket example
  the exposure estimate rises from 1.28 (t = 2.6) to 1.47 (t = 3.9).

## Synchronization with the current working paper

* `ec_recovery_set()` now uses the paper's notation: the partial-recovery
  bound is `delta` (the old argument `eps` still works with a
  deprecation warning; the output column is now `delta`). The
  documentation states the bound exactly as in the paper — valuation
  variation at most `delta^2` times the *measured* log-odds variation —
  and explains the low-clock endpoint `(1 - delta)^2`.
* The companion working paper *The Event Clock: What State Prices
  Identify About Physical Information* (SSRN 7420838) is now cited in
  `citation("eventclock")`, the README, and the vignettes; the package
  version in the citation is read from `DESCRIPTION`.
* "Event Clock" is capitalized throughout, as in the papers
  ("event-clock time" stays lower case).
* `ec_iv_rule()` is documented as the first-order screening formula; the
  exact pre-resolution value is `ec_mix_iv_pre()`, which reproduces the
  paper's Brexit two-week learning contribution (0.0083 IV points).
* Golden tests relabeled: Brexit 1W/2W/1M clocks are the paper's
  main-text numbers; robustness variants are pinned against earlier
  versions' reference values; the trailing-60 real-time forecast
  reproduces the paper's 2016 values (0.0476 / 0.0951) to within 1%.

## Measuring the clock in practice

* `event_clock_forecast()` is rebuilt around the paper's no-look-ahead
  forecast: estimation windows in trailing observations (default,
  unchanged results), trailing calendar days (`days = 3` with hourly
  data), or the whole history (`expanding = TRUE`); any estimator
  (`method`); optional staggered sampling (`interval`). New output
  columns `rule` and `rate_per_day`.
* `ec_forecast_rules()` and `ec_forecast_select()` choose the forecasting
  rule by out-of-sample RMSE on earlier option lives only. On the shipped
  data they reproduce the working paper's choices: trailing-60 realized
  variation for the 2016 daily series, and a trailing three-day window
  for hourly Polymarket prices with weekly option lives in 2024.
* `event_clock_staggered()` — clocks on staggered time grids (e.g. 30-,
  60-, 120-minute sampling averaged over all grid offsets), with the
  estimator applied within each grid.
* `event_clock_venues()` / `event_clock_venues_path()` — clocks from two
  venues: each venue's own clock, the equal-weight composite, and the
  cross-venue clock that filters venue-specific noise; reports
  increment correlation and each venue's noise share.

## Option-implied exposure and a second venue

* `ec_theta_fit()` gains a date-block (moving-block) bootstrap for the
  common exposure (`boot_reps`, `block`, `block_length`, `conf`), the
  working paper's inference for the conditional-mean ratio; per-node
  fitted values and residuals (`$nodes`); and, when bid and ask implied
  volatilities are supplied, the share of fitted values inside the
  quotes (`$inside_share`).
* Kalshi connector: `ks_events()`, `ks_markets()`, `ks_prices()` on the
  public, keyless trade API (live and settled markets, chunked
  candlesticks, last-trade or mid prices), returning `event_prices`
  objects.
* New dataset `kalshi2024`: daily 15:45 New York snapshot of the Kalshi
  Trump-win contract, October 4 to November 5, 2024 — the second venue
  for `event_clock_venues()`.

## Pricing, data, and documentation

* `ec_mix_price_pre()` / `ec_mix_iv_pre()` — exact pre-resolution
  option prices under event learning: the future event probability
  follows the maintained two-component logistic-normal transition,
  ordinary risk is an independent lognormal, and `A = 0` collapses to
  the fixed-probability (no-learning) Black benchmark. Completes the
  pricing side of the framework; the first-order formula-book versions
  (`ec_sigma_eff()`, `ec_iv_rule()`) remain as back-of-the-envelope
  checks.
* The event-spanning vignette was rewritten for general readers:
  motivation without paper context, an explicit "what you need"
  section, and a new pre-resolution pricing section.
* README gains a workflow section mapping the paper's sequential
  architecture (probability -> clock -> validation -> returns-based
  exposure -> option-implied exposure -> learning test) to functions
  and vignettes.
* pkgdown now renders help-page math via MathJax (previously raw
  LaTeX appeared on reference pages).
* New dataset `us2016_surfaces_sim`: simulated event-spanning
  delta-grid surfaces matching the S&P 500 profile over the last four
  weeks before the 2016 U.S. election (47 surfaces, common exposure
  theta = -0.077). Fully synthetic — generated from the event mixture
  with fitted parameters as calibration targets — and the worked
  real-scale example of the event-spanning vignette.

# eventclock 0.4.0

## Event-spanning options

* `ec_mix_price()` / `ec_mix_iv()` — forward-normalized option prices and
  Black implied dispersions under the two-component lognormal event
  mixture (outcome-conditional means parametrized by the event exposure
  `theta = log(m1/m2)` under the pricing-measure adding-up
  normalization).
* `ec_theta_fit()` — the common conditional-mean-ratio design: per-surface
  outcome-conditional dispersions, one event exposure `theta` across all
  event-spanning surfaces (surface-balanced IV objective); `common =
  FALSE` gives the free-ratio diagnostic.
* `ec_theta_hump()` — first-order `|theta|` from the spanning
  total-variance hump, `sqrt(dvar / (q (1 - q)))`; the quick estimator on
  top of an existing maturity-hump pipeline.
* `ec_delta_to_k()` — call-equivalent delta grid to log-forward moneyness.

## Event clock

* `ec_recovery_set()` — the sharp partial-recovery interval
  `[(1 - eps)_+^2 A, (1 + eps)^2 A]` for the physical event clock, the
  working paper's sensitivity grid around exact recovery.

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
