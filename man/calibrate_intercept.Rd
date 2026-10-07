\name{calibrate_intercept}
\alias{calibrate_intercept}
\title{Calibrate a Binomial Intercept to a Marginal Event Probability}
\usage{
calibrate_intercept(formula, coefficients, data, target,
                    family = stats::binomial(), interval = c(-40, 40), tol = 1e-9)
}
\arguments{
\item{formula}{Model formula, including an intercept.}
\item{coefficients}{Named coefficient vector. The existing intercept is ignored.}
\item{data}{Fixed, representative reference covariate data.}
\item{target}{Desired mean event probability, strictly between zero and one.}
\item{family}{Binomial family object with the intended link.}
\item{interval}{Increasing finite intercept bounds for root finding.}
\item{tol}{Positive numerical tolerance.}
}
\description{Solve for the intercept whose predicted probabilities average to the
target over the reference rows, with all slopes and offsets held fixed.}
\details{Rows receive equal weight. This calibrates a marginal event probability
for the reference covariate distribution, not a probability at the mean covariate
profile and not a trial-weighted grouped-binomial probability. Calibrate once on a
large, fixed reference sample; recalibrating inside each replicate changes the
data-generating process. Root-finding tolerance does not remove Monte Carlo error
or uncertainty about the reference population.}
\value{One numeric intercept.}
\examples{
set.seed(1)
ref <- data.frame(x = rnorm(2000))
b <- c("(Intercept)" = 0, x = log(1.5))
b[1] <- calibrate_intercept(y ~ x, b, ref, target = 0.13)
mean(plogis(b[1] + b[2] * ref$x))
}
