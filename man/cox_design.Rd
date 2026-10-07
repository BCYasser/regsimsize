\name{cox_design}
\alias{cox_design}
\title{Construct a Right-Censored Cox Model Simulation}
\usage{
cox_design(formula, coefficients, covariates, test,
           baseline = weibull_baseline(), censoring = NULL, followup = Inf,
           lp_formula = NULL, fit_args = list(),
           label = "Proportional hazards Cox regression")
}
\arguments{
\item{formula}{Two-sided Cox formula with \code{Surv(time, status)} as its response.
Time and status must be different plain column names.}
\item{coefficients}{Named log-hazard coefficients, without an intercept.}
\item{covariates}{Function of n returning n covariate rows without time or status.}
\item{test}{Test callback such as wald_test.}
\item{baseline}{Inverse cumulative baseline hazard \code{function(q, data)} returning
n positive finite event times. q is already divided by the relative hazard.}
\item{censoring}{Optional \code{function(n, data)} returning positive censoring times
measured since entry. NULL means no dropout censoring.}
\item{followup}{Positive maximum follow-up time or \code{function(n, data)} returning
one or n limits. Inf means no administrative limit. For staggered accrual, return
calendar study end minus each participant's enrollment time.}
\item{lp_formula}{One-sided generating predictor formula. Required for analysis
formulas containing strata or cluster. Its intercept is removed.}
\item{fit_args}{Named arguments to coxph, or function of data returning them.
Formula and data are protected. x, y, and model default to TRUE.}
\item{label}{Descriptive label.}
}
\description{Generate proportional-hazards event times by inverse cumulative
hazard, apply dropout and administrative censoring, and fit coxph.}
\details{For an independent unit-rate exponential variate E and linear predictor
eta, event time is \eqn{H_0^{-1}(E\exp(-eta))}. The observed status is 1 when the
event precedes both censoring and follow-up limits, including equality. The built-in
generator assumes baseline covariates and a single right-censored event per person.
Stratified generation requires explicitly appropriate stratum-specific baselines;
adding strata to the analysis formula alone does not change the data generator.
Likewise, a cluster-robust analysis alone does not generate correlated observations.
Use simulation_design for left truncation, time-varying covariates or effects,
recurrent events, frailty, penalties, multistate data, or competing risks, and specify
valid inference there. Fine-Gray models target a different estimand from Cox models.}
\value{A \code{regsim_design}.}
\references{Bender R, Augustin T, Blettner M (2005). Generating survival times to
simulate Cox proportional hazards models. Statistics in Medicine, 24, 1713-1723.
\doi{10.1002/sim.2059}.}
\examples{
d <- cox_design(survival::Surv(time, status) ~ treatment,
  c(treatment = log(.7)), function(n) data.frame(treatment = rbinom(n, 1, .5)),
  wald_test("treatment"), baseline = weibull_baseline(.1, 1.2), followup = 5)
power_curve(d, c(100, 200), nsim = 10)
}
