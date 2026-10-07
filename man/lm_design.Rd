\name{lm_design}
\alias{lm_design}
\title{Construct a Linear Regression Simulation}
\usage{
lm_design(formula, coefficients, covariates, test, sigma = 1,
          error = NULL, fit_args = list(), label = "Linear regression")
}
\arguments{
\item{formula}{Two-sided formula with a plain response name.}
\item{coefficients}{Named generating coefficients matching the model matrix.}
\item{covariates}{Function of n returning n rows of covariates without the response.}
\item{test}{A function testing the fitted analysis.}
\item{sigma}{Positive residual standard deviation, or function of data returning
one or n standard deviations. Used only when error is NULL.}
\item{error}{Optional \code{error(n, data)} returning n residuals. It replaces the
Gaussian generator; it is not multiplied by sigma. The user specifies its centering,
variance, and dependence.}
\item{fit_args}{Named arguments to lm, or a function of data returning a named list.
Use this to pass analysis weights. Formula and data cannot be replaced.}
\item{label}{Descriptive label.}
}
\description{Generate continuous outcomes and fit ordinary or weighted linear regression.}
\details{Formula-based interactions, polynomial terms, and fixed spline bases are
supported. For heteroscedastic data, choose correct inverse-variance weights or an
appropriate robust/custom test. The default lm standard errors assume the fitted
variance model is correct. Repeated measures, generalized least squares, random
effects, multivariate responses, and other model classes use simulation_design.}
\value{A \code{regsim_design}.}
\examples{
d <- lm_design(y ~ x, c("(Intercept)" = 0, x = .3),
               function(n) data.frame(x = rnorm(n)), wald_test("x"), sigma = 1.2)
power_curve(d, c(50, 100), nsim = 10)
}
