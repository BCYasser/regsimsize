.reference_df <- function(fit, df) {
  if (is.function(df)) df <- df(fit)
  if (!is.null(df)) {
    if (!is.numeric(df) || length(df) != 1L || is.na(df) || df <= 0)
      .stop("df must be positive (Inf gives normal/chi-square reference distributions).")
    return(df)
  }
  if (inherits(fit, "coxph")) return(Inf)
  if (inherits(fit, "glm")) {
    known_dispersion <- fit$family$dispersion
    if (!is.null(known_dispersion) && length(known_dispersion) == 1L &&
        is.finite(known_dispersion)) return(Inf)
    if (fit$family$family %in% c("binomial", "poisson")) return(Inf)
    return(stats::df.residual(fit))
  }
  if (inherits(fit, "lm")) return(stats::df.residual(fit))
  .stop("Supply df or a custom test for this model class.")
}

wald_test <- function(terms, null = 0, alternative = c("two.sided", "greater", "less"),
                      vcov = NULL, df = NULL) {
  if (!is.character(terms) || !length(terms) || anyNA(terms) ||
      any(!nzchar(terms)) || anyDuplicated(terms))
    .stop("terms must contain unique coefficient names.")
  alternative <- match.arg(alternative)
  null <- .vector(null, length(terms), "null")
  if (length(terms) > 1L && alternative != "two.sided")
    .stop("Directional tests require one coefficient.")
  if (!is.null(vcov)) {
    .function(vcov, "vcov")
    if (is.null(df)) .stop("When supplying vcov, specify df explicitly for the intended reference distribution.")
  }
  force(terms); force(null); force(df); force(vcov)
  function(fit, data) {
    .check_fit(fit)
    if (inherits(fit, "coxph.penal"))
      .stop("Penalized Cox inference needs a model-specific custom test.")
    b <- stats::coef(fit)
    if (!is.numeric(b) || !all(terms %in% names(b)))
      .stop("Requested coefficient is absent: ", paste(setdiff(terms, names(b)), collapse = ", "))
    V <- if (is.null(vcov)) stats::vcov(fit) else vcov(fit)
    if (!is.matrix(V) || !all(terms %in% rownames(V)) || !all(terms %in% colnames(V)))
      .stop("Covariance matrix does not contain the requested terms.")
    V <- V[terms, terms, drop = FALSE]
    delta <- b[terms] - null
    if (any(!is.finite(delta)) || any(!is.finite(V)) ||
        !isTRUE(all.equal(V, t(V), tolerance = 1e-8)))
      .stop("Invalid coefficient covariance matrix.")
    # Cholesky also rejects non-positive and rank-deficient covariance matrices.
    R <- tryCatch(chol(V), error = function(e) .stop("Test covariance is not positive definite."))
    ddf <- .reference_df(fit, df)
    if (is.na(ddf) || ddf <= 0) .stop("No residual degrees of freedom for this test.")
    if (length(terms) == 1L) {
      se <- sqrt(V[1, 1])
      stat <- unname(delta / se)
      upper <- function(z) if (is.infinite(ddf)) stats::pnorm(z, lower.tail = FALSE)
        else stats::pt(z, df = ddf, lower.tail = FALSE)
      p <- switch(alternative, two.sided = 2 * upper(abs(stat)),
                  greater = upper(stat), less = upper(-stat))
      return(list(p.value = min(1, p), estimate = unname(b[terms]),
                  se = se, statistic = stat, df = ddf))
    }
    w <- sum(backsolve(R, delta, transpose = TRUE)^2)
    k <- length(terms)
    p <- if (is.infinite(ddf)) stats::pchisq(w, k, lower.tail = FALSE)
      else stats::pf(w / k, k, ddf, lower.tail = FALSE)
    list(p.value = p, statistic = if (is.infinite(ddf)) w else w / k,
         df = k, df.residual = ddf)
  }
}

lrt_test <- function(reduced_formula) {
  if (!inherits(reduced_formula, "formula")) .stop("reduced_formula must be a formula.")
  force(reduced_formula)
  function(fit, data) {
    .check_fit(fit)
    if (!inherits(fit, c("lm", "glm", "coxph")) || inherits(fit, "coxph.penal"))
      .stop("Use a custom likelihood-ratio test for this model class.")
    if (inherits(fit, "glm") && grepl("^quasi", fit$family$family))
      .stop("Quasi-likelihood does not support this likelihood-ratio test.")
    if (inherits(fit, "coxph") && !is.null(fit$naive.var))
      .stop("A partial-likelihood ratio is not a robust cluster test; use a robust Wald or custom test.")
    reduced <- stats::update(fit, formula. = reduced_formula, data = data)
    .check_fit(reduced)
    f1 <- stats::model.frame(fit)
    f0 <- stats::model.frame(reduced)
    same <- function(a, b) isTRUE(all.equal(a, b, check.attributes = TRUE))
    if (!identical(rownames(f1), rownames(f0)) ||
        !same(stats::model.response(f1), stats::model.response(f0)) ||
        !same(stats::model.weights(f1), stats::model.weights(f0)) ||
        !same(stats::model.offset(f1), stats::model.offset(f0)))
      .stop("Models must use identical rows, responses, weights, and offsets.")
    if (inherits(fit, "coxph")) {
      specials <- function(x) {
        labs <- attr(stats::terms(x), "term.labels")
        sort(labs[grepl("strata\\(|cluster\\(", labs)])
      }
      if (!identical(specials(fit), specials(reduced)))
        .stop("Cox likelihood-ratio models must retain the same strata and cluster structure.")
    }
    X1 <- stats::model.matrix(fit)
    X0 <- stats::model.matrix(reduced)
    if (nrow(X1) != nrow(X0) || qr(cbind(X1, X0))$rank != qr(X1)$rank)
      .stop("The reduced model is not nested in the full model.")
    l1 <- stats::logLik(fit)
    l0 <- stats::logLik(reduced)
    k <- attr(l1, "df") - attr(l0, "df")
    stat <- 2 * as.numeric(l1 - l0)
    if (length(k) != 1L || !is.finite(k) || k <= 0 ||
        !is.finite(stat) || stat < -1e-6)
      .stop("Invalid nested likelihood comparison.")
    stat <- max(0, stat)
    list(p.value = stats::pchisq(stat, k, lower.tail = FALSE), statistic = stat, df = k)
  }
}
