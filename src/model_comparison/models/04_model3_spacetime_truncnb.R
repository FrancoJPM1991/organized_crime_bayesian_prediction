library(INLA)

cfg <- list(
  data_dir = "data/processed/model_comparisson/truncnb",
  out_dir  = "data/processed/model_comparisson/truncnb"
)

dp <- readRDS(file.path(cfg$data_dir, "truncnb_positive.rds"))
dp$year_rw <- dp$year_idx

W <- readRDS(file.path(cfg$data_dir, "adj_matrix.rds"))
g <- inla.read.graph(as.matrix(W))
n_area <- nrow(W)

## Unique index per area-year cell for the Type I interaction
dp$id_st <- (dp$year_idx - 1) * n_area + dp$mun_idx

## ---- Model 3 (Type I): Model 2 + unstructured space-time interaction --
formula3a <- y ~ 1 + year_idx + f(year_rw, model = "rw1") +
  f(mun_idx, model = "bym2", graph = g,
    scale.model = TRUE, constr = TRUE,
    hyper = list(
      phi  = list(prior = "pc", param = c(0.5, 0.5)),
      prec = list(prior = "pc.prec", param = c(1, 0.01))
    )) +
  f(id_st, model = "iid",
    hyper = list(prec = list(prior = "pc.prec", param = c(1, 0.01))))

fit3a <- inla(
  formula3a,
  family = "zeroinflatednbinomial0",
  data = dp,
  E = E,
  control.family = list(hyper = list(
    theta2 = list(initial = -20, fixed = TRUE)
  )),
  control.compute = list(dic = TRUE, waic = TRUE, cpo = TRUE, config = TRUE),
  control.predictor = list(compute = TRUE)
)

## ---- Diagnostics -------------------------------------------------------
cat("\n=== Fixed effects ===\n")
print(fit3a$summary.fixed[, c("mean", "sd", "0.025quant", "0.975quant")])

cat("\n=== Hyperparameters ===\n")
print(fit3a$summary.hyperpar[, c("mean", "sd")])
# phi for mun_idx should stay close to Model 2's 0.789 if the main
# spatial effect wasn't disturbed this time

cat("\n=== Interaction term spread ===\n")
print(summary(fit3a$summary.random$id_st$mean))
print(range(fit3a$summary.random$id_st$mean))

cat("\n=== Fit ===\n")
cat("WAIC:", fit3a$waic$waic, "| DIC:", fit3a$dic$dic, "\n")

n_failures <- sum(fit3a$cpo$failure > 0, na.rm = TRUE)
cat("CPO failures:", n_failures, "of", nrow(dp), "\n")
lcpo <- -mean(log(fit3a$cpo$cpo), na.rm = TRUE)
cat("LCPO (mean -log CPO):", lcpo, "\n")

## ---- Comparison table: Model 1 / 1b / 2 / 3-TypeI ------------------------
fit1  <- readRDS(file.path(cfg$data_dir, "fit_model1_truncnb.rds"))
fit1b <- readRDS(file.path(cfg$data_dir, "fit_model1b_truncnb.rds"))
fit2  <- readRDS(file.path(cfg$data_dir, "fit_model2_bym2_truncnb.rds"))

cat("\n=== Model 1 vs 1b vs 2 vs 3-TypeI ===\n")
cat(sprintf("%-8s %10s %10s %10s %10s\n", "", "Model1", "Model1b", "Model2", "Model3a"))
cat(sprintf("%-8s %10.1f %10.1f %10.1f %10.1f\n", "WAIC",
            fit1$waic$waic, fit1b$waic$waic, fit2$waic$waic, fit3a$waic$waic))
cat(sprintf("%-8s %10.1f %10.1f %10.1f %10.1f\n", "DIC",
            fit1$dic$dic, fit1b$dic$dic, fit2$dic$dic, fit3a$dic$dic))
cat(sprintf("%-8s %10.4f %10.4f %10.4f %10.4f\n", "LCPO",
            -mean(log(fit1$cpo$cpo),  na.rm = TRUE),
            -mean(log(fit1b$cpo$cpo), na.rm = TRUE),
            -mean(log(fit2$cpo$cpo),  na.rm = TRUE),
            -mean(log(fit3a$cpo$cpo), na.rm = TRUE)))

## ---- Save ----------------------------------------------------------------
saveRDS(fit3a, file.path(cfg$out_dir, "fit_model3a_typeI_truncnb.rds"))
cat("Saved to", file.path(cfg$out_dir, "fit_model3a_typeI_truncnb.rds"), "\n")