
<!-- README.md is generated from README.Rmd. Please edit that file -->

# BayesMallows

[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/BayesMallows)](https://cran.r-project.org/package=BayesMallows)
[![R-CMD-check](https://github.com/ocbe-uio/BayesMallows/workflows/R-CMD-check/badge.svg)](https://github.com/ocbe-uio/BayesMallows/actions)
[![Codecov test
coverage](https://codecov.io/gh/ocbe-uio/BayesMallows/branch/master/graph/badge.svg)](https://app.codecov.io/gh/ocbe-uio/BayesMallows?branch=master)

This package provides a general framework for analyzing rank and
preference data based on the Bayesian Mallows model first described in
[Vitelli et al.(2018)](https://jmlr.org/papers/v18/15-481.html). In particular, we added new datasets to analyse and new priors.


## The Bayesian Mallows Model

### Methodology

The BayesMallows package currently implements the complete model
described in Vitelli et al. (2018), which includes a large number of
distance metrics, handling of missing ranks and pairwise comparisons,
and clustering of users with similar preferences. The extension to
non-transitive pairwise comparisons by Crispino et al. (2019) is also
implemented. In addition, the partition function of the Mallows model
can be estimated using the importance sampling algorithm of Vitelli et
al. (2018) and the asymptotic approximation of Mukherjee (2016). For a
review of ranking models in general, see Q. Liu et al. (2019b). Crispino
and Antoniano-Villalobos (2019) outlines how informative priors can be
used within the model.

Updating of the posterior distribution based on new data, using
sequential Monte Carlo methods, is implemented and described in a
separate vignette which can be shown with the command
`vignette("SMC-Mallows")`.

### Applications

Among the current applications, Q. Liu et al. (2019a) applied the
Bayesian Mallows model for providing personalized recommendations based
on clicking data, and Barrett and Crispino (2018) used the model of
Crispino et al. (2019) to analyze listeners’ understanding of music.

### Future Extensions

Plans for future extensions of the package include allowing for analysis
of time-varying ranks as described in Asfaw et al. (2016), and
implementation of a variational Bayes algorithm for approximation the
posterior distribution. The sequential Monte Carlo algorithms will also
be extended to cover a larger part of the model framework.

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-asfaw2016" class="csl-entry">

Asfaw, D., V. Vitelli, Ø Sørensen, E. Arjas, and A. Frigessi. 2016.
“Time-Varying Rankings with the Bayesian Mallows Model.” *Stat* 6 (1):
14–30. <https://doi.org/10.1002/sta4.132>.

</div>

<div id="ref-barrett2018" class="csl-entry">

Barrett, N., and M. Crispino. 2018. “The Impact of 3-d Sound
Spatialisation on Listeners’ Understanding of Human Agency in Acousmatic
Music.” *Journal of New Music Research* 47 (5): 399–415.
<https://doi.org/10.1080/09298215.2018.1437187>.

</div>

<div id="ref-crispino2019informative" class="csl-entry">

Crispino, M., and I. Antoniano-Villalobos. 2019. “Informative Extended
Mallows Priors in the Bayesian Mallows Model.”
<https://arxiv.org/abs/1901.10870>.

</div>

<div id="ref-crispino2019" class="csl-entry">

Crispino, M., E. Arjas, V. Vitelli, N. Barrett, and A. Frigessi. 2019.
“A Bayesian Mallows Approach to Nontransitive Pair Comparison Data: How
Human Are Sounds?” *The Annals of Applied Statistics* 13 (1): 492–519.
<https://doi.org/10.1214/18-aoas1203>.

</div>

<div id="ref-liu2019b" class="csl-entry">

Liu, Q., A. H. Reiner, A. Frigessi, and I. Scheel. 2019a. “Diverse
Personalized Recommendations with Uncertainty from Implicit Preference
Data with the Bayesian Mallows Model.” *Knowledge-Based Systems* 186
(December): 104960. <https://doi.org/10.1016/j.knosys.2019.104960>.

</div>

<div id="ref-liu2019" class="csl-entry">

Liu, Q, M Crispino, I Scheel, V Vitelli, and A Frigessi. 2019b.
“Model-Based Learning from Preference Data.” *Annual Review of
Statistics and Its Application* 6 (1).
<https://doi.org/10.1146/annurev-statistics-031017-100213>.

</div>

<div id="ref-mukherjee2016" class="csl-entry">

Mukherjee, S. 2016. “Estimation in Exponential Families on
Permutations.” *The Annals of Statistics* 44 (2): 853–75.
<https://doi.org/10.1214/15-aos1389>.

</div>

<div id="ref-sorensen2020" class="csl-entry">

Sørensen, Øystein, Marta Crispino, Qinghua Liu, and Valeria Vitelli.
2020. “BayesMallows: An R Package for the Bayesian Mallows Model.” *The
R Journal* 12 (1): 324–42. <https://doi.org/10.32614/RJ-2020-026>.

</div>

<div id="ref-vitelli2018" class="csl-entry">

Vitelli, V., Ø. Sørensen, M. Crispino, E. Arjas, and A. Frigessi. 2018.
“Probabilistic Preference Learning with the Mallows Rank Model.”
*Journal of Machine Learning Research* 18 (1): 1–49.
<https://jmlr.org/papers/v18/15-481.html>.

</div>

</div>
