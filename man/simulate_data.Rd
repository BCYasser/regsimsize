\name{simulate_data}
\alias{simulate_data}
\title{Generate One Study Dataset}
\usage{simulate_data(design, n, seed = 1L)}
\arguments{
\item{design}{A \code{regsim_design}.}
\item{n}{Positive integer number of sampling units.}
\item{seed}{Nonnegative integer random seed.}
}
\description{Inspect the simulated study before running a power calculation.}
\details{The caller's random-number generator type and state are restored after
the call, including on error. The same seed and study specification reproduce
the same data within a compatible R and package environment.}
\value{The data frame returned by the design's generator.}
\examples{
d <- lm_design(y ~ x, c("(Intercept)" = 0, x = 0.3),
               function(n) data.frame(x = rnorm(n)), wald_test("x"))
simulate_data(d, 6, seed = 42)
}
