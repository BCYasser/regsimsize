\name{glm_design}
\alias{glm_design}
\title{Construct a Generalized Linear Model Simulation}
\usage{
glm_design(formula, coefficients, covariates, test,
           family = stats::binomial(), dispersion = 1, trials = 1L,
           response_generator = NULL, fit_args = list(), label = NULL)
}
\arguments{
\item{formula}{Two-sided analysis formula with a simple response name, such as
\code{outcome ~ treatment + age}. Interactions, transformations, factors, and offsets
follow R's formula rules. Use \code{simulation_design} for transformed responses.}
\item{coefficients}{Exactly named model-matrix coefficients, including the intercept
when present. Zero effects must be explicitly included.}
\item{covariates}{Function \code{covariates(n)} returning n rows. It must not return
the response column. Simulate joint distributions here to retain predictor dependence.}
\item{test}{A test callback, often from \code{wald_test} or \code{lrt_test}.}
\item{family}{Family object accepted by \code{stats::glm}, such as \code{binomial("probit")}.
Automatic generation covers binomial, Poisson, Gaussian, Gamma and inverse Gaussian.}
\item{dispersion}{Positive generating dispersion. Gaussian variance is dispersion;
Gamma variance is dispersion times squared mean; inverse Gaussian variance is
dispersion times cubed mean. Binomial and Poisson dispersion must be 1 with their
built-in generators. This argument does not fix the fitted dispersion.}
\item{trials}{Binomial trial count: positive integer scalar or vector, or a function
\code{trials(n, data)}. Ignored with a custom response generator.}
\item{response_generator}{Optional function \code{response_generator(n, mu, data)}
returning the outcome. Required for quasi-families and other custom families.
For binomial outcomes return 0/1 values or an n by 2 successes/failures matrix.}
\item{fit_args}{Named additional arguments to glm, or \code{function(data)} returning
a named list. It cannot override formula, data, or family.}
\item{label}{Optional descriptive label.}
}
\description{Generate covariates, calculate the formula's linear predictor and
inverse link, sample outcomes, and fit the planned generalized linear model.}
\details{Links must generate valid means for the entire covariate distribution.
In grouped-binomial designs, n counts covariate rows, not underlying trials. The
response is stored as a matrix when trial counts exceed one. Event fractions then
use total successes divided by total trials. Formula offsets affect both generation
and fitting; a fit-only offset in fit_args deliberately changes only the analysis.
Quasi-families specify mean-variance relations without a full sampling distribution,
so overdispersion must be explicitly generated. Missingness, survey designs,
multinomial or ordinal models, penalization, and random effects need appropriate
custom generation, fitting, and inference.}
\value{A \code{regsim_design}.}
\seealso{\code{\link{simulation_design}}, \code{\link{model_coefficients}}}
\examples{
d <- glm_design(outcome ~ treatment + age,
  c("(Intercept)" = -2, treatment = log(1.6), age = 0.2),
  covariates = function(n) data.frame(treatment = rbinom(n, 1, .5), age = rnorm(n)),
  test = wald_test("treatment"))
power_curve(d, c(100, 200), nsim = 10, seed = 7)
}
