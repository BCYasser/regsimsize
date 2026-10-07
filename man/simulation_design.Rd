\name{simulation_design}
\alias{simulation_design}
\alias{print.regsim_design}
\title{Define a Simulation, Analysis, and Hypothesis}
\usage{
simulation_design(generate, fit, test, diagnostics = NULL,
                  label = "Custom simulation design")
\method{print}{regsim_design}(x, ...)
}
\arguments{
\item{generate}{Function \code{generate(n)} returning a nonempty data frame. Here
\code{n} is the sampling unit chosen by the user, such as individuals or clusters.
The number of returned rows may differ from \code{n}.}
\item{fit}{Function \code{fit(data)} returning the fitted analysis object. It must
perform model-specific convergence and validity checks for unsupported classes.}
\item{test}{Function \code{test(fit, data)} returning one numeric p-value, or a list
with \code{p.value}. Optional numeric scalar fields \code{estimate}, \code{se}, and
\code{statistic} are retained. It must implement the intended inferential test.}
\item{diagnostics}{Optional function of generated data returning a named numeric
vector with \code{events} and/or \code{event_fraction}. Values must be finite;
events must be nonnegative and fractions must lie in [0, 1].}
\item{label}{One descriptive string.}
\item{x}{A simulation design.}
\item{...}{Unused additional arguments.}
}
\description{Separate the data-generating process from the planned analysis and
the scientific hypothesis. This interface is the extension point for complex models.}
\details{Use for start-stop survival data, recurrent events, random effects, custom
families, multivariate models, or specialized inference. No model assumptions are
inferred from the name of a fitter. Built-in checks reject nonconverged or boundary
GLMs and nonfinite or aliased coefficients for lm and coxph objects. Custom classes
require checks within the user's fit or test function. Use self-contained closures
with namespace-qualified external functions for parallel workers; packages and data
referenced only through global variables may not exist on a worker. Do not reset the
random seed inside callbacks.}
\value{A \code{regsim_design} list containing callbacks, a label, and metadata.
The print method returns its input invisibly.}
\examples{
d <- simulation_design(
  generate = function(n) data.frame(x = rnorm(n), y = rnorm(n)),
  fit = function(data) lm(y ~ x, data = data),
  test = wald_test("x")
)
simulate_data(d, 5)
}
