library(INLA)

cat("INLA version:", as.character(packageVersion("INLA")), "\n\n")

lik <- inla.models()$likelihood

pattern <- "nbinomial|seroinflated|seroinflated|hurdle|trunc"
cand <- names(lik)[grepl(pattern, names(lik), ignore.case = TRUE)]

cat("Candidate families:\n")
print(cand)

for (f in cand) {
  cat("\n=====", f, "=====\n")
  cat("Doc:", lik[[f]]$doc, "\n")
  cat("Hyperparameters:", paste(names(lik[[f]]$hyper), collapse = ", "), "\n")
}