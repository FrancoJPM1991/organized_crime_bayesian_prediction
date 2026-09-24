library(INLA)

cfg <- list(
  data_dir = "data/processed/model_comparisson/truncnb",
  out_dir = "data/processed/model_comparisson/truncnb"
)

dp <- readRDS(file.path(cfg$data_dir, "truncnb_positive.rds"))
dp$year_rw <- dp$year_idx

W <- readRDS(file.path(cfg$data_dir, "adj_matrix.rds"))
g <- inla.read.graph(as.matrix(W))
cat("Graph nodes:", g$n, "| municipalitites in data:")

formula2 <- y ~ 1 + year_idx + f(year_rw, model = "rw1") + 
  f(mun_idx, model = "bym2", graph = g,
    scale.model = TRUE, constr = TRUE,
    hyper = list(
      phi = list(prior = "pc", param = c(0.5, 0.5)),
      prec = list(prior = "pc.prec", param = c(1, 0.01))
    ))


fit2 <- inla(
  formula2,
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
print(fit2$summary.fixed[, c("mean", "sd", "0.025quant", "0.975quant")])

cat("\n**** Hyperparameters ****\n")
print(fit2$summary.hyperpar[, c("mean", "sd")])

cat("\n**** Fit ****\n")
cat("WAIC:", fit2$waic$waic, "|DIC:", fit2$dic$dic, "\n")

n_failures <- sum(fit2$cpo$failure > 0, na.rm = TRUE)
cat("CPO failures:", n_failures, "of", nrow(dp), "\n")
lcpo <- -mean(log(fit2$cpo$cpo), na.rm = TRUE)
cat("LCPO (mean -log CPO):", lcpo, "\n")

#------------------------------BENCHMARK

fit1  <- readRDS(file.path(cfg$data_dir, "fit_model1_truncnb.rds"))
fit1b <- readRDS(file.path(cfg$data_dir, "fit_model1b_truncnb.rds"))

cat("\n=== Model 1 vs 1b vs 2 ===\n")
cat(sprintf("%-8s %10s %10s %10s\n", "", "Model1", "Model1b", "Model2"))
cat(sprintf("%-8s %10.1f %10.1f %10.1f\n", "WAIC",
            fit1$waic$waic, fit1b$waic$waic, fit2$waic$waic))
cat(sprintf("%-8s %10.1f %10.1f %10.1f\n", "DIC",
            fit1$dic$dic, fit1b$dic$dic, fit2$dic$dic))
cat(sprintf("%-8s %10.4f %10.4f %10.4f\n", "LCPO",
            -mean(log(fit1$cpo$cpo),  na.rm = TRUE),
            -mean(log(fit1b$cpo$cpo), na.rm = TRUE),
            -mean(log(fit2$cpo$cpo),  na.rm = TRUE)))

#-------------------------------SAVE
saveRDS(fit2, file.path(cfg$out_dir, "fit_model2_bym2_truncnb.rds"))
cat("SAVED")
