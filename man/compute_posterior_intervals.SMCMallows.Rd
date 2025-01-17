% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compute_posterior_intervals.R
\name{compute_posterior_intervals.SMCMallows}
\alias{compute_posterior_intervals.SMCMallows}
\title{Compute posterior intervals}
\usage{
\method{compute_posterior_intervals}{SMCMallows}(
  model_fit,
  burnin = model_fit$burnin,
  parameter = "alpha",
  level = 0.95,
  decimals = 3L,
  ...
)
}
\arguments{
\item{model_fit}{An object returned from \code{\link{compute_mallows}}.}

\item{burnin}{A numeric value specifying the number of iterations
to discard as burn-in. Defaults to \code{model_fit$burnin}, and must be
provided if \code{model_fit$burnin} does not exist.
See \code{\link{assess_convergence}}.}

\item{parameter}{Character string defining which parameter to compute
posterior intervals for. One of \code{"alpha"}, \code{"rho"}, or
\code{"cluster_probs"}. Default is \code{"alpha"}.}

\item{level}{Decimal number in \eqn{[0,1]} specifying the confidence level.
Defaults to \code{0.95}.}

\item{decimals}{Integer specifying the number of decimals to include
in posterior intervals and the mean and median. Defaults to \code{3}.}

\item{...}{other arguments passed to methods.}
}
\description{
Compute posterior intervals
}
