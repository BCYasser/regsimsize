\name{plot.regsim_power}
\alias{plot.regsim_power}
\alias{plot_event_rate}
\title{Plot Power and Simulated Event Fractions}
\usage{
\method{plot}{regsim_power}(x, y = NULL, target = 0.8,
                          col = "#0072B2", band = TRUE,
                          xlab = "Sample size", ylab = "Power",
                          main = x$design$label, ...)
plot_event_rate(x, n = max(x$summary$n), col = "#0072B2", ...)
}
\arguments{
\item{x}{A power_curve result.}
\item{y}{Unused; supplied for S3 compatibility.}
\item{target}{Power reference line.}
\item{col}{Plot color.}
\item{band}{Whether to show pointwise Monte Carlo confidence intervals.}
\item{xlab, ylab, main}{Axis labels and title.}
\item{n}{One evaluated sample size for the event-fraction histogram.}
\item{...}{Other arguments to the initial plot or histogram. Do not duplicate
arguments already fixed by the method, such as ylim, type, probability or breaks.}
}
\description{Draw a power curve with pointwise intervals or a histogram of event
fractions among generated studies at one sample size.}
\details{Connecting segments in a power plot are visual guides, not fitted models
or interpolated sample size estimates. Event histograms include all datasets with
available event diagnostics, including failed fits. A kernel density overlay is
drawn only when fractions vary and can extend beyond the [0, 1] boundaries.
Use a graphics device such as pdf, svg or png to export.}
\value{The power plot invisibly returns x; the event plot invisibly returns the
vector of event fractions.}
\examples{
d <- glm_design(y ~ x, c("(Intercept)" = -1, x = .4),
                function(n) data.frame(x = rnorm(n)), wald_test("x"))
p <- power_curve(d, c(100, 200), nsim = 10)
plot(p)
plot_event_rate(p)
}
