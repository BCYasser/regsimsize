\name{model_coefficients}
\alias{model_coefficients}
\title{Obtain the Coefficient Names Implied by a Formula}
\usage{model_coefficients(formula, data, value = 0, intercept = TRUE)}
\arguments{
\item{formula}{A one-sided or two-sided formula. Its response is ignored.}
\item{data}{Reference covariate data frame, with explicit factor levels.}
\item{value}{Initial value assigned to every coefficient.}
\item{intercept}{Whether to retain an intercept column. Use FALSE for Cox coefficients.}
}
\description{Return a named coefficient vector matching R's model matrix.}
\details{Every model-matrix column must have an explicitly named coefficient,
including dummy variables and interactions. Offset values contribute to the linear
predictor without receiving a coefficient. Keep factor levels and contrasts stable
across replicates. Use fixed spline knots and fixed polynomial definitions when
coefficient meanings must remain constant.}
\value{A named numeric vector.}
\examples{
data <- data.frame(age = 1:6, group = factor(rep(c("A", "B", "C"), 2)))
model_coefficients(y ~ age * group, data)
}
