# Hex logo for eventclock.
# Concept: a clock dial whose 12 ticks are placed where each 1/12 of the
# 2024 election's information actually arrived (real polymarket2024 data) —
# event-clock time vs. calendar time — plus the cumulative clock curve.
stopifnot(file.exists("DESCRIPTION"))
suppressMessages(devtools::load_all("."))
library(ggplot2)

# fonts (fall back silently to default if offline)
font_ok <- tryCatch({
  sysfonts::font_add_google("Roboto Condensed", "roboto")
  showtext::showtext_auto()
  TRUE
}, error = function(e) FALSE)
logo_font <- if (font_ok) "roboto" else "sans"

col_bg <- "#1d3048" # deep navy hex fill
col_hex <- "#f0a832" # amber border
col_curve <- "#ffffff"
col_tick <- "#f0a832"
col_dial <- "#7f97ad"

# --- real data: cumulative clock of the 2024 election (daily) ---------------
data(polymarket2024)
path <- event_clock_path(pm_daily(as_event_prices(polymarket2024)))
cf <- path$cal_frac
af <- path$A_frac

# ticks: calendar position at which each 1/12 of clock time had arrived
tick_af <- seq(1 / 12, 11 / 12, by = 1 / 12)
tick_cf <- vapply(tick_af, function(a) cf[which(af >= a)[1]], numeric(1))
# 12 o'clock = start; clockwise
tick_theta <- pi / 2 - 2 * pi * tick_cf
r_out <- 1
r_in <- 0.86
ticks <- data.frame(
  x = r_in * cos(tick_theta), xend = r_out * cos(tick_theta),
  y = r_in * sin(tick_theta), yend = r_out * sin(tick_theta)
)
# the "event" tick at 12 o'clock, doubled weight
ev <- data.frame(x = 0, xend = 0, y = 0.78, yend = 1)

# dial circle
th <- seq(0, 2 * pi, length.out = 400)
dial <- data.frame(x = cos(th), y = sin(th))

# cumulative clock curve inside the dial (staircase), scaled to a box
sc <- function(v, lo, hi) lo + v * (hi - lo)
curve_df <- data.frame(
  x = sc(cf, -0.62, 0.62),
  y = sc(af, -0.52, 0.55)
)

sub <- ggplot() +
  geom_path(data = dial, aes(x, y), color = col_dial, linewidth = 0.5) +
  geom_segment(
    data = ticks, aes(x = x, y = y, xend = xend, yend = yend),
    color = col_tick, linewidth = 0.9, lineend = "round"
  ) +
  geom_segment(
    data = ev, aes(x = x, y = y, xend = xend, yend = yend),
    color = "#e74c3c", linewidth = 1.4, lineend = "round"
  ) +
  geom_step(
    data = curve_df, aes(x, y),
    color = col_curve, linewidth = 0.75
  ) +
  coord_equal(xlim = c(-1.05, 1.05), ylim = c(-1.05, 1.05)) +
  theme_void() +
  theme(plot.background = element_blank(), panel.background = element_blank())

hexSticker::sticker(
  sub,
  package = "eventclock",
  p_family = logo_font, p_size = 22, p_color = "#ffffff", p_y = 0.52,
  s_x = 1, s_y = 1.18, s_width = 1.25, s_height = 1.25,
  h_fill = col_bg, h_color = col_hex, h_size = 1.4,
  url = "",
  filename = "man/figures/logo.png", dpi = 320
)
cat("written: man/figures/logo.png\n")
