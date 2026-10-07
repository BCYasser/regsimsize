\name{lrt_test}
\alias{lrt_test}
\title{Create a Nested Likelihood-Ratio Test}
\usage{lrt_test(reduced_formula)}
\arguments{\item{reduced_formula}{Formula for the reduced model. A full formula is
recommended; an update formula such as \code{. ~ . - treatment} is also accepted.}}
\description{Refit a nested reduced model on the same generated data and compare
its likelihood with that of the full analysis.}
\details{Uses twice the log-likelihood difference and a chi-square reference with
the difference in parameter degrees of freedom. Supported fits are lm, likelihood
GLMs, and unpenalized Cox models without robust covariance. Rows, outcomes, weights,
offsets, nesting of design matrices, and Cox strata must agree. Quasi-likelihood,
robust cluster Cox inference, and penalized Cox fits are rejected. For Gaussian
linear models wald_test gives the exact finite-sample F test, whereas this LRT is
asymptotic. Nonstandard boundary nulls or selected models need specialized inference.}
\value{Function \code{function(fit, data)} returning p.value, statistic, and df.}
\examples{
set.seed(2)
d <- data.frame(x = rnorm(200))
d$y <- rbinom(200, 1, plogis(-1 + .5 * d$x))
lrt_test(y ~ 1)(glm(y ~ x, d, family = binomial()), d)
}
