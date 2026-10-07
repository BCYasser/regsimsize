\name{select_sample_size}
\alias{select_sample_size}
\title{Select the Smallest Evaluated Sample Size Meeting a Target}
\usage{
select_sample_size(x, target = 0.8, criterion = c("lower", "estimate"),
                   max_failure = 0.01)
}
\arguments{
\item{x}{A power_curve result.}
\item{target}{Desired power, strictly between 0 and 1.}
\item{criterion}{Use the lower pointwise Monte Carlo confidence limit by default,
or the estimated power. Both use all attempted analyses as the denominator.}
\item{max_failure}{Maximum acceptable observed fraction of failed analyses.}
}
\description{Choose the smallest tested n that meets both the power criterion
and the observed failure-rate limit.}
\details{No smoothing, interpolation, extrapolation, or monotonicity assumption is
used. A noisy curve may have a lower qualifying point followed by a nonqualifying
one. Inspect the full curve and independently confirm the candidate with more
replicates and a new seed. Using a lower pointwise limit is a cautious selection
rule, not a simultaneous guarantee across the grid or across uncertain assumptions.
The failure limit is checked against its observed fraction, not a confidence bound.
If the smallest grid point qualifies, the result is still only the smallest tested
sample size, not a demonstrated global minimum.}
\value{One-row data frame with n, target, criterion, achieved, power, lower, upper,
and failure_rate. If no point qualifies, n and estimated quantities are NA and a
warning is issued.}
\examples{
d <- lm_design(y ~ x, c("(Intercept)" = 0, x = 1),
               function(n) data.frame(x = rnorm(n)), wald_test("x"))
p <- power_curve(d, c(100, 200), nsim = 30)
select_sample_size(p)
}
