context('SMC new user and item rank combined')

# a simpler example to test ====================================================
set.seed(101)
Time <- dim(sample_dataset)[3]

# General ======================================================================
n_items <- dim(sample_dataset)[2] # Number of items
rho_0 <- seq(from = 1, to = n_items, by = 1) # 'true' consensus ranking
alpha_0 <- 2 # fixed/ 'true' scale parameter
leap_size <- floor(n_items / 5)
metric <- "footrule"

# Generate estimate of Z_n(alpha) ==============================================
alpha_vector <- seq(from = 0, to = 20, by = 0.1)
iter <- 1e2
degree <- 10

# Estimate the logarithm of the partition function of the Mallows rank model
# using the estimate partition function
logz_estimate <- estimate_partition_function(
  method = "importance_sampling",
  alpha_vector = alpha_vector,
  n_items = n_items, metric = metric,
  nmc = iter, degree = degree
)

mcmc_kernel_app <- 5
N <- 20
alpha_prop_sd <- 0.5
lambda <- 0.15
alpha_max <- 1e6

test_that("Produces the wrong metric and aug_method error", {
	expect_error(
		smc_mallows_new_item_rank_alpha_fixed(
			alpha = alpha_0, n_items = n_items, R_obs = sample_dataset,
			metric = "cayley", leap_size = leap_size, N = N, Time = Time,
			logz_estimate = logz_estimate, mcmc_kernel_app = mcmc_kernel_app,
			alpha_prop_sd = alpha_prop_sd, lambda = lambda,
			alpha_max = alpha_max, aug_method = "pseudolikelihood"
		)
	)
	expect_error(
		smc_mallows_new_item_rank(
			n_items = n_items, R_obs = sample_dataset,
			metric = "cayley", leap_size = leap_size, N = N, Time = Time,
			logz_estimate = logz_estimate, mcmc_kernel_app = mcmc_kernel_app,
			alpha_prop_sd = alpha_prop_sd, lambda = lambda,
			alpha_max = alpha_max, aug_method = "pseudolikelihood"
		)
	)
})

test_that("Runs with unif kernel", {
	smc_unif_alpha_fixed_unif <- suppressMessages(
		smc_mallows_new_item_rank_alpha_fixed(
			alpha = alpha_0, n_items = n_items, R_obs = sample_dataset,
			metric = "footrule", leap_size = leap_size, N = N, Time = Time,
			logz_estimate = logz_estimate, mcmc_kernel_app = mcmc_kernel_app,
			alpha_prop_sd = alpha_prop_sd, lambda = lambda,
			alpha_max = alpha_max, aug_method = "random"
		)
	)
	expect_is(smc_unif_alpha_fixed_unif, "list")
	expect_length(smc_unif_alpha_fixed_unif, 1)
	expect_equal(dim(smc_unif_alpha_fixed_unif$rho_samples), c(N, 6, 31))
	smc_unif <- suppressMessages(
		smc_mallows_new_item_rank(
			n_items = n_items, R_obs = sample_dataset,
			metric = "footrule", leap_size = leap_size, N = N, Time = Time,
			logz_estimate = logz_estimate, mcmc_kernel_app = mcmc_kernel_app,
			alpha_prop_sd = alpha_prop_sd, lambda = lambda,
			alpha_max = alpha_max, aug_method = "random"
		)
	)
	expect_is(smc_unif, "list")
	expect_length(smc_unif, 2)
	expect_equal(dim(smc_unif$rho_samples), c(N, 6, 31))
	expect_equal(dim(smc_unif$alpha_samples), c(N, 31))
})

test_that("Runs with pseudo kernel", {
	smc_unif_alpha_fixed_unif <- suppressMessages(
		smc_mallows_new_item_rank_alpha_fixed(
			alpha = alpha_0, n_items = n_items, R_obs = sample_dataset,
			metric = "footrule", leap_size = leap_size, N = N, Time = Time,
			logz_estimate = logz_estimate, mcmc_kernel_app = mcmc_kernel_app,
			alpha_prop_sd = alpha_prop_sd, lambda = lambda,
			alpha_max = alpha_max, aug_method = "pseudolikelihood"
		)
	)
	expect_is(smc_unif_alpha_fixed_unif, "list")
	expect_length(smc_unif_alpha_fixed_unif, 1)
	expect_equal(dim(smc_unif_alpha_fixed_unif$rho_samples), c(N, 6, 31))
	smc_unif <- suppressMessages(
		smc_mallows_new_item_rank(
			n_items = n_items, R_obs = sample_dataset,
			metric = "footrule", leap_size = leap_size, N = N, Time = Time,
			logz_estimate = logz_estimate, mcmc_kernel_app = mcmc_kernel_app,
			alpha_prop_sd = alpha_prop_sd, lambda = lambda,
			alpha_max = alpha_max, aug_method = "pseudolikelihood"
		)
	)
	expect_is(smc_unif, "list")
	expect_length(smc_unif, 2)
	expect_equal(dim(smc_unif$rho_samples), c(N, 6, 31))
	expect_equal(dim(smc_unif$alpha_samples), c(N, 31))
})
