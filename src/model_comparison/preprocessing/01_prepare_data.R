library(Matrix)

## ---- CONFIG: edit to match your files ------------------------------
cfg <- list(
  data_path = "data/interim/crime_with_population.csv",
  adj_path = "data/interim/contiguity_matrix.csv",
  col_mun = "CVEGEO",
  col_year = "year",
  col_count = "crime_count",
  col_logpop = "log_pop",
  out_dir = "data/processed/model_comparisson/truncnb"
)
dir.create(cfg$out_dir, recursive = TRUE, showWarnings = FALSE)

# 5-digit municipal codes with leading zeros kept (e.g. "06009")
pad5 <- function(x) formatC(as.integer(x), width = 5, flag = "0")

## ---- 1. Adjacency ---------------------------------------------------
read_adjacency <- function(path) {
  raw <- read.csv(path, colClasses = "character", check.names = FALSE)
  if (ncol(raw) == 2) {                       # edge list
    ids <- sort(unique(pad5(c(raw[[1]], raw[[2]]))))
    W <- sparseMatrix(i = match(pad5(raw[[1]]), ids),
                      j = match(pad5(raw[[2]]), ids),
                      x = 1, dims = c(length(ids), length(ids)))
  } else {                                     # square matrix
    if (ncol(raw) == nrow(raw) + 1) {          # ids in first column
      ids <- pad5(raw[[1]]); raw <- raw[, -1, drop = FALSE]
      stopifnot(identical(pad5(names(raw)), ids))
    } else if (ncol(raw) == nrow(raw)) {       # ids only as headers
      ids <- pad5(names(raw))
    } else {
      stop("Unrecognised adjacency layout: ", nrow(raw), " x ", ncol(raw))
    }
    W <- Matrix(as.matrix(as.data.frame(lapply(raw, as.numeric))), sparse = TRUE)
  }
  W <- 1 * (W != 0)
  diag(W) <- 0
  W <- drop0(W)
  list(W = W, ids = ids)
}

adj <- read_adjacency(cfg$adj_path)
stopifnot(!anyDuplicated(adj$ids))
if (!isSymmetric(adj$W)) stop("Adjacency matrix is not symmetric")
n_islands <- sum(rowSums(adj$W) == 0)
if (n_islands > 0) stop(n_islands, " municipalities have no neighbours")

## ---- 2. Data --------------------------------------------------------
dat <- read.csv(cfg$data_path, check.names = FALSE,
                colClasses = setNames("character", cfg$col_mun))
d <- data.frame(
  mun_id = pad5(dat[[cfg$col_mun]]),
  year   = as.integer(dat[[cfg$col_year]]),
  y      = as.integer(dat[[cfg$col_count]]),
  E      = exp(suppressWarnings(as.numeric(dat[[cfg$col_logpop]])))
)

# ID, year and count must be complete everywhere
stopifnot(!anyNA(d[, c("mun_id", "year", "y")]))
if (anyDuplicated(d[, c("mun_id", "year")])) stop("Duplicate municipality-year rows")

na_pop <- is.na(d$E)
no_pop_ids <- sort(unique(d$mun_id[na_pop]))
cat("Municipalities with no population record:", length(no_pop_ids), "\n")
cat("  ", paste(no_pop_ids, collapse = ", "), "\n")
cat("Rows excluded from the truncated NB fit as a result:", sum(na_pop), "\n")
cat("  of which positive-count rows lost:", sum(na_pop & d$y >= 1), "\n")

unknown <- setdiff(unique(d$mun_id), adj$ids)
if (length(unknown) > 0) stop(length(unknown), " municipalities in data are missing from the graph")

# Indices are built on the FULL data (including no-population rows) so the
# graph and the later occurrence-part model can still include them
d$mun_idx  <- match(d$mun_id, adj$ids)
d$year_idx <- d$year - min(d$year) + 1L

# Flag for downstream use, rather than dropping from `d` itself
d$has_pop <- !na_pop

## ---- 3. Positive-only subset ---------------------------------------
dp <- d[d$y >= 1 & d$has_pop, ]
dp <- dp[order(dp$mun_idx, dp$year_idx), ]

no_pos <- setdiff(seq_along(adj$ids), unique(dp$mun_idx))

cat("Rows total:", nrow(d), "| positive:", nrow(dp),
    sprintf("(%.1f%% zeros dropped)\n", 100 * (1 - nrow(dp) / nrow(d))))
cat("Municipalities in graph:", length(adj$ids),
    "| with no positive year:", length(no_pos), "\n")
cat("Years:", min(d$year), "-", max(d$year), "(year_idx 1 -", max(d$year_idx), ")\n")
cat("y range (positives):", range(dp$y), "\n")
cat("E range:", signif(range(dp$E), 4), "\n")

## ---- 4. Save --------------------------------------------------------
saveRDS(dp,    file.path(cfg$out_dir, "truncnb_positive.rds"))
saveRDS(adj$W, file.path(cfg$out_dir, "adj_matrix.rds"))
write.csv(data.frame(mun_idx = seq_along(adj$ids), mun_id = adj$ids),
          file.path(cfg$out_dir, "mun_index.csv"), row.names = FALSE)
cat("Saved to", cfg$out_dir, "\n")