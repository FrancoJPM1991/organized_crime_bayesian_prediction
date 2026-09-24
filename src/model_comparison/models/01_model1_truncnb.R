library(INLA)

cfg <- list(
  data_dir = "data/processed/model_comparisson/truncnb",
  out_dir = "data/processed/model_comparisson/truncnb"
)

dp <- readRDS(file.path(cfg$data_dir, "truncnb_positive.rds"))
cat("Rows:", nrow(dp), "| municipalities:", length(unique(dp$mun_idx)),
    "| years:", length(unique(dp$year_idx)), "\n")

dp$year_rw <- dp$year_idx

formula1 <- y ~ 1 + year_idx + f(year_rw, model = "rw1")

fit1 <- inla(
  verbose = TRUE,
  formula1,
  family = "zeroinflatednbinomial0",
  data = dp,
  E = E,
  control.family = list(hyper = list(
    theta2 = list(initial = -20, fixed = TRUE)
  )),
  control.compute = list(dic = TRUE, waic = TRUE, cpo = TRUE, config = TRUE),
  control.predictor = list(compute = TRUE)
)

cat("\n**** Fixed effects ****\n")
print(fit1$summary.fixed[, c("mean", "sd", "0.025quant", "0.975quant")])

cat("\n**** Hyperparameters ****\n")
print(fit1$summary.hyperpar[, c("mean", "sd")])

cat("\n**** RW1 random effect around the trend ****\n")
print(summary(fit1$summary.random$year_rw$mean))
print(range(fit1$summary.random$year_rw$mean))

cat("\n**** Fit ****\n")
cat("WAIC:", fit1$waic$waic, "|DIC:", fit1$dic$dic, "\n")

n_failures <- sum(fit1$cpo$failure > 0, na.rm = TRUE)
cat("CPO failures:", n_failures, "of", nrow(dp), "\n")
lcpo <- -mean(log(fit1$cpo$cpo), na.rm = TRUE)
cat("LCPO (mean -log CPO):", lcpo, "\n")

#------------------------SAVE
saveRDS(fit1, file.path(cfg$out_dir, "fit_model1_truncnb.rds"))
cat("SAVED")


