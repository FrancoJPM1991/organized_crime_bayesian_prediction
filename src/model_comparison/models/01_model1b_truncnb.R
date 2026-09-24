library(INLA)

cfg <- list(
  data_dir = "data/processed/model_comparisson/truncnb",
  out_dir = "data/processed/model_comparisson/truncnb"
)

dp <- readRDS(file.path(cfg$data_dir, "truncnb_positive.rds"))
dp$year_rw <- dp$year_idx
cat("Rows:", nrow(dp), "| municipalities:", length(unique(dp$mun_idx)),
    "| years:", length(unique(dp$year_idx)), "\n")

formula1b <-y ~ 1 + year_idx + f(year_rw, model = "rw1") + f(mun_idx, model = "iid")

fit1b <- inla(
  formula1b,
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
print(fit1b$summary.fixed[, c("mean", "sd", "0.025quant", "0.975quant")])

cat("\n**** Hyperparameters ****\n")
print(fit1b$summary.hyperpar[, c("mean", "sd")])

cat("\n**** RW1 random effect around the trend ****\n")
print(summary(fit1b$summary.random$year_rw$mean))
print(range(fit1b$summary.random$year_rw$mean))

cat("\n**** Fit ****\n")
cat("WAIC:", fit1b$waic$waic, "|DIC:", fit1b$dic$dic, "\n")

n_failures <- sum(fit1b$cpo$failure > 0, na.rm = TRUE)
cat("CPO failures:", n_failures, "of", nrow(dp), "\n")
lcpo <- -mean(log(fit1b$cpo$cpo), na.rm = TRUE)
cat("LCPO (mean -log CPO):", lcpo, "\n")

fit1 <- readRDS(file.path(cfg$data_dir, "fit_model1_truncnb.rds"))
cat("\n**** Model 1 vs Model 1b ****\n")
cat(sprintf("%-10s %12s %12s\n", "", "Model 1", "Model 1b"))
cat(sprintf("%-10s %12.1f %12.1f\n", "WAIC", fit1$waic$waic, fit1b$waic$waic))
cat(sprintf("%-10s %12.1f %12.1f\n", "DIC",  fit1$dic$dic,   fit1b$dic$dic))
cat(sprintf("%-10s %12.4f %12.4f\n", "LCPO",
            -mean(log(fit1$cpo$cpo), na.rm = TRUE),
            -mean(log(fit1b$cpo$cpo), na.rm = TRUE)))

#-------------------------------SAVED
saveRDS(fit1b, file.path(cfg$out_dir, "fit_model1b_truncnb.rds"))
cat("SAVED")
