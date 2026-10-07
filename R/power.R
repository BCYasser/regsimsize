.run_one <- function(task, design, alpha, warning_policy) {
  assign(".Random.seed", task$stream, envir = .GlobalEnv)
  messages <- character()
  row <- list(n = task$n, replicate = task$replicate, status = "ok",
              p_value = NA_real_, reject = FALSE, estimate = NA_real_,
              se = NA_real_, statistic = NA_real_, n_rows = NA_real_,
              n_analyzed = NA_real_, events = NA_real_, event_fraction = NA_real_,
              warnings = "", error = "", stage = "generate")
  answer <- tryCatch(withCallingHandlers({
    data <- design$generate(task$n)
    if (!is.data.frame(data) || !nrow(data))
      .stop("generate(n) must return a nonempty data frame.")
    row$n_rows <- nrow(data)
    row$stage <- "diagnostics"
    if (!is.null(design$diagnostics)) {
      d <- design$diagnostics(data)
      if (!is.numeric(d) || (length(d) &&
          (is.null(names(d)) || anyNA(names(d)) || anyDuplicated(names(d)) ||
           any(!names(d) %in% c("events", "event_fraction")) || any(!is.finite(d)))))
        .stop("diagnostics must return a named numeric vector using events and/or event_fraction.")
      for (nm in names(d)) row[[nm]] <- unname(d[nm])
      if ((!is.na(row$events) && row$events < 0) ||
          (!is.na(row$event_fraction) && (row$event_fraction < 0 || row$event_fraction > 1)))
        .stop("Invalid event diagnostics.")
    }
    row$stage <- "fit"
    fit <- design$fit(data)
    .check_fit(fit)
    observed <- tryCatch(stats::nobs(fit), error = function(e) NA_real_)
    if (is.numeric(observed) && length(observed) == 1L) row$n_analyzed <- as.numeric(observed)
    row$stage <- "test"
    result <- design$test(fit, data)
    p <- if (is.list(result)) result$p.value else result
    if (!is.numeric(p) || length(p) != 1L || !is.finite(p) || p < 0 || p > 1)
      .stop("test(fit, data) must return one p-value in [0, 1], or a list with p.value.")
    row$p_value <- unname(p)
    if (is.list(result)) {
      for (nm in c("estimate", "se", "statistic")) {
        v <- result[[nm]]
        if (is.numeric(v) && length(v) == 1L && is.finite(v)) row[[nm]] <- unname(v)
      }
    }
    row$reject <- p < alpha
    row$stage <- "complete"
    TRUE
  }, warning = function(w) {
    messages <<- c(messages, conditionMessage(w))
    invokeRestart("muffleWarning")
  }), error = function(e) {
    row$status <<- "error"
    row$error <<- conditionMessage(e)
    FALSE
  })
  row$warnings <- paste(unique(messages), collapse = " | ")
  if (isTRUE(answer) && length(messages) && warning_policy == "fail") {
    row$status <- "warning"
    row$error <- "Warnings treated as failed analyses by the selected policy."
  }
  if (row$status != "ok") {
    row$p_value <- NA_real_
    row$reject <- FALSE
  }
  as.data.frame(row, stringsAsFactors = FALSE)
}

power_curve <- function(design, sample_sizes, nsim = 1000L, alpha = 0.05,
                        conf.level = 0.95, seed = 1L, workers = 1L,
                        warning_policy = c("fail", "record"), progress = interactive()) {
  if (!inherits(design, "regsim_design")) .stop("design must be a simulation design.")
  if (!is.numeric(sample_sizes) || !length(sample_sizes) ||
      any(!is.finite(sample_sizes) | sample_sizes < 1 |
          sample_sizes > .Machine$integer.max | sample_sizes != floor(sample_sizes)))
    .stop("sample_sizes must be positive integers.")
  sample_sizes <- sort(unique(as.integer(sample_sizes)))
  .scalar(nsim, "nsim", 1, .Machine$integer.max, integer = TRUE)
  .scalar(workers, "workers", 1, .Machine$integer.max, integer = TRUE)
  .scalar(seed, "seed", 0, .Machine$integer.max, integer = TRUE)
  .probability(alpha, "alpha")
  .probability(conf.level, "conf.level")
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress))
    .stop("progress must be TRUE or FALSE.")
  warning_policy <- match.arg(warning_policy)
  total <- length(sample_sizes) * nsim
  if (total > .Machine$integer.max) .stop("Too many simulation tasks.")
  tasks <- .with_seed(seed, function() {
    stream <- get(".Random.seed", envir = .GlobalEnv)
    out <- vector("list", total)
    k <- 0L
    for (n in sample_sizes) for (r in seq_len(nsim)) {
      k <- k + 1L
      out[[k]] <- list(n = n, replicate = r, stream = stream)
      stream <- parallel::nextRNGStream(stream)
    }
    out
  })
  if (progress) message("Running ", total, " analyses across ", length(sample_sizes), " sample sizes.")
  results <- .preserve_rng(function() {
    if (workers == 1L) {
      lapply(tasks, .run_one, design = design, alpha = alpha, warning_policy = warning_policy)
    } else {
      cl <- parallel::makePSOCKcluster(min(workers, total))
      on.exit(parallel::stopCluster(cl), add = TRUE)
      parallel::clusterCall(cl, function(paths) .libPaths(paths), .libPaths())
      parallel::parLapply(cl, tasks, .run_one, design = design,
                         alpha = alpha, warning_policy = warning_policy)
    }
  })
  raw <- do.call(rbind, results)
  summary <- do.call(rbind, lapply(sample_sizes, function(n) {
    r <- raw[raw$n == n, , drop = FALSE]
    ok <- r$status == "ok"
    k <- sum(r$reject)
    m <- sum(ok)
    ci <- .wilson(k, nsim, conf.level)
    conditional <- .wilson(k, m, conf.level)
    p <- k / nsim
    data.frame(n = n, nsim = nsim, successful = m, failed = nsim - m,
               failure_rate = (nsim - m) / nsim, warning_rate = mean(nzchar(r$warnings)),
               rejections = k, power = p, mcse = sqrt(p * (1 - p) / nsim),
               lower = unname(ci[1]), upper = unname(ci[2]),
               power_successful = if (m) k / m else NA_real_,
               lower_successful = unname(conditional[1]), upper_successful = unname(conditional[2]),
               mean_events = .mean_finite(r$events),
               mean_event_fraction = .mean_finite(r$event_fraction),
               mean_rows = .mean_finite(r$n_rows), mean_analyzed = .mean_finite(r$n_analyzed))
  }))
  out <- structure(list(summary = summary, replicates = raw, design = design,
                        settings = list(nsim = nsim, alpha = alpha, conf.level = conf.level,
                                        seed = seed, workers = workers, warning_policy = warning_policy,
                                        interval = "pointwise Wilson", failure_denominator = "all attempts"),
                        session = utils::sessionInfo()), class = "regsim_power")
  if (any(summary$failed > 0)) warning(sum(summary$failed), " of ", total,
    " analyses failed or were rejected for warnings. Inspect $replicates before using the estimates.", call. = FALSE)
  out
}

select_sample_size <- function(x, target = 0.8, criterion = c("lower", "estimate"),
                               max_failure = 0.01) {
  if (!inherits(x, "regsim_power")) .stop("x must be a power_curve result.")
  .probability(target, "target")
  .scalar(max_failure, "max_failure", 0, 1)
  criterion <- match.arg(criterion)
  s <- x$summary
  value <- if (criterion == "lower") s$lower else s$power
  eligible <- which(is.finite(value) & value >= target &
                     s$failure_rate <= max_failure & s$successful > 0)
  if (!length(eligible)) {
    warning("No evaluated sample size meets the target and failure-rate limit.", call. = FALSE)
    return(data.frame(n = NA_integer_, target = target, criterion = criterion,
                      achieved = NA_real_, power = NA_real_, lower = NA_real_,
                      upper = NA_real_, failure_rate = NA_real_))
  }
  j <- eligible[which.min(s$n[eligible])]
  data.frame(n = s$n[j], target = target, criterion = criterion, achieved = value[j],
             power = s$power[j], lower = s$lower[j], upper = s$upper[j],
             failure_rate = s$failure_rate[j])
}

mc_replicates <- function(half_width = 0.01, power = 0.5, conf.level = 0.95) {
  .probability(half_width, "half_width")
  .probability(power, "power")
  .probability(conf.level, "conf.level")
  ceiling(stats::qnorm(1 - (1 - conf.level) / 2)^2 * power * (1 - power) / half_width^2)
}

print.regsim_power <- function(x, ...) {
  cat(x$design$label, "\n")
  cat("Power uses all attempted analyses. Failed analyses count as non-rejections.\n")
  print(x$summary[, c("n", "power", "lower", "upper", "mcse", "failed", "mean_events")],
        row.names = FALSE, ...)
  invisible(x)
}

summary.regsim_power <- function(object, ...) object$summary

as.data.frame.regsim_power <- function(x, row.names = NULL, optional = FALSE, ...) {
  out <- x$summary
  if (!is.null(row.names)) rownames(out) <- row.names
  out
}
