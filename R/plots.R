plot.regsim_power <- function(x, y = NULL, target = 0.8,
                              col = "#0072B2", band = TRUE,
                              xlab = "Sample size", ylab = "Power",
                              main = x$design$label, ...) {
  .probability(target, "target")
  if (!is.logical(band) || length(band) != 1L || is.na(band)) .stop("band must be TRUE or FALSE.")
  s <- x$summary[order(x$summary$n), ]
  graphics::plot(s$n, s$power, type = "n", ylim = c(0, 1),
                 xlab = xlab, ylab = ylab, main = main, ...)
  if (band && nrow(s) > 1L) {
    graphics::polygon(c(s$n, rev(s$n)), c(s$lower, rev(s$upper)),
                      border = NA, col = grDevices::adjustcolor(col, alpha.f = 0.18))
  } else if (band) {
    graphics::segments(s$n, s$lower, s$n, s$upper, col = col, lwd = 2)
  }
  graphics::abline(h = target, lty = 2, col = "#666666")
  graphics::lines(s$n, s$power, col = col, lwd = 2)
  graphics::points(s$n, s$power, pch = 16, col = col)
  invisible(x)
}

plot_event_rate <- function(x, n = max(x$summary$n), col = "#0072B2", ...) {
  if (!inherits(x, "regsim_power")) .stop("x must be a power_curve result.")
  .scalar(n, "n", 1, integer = TRUE)
  if (!n %in% x$summary$n) .stop("n was not evaluated.")
  z <- x$replicates$event_fraction[x$replicates$n == n]
  z <- z[is.finite(z)]
  if (!length(z)) .stop("No event-fraction diagnostics are available at this sample size.")
  graphics::hist(z, breaks = "FD", probability = TRUE,
                 col = grDevices::adjustcolor(col, alpha.f = 0.22), border = "white",
                 xlab = "Observed event fraction", main = paste("Event fractions at n =", n), ...)
  if (length(z) > 1 && stats::sd(z) > 0) graphics::lines(stats::density(z), col = col, lwd = 2)
  graphics::rug(z, col = grDevices::adjustcolor(col, alpha.f = 0.2))
  invisible(z)
}
