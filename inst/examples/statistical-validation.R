# Run after installing regsimsize. Defaults: 2000 replicates per scenario.
# Rscript statistical-validation.R [replicates] [output_directory]
library(regsimsize)
args <- commandArgs(trailingOnly = TRUE)
nsim <- if (length(args)) as.integer(args[1]) else 2000L
outdir <- if (length(args) > 1) args[2] else file.path(tempdir(), "regsimsize-validation")
stopifnot(is.finite(nsim), nsim >= 100)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

balanced <- function(n) data.frame(treatment = rep(0:1, length.out = n))
linear <- function(effect) lm_design(y ~ treatment,
  c("(Intercept)" = 0, treatment = effect), balanced, wald_test("treatment"))
logistic <- function(effect) glm_design(y ~ treatment,
  c("(Intercept)" = qlogis(.15), treatment = effect), balanced, wald_test("treatment"))
cox <- function(effect) cox_design(survival::Surv(time, status) ~ treatment,
  c(treatment = effect), balanced, wald_test("treatment"),
  baseline = weibull_baseline(.1, 1), followup = 5)
scenarios <- list(
  linear_null = list(design = linear(0), n = 120),
  linear_alternative = list(design = linear(.5), n = 120),
  logistic_null = list(design = logistic(0), n = 600),
  logistic_alternative = list(design = logistic(log(1.7)), n = 600),
  cox_null = list(design = cox(0), n = 300),
  cox_alternative = list(design = cox(log(.7)), n = 600)
)
results <- vector("list", length(scenarios))
names(results) <- names(scenarios)
for (i in seq_along(scenarios)) {
  s <- scenarios[[i]]
  message("Validating ", names(scenarios)[i])
  results[[i]] <- power_curve(s$design, s$n, nsim = nsim, seed = 1200 + i, progress = FALSE)
}
tab <- do.call(rbind, lapply(names(results), function(nm) {
  cbind(scenario = nm, results[[nm]]$summary, row.names = NULL)
}))
tab$benchmark <- NA_real_
tab$benchmark[grepl("_null$", tab$scenario)] <- .05
exact_linear <- power.t.test(n = 60, delta = .5, sd = 1,
                             sig.level = .05, type = "two.sample", strict = TRUE)$power
tab$benchmark[tab$scenario == "linear_alternative"] <- exact_linear
p0 <- .15
p1 <- plogis(qlogis(p0) + log(1.7))
se_log_or <- sqrt(1 / (300*p0*(1-p0)) + 1 / (300*p1*(1-p1)))
z <- log(1.7) / se_log_or
approx_logistic <- pnorm(-qnorm(.975) - z) + pnorm(z - qnorm(.975))
tab$benchmark[tab$scenario == "logistic_alternative"] <- approx_logistic
tab$comparison <- c("nominal type I error", "exact pooled two-sample t power",
                     "nominal type I error", "large-sample binary-logistic approximation",
                     "nominal type I error", "coefficient and event-fraction recovery below")
write.csv(tab, file.path(outdir, "statistical-validation.csv"), row.names = FALSE)

checks <- data.frame(check = character(), observed = numeric(), expected = numeric(),
                     tolerance = numeric(), passed = logical())
record <- function(label, observed, expected, tolerance) {
  checks <<- rbind(checks, data.frame(check=label, observed=observed, expected=expected,
                                    tolerance=tolerance, passed=abs(observed-expected) <= tolerance))
}
for (nm in c("linear_null", "logistic_null", "cox_null")) {
  r <- results[[nm]]$summary
  record(paste(nm, "type I error"), r$power, .05, 4*sqrt(.05*.95/nsim))
  record(paste(nm, "failed analyses"), r$failed, 0, 0)
}
record("linear exact power benchmark", results$linear_alternative$summary$power,
        exact_linear, 4*sqrt(exact_linear*(1-exact_linear)/nsim))
# This approximation is not an exact gold standard; allow finite-sample error.
record("logistic approximate power benchmark", results$logistic_alternative$summary$power,
        approx_logistic, .015 + 4*sqrt(approx_logistic*(1-approx_logistic)/nsim))
coefs <- results$cox_alternative$replicates$estimate
record("Cox log hazard ratio recovery", mean(coefs), log(.7), .01 + 4*sd(coefs)/sqrt(nsim))
expected_events <- .5*(1-exp(-.1*5)) + .5*(1-exp(-.1*.7*5))
record("Cox observed event fraction", results$cox_alternative$summary$mean_event_fraction,
        expected_events, 4*sqrt(expected_events*(1-expected_events)/(600*nsim)))

# Moment checks for less frequently used automatic outcome generators.
constant <- function(n) data.frame(x = rep(0, n))
for (fam in list(gaussian(), Gamma("log"), inverse.gaussian("log"))) {
  beta <- c("(Intercept)" = if (fam$link == "identity") 2 else log(2), x = 0)
  d <- glm_design(y ~ x, beta, constant, wald_test("x"), fam, dispersion = .3)
  y <- simulate_data(d, 100000, seed = 88)$y
  expected_var <- switch(fam$family, gaussian=.3, Gamma=.3*2^2, inverse.gaussian=.3*2^3)
  record(paste(fam$family,"generated mean"), mean(y), 2, .03)
  record(paste(fam$family,"generated variance"), var(y), expected_var, .15*expected_var)
}

surv_design <- cox_design(survival::Surv(time,status) ~ x, c(x=0), constant,
                          wald_test("x"), baseline=weibull_baseline(.1,1.5))
tt <- simulate_data(surv_design, 100000, 76)$time
haz <- .1*tt^1.5
record("Weibull transformed cumulative hazard mean", mean(haz), 1, .02)
record("Weibull transformed cumulative hazard variance", var(haz), 1, .06)

# Illustrative curve analogous in structure to the supplied logistic plot.
covariates <- function(n) data.frame(
  continuous = rnorm(n), category1 = factor(sample(c("A","B"), n, TRUE), levels=c("A","B")),
  category2 = factor(sample(c("low","middle","high"), n, TRUE, c(.5,.3,.2)),
                     levels=c("low","middle","high")))
set.seed(30)
ref <- covariates(50000)
form <- outcome ~ continuous + category1 + category2
beta <- model_coefficients(form, ref)
beta[-1] <- log(c(1.25,1.2,1.4,1.8))
beta[1] <- calibrate_intercept(form,beta,ref,.13)
record("Calibrated reference event probability", mean(plogis(drop(model.matrix(form[-2],ref)%*%beta))), .13, 1e-7)
demo <- glm_design(form,beta,covariates,wald_test("continuous"),
                    label="Illustrative logistic regression")
curve <- power_curve(demo,seq(200,3000,400),nsim=max(100L,as.integer(nsim/4)),seed=709)
write.csv(curve$summary,file.path(outdir,"illustrative-power-curve.csv"),row.names=FALSE)
grDevices::png(file.path(outdir,"illustrative-power-curve.png"),width=1500,height=950,res=180)
par(mar=c(4.2,4.2,2.5,1),las=1,bty="l")
plot(curve,main="Illustrative logistic model: one continuous and two categorical predictors")
grDevices::dev.off()
grDevices::png(file.path(outdir,"illustrative-event-fractions.png"),width=1500,height=950,res=180)
par(mar=c(4.2,4.2,2.5,1),las=1,bty="l")
plot_event_rate(curve)
grDevices::dev.off()

write.csv(checks,file.path(outdir,"validation-checks.csv"),row.names=FALSE)
saveRDS(list(results=results,illustrative_curve=curve,checks=checks),file.path(outdir,"validation-results.rds"))
capture.output(sessionInfo(),file=file.path(outdir,"session-info.txt"))
print(tab[,c("scenario","power","lower","upper","benchmark","failed")],row.names=FALSE)
print(checks,row.names=FALSE)
if (!all(checks$passed)) stop("A statistical validation check failed; inspect the saved outputs.")
cat("All statistical checks passed.\n")
