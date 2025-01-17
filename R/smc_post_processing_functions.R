#' @importFrom graphics mtext par

#' @title SMC Processing
#' @author Anja Stein
#' @param output input
#' @param colnames colnames
# AS: edited this function to include parameter `colnames`. This resolve issues in #118 with post processing functions not printing the names of items in rankings.
# The `default` is set to NULL so tat we do not cause plotting issues in `plot_rho_heatplot.
smc_processing <- function(output, colnames = NULL) {

  df <- data.frame(data = output)

  # if colnames are specified, then incorporate them
  if(is.null(colnames)){
    n_items <- ncol(df)
    cletters <- rep(c("Item"), times = n_items)
    cindexes <- (c(1:n_items))
    cnames <- c(paste(cletters, cindexes, sep = " "))
    colnames(df) <- cnames
  } else {
    colnames(df) <- colnames
  }
  new_df <- stats::reshape(
    df,
    direction = "long",
    varying = names(df),
    new.row.names = seq_len(prod(dim(df))),
    v.names = "value",
    timevar = "item",
    idvar = NULL,
    times = names(df)
  )
  attr(x = new_df, "reshapeLong") <- NULL # preserves identity to gather output
  class(new_df) <- c("SMCMallows", "data.frame")
  return(new_df)
}

#' Compute Consensus Ranking
#'
#' Compute the consensus ranking using either cumulative probability (CP) or maximum a posteriori (MAP) consensus
#' \insertCite{vitelli2018}{BayesMallows}. For mixture models, the
#' consensus is given for each mixture.
#'
#' @param model_fit An object returned from \code{\link{compute_mallows}}.
#'
#' @param type Character string specifying which consensus to compute. Either
#' \code{"CP"} or \code{"MAP"}. Defaults to \code{"CP"}.
#'
#' @param burnin A numeric value specifying the number of iterations
#' to discard as burn-in. Defaults to \code{model_fit$burnin}, and must be
#' provided if \code{model_fit$burnin} does not exist. See \code{\link{assess_convergence}}.
#' @author Anja Stein
#'
compute_consensus_smc <- function(model_fit, type, burnin) {
  if (type == "CP") {
    .compute_cp_consensus_smc(model_fit, burnin = burnin)
  } else if (type == "MAP") {
    .compute_map_consensus_smc(model_fit, burnin = burnin)
  }
}

.compute_cp_consensus_smc <- function(model_fit, burnin){
#TODO #80: this function already exists on compute_consensus.R. Add S3 method.

  if(is.null(burnin)){
    stop("Please specify the burnin.")
  }

  stopifnot(burnin < model_fit$nmc)

  # Filter out the pre-burnin iterations

  if(burnin!=0){
    df <- dplyr::filter(model_fit, .data$iteration > burnin)
  }else {df <- model_fit}

  # Find the problem dimensions
  n_rows <- nrow(dplyr::distinct(df, .data$item, .data$cluster))

  # Check that there are rows.
  stopifnot(n_rows > 0)

  # Check that the number of rows are consistent with the information in
  # the model object
  stopifnot(model_fit$n_clusters * model_fit$n_items == n_rows)

  # Convert items and clustr to character, since factor levels are not needed in this case
  df <- dplyr::mutate_at(df, dplyr::vars(.data$item, .data$cluster), as.character)

  # Group by item, cluster, and value
  df <- dplyr::group_by(df, .data$item, .data$cluster, .data$value)

  # Find the count of each unique combination (value, item, cluster)
  df <- dplyr::count(df)

  # Arrange according to value, per item and cluster
  df <- dplyr::ungroup(df)
  df <- dplyr::group_by(df, .data$item, .data$cluster)
  df <- dplyr::arrange(df, .data$value, .by_group = TRUE)

  # Find the cumulative probability, by dividing by the total
  # count in (item, cluster) and the summing cumulatively
  df <- dplyr::mutate(df, cumprob = cumsum(.data$n/sum(.data$n)))

  # Find the CP consensus per cluster, using the find_cpc_smc function
  df <- dplyr::ungroup(df)
  df <- dplyr::group_by(df, .data$cluster)
  df <- dplyr::do(df, find_cpc_smc(.data))
  df <- dplyr::ungroup(df)

  # If there is only one cluster, we drop the cluster column
  if (model_fit$n_clusters[1] == 1) {
    df <- dplyr::select(df, -.data$cluster)
  }

  return(df)

}


# Internal function for finding CP consensus.
find_cpc_smc <- function(group_df){
#TODO #80: this function already exists on compute_consensus.R. Add S3 method.
  # Declare the result dataframe before adding rows to it
  result <- dplyr::tibble(
    cluster = character(),
    ranking = numeric(),
    item = character(),
    cumprob = numeric()
  )
  n_items <- max(group_df$value)
  for(i in seq(from = 1, to = n_items, by = 1)){
    # Filter out the relevant rows
    tmp_df <- dplyr::filter(group_df, group_df$value == i)

    # Remove items in result
    tmp_df <- dplyr::anti_join(tmp_df, result, by = c("cluster", "item"))

    # Keep the max only. This filtering must be done after the first filter,
    # since we take the maximum among the filtered values
    if (nrow(tmp_df) >= 1) {
      tmp_df <- dplyr::filter(tmp_df, .data$cumprob == max(.data$cumprob))
    }

    # Add the ranking
    tmp_df <- dplyr::mutate(tmp_df, ranking = i)

    # Select the columns we want to keep, and put them in result
    result <- dplyr::bind_rows(
      result,
      dplyr::select(
        tmp_df, .data$cluster, .data$ranking, .data$item, .data$cumprob
      )
    )

  }
  return(result)
}

 #AS: added one extra line of code to resolve of the issues in #118 with plotting too many rows in compute_rho_consensus
.compute_map_consensus_smc <- function(model_fit, burnin = model_fit$burnin){
#TODO #80: this function already exists on compute_consensus.R. Add S3 method.

  if(is.null(burnin)){
    stop("Please specify the burnin.")
  }

  if(burnin != 0){
    df <- dplyr::filter(model_fit, .data$iteration > burnin)
  } else {
    df <- model_fit
  }

  # Store the total number of iterations after burnin
  n_samples <- length(unique(df$iteration))

  #-----------------------------------------------------------
  #AS: remove the column n_clusters, parameter
  df <- within(df, {n_clusters <- NULL; parameter <- NULL})
  #------------------------------------------------------------

  # Spread to get items along columns
  df <- stats::reshape(
    data = as.data.frame(df),
    direction = "wide",
    idvar = c("iteration", "cluster"),
    timevar = "item",
    varying = list(unique(df$item))
  )
  attr(df, "reshapeWide") <- NULL # maintain identity to spread() output

  # Group by everything except iteration, and count the unique combinations
  df <- dplyr::group_by_at(df, .vars = dplyr::vars(-.data$iteration))
  df <- dplyr::count(df)
  df <- dplyr::ungroup(df)
  # Keep only the maximum per cluster
  df <- dplyr::group_by(df, .data$cluster)
  df <- dplyr::mutate(df, n_max = max(.data$n))
  df <- dplyr::filter(df, .data$n == .data$n_max)
  df <- dplyr::ungroup(df)

  # Compute the probability
  df <- dplyr::mutate(df, probability = .data$n / n_samples)
  df <- dplyr::select(df, -.data$n_max, -.data$n)

  # Now collect one set of ranks per cluster
  df <- stats::reshape(
    as.data.frame(df),
    direction = "long",
    varying = setdiff(names(df), c("cluster", "probability")),
    new.row.names = seq_len(prod(dim(df))),
    v.names = "map_ranking",
    timevar = "item",
    idvar = NULL,
    times = setdiff(names(df), c("cluster", "probability"))
  )
  attr(x = df, "reshapeLong") <- NULL # preserves identity to gather() output

  # Sort according to cluster and ranking
  df <- dplyr::arrange(df, .data$cluster, .data$map_ranking)

  if (model_fit$n_clusters[1] == 1) {
    df <- dplyr::select(df, -.data$cluster)
  }

  return(df)

}

#' @title Compute Posterior Intervals Rho
#' @description posterior confidence intervals for rho
#' @inheritParams smc_processing
#' @param nmc Number of Monte Carlo samples
#' @param burnin A numeric value specifying the number of iterations
#' to discard as burn-in. Defaults to \code{model_fit$burnin}, and must be
#' provided if \code{model_fit$burnin} does not exist. See \code{\link{assess_convergence}}.
#' @param verbose if \code{TRUE}, prints the final output even if the function
#' is assigned to an object. Defaults to \code{FALSE}.
#' @export
#' @author Anja Stein
#'
# AS: added an extra inout variable `colnames`. This is called in the function `smc_processing`.
compute_posterior_intervals_rho <- function(output, nmc, burnin, colnames = NULL, verbose=FALSE) {
  #----------------------------------------------------------------
  # AS: added extra input parameter
  smc_plot <- smc_processing(output = output, colnames = colnames)
  #----------------------------------------------------------------
  smc_plot$n_clusters <- 1
  smc_plot$cluster <- "Cluster 1"

  rho_posterior_interval <- compute_posterior_intervals(
    model_fit = smc_plot, burnin = burnin,
    parameter = "rho", level = 0.95, decimals = 2
  )

  #------------------------------------------------------------------------------------------
  #AS: reorder items to be in numerical order if no colnames are specified
  if (is.null(colnames)) {
    item_numbers <- as.numeric(gsub("\\D", "", rho_posterior_interval$item))
    mixed_order <- match(sort(item_numbers), item_numbers)
    rho_posterior_interval <- rho_posterior_interval[mixed_order, ]
  }
  #------------------------------------------------------------------------------------------

  if(verbose) print(rho_posterior_interval)
  return(rho_posterior_interval)
}

#' @title Compute rho consensus
#' @description MAP AND CP consensus ranking estimates
#' @inheritParams compute_posterior_intervals_rho
#' @param C C
#' @param type type
#' @export
#' @author Anja Stein
#'
# AS: added an extra inout variable `colnames`. This is called in the function `smc_processing`.
compute_rho_consensus <- function(output, nmc, burnin, C, type, colnames = NULL, verbose=FALSE) {

  n_items <- dim(output)[2]

  #----------------------------------------------------------------
  # AS: added extra input parameter
  smc_plot <- smc_processing(output = output, colnames = colnames)
  #----------------------------------------------------------------

  iteration <- array(rep((1:nmc), n_items))
  smc_plot <- data.frame(data = cbind(iteration, smc_plot))
  colnames(smc_plot) <- c("iteration", "item", "value")

  smc_plot$n_clusters <- C
  smc_plot$parameter <- "rho"
  smc_plot$cluster <- "cluster 1"

  # rho estimation using cumulative probability
  if (type == "CP") {
    results <- compute_consensus_smc(
      model_fit = smc_plot, type = "CP", burnin = burnin
    )
  } else {
    results <- compute_consensus_smc(
      model_fit = smc_plot, type = "MAP", burnin = burnin
    )
  }
  if (verbose) print(results)

  return(results)
}

#' @title Plot Alpha Posterior
#' @description posterior for alpha
#' @inheritParams compute_posterior_intervals_rho
#' @export
#' @author Anja Stein
#'
# AS: if you remove the verbose input variable, then the function will be consistent
# with the other plot functions(they all print when verbose=FALSE, but this function doesn't.)
#`plot_rho_heatplot` doesn't require the variable `verbose`,
# so I'm not sure if this function does to plot the density of alpha
plot_alpha_posterior <- function(output, nmc, burnin) {
  alpha_samples_table <- data.frame(iteration = 1:nmc, value = output)

  plot_posterior_alpha <- ggplot2::ggplot(alpha_samples_table, ggplot2::aes_(x =~ value)) +
    ggplot2::geom_density() +
    ggplot2::xlab(expression(alpha)) +
    ggplot2::ylab("Posterior density") +
    ggplot2::ggtitle(label = "Implemented SMC scheme") +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

  print(plot_posterior_alpha)
}

#' @title Compute Posterior Intervals Alpha
#' @description posterior confidence intervals
#' @inheritParams compute_posterior_intervals_rho
#' @export
#' @author Anja Stein
#'
compute_posterior_intervals_alpha <- function(output, nmc, burnin, verbose=FALSE) {
  alpha_samples_table <- data.frame(iteration = 1:nmc, value = output)
  alpha_samples_table$n_clusters <- 1
  alpha_samples_table$cluster <- "Cluster 1"
  class(alpha_samples_table) <- c("SMCMallows", "data.frame")

  alpha_mixture_posterior_interval <- compute_posterior_intervals(alpha_samples_table,
    burnin = burnin,
    parameter = "alpha", level = 0.95, decimals = 2
  )
  if (verbose) print(alpha_mixture_posterior_interval)
  return(alpha_mixture_posterior_interval)
}



#' @title Plot the posterior for rho for each item
#' @param output input
#' @param nmc Number of Monte Carlo samples
#' @param burnin A numeric value specifying the number of iterations
#' to discard as burn-in. Defaults to \code{model_fit$burnin}, and must be
#' provided if \code{model_fit$burnin} does not exist. See \code{\link{assess_convergence}}
#' @param C Number of cluster
#' @param colnames A vector of item names. If NULL, we generate generic names for the items in the ranking.
#' @param items Either a vector of item names, or a
#'   vector of indices. If NULL, five items are selected randomly.
#' @export
plot_rho_posterior <- function(output, nmc, burnin, C, colnames = NULL, items = NULL){

  n_items = dim(output)[2]

  if(is.null(items) && n_items > 5){
    message("Items not provided by user or more than 5 items in a ranking. Picking 5 at random.")
    items <- sample(1:n_items, 5, replace = F)
    items = sort(items)

  } else if (is.null(items) && n_items <= 5) {
    items <- c(1:n_items)
    items = sort(items)
  }

  # do smc processing here
  smc_plot = smc_processing(output = output, colnames = colnames)

  if(!is.character(items)){
    items <- unique(smc_plot$item)[items]
  }

  iteration = rep(c(1:nmc), times = n_items)
  df = cbind(iteration, smc_plot)

  if(C==1){
    df = cbind(cluster = "Cluster 1", df)
  }

  df <- dplyr::filter(df, .data$iteration > burnin, .data$item %in% items)

  # Compute the density, rather than the count, since the latter
  # depends on the number of Monte Carlo samples
  df <- dplyr::group_by(df, .data$cluster, .data$item, .data$value)
  df <- dplyr::summarise(df, n = dplyr::n())
  df <- dplyr::mutate(df, pct = .data$n / sum(.data$n))

  df$item <- factor(df$item, levels = c(items))

  # Taken from misc.R function in BayesMallows
  scalefun <- function(x) sprintf("%d", as.integer(x))

  # Finally create the plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$value, y = .data$pct)) +
    ggplot2::geom_col() +
    ggplot2::scale_x_continuous(labels = scalefun) +
    ggplot2::xlab("rank") +
    ggplot2::ylab("Posterior probability")

  if(C == 1){
    p <- p + ggplot2::facet_wrap(~ .data$item)
  } else {
    p <- p + ggplot2::facet_wrap(~ .data$cluster + .data$item)
  }

  return(p)
}
