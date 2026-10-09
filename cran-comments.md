## Submission status

Prepared for first CRAN submission of regsimsize 0.1.1.
Maintainer: Yasser C Bouklouch <Yasser.bouklouch@gmail.com>.

## Contribution

Simulation-based inferential power for prespecified regression hypotheses, with
linear, GLM and Cox constructors and custom generation/fitting/testing callbacks.
Outputs include Monte Carlo uncertainty, failed-analysis denominators, event
summaries and reproducible sequential/PSOCK execution. This does not claim to
establish prediction-model development adequacy or validate arbitrary callbacks.

## Completed checks, 7 October 2026

* Ubuntu 24.04.3 LTS, x86_64, R 4.6.1 (current release).
* R CMD build: passed, including the HTML vignette.
* R CMD check --as-cran on regsimsize_0.1.1.tar.gz:
  0 errors, 0 warnings, 1 NOTE: New submission.
* Online incoming checks, examples, tests, vignette rebuilding, PDF and HTML
  manual checks completed. No checks were disabled.
* REGSIMSIZE_TEST_PARALLEL=true: 57 regression checks passed, including the
  two-worker reproducibility test.
* R_RD4PDF=times,hyper selected installed fonts for the PDF manual.
* Four optional advanced example designs each completed eight analyses.
* Dependency versions and full logs accompany the local delivery.

## Additional checks completed — 7 October 2026

R CMD check --as-cran completed successfully on:

* Windows: R 4.6.1
* macOS: R 4.6.1
* Ubuntu Linux: R 4.6.1
* Ubuntu Linux: R-devel (2026-10-06 r90643)

All four environments returned:
0 errors, 0 warnings, 1 NOTE.

The only NOTE was "New submission", which is expected for
this package's first CRAN submission.

Workflow results:
https://github.com/BCYasser/regsimsize/actions/runs/37683602888

## Additional information

This is a new submission. No external accounts or services are required to run
examples or tests. Automated runs use at most two workers. No compiled code is
included. The simulation/inference implementation is unchanged from the
previous GitHub version; 0.1.1 updates packaging and submission preparation.
