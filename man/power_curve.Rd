\name{power_curve}
\alias{power_curve}
\alias{print.regsim_power}
\alias{summary.regsim_power}
\alias{as.data.frame.regsim_power}
\title{Estimate Power Across a Prespecified Sample Size Grid}
\usage{
power_curve(design, sample_sizes, nsim = 1000L, alpha = 0.05,
            conf.level = 0.95, seed = 1L, workers = 1L,
            warning_policy = c("fail", "record"), progress = interactive())
\method{print}{regsim_power}(x, ...)
\method{summary}{regsim_power}(object, ...)
\method{as.data.frame}{regsim_power}(x, row.names = NULL, optional = FALSE, ...)
}
\arguments{
\item{design}{A regsim_design object.}
\item{sample_sizes}{Positive integer grid; sorted and deduplicated.}
\item{nsim}{Positive integer number of simulated studies per grid point.}
\item{alpha}{Rejection threshold; a p-value strictly below alpha is significant.}
\item{conf.level}{Pointwise Monte Carlo interval confidence level.}
\item{seed}{Nonnegative integer random seed.}
\item{workers}{Number of PSOCK workers. The default runs sequentially.
Use at most two workers in examples, tests, vignettes, or other code run on CRAN.}
\item{warning_policy}{By default any warning makes that replicate a failed
analysis. With record, warnings are retained but a valid test can contribute a
rejection. Nonconvergence, boundary GLMs, invalid coefficients, errors and invalid
p-values still fail. Warning text can vary across R and package versions.}
\item{progress}{Whether to print a start message.}
\item{x, object}{A regsim_power object.}
\item{row.names}{Optional replacement data-frame row names.}
\item{optional}{Accepted for S3 compatibility.}
\item{...}{Additional print arguments for print; otherwise unused.}
}
\description{Repeatedly generate a study, fit its planned model, and evaluate
the prespecified test at each sample size.}
\details{Primary power is rejections divided by all attempted replicates, so failed
analyses count as non-rejections. This estimates the operating success of a procedure
that does not reject on failure; it is not the unknowable power of a hypothetically
successful replacement analysis. Conditional power divides by successful analyses
and is also reported. It may be biased upward if difficult datasets fail.

Monte Carlo standard error is the binomial plug-in standard error. Pointwise
Wilson intervals remain informative at zero or full rejection despite a zero
plug-in standard error. They quantify simulation error under fixed assumptions,
not uncertainty in the assumed effects or data distribution. Grid intervals are
not simultaneous, and adaptive searching needs independent confirmation.

Each replicate receives a separate L'Ecuyer-CMRG stream. Identical settings reproduce
raw results across sequential and PSOCK execution for self-contained, deterministic
callbacks with compatible R/package versions. Changing nsim or the grid changes
stream allocation after the affected task; runs cannot be appended as if streams
were unchanged. The caller's random state and RNG kind are restored. Callback
functions must not reseed or use independent external random-number generators.
All replicate rows are retained in memory; large simulations may need separate runs
with distinct seeds and explicitly planned aggregation.
}
\value{A regsim_power list with:
\item{summary}{Data frame with n, nsim, successful, failed, failure_rate,
warning_rate, rejections, power, mcse, lower, upper, power_successful,
lower_successful, upper_successful, mean_events, mean_event_fraction, mean_rows,
and mean_analyzed. Event summaries include all datasets with available diagnostics,
including datasets whose fits failed. mean_analyzed uses the fitter's nobs method;
for coxph this is the number of events, not participant rows.}
\item{replicates}{Data frame of individual results, p-values, rejection flags,
coefficient details when available, event diagnostics, row counts, warnings,
error messages, and the stage at which errors occurred.}
\item{design}{The full simulation specification, including callbacks.}
\item{settings}{Seeds, number of replicates, thresholds, and failure policy.}
\item{session}{R and package session information.}
The summary and as.data.frame methods return the summary data frame. Print returns
its input invisibly.}
\examples{
d <- lm_design(y ~ x, c("(Intercept)" = 0, x = .4),
               function(n) data.frame(x = rnorm(n)), wald_test("x"))
p <- power_curve(d, c(40, 80, 120), nsim = 10, seed = 15)
summary(p)
head(p$replicates)
}
