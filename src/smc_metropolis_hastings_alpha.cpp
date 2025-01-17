#include "RcppArmadillo.h"
#include "smc.h"
#include "partitionfuns.h"

// [[Rcpp::depends(RcppArmadillo)]]
//' @title Metropolis-Hastings Alpha
//' @description Function to perform Metropolis-Hastings for new rho under
//'   the Mallows model with footrule distance metric!
//' @param alpha Numeric value of the scale parameter
//' @param n_items Integer is the number of items in a ranking
//' @param rankings the observed rankings, i.e, preference data
//' @details \code{rankings} is a matrix of size
//'   \eqn{N }\eqn{\times}{x}\eqn{ n_items} of rankings in each row.
//'   Alternatively, if \eqn{N} equals 1, \code{rankings} can be a vector.
//' @param metric A character string specifying the distance metric to use
//'   in the Bayesian Mallows Model. Available options are \code{"footrule"},
//'   \code{"spearman"}, \code{"cayley"}, \code{"hamming"}, \code{"kendall"},
//'   and \code{"ulam"}.
//' @param rho Numeric vector specifying the current consensus ranking
//' @param logz_estimate Estimate  grid of log of partition function,
//'   computed with \code{\link{estimate_partition_function}} in
//'   the BayesMallow R package {estimate_partition_function}.
//' @param alpha_prop_sd Numeric value specifying the standard deviation of the
//'   lognormal proposal distribution used for \eqn{\alpha} in the
//'   Metropolis-Hastings algorithm. Defaults to \code{0.1}.
//' @return \code{alpha} or \code{alpha_prime}: Numeric value to be used
//'   as the proposal of a new alpha
//' @param lambda Strictly positive numeric value specifying the rate parameter
//'   of the truncated exponential prior distribution of \eqn{\alpha}. Defaults
//'   to \code{0.1}. When \code{n_cluster > 1}, each mixture component
//'   \eqn{\alpha_{c}} has the same prior distribution.
//' @param alpha_max Maximum value of \code{alpha} in the truncated exponential
//'   prior distribution.
//' @importFrom stats dexp rlnorm runif
//' @author Anja Stein
//' @example /inst/examples/metropolis_hastings_alpha_example.R
//'
//' @export
// [[Rcpp::export]]
double metropolis_hastings_alpha(
  double alpha,
  int n_items,
  arma::mat rankings,
  std::string metric,
  arma::vec rho,
  const Rcpp::Nullable<arma::vec> logz_estimate,
  double alpha_prop_sd,
  double lambda,
  double alpha_max
) {
  double rand = Rcpp::as<double>(Rcpp::rnorm(1, 0, 1));
  double alpha_prime_log = rand * alpha_prop_sd + std::log(alpha);
  double alpha_prime = std::exp(alpha_prime_log);

  // Difference between current and proposed alpha
  double alpha_diff = alpha - alpha_prime;
  double mallows_loglik_prop = get_mallows_loglik(alpha_prime - alpha, rho, n_items, rankings, metric);

  // evaluate the log estimate of the partition function for a particular
  // value of alpha
  const Rcpp::Nullable<arma::vec> cardinalities = R_NilValue;
  double logz_alpha = get_partition_function(n_items, alpha, cardinalities, logz_estimate, metric);
  double logz_alpha_prime = get_partition_function(n_items, alpha_prime, cardinalities, logz_estimate, metric);

  double obs_freq = rankings.n_elem / n_items;

  // Compute the Metropolis-Hastings ratio
  double loga = mallows_loglik_prop + lambda * alpha_diff + obs_freq * (logz_alpha - logz_alpha_prime) + log(alpha_prime) - log(alpha);

  // determine whether to accept or reject proposed rho and return now consensus
  // ranking
  double p = Rcpp::as<double>(Rcpp::runif(1, 0, 1));
  if (log(p) <= loga && alpha_prime < alpha_max) {
    return(alpha_prime);
  } else {
    return(alpha);
  }
}
