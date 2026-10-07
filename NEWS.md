# regsimsize 0.1.1

* Add repository and issue URLs, build exclusions, and a cross-platform
  CRAN-style checking workflow with retained logs and source archives.
* Update submission instructions and distinguish current from historical checks.
* Use temporary output by default for the optional statistical benchmark.
* Clean up test graphics and document the CRAN worker limit.
* Retain the existing simulation and inference implementation.

# regsimsize 0.1.0

Initial development release.

* Formula constructors for common GLMs, linear models and right-censored Cox models.
* Custom generation, fitting, diagnostics and testing callbacks.
* Single-coefficient and joint Wald tests, plus nested likelihood-ratio tests.
* Pointwise Wilson Monte Carlo intervals and explicit failed-analysis denominators.
* Reproducible sequential and PSOCK execution, with caller RNG restoration.
* Sample size grid selection, event summaries, base R graphics and worked examples.

This release is a new implementation based on the supplied simulator plots and
reference paper. The original simulator source code was not available for comparison.
