\name{wald_test}
\alias{wald_test}
\title{Create a Single-Coefficient or Joint Wald Test}
\usage{
wald_test(terms, null = 0, alternative = c("two.sided", "greater", "less"),
          vcov = NULL, df = NULL)
}
\arguments{
\item{terms}{Character vector of exact coefficient names. For a factor's overall
effect, provide all associated dummy-variable coefficients.}
\item{null}{Scalar null coefficient value recycled to all terms, or a vector in
the same order as terms. Names on this vector do not change the order.}
\item{alternative}{Two-sided or directional alternative. Directional tests require
a single coefficient. Logistic and Cox values are on log-odds and log-hazard scales.}
\item{vcov}{Optional function of the fitted object returning a named covariance
matrix. When provided, df must be specified explicitly. The default is stats::vcov,
which uses robust covariance stored in a cluster-robust coxph fit.}
\item{df}{Positive denominator degrees of freedom or function of the fit returning
them. Inf uses normal and chi-square distributions. By default lm and GLMs with
estimated dispersion use residual degrees of freedom; binomial, Poisson, and Cox
models use Inf. Unsupported model classes require explicit df or custom inference.}
}
\description{Create a test callback for the hypothesis that the selected
coefficient or coefficients equal prespecified values.}
\details{A single coefficient uses a t or normal reference. A joint test uses
the covariance quadratic form, with F or chi-square reference as appropriate.
This is a large-sample Wald approximation except for correctly specified Gaussian
linear models. A custom robust covariance matrix does not determine its own valid
degrees of freedom. Penalized Cox models are rejected and require custom tests.
For general contrasts, variance components, penalized or selected coefficients,
bootstrap inference, or multiplicity adjustment, use a custom test callback.
Passing many terms tests one joint null, not separate unadjusted hypotheses.}
\value{Function \code{function(fit, data)} returning a list with p.value and test
details. For a single coefficient, estimate and se are also returned.}
\examples{
set.seed(1)
d <- data.frame(x = rnorm(50), y = rnorm(50))
wald_test("x")(lm(y ~ x, d), d)
}
