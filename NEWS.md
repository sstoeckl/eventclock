# eventclock 0.0.0.9000 (development version)

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
