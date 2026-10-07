# Every example defines the generating assumptions as well as the analysis.
# These are templates, not validated recommendations for a particular study.
library(regsimsize)

# Treatment begins at time 2 for a randomized subgroup. The time-dependent
# exposure enters the hazard only after treatment begins. n means individuals.
time_varying_design <- function(hazard_ratio = .65) {
  simulation_design(
    generate = function(n) {
      age_z <- rnorm(n)
      assigned <- rbinom(n, 1, .5)
      r0 <- .08 * exp(.2 * age_z)
      e <- rexp(n)
      event <- ifelse(e <= 2 * r0, e / r0,
                      2 + (e - 2 * r0) / (r0 * hazard_ratio^assigned))
      end <- pmin(event, 5)
      first <- data.frame(id = seq_len(n), start = 0, stop = pmin(end, 2),
                           status = as.integer(event <= 2 & event <= 5),
                           treated = 0, age_z = age_z)
      keep <- end > 2
      second <- data.frame(id = which(keep), start = rep(2, sum(keep)),
                            stop = end[keep], status = as.integer(event[keep] <= 5),
                            treated = assigned[keep], age_z = age_z[keep])
      rbind(first, second)
    },
    fit = function(data) survival::coxph(
      survival::Surv(start, stop, status) ~ treated + age_z,
      data = data, cluster = id),
    test = wald_test("treated"),
    diagnostics = function(data) c(events = sum(data$status),
      event_fraction = sum(data$status) / length(unique(data$id))),
    label = "Cox regression with an exposure beginning during follow-up"
  )
}

# Recurrent events with a shared individual event-rate multiplier.
# n means individuals. Robust covariance accounts for within-person dependence.
recurrent_design <- function(hazard_ratio = .7) {
  simulation_design(
    generate = function(n) {
      treatment <- rbinom(n, 1, .5)
      frailty <- rgamma(n, shape = 2, rate = 2)
      pieces <- lapply(seq_len(n), function(i) {
        rate <- .2 * frailty[i] * hazard_ratio^treatment[i]
        events <- sort(runif(rpois(1, 5 * rate), 0, 5))
        data.frame(id = i, treatment = treatment[i],
                    start = c(0, events), stop = c(events, 5),
                    status = c(rep(1L, length(events)), 0L))
      })
      do.call(rbind, pieces)
    },
    fit = function(data) survival::coxph(
      survival::Surv(start, stop, status) ~ treatment, data = data, cluster = id),
    test = wald_test("treatment"),
    diagnostics = function(data) c(events = sum(data$status),
      event_fraction = length(unique(data$id[data$status == 1])) / length(unique(data$id))),
    label = "Recurrent-event Cox model with robust inference"
  )
}

# Clustered survival with gamma frailty. n means clusters, with four members each.
# The custom test explicitly uses the penalized-fit summary's treatment test;
# routine wald_test rejects penalized Cox fits to avoid choosing this implicitly.
frailty_design <- function(hazard_ratio = .7) {
  simulation_design(
    generate = function(n) {
      id <- rep(seq_len(n), each = 4)
      treatment <- rep(rbinom(n, 1, .5), each = 4)
      u <- rep(rgamma(n, shape = 2, rate = 2), each = 4)
      time <- rexp(length(id), .15 * u * hazard_ratio^treatment)
      data.frame(id = id, treatment = treatment, time = pmin(time, 5),
                  status = as.integer(time <= 5))
    },
    fit = function(data) {
      # Bind the special locally so survival recognizes the formula term.
      frailty <- survival::frailty
      survival::coxph(survival::Surv(time, status) ~ treatment + frailty(id), data = data)
    },
    test = function(fit, data) {
      tab <- summary(fit)$coefficients
      p <- tab["treatment", "p"]
      if (!is.finite(p)) stop("Invalid frailty-model treatment test.")
      p
    },
    diagnostics = function(data) c(events = sum(data$status), event_fraction = mean(data$status)),
    label = "Shared gamma-frailty Cox model; sample size counts clusters"
  )
}

# Repeated Gaussian outcomes with random intercepts. n means participants.
# Treatment is assigned between participants, not independently by visit.
mixed_design <- function(effect = .4) {
  if (!requireNamespace("nlme", quietly = TRUE)) stop("Install nlme to run this example.")
  simulation_design(
    generate = function(n) {
      id <- factor(rep(seq_len(n), each = 3))
      treatment <- rep(rbinom(n, 1, .5), each = 3)
      visit <- rep(0:2, n)
      u <- rep(rnorm(n, sd = .8), each = 3)
      data.frame(id = id, treatment = treatment, visit = visit,
                  y = effect * treatment + .1 * visit + u + rnorm(3 * n))
    },
    fit = function(data) nlme::lme(y ~ treatment + visit, random = ~ 1 | id, data = data),
    test = function(fit, data) summary(fit)$tTable["treatment", "p-value"],
    label = "Random-intercept linear model; sample size counts participants"
  )
}

# Start with small smoke runs, then verify the null and relevant alternatives
# using a much larger number of replicates for the planned study.
# power_curve(time_varying_design(), c(300, 600), nsim = 100, seed = 3)
# power_curve(recurrent_design(), c(200, 400), nsim = 100, seed = 4)
# power_curve(frailty_design(), c(60, 100), nsim = 100, seed = 5)
# power_curve(mixed_design(), c(60, 100), nsim = 100, seed = 6)
