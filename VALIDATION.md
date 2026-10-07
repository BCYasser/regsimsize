# Validation record: regsimsize 0.1.1

Checked 7 October 2026. Source: BCYasser/regsimsize, commit
6592c9c91f83193b1f6a3d54cd2da633ff6ea2bf, with local packaging/documentation changes.
All 40 original files matched their GitHub blob hashes before editing.
The six files in R/ are unchanged.

## Current results

Environment: Ubuntu 24.04.3 LTS, x86_64, R 4.6.1 (2026-06-24).

| Check | Result |
|---|---|
| R CMD build | Passed; generated HTML vignette and extracted R code |
| R CMD check --as-cran, final tarball | 0 errors, 0 warnings, 1 NOTE |
| Sole NOTE | CRAN incoming feasibility: New submission |
| Online incoming checks | Completed; not disabled |
| Installation, namespace and code analysis | Passed |
| Rd, code/documentation consistency and examples | Passed |
| Regression suite, including two-worker reproducibility | 57 checks passed |
| Vignette execution and rebuilding | Passed |
| PDF reference manual | Passed |
| HTML manual validation and math rendering | Passed, using tidy and V8 |
| Installed vignette discovery, exports and citation | Verified |
| Optional advanced examples | Four designs, eight successful analyses each |
| Tarball contents | Repository-only files excluded; LICENSE and built vignette retained |

Commands used for the final tarball:

```sh
R CMD build regsimsize
R_RD4PDF=times,hyper REGSIMSIZE_TEST_PARALLEL=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 R CMD check --as-cran regsimsize_0.1.1.tar.gz
```

R_RD4PDF selected installed standard PDF fonts; it did not skip the manual.
R-devel was not installed in this environment, so current R-release was used.
The delivery's validation/ directory contains the full final log, regression
output, environment details and tarball SHA-256. Updating this excluded
validation record does not change the checked tarball.

Dependency versions used in the final check:

```
survival 3.8.12
nlme 3.1.171
knitr 1.52
evaluate 1.0.5
highr 0.12
xfun 0.61
yaml 2.3.12
codetools 0.2.20
V8 8.2.0

```

The final source tarball SHA-256 is:

```
59a6b85c9909f605775c7a860803a4aba6312e341b3c83f7145b0b81c3d03a19
```

## Remaining before submission

* Run current R-devel and Windows/macOS checks. The included GitHub Actions
  workflow enables these after upload; no remote run is claimed here.
* Check the exact intended submission tarball with R-devel, for example through
  Winbuilder. CI matrix jobs independently build their own tarballs.
* Review every CI note and update cran-comments.md with the actual results.
* Recheck name availability and URLs at submission. On 7 October, no exact
  case-insensitive regsimsize match was found in current CRAN, CRAN Archive,
  or the Bioconductor 3.23 release software index. The online incoming check
  reported only New submission. This does not reserve the name.
* The maintainer confirms authorship/permissions and the submission email.

## Historical evidence and scope

The original repository reported an ordinary R 4.3.3 check and a larger
statistical benchmark. The original benchmark output files were absent from
GitHub and are not included or independently reproduced here. This delivery
replaces the historical check claim with actual current release-check evidence.
Small demonstration runs verify execution, not precise power or the validity
of arbitrary user callbacks. CRAN acceptance remains a separate review.
