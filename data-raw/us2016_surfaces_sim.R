## us2016_surfaces_sim: SIMULATED event-spanning option surfaces around the
## 2016 U.S. presidential election (S&P 500 index profile).
##
## Fully synthetic: every implied volatility below is generated from the
## package's lognormal event mixture (ec_mix_iv) plus Gaussian noise. The
## generator is parametrized by ESTIMATION RESULTS only — the common event
## exposure theta and the per-surface (q, s1, s2) fitted on index-option
## smiles over the last four pre-election weeks. No vendor data values,
## quotes, or residuals enter this dataset.

pkg <- "D:/OneDrive - University of Liechtenstein/ROOT/Packages/eventclock"
setwd(pkg)
suppressMessages(devtools::load_all(pkg, quiet = TRUE))

fitfile <- paste0(
  "D:/OneDrive - University of Liechtenstein/ROOT/Projects/",
  "_SANDBOX_election_clock/06_theta/output/us2016_theta_fit.rds"
)
fr <- readRDS(fitfile)
theta <- fr$fit$theta                 # -0.0774 (estimation result)
par <- fr$fit$surfaces[, c("surface", "q", "s1", "s2")]  # results only
rm(fr)

event_date <- as.Date("2016-11-08")
nodes <- seq(0.1, 0.9, by = 0.1)      # call-equivalent delta grid
noise_sd <- 0.004                     # annualized IV points / 100
set.seed(20161108)

rows <- lapply(seq_len(nrow(par)), function(i) {
  ids <- strsplit(par$surface[i], "_x_", fixed = TRUE)[[1]]
  obs_date <- as.Date(ids[1]); expiry_date <- as.Date(ids[2])
  tau <- as.numeric(expiry_date - obs_date) / 365
  q <- par$q[i]; s1 <- par$s1[i]; s2 <- par$s2[i]

  # fixed point: delta nodes -> log-moneyness under the model smile
  s_tot <- rep(ec_mix_iv(0, q, theta, s1, s2), length(nodes))
  for (it in 1:6) {
    k <- ec_delta_to_k(nodes, s_tot)
    s_tot <- ec_mix_iv(k, q, theta, s1, s2)
  }
  iv_ann <- s_tot / sqrt(tau) + stats::rnorm(length(nodes), sd = noise_sd)

  tibble::tibble(
    event_date = event_date, obs_date = obs_date,
    expiry_date = expiry_date, node = nodes,
    iv = round(iv_ann, 6), q = q
  )
})
us2016_surfaces_sim <- do.call(rbind, rows)

stopifnot(nrow(us2016_surfaces_sim) == nrow(par) * length(nodes),
          all(us2016_surfaces_sim$iv > 0))
save(us2016_surfaces_sim, file = "data/us2016_surfaces_sim.rda",
     compress = "xz")
cat("Saved data/us2016_surfaces_sim.rda:", nrow(us2016_surfaces_sim),
    "rows,", nrow(par), "surfaces, theta =", round(theta, 4), "\n")
