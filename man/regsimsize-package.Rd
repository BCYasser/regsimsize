\name{regsimsize-package}
\alias{regsimsize}
\alias{regsimsize-package}
\docType{package}
\title{Simulation-Based Regression Power and Sample Size}
\description{Specify how study data arise, fit the intended analysis, and estimate
the probability of rejecting a prespecified hypothesis over a sample size grid.}
\details{Convenience constructors support linear regression, generalized linear
models, and right-censored proportional hazards models. The general function
interface accepts other generators, fitters, and valid scalar-p-value tests.
Power concerns a specified inferential procedure; it is not a prediction-model
development adequacy criterion. See the user guide for worked examples and scope.}
\references{Morris TP, White IR, Crowther MJ (2019). Using simulation studies to
evaluate statistical methods. Statistics in Medicine, 38, 2074-2102.
\doi{10.1002/sim.8086}.}
\seealso{\code{\link{glm_design}}, \code{\link{simulation_design}},
\code{\link{power_curve}}}
\author{Yasser C Bouklouch \email{Yasser.bouklouch@gmail.com}}
\keyword{package}
