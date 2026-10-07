\name{mc_replicates}
\alias{mc_replicates}
\title{Plan the Number of Monte Carlo Replicates}
\usage{mc_replicates(half_width = 0.01, power = 0.5, conf.level = 0.95)}
\arguments{
\item{half_width}{Desired approximate confidence-interval half width.}
\item{power}{Planning rejection probability. The default 0.5 gives the largest
binomial variance and a conservative planning count.}
\item{conf.level}{Confidence level. All three arguments must be in (0, 1).}
}
\description{Use the normal binomial approximation to plan simulation precision.}
\details{Returns the ceiling of squared normal quantile times power times
one minus power, divided by squared half width. This is a planning approximation,
not a guarantee about the realized Wilson interval.}
\value{Numeric number of replicates.}
\examples{mc_replicates(half_width = .01, power = .8)}
