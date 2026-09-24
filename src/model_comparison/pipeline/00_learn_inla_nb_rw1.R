library(INLA)
library(here)
library(dplyr)
library(readr)

panel <- read_csv(here("data", "interim", "crime_with_population.csv"), locale = locale(encoding = "latin1"))
adj <- read_csv(here("data", "interim", "contiguity_matrix.csv"), locale = locale(encoding = "latin1"))

dim(panel)
names(panel)
str(panel)

sum(is.na(panel$crime_count))
sum(panel$crime_count < 0, na.rm = TRUE)
sum(panel$crime_count != round(panel$crime_count), na.rm = TRUE)

sum(duplicated(panel[c("CVEGEO", "year")]))

table(panel$year)

panel <- panel |>
  mutate(
    municipality_id = sprintf("%05d", as.integer(CVEGEO)),
    year = as.integer(year)
    )

head(panel[c("CVEGEO", "municipality_id")])

panel |>
  filter(municipality_id == "01001") |>
  select(year, state, municipality, population)

panel |>
  group_by(year) |>
  summarise(
    min_population = min(population, na.rm = TRUE),
    median_population = median(population, na.rm = TRUE),
    max_population = max(population, na.rm = TRUE)
  )

panel_model <- panel |>
  filter(
    !is.na(population),
    population > 0
  )

panel_model <- panel_model |>
  mutate(
    crime_count = as.integer(crime_count),
    year_index = match(year, sort(unique(year))),
    log_population = log(population)
  ) |> 
  arrange(year_index, municipality_id)

panel_model |> distinct(year, year_index) |>
  arrange(year_index)

c(
  original_rows = nrow(panel),
  analytical_rows = nrow(panel_model),
  excluded_rows = nrow(panel) - nrow(panel_model)
)

formula_nb0 <- crime_count ~ 1 + offset(log_population)

fit_nb0 <- inla(
  formula_nb0,
  family = "nbinomial",
  data = panel_model,
  control.predictor = list(compute = TRUE),
  control.compute = list(
    dic = TRUE,
    waic = TRUE,
    cpo = TRUE
  )
)

fit_nb0$summary.fixed
fit_nb0$summary.hyperpar

fit_nb0$waic$waic
fit_nb0$dic$dic

exp(fit_nb0$summary.fixed["(Intercept", "mean"]) * 100000

exp(fit_nb0$summary.fixed["(Intercept)", c("0.025quant", "0.975quant")]) * 100000

sum(fit_nb0$cpo$failure != 0)

prior_rw1 <- list(
  prec = list(
    prior = "pc.prec",
    param = c(1, 0.01)
  )
  )

formula_nb_rw1 <- crime_count ~ 
  1 + 
  offset(log_population) +
  f(
    year_index,
    model = "rw1",
    constr = TRUE,
    scale.model = TRUE,
    hyper = prior_rw1
  )

formula_nb_rw1

fit_nb_rw1 <- inla(
  formula_nb_rw1,
  family = "nbinomial",
  data = panel_model,
  control.predictor = list(
    copmute = TRUE
  ),
  control.compute = list(
    dic = TRUE,
    waic = TRUE,
    cpo = TRUE,
    config = TRUE
  )
)

fit_nb_rw1$ok

fit_nb_rw1$summary.fixed
fit_nb_rw1$summary.hyperpar
fit_nb_rw1$summary.random$year_index

fit_nb_rw1$waic$waic
fit_nb_rw1$dic$dic
sum(fit_nb_rw1$cpo$failure != 0)

year_effects <- fit_nb_rw1$summary.random$year_index |>
  mutate(
    year = sort(unique(panel_model$year)),
    rate_ratio = exp(mean),
    rr_lower = exp(`0.025quant`),
    rr_upper = exp(`0.975quant`)
  ) |>
  select(year, mean, `0.025quant`, `0.975quant`,
         rate_ratio, rr_lower, rr_upper)

year_effects

