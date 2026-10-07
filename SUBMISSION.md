# Publishing regsimsize 0.1.1

## Upload to GitHub

Extract the delivery ZIP. Upload the contents of its regsimsize/ folder to the
repository root. DESCRIPTION must remain at the root, not in a nested folder.
Include .Rbuildignore, .gitignore, and .github/workflows/R-CMD-check.yaml.
If the web uploader omits dotfiles, use GitHub Desktop or create those files
using Add file > Create new file and their exact paths.
Do not upload the delivery ZIP, validation/ folder, or tarball into the package root.

The workflow runs after a push to main/master and can also be started through
Actions > R-CMD-check > Run workflow. It checks current R-release on Linux,
Windows and macOS, plus R-devel on Linux. Examples, tests, vignette rebuilding,
PDF manual, online incoming checks and two-worker regression checks are enabled.
A green job permits notes; download and review every check log.

## Before CRAN submission

Read VALIDATION.md and replace the pending items in cran-comments.md with actual
results. The workflow uploads full check directories, including source tarballs,
as platform-specific artifacts. Use the tarball built with current R-release,
and check that same file with current R-devel before submission.

From the parent of the package directory, with current R and all dependencies:

```sh
R CMD build regsimsize
R CMD check --as-cran regsimsize_0.1.1.tar.gz
```

A LaTeX installation is needed for the reference manual. No Pandoc or rmarkdown
is needed for this package's knitr Rhtml vignette. Do not suppress checks to obtain
a passing result. Explain unavoidable notes in the submission comments.

Check the identical source tarball on Windows with Winbuilder R-devel if needed:
https://win-builder.r-project.org/

Recheck package-name availability and all URLs immediately before submission.
Source tarballs must be made with R CMD build; a repository ZIP is not a CRAN
submission file. After changing package code or included documentation, rebuild
and recheck. Maintainer confirmation and CRAN review remain required.

Upload through https://cran.r-project.org/submit.html and complete the maintainer
email confirmation. Do not resubmit while an earlier submission is pending.

## Scope and provenance

This package estimates inferential power for a prespecified regression hypothesis.
It combines built-in linear, GLM and Cox generators with custom callbacks,
Monte Carlo uncertainty and explicit failed-analysis reporting. It does not
establish prediction-model development adequacy or validate arbitrary callbacks.

Version 0.1.1 was prepared locally from GitHub commit
6592c9c91f83193b1f6a3d54cd2da633ff6ea2bf. The simulation and inference code is unchanged.
The supplied plots and Hsieh reference informed the original implementation;
the original simulator source was unavailable, so equivalence is not established.

Requirements consulted 7 October 2026:
https://cran.r-project.org/web/packages/policies.html
https://cran.r-project.org/web/packages/submission_checklist.html
https://cran.r-project.org/doc/manuals/r-devel/R-exts.html
