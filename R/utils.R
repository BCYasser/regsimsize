.stop <- function(...) stop(..., call. = FALSE)

.scalar <- function(x, name, lower = -Inf, upper = Inf, integer = FALSE,
                    open_lower = FALSE, open_upper = FALSE) {
  bad <- !is.numeric(x) || length(x) != 1L || !is.finite(x)
  if (!bad) bad <- (if (open_lower) x <= lower else x < lower) ||
    (if (open_upper) x >= upper else x > upper) ||
    (integer && x != floor(x))
  if (bad) .stop(name, " must be a finite ", if (integer) "integer " else "number ",
                 "in the permitted range.")
  invisible(x)
}

.probability <- function(x, name) {
  .scalar(x, name, 0, 1, open_lower = TRUE, open_upper = TRUE)
}

.function <- function(x, name) {
  if (!is.function(x)) .stop(name, " must be a function.")
}

.preserve_rng <- function(fun) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  fun()
}

.with_seed <- function(seed, fun) {
  .scalar(seed, "seed", 0, .Machine$integer.max, integer = TRUE)
  .preserve_rng(function() {
    RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")
    set.seed(as.integer(seed))
    fun()
  })
}

.rhs <- function(formula) {
  if (!inherits(formula, "formula")) .stop("formula must be an R formula.")
  stats::delete.response(stats::terms(formula))
}

.response_name <- function(formula) {
  if (!inherits(formula, "formula") || length(formula) != 3L ||
      !is.symbol(formula[[2L]]))
    .stop("Use a two-sided formula with a plain response name, such as y ~ x.")
  as.character(formula[[2L]])
}

.matrix <- function(formula, data, intercept = TRUE) {
  frame <- stats::model.frame(.rhs(formula), data = data,
                             na.action = stats::na.fail)
  X <- stats::model.matrix(.rhs(formula), data = frame)
  if (!intercept && "(Intercept)" %in% colnames(X))
    X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  off <- stats::model.offset(frame)
  if (is.null(off)) off <- rep(0, nrow(X))
  if (nrow(X) != nrow(data) || any(!is.finite(X)) || any(!is.finite(off)))
    .stop("The design matrix and offsets must be finite for every generated row.")
  list(X = X, offset = off)
}

.coefs <- function(coefficients) {
  if (!is.numeric(coefficients) || any(!is.finite(coefficients)) ||
      (length(coefficients) && (is.null(names(coefficients)) ||
       anyNA(names(coefficients)) || any(!nzchar(names(coefficients))))) ||
      anyDuplicated(names(coefficients)))
    .stop("coefficients must be finite, uniquely named numbers (use model_coefficients()).")
}

.lp <- function(formula, coefficients, data, intercept = TRUE) {
  .coefs(coefficients)
  mm <- .matrix(formula, data, intercept)
  if (!setequal(colnames(mm$X), names(coefficients))) {
    .stop("Coefficient names must match the design matrix exactly. Missing: ",
          paste(setdiff(colnames(mm$X), names(coefficients)), collapse = ", "),
          "; extra: ", paste(setdiff(names(coefficients), colnames(mm$X)), collapse = ", "))
  }
  eta <- drop(mm$X %*% coefficients[colnames(mm$X)]) + mm$offset
  if (any(!is.finite(eta))) .stop("Nonfinite linear predictor.")
  eta
}

.vector <- function(x, n, name, finite = TRUE, lower = -Inf,
                    strict = FALSE, integer = FALSE) {
  if (!is.numeric(x) || !length(x) || !(length(x) %in% c(1L, n)) ||
      anyNA(x) || any(is.nan(x))) .stop(name, " must have length 1 or n and be numeric.")
  x <- rep_len(x, n)
  if ((finite && any(!is.finite(x))) ||
      any(if (strict) x <= lower else x < lower) ||
      (integer && any(!is.finite(x) | x != floor(x))))
    .stop("Invalid values in ", name, ".")
  x
}

.data <- function(covariates, n, reserved = character()) {
  d <- covariates(n)
  if (!is.data.frame(d) || nrow(d) != n || anyDuplicated(names(d)))
    .stop("covariates(n) must return a data frame with n rows and unique column names.")
  if (any(reserved %in% names(d)))
    .stop("Generated covariates contain a reserved response column: ",
          paste(intersect(reserved, names(d)), collapse = ", "))
  d
}

.args <- function(args, data, protected) {
  if (is.function(args)) args <- args(data)
  if (!is.list(args) || (length(args) &&
      (is.null(names(args)) || anyNA(names(args)) || any(!nzchar(names(args))) ||
       anyDuplicated(names(args))))) .stop("fit_args must be a named list, or a function returning one.")
  if (any(names(args) %in% protected))
    .stop("fit_args cannot replace: ", paste(intersect(names(args), protected), collapse = ", "))
  args
}

.check_fit <- function(fit) {
  if (inherits(fit, "glm") && !isTRUE(fit$converged)) .stop("GLM did not converge.")
  if (inherits(fit, "glm") && isTRUE(fit$boundary)) .stop("GLM stopped at a boundary.")
  if (inherits(fit, c("lm", "coxph"))) {
    b <- stats::coef(fit)
    if (any(!is.finite(b)))
      .stop("Model has missing, aliased, or nonfinite coefficients.")
  }
  invisible(fit)
}

.wilson <- function(k, n, level) {
  if (!n) return(c(lower = NA_real_, upper = NA_real_))
  z <- stats::qnorm(1 - (1 - level) / 2)
  p <- k / n
  den <- 1 + z^2 / n
  mid <- (p + z^2 / (2 * n)) / den
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  c(lower = max(0, mid - half), upper = min(1, mid + half))
}

.mean_finite <- function(x) {
  if (any(is.finite(x))) mean(x[is.finite(x)]) else NA_real_
}
