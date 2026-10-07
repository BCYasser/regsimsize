# regsimsize

**Plan a study by simulating the analysis you intend to run.**

`regsimsize` estimates power for a prespecified regression hypothesis across a
sample size grid. It keeps the study generator, analysis model, and hypothesis
separate, so each can be changed without rewriting the simulation engine.

Version 0.1.1 is a source release prepared for publication. It has not been
submitted to CRAN. See `SUBMISSION.md` for the publishing steps.

Author and maintainer: **Yasser C Bouklouch**
<Yasser.bouklouch@gmail.com>. Licensed under the **MIT License**.

## Install

```r
install.packages("regsimsize_0.1.1.tar.gz", repos = NULL, type = "source")
library(regsimsize)
```

The runtime uses R 4.1 or later, base/recommended packages, and `survival`.
No compilation is needed for this package. `knitr` is needed to rebuild the
vignette. `nlme` is used only by the optional mixed-model example.

## A logistic example

Suppose the study aims to detect a treatment odds ratio of 1.6 after accounting
for age. These are illustrative planning assumptions, not estimates from the
uploaded plots or a clinical dataset.

```r
covariates <- function(n) {
  data.frame(treatment = rbinom(n, 1, 0.5), age_z = rnorm(n))
}

design <- glm_design(
  outcome ~ treatment + age_z,
  coefficients = c("(Intercept)" = -2, treatment = log(1.6), age_z = log(1.3)),
  covariates = covariates,
  family = binomial(),
  test = wald_test("treatment")
)

head(simulate_data(design, n = 100, seed = 8))
curve <- power_curve(design, sample_sizes = seq(200, 1600, 200),
                     nsim = 1000, seed = 2026)
plot(curve)
summary(curve)
select_sample_size(curve, target = 0.80)
plot_event_rate(curve)
```

The intercept describes risk at treatment = 0 and age_z = 0. It does not set the
overall event proportion. `calibrate_intercept()` sets the marginal probability
over a representative reference covariate sample when that is the desired input.

## Model support

| Planned analysis | Convenient route | Scope |
|---|---|---|
| Binary or grouped-binomial GLM | `glm_design()` | Logit, probit, complementary log-log and other compatible links |
| Other GLMs | `glm_design()` | Automatic Poisson, Gaussian, Gamma and inverse-Gaussian outcomes; custom generators for quasi/other families |
| Ordinary or weighted linear regression | `lm_design()` | Factors, interactions, offsets, transformations, fixed spline bases and custom residuals |
| Right-censored proportional-hazards Cox | `cox_design()` | Flexible baseline hazards, dropout, follow-up limits and explicit stratified generation |
| Time-varying, recurrent-event, delayed-entry or frailty Cox | `simulation_design()` | Supply the correct longitudinal/event generator, fitter and test |
| Mixed, generalized least squares, multinomial, ordinal, penalized or other models | `simulation_design()` | Supply callbacks and model-specific inference; compatibility is not automatic statistical validation |

For Cox regression, the number of events and their timing matter alongside the
number recruited. The package records event counts and fractions. For custom
clustered designs, `n` can mean clusters; `mean_rows` separately reports generated
rows. For grouped binomial models, `n` is the number of covariate rows, not total trials.

## Choose the scientific test

```r
wald_test("treatment")                         # one coefficient
wald_test(c("groupB", "groupC"))              # one overall factor hypothesis
wald_test("treatment", alternative = "greater")
lrt_test(outcome ~ age_z)                       # reduced model excludes treatment
```

Coefficient names must match R's model matrix exactly. Use
`model_coefficients(formula, reference_data)` to build the vector. A factor with
three levels generally needs two coefficients; an interaction adds more.
Joint testing and testing each coefficient separately answer different questions.

For specialized inference, a custom test returns **one valid p-value** for the
prespecified procedure. It can implement an adjusted familywise test, bootstrap
test, or model-specific contrast. The core does not choose these procedures for you.

## Read the result correctly

* `power` is rejections divided by **all attempted analyses**.
* `failed` and `failure_rate` show errors, invalid fits/tests and, by default, warnings.
* `power_successful` conditions on successful analyses. It can look optimistic
  when sparse or difficult datasets fail.
* `lower` and `upper` are pointwise Wilson confidence limits for simulation error.
* `mcse` is the estimated Monte Carlo standard error. At power 0 or 1 it is zero,
  but the Wilson interval still reflects finite simulation precision.
* `mean_events` and `mean_event_fraction` describe generated data, including
  datasets whose analyses failed.

Inspect `curve$replicates` for messages and failure stages. Suppressing warnings
does not repair a failed analysis. The optional `warning_policy = "record"`
accepts warning-producing fits only when the test remains valid and built-in
convergence checks pass; use it after reviewing the warning's meaning.

## Select and confirm a sample size

The default selection requires the **lower pointwise Monte Carlo limit** to meet
the target and the observed failure rate to stay at or below 1%. It returns the
smallest **evaluated** sample size satisfying those rules. It never invents a
sample size outside the grid, smooths away failed fits, or assumes monotone power.

```r
candidate <- select_sample_size(curve, target = .8)
if (!is.na(candidate$n)) {
  confirmation <- power_curve(design, candidate$n, nsim = 10000, seed = 417)
  print(confirmation)
}
mc_replicates(half_width = .01, power = .8)  # approximately 6147 replicates
```

The selection rule is not a simultaneous guarantee over a searched grid.
Confirm the candidate independently and rerun clinically plausible scenarios
for effect sizes, event rates, predictor relationships, missingness and censoring.

## Prediction-model development is a different goal

Detecting one coefficient does not ensure reliable prediction, limited overfitting,
or precise calibration. For prediction-model development, use appropriate
development criteria, such as those implemented in
[`pmsampsize`](https://CRAN.R-project.org/package=pmsampsize), or a separately
specified validation-based simulation. The current engine estimates rejection
probabilities and does not automatically calculate prediction-development sample sizes.

## Reproducibility

```r
curve_parallel <- power_curve(design, c(200, 400), nsim = 100, seed = 20, workers = 2)
saveRDS(curve_parallel, "planning-result.rds")
write.csv(as.data.frame(curve_parallel), "power-summary.csv", row.names = FALSE)
```

The package assigns an independent L'Ecuyer-CMRG stream to each replicate and
restores the caller's RNG state. The same grid, `nsim`, seed, callbacks and software
environment give the same raw results regardless of worker count. Changing the
grid or `nsim` changes later stream assignments. Callback dependencies must be
self-contained on workers, and callbacks must not reset their own seed.

## Learn more

```r
help(package = "regsimsize")
vignette("regsimsize", package = "regsimsize")
system.file("examples", package = "regsimsize")
citation("regsimsize")
```

The package includes a worked guide, advanced callback examples, a reproducible
validation script, an annotated methods note, verified references, and CI setup.
The attached plots and Hsieh paper inspired this implementation; the original
simulator source was not supplied, so numerical equivalence to it has not been tested.

Simulation-based power is an established approach. Existing tools include
[`simr`](https://CRAN.R-project.org/package=simr) for mixed models and
[`simstudy`](https://CRAN.R-project.org/package=simstudy) for data generation.
This package's proposed contribution is a small shared interface across study
generators, fitters and tests with explicit diagnostics. It does not claim that
the general simulation approach is new.
