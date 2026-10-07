# Statistical design and interpretation

## What is being estimated?

For a specified sample size, generating distribution, fitted analysis, hypothesis,
and significance threshold, the engine estimates how often that procedure rejects
the null. Under a null generating scenario this is an estimate of type I error.
Under a specified alternative it is power. The unit counted by sample size must be
declared: individuals, clusters, or grouped-binomial rows are not interchangeable.

Let R be the number of attempted studies, K the number of valid rejections and
S the number of successful analyses. The primary estimate is K/R. The conditional
estimate is K/S, or undefined if S = 0. Failed studies remain in the primary
denominator and count as non-rejections. K/R describes a procedure that does not
reject when its analysis fails. It should not be described as unbiased power for
an unavailable replacement procedure that would have succeeded on every dataset.

The Monte Carlo standard error is sqrt[p(1-p)/R]. Pointwise Wilson limits use the
normal quantile z, center [p + z²/(2R)]/[1 + z²/R], and half width
z sqrt[p(1-p)/R + z²/(4R²)]/[1 + z²/R]. The interval stays nondegenerate at zero
or full rejection, even when the plug-in standard error is zero. These are
approximate frequentist simulation intervals, not Bayesian credible intervals.

## Generate the full study

The convenience GLM generator forms the exact R model matrix and its offset,
multiplies by explicitly named coefficients, and applies the specified inverse
link. Bernoulli or grouped-binomial, Poisson, Gaussian, Gamma, and inverse-Gaussian
responses have explicit sampling distributions. Quasi-families do not define one,
so they require a custom response generator. Grouped observations with different
trial counts contribute different information even when the number of rows is equal.

Linear outcomes add normal residuals by default. A supplied residual function
replaces that distribution, while an observation-specific standard deviation
allows heteroscedasticity. Analysis weights are specified independently so users
can examine correct and deliberately misspecified variance models.

For a proportional-hazards Cox model, the generator samples E from a unit-rate
exponential distribution and returns H0_inverse[E exp(-eta)]. Weibull and
piecewise-constant baseline hazards are provided; a custom inverse cumulative
baseline hazard can replace them. Dropout and administrative limits determine
observed time and event status. This construction follows the general
hazard-inversion approach described by
[Bender and colleagues](https://onlinelibrary.wiley.com/doi/10.1002/sim.2059).

Stratum-specific baselines, correlated covariates, clustering, missingness,
informative observation, exposure changes, and recurrent events require explicit
generating assumptions. Merely writing a term in an analysis formula does not
generate the corresponding study structure.

## Match the test to the scientific question

The single-coefficient Wald test uses the estimated coefficient minus its null
value divided by its standard error. Ordinary Gaussian linear fits use the
appropriate residual t reference. Binomial, Poisson and Cox fits use the normal
reference; GLMs with estimated dispersion use residual degrees of freedom.
Joint Wald tests use the relevant coefficient covariance matrix and an F or
chi-square reference. The default covariance includes the robust covariance
stored in a cluster-robust Cox fit. Other robust covariance functions require
explicit degrees of freedom.

The likelihood-ratio test compares correctly nested models on the same rows,
outcomes, weights and offsets. Cox strata must also remain unchanged. Quasi-models,
penalized Cox fits and cluster-robust Cox likelihood comparisons are rejected.
An ordinary LRT is asymptotic, including for Gaussian linear models, where the
Wald/F alternative supplies an exact finite-sample test under its assumptions.

Complex analyses may use a model-specific test callback. A fitting function alone
is insufficient to establish a valid p-value for a penalized coefficient, a
variance component on a boundary, a post-selection target, or a complex contrast.
One returned p-value represents one prespecified procedure. There is no automatic
multiple-testing correction beyond the user's chosen test.

## Select sample size without hiding uncertainty

The selector returns the smallest evaluated n meeting the target criterion and
the observed failure-rate threshold. Its default uses the lower pointwise
simulation limit; the optional point-estimate criterion is less cautious. It
does not smooth, interpolate, extrapolate or enforce monotonicity. A candidate
selected after inspecting several sample sizes should be confirmed with a new seed
and a larger prespecified number of replicates. Pointwise intervals do not provide
simultaneous coverage across a grid or protect against repeated optional searching.

More replicates reduce simulation error, not uncertainty about clinical assumptions.
The study should be planned across defensible ranges for the effect, outcome rate,
predictor dependence, loss to follow-up and model misspecification. Null-scenario
checks matter because apparent power is unhelpful if the fitted test is too liberal.
This separation of aims, generating assumptions, methods and performance measures
is consistent with the guidance of
[Morris and colleagues](https://onlinelibrary.wiley.com/doi/10.1002/sim.8086).

## Model development and epidemiological bias

A model can have a significant predictor and still be unsuitable for individual
risk prediction. Development sample sizes should address overfitting and the
precision of predicted risks using appropriate methods, such as those implemented
in [pmsampsize](https://CRAN.R-project.org/package=pmsampsize). This package's
rejection-probability engine does not automatically evaluate calibration, shrinkage,
discrimination, external validity or the precision of model performance.

Simulation is useful for exploring plausible bias, but conclusions depend on
what was represented. Correlated predictors can reduce information; selection can
alter the target population; exposure or outcome misclassification can change an
observed association; and informative censoring can distort survival estimates.
For an exposure that begins during follow-up, attributing all preceding time to
the exposed group creates an incorrect time ordering. The advanced time-varying
example instead changes the exposure and its hazard only when exposure begins.
Study-specific selection, confounding and missing-data mechanisms must be encoded
and analyzed explicitly. The default constructors assume none of those mechanisms
unless the user supplies them.

## Relationship to the supplied work

The supplied Hsieh paper discusses approximate sample size calculations for
linear and logistic regression and uses simulation for comparisons. The present
package performs simulation directly and does not implement those analytic formulas.
Its clinical-looking example inputs are invented planning values, clearly labeled
as illustrative. The plots and reference PDF were available, but the original
simulator code was not, so a source-to-source or numerical reproduction audit
could not be done. References are supplied in BibTeX with verification notes.
