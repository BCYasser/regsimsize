library(regsimsize)

checks <- 0L
check <- function(value, label) {
  if (!isTRUE(value)) stop("FAILED: ", label)
  checks <<- checks + 1L
}
near <- function(a, b, tol = 1e-8) isTRUE(all.equal(unname(a), unname(b), tolerance = tol))
errors <- function(expr) inherits(tryCatch(force(expr), error = identity), "error")
quiet <- function(expr) suppressWarnings(force(expr))

set.seed(19)
d <- data.frame(x = rnorm(120), z = rnorm(120), g = factor(rep(letters[1:3], 40)))
d$y <- 0.2 + 0.4 * d$x + rnorm(120)
lmfit <- lm(y ~ x + z + g, d)
check(near(wald_test("x")(lmfit, d)$p.value, coef(summary(lmfit))["x", "Pr(>|t|)"]),
      "linear single coefficient agrees with summary.lm")
reduced <- lm(y ~ z, d)
joint <- wald_test(c("x", "gb", "gc"))(lmfit, d)$p.value
check(near(joint, anova(reduced, lmfit)$`Pr(>F)`[2]), "joint Wald agrees with nested linear F test")
check(near(wald_test("x", alternative = "greater")(lmfit, d)$p.value,
           pt(coef(summary(lmfit))["x", "t value"], df.residual(lmfit), lower.tail = FALSE)),
      "directional t test")
check(errors(wald_test(c("x", "z"), alternative = "less")), "joint directional test rejected")
check(errors(wald_test("absent")(lmfit, d)), "unknown target rejected")
check(errors(wald_test("x", vcov = vcov)), "custom covariance needs explicit reference df")
check(errors(wald_test("x", vcov = function(f) -vcov(f), df = Inf)(lmfit, d)),
      "invalid covariance rejected")

d$b <- rbinom(nrow(d), 1, plogis(-0.5 + 0.6 * d$x))
gf <- glm(b ~ x + z, d, family = binomial())
check(near(wald_test("x")(gf, d)$p.value, coef(summary(gf))["x", "Pr(>|z|)"]),
      "logistic Wald agrees with summary.glm")
check(near(lrt_test(b ~ z)(gf, d)$p.value, anova(glm(b ~ z, d, family = binomial()), gf,
                                             test = "LRT")$`Pr(>Chi)`[2]), "logistic LRT agrees with anova")
check(errors(lrt_test(b ~ g)(gf, d)), "nonnested models rejected")
qf <- glm(b ~ x + z, d, family = quasibinomial())
check(near(wald_test("x")(qf, d)$p.value, coef(summary(qf))["x", "Pr(>|t|)"]), "quasi t reference")
check(errors(lrt_test(b ~ z)(qf, d)), "quasi LRT rejected")

gen <- function(n) data.frame(x = rnorm(n), group = factor(sample(c("a", "b", "c"), n, TRUE),
                                                         levels = c("a", "b", "c")), exposure = runif(n, 1, 2))
pilot <- gen(200)
f <- y ~ x * group + I(x^2) + offset(log(exposure))
beta <- model_coefficients(f, pilot)
beta["(Intercept)"] <- -1
beta["x"] <- 0.3
gd <- glm_design(f, beta, gen, wald_test("x"))
draw <- simulate_data(gd, 500, 3)
check(nrow(draw) == 500 && all(draw$y %in% 0:1), "factors interactions transformations and offset")
check(errors(simulate_data(glm_design(f, beta[-1], gen, wald_test("x")), 100)), "missing coefficient rejected")
check(errors(simulate_data(glm_design(f, c(beta, extra = 0), gen, wald_test("x")), 100)),
      "extra coefficient rejected")

one <- function(n) data.frame(x = rnorm(n))
for (link in c("logit", "probit", "cloglog", "cauchit")) {
  dd <- glm_design(y ~ x, c("(Intercept)" = -0.5, x = 0.2), one, wald_test("x"), binomial(link))
  rr <- power_curve(dd, 150, nsim = 4, seed = 123)
  check(all(rr$replicates$status == "ok"), paste("binomial link", link))
}
for (fam in list(poisson(), gaussian(), Gamma("log"), inverse.gaussian("log"))) {
  dd <- glm_design(y ~ x, c("(Intercept)" = 1, x = 0.1), one, wald_test("x"), fam)
  rr <- quiet(power_curve(dd, 300, nsim = 4, seed = 80))
  check(all(rr$replicates$status == "ok"), paste("GLM family", fam$family))
}
check(errors(glm_design(y ~ x, c("(Intercept)" = 0, x = 0), one,
                        wald_test("x"), quasipoisson())), "quasi needs explicit generation")
qdesign <- glm_design(y ~ x, c("(Intercept)" = 1, x = 0.1), one, wald_test("x"),
                     quasipoisson(), response_generator = function(n, mu, data) rnbinom(n, mu = mu, size = 4))
check(all(power_curve(qdesign, 200, nsim = 3)$replicates$status == "ok"), "overdispersed custom generator")
bd <- glm_design(y ~ x, c("(Intercept)" = -1, x = 0.4), one, wald_test("x"), trials = 5)
dd <- simulate_data(bd, 200)
check(is.matrix(dd$y) && all(rowSums(dd$y) == 5), "grouped binomial counts")
br <- power_curve(bd, 200, nsim = 4)
check(all(br$replicates$status == "ok") && near(br$summary$mean_events / 1000,
                                               br$summary$mean_event_fraction), "grouped event fraction denominator")
ref <- one(3000)
b <- c("(Intercept)" = 0, x = 0.7)
b[1] <- calibrate_intercept(y ~ x, b, ref, target = 0.13)
check(abs(mean(plogis(b[1] + b[2] * ref$x)) - 0.13) < 1e-7, "marginal prevalence calibration")

w <- lm_design(y ~ x, c("(Intercept)" = 0, x = 0.2), one, wald_test("x"),
               sigma = function(d) sqrt(1 + d$x^2), fit_args = function(d) list(weights = 1/(1+d$x^2)))
check(all(power_curve(w, 100, nsim = 4)$replicates$status == "ok"), "weighted heteroscedastic linear design")

library(survival)
cd <- cox_design(Surv(time, status) ~ x, c(x = 0.4), one, wald_test("x"), followup = 4)
ds <- simulate_data(cd, 200, 71)
cf <- cd$fit(ds)
check(near(wald_test("x")(cf, ds)$p.value, coef(summary(cf))["x", "Pr(>|z|)"]), "Cox Wald")
check(near(lrt_test(Surv(time, status) ~ 1)(cf, ds)$p.value,
           summary(cf)$logtest["pvalue"]), "Cox LRT with coefficient-free null")
csr <- cox_design(Surv(time, status) ~ x + strata(group), c(x = 0.2), gen,
                  wald_test("x"), lp_formula = ~ x, followup = 5,
                  baseline = weibull_baseline(rate = function(d) ifelse(d$group == "a", 0.1, 0.2)))
check(all(power_curve(csr, 250, nsim = 4)$replicates$status == "ok"), "stratified Cox and stratum-specific baselines")
cr <- coxph(Surv(time, status) ~ x, ds, cluster = rep(1:50, 4))
check(near(wald_test("x")(cr, ds)$p.value, coef(summary(cr))["x", "Pr(>|z|)"]), "robust Cox covariance")
check(errors(lrt_test(Surv(time, status) ~ 1)(cr, ds)), "robust Cox LRT rejected")
check(errors(cox_design(Surv(start, stop, status) ~ x, c(x = .2), one, wald_test("x"))),
      "counting process needs custom generator")
check(errors(cox_design(Surv(time, status) ~ tt(x), c(x=.2), one, wald_test("x"))),
      "time transforms need custom design")
inv <- piecewise_baseline(c(0, 2, 5), c(.1, .3, .05))
check(near(inv(c(0, .1, .2, .5, 1.1, 1.2), data.frame()), c(0, 1, 2, 3, 5, 7)),
      "piecewise inverse cumulative hazard including boundaries")
check(near(weibull_baseline(.2, 2)(c(.2,.8), data.frame()), c(1,2)), "Weibull parameterization")

design <- lm_design(y ~ x, c("(Intercept)" = 0, x = .4), one, wald_test("x"))
set.seed(101)
state <- .Random.seed
kind <- RNGkind()
a <- power_curve(design, c(60, 30, 60), nsim = 7, seed = 902)
check(identical(state, .Random.seed) && identical(kind, RNGkind()), "caller RNG restored")
check(identical(a$replicates, power_curve(design, c(30,60), nsim=7, seed=902)$replicates),
      "repeatable sorted grid")
# Two workers are only requested when explicitly enabled; CRAN tests stay sequential.
if (identical(Sys.getenv("REGSIMSIZE_TEST_PARALLEL"), "true")) {
  par <- power_curve(design, c(30,60), nsim=7, seed=902, workers=2)
  check(identical(a$replicates, par$replicates), "serial/PSOCK equality")
}
check(identical(simulate_data(design, 40, 1), simulate_data(design, 40, 1)), "data generator reproducibility")
check(identical(state, .Random.seed), "simulate_data restores caller RNG")

bad <- simulation_design(function(n) data.frame(x=seq_len(n)),
                         function(d) stop("deliberate failure"), function(f,d) .01)
r <- quiet(power_curve(bad, 10, nsim=5))
check(r$summary$power == 0 && r$summary$failed == 5 && is.na(r$summary$power_successful),
      "failed analyses retained, conditional power undefined")
check(all(r$replicates$stage == "fit") && all(grepl("deliberate", r$replicates$error)), "failure stage captured")
check(is.na(quiet(select_sample_size(r))$n), "no recommendation when all fits fail")
badp <- simulation_design(function(n) data.frame(x=seq_len(n)), identity, function(f,d) c(.01,.02))
check(quiet(power_curve(badp,10,nsim=3))$summary$failed == 3, "multiple p-values rejected")
warn <- simulation_design(function(n) data.frame(x=seq_len(n)),
                          function(d) {warning("test warning");d}, function(f,d) .01)
check(quiet(power_curve(warn,10,nsim=3))$summary$failed == 3, "warning default fails")
record <- power_curve(warn,10,nsim=3,warning_policy="record")
check(record$summary$power == 1 && record$summary$warning_rate == 1, "explicit warning recording")
check(record$summary$lower < 1 && record$summary$upper == 1, "interval remains informative at all successes")
check(mc_replicates(.01,.8) == 6147, "Monte Carlo planning calculation")
check(errors(power_curve(design, 10, nsim=0)), "zero simulations rejected")
check(errors(power_curve(design, c(10,NA))), "missing sample sizes rejected")
check(errors(power_curve(design, 10, alpha=1)), "invalid alpha rejected")
check(errors(select_sample_size(a, max_failure=-.1)), "invalid failure threshold rejected")
check(identical(as.data.frame(a), summary(a)), "data-frame summary")

plot_file <- tempfile(fileext = ".pdf")
grDevices::pdf(file = plot_file)
plot(a)
plot(br)
plot_event_rate(br)
grDevices::dev.off()
unlink(plot_file)
check(TRUE, "plot methods execute")
cat(checks, "checks passed.\n")
