## Same CONFIG as step1_prepare_data.R
cfg <- list(
  data_path  = "data/interim/crime_with_population.csv",
  col_mun    = "CVEGEO",
  col_year   = "year",
  col_count  = "crime_count",
  col_logpop = "log_pop"
)

dat <- read.csv(cfg$data_path, check.names = FALSE, colClasses = "character")

cat("Rows:", nrow(dat), "\n")
cat("Column names in file:\n"); print(names(dat))

cols <- c(cfg$col_mun, cfg$col_year, cfg$col_count, cfg$col_logpop)
missing_cols <- setdiff(cols, names(dat))
if (length(missing_cols) > 0) stop("Not in file: ", paste(missing_cols, collapse = ", "))

for (cn in cols) {
  raw <- dat[[cn]]
  num <- suppressWarnings(as.numeric(raw))
  raw_blank <- is.na(raw) | trimws(raw) == "" | toupper(trimws(raw)) %in% c("NA", "NAN", "NULL")
  bad_conv  <- !raw_blank & is.na(num)
  cat("\n---", cn, "---\n")
  cat("Blank / NA in raw:", sum(raw_blank), "\n")
  if (cn != cfg$col_mun) {
    cat("Non-numeric strings:", sum(bad_conv), "\n")
    if (sum(bad_conv) > 0) print(head(unique(raw[bad_conv]), 10))
    cat("Non-integer values:", sum(!is.na(num) & num != round(num)), "\n")
    cat("Negative values:", sum(!is.na(num) & num < 0), "\n")
  } else {
    cat("Distinct code lengths:\n"); print(table(nchar(raw)))
  }
}

# Rows with any problem in the four columns, and what they have in common
num_cols <- c(cfg$col_year, cfg$col_count, cfg$col_logpop)
bad_row <- Reduce(`|`, lapply(num_cols, function(cn)
  is.na(suppressWarnings(as.numeric(dat[[cn]])))))
bad_row <- bad_row | is.na(dat[[cfg$col_mun]]) | trimws(dat[[cfg$col_mun]]) == ""

cat("\nRows with at least one problem:", sum(bad_row), "\n")
if (sum(bad_row) > 0) {
  print(head(dat[bad_row, cols], 15))
  cat("\nBy year:\n");         print(table(dat[[cfg$col_year]][bad_row], useNA = "ifany"))
  cat("\nDistinct municipalities affected:",
      length(unique(dat[[cfg$col_mun]][bad_row])), "\n")
}