# Silence R CMD check notes for non-standard evaluation used with dplyr/ggplot2.
utils::globalVariables(c(
  # event_prices columns
  "time", "q", "q_raw", "flag_clip", "flag_na",
  # clock path columns
  "L", "dL", "dA", "A", "A_frac", "cal_frac",
  # polymarket connector
  "t", "p", "hr", "date", "outcome", "token_id", "question",
  "market_slug", "event_slug",
  # signature / beta
  "spacing_days", "A_min", "A_max", "dq",
  # plotting
  "method", "horizon"
))
