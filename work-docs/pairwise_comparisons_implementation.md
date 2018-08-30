Pairwise Comparison Proposals
================

``` r
library(dplyr)
```

The purpose of this document is to describe in detail how the data augmentation works in the case of pairwise preferences. Much of this uses internal functions, so it can be a good idea to make all these functions available with the following command:

``` r
devtools::load_all()
```

    ## Loading BayesMallows

    ## 
    ## Attaching package: 'testthat'

    ## The following object is masked from 'package:dplyr':
    ## 
    ##     matches

Let us take the familiar beach example.

Data Preparation
----------------

We use the function `generate_transitive_closure` to expand the dataframe \`beach\_preferences´ to include all pairwise preferences implied by the orderings.

``` r
beach_tc <- generate_transitive_closure(beach_preferences)
```

Next, we generate the initial ranking.

``` r
beach_init_rank <- generate_initial_ranking(beach_tc)
```

Hint: If you want to look at the source code, use `View(generate_initial_ranking)` or `View(generate_transitive_closure)` inside RStudio. The same applies to all other R functions described.

We now issue the following function call:

``` r
model_fit <- compute_mallows(rankings = beach_init_rank, 
                             preferences = beach_tc)
```

Generating Constraints
----------------------

Inside `compute_mallows.R`, before the `C++` code for running MCMC is called, we find the following lines of code:

``` r
# Generate the constraint set
  if(!is.null(preferences)){
    constraints <- generate_constraints(preferences, n_items)
  } else {
    constraints <- list()
  }
```

Let us run this function on the beach data.

``` r
preferences <- beach_tc
n_items <- ncol(beach_init_rank)
constraints <- generate_constraints(preferences, n_items)
```

The `constraints` object that comes out, is a list. Its lengths equals the number of assessors.

``` r
class(constraints)
```

    ## [1] "list"

``` r
length(constraints)
```

    ## [1] 60

Inside each list element of `constraints`, we find three objects:

-   `constrained_items`: a numeric vector of the unique items that are constrained for the assessor.
-   `items_above`: a list of length `n_items`. Each element is a numeric vector of items that are ranked above the given item.
-   `items_below`: a list of length `n_items`. Each element is a numeric vector of items that are ranked below the given item.

Let us go through these list elements one by one.

### Constrained Items

Let us start by looking at `constrained_items` for assessor 1.

``` r
constraints[[1]][["constrained_items"]]
```

    ##  [1]  4  5  7  8  9 13 14  2  3 12 15  1  6 10 11

We could also have accessed it using `constraints[[1]][[1]]`. Let us find out which items are not constrained, if any.

``` r
setdiff(seq(1, n_items, 1), constraints[[1]][[1]])
```

    ## numeric(0)

All items are constrained for assessor 1.

We can also do the same for assessor 2. Here are this assessor's constrained items.

``` r
constraints[[2]][["constrained_items"]]
```

    ##  [1]  2  4 14  1  7 10 12 15  8  5  9 11

Here we find out which items are not constrained at all for assessor 2.

``` r
setdiff(seq(1, n_items, 1), constraints[[2]][[1]])
```

    ## [1]  3  6 13

Assessor 2 has no implied orderings of items 3, 6, or 13. Let us confirm this, by looking at `beach_tc`:

``` r
beach_tc %>% 
  filter(assessor == 2, 
         top_item %in% c(3, 6, 13) | bottom_item %in% c(3, 6, 13))
```

    ## # A tibble: 0 x 3
    ## # ... with 3 variables: assessor <dbl>, bottom_item <int>, top_item <int>

That seems correct.

### Items Above

The next element in the `constraints` list is called `items_above`. Let us again start by looking at assessor 1. We print out the whole thing. Note that items that have no items above them get an empty vector `integer(0)`.

``` r
constraints[[1]][["items_above"]]
```

    ## $`1`
    ## [1] 10
    ## 
    ## $`2`
    ## [1]  6 15
    ## 
    ## $`3`
    ## [1]  6 11
    ## 
    ## $`4`
    ## [1]  1  3  6  7  9 10 11
    ## 
    ## $`5`
    ## [1]  1  3  6  7  9 10 11 15
    ## 
    ## $`6`
    ## integer(0)
    ## 
    ## $`7`
    ## [1]  1  3  6  9 10 11
    ## 
    ## $`8`
    ## [1]  3  6 10 11 12 13
    ## 
    ## $`9`
    ## [1]  3  6 11
    ## 
    ## $`10`
    ## integer(0)
    ## 
    ## $`11`
    ## integer(0)
    ## 
    ## $`12`
    ## [1] 6
    ## 
    ## $`13`
    ## [1]  3  6 11 12
    ## 
    ## $`14`
    ## [1]  3  6  9 11
    ## 
    ## $`15`
    ## [1] 6

For example, let us look at the items that are ranked above item 6.

``` r
constraints[[1]][["items_above"]][[6]]
```

    ## integer(0)

According to `constraints`, there are no such items. Let us check with `beach_tc` to see that this is correct.

``` r
beach_tc %>% 
  filter(assessor == 1, bottom_item == 6)
```

    ## # A tibble: 0 x 3
    ## # ... with 3 variables: assessor <dbl>, bottom_item <int>, top_item <int>

That seems correct. No items are above item 6.

Let us also look at item 4.

``` r
constraints[[1]][["items_above"]][[4]]
```

    ## [1]  1  3  6  7  9 10 11

Lots of items are above item 4, according to `constraints`. Let us again confirm with `beach_tc`.

``` r
beach_tc %>% 
  filter(assessor == 1, bottom_item == 4) %>% 
  knitr::kable()
```

|  assessor|  bottom\_item|  top\_item|
|---------:|-------------:|----------:|
|         1|             4|          1|
|         1|             4|          3|
|         1|             4|          6|
|         1|             4|          7|
|         1|             4|          9|
|         1|             4|         10|
|         1|             4|         11|

That seems correct.

### Items Below

The last element in the `constraints` list is called `items_below`. Let us again start by looking at assessor 1.

``` r
constraints[[1]][["items_below"]]
```

    ## $`1`
    ## [1] 4 5 7
    ## 
    ## $`2`
    ## integer(0)
    ## 
    ## $`3`
    ## [1]  4  5  7  8  9 13 14
    ## 
    ## $`4`
    ## integer(0)
    ## 
    ## $`5`
    ## integer(0)
    ## 
    ## $`6`
    ##  [1]  2  3  4  5  7  8  9 12 13 14 15
    ## 
    ## $`7`
    ## [1] 4 5
    ## 
    ## $`8`
    ## integer(0)
    ## 
    ## $`9`
    ## [1]  4  5  7 14
    ## 
    ## $`10`
    ## [1] 1 4 5 7 8
    ## 
    ## $`11`
    ## [1]  3  4  5  7  8  9 13 14
    ## 
    ## $`12`
    ## [1]  8 13
    ## 
    ## $`13`
    ## [1] 8
    ## 
    ## $`14`
    ## integer(0)
    ## 
    ## $`15`
    ## [1] 2 5

Let us now look at item 1.

``` r
constraints[[1]][["items_below"]][[1]]
```

    ## [1] 4 5 7

It is claimed that items 4, 5, and 7 are ranked below item 1. We confirm this with `beach_tc`.

``` r
beach_tc %>% 
  filter(assessor == 1, top_item == 1) %>% 
  knitr::kable()
```

|  assessor|  bottom\_item|  top\_item|
|---------:|-------------:|----------:|
|         1|             4|          1|
|         1|             5|          1|
|         1|             7|          1|

Again, it seems correct.

Proposing Augmentations
-----------------------

We now have described the `constraints` object, and can go on to show how it is used in the MCMC algorithm.

Inside `compute_mallows`, the `C++` function `run_mcmc` is used to do the MCMC. The `constraints` object is passed as an `Rcpp::List`. Here is the declaration of `run_mcmc`. After having run `devtools::load_all()`, you can look at its documentation with `?run_mcmc`.

``` cpp
Rcpp::List run_mcmc(arma::mat rankings, int nmc,
                    Rcpp::List constraints,
                    Rcpp::Nullable<arma::vec> cardinalities,
                    Rcpp::Nullable<arma::vec> is_fit,
                    Rcpp::Nullable<arma::vec> rho_init,
                    std::string metric = "footrule",
                    int n_clusters = 1,
                    bool include_wcd = false,
                    int leap_size = 1,
                    double alpha_prop_sd = 0.5,
                    double alpha_init = 5,
                    int alpha_jump = 1,
                    double lambda = 0.1,
                    int psi = 10,
                    int thinning = 1,
                    bool save_augmented_data = false
                      );
```

The first time we encounter `constraints` inside `run_mcmc` is with the following lines:

``` cpp
if(constraints.length() > 0){
    augpair = true;
  } else {
    augpair = false;
  }
```

As we saw in the code snippet from `compute_mallows` way up in this document, if no pairwise preferences are provided, `constraints` is set to an empty list, which has length 0. In this case, the boolean `augpair` is set to `false`, and no pairwise augmentation is ever done. Otherwise, it is set to `true`.

The next, and final, time we meet `constraints` in `run_mcmc` is within the MCMC loop. Here is the code snippet:

``` cpp
// Perform data augmentation of pairwise comparisons, if needed
if(augpair){
  augment_pairwise(rankings, cluster_assignment, alpha_old, rho_old,
                   metric, constraints, n_assessors, n_items, t,
                   aug_acceptance, clustering, augmentation_accepted);

}
```

`augment_pairwise` is a void function, which performs in-place modification of the `rankings` matrix (`rankings` corresponds to `Rtilde` in this case).

### Augment Pairwise

Inside the `augment_pairwise` function, we loop over all assessors and propose new rankings which are either rejected or accepted. Here is the core part of the code. In reality it is a bit longer, because it saves acceptance statistics.

``` cpp
for(int i = 0; i < n_assessors; ++i){
    // Call the function which creates a proposal
    arma::vec proposal;
    propose_pairwise_augmentation(proposal, rankings, 
                                  constraints, n_items, i);

    // Finally, decide whether to accept the proposal or not
    // Draw a uniform random number
    double u = log(arma::randu<double>());

    // Find which cluster the assessor belongs to in this iteration
    int cluster = 0;
    if(clustering){
      cluster = cluster_assignment(i, t);
    }

    double ratio = -alpha(cluster) / n_items *
      (get_rank_distance(proposal, rho.col(cluster), metric) -
      get_rank_distance(rankings.col(i), rho.col(cluster), metric));

    if(ratio > u) rankings.col(i) = proposal;
  }
```

### Propose Pairwise Augmentation

The interesting function here is called `propose_pairwise_augmentation`. Here is the body of that function:

``` cpp
// Extract the constraints for this particular assessor
Rcpp::List assessor_constraints = Rcpp::as<Rcpp::List>(constraints[i]);
arma::uvec constrained_items = Rcpp::as<arma::uvec>(assessor_constraints[0]);

// Draw an integer between 1 and n_items
int item = arma::randi<int>(arma::distr_param(1, n_items));
// Check if the item is constrained for this assessor
bool item_is_constrained = arma::any(constrained_items == item);

// Left and right limits of the interval we draw ranks from
// Correspond to l_j and r_j, respectively, in Vitelli et al. (2018), JMLR, Sec. 4.2.
int left_limit = 0, right_limit = n_items + 1;

if(item_is_constrained){
  find_pairwise_limits(left_limit, right_limit, item,
                       assessor_constraints, rankings.col(i));
}

// Now complete the leap step by drawing a new proposal uniformly between
// left_limit + 1 and right_limit - 1
int proposed_rank = arma::randi<int>(arma::distr_param(left_limit + 1, right_limit - 1));

// Assign the proposal to the (item-1)th item
proposal = rankings.col(i);
proposal(item - 1) = proposed_rank;

double delta_r;
arma::uvec indices;

// Do the shift step
shift_step(proposal, rankings.col(i), item, delta_r, indices);
```

Let us decipher it.

#### Finding Constrained Items

In the first few lines, we find the constrained items for assessor `i`. Remember that `C++` uses 0-first indexing.

``` cpp
// Extract the constraints for this particular assessor
Rcpp::List assessor_constraints = Rcpp::as<Rcpp::List>(constraints[i]);
arma::uvec constrained_items = Rcpp::as<arma::uvec>(assessor_constraints[0]);
```

The `R` equivalent of this code is (we set `i <- 1` to give an example for assessor 1):

``` r
i <- 1
assessor_constraints <- constraints[[i]]
(constrained_items <- assessor_constraints[[1]])
```

    ##  [1]  4  5  7  8  9 13 14  2  3 12 15  1  6 10 11

#### Checking if Item is Constrained

Next, we draw the random number `item`, which corresponds to *u* in the mathematical notation of the paper. Then we check if the item is constrained.

``` cpp
// Draw an integer between 1 and n_items
int item = arma::randi<int>(arma::distr_param(1, n_items));
// Check if the item is constrained for this assessor
bool item_is_constrained = arma::any(constrained_items == item);
```

The `R` equivalent of this code is:

``` r
item <- sample.int(n_items, 1)
item_is_constrained <- any(constrained_items == item)
```

#### Finding Left and Right Limits

Next, we find the left and right limits, *l*<sub>*i*</sub> and *r*<sub>*i*</sub>. This only needs to be done if the item is constrained. If the item is constrained, we call the function `find_pairwise_limits`, which performs in-place modification of `left_limit` and `right_limit`.

``` cpp
// Left and right limits of the interval we draw ranks from
// Correspond to l_j and r_j, respectively, in Vitelli et al. (2018), JMLR, Sec. 4.2.
int left_limit = 0, right_limit = n_items + 1;

if(item_is_constrained){
  find_pairwise_limits(left_limit, right_limit, item,
                       assessor_constraints, rankings.col(i));
}
```

Here is the body of the function `find_pairwise_limits`:

``` cpp
// Find the items which are preferred to the given item
// Items go from 1, ..., n_items, so must use [item - 1]
arma::uvec items_above = Rcpp::as<arma::uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[1])[item - 1]);
arma::uvec items_below = Rcpp::as<arma::uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[2])[item - 1]);

// If there are any items above, we must find the possible rankings
if(items_above.n_elem > 0){
  // Again subtracting 1 because of zero-first indexing
  // Find all the rankings of the items that are preferred to *item*
  arma::vec rankings_above = current_ranking.elem(items_above - 1);
  left_limit = arma::max(rankings_above);
}

// If there are any items below, we must find the possible rankings
if(items_below.n_elem > 0){
  // Find all the rankings of the items that are disfavored to *item*
  arma::vec rankings_below = current_ranking.elem(items_below - 1);
  right_limit = arma::min(rankings_below);
}
```

`current_ranking` is the rankings of this assessor, obtained with the statement `rankings.col(i)` in the code snippet in the top of this subsection. Note that in `C++` we have transposed the `rankings` matrix, so `rankings.col(i)` correponds to `rankings[i, ]` in `R`.

The `R` equivalent is:

``` r
items_above <- assessor_constraints[[2]][[item]]
items_below <- assessor_constraints[[3]][[item]]

if(length(items_above) > 0){
  rankings_above <- current_ranking[items_above]
  left_limit = max(rankings_above)
}

if(length(items_below) > 0){
  rankings_below <- current_ranking[items_below]
  right_limit <- min(rankings_below)
}
```

#### Proposing New Rank

Now that we have `left_limit` and `right_limit` set, we go on by proposing a new rank between `left_limit + 1` and `right_limit - 1`.

``` cpp
// Now complete the leap step by drawing a new proposal uniformly between
// right_limit + 1 and left_limit - 1
int proposed_rank = arma::randi<int>(arma::distr_param(left_limit + 1, right_limit - 1));

// Assign the proposal to the (item-1)th item
proposal = rankings.col(i);
proposal(item - 1) = proposed_rank;
```

The `R` equivalent of this code is:

``` r
proposed_rank <- sample(
  x = seq(from = (left_limit + 1), to = (right_limit + 1), by = 1),
  size = 1
  )

proposal <- rankings[i, ]
proposal[[item]] <- proposed_rank
```

#### Shift Step

Finally, we do the shift step, using exactly the same function that is used for the shift step in the proposal for *ρ*.

``` cpp
double delta_r;
arma::uvec indices;

// Do the shift step
shift_step(proposal, rankings.col(i), item, delta_r, indices);
```

### Completing the Augmentation

So now we have digged very deep into the function structure. Having the proposal ready, we can go back to the `augment_pairwise` function which we started with above. Its remaining lines of code are.

``` cpp
// Finally, decide whether to accept the proposal or not
// Draw a uniform random number
double u = log(arma::randu<double>());

// Find which cluster the assessor belongs to
int cluster = 0;
if(clustering){
  cluster = cluster_assignment(i, t);
}

double ratio = -alpha(cluster) / n_items *
  (get_rank_distance(proposal, rho.col(cluster), metric) -
  get_rank_distance(rankings.col(i), rho.col(cluster), metric));

if(ratio > u) rankings.col(i) = proposal;
```

When this is done, the function is complete, and we go back to the MCMC loop.