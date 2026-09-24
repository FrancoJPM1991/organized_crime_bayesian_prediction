library(pscl)

cfg <- list(
  data_path = "data/interim/crime_with_population.csv",
  col_mun = "CVEGEO",
  col_year = "year",
  col_count = "crime_count",
  col_logpop = "log_pop",
  out_dir = "data/processed/model_comparisson/truncnb"
)

pad5 <- function(x) formatC(as.integer(x), width = 5, flag = "0")

dat <- read.csv(cfg$data_path, check.names = FALSE,
                colClasses = setNames("character", cfg$col_mun))

d <- data.frame(
  mun_id = pad5(dat[[cfg$col_mun]]),
  year = as.integer(dat[[cfg$col_year]]),
  y = as.integer(dat[[cfg$col_count]]),
  E = exp(suppressWarnings(as.numeric(dat[[cfg$col_logpop]])))
)

stopifnot(!anyNA(d[, c("mun_id", "year", "y")]))

no_pop_ids <- unique(d$mun_id[is.na(d$E)])
cat("Municipalities excluded entirely (no population record:",
    length(no_pop_ids), "\n")

d2 <- d[!(d$mun_id %in% no_pop_ids), ]
d2$year <- factor(d2$year)

cat("Rows: full panel", nrow(d), "-> after exclusion", nrow(d2), "\n")
cat("Zeros:", sum(d2$y == 0), "| positives:", sum(d2$y >= 1), "\n")


fit_hnb <- hurdle(
  y ~ year + offset(log(E)) | 1,
  data = d2,
  dist = "negbin",
  zero.dist = "binomial"
)

cat("\n***** Hurdle NB summary ****\n")
print(summary(fit_hnb))

cat("\n**** Count-part coefficients ****\n")
print(coef(fit_hnb, model = "count"))

cat("\n**** Count-part theta ****\n")
print(fit_hnb$theta)

cat("\nAIC:", AIC(fit_hnb), "| loglik:", logLik(fit_hnb), "\n")

#------------------------------SAVE
saveRDS(fit_hnb, file.path(cfg$out_dir, "fit_hnb_benchmark.rds"))
print("SAVED")







