# Build the brexit2016 and us2016 datasets from the raw betting-quote CSVs.
# Run from the package root: source("data-raw/00-import-betdata.R")
stopifnot(file.exists("DESCRIPTION"))

src <- file.path(
  "D:", "OneDrive - University of Liechtenstein", "ROOT", "Exchange",
  "Forschung_Sebastian", "3131_Options", "SUP100"
)

# --- Brexit: semicolon-separated, DD.MM.YYYY, column "Q(remain)" -------------
gb_raw <- utils::read.csv2(
  file.path(src, "betdata_GB.csv"),
  dec = ".", check.names = FALSE, strip.white = TRUE
)
stopifnot(ncol(gb_raw) >= 2)
brexit2016 <- tibble::tibble(
  date = as.Date(trimws(gb_raw[[1]]), format = "%d.%m.%Y"),
  q_remain = as.numeric(gb_raw[[2]])
)
brexit2016$q_leave <- 1 - brexit2016$q_remain
stopifnot(!anyNA(brexit2016$date), !anyNA(brexit2016$q_remain))
stopifnot(nrow(brexit2016) == 119)

# --- US 2016: comma-separated, candidate columns in PERCENT ------------------
us_raw <- utils::read.csv(
  file.path(src, "betdata_us.csv"),
  check.names = FALSE, strip.white = TRUE
)
us2016 <- tibble::tibble(
  date = as.Date(us_raw$timestamp),
  trump = as.numeric(us_raw[["Donald Trump"]]) / 100,
  clinton = as.numeric(us_raw[["Hillary Clinton"]]) / 100,
  sanders = as.numeric(us_raw[["Bernie Sanders"]]) / 100,
  cruz = as.numeric(us_raw[["Ted Cruz"]]) / 100,
  kasich = as.numeric(us_raw[["John Kasich"]]) / 100,
  biden = as.numeric(us_raw[["Joe Biden"]]) / 100,
  mcmullin = as.numeric(us_raw[["Evan McMullin"]]) / 100,
  volume = as.numeric(us_raw$volume)
)
stopifnot(!anyNA(us2016$date), !anyNA(us2016$trump))
stopifnot(nrow(us2016) == 237)

usethis::use_data(brexit2016, us2016, overwrite = TRUE, compress = "xz")
