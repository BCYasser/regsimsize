.rinvgaussian <- function(n, mu, dispersion) {
  # Stable form of the normal-square mixture algorithm; lambda = 1 / phi.
  a <- mu * stats::rnorm(n)^2 * dispersion / 2
  x <- mu / (1 + a + sqrt(a * (2 + a)))
  ifelse(stats::runif(n) <= mu / (mu + x), x, mu^2 / x)
}

glm_design <- function(formula, coefficients, covariates, test,
                       family = stats::binomial(), dispersion = 1,
                       trials = 1L, response_generator = NULL,
                       fit_args = list(), label = NULL) {
  response <- .response_name(formula)
  .coefs(coefficients)
  .function(covariates, "covariates")
  .function(test, "test")
  if (!inherits(family, "family")) .stop("family must be a family object, such as binomial().")
  .scalar(dispersion, "dispersion", 0, open_lower = TRUE)
  known <- c("binomial", "poisson", "gaussian", "Gamma", "inverse.gaussian")
  if (is.null(response_generator) && !family$family %in% known)
    .stop("This family needs response_generator(n, mu, data). Quasi-families do not specify a distribution.")
  if (!is.null(response_generator)) .function(response_generator, "response_generator")
  if (is.null(response_generator) && family$family %in% c("binomial", "poisson") &&
      dispersion != 1) .stop("Binomial and Poisson dispersion is fixed at 1; use a custom generator for overdispersion.")
  if (family$family != "binomial" && (!is.numeric(trials) || length(trials) != 1L || trials != 1))
    .stop("trials is only used for the binomial family.")
  generate <- function(n) {
    d <- .data(covariates, n, response)
    mu <- family$linkinv(.lp(formula, coefficients, d))
    if (length(mu) != n || any(!is.finite(mu)) || !isTRUE(family$validmu(mu)))
      .stop("The chosen coefficients and link generated invalid response means.")
    if (!is.null(response_generator)) {
      y <- response_generator(n, mu, d)
    } else {
      y <- switch(family$family,
        binomial = {
          size <- if (is.function(trials)) trials(n, d) else trials
          size <- .vector(size, n, "trials", lower = 1, integer = TRUE)
          successes <- stats::rbinom(n, size, mu)
          if (all(size == 1)) successes else cbind(successes, size - successes)
        },
        poisson = stats::rpois(n, mu),
        gaussian = stats::rnorm(n, mu, sqrt(dispersion)),
        Gamma = stats::rgamma(n, shape = 1 / dispersion, scale = mu * dispersion),
        inverse.gaussian = .rinvgaussian(n, mu, dispersion)
      )
    }
    if (!is.numeric(y) || any(!is.finite(y)) ||
        (if (is.matrix(y)) nrow(y) != n || ncol(y) != 2L else length(y) != n))
      .stop("The response generator must return n finite numbers or an n by 2 count matrix.")
    if (is.matrix(y) && !family$family %in% c("binomial", "quasibinomial"))
      .stop("Matrix responses require a binomial or quasibinomial family.")
    if (family$family %in% c("binomial", "quasibinomial")) {
      if (is.matrix(y)) {
        if (any(y < 0 | y != floor(y)) || any(rowSums(y) <= 0))
          .stop("Grouped binomial responses must contain nonnegative integer counts and positive totals.")
      } else if (any(!y %in% c(0, 1)))
        .stop("Return Bernoulli 0/1 responses or a successes/failures matrix for binomial simulation.")
    }
    d[[response]] <- y
    d
  }
  fit <- function(data) {
    args <- .args(fit_args, data, c("formula", "data", "family"))
    do.call(stats::glm, c(list(formula = formula, data = data, family = family), args))
  }
  diagnostics <- function(data) {
    y <- data[[response]]
    if (!family$family %in% c("binomial", "quasibinomial")) return(numeric())
    if (is.matrix(y)) c(events = sum(y[, 1]), event_fraction = sum(y[, 1]) / sum(y))
    else c(events = sum(y), event_fraction = mean(y))
  }
  if (is.null(label)) label <- paste(family$family, "GLM with", family$link, "link")
  out <- simulation_design(generate, fit, test, diagnostics, label)
  out$metadata <- list(formula = formula, coefficients = coefficients,
                       family = family$family, link = family$link,
                       dispersion = dispersion,
                       sampling_unit = "covariate row; grouped binomial totals may exceed n")
  out
}

lm_design <- function(formula, coefficients, covariates, test, sigma = 1,
                      error = NULL, fit_args = list(), label = "Linear regression") {
  response <- .response_name(formula)
  .coefs(coefficients)
  .function(covariates, "covariates")
  .function(test, "test")
  if (!is.function(sigma)) .scalar(sigma, "sigma", 0, open_lower = TRUE)
  if (!is.null(error)) .function(error, "error")
  generate <- function(n) {
    d <- .data(covariates, n, response)
    mu <- .lp(formula, coefficients, d)
    if (is.null(error)) {
      sd <- if (is.function(sigma)) sigma(d) else sigma
      sd <- .vector(sd, n, "sigma", lower = 0, strict = TRUE)
      eps <- stats::rnorm(n, sd = sd)
    } else {
      eps <- error(n, d)
      if (!is.numeric(eps) || length(eps) != n || any(!is.finite(eps)))
        .stop("error(n, data) must return exactly n finite residuals.")
    }
    d[[response]] <- mu + eps
    d
  }
  fit <- function(data) {
    do.call(stats::lm, c(list(formula = formula, data = data),
                       .args(fit_args, data, c("formula", "data"))))
  }
  out <- simulation_design(generate, fit, test, label = label)
  out$metadata <- list(formula = formula, coefficients = coefficients,
                       sampling_unit = "generated row")
  out
}

weibull_baseline <- function(rate = 0.1, shape = 1) {
  if (!is.function(rate)) .scalar(rate, "rate", 0, open_lower = TRUE)
  if (!is.function(shape)) .scalar(shape, "shape", 0, open_lower = TRUE)
  function(q, data) {
    n <- length(q)
    r <- .vector(if (is.function(rate)) rate(data) else rate,
                 n, "rate", lower = 0, strict = TRUE)
    s <- .vector(if (is.function(shape)) shape(data) else shape,
                 n, "shape", lower = 0, strict = TRUE)
    (q / r)^(1 / s)
  }
}

piecewise_baseline <- function(breaks = c(0, 1), rates = c(0.1, 0.2)) {
  if (!is.numeric(breaks) || !length(breaks) || any(!is.finite(breaks)) ||
      breaks[1] != 0 || any(diff(breaks) <= 0))
    .stop("breaks must start at 0 and contain increasing finite interval start times.")
  if (!is.numeric(rates) || length(rates) != length(breaks) ||
      any(!is.finite(rates) | rates <= 0))
    .stop("Supply one strictly positive rate per interval; the last interval continues indefinitely.")
  cumhaz <- c(0, cumsum(diff(breaks) * rates[-length(rates)]))
  function(q, data) {
    if (!is.numeric(q) || any(!is.finite(q) | q < 0)) .stop("Invalid cumulative hazards.")
    j <- findInterval(q, cumhaz, all.inside = FALSE)
    breaks[j] + (q - cumhaz[j]) / rates[j]
  }
}

.cox_response <- function(formula) {
  if (!inherits(formula, "formula") || length(formula) != 3L)
    .stop("Cox formula must be two-sided.")
  lhs <- formula[[2]]
  callname <- if (is.call(lhs)) paste(deparse(lhs[[1]]), collapse = "") else ""
  if (!callname %in% c("Surv", "survival::Surv") || length(lhs) != 3L ||
      !is.symbol(lhs[[2]]) || !is.symbol(lhs[[3]]))
    .stop("cox_design generates right-censored Surv(time, status) data. Use simulation_design for other survival structures.")
  out <- c(as.character(lhs[[2]]), as.character(lhs[[3]]))
  if (out[1] == out[2]) .stop("Time and status need different names.")
  out
}

cox_design <- function(formula, coefficients, covariates, test,
                       baseline = weibull_baseline(), censoring = NULL,
                       followup = Inf, lp_formula = NULL,
                       fit_args = list(), label = "Proportional hazards Cox regression") {
  response <- .cox_response(formula)
  .coefs(coefficients)
  .function(covariates, "covariates")
  .function(test, "test")
  .function(baseline, "baseline")
  if (!is.null(censoring)) .function(censoring, "censoring")
  calls <- all.names(formula[[3]], functions = TRUE)
  if (any(c("tt", "frailty", "frailty.gamma", "frailty.gaussian", "pspline", "ridge") %in% calls))
    .stop("Time-transform, frailty, and penalized Cox models need simulation_design with explicit generation and inference.")
  if (is.null(lp_formula)) {
    if (any(c("strata", "cluster") %in% calls))
      .stop("Supply lp_formula for a stratified or cluster-robust Cox analysis.")
    lp_formula <- stats::formula(.rhs(formula))
  }
  if (!inherits(lp_formula, "formula") || length(lp_formula) != 2L)
    .stop("lp_formula must be a one-sided formula for the generating linear predictor.")
  env <- new.env(parent = environment(formula))
  env$Surv <- survival::Surv
  env$strata <- survival::strata
  env$cluster <- survival::cluster
  environment(formula) <- env
  generate <- function(n) {
    d <- .data(covariates, n, response)
    eta <- .lp(lp_formula, coefficients, d, intercept = FALSE)
    q <- stats::rexp(n) * exp(-eta)
    if (any(!is.finite(q) | q <= 0)) .stop("Invalid hazard scale; inspect effect sizes.")
    event_time <- baseline(q, d)
    if (!is.numeric(event_time) || length(event_time) != n ||
        any(!is.finite(event_time) | event_time <= 0))
      .stop("baseline(q, data) must return exactly n positive finite event times.")
    cap <- if (is.function(followup)) followup(n, d) else followup
    cap <- .vector(cap, n, "followup", finite = FALSE, lower = 0, strict = TRUE)
    censor <- if (is.null(censoring)) rep(Inf, n) else censoring(n, d)
    censor <- .vector(censor, n, "censoring", finite = FALSE, lower = 0, strict = TRUE)
    d[[response[1]]] <- pmin(event_time, censor, cap)
    d[[response[2]]] <- as.integer(event_time <= pmin(censor, cap))
    d
  }
  fit <- function(data) {
    args <- .args(fit_args, data, c("formula", "data"))
    if (is.null(args$x)) args$x <- TRUE
    if (is.null(args$y)) args$y <- TRUE
    if (is.null(args$model)) args$model <- TRUE
    do.call(survival::coxph, c(list(formula = formula, data = data), args))
  }
  diagnostics <- function(data) c(events = sum(data[[response[2]]]),
                                 event_fraction = mean(data[[response[2]]]))
  out <- simulation_design(generate, fit, test, diagnostics, label)
  out$metadata <- list(formula = formula, lp_formula = lp_formula,
                       coefficients = coefficients, sampling_unit = "individual")
  out
}
