# All numerical assumptions below are illustrative.
# Small demonstration nsim values are not enough for final study planning.
library(regsimsize)

covariates <- function(n) {
  data.frame(age_z = rnorm(n),
             sex = factor(sample(c("female", "male"), n, TRUE, c(.6, .4)),
                          levels = c("female", "male")),
             group = factor(sample(c("A", "B", "C"), n, TRUE, c(.5, .3, .2)),
                            levels = c("A", "B", "C")))
}
formula <- outcome ~ age_z + sex + group
set.seed(17)
reference <- covariates(50000)
beta <- model_coefficients(formula, reference)
beta[c("age_z", "sexmale", "groupB", "groupC")] <- log(c(1.25, 1.2, 1.4, 1.8))
beta["(Intercept)"] <- calibrate_intercept(formula, beta, reference, target = .13)

logistic <- glm_design(formula, beta, covariates, wald_test("age_z"),
                       label = "Illustrative logistic study: one continuous and two categorical predictors")
logistic_power <- power_curve(logistic, seq(200, 3000, 400), nsim = 20, seed = 501)
print(logistic_power)
plot(logistic_power, main = "Illustrative logistic study")
plot_event_rate(logistic_power, n = 3000)
select_sample_size(logistic_power)

linear <- lm_design(outcome ~ treatment + age_z,
  c("(Intercept)" = 0, treatment = .5, age_z = .2),
  function(n) data.frame(treatment = rep(0:1, length.out = n), age_z = rnorm(n)),
  wald_test("treatment"), sigma = 1)
linear_power <- power_curve(linear, c(60, 100, 160, 240), nsim = 20, seed = 502)
plot(linear_power)

cox <- cox_design(survival::Surv(time, status) ~ treatment + age_z,
  c(treatment = log(.7), age_z = log(1.2)),
  function(n) data.frame(treatment = rbinom(n, 1, .5), age_z = rnorm(n)),
  wald_test("treatment"), baseline = weibull_baseline(rate = .1, shape = 1.2),
  censoring = function(n, data) rexp(n, rate = .03), followup = 5)
cox_power <- power_curve(cox, c(200, 400, 600, 800), nsim = 20, seed = 503)
plot(cox_power)

# Save a complete result, including assumptions, diagnostics and session information:
# saveRDS(logistic_power, "logistic-planning-result.rds")
# write.csv(summary(logistic_power), "logistic-power.csv", row.names = FALSE)
# grDevices::pdf("logistic-power.pdf", width = 7, height = 5)
# plot(logistic_power, main = "Illustrative logistic study")
# grDevices::dev.off()
