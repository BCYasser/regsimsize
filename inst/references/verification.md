# Reference verification

Checked during development on 8 September 2026. No fabricated package DOI or
publication reference is included. `references.bib` can be imported into Zotero.

| Reference | Verification source | Role in this package |
|---|---|---|
| Hsieh, Bloch and Larsen, 1998, Statistics in Medicine 17:1623-1634 | Supplied PDF, [PubMed 9699234](https://pubmed.ncbi.nlm.nih.gov/9699234/) and Europe PMC metadata | Historical context and the supplied simulator's reference; the package does not implement its sample-size approximation |
| Bender, Augustin and Blettner, 2005, Statistics in Medicine 24:1713-1723 | [Publisher record](https://onlinelibrary.wiley.com/doi/10.1002/sim.2059) | Inverse cumulative-hazard survival generation |
| Morris, White and Crowther, 2019, Statistics in Medicine 38:2074-2102 | [Publisher article](https://onlinelibrary.wiley.com/doi/10.1002/sim.8086) | Simulation design and Monte Carlo reporting context |

Implementation interfaces were checked against the primary R documentation:

* [Family objects](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/family.html)
* [Generalized linear models](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/glm.html)
* [Cox proportional hazards fitting](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/coxph.html)
* [Writing R Extensions](https://cran.r-project.org/doc/manuals/R-exts.html)
* [CRAN repository policies](https://cran.r-project.org/web/packages/policies.html)

The positioning discussion uses the packages' own documentation:

* [simr](https://CRAN.R-project.org/package=simr)
* [simstudy](https://CRAN.R-project.org/package=simstudy)
* [pmsampsize](https://CRAN.R-project.org/package=pmsampsize)

These comparisons are brief descriptions, not exhaustive benchmark comparisons.
