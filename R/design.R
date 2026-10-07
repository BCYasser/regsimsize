# Public functions are documented in man/ and the user guide.
simulation_design <- function(generate, fit, test, diagnostics = NULL,
                              label = "Custom simulation design") {
  .function(generate, "generate")
  .function(fit, "fit")
  .function(test, "test")
  if (!is.null(diagnostics)) .function(diagnostics, "diagnostics")
  if (!is.character(label) || length(label) != 1L || is.na(label))
    .stop("label must be one string.")
  structure(list(generate = generate, fit = fit, test = test,
                 diagnostics = diagnostics, label = label, metadata = list()),
            class = "regsim_design")
}

print.regsim_design <- function(x, ...) {
  cat("Simulation design:", x$label, "\n")
  if (length(x$metadata)) print(x$metadata)
  invisible(x)
}

simulate_data <- function(design, n, seed = 1L) {
  if (!inherits(design, "regsim_design")) .stop("design must be a simulation design.")
  .scalar(n, "n", 1, .Machine$integer.max, integer = TRUE)
  .with_seed(seed, function() design$generate(as.integer(n)))
}

model_coefficients <- function(formula, data, value = 0, intercept = TRUE) {
  .scalar(value, "value")
  if (!is.logical(intercept) || length(intercept) != 1L || is.na(intercept))
    .stop("intercept must be TRUE or FALSE.")
  X <- .matrix(formula, data, intercept)$X
  stats::setNames(rep(value, ncol(X)), colnames(X))
}

calibrate_intercept <- function(formula, coefficients, data, target,
                                family = stats::binomial(),
                                interval = c(-40, 40), tol = 1e-9) {
  .probability(target, "target")
  .scalar(tol, "tol", 0, open_lower = TRUE)
  if (!inherits(family, "family") || !identical(family$family, "binomial"))
    .stop("calibrate_intercept requires a binomial family object.")
  if (!is.numeric(interval) || length(interval) != 2L ||
      any(!is.finite(interval)) || interval[1] >= interval[2])
    .stop("interval must be two increasing finite numbers.")
  if (!"(Intercept)" %in% names(coefficients)) .stop("An intercept coefficient is required.")
  coefficients["(Intercept)"] <- 0
  lp <- .lp(formula, coefficients, data)
  f <- function(a) mean(family$linkinv(a + lp)) - target
  ends <- vapply(interval, f, numeric(1))
  if (any(!is.finite(ends)) || prod(sign(ends)) > 0)
    .stop("Target is not bracketed; widen interval or inspect the link and reference data.")
  stats::uniroot(f, interval, tol = tol)$root
}
