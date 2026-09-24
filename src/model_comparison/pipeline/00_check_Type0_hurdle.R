library(INLA)
set.seed(42)

n         <- 20000
b0        <- 1.0
b1        <- 0.5
size_true <- 2
pi0_true  <- 0.40   # P(y = 0), constant

x  <- rnorm(n)
mu <- exp(b0 + b1 * x)

# Zero-truncated NB draws: redraw any zeros until all are positive
y_pos <- rnbinom(n, mu = mu, size = size_true)
while (any(y_pos == 0)) {
  idx <- which(y_pos == 0)
  y_pos[idx] <- rnbinom(length(idx), mu = mu[idx], size = size_true)
}

# Hurdle: zero with prob pi0, otherwise the truncated draw
is_zero <- rbinom(n, 1, pi0_true) == 1
y       <- ifelse(is_zero, 0L, y_pos)
df      <- data.frame(y = y, x = x)

cat("Truth: b0 =", b0, "| b1 =", b1,
    "| size =", size_true, "| P(y=0) =", pi0_true, "\n\n")

# Fit 1: candidate hurdle family on ALL rows
fit_h <- inla(y ~ x, family = "zeroinflatednbinomial0", data = df)
cat("=== zeroinflatednbinomial0, full data ===\n")
print(fit_h$summary.fixed[, c("mean", "sd")])
print(fit_h$summary.hyperpar[, c("mean", "sd")])

# Fit 2 (reference): plain NB on positive rows only, ignoring truncation
fit_n <- inla(y ~ x, family = "nbinomial", data = df[df$y > 0, ])
cat("\n=== plain nbinomial, positives only (ignores truncation) ===\n")
print(fit_n$summary.fixed[, c("mean", "sd")])
print(fit_n$summary.hyperpar[, c("mean", "sd")])

# The doc page that defines the family
inla.doc("zeroinflated")