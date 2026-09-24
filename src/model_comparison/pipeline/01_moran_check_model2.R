library(INLA)
library(spdep)
library(Matrix)

cfg <- list(
  data_dir = "data/processed/model_comparisson/truncnb"
)

dp   <- readRDS(file.path(cfg$data_dir, "truncnb_positive.rds"))
fit2 <- readRDS(file.path(cfg$data_dir, "fit_model2_bym2_truncnb.rds"))
W    <- readRDS(file.path(cfg$data_dir, "adj_matrix.rds"))
size <- fit2$summary.hyperpar["size for nbinomial_0 zero-inflated observations", "mean"]


mu <- fit2$summary.fitted.values$mean
var_nb <- mu + mu^2 / size
dp$resid <- (dp$y - mu) / sqrt(var_nb)

cat("Residual summary:\n"); print(summary(dp$resid))

mun_resid <- tapply(dp$resid, dp$mun_idx, mean)
mun_ids   <- as.integer(names(mun_resid))
cat("\nMunicipalities with residuals (i.e. >=1 positive year):", length(mun_ids),
    "of", nrow(W), "in the graph\n")


W_sub <- W[mun_ids, mun_ids]

has_nb <- Matrix::rowSums(W_sub) > 0
if (any(!has_nb)) {
  cat("Dropping", sum(!has_nb), "municipalities isolated after subsetting\n")
  mun_resid <- mun_resid[has_nb]
  mun_ids   <- mun_ids[has_nb]
  W_sub     <- W_sub[has_nb, has_nb]
}

nb    <- mat2listw(as.matrix(W_sub), style = "W")
moran <- moran.test(as.numeric(mun_resid), nb, zero.policy = TRUE)

cat("\n=== Moran's I on Model 2 residuals ===\n")
print(moran)