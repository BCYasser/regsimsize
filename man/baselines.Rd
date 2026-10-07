\name{weibull_baseline}
\alias{weibull_baseline}
\alias{piecewise_baseline}
\title{Inverse Cumulative Baseline Hazard Functions}
\usage{
weibull_baseline(rate = 0.1, shape = 1)
piecewise_baseline(breaks = c(0, 1), rates = c(0.1, 0.2))
}
\arguments{
\item{rate}{Positive rate, or a function of covariate data returning one or n rates.}
\item{shape}{Positive Weibull shape, or a function of covariate data returning one
or n shapes. Shape 1 gives exponential survival times.}
\item{breaks}{Increasing finite interval start times beginning at 0.}
\item{rates}{One strictly positive hazard per interval. The final rate continues indefinitely.}
}
\description{Create callbacks for the baseline argument of cox_design.}
\details{The Weibull cumulative hazard is \eqn{H_0(t)=rate\,t^{shape}};
the corresponding R Weibull scale is \eqn{rate^{-1/shape}}. A custom inverse may
also be supplied directly to cox_design. Rate or shape functions allow generating
different baselines across strata. All times and hazards must use consistent units.}
\value{Function \code{function(q, data)} returning the inverse cumulative hazard
at q for each row. q is a nonnegative cumulative hazard, not a probability.}
\examples{
inverse <- weibull_baseline(rate = .2, shape = 2)
inverse(c(.2, .8), data.frame())
piecewise_baseline(c(0, 2, 5), c(.1, .3, .05))(c(.1, .5, 1.2), data.frame())
}
