library(INLA)
set.seed(42)

# Known truth
n         <- 20000
b0        <- -8      # log-rate per unit of E
b1        <- 0.5
size_true <- 2

x  <- rnorm(n)
E  <- sample(c(2000, 10000, 50000, 200000), n, replace = TRUE) 
mu <- E * exp(b0 + b1 * x)   

# Zero-truncated NB draws: redraw any zeros until all are positive
y <- rnbinom(n, mu = mu, size = size_true)
while (any(y == 0)) {
  idx <- which(y == 0)
  y[idx] <- rnbinom(length(idx), mu = mu[idx], size = size_true)
}
df <- data.frame(y = y, x = x, E = E)

cat("Truth: b0 =", b0, "| b1 =", b1, "| size =", size_true, "\n\n")

# Fit 1: type-0 family on positives, zero-probability fixed near 0
fit_t <- inla(
  y ~ x, family = "zeroinflatednbinomial0", data = df, E = E,
  control.family = list(hyper = list(
    theta2 = list(initial = -20, fixed = TRUE)
  ))
)
cat("=== zeroinflatednbinomial0, positives only, p fixed ===\n")
print(fit_t$summary.fixed[, c("mean", "sd")])
print(fit_t$summary.hyperpar[, c("mean", "sd")])

# Fit 2 (contrast): plain NB on the same data, ignoring truncation
fit_n <- inla(y ~ x, family = "nbinomial", data = df, E = E)
cat("\n=== plain nbinomial, same data (ignores truncation) ===\n")
print(fit_n$summary.fixed[, c("mean", "sd")])
print(fit_n$summary.hyperpar[, c("mean", "sd")])